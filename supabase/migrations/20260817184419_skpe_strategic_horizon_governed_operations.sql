alter table public.skpe_strategic_horizon_proposals
  drop constraint if exists skpe_strategic_horizon_proposals_status_check;

alter table public.skpe_strategic_horizon_proposals
  add constraint skpe_strategic_horizon_proposals_status_check
  check (status = any (array[
    'draft','proposed','under_review','approved','adjusted','deferred','rejected','superseded'
  ]));

drop index if exists public.ux_skpe_strategic_horizon_proposals_open;
create unique index ux_skpe_strategic_horizon_proposals_open
  on public.skpe_strategic_horizon_proposals (project_id)
  where status in ('draft','proposed','under_review','adjusted','deferred');

create or replace function public.skpe_validate_strategic_horizon_proposal_context()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_project_org uuid;
  v_previous_project uuid;
  v_previous_org uuid;
begin
  select organization_id into v_project_org
  from public.skpe_projects
  where id = new.project_id and archived_at is null;

  if v_project_org is null then
    raise exception using errcode='22023', message='Projeto SK-PE nÃ£o encontrado para a proposta de horizonte.';
  end if;

  if v_project_org <> new.organization_id then
    raise exception using errcode='22023', message='A organizaÃ§Ã£o da proposta de horizonte diverge da organizaÃ§Ã£o do projeto.';
  end if;

  if new.supersedes_proposal_id is not null then
    if new.supersedes_proposal_id = new.id then
      raise exception using errcode='22023', message='Uma proposta de horizonte nÃ£o pode substituir a si mesma.';
    end if;

    select project_id, organization_id
      into v_previous_project, v_previous_org
    from public.skpe_strategic_horizon_proposals
    where id = new.supersedes_proposal_id;

    if v_previous_project is null
       or v_previous_project <> new.project_id
       or v_previous_org <> new.organization_id then
      raise exception using errcode='22023', message='A proposta substituÃ­da pertence a outro projeto ou organizaÃ§Ã£o.';
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.skpe_validate_strategic_horizon_context()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_project_org uuid;
  v_proposal_project uuid;
  v_proposal_org uuid;
  v_proposal_status text;
  v_gate_project uuid;
  v_gate_org uuid;
  v_gate_outcome text;
  v_gate_code text;
  v_previous_project uuid;
  v_previous_org uuid;
begin
  select organization_id into v_project_org
  from public.skpe_projects
  where id = new.project_id and archived_at is null;

  if v_project_org is null then
    raise exception using errcode='22023', message='Projeto SK-PE nÃ£o encontrado para o horizonte estratÃ©gico.';
  end if;

  if v_project_org <> new.organization_id then
    raise exception using errcode='22023', message='A organizaÃ§Ã£o do horizonte diverge da organizaÃ§Ã£o do projeto.';
  end if;

  if new.proposal_id is not null then
    select project_id, organization_id, status
      into v_proposal_project, v_proposal_org, v_proposal_status
    from public.skpe_strategic_horizon_proposals
    where id = new.proposal_id;

    if v_proposal_project is null
       or v_proposal_project <> new.project_id
       or v_proposal_org <> new.organization_id then
      raise exception using errcode='22023', message='A proposta vinculada ao horizonte pertence a outro projeto ou organizaÃ§Ã£o.';
    end if;

    if new.governance_status = 'approved' and v_proposal_status <> 'approved' then
      raise exception using errcode='55000', message='Horizonte aprovado exige proposta de horizonte aprovada.';
    end if;
  end if;

  if new.decision_gate_id is not null then
    select gd.project_id, gd.organization_id, gd.decision_outcome, ji.code
      into v_gate_project, v_gate_org, v_gate_outcome, v_gate_code
    from public.skpe_gate_decisions gd
    join public.skpe_journey_items ji on ji.id = gd.gate_journey_item_id
    where gd.id = new.decision_gate_id;

    if v_gate_project is null
       or v_gate_project <> new.project_id
       or v_gate_org <> new.organization_id then
      raise exception using errcode='22023', message='A decisÃ£o vinculada ao horizonte pertence a outro projeto ou organizaÃ§Ã£o.';
    end if;

    if new.decision_origin_type = 'native_platform' then
      if v_gate_code <> 'PEM-01.GATE' then
        raise exception using errcode='55000', message='Horizonte nativo deve ser deliberado no PEM-01.GATE.';
      end if;
      if v_gate_outcome not in ('approved','approved_with_reservations') then
        raise exception using errcode='55000', message='Horizonte nativo vigente exige decisÃ£o favorÃ¡vel no PEM-01.GATE.';
      end if;
    end if;
  elsif new.decision_origin_type = 'native_platform' and new.governance_status = 'approved' then
    raise exception using errcode='55000', message='Horizonte nativo aprovado exige decisÃ£o institucional vinculada.';
  end if;

  if new.supersedes_horizon_id is not null then
    if new.supersedes_horizon_id = new.id then
      raise exception using errcode='22023', message='Um horizonte nÃ£o pode substituir a si mesmo.';
    end if;

    select project_id, organization_id
      into v_previous_project, v_previous_org
    from public.skpe_strategic_horizons
    where id = new.supersedes_horizon_id;

    if v_previous_project is null
       or v_previous_project <> new.project_id
       or v_previous_org <> new.organization_id then
      raise exception using errcode='22023', message='O horizonte substituÃ­do pertence a outro projeto ou organizaÃ§Ã£o.';
    end if;
  end if;

  if new.is_current and new.governance_status not in ('approved','historical_recognized') then
    raise exception using errcode='55000', message='Somente horizonte aprovado ou histÃ³rico reconhecido pode ser vigente.';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_skpe_validate_strategic_horizon_proposal_context on public.skpe_strategic_horizon_proposals;
create trigger trg_skpe_validate_strategic_horizon_proposal_context
before insert or update on public.skpe_strategic_horizon_proposals
for each row execute function public.skpe_validate_strategic_horizon_proposal_context();

drop trigger if exists trg_skpe_validate_strategic_horizon_context on public.skpe_strategic_horizons;
create trigger trg_skpe_validate_strategic_horizon_context
before insert or update on public.skpe_strategic_horizons
for each row execute function public.skpe_validate_strategic_horizon_context();

create or replace function public.get_skpe_strategic_horizon_context(
  target_organization_id uuid,
  target_project_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_project public.skpe_projects%rowtype;
  v_current_horizon jsonb;
  v_open_proposal jsonb;
begin
  if not public.can_view_skpe_journey(target_organization_id) then
    raise exception 'Acesso negado ao contexto do horizonte estratÃ©gico.' using errcode='42501';
  end if;

  select * into v_project
  from public.skpe_projects
  where id = target_project_id
    and organization_id = target_organization_id
    and archived_at is null;

  if v_project.id is null then
    raise exception 'Projeto SK-PE nÃ£o encontrado.' using errcode='22023';
  end if;

  select to_jsonb(h) into v_current_horizon
  from public.skpe_strategic_horizons h
  where h.project_id = target_project_id and h.is_current = true
  limit 1;

  select to_jsonb(p) into v_open_proposal
  from public.skpe_strategic_horizon_proposals p
  where p.project_id = target_project_id
    and p.status in ('draft','proposed','under_review','adjusted','deferred')
  order by p.version_number desc
  limit 1;

  return jsonb_build_object(
    'project_id', v_project.id,
    'organization_id', v_project.organization_id,
    'project_code', v_project.code,
    'project_status', v_project.status,
    'current_phase_code', v_project.current_phase_code,
    'project_progress', v_project.progress,
    'compatibility_projection', jsonb_build_object(
      'planning_horizon_start_year', v_project.planning_horizon_start_year,
      'planning_horizon_end_year', v_project.planning_horizon_end_year,
      'reference_year', v_project.reference_year,
      'review_cycle', v_project.review_cycle,
      'valid_from', v_project.valid_from,
      'valid_until', v_project.valid_until
    ),
    'current_horizon', v_current_horizon,
    'open_proposal', v_open_proposal
  );
end;
$$;

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
    raise exception 'Acesso negado: o usuÃ¡rio nÃ£o pode preparar o Planejamento EstratÃ©gico desta organizaÃ§Ã£o.' using errcode='42501';
  end if;

  select * into v_org from public.organizations
  where id = target_organization_id and status = 'active';
  if v_org.id is null then
    raise exception 'OrganizaÃ§Ã£o ativa nÃ£o localizada.' using errcode='22023';
  end if;

  select id into v_existing
  from public.skpe_projects
  where organization_id = target_organization_id
    and archived_at is null and status <> 'archived'
  order by created_at desc limit 1;
  if v_existing is not null then return v_existing; end if;

  v_base_code := regexp_replace(upper(coalesce(nullif(trim(v_org.code),''),'ORGANIZACAO')),'[^A-Z0-9]+','-','g');
  v_code := format('PE-%s-%s', trim(both '-' from v_base_code), extract(year from current_date)::integer);
  while exists(select 1 from public.skpe_projects where organization_id=target_organization_id and code=v_code) loop
    v_suffix := v_suffix + 1;
    v_code := format('PE-%s-%s-%s', trim(both '-' from v_base_code), extract(year from current_date)::integer, v_suffix);
  end loop;

  v_project := public.create_skpe_project_from_template(
    target_organization_id,
    v_code,
    coalesce(nullif(trim(target_project_name),''), 'Planejamento EstratÃ©gico de ' || coalesce(nullif(trim(v_org.trade_name),''), v_org.legal_name, v_org.code)),
    'Planejamento EstratÃ©gico preparado pela Macrofase de GovernanÃ§a, Abertura e GestÃ£o de EvidÃªncias â€” PEM-00.',
    current_date,
    null,
    null
  );

  update public.skpe_projects
  set current_phase_code='PEM-00', reference_year=extract(year from current_date)::integer,
      status='draft', updated_at=timezone('utc',now()), updated_by=auth.uid()
  where id=v_project;

  update public.skpe_journey_items
  set is_current=false, updated_at=timezone('utc',now()), updated_by=auth.uid()
  where project_id=v_project;

  update public.skpe_journey_items
  set status='in_progress', is_current=true,
      planned_start_date=coalesce(planned_start_date,current_date),
      actual_start_date=coalesce(actual_start_date,current_date),
      updated_at=timezone('utc',now()), updated_by=auth.uid()
  where project_id=v_project and code='PEM-00';

  insert into public.skpe_journey_audit(organization_id,project_id,actor_user_id,action_code,reason,new_data)
  values(target_organization_id,v_project,auth.uid(),'project_prepared_pem00',
    'Planejamento EstratÃ©gico preparado sem antecipar a decisÃ£o institucional do Horizonte EstratÃ©gico.',
    jsonb_build_object('current_phase_code','PEM-00','strategic_horizon_state','not_decided'));

  return v_project;
end;
$$;

create or replace function public.upsert_skpe_strategic_horizon_proposal(
  target_project_id uuid,
  target_proposal_id uuid,
  proposed_start_year integer,
  proposed_end_year integer,
  proposal_origin_type text,
  proposal_rationale text,
  proposal_source_reference text,
  change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_project public.skpe_projects%rowtype;
  v_proposal public.skpe_strategic_horizon_proposals%rowtype;
  v_id uuid;
  v_version integer;
begin
  perform public.skpe_assert_reason(change_reason);

  select * into v_project from public.skpe_projects where id=target_project_id and archived_at is null for update;
  if v_project.id is null then raise exception 'Projeto SK-PE nÃ£o encontrado.' using errcode='22023'; end if;
  if not public.can_manage_skpe_governance(v_project.organization_id) then
    raise exception 'Acesso negado Ã  gestÃ£o da proposta de Horizonte EstratÃ©gico.' using errcode='42501';
  end if;
  if proposed_start_year is null or proposed_end_year is null or proposed_end_year < proposed_start_year then
    raise exception 'Informe um Horizonte EstratÃ©gico vÃ¡lido.' using errcode='22023';
  end if;
  if proposal_origin_type not in ('consultancy_suggestion','organization','diagnostic','historical_import','system') then
    raise exception 'Origem da proposta de Horizonte EstratÃ©gico invÃ¡lida.' using errcode='22023';
  end if;

  if target_proposal_id is null then
    if exists(select 1 from public.skpe_strategic_horizon_proposals where project_id=target_project_id and status in ('draft','proposed','under_review','adjusted','deferred')) then
      raise exception 'JÃ¡ existe proposta de Horizonte EstratÃ©gico em aberto para este projeto.' using errcode='55000';
    end if;
    select coalesce(max(version_number),0)+1 into v_version from public.skpe_strategic_horizon_proposals where project_id=target_project_id;
    insert into public.skpe_strategic_horizon_proposals(
      organization_id,project_id,version_number,status,proposed_start_year,proposed_end_year,origin_type,rationale,source_reference,metadata,created_by,updated_by
    ) values(
      v_project.organization_id,target_project_id,v_version,'draft',proposed_start_year,proposed_end_year,proposal_origin_type,
      nullif(trim(proposal_rationale),''),nullif(trim(proposal_source_reference),''),
      jsonb_build_object('created_during_phase',v_project.current_phase_code),auth.uid(),auth.uid()
    ) returning id into v_id;
  else
    select * into v_proposal from public.skpe_strategic_horizon_proposals where id=target_proposal_id for update;
    if v_proposal.id is null or v_proposal.project_id<>target_project_id then
      raise exception 'Proposta de Horizonte EstratÃ©gico nÃ£o encontrada neste projeto.' using errcode='22023';
    end if;
    if v_proposal.status not in ('draft','adjusted') then
      raise exception 'Somente proposta em rascunho ou ajuste pode ser editada.' using errcode='55000';
    end if;
    update public.skpe_strategic_horizon_proposals
    set proposed_start_year=proposed_start_year, proposed_end_year=proposed_end_year,
        origin_type=proposal_origin_type, rationale=nullif(trim(proposal_rationale),''),
        source_reference=nullif(trim(proposal_source_reference),''), updated_at=timezone('utc',now()), updated_by=auth.uid()
    where id=target_proposal_id returning id into v_id;
  end if;

  insert into public.skpe_journey_audit(organization_id,project_id,actor_user_id,action_code,reason,new_data)
  values(v_project.organization_id,target_project_id,auth.uid(),'strategic_horizon_proposal_upserted',change_reason,
    jsonb_build_object('proposal_id',v_id,'start_year',proposed_start_year,'end_year',proposed_end_year,'origin_type',proposal_origin_type));
  return v_id;
end;
$$;

create or replace function public.transition_skpe_strategic_horizon_proposal(
  target_proposal_id uuid,
  transition_action text,
  change_reason text
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_proposal public.skpe_strategic_horizon_proposals%rowtype;
  v_new_status text;
begin
  perform public.skpe_assert_reason(change_reason);
  select * into v_proposal from public.skpe_strategic_horizon_proposals where id=target_proposal_id for update;
  if v_proposal.id is null then raise exception 'Proposta de Horizonte EstratÃ©gico nÃ£o encontrada.' using errcode='22023'; end if;
  if not public.can_manage_skpe_governance(v_proposal.organization_id) then
    raise exception 'Acesso negado Ã  gestÃ£o da proposta de Horizonte EstratÃ©gico.' using errcode='42501';
  end if;

  v_new_status := case transition_action
    when 'submit' then case when v_proposal.status in ('draft','adjusted') then 'proposed' end
    when 'start_review' then case when v_proposal.status='proposed' then 'under_review' end
    when 'defer' then case when v_proposal.status in ('draft','proposed','under_review','adjusted') then 'deferred' end
    when 'reject' then case when v_proposal.status in ('draft','proposed','under_review','adjusted','deferred') then 'rejected' end
    when 'reopen' then case when v_proposal.status in ('deferred','rejected') then 'draft' end
    else null end;
  if v_new_status is null then raise exception 'TransiÃ§Ã£o invÃ¡lida para o estado atual da proposta.' using errcode='55000'; end if;

  update public.skpe_strategic_horizon_proposals
  set status=v_new_status, updated_at=timezone('utc',now()), updated_by=auth.uid()
  where id=target_proposal_id;

  insert into public.skpe_journey_audit(organization_id,project_id,actor_user_id,action_code,reason,new_data)
  values(v_proposal.organization_id,v_proposal.project_id,auth.uid(),'strategic_horizon_proposal_transitioned',change_reason,
    jsonb_build_object('proposal_id',target_proposal_id,'previous_status',v_proposal.status,'new_status',v_new_status,'action',transition_action));
  return v_new_status;
end;
$$;

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
    raise exception 'Resultado de decisÃ£o invÃ¡lido para Horizonte EstratÃ©gico.' using errcode='22023';
  end if;
  if decision_outcome='approved_with_reservations' and nullif(trim(reservations),'') is null then
    raise exception 'AprovaÃ§Ã£o com ressalvas exige descriÃ§Ã£o das ressalvas.' using errcode='22023';
  end if;
  if decision_outcome='returned_for_adjustment' and nullif(trim(adjustment_requirements),'') is null then
    raise exception 'Retorno para ajuste exige requisitos de ajuste.' using errcode='22023';
  end if;

  select * into v_proposal from public.skpe_strategic_horizon_proposals where id=target_proposal_id for update;
  if v_proposal.id is null then raise exception 'Proposta de Horizonte EstratÃ©gico nÃ£o encontrada.' using errcode='22023'; end if;
  if v_proposal.status not in ('proposed','under_review') then
    raise exception 'A proposta precisa estar submetida ou em revisÃ£o para decisÃ£o institucional.' using errcode='55000';
  end if;
  if not public.can_ratify_skpe_governance(v_proposal.organization_id) then
    raise exception 'Acesso negado: o usuÃ¡rio nÃ£o possui permissÃ£o para deliberar o Horizonte EstratÃ©gico.' using errcode='42501';
  end if;

  select * into v_project from public.skpe_projects where id=v_proposal.project_id and archived_at is null for update;
  if v_project.id is null then raise exception 'Projeto SK-PE nÃ£o encontrado.' using errcode='22023'; end if;

  select * into v_gate from public.skpe_journey_items
  where project_id=v_project.id and code='PEM-01.GATE' and item_type='gate' limit 1;
  select * into v_pem01 from public.skpe_journey_items
  where project_id=v_project.id and code='PEM-01' and item_type='macrophase' limit 1;
  if v_gate.id is null or v_pem01.id is null then raise exception 'Estrutura PEM-01/PEM-01.GATE nÃ£o localizada no projeto.' using errcode='55000'; end if;
  if not ((v_pem01.status='completed' and v_pem01.progress=100) or v_gate.status in ('in_progress','completed')) then
    raise exception 'O Horizonte EstratÃ©gico sÃ³ pode ser deliberado no fechamento do DiagnÃ³stico EstratÃ©gico.' using errcode='55000';
  end if;

  select id,decision_sequence into v_prev_decision,v_prev_sequence
  from public.skpe_gate_decisions where project_id=v_project.id and gate_journey_item_id=v_gate.id
  order by decision_sequence desc limit 1;

  insert into public.skpe_gate_decisions(
    organization_id,project_id,gate_journey_item_id,decision_outcome,decision_reason,reservations,adjustment_requirements,
    readiness_snapshot,decision_context,supersedes_decision_id,decision_sequence,decided_at,decided_by,
    decision_origin_type,decided_by_actor_type,decision_time_precision,metadata
  ) values(
    v_project.organization_id,v_project.id,v_gate.id,decision_outcome,decision_reason,
    case when decision_outcome='approved_with_reservations' then nullif(trim(reservations),'') end,
    case when decision_outcome='returned_for_adjustment' then nullif(trim(adjustment_requirements),'') end,
    jsonb_build_object('pem01_status',v_pem01.status,'pem01_progress',v_pem01.progress,'gate_status',v_gate.status),
    jsonb_build_object('decision_kind','strategic_horizon','proposal_id',v_proposal.id,'proposed_start_year',v_proposal.proposed_start_year,'proposed_end_year',v_proposal.proposed_end_year),
    v_prev_decision,coalesce(v_prev_sequence,0)+1,timezone('utc',now()),auth.uid(),
    'native_platform','organization','exact_datetime',jsonb_build_object('gate','17-B.3A')
  ) returning id into v_decision;

  if decision_outcome='returned_for_adjustment' then
    update public.skpe_strategic_horizon_proposals
    set status='adjusted',updated_at=timezone('utc',now()),updated_by=auth.uid()
    where id=v_proposal.id;

    insert into public.skpe_journey_audit(organization_id,project_id,actor_user_id,action_code,reason,new_data)
    values(v_project.organization_id,v_project.id,auth.uid(),'strategic_horizon_returned_for_adjustment',change_reason,
      jsonb_build_object('proposal_id',v_proposal.id,'gate_decision_id',v_decision,'adjustment_requirements',adjustment_requirements));

    return jsonb_build_object('proposal_id',v_proposal.id,'gate_decision_id',v_decision,'decision_outcome',decision_outcome,'horizon_id',null);
  end if;

  update public.skpe_strategic_horizon_proposals
  set status='approved',updated_at=timezone('utc',now()),updated_by=auth.uid()
  where id=v_proposal.id;

  select * into v_prev_horizon from public.skpe_strategic_horizons
  where project_id=v_project.id and is_current=true for update;

  if v_prev_horizon.id is not null then
    update public.skpe_strategic_horizons
    set is_current=false,governance_status='superseded',superseded_at=timezone('utc',now()),superseded_by=auth.uid(),
        updated_at=timezone('utc',now()),updated_by=auth.uid()
    where id=v_prev_horizon.id;
  end if;

  select coalesce(max(version_number),0)+1 into v_horizon_version
  from public.skpe_strategic_horizons where project_id=v_project.id;

  insert into public.skpe_strategic_horizons(
    organization_id,project_id,proposal_id,version_number,horizon_start_year,horizon_end_year,valid_from,valid_until,
    governance_status,is_current,decision_origin_type,decision_gate_id,source_reference,regularization_status,
    supersedes_horizon_id,metadata,approved_at,approved_by,created_by,updated_by
  ) values(
    v_project.organization_id,v_project.id,v_proposal.id,v_horizon_version,v_proposal.proposed_start_year,v_proposal.proposed_end_year,
    current_date,make_date(v_proposal.proposed_end_year,12,31),'approved',true,'native_platform',v_decision,
    v_proposal.source_reference,'not_required',v_prev_horizon.id,
    jsonb_build_object('gate','17-B.3A','proposal_version',v_proposal.version_number),timezone('utc',now()),auth.uid(),auth.uid(),auth.uid()
  ) returning id into v_horizon;

  update public.skpe_projects
  set planning_horizon_start_year=v_proposal.proposed_start_year,
      planning_horizon_end_year=v_proposal.proposed_end_year,
      reference_year=coalesce(reference_year,v_proposal.proposed_start_year),
      review_cycle=coalesce(review_cycle,'RevisÃ£o anual'),
      valid_from=current_date,
      valid_until=make_date(v_proposal.proposed_end_year,12,31),
      updated_at=timezone('utc',now()),updated_by=auth.uid()
  where id=v_project.id;

  insert into public.skpe_journey_audit(organization_id,project_id,actor_user_id,action_code,reason,new_data)
  values(v_project.organization_id,v_project.id,auth.uid(),'strategic_horizon_approved',change_reason,
    jsonb_build_object('proposal_id',v_proposal.id,'gate_decision_id',v_decision,'horizon_id',v_horizon,'start_year',v_proposal.proposed_start_year,'end_year',v_proposal.proposed_end_year));

  return jsonb_build_object('proposal_id',v_proposal.id,'gate_decision_id',v_decision,'decision_outcome',decision_outcome,'horizon_id',v_horizon);
end;
$$;

comment on function public.start_skpe_project_pem00(uuid,text,integer,integer) is
'LEGACY/DEPRECATED: mantÃ©m compatibilidade temporÃ¡ria. Novos fluxos devem usar prepare_skpe_project e governar o Horizonte EstratÃ©gico no PEM-01.GATE.';

revoke all on function public.get_skpe_strategic_horizon_context(uuid,uuid) from public, anon;
revoke all on function public.prepare_skpe_project(uuid,text) from public, anon;
revoke all on function public.upsert_skpe_strategic_horizon_proposal(uuid,uuid,integer,integer,text,text,text,text) from public, anon;
revoke all on function public.transition_skpe_strategic_horizon_proposal(uuid,text,text) from public, anon;
revoke all on function public.decide_skpe_strategic_horizon(uuid,text,text,text,text,text) from public, anon;

grant execute on function public.get_skpe_strategic_horizon_context(uuid,uuid) to authenticated, service_role;
grant execute on function public.prepare_skpe_project(uuid,text) to authenticated, service_role;
grant execute on function public.upsert_skpe_strategic_horizon_proposal(uuid,uuid,integer,integer,text,text,text,text) to authenticated, service_role;
grant execute on function public.transition_skpe_strategic_horizon_proposal(uuid,text,text) to authenticated, service_role;
grant execute on function public.decide_skpe_strategic_horizon(uuid,text,text,text,text,text) to authenticated, service_role;

revoke all on function public.skpe_validate_strategic_horizon_proposal_context() from public, anon, authenticated;
revoke all on function public.skpe_validate_strategic_horizon_context() from public, anon, authenticated;
grant execute on function public.skpe_validate_strategic_horizon_proposal_context() to service_role;
grant execute on function public.skpe_validate_strategic_horizon_context() to service_role;