insert into public.skpe_methodology_gate_criteria (
  gate_template_item_id,
  code,
  name,
  description,
  criterion_type,
  requirement_level,
  evaluation_method,
  blocking,
  expected_value,
  evaluation_rule,
  display_order,
  active,
  metadata
)
select
  t.id,
  c.code,
  c.name,
  c.description,
  c.criterion_type,
  c.requirement_level,
  c.evaluation_method,
  c.blocking,
  c.expected_value,
  c.evaluation_rule,
  c.display_order,
  true,
  jsonb_build_object(
    'gate', '17-B.3B',
    'methodology_version', v.version_code,
    'principle', c.principle
  )
from public.skpe_methodology_template_items t
join public.skpe_methodology_template_versions v
  on v.id = t.template_version_id
cross join (
  values
    ('PEM01_DIAGNOSTICO_CONCLUIDO','DiagnÃ³stico EstratÃ©gico concluÃ­do','Confirma que a Macrofase PEM-01 foi concluÃ­da antes da passagem para FormulaÃ§Ã£o EstratÃ©gica.','methodological','required','automatic',true,jsonb_build_object('status','completed','progress',100),jsonb_build_object('source','skpe_journey_items','item_code','PEM-01'),10,'diagnostic_completion_is_blocking'),
    ('PEM01_DECISAO_GATE_FAVORAVEL','DecisÃ£o institucional favorÃ¡vel no Gate do DiagnÃ³stico','Exige decisÃ£o aprovada ou aprovada com ressalvas no PEM-01.GATE antes da FormulaÃ§Ã£o EstratÃ©gica.','decision','required','automatic',true,jsonb_build_object('outcomes',jsonb_build_array('approved','approved_with_reservations')),jsonb_build_object('source','skpe_gate_decisions','gate_code','PEM-01.GATE'),20,'institutional_decision_is_blocking'),
    ('PEM01_HORIZONTE_VIGENTE','Horizonte EstratÃ©gico vigente','Confirma a existÃªncia de Horizonte EstratÃ©gico vigente, aprovado nativamente ou reconhecido historicamente.','validation','required','automatic',true,jsonb_build_object('is_current',true,'governance_status',jsonb_build_array('approved','historical_recognized')),jsonb_build_object('source','skpe_strategic_horizons'),30,'current_horizon_is_blocking'),
    ('PEM01_LACUNAS_EVIDENCIAS_CONHECIDAS','Lacunas de evidÃªncias conhecidas e explicitadas','As lacunas de evidÃªncias devem ser conhecidas e sinalizadas, mas sua existÃªncia nÃ£o bloqueia automaticamente a continuidade do Planejamento EstratÃ©gico.','evidence','recommended','hybrid',false,jsonb_build_object('principle','known_gaps_do_not_block'),jsonb_build_object('assessment','manual_or_evidence_service'),40,'evidence_gaps_reduce_confidence_but_do_not_block'),
    ('PEM01_RESSALVAS_EXPLICITADAS','Ressalvas e pendÃªncias explicitadas','Quando houver aprovaÃ§Ã£o com ressalvas, as pendÃªncias precisam permanecer visÃ­veis e rastreÃ¡veis para tratamento posterior.','quality','recommended','hybrid',false,jsonb_build_object('principle','reservations_are_traceable'),jsonb_build_object('source','skpe_gate_decisions','field','reservations'),50,'reservations_do_not_block_when_formally_accepted')
) as c(code,name,description,criterion_type,requirement_level,evaluation_method,blocking,expected_value,evaluation_rule,display_order,principle)
where t.code = 'PEM-01.GATE'
  and t.item_type = 'gate'
  and v.version_code = 'SK-PE-2026.2'
  and v.status = 'published'
on conflict (gate_template_item_id, code) do update
set name = excluded.name,
    description = excluded.description,
    criterion_type = excluded.criterion_type,
    requirement_level = excluded.requirement_level,
    evaluation_method = excluded.evaluation_method,
    blocking = excluded.blocking,
    expected_value = excluded.expected_value,
    evaluation_rule = excluded.evaluation_rule,
    display_order = excluded.display_order,
    active = excluded.active,
    metadata = excluded.metadata,
    updated_at = timezone('utc', now());

create or replace function public.get_skpe_pem01_gate_readiness(
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
  v_pem01 public.skpe_journey_items%rowtype;
  v_gate public.skpe_journey_items%rowtype;
  v_pem02 public.skpe_journey_items%rowtype;
  v_decision public.skpe_gate_decisions%rowtype;
  v_horizon public.skpe_strategic_horizons%rowtype;
  v_diag_ok boolean;
  v_decision_ok boolean;
  v_horizon_ok boolean;
  v_already_advanced boolean;
  v_reservations text;
  v_blocking_count integer;
  v_criteria jsonb;
begin
  if not public.can_view_skpe_journey(target_organization_id) then
    raise exception 'Acesso negado Ã  prontidÃ£o do Gate PEM-01.' using errcode='42501';
  end if;

  select * into v_project
  from public.skpe_projects
  where id = target_project_id
    and organization_id = target_organization_id
    and archived_at is null;

  if v_project.id is null then
    raise exception 'Projeto SK-PE nÃ£o encontrado.' using errcode='22023';
  end if;

  select * into v_pem01 from public.skpe_journey_items where project_id = target_project_id and code = 'PEM-01' and item_type = 'macrophase' limit 1;
  select * into v_gate from public.skpe_journey_items where project_id = target_project_id and code = 'PEM-01.GATE' and item_type = 'gate' limit 1;
  select * into v_pem02 from public.skpe_journey_items where project_id = target_project_id and code = 'PEM-02' and item_type = 'macrophase' limit 1;

  if v_pem01.id is null or v_gate.id is null or v_pem02.id is null then
    raise exception 'Estrutura metodolÃ³gica PEM-01 â†’ PEM-01.GATE â†’ PEM-02 nÃ£o localizada no projeto.' using errcode='55000';
  end if;

  select * into v_decision
  from public.skpe_gate_decisions
  where project_id = target_project_id and gate_journey_item_id = v_gate.id
  order by decision_sequence desc
  limit 1;

  select * into v_horizon
  from public.skpe_strategic_horizons
  where project_id = target_project_id and is_current = true
  limit 1;

  v_diag_ok := v_pem01.status = 'completed' and v_pem01.progress = 100;
  v_decision_ok := v_decision.id is not null and v_decision.decision_outcome in ('approved','approved_with_reservations');
  v_horizon_ok := v_horizon.id is not null and v_horizon.governance_status in ('approved','historical_recognized') and v_horizon.is_current = true;
  v_already_advanced := v_pem02.status in ('in_progress','pending_validation','completed') or v_project.current_phase_code like 'PEM-02%';
  v_reservations := case when v_decision.decision_outcome='approved_with_reservations' then v_decision.reservations else null end;
  v_blocking_count := (case when v_diag_ok then 0 else 1 end) + (case when v_decision_ok then 0 else 1 end) + (case when v_horizon_ok then 0 else 1 end);

  v_criteria := jsonb_build_array(
    jsonb_build_object('code','PEM01_DIAGNOSTICO_CONCLUIDO','name','DiagnÃ³stico EstratÃ©gico concluÃ­do','blocking',true,'status',case when v_diag_ok then 'satisfied' else 'not_satisfied' end,'observed',jsonb_build_object('status',v_pem01.status,'progress',v_pem01.progress)),
    jsonb_build_object('code','PEM01_DECISAO_GATE_FAVORAVEL','name','DecisÃ£o institucional favorÃ¡vel no Gate do DiagnÃ³stico','blocking',true,'status',case when v_decision_ok then 'satisfied' else 'not_satisfied' end,'observed',jsonb_build_object('gate_decision_id',v_decision.id,'decision_outcome',v_decision.decision_outcome,'decision_sequence',v_decision.decision_sequence)),
    jsonb_build_object('code','PEM01_HORIZONTE_VIGENTE','name','Horizonte EstratÃ©gico vigente','blocking',true,'status',case when v_horizon_ok then 'satisfied' else 'not_satisfied' end,'observed',jsonb_build_object('horizon_id',v_horizon.id,'governance_status',v_horizon.governance_status,'is_current',coalesce(v_horizon.is_current,false),'start_year',v_horizon.horizon_start_year,'end_year',v_horizon.horizon_end_year,'regularization_status',v_horizon.regularization_status)),
    jsonb_build_object('code','PEM01_LACUNAS_EVIDENCIAS_CONHECIDAS','name','Lacunas de evidÃªncias conhecidas e explicitadas','blocking',false,'status','requires_context_review','observed',jsonb_build_object('principle','A ausÃªncia de evidÃªncias nÃ£o bloqueia o PE; deve reduzir confianÃ§a e permanecer explicitada.')),
    jsonb_build_object('code','PEM01_RESSALVAS_EXPLICITADAS','name','Ressalvas e pendÃªncias explicitadas','blocking',false,'status',case when v_decision.id is null then 'not_evaluated' when v_decision.decision_outcome='approved_with_reservations' and nullif(trim(v_reservations),'') is not null then 'satisfied_with_reservations' when v_decision.decision_outcome='approved' then 'not_applicable' else 'not_evaluated' end,'observed',jsonb_build_object('reservations',v_reservations))
  );

  return jsonb_build_object(
    'organization_id', target_organization_id,
    'project_id', target_project_id,
    'project_code', v_project.code,
    'methodology_version', v_project.methodology_version,
    'gate_code', 'PEM-01.GATE',
    'transition', 'PEM-01.GATE -> PEM-02',
    'blocking_criteria_total', 3,
    'blocking_criteria_unsatisfied', v_blocking_count,
    'ready_to_advance', v_blocking_count = 0,
    'already_advanced', v_already_advanced,
    'decision_outcome', v_decision.decision_outcome,
    'reservations', v_reservations,
    'criteria', v_criteria
  );
end;
$$;

create or replace function public.advance_skpe_from_pem01_gate(
  target_project_id uuid,
  change_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_project public.skpe_projects%rowtype;
  v_gate public.skpe_journey_items%rowtype;
  v_pem02 public.skpe_journey_items%rowtype;
  v_readiness jsonb;
  v_ready boolean;
  v_already_advanced boolean;
begin
  perform public.skpe_assert_reason(change_reason);

  select * into v_project
  from public.skpe_projects
  where id = target_project_id and archived_at is null
  for update;

  if v_project.id is null then
    raise exception 'Projeto SK-PE nÃ£o encontrado.' using errcode='22023';
  end if;

  if not public.can_manage_skpe_journey(v_project.organization_id) then
    raise exception 'Acesso negado: o usuÃ¡rio nÃ£o pode avanÃ§ar a Jornada EstratÃ©gica desta organizaÃ§Ã£o.' using errcode='42501';
  end if;

  v_readiness := public.get_skpe_pem01_gate_readiness(v_project.organization_id, v_project.id);
  v_ready := coalesce((v_readiness->>'ready_to_advance')::boolean,false);
  v_already_advanced := coalesce((v_readiness->>'already_advanced')::boolean,false);

  if v_already_advanced then
    return v_readiness || jsonb_build_object('transition_result','already_advanced','message','O projeto jÃ¡ se encontra na FormulaÃ§Ã£o EstratÃ©gica ou em etapa posterior; nenhuma regressÃ£o foi realizada.');
  end if;

  if not v_ready then
    raise exception using errcode='55000', message='O Gate PEM-01 ainda possui critÃ©rios bloqueadores nÃ£o atendidos.', detail=v_readiness::text;
  end if;

  select * into v_gate from public.skpe_journey_items where project_id=v_project.id and code='PEM-01.GATE' and item_type='gate' limit 1;
  select * into v_pem02 from public.skpe_journey_items where project_id=v_project.id and code='PEM-02' and item_type='macrophase' limit 1;

  perform public.set_skpe_journey_item_status(v_gate.id,'completed',100,'Gate PEM-01 concluÃ­do apÃ³s verificaÃ§Ã£o governada de prontidÃ£o. ' || trim(change_reason));
  perform public.set_skpe_journey_item_status(v_pem02.id,'in_progress',greatest(coalesce(v_pem02.progress,0),0),'FormulaÃ§Ã£o EstratÃ©gica iniciada apÃ³s aprovaÃ§Ã£o do Gate PEM-01. ' || trim(change_reason));

  update public.skpe_projects
  set current_phase_code='PEM-02',
      status=case when status='draft' then 'active' else status end,
      updated_at=timezone('utc',now()),
      updated_by=auth.uid()
  where id=v_project.id;

  insert into public.skpe_journey_audit(organization_id,project_id,journey_item_id,actor_user_id,action_code,reason,previous_data,new_data)
  values (
    v_project.organization_id,
    v_project.id,
    v_gate.id,
    auth.uid(),
    'pem01_gate_advanced_to_pem02',
    trim(change_reason),
    jsonb_build_object('current_phase_code',v_project.current_phase_code,'project_status',v_project.status,'readiness',v_readiness),
    jsonb_build_object('current_phase_code','PEM-02','project_status',case when v_project.status='draft' then 'active' else v_project.status end)
  );

  return public.get_skpe_pem01_gate_readiness(v_project.organization_id, v_project.id)
    || jsonb_build_object('transition_result','advanced','message','Gate PEM-01 concluÃ­do e FormulaÃ§Ã£o EstratÃ©gica iniciada.');
end;
$$;

revoke all on function public.get_skpe_pem01_gate_readiness(uuid,uuid) from public, anon;
revoke all on function public.advance_skpe_from_pem01_gate(uuid,text) from public, anon;
grant execute on function public.get_skpe_pem01_gate_readiness(uuid,uuid) to authenticated, service_role;
grant execute on function public.advance_skpe_from_pem01_gate(uuid,text) to authenticated, service_role;