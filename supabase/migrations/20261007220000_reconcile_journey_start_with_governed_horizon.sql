-- V1-B02: reconcile Journey start with governed Strategic Horizon lifecycle.
-- Starting PEM-00 creates only a Horizon proposal; legacy project horizon fields remain
-- null until institutional approval at the governed PEM-01 decision point.

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
as $function$
declare
  organization_record public.organizations%rowtype;
  existing_project_id uuid;
  created_project_id uuid;
  baseline_version_id uuid;
  horizon_proposal_id uuid;
  base_code text;
  candidate_code text;
  suffix integer := 1;
  journey_target_end_date date;
  cadence_snapshot jsonb;
  journey_duration integer;
  journey_duration_mode text;
begin
  if not public.can_manage_skpe_journey(target_organization_id) then
    raise exception 'Acesso negado: o usuario nao pode iniciar o Planejamento Estrategico desta organizacao.' using errcode='42501';
  end if;

  if target_horizon_start_year is null
     or target_horizon_end_year is null
     or target_horizon_end_year < target_horizon_start_year then
    raise exception 'Informe um horizonte estrategico valido.' using errcode='22023';
  end if;

  select *
    into organization_record
  from public.organizations
  where id=target_organization_id
    and status='active';

  if organization_record.id is null then
    raise exception 'Organizacao ativa nao localizada.' using errcode='22023';
  end if;

  select p.id
    into existing_project_id
  from public.skpe_projects p
  where p.organization_id=target_organization_id
    and p.archived_at is null
    and p.status <> 'archived'
  order by p.created_at desc
  limit 1;

  if existing_project_id is not null then
    return existing_project_id;
  end if;

  cadence_snapshot := public.get_skpe_journey_cadence_snapshot(target_organization_id,null);
  journey_duration := (cadence_snapshot->>'implementation_total')::int;
  journey_duration_mode := cadence_snapshot->'duration_mode'->>'value';

  base_code := regexp_replace(
    upper(coalesce(nullif(trim(organization_record.code),''),'ORGANIZACAO')),
    '[^A-Z0-9]+','-','g'
  );
  candidate_code := format(
    'PE-%s-%s',
    trim(both '-' from base_code),
    target_horizon_start_year
  );

  while exists (
    select 1 from public.sparks_initiatives si
    where si.organization_id=target_organization_id
      and si.code=candidate_code
  ) or exists (
    select 1 from public.skpe_projects p
    where p.organization_id=target_organization_id
      and p.code=candidate_code
  ) loop
    suffix := suffix + 1;
    candidate_code := format(
      'PE-%s-%s-%s',
      trim(both '-' from base_code),
      target_horizon_start_year,
      suffix
    );
  end loop;

  journey_target_end_date := public.sparks_date_at_offset(
    current_date,
    journey_duration-1,
    journey_duration_mode
  );

  created_project_id := public.create_skpe_project_from_template(
    target_organization_id,
    candidate_code,
    coalesce(
      nullif(trim(target_project_name),''),
      'Planejamento Estrategico de ' || coalesce(
        nullif(trim(organization_record.trade_name),''),
        organization_record.legal_name,
        organization_record.code
      )
    ),
    'Jornada estrategica iniciada pela Metafase de Governanca e Preparacao - PEM-00.',
    current_date,
    journey_target_end_date,
    null
  );

  -- Project execution context is established now. Horizon compatibility fields
  -- are intentionally untouched until a governed Horizon is institutionally approved.
  update public.skpe_projects
  set current_phase_code='PEM-00',
      start_date=current_date,
      target_end_date=journey_target_end_date,
      progress=0,
      status='draft',
      updated_at=timezone('utc',now()),
      updated_by=auth.uid()
  where id=created_project_id;

  horizon_proposal_id := public.upsert_skpe_strategic_horizon_proposal(
    created_project_id,
    null,
    target_horizon_start_year,
    target_horizon_end_year,
    'system',
    'Sugestao inicial de Horizonte Estrategico apresentada no inicio da Jornada; depende de analise e deliberacao institucional governada.',
    'start_skpe_project_pem00',
    'Registro da proposta inicial de Horizonte sem aprovacao institucional antecipada.'
  );

  update public.skpe_journey_items
  set is_current=false,
      updated_at=timezone('utc',now()),
      updated_by=auth.uid()
  where project_id=created_project_id;

  update public.skpe_journey_items
  set status='in_progress',
      is_current=true,
      planned_start_date=coalesce(planned_start_date,current_date),
      updated_at=timezone('utc',now()),
      updated_by=auth.uid()
  where project_id=created_project_id
    and code='PEM-00';

  baseline_version_id := public.initialize_skpe_journey_business_day_baseline(created_project_id);

  insert into public.skpe_journey_audit (
    organization_id,
    project_id,
    actor_user_id,
    action_code,
    reason,
    new_data
  ) values (
    target_organization_id,
    created_project_id,
    auth.uid(),
    'project_started_pem00',
    'Planejamento Estrategico iniciado com proposta de Horizonte separada da cadencia parametrizada por Megafase.',
    jsonb_build_object(
      'current_phase_code','PEM-00',
      'horizon_proposal_id',horizon_proposal_id,
      'proposed_horizon_start_year',target_horizon_start_year,
      'proposed_horizon_end_year',target_horizon_end_year,
      'horizon_governance_status','draft',
      'legacy_horizon_projection_written',false,
      'journey_start_date',current_date,
      'journey_target_end_date',journey_target_end_date,
      'journey_duration_value',journey_duration,
      'journey_duration_mode',journey_duration_mode,
      'cadence_matrix_version','SPARKs PE v1',
      'cadence_snapshot',cadence_snapshot,
      'baseline_proposal_version_id',baseline_version_id
    )
  );

  return created_project_id;
end;
$function$;

comment on function public.start_skpe_project_pem00(uuid,text,integer,integer) is
  'Inicia PEM-00, registra Horizonte apenas como proposta governada e cria Linha de Base Proposta; projeção legada de Horizonte só existe após aprovação institucional.';
