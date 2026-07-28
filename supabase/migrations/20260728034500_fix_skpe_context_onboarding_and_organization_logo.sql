-- ============================================================
-- Plataforma SPARKs / SK-PE
-- Correções críticas:
-- 1) isolamento do contexto estratégico por organização;
-- 2) onboarding de projeto pela PEM-00;
-- 3) identidade visual na Administração Global.
-- ============================================================

begin;

-- ------------------------------------------------------------
-- 1. Contexto estratégico estritamente vinculado à organização.
-- ------------------------------------------------------------
create or replace function public.get_skpe_project_context(
  target_organization_id uuid
)
returns table (
  project_id uuid,
  project_code text,
  project_name text,
  project_status text,
  project_progress numeric,
  current_phase_code text,
  planning_horizon_start_year integer,
  planning_horizon_end_year integer,
  reference_year integer,
  review_cycle text,
  valid_from date,
  valid_until date
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.can_view_skpe_journey(target_organization_id) then
    raise exception
      'Acesso negado: o usuário não pode consultar o contexto estratégico desta organização.'
      using errcode = '42501';
  end if;

  return query
  select
    p.id,
    p.code,
    p.name,
    p.status,
    p.progress,
    p.current_phase_code,
    p.planning_horizon_start_year,
    p.planning_horizon_end_year,
    p.reference_year,
    p.review_cycle,
    p.valid_from,
    p.valid_until
  from public.skpe_projects p
  where p.organization_id = target_organization_id
    and p.archived_at is null
    and p.status <> 'archived'
  order by p.created_at desc
  limit 1;
end;
$$;

-- ------------------------------------------------------------
-- 2. Início controlado da jornada pela Metafase PEM-00.
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
    raise exception 'Informe um horizonte estratégico válido.';
  end if;

  select *
    into organization_record
  from public.organizations
  where id = target_organization_id
    and status = 'active';

  if organization_record.id is null then
    raise exception 'Organização ativa não localizada.';
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
    upper(coalesce(nullif(trim(organization_record.code), ''), 'ORGANIZACAO')),
    '[^A-Z0-9]+',
    '-',
    'g'
  );

  candidate_code := format('PE-%s-%s', trim(both '-' from base_code), target_horizon_start_year);

  while exists (
    select 1
    from public.skpe_projects p
    where p.organization_id = target_organization_id
      and p.code = candidate_code
  ) loop
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
      'Planejamento Estratégico de ' || coalesce(
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
-- 3. Identidade visual na Administração Global.
-- ------------------------------------------------------------
create or replace function public.get_platform_admin_organization_branding(
  target_organization_id uuid
)
returns table (
  logo_url text,
  logo_storage_path text,
  logo_version integer
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public.require_platform_super_admin();

  return query
  select
    o.logo_url,
    o.logo_storage_path,
    coalesce(o.logo_version, 0)
  from public.organizations o
  where o.id = target_organization_id;
end;
$$;

create or replace function public.set_platform_admin_organization_logo(
  target_organization_id uuid,
  target_logo_storage_path text,
  change_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_path text;
begin
  perform public.require_platform_super_admin();

  if change_reason is null or length(trim(change_reason)) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.';
  end if;

  if target_logo_storage_path is null
     or target_logo_storage_path !~ ('^' || target_organization_id::text || '/logo/') then
    raise exception 'O caminho da logo não pertence à organização informada.';
  end if;

  select logo_storage_path
    into previous_path
  from public.organizations
  where id = target_organization_id
  for update;

  if not found then
    raise exception 'Organização não localizada.';
  end if;

  update public.organizations
  set
    logo_url = null,
    logo_storage_path = target_logo_storage_path,
    logo_version = coalesce(logo_version, 0) + 1,
    visual_identity_metadata = coalesce(visual_identity_metadata, '{}'::jsonb)
      || jsonb_build_object(
        'logo_updated_at', timezone('utc', now()),
        'logo_updated_by', auth.uid(),
        'previous_logo_storage_path', previous_path
      ),
    institutional_profile_updated_at = timezone('utc', now()),
    institutional_profile_updated_by = auth.uid(),
    updated_at = timezone('utc', now()),
    updated_by = auth.uid()
  where id = target_organization_id;

  if to_regclass('public.privileged_access_audit') is not null then
    insert into public.privileged_access_audit (
      actor_user_id,
      organization_id,
      event_type,
      event_description,
      entity_schema,
      entity_table,
      entity_id,
      previous_data,
      new_data,
      metadata
    )
    values (
      auth.uid(),
      target_organization_id,
      'configuration_changed',
      trim(change_reason),
      'public',
      'organizations',
      target_organization_id::text,
      jsonb_build_object('logo_storage_path', previous_path),
      jsonb_build_object('logo_storage_path', target_logo_storage_path),
      jsonb_build_object('source', 'platform_admin')
    );
  end if;
end;
$$;

revoke all on function public.get_skpe_project_context(uuid) from public, anon;
revoke all on function public.start_skpe_project_pem00(uuid,text,integer,integer) from public, anon;
revoke all on function public.get_platform_admin_organization_branding(uuid) from public, anon;
revoke all on function public.set_platform_admin_organization_logo(uuid,text,text) from public, anon;

grant execute on function public.get_skpe_project_context(uuid) to authenticated, service_role;
grant execute on function public.start_skpe_project_pem00(uuid,text,integer,integer) to authenticated, service_role;
grant execute on function public.get_platform_admin_organization_branding(uuid) to authenticated, service_role;
grant execute on function public.set_platform_admin_organization_logo(uuid,text,text) to authenticated, service_role;

commit;

select
  'OK' as status,
  'Contexto isolado, onboarding PEM-00 e identidade visual global preparados.' as resultado;
