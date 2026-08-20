-- ============================================================
-- Plataforma SPARKs / SK-PE-CONT-01
-- 17-B.5F.3C.4 - Hardening dos callers de criacao do Projeto
--
-- Decisoes canonicas:
-- - sparks_initiatives e a autoridade transversal da identidade.
-- - skpe_projects permanece o workspace metodologico especializado.
-- - Os callers devem gerar codigo livre nos dois dominios.
-- - A criacao atomica continua exclusivamente delegada a
--   create_skpe_project_from_template().
-- - Nenhuma assinatura publica e alterada.
-- ============================================================

begin;

-- ------------------------------------------------------------
-- 1. Inicio controlado pela PEM-00.
-- ------------------------------------------------------------
create or replace function public.start_skpe_project_pem00(
  target_organization_id uuid,
  target_project_name text default null,
  target_horizon_start_year integer default extract(year from current_date)::integer,
  target_horizon_end_year integer default (extract(year from current_date)::integer + 4)
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  organization_record public.organizations%rowtype;
  existing_project_id uuid;
  created_project_id uuid;
  base_code text;
  candidate_code text;
  suffix integer := 1;
begin
  if not public.can_manage_skpe_journey(target_organization_id) then
    raise exception
      'Acesso negado: o usuário não pode iniciar o Planejamento Estratégico desta organização.'
      using errcode = '42501';
  end if;

  if target_horizon_start_year is null
     or target_horizon_end_year is null
     or target_horizon_end_year < target_horizon_start_year then
    raise exception
      'Informe um horizonte estratégico válido.'
      using errcode = '22023';
  end if;

  select *
    into organization_record
  from public.organizations
  where id = target_organization_id
    and status = 'active';

  if organization_record.id is null then
    raise exception
      'Organização ativa não localizada.'
      using errcode = '22023';
  end if;

  select p.id
    into existing_project_id
  from public.skpe_projects p
  where p.organization_id = target_organization_id
    and p.archived_at is null
    and p.status <> 'archived'
  order by p.created_at desc
  limit 1;

  if existing_project_id is not null then
    return existing_project_id;
  end if;

  base_code := regexp_replace(
    upper(
      coalesce(
        nullif(trim(organization_record.code), ''),
        'ORGANIZACAO'
      )
    ),
    '[^A-Z0-9]+',
    '-',
    'g'
  );

  candidate_code := format(
    'PE-%s-%s',
    trim(both '-' from base_code),
    target_horizon_start_year
  );

  while
    exists (
      select 1
      from public.sparks_initiatives si
      where si.organization_id = target_organization_id
        and si.code = candidate_code
    )
    or exists (
      select 1
      from public.skpe_projects p
      where p.organization_id = target_organization_id
        and p.code = candidate_code
    )
  loop
    suffix := suffix + 1;

    candidate_code := format(
      'PE-%s-%s-%s',
      trim(both '-' from base_code),
      target_horizon_start_year,
      suffix
    );
  end loop;

  created_project_id := public.create_skpe_project_from_template(
    target_organization_id,
    candidate_code,
    coalesce(
      nullif(trim(target_project_name), ''),
      'Planejamento Estratégico de ' ||
      coalesce(
        nullif(trim(organization_record.trade_name), ''),
        organization_record.legal_name,
        organization_record.code
      )
    ),
    'Jornada estratégica iniciada pela Metafase de Governança e Preparação — PEM-00.',
    current_date,
    make_date(target_horizon_end_year, 12, 31),
    null
  );

  update public.skpe_projects
  set
    current_phase_code = 'PEM-00',
    planning_horizon_start_year = target_horizon_start_year,
    planning_horizon_end_year = target_horizon_end_year,
    reference_year = target_horizon_start_year,
    review_cycle = 'Revisão anual',
    valid_from = current_date,
    valid_until = make_date(target_horizon_end_year, 12, 31),
    progress = 0,
    status = 'draft',
    updated_at = timezone('utc', now()),
    updated_by = auth.uid()
  where id = created_project_id;

  update public.skpe_journey_items
  set
    is_current = false,
    updated_at = timezone('utc', now()),
    updated_by = auth.uid()
  where project_id = created_project_id;

  update public.skpe_journey_items
  set
    status = 'in_progress',
    is_current = true,
    planned_start_date = coalesce(planned_start_date, current_date),
    updated_at = timezone('utc', now()),
    updated_by = auth.uid()
  where project_id = created_project_id
    and code = 'PEM-00';

  insert into public.skpe_journey_audit (
    organization_id,
    project_id,
    actor_user_id,
    action_code,
    reason,
    new_data
  )
  values (
    target_organization_id,
    created_project_id,
    auth.uid(),
    'project_started_pem00',
    'Planejamento Estratégico iniciado pela Metafase de Governança e Preparação.',
    jsonb_build_object(
      'current_phase_code', 'PEM-00',
      'horizon_start_year', target_horizon_start_year,
      'horizon_end_year', target_horizon_end_year
    )
  );

  return created_project_id;
end;
$$;

-- ------------------------------------------------------------
-- 2. Preparacao do Projeto sem antecipar Horizonte Estrategico.
-- ------------------------------------------------------------
create or replace function public.prepare_skpe_project(
  target_organization_id uuid,
  target_project_name text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_org public.organizations%rowtype;
  v_existing uuid;
  v_project uuid;
  v_base_code text;
  v_code text;
  v_suffix integer := 1;
begin
  if not public.can_manage_skpe_journey(target_organization_id) then
    raise exception
      'Acesso negado: o usuário não pode preparar o Planejamento Estratégico desta organização.'
      using errcode = '42501';
  end if;

  select *
    into v_org
  from public.organizations
  where id = target_organization_id
    and status = 'active';

  if v_org.id is null then
    raise exception
      'Organização ativa não localizada.'
      using errcode = '22023';
  end if;

  select p.id
    into v_existing
  from public.skpe_projects p
  where p.organization_id = target_organization_id
    and p.archived_at is null
    and p.status <> 'archived'
  order by p.created_at desc
  limit 1;

  if v_existing is not null then
    return v_existing;
  end if;

  v_base_code := regexp_replace(
    upper(
      coalesce(
        nullif(trim(v_org.code), ''),
        'ORGANIZACAO'
      )
    ),
    '[^A-Z0-9]+',
    '-',
    'g'
  );

  v_code := format(
    'PE-%s-%s',
    trim(both '-' from v_base_code),
    extract(year from current_date)::integer
  );

  while
    exists (
      select 1
      from public.sparks_initiatives si
      where si.organization_id = target_organization_id
        and si.code = v_code
    )
    or exists (
      select 1
      from public.skpe_projects p
      where p.organization_id = target_organization_id
        and p.code = v_code
    )
  loop
    v_suffix := v_suffix + 1;

    v_code := format(
      'PE-%s-%s-%s',
      trim(both '-' from v_base_code),
      extract(year from current_date)::integer,
      v_suffix
    );
  end loop;

  v_project := public.create_skpe_project_from_template(
    target_organization_id,
    v_code,
    coalesce(
      nullif(trim(target_project_name), ''),
      'Planejamento Estratégico de ' ||
      coalesce(
        nullif(trim(v_org.trade_name), ''),
        v_org.legal_name,
        v_org.code
      )
    ),
    'Planejamento Estratégico preparado pela Macrofase de Governança, Abertura e Gestão de Evidências — PEM-00.',
    current_date,
    null,
    null
  );

  update public.skpe_projects
  set
    current_phase_code = 'PEM-00',
    reference_year = extract(year from current_date)::integer,
    status = 'draft',
    updated_at = timezone('utc', now()),
    updated_by = auth.uid()
  where id = v_project;

  update public.skpe_journey_items
  set
    is_current = false,
    updated_at = timezone('utc', now()),
    updated_by = auth.uid()
  where project_id = v_project;

  update public.skpe_journey_items
  set
    status = 'in_progress',
    is_current = true,
    planned_start_date = coalesce(planned_start_date, current_date),
    actual_start_date = coalesce(actual_start_date, current_date),
    updated_at = timezone('utc', now()),
    updated_by = auth.uid()
  where project_id = v_project
    and code = 'PEM-00';

  insert into public.skpe_journey_audit (
    organization_id,
    project_id,
    actor_user_id,
    action_code,
    reason,
    new_data
  )
  values (
    target_organization_id,
    v_project,
    auth.uid(),
    'project_prepared_pem00',
    'Planejamento Estratégico preparado sem antecipar a decisão institucional do Horizonte Estratégico.',
    jsonb_build_object(
      'current_phase_code', 'PEM-00',
      'strategic_horizon_state', 'not_decided'
    )
  );

  return v_project;
end;
$$;

commit;