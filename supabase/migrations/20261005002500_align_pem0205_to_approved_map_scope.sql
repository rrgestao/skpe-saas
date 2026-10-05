-- Align PEM-02.05 readiness with the actual institutional approval scope.
-- Owners and detailed OE-to-OE causal relations remain governed follow-up items,
-- but do not retroactively block recognition of the Map approved on 2026-09-23.

alter function public.get_skpe_strategic_map_readiness(uuid)
  rename to get_skpe_strategic_map_readiness_pre_approval_scope_20261004;

revoke execute on function public.get_skpe_strategic_map_readiness_pre_approval_scope_20261004(uuid)
from public,authenticated;
grant execute on function public.get_skpe_strategic_map_readiness_pre_approval_scope_20261004(uuid)
to service_role;

create or replace function public.get_skpe_strategic_map_readiness(
  target_formulation_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $function$
declare
  base_readiness jsonb;
  normalized_issues jsonb := '[]'::jsonb;
  content_blocking_count integer := 0;
  total_blocking_count integer := 0;
  issue jsonb;
  methodology_rules jsonb;
begin
  base_readiness :=
    public.get_skpe_strategic_map_readiness_pre_approval_scope_20261004(
      target_formulation_id
    );

  for issue in
    select value
    from jsonb_array_elements(coalesce(base_readiness->'issues','[]'::jsonb))
  loop
    if issue->>'code' in (
      'OBJECTIVE_WITHOUT_OWNER',
      'CAUSAL_RELATION_VALIDATION_PENDING',
      'CAUSAL_RELATION_REJECTED',
      'OBJECTIVE_WITHOUT_CAUSAL_LINK'
    ) then
      normalized_issues := normalized_issues || jsonb_build_array(
        issue
        || jsonb_build_object(
          'severity','recommendation',
          'scope','next_intervention',
          'message',
            case issue->>'code'
              when 'OBJECTIVE_WITHOUT_OWNER'
                then 'Responsáveis pelos Objetivos Estratégicos serão definidos em intervenção específica com a Gestão; não integraram o escopo da aprovação do Mapa.'
              when 'CAUSAL_RELATION_VALIDATION_PENDING'
                then 'Relações causais OE→OE propostas exigem validação humana em intervenção posterior; não integraram o escopo da aprovação do Mapa.'
              when 'CAUSAL_RELATION_REJECTED'
                then 'Relações causais rejeitadas devem ser revistas antes de sua adoção operacional, sem reabrir a aprovação já ocorrida do Mapa.'
              else
                'A arquitetura causal OE→OE será detalhada e validada em intervenção posterior; o Mapa aprovado expressa a lógica entre Perspectivas e Objetivos.'
            end
        )
      );
    else
      normalized_issues := normalized_issues || jsonb_build_array(issue);
    end if;
  end loop;

  select
    count(*) filter (
      where item->>'severity'='blocking'
        and item->>'scope'='content'
    )::integer,
    count(*) filter (
      where item->>'severity'='blocking'
    )::integer
  into content_blocking_count,total_blocking_count
  from jsonb_array_elements(normalized_issues) item;

  methodology_rules :=
    coalesce(base_readiness->'methodologyRules','{}'::jsonb)
    || jsonb_build_object(
      'ownerRequired',false,
      'ownerDefinitionDeferredToNextIntervention',true,
      'detailedCausalRelationsRequiredForMapApproval',false,
      'detailedCausalRelationsDeferredToNextIntervention',true,
      'approvalScope',jsonb_build_array(
        'strategic_perspectives',
        'strategic_themes',
        'strategic_objectives',
        'perspective_level_cause_effect_logic'
      )
    );

  return base_readiness || jsonb_build_object(
    'issues',normalized_issues,
    'contentBlockingIssueCount',content_blocking_count,
    'blockingIssueCount',total_blocking_count,
    'readyForValidation',content_blocking_count=0,
    'readyForFormulation',
      content_blocking_count=0
      and coalesce((base_readiness->>'validated')::boolean,false),
    'methodologyRules',methodology_rules
  );
end;
$function$;

revoke all on function public.get_skpe_strategic_map_readiness(uuid)
from public,anon;
grant execute on function public.get_skpe_strategic_map_readiness(uuid)
to authenticated,service_role;

create or replace function public.recognize_skpe_strategic_map_historical_approval(
  target_formulation_id uuid,
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
  formulation_row public.skpe_strategic_formulations%rowtype;
  package_row public.skpe_strategic_map_packages%rowtype;
  evidence_row public.skpe_evidence_sources%rowtype;
  journey_row public.skpe_journey_items%rowtype;
  readiness jsonb;
  previous_package jsonb;
  updated_package jsonb;
begin
  if auth.uid() is null then
    raise exception using errcode='42501',
      message='Operação exige usuário autenticado.';
  end if;

  if decision_occurred_at is null or decision_occurred_at > now() then
    raise exception using errcode='22023',
      message='A data da decisão humana deve existir e não pode estar no futuro.';
  end if;

  if length(trim(coalesce(decision_notes,''))) < 10 then
    raise exception using errcode='22023',
      message='Informe justificativa com pelo menos 10 caracteres.';
  end if;

  select * into formulation_row
  from public.skpe_strategic_formulations
  where id=target_formulation_id;

  if formulation_row.id is null then
    raise exception using errcode='22023',
      message='Formulação Estratégica não encontrada.';
  end if;

  if not public.can_validate_skpe_formulation(formulation_row.organization_id) then
    raise exception using errcode='42501',
      message='Acesso negado para reconhecer a aprovação histórica do Mapa Estratégico.';
  end if;

  select * into journey_row
  from public.skpe_journey_items
  where project_id=formulation_row.project_id
    and code='PEM-02.05'
    and archived_at is null
  limit 1;

  if journey_row.id is null
     or journey_row.status<>'in_progress'
     or not journey_row.is_current then
    raise exception using errcode='55000',
      message='A aprovação histórica do Mapa só pode ser reconhecida durante PEM-02.05 em execução.';
  end if;

  select * into evidence_row
  from public.skpe_evidence_sources
  where id=target_evidence_source_id;

  if evidence_row.id is null
     or evidence_row.organization_id<>formulation_row.organization_id
     or evidence_row.project_id<>formulation_row.project_id then
    raise exception using errcode='22023',
      message='Evidência inválida ou fora do escopo do projeto.';
  end if;

  if not (
    coalesce((evidence_row.metadata->'map_confirmation'->>'strategic_objectives')::integer,0) > 0
    and coalesce(
      evidence_row.metadata->'map_confirmation'->>'approved_without_reservations_at',
      ''
    ) <> ''
  ) then
    raise exception using errcode='55000',
      message='A evidência não confirma de forma estruturada a aprovação institucional do Mapa.';
  end if;

  readiness := public.get_skpe_strategic_map_readiness(target_formulation_id);

  if not coalesce((readiness->>'readyForValidation')::boolean,false) then
    raise exception using
      errcode='55000',
      message='O Mapa ainda possui pendências bloqueantes dentro do escopo efetivamente aprovado.',
      detail=readiness::text;
  end if;

  select * into package_row
  from public.skpe_strategic_map_packages
  where formulation_id=target_formulation_id
  for update;

  if package_row.id is null then
    raise exception using errcode='55000',
      message='Pacote do Mapa Estratégico não encontrado.';
  end if;

  if package_row.status='validated'
     and coalesce(package_row.metadata->'historicalApproval'->>'evidenceSourceId','')
       = evidence_row.id::text then
    return jsonb_build_object(
      'strategicMapPackageId',package_row.id,
      'status',package_row.status,
      'idempotent',true
    );
  end if;

  previous_package := to_jsonb(package_row);

  update public.skpe_strategic_map_packages
  set
    status='validated',
    validation_notes=trim(decision_notes),
    validated_at=decision_occurred_at,
    validated_by=null,
    metadata=coalesce(metadata,'{}'::jsonb) || jsonb_build_object(
      'historicalApproval',jsonb_build_object(
        'mode','historical_decision_reuse',
        'evidenceSourceId',evidence_row.id,
        'institutionalDecisionOccurredAt',decision_occurred_at,
        'recordedAt',timezone('utc',now()),
        'recordedBy',auth.uid(),
        'approvalScope',jsonb_build_array(
          'strategic_perspectives',
          'strategic_themes',
          'strategic_objectives',
          'perspective_level_cause_effect_logic'
        ),
        'objectiveOwnersApproved',false,
        'detailedObjectiveRelationsApproved',false,
        'noNewHumanDecisionCreated',true
      )
    ),
    updated_at=timezone('utc',now()),
    updated_by=auth.uid()
  where id=package_row.id
  returning to_jsonb(public.skpe_strategic_map_packages.*)
  into updated_package;

  perform public.skpe_record_operational_audit(
    formulation_row.organization_id,
    formulation_row.project_id,
    'strategic_map_package',
    package_row.id,
    'pem02.05.historical_map_approval_recognized',
    trim(decision_notes),
    previous_package,
    updated_package
  );

  return jsonb_build_object(
    'strategicMapPackageId',package_row.id,
    'status','validated',
    'institutionalDecisionOccurredAt',decision_occurred_at,
    'evidenceSourceId',evidence_row.id,
    'idempotent',false
  );
end;
$function$;

revoke all on function public.recognize_skpe_strategic_map_historical_approval(uuid,uuid,timestamptz,text)
from public,anon;
grant execute on function public.recognize_skpe_strategic_map_historical_approval(uuid,uuid,timestamptz,text)
to authenticated,service_role;

comment on function public.get_skpe_strategic_map_readiness(uuid) is
'PEM-02.05 readiness aligned to the institutional approval scope: Perspectives, Themes, Objectives and perspective-level cause/effect logic. Owners and detailed OE relations are follow-up items.';

comment on function public.recognize_skpe_strategic_map_historical_approval(uuid,uuid,timestamptz,text) is
'Recognizes the Map approval that already occurred, preserving its actual scope and deferring owners/detailed causal relations to a later intervention.';
