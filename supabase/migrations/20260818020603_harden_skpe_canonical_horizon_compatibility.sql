-- GATE-17-B.4B.1 — Canonical Horizon Compatibility Hardening
-- Preserve brownfield compatibility while preventing legacy fields from becoming a second source of truth.

create or replace function public.get_skpe_effective_strategic_horizon_period(
  target_project_id uuid,
  target_formulation_id uuid default null
)
returns table (
  strategic_horizon_id uuid,
  period_start date,
  period_end date,
  resolution_source text
)
language plpgsql
stable
set search_path = ''
as $$
declare
  v_project public.skpe_projects%rowtype;
  v_horizon public.skpe_strategic_horizons%rowtype;
  v_formulation public.skpe_strategic_formulations%rowtype;
begin
  select * into v_project
  from public.skpe_projects
  where id = target_project_id
    and archived_at is null;

  if v_project.id is null then
    raise exception 'Projeto SK-PE não encontrado.' using errcode='22023';
  end if;

  select * into v_horizon
  from public.skpe_strategic_horizons
  where project_id = target_project_id
    and is_current = true
    and governance_status in ('approved','historical_recognized')
  order by version_number desc
  limit 1;

  if target_formulation_id is not null then
    select * into v_formulation
    from public.skpe_strategic_formulations
    where id = target_formulation_id
      and project_id = target_project_id;

    if v_formulation.id is null then
      raise exception 'Formulação Estratégica não encontrada neste projeto.' using errcode='22023';
    end if;
  end if;

  strategic_horizon_id := v_horizon.id;

  if v_horizon.id is not null then
    period_start := coalesce(
      v_formulation.valid_from,
      v_horizon.valid_from,
      make_date(v_horizon.horizon_start_year, 1, 1)
    );
    period_end := coalesce(
      v_formulation.valid_until,
      v_horizon.valid_until,
      make_date(v_horizon.horizon_end_year, 12, 31)
    );
    resolution_source := case
      when target_formulation_id is not null
           and (v_formulation.valid_from is not null or v_formulation.valid_until is not null)
        then 'formulation_with_canonical_horizon'
      else 'canonical_strategic_horizon'
    end;
  elsif target_formulation_id is not null
        and (v_formulation.valid_from is not null or v_formulation.valid_until is not null) then
    period_start := v_formulation.valid_from;
    period_end := v_formulation.valid_until;
    resolution_source := 'formulation_without_approved_horizon';
  else
    period_start := null;
    period_end := null;
    resolution_source := 'strategic_horizon_not_decided';
  end if;

  return next;
end;
$$;

revoke all on function public.get_skpe_effective_strategic_horizon_period(uuid,uuid) from public, anon;
grant execute on function public.get_skpe_effective_strategic_horizon_period(uuid,uuid) to authenticated, service_role;

create or replace function public.skpe_guard_project_horizon_projection()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_horizon public.skpe_strategic_horizons%rowtype;
begin
  select * into v_horizon
  from public.skpe_strategic_horizons
  where project_id = new.id
    and is_current = true
    and governance_status in ('approved','historical_recognized')
  order by version_number desc
  limit 1;

  if v_horizon.id is null then
    if new.planning_horizon_start_year is not null
       or new.planning_horizon_end_year is not null then
      raise exception using
        errcode='55000',
        message='Os campos legados de Horizonte em skpe_projects são somente projeção de compatibilidade e não podem ser definidos antes de existir Horizonte Estratégico vigente.';
    end if;
    return new;
  end if;

  if new.planning_horizon_start_year is distinct from v_horizon.horizon_start_year
     or new.planning_horizon_end_year is distinct from v_horizon.horizon_end_year then
    raise exception using
      errcode='55000',
      message='A projeção legada do Horizonte em skpe_projects deve permanecer sincronizada com o Horizonte Estratégico canônico.';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_skpe_guard_project_horizon_projection on public.skpe_projects;

create trigger trg_skpe_guard_project_horizon_projection
before insert or update of planning_horizon_start_year, planning_horizon_end_year
on public.skpe_projects
for each row execute function public.skpe_guard_project_horizon_projection();

create or replace function public.start_skpe_project_pem00(
  target_organization_id uuid,
  target_project_name text default null,
  target_horizon_start_year integer default (extract(year from current_date))::integer,
  target_horizon_end_year integer default ((extract(year from current_date))::integer + 4)
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_project uuid;
begin
  -- Compatibility adapter only. Horizon parameters are intentionally ignored.
  -- The Strategic Horizon is proposed and institutionally decided later, at PEM-01.GATE.
  v_project := public.prepare_skpe_project(
    target_organization_id,
    target_project_name
  );

  insert into public.skpe_journey_audit(
    organization_id,
    project_id,
    actor_user_id,
    action_code,
    reason,
    new_data
  ) values (
    target_organization_id,
    v_project,
    auth.uid(),
    'legacy_project_start_adapter_used',
    'RPC legada preservada por compatibilidade; parâmetros automáticos de Horizonte foram ignorados para não antecipar decisão institucional.',
    jsonb_build_object(
      'legacy_requested_horizon_start_year', target_horizon_start_year,
      'legacy_requested_horizon_end_year', target_horizon_end_year,
      'canonical_horizon_state', 'not_decided',
      'gate', '17-B.4B.1'
    )
  );

  return v_project;
end;
$$;

revoke all on function public.start_skpe_project_pem00(uuid,text,integer,integer) from public, anon;
grant execute on function public.start_skpe_project_pem00(uuid,text,integer,integer) to authenticated, service_role;

create or replace function public.decide_skpe_strategic_horizon(
  target_proposal_id uuid,
  decision_outcome text,
  decision_reason text,
  reservations text,
  adjustment_requirements text,
  change_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_proposal public.skpe_strategic_horizon_proposals%rowtype;
  v_project public.skpe_projects%rowtype;
  v_gate public.skpe_journey_items%rowtype;
  v_pem01 public.skpe_journey_items%rowtype;
  v_prev_decision uuid;
  v_prev_sequence integer;
  v_decision uuid;
  v_prev_horizon public.skpe_strategic_horizons%rowtype;
  v_horizon uuid;
  v_horizon_version integer;
begin
  perform public.skpe_assert_reason(change_reason);

  if decision_outcome not in ('approved','approved_with_reservations','returned_for_adjustment') then
    raise exception 'Resultado de decisão inválido para Horizonte Estratégico.' using errcode='22023';
  end if;

  if decision_outcome='approved_with_reservations'
     and nullif(trim(reservations),'') is null then
    raise exception 'Aprovação com ressalvas exige descrição das ressalvas.' using errcode='22023';
  end if;

  if decision_outcome='returned_for_adjustment'
     and nullif(trim(adjustment_requirements),'') is null then
    raise exception 'Retorno para ajuste exige requisitos de ajuste.' using errcode='22023';
  end if;

  select *
  into v_proposal
  from public.skpe_strategic_horizon_proposals
  where id=target_proposal_id
  for update;

  if v_proposal.id is null then
    raise exception 'Proposta de Horizonte Estratégico não encontrada.' using errcode='22023';
  end if;

  if v_proposal.status not in ('proposed','under_review') then
    raise exception 'A proposta precisa estar submetida ou em revisão para decisão institucional.' using errcode='55000';
  end if;

  if not public.can_ratify_skpe_governance(v_proposal.organization_id) then
    raise exception 'Acesso negado: o usuário não possui permissão para deliberar o Horizonte Estratégico.' using errcode='42501';
  end if;

  select *
  into v_project
  from public.skpe_projects
  where id=v_proposal.project_id
    and archived_at is null
  for update;

  if v_project.id is null then
    raise exception 'Projeto SK-PE não encontrado.' using errcode='22023';
  end if;

  select *
  into v_gate
  from public.skpe_journey_items
  where project_id=v_project.id
    and code='PEM-01.GATE'
    and item_type='gate'
  limit 1;

  select *
  into v_pem01
  from public.skpe_journey_items
  where project_id=v_project.id
    and code='PEM-01'
    and item_type='macrophase'
  limit 1;

  if v_gate.id is null or v_pem01.id is null then
    raise exception 'Estrutura PEM-01/PEM-01.GATE não localizada no projeto.' using errcode='55000';
  end if;

  if not (
    (v_pem01.status='completed' and v_pem01.progress=100)
    or v_gate.status in ('in_progress','completed')
  ) then
    raise exception 'O Horizonte Estratégico só pode ser deliberado no fechamento do Diagnóstico Estratégico.' using errcode='55000';
  end if;

  select id, decision_sequence
  into v_prev_decision, v_prev_sequence
  from public.skpe_gate_decisions
  where project_id=v_project.id
    and gate_journey_item_id=v_gate.id
  order by decision_sequence desc
  limit 1;

  insert into public.skpe_gate_decisions(
    organization_id,
    project_id,
    gate_journey_item_id,
    decision_outcome,
    decision_reason,
    reservations,
    adjustment_requirements,
    readiness_snapshot,
    decision_context,
    supersedes_decision_id,
    decision_sequence,
    decided_at,
    decided_by,
    decision_origin_type,
    decided_by_actor_type,
    decision_time_precision,
    metadata
  ) values(
    v_project.organization_id,
    v_project.id,
    v_gate.id,
    decision_outcome,
    decision_reason,
    case
      when decision_outcome='approved_with_reservations'
      then nullif(trim(reservations),'')
    end,
    case
      when decision_outcome='returned_for_adjustment'
      then nullif(trim(adjustment_requirements),'')
    end,
    jsonb_build_object(
      'pem01_status',v_pem01.status,
      'pem01_progress',v_pem01.progress,
      'gate_status',v_gate.status
    ),
    jsonb_build_object(
      'decision_kind','strategic_horizon',
      'proposal_id',v_proposal.id,
      'proposed_start_year',v_proposal.proposed_start_year,
      'proposed_end_year',v_proposal.proposed_end_year
    ),
    v_prev_decision,
    coalesce(v_prev_sequence,0)+1,
    timezone('utc',now()),
    auth.uid(),
    'native_platform',
    'organization',
    'exact_datetime',
    jsonb_build_object('gate','17-B.4B.1')
  )
  returning id into v_decision;

  if decision_outcome='returned_for_adjustment' then
    update public.skpe_strategic_horizon_proposals
    set status='adjusted',
        updated_at=timezone('utc',now()),
        updated_by=auth.uid()
    where id=v_proposal.id;

    insert into public.skpe_journey_audit(
      organization_id,
      project_id,
      actor_user_id,
      action_code,
      reason,
      new_data
    )
    values(
      v_project.organization_id,
      v_project.id,
      auth.uid(),
      'strategic_horizon_returned_for_adjustment',
      change_reason,
      jsonb_build_object(
        'proposal_id',v_proposal.id,
        'gate_decision_id',v_decision,
        'adjustment_requirements',adjustment_requirements
      )
    );

    return jsonb_build_object(
      'proposal_id',v_proposal.id,
      'gate_decision_id',v_decision,
      'decision_outcome',decision_outcome,
      'horizon_id',null
    );
  end if;

  update public.skpe_strategic_horizon_proposals
  set status='approved',
      updated_at=timezone('utc',now()),
      updated_by=auth.uid()
  where id=v_proposal.id;

  select *
  into v_prev_horizon
  from public.skpe_strategic_horizons
  where project_id=v_project.id
    and is_current=true
  for update;

  if v_prev_horizon.id is not null then
    update public.skpe_strategic_horizons
    set is_current=false,
        governance_status='superseded',
        superseded_at=timezone('utc',now()),
        superseded_by=auth.uid(),
        updated_at=timezone('utc',now()),
        updated_by=auth.uid()
    where id=v_prev_horizon.id;
  end if;

  select coalesce(max(version_number),0)+1
  into v_horizon_version
  from public.skpe_strategic_horizons
  where project_id=v_project.id;

  insert into public.skpe_strategic_horizons(
    organization_id,
    project_id,
    proposal_id,
    version_number,
    horizon_start_year,
    horizon_end_year,
    valid_from,
    valid_until,
    governance_status,
    is_current,
    decision_origin_type,
    decision_gate_id,
    source_reference,
    regularization_status,
    supersedes_horizon_id,
    metadata,
    approved_at,
    approved_by,
    created_by,
    updated_by
  ) values(
    v_project.organization_id,
    v_project.id,
    v_proposal.id,
    v_horizon_version,
    v_proposal.proposed_start_year,
    v_proposal.proposed_end_year,
    current_date,
    make_date(v_proposal.proposed_end_year,12,31),
    'approved',
    true,
    'native_platform',
    v_decision,
    v_proposal.source_reference,
    'not_required',
    v_prev_horizon.id,
    jsonb_build_object(
      'gate','17-B.4B.1',
      'proposal_version',v_proposal.version_number
    ),
    timezone('utc',now()),
    auth.uid(),
    auth.uid(),
    auth.uid()
  )
  returning id into v_horizon;

  -- Compatibility projection only. Cadence/review_cycle is intentionally not inferred from Horizon approval.
  update public.skpe_projects
  set planning_horizon_start_year=v_proposal.proposed_start_year,
      planning_horizon_end_year=v_proposal.proposed_end_year,
      reference_year=coalesce(reference_year,v_proposal.proposed_start_year),
      valid_from=current_date,
      valid_until=make_date(v_proposal.proposed_end_year,12,31),
      updated_at=timezone('utc',now()),
      updated_by=auth.uid()
  where id=v_project.id;

  insert into public.skpe_journey_audit(
    organization_id,
    project_id,
    actor_user_id,
    action_code,
    reason,
    new_data
  )
  values(
    v_project.organization_id,
    v_project.id,
    auth.uid(),
    'strategic_horizon_approved',
    change_reason,
    jsonb_build_object(
      'proposal_id',v_proposal.id,
      'gate_decision_id',v_decision,
      'horizon_id',v_horizon,
      'start_year',v_proposal.proposed_start_year,
      'end_year',v_proposal.proposed_end_year,
      'review_cycle_inferred',false
    )
  );

  return jsonb_build_object(
    'proposal_id',v_proposal.id,
    'gate_decision_id',v_decision,
    'decision_outcome',decision_outcome,
    'horizon_id',v_horizon
  );
end;
$$;

revoke all on function public.decide_skpe_strategic_horizon(uuid,text,text,text,text,text) from public, anon;
grant execute on function public.decide_skpe_strategic_horizon(uuid,text,text,text,text,text) to authenticated, service_role;