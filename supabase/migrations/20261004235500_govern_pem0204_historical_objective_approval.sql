-- Govern PEM-02.04 recognition of objective approvals that already occurred.
-- Reuses documentary evidence without inventing a new meeting or human decision.

create or replace function public.recognize_skpe_objective_historical_approval(
  target_objective_id uuid,
  target_evidence_source_id uuid,
  decision_occurred_at timestamptz,
  decision_notes text
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $function$
declare
  objective_row public.skpe_strategic_objectives%rowtype;
  formulation_row public.skpe_strategic_formulations%rowtype;
  evidence_row public.skpe_evidence_sources%rowtype;
  journey_row public.skpe_journey_items%rowtype;
  before_row jsonb;
  after_row jsonb;
  objective_codes jsonb;
begin
  if auth.uid() is null then
    raise exception using errcode='42501', message='Operação exige usuário autenticado.';
  end if;

  if length(trim(coalesce(decision_notes,''))) < 10 then
    raise exception using errcode='22023', message='Informe justificativa com pelo menos 10 caracteres.';
  end if;

  if decision_occurred_at is null or decision_occurred_at > now() then
    raise exception using errcode='22023', message='A data da decisão humana deve existir e não pode estar no futuro.';
  end if;

  select * into objective_row
  from public.skpe_strategic_objectives
  where id=target_objective_id
  for update;

  if objective_row.id is null then
    raise exception using errcode='22023', message='Objetivo Estratégico não encontrado.';
  end if;

  select * into formulation_row
  from public.skpe_strategic_formulations
  where id=objective_row.formulation_id;

  if formulation_row.id is null then
    raise exception using errcode='55000', message='Formulação Estratégica do Objetivo não encontrada.';
  end if;

  if not public.can_validate_skpe_formulation(formulation_row.organization_id) then
    raise exception using errcode='42501', message='Acesso negado para reconhecer aprovação de Objetivo Estratégico.';
  end if;

  select * into journey_row
  from public.skpe_journey_items
  where project_id=formulation_row.project_id
    and code='PEM-02.04'
    and archived_at is null
  limit 1;

  if journey_row.id is null or journey_row.status <> 'in_progress' or not journey_row.is_current then
    raise exception using
      errcode='55000',
      message='A aprovação de Objetivos só pode ser reconhecida durante PEM-02.04 em execução.';
  end if;

  select * into evidence_row
  from public.skpe_evidence_sources
  where id=target_evidence_source_id;

  if evidence_row.id is null
     or evidence_row.organization_id <> formulation_row.organization_id
     or evidence_row.project_id <> formulation_row.project_id then
    raise exception using errcode='22023', message='Evidência de aprovação inválida ou fora do escopo do projeto.';
  end if;

  if lower(coalesce(
      evidence_row.metadata->'documentary_counterproof'->>'status',''
    )) not in ('reconciled','validated','accepted','approved','confirmed') then
    raise exception using errcode='55000', message='A evidência ainda não foi reconciliada como contraprova documental.';
  end if;

  if not coalesce(
    (evidence_row.metadata->'pem0204_transport'->>'preserve_human_approval')::boolean,
    false
  ) then
    raise exception using errcode='55000', message='A evidência não autoriza reutilização da aprovação humana em PEM-02.04.';
  end if;

  objective_codes:=coalesce(
    evidence_row.metadata->'pem0204_transport'->'objective_codes',
    '[]'::jsonb
  );

  if not (objective_codes ? objective_row.code) then
    raise exception using
      errcode='55000',
      message='A evidência reconciliada não inclui este Objetivo Estratégico no escopo aprovado.';
  end if;

  if objective_row.validation_status='validated'
     and coalesce(objective_row.metadata->'pem0204Approval'->>'evidenceSourceId','')=evidence_row.id::text then
    return jsonb_build_object(
      'objectiveId',objective_row.id,
      'code',objective_row.code,
      'status',objective_row.status,
      'validationStatus',objective_row.validation_status,
      'idempotent',true
    );
  end if;

  before_row:=to_jsonb(objective_row);

  update public.skpe_strategic_objectives
  set
    status='active',
    validation_status='validated',
    approved_at=decision_occurred_at,
    approved_by=null,
    metadata=coalesce(metadata,'{}'::jsonb) || jsonb_build_object(
      'pem0204Approval',jsonb_build_object(
        'mode','historical_decision_reuse',
        'evidenceSourceId',evidence_row.id,
        'institutionalDecisionOccurredAt',decision_occurred_at,
        'recordedAt',timezone('utc',now()),
        'recordedBy',auth.uid(),
        'noNewHumanDecisionCreated',true,
        'contentChanged',false
      )
    ),
    updated_at=timezone('utc',now()),
    updated_by=auth.uid()
  where id=objective_row.id
  returning to_jsonb(public.skpe_strategic_objectives.*) into after_row;

  perform public.skpe_record_operational_audit(
    formulation_row.organization_id,
    formulation_row.project_id,
    'strategic_objective',
    objective_row.id,
    'pem02.04.historical_objective_approval_recognized',
    trim(decision_notes),
    before_row,
    after_row
  );

  return jsonb_build_object(
    'objectiveId',objective_row.id,
    'code',objective_row.code,
    'status','active',
    'validationStatus','validated',
    'evidenceSourceId',evidence_row.id,
    'institutionalDecisionOccurredAt',decision_occurred_at,
    'idempotent',false
  );
end;
$function$;

revoke all on function public.recognize_skpe_objective_historical_approval(uuid,uuid,timestamptz,text)
from public,anon;
grant execute on function public.recognize_skpe_objective_historical_approval(uuid,uuid,timestamptz,text)
to authenticated,service_role;

create or replace function public.get_skpe_pem0204_objective_readiness(
  target_formulation_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $function$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  objective_count integer:=0;
  approved_count integer:=0;
  missing_evidence_count integer:=0;
  issues jsonb:='[]'::jsonb;
  blocking_count integer:=0;
begin
  select * into formulation_row
  from public.skpe_strategic_formulations
  where id=target_formulation_id;

  if formulation_row.id is null then
    raise exception using errcode='22023', message='Formulação Estratégica não encontrada.';
  end if;

  if not public.can_view_skpe_formulation(formulation_row.organization_id) then
    raise exception using errcode='42501', message='Acesso negado à prontidão de PEM-02.04.';
  end if;

  select
    count(*)::integer,
    count(*) filter (
      where objective.status='active'
        and objective.validation_status='validated'
    )::integer,
    count(*) filter (
      where objective.status='active'
        and objective.validation_status='validated'
        and coalesce(objective.metadata->'pem0204Approval'->>'evidenceSourceId','')=''
    )::integer
  into objective_count,approved_count,missing_evidence_count
  from public.skpe_strategic_objectives objective
  where objective.formulation_id=formulation_row.id
    and objective.status<>'archived';

  if objective_count=0 then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0204_OBJECTIVES_MISSING',
      'severity','blocking',
      'message','PEM-02.04 exige Objetivos Estratégicos materializados.'
    ));
  end if;

  if approved_count<objective_count then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0204_OBJECTIVE_APPROVALS_PENDING',
      'severity','blocking',
      'message','Todos os Objetivos Estratégicos exigem aprovação humana reconhecida de forma governada.',
      'affectedCount',objective_count-approved_count
    ));
  end if;

  if missing_evidence_count>0 then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0204_APPROVAL_EVIDENCE_MISSING',
      'severity','blocking',
      'message','Objetivos validados precisam manter referência explícita à evidência da aprovação.',
      'affectedCount',missing_evidence_count
    ));
  end if;

  select count(*)::integer into blocking_count
  from jsonb_array_elements(issues) issue
  where issue->>'severity'='blocking';

  return jsonb_build_object(
    'formulationId',formulation_row.id,
    'projectId',formulation_row.project_id,
    'organizationId',formulation_row.organization_id,
    'readyForCompletion',blocking_count=0,
    'blockingIssueCount',blocking_count,
    'issues',issues,
    'counts',jsonb_build_object(
      'objectives',objective_count,
      'approvedObjectives',approved_count,
      'validatedWithoutEvidence',missing_evidence_count
    ),
    'methodologyRules',jsonb_build_object(
      'humanApprovalRequiredForEveryObjective',true,
      'historicalApprovalMayBeReusedWhenDocumented',true,
      'newMeetingNotRequiredWhenDecisionAlreadyOccurred',true,
      'evidenceReferenceRequired',true
    )
  );
end;
$function$;

revoke all on function public.get_skpe_pem0204_objective_readiness(uuid)
from public,anon;
grant execute on function public.get_skpe_pem0204_objective_readiness(uuid)
to authenticated,service_role;

create or replace function public.skpe_guard_pem0204_completion()
returns trigger
language plpgsql
security definer
set search_path=''
as $function$
declare
  formulation_id uuid;
  readiness jsonb;
begin
  if new.code<>'PEM-02.04' or new.status<>'completed' then
    return new;
  end if;

  select id into formulation_id
  from public.skpe_strategic_formulations
  where project_id=new.project_id
    and archived_at is null
  order by version_number desc
  limit 1;

  if formulation_id is null then
    raise exception using errcode='55000',
      message='PEM-02.04 não pode ser concluída sem Formulação Estratégica.';
  end if;

  readiness:=public.get_skpe_pem0204_objective_readiness(formulation_id);

  if not coalesce((readiness->>'readyForCompletion')::boolean,false) then
    raise exception using
      errcode='55000',
      message='PEM-02.04 não pode ser concluída: existem Objetivos sem aprovação governada ou sem evidência.',
      detail=readiness::text;
  end if;

  new.metadata:=jsonb_set(
    coalesce(new.metadata,'{}'::jsonb),
    '{completionEvidence}',
    jsonb_build_object(
      'readinessVerifiedAt',timezone('utc',now()),
      'readinessSnapshot',readiness
    ),
    true
  );

  return new;
end;
$function$;

drop trigger if exists skpe_pem0204_completion_guard
on public.skpe_journey_items;

create trigger skpe_pem0204_completion_guard
before update of status,progress
on public.skpe_journey_items
for each row
execute function public.skpe_guard_pem0204_completion();

comment on function public.recognize_skpe_objective_historical_approval(uuid,uuid,timestamptz,text) is
'Recognizes a strategic objective approval that already occurred, only from reconciled documentary evidence during PEM-02.04. Does not create a new human decision.';

comment on function public.get_skpe_pem0204_objective_readiness(uuid) is
'Canonical readiness for PEM-02.04. Requires every objective to have governed human approval and explicit evidence reference.';

comment on function public.skpe_guard_pem0204_completion() is
'Fail-closed completion guard for PEM-02.04. Does not invent or infer objective approvals.';
