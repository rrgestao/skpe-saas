-- SK-PE - Consumo do motor transversal de parametros pela Jornada
-- Mantem assinaturas publicas e governanca existentes.

begin;

create or replace function public.initialize_skpe_journey_business_day_baseline(
  p_project_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_project public.skpe_projects%rowtype;
  v_version_id uuid;
  v_existing_id uuid;
  v_leaf_count integer;
  v_index integer := 0;
  v_start_date date;
  v_end_date date;
  v_start_offset integer;
  v_end_offset integer;
  v_item record;
  v_duration_param jsonb;
  v_mode_param jsonb;
  v_accelerated_param jsonb;
  v_followup_param jsonb;
  v_duration integer;
  v_mode text;
begin
  if auth.uid() is null then
    raise exception 'Usuario nao autenticado.' using errcode = '42501';
  end if;

  select * into v_project
  from public.skpe_projects
  where id = p_project_id
    and archived_at is null;

  if v_project.id is null then
    raise exception 'Projeto SK-PE ativo nao encontrado.';
  end if;

  if not public.can_manage_skpe_journey_schedule(v_project.organization_id) then
    raise exception 'Acesso negado para gerenciar o cronograma da Jornada.' using errcode = '42501';
  end if;

  select id into v_existing_id
  from public.skpe_journey_schedule_versions
  where project_id = p_project_id
    and schedule_kind = 'baseline'
    and governance_status in ('draft','pending_approval','approved')
  order by version_number desc
  limit 1;

  if v_existing_id is not null then
    return v_existing_id;
  end if;

  v_duration_param := public.get_sparks_effective_parameter(
    'SKPE.JOURNEY.STANDARD_DURATION', v_project.organization_id, 'SK-PE', v_project.id
  );
  v_mode_param := public.get_sparks_effective_parameter(
    'SKPE.JOURNEY.DURATION_MODE', v_project.organization_id, 'SK-PE', v_project.id
  );
  v_accelerated_param := public.get_sparks_effective_parameter(
    'SKPE.JOURNEY.ACCELERATED_DURATION', v_project.organization_id, 'SK-PE', v_project.id
  );
  v_followup_param := public.get_sparks_effective_parameter(
    'SKPE.JOURNEY.POST_DELIVERY_FOLLOWUP', v_project.organization_id, 'SK-PE', v_project.id
  );

  v_duration := (v_duration_param->>'value')::integer;
  v_mode := v_mode_param->>'value';
  v_start_date := coalesce(v_project.start_date, current_date);
  v_end_date := public.sparks_date_at_offset(v_start_date, v_duration - 1, v_mode);

  update public.skpe_projects
  set target_end_date = v_end_date,
      updated_at = timezone('utc', now()),
      updated_by = auth.uid()
  where id = v_project.id;

  update public.sparks_initiatives si
  set target_end_date = v_end_date,
      updated_at = timezone('utc', now()),
      updated_by = auth.uid()
  from public.skpe_project_initiative_bindings binding
  where binding.skpe_project_id = v_project.id
    and binding.initiative_id = si.id;

  select count(*) into v_leaf_count
  from public.skpe_journey_items ji
  where ji.project_id = p_project_id
    and ji.archived_at is null
    and not exists (
      select 1
      from public.skpe_journey_items child
      where child.parent_item_id = ji.id
        and child.archived_at is null
    );

  if v_leaf_count = 0 then
    raise exception 'A Jornada nao possui itens finais ativos para compor a Linha de Base proposta.';
  end if;

  insert into public.skpe_journey_schedule_versions (
    organization_id, project_id, version_number, schedule_kind,
    governance_status, title, notes, is_current_plan, metadata,
    created_by, updated_by
  ) values (
    v_project.organization_id,
    v_project.id,
    coalesce((select max(version_number) from public.skpe_journey_schedule_versions where project_id = p_project_id), 0) + 1,
    'baseline',
    'draft',
    'Linha de Base Proposta da Jornada Estrategica',
    format('Proposta inicial SPARKs PE em %s %s. Deve ser revisada e aprovada pela Organizacao antes de se tornar compromisso institucional.', v_duration, v_mode),
    false,
    jsonb_build_object(
      'proposal_origin', 'sparks_parameter_engine',
      'duration_value', v_duration,
      'duration_mode', v_mode,
      'parameter_snapshot', jsonb_build_object(
        'standard_duration', v_duration_param,
        'duration_mode', v_mode_param,
        'accelerated_duration', v_accelerated_param,
        'post_delivery_followup', v_followup_param
      ),
      'internal_allocation', 'provisional_equal_leaf_distribution',
      'methodological_detail_status', 'pending_pem_duration_approval'
    ),
    auth.uid(), auth.uid()
  ) returning id into v_version_id;

  for v_item in
    select ji.*
    from public.skpe_journey_items ji
    where ji.project_id = p_project_id
      and ji.archived_at is null
      and not exists (
        select 1
        from public.skpe_journey_items child
        where child.parent_item_id = ji.id
          and child.archived_at is null
      )
    order by ji.display_order, ji.code
  loop
    v_start_offset := floor((v_index * v_duration::numeric) / v_leaf_count)::integer;
    v_end_offset := greatest(
      v_start_offset,
      floor(((v_index + 1) * v_duration::numeric) / v_leaf_count)::integer - 1
    );

    insert into public.skpe_journey_schedule_items (
      organization_id, project_id, schedule_version_id, journey_item_id,
      planned_start_date, planned_end_date, source_mode, planning_note,
      metadata, created_by, updated_by
    ) values (
      v_project.organization_id,
      v_project.id,
      v_version_id,
      v_item.id,
      case when v_item.item_type in ('gate','deliverable') then null
        else public.sparks_date_at_offset(v_start_date, v_start_offset, v_mode) end,
      public.sparks_date_at_offset(v_start_date, v_end_offset, v_mode),
      'derived',
      'Sugestao inicial gerada pelo motor transversal de parametros; distribuicao interna provisoria ate aprovacao da cadencia metodologica por PEM/fase.',
      jsonb_build_object(
        'allocation_status', 'provisional',
        'duration_mode', v_mode,
        'parameter_snapshot_source', 'schedule_version.metadata.parameter_snapshot'
      ),
      auth.uid(), auth.uid()
    );

    v_index := v_index + 1;
  end loop;

  insert into public.skpe_journey_audit (
    organization_id, project_id, journey_item_id, actor_user_id,
    action_code, reason, previous_data, new_data
  ) values (
    v_project.organization_id,
    v_project.id,
    null,
    auth.uid(),
    'journey_baseline_proposal_initialized',
    'Linha de Base Proposta criada automaticamente a partir dos parametros efetivos da Organizacao.',
    null,
    jsonb_build_object(
      'schedule_version_id', v_version_id,
      'governance_status', 'draft',
      'duration_value', v_duration,
      'duration_mode', v_mode,
      'start_date', v_start_date,
      'target_end_date', v_end_date,
      'leaf_count', v_leaf_count,
      'parameter_snapshot', jsonb_build_object(
        'standard_duration', v_duration_param,
        'duration_mode', v_mode_param,
        'accelerated_duration', v_accelerated_param,
        'post_delivery_followup', v_followup_param
      ),
      'internal_allocation', 'provisional_equal_leaf_distribution'
    )
  );

  return v_version_id;
end;
$$;

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
  baseline_version_id uuid;
  base_code text;
  candidate_code text;
  suffix integer := 1;
  journey_target_end_date date;
  duration_parameter jsonb;
  mode_parameter jsonb;
  journey_duration integer;
  journey_duration_mode text;
begin
  if not public.can_manage_skpe_journey(target_organization_id) then
    raise exception 'Acesso negado: o usuario nao pode iniciar o Planejamento Estrategico desta organizacao.' using errcode = '42501';
  end if;
  if target_horizon_start_year is null or target_horizon_end_year is null or target_horizon_end_year < target_horizon_start_year then
    raise exception 'Informe um horizonte estrategico valido.' using errcode = '22023';
  end if;

  select * into organization_record
  from public.organizations
  where id = target_organization_id and status = 'active';

  if organization_record.id is null then
    raise exception 'Organizacao ativa nao localizada.' using errcode = '22023';
  end if;

  select p.id into existing_project_id
  from public.skpe_projects p
  where p.organization_id = target_organization_id
    and p.archived_at is null
    and p.status <> 'archived'
  order by p.created_at desc
  limit 1;

  if existing_project_id is not null then
    return existing_project_id;
  end if;

  duration_parameter := public.get_sparks_effective_parameter(
    'SKPE.JOURNEY.STANDARD_DURATION', target_organization_id, 'SK-PE', null
  );
  mode_parameter := public.get_sparks_effective_parameter(
    'SKPE.JOURNEY.DURATION_MODE', target_organization_id, 'SK-PE', null
  );
  journey_duration := (duration_parameter->>'value')::integer;
  journey_duration_mode := mode_parameter->>'value';

  base_code := regexp_replace(
    upper(coalesce(nullif(trim(organization_record.code), ''), 'ORGANIZACAO')),
    '[^A-Z0-9]+', '-', 'g'
  );
  candidate_code := format('PE-%s-%s', trim(both '-' from base_code), target_horizon_start_year);

  while exists (
    select 1 from public.sparks_initiatives si
    where si.organization_id = target_organization_id and si.code = candidate_code
  ) or exists (
    select 1 from public.skpe_projects p
    where p.organization_id = target_organization_id and p.code = candidate_code
  ) loop
    suffix := suffix + 1;
    candidate_code := format('PE-%s-%s-%s', trim(both '-' from base_code), target_horizon_start_year, suffix);
  end loop;

  journey_target_end_date := public.sparks_date_at_offset(
    current_date, journey_duration - 1, journey_duration_mode
  );

  created_project_id := public.create_skpe_project_from_template(
    target_organization_id,
    candidate_code,
    coalesce(
      nullif(trim(target_project_name), ''),
      'Planejamento Estrategico de ' || coalesce(
        nullif(trim(organization_record.trade_name), ''),
        organization_record.legal_name,
        organization_record.code
      )
    ),
    'Jornada estrategica iniciada pela Metafase de Governanca e Preparacao - PEM-00.',
    current_date,
    journey_target_end_date,
    null
  );

  update public.skpe_projects
  set
    current_phase_code = 'PEM-00',
    planning_horizon_start_year = target_horizon_start_year,
    planning_horizon_end_year = target_horizon_end_year,
    reference_year = target_horizon_start_year,
    review_cycle = 'Revisao anual',
    valid_from = current_date,
    valid_until = make_date(target_horizon_end_year, 12, 31),
    start_date = current_date,
    target_end_date = journey_target_end_date,
    progress = 0,
    status = 'draft',
    updated_at = timezone('utc', now()),
    updated_by = auth.uid()
  where id = created_project_id;

  update public.skpe_journey_items
  set is_current = false,
      updated_at = timezone('utc', now()),
      updated_by = auth.uid()
  where project_id = created_project_id;

  update public.skpe_journey_items
  set status = 'in_progress',
      is_current = true,
      planned_start_date = coalesce(planned_start_date, current_date),
      updated_at = timezone('utc', now()),
      updated_by = auth.uid()
  where project_id = created_project_id
    and code = 'PEM-00';

  baseline_version_id := public.initialize_skpe_journey_business_day_baseline(created_project_id);

  insert into public.skpe_journey_audit (
    organization_id, project_id, actor_user_id,
    action_code, reason, new_data
  ) values (
    target_organization_id,
    created_project_id,
    auth.uid(),
    'project_started_pem00',
    'Planejamento Estrategico iniciado com Horizonte Estrategico separado da janela parametrizada da Jornada.',
    jsonb_build_object(
      'current_phase_code', 'PEM-00',
      'horizon_start_year', target_horizon_start_year,
      'horizon_end_year', target_horizon_end_year,
      'journey_start_date', current_date,
      'journey_target_end_date', journey_target_end_date,
      'journey_duration_value', journey_duration,
      'journey_duration_mode', journey_duration_mode,
      'duration_parameter', duration_parameter,
      'mode_parameter', mode_parameter,
      'baseline_proposal_version_id', baseline_version_id
    )
  );

  return created_project_id;
end;
$$;

comment on function public.initialize_skpe_journey_business_day_baseline(uuid) is
  'Cria Linha de Base Proposta usando os parametros efetivos da Jornada SK-PE e preserva snapshot/proveniencia.';
comment on function public.start_skpe_project_pem00(uuid,text,integer,integer) is
  'Inicia Projeto SK-PE separando Horizonte Estrategico da janela parametrizada da Jornada e cria Linha de Base Proposta.';

commit;
