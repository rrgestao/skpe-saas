-- SK-PE - Govern historical evidence-management rows as a canonical evidence-collection checklist.
-- Historical maturity/status is preserved as source metadata and is not promoted to a current assessment.

create or replace function public.skpe_materialize_import_request_as_evidence_checklist_item(
  p_request_id uuid,
  p_materialized_by_actor_type text,
  p_materialized_by_user_id uuid default null,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_request public.skpe_import_incorporation_requests%rowtype;
  v_record public.skpe_import_records%rowtype;
  v_decision public.skpe_import_incorporation_decisions%rowtype;
  v_resolution public.skpe_import_target_resolution_events%rowtype;
  v_checklist_id uuid;
  v_item_id uuid;
  v_source_code text;
  v_item_name text;
  v_is_required boolean;
  v_display_order integer;
begin
  perform public.skpe_assert_governed_import_materialization(p_request_id);

  select * into v_request
  from public.skpe_import_incorporation_requests
  where id=p_request_id;

  select * into v_record
  from public.skpe_import_records
  where id=v_request.import_record_id;

  if v_record.id is null or v_record.entity_code <> 'evidence_management' then
    raise exception using errcode='55000',
      message='Materializador de checklist de evidências exige entity_code = evidence_management.';
  end if;

  select * into v_decision
  from public.skpe_import_incorporation_decisions d
  where d.incorporation_request_id=v_request.id
  order by d.decision_sequence desc
  limit 1;

  if v_decision.id is null
     or v_decision.permits_incorporation <> true
     or v_decision.decision_outcome not in ('approved','approved_with_reservations') then
    raise exception using errcode='55000',
      message='Decisão vigente não permite materialização do item de checklist de evidências.';
  end if;

  select * into v_resolution
  from public.skpe_import_target_resolution_events e
  where e.import_record_id=v_record.id
    and e.organization_id=v_request.organization_id
    and e.project_id=v_request.project_id
    and e.formulation_id is not distinct from v_request.formulation_id
    and e.source_entity_code='evidence_management'
    and e.target_entity_type='evidence_checklist_item'
    and e.resolution_status='resolved'
    and e.resolution_mode='create_new_entity'
    and coalesce(jsonb_array_length(e.blockers),0)=0
  order by e.resolved_at desc,e.resolution_sequence desc
  limit 1;

  if v_resolution.id is null then
    raise exception using errcode='55000',
      message='Item histórico de gestão de evidências não possui resolução governada para criação.';
  end if;

  v_source_code:=nullif(btrim(v_record.values_json->>'id'),'');
  v_item_name:=nullif(btrim(v_record.values_json->>'evidencia_necessaria'),'');
  v_is_required:=lower(btrim(coalesce(v_record.values_json->>'obrigatoria',''))) in ('sim','yes','true','1');

  if v_source_code is null or v_item_name is null then
    raise exception using errcode='55000',
      message='Item histórico de gestão de evidências exige id e evidencia_necessaria.';
  end if;

  begin
    v_display_order:=coalesce(nullif(regexp_replace(v_source_code,'\D','','g'),''),'0')::integer;
  exception when others then
    v_display_order:=coalesce(v_record.source_row,0);
  end;

  select id into v_checklist_id
  from public.skpe_evidence_checklists
  where project_id=v_request.project_id
    and code='HIST-EVIDENCE-MGMT-V26'
  limit 1;

  if v_checklist_id is null then
    insert into public.skpe_evidence_checklists(
      organization_id,
      project_id,
      code,
      name,
      description,
      template_code,
      organization_profile_snapshot,
      status,
      completion_percentage,
      created_by,
      updated_by,
      checklist_kind,
      requirement_mode
    )
    values(
      v_request.organization_id,
      v_request.project_id,
      'HIST-EVIDENCE-MGMT-V26',
      'Gestão de Evidências — base histórica v26',
      'Checklist canônico criado a partir da aba histórica 32_Gestao_Evidencias. Os estados históricos são preservados como metadata e não equivalem a avaliação atual.',
      null,
      jsonb_build_object(
        'source','COOTAQUARA historical workbook v26',
        'source_batch_id',v_record.batch_id,
        'historical_import',true,
        'current_collection_state_inferred',false,
        'current_assessment_state_inferred',false
      ),
      'draft',
      0,
      p_materialized_by_user_id,
      p_materialized_by_user_id,
      'evidence_collection',
      'methodology_required'
    )
    returning id into v_checklist_id;
  end if;

  if not exists(
    select 1
    from public.skpe_evidence_checklists c
    where c.id=v_checklist_id
      and c.organization_id=v_request.organization_id
      and c.project_id=v_request.project_id
      and c.checklist_kind='evidence_collection'
  ) then
    raise exception using errcode='55000',
      message='Checklist histórico de evidências existente é incompatível com o escopo do request.';
  end if;

  select id into v_item_id
  from public.skpe_evidence_checklist_items
  where checklist_id=v_checklist_id
    and code=v_source_code
  limit 1;

  if v_item_id is not null then
    return v_item_id;
  end if;

  insert into public.skpe_evidence_checklist_items(
    checklist_id,
    code,
    name,
    description,
    request_reason,
    applicability_rule,
    is_required,
    is_applicable,
    responsible_area,
    collection_status,
    assessment_status,
    display_order,
    metadata,
    created_by,
    updated_by
  )
  values(
    v_checklist_id,
    v_source_code,
    v_item_name,
    nullif(btrim(v_record.values_json->>'conclusao_da_consultoria'),''),
    nullif(btrim(v_record.values_json->>'por_que_e_necessaria'),''),
    '{}'::jsonb,
    v_is_required,
    true,
    nullif(btrim(v_record.values_json->>'responsavel'),''),
    'not_requested',
    'not_assessed',
    v_display_order,
    jsonb_build_object(
      'historical_import',true,
      'source_batch_id',v_record.batch_id,
      'source_import_record_id',v_record.id,
      'source_sheet',v_record.source_sheet,
      'source_row',v_record.source_row,
      'source_external_key',v_record.external_key,
      'source_payload',v_record.values_json,
      'source_status',v_record.values_json->>'status',
      'source_maturity',v_record.values_json->>'maturidade',
      'source_evidence_level',v_record.values_json->>'nivel_e0_e5',
      'source_attendance',v_record.values_json->>'atendimento',
      'source_gap_action',v_record.values_json->>'lacuna_acao',
      'source_due_text',v_record.values_json->>'prazo',
      'source_alert',v_record.values_json->>'alerta',
      'current_collection_state_inferred',false,
      'current_assessment_state_inferred',false,
      'evidence_file_created',false,
      'semantic_inference',false
    ),
    p_materialized_by_user_id,
    p_materialized_by_user_id
  )
  returning id into v_item_id;

  insert into public.skpe_import_events(
    batch_id,organization_id,project_id,actor_user_id,event_code,event_data
  )
  values(
    v_record.batch_id,
    v_record.organization_id,
    v_record.project_id,
    p_materialized_by_user_id,
    'EVIDENCE_CHECKLIST_ITEM_MATERIALIZED',
    jsonb_build_object(
      'importRecordId',v_record.id,
      'incorporationRequestId',v_request.id,
      'incorporationDecisionId',v_decision.id,
      'targetResolutionEventId',v_resolution.id,
      'checklistId',v_checklist_id,
      'checklistItemId',v_item_id,
      'sourceItemCode',v_source_code,
      'currentCollectionStateInferred',false,
      'currentAssessmentStateInferred',false,
      'evidenceFileCreated',false,
      'semanticInference',false
    )||p_metadata
  );

  return v_item_id;
end;
$function$;

revoke all on function public.skpe_materialize_import_request_as_evidence_checklist_item(uuid,text,uuid,jsonb)
from public,anon,authenticated;
grant execute on function public.skpe_materialize_import_request_as_evidence_checklist_item(uuid,text,uuid,jsonb)
to service_role;

do $$
declare
  v_catalog_id uuid;
  v_version_id uuid;
begin
  select id into v_catalog_id
  from public.skpe_incorporation_mapping_catalogs
  where mapping_code='evidence_management_to_checklist_item';

  if v_catalog_id is null then
    insert into public.skpe_incorporation_mapping_catalogs(
      mapping_code,mapping_name,description,source_entity_code,target_entity_type,
      resolution_strategy,materialization_strategy,provenance_strategy,
      requires_human_review,allows_create_new,allows_existing_entity,
      allows_semantic_inference,status,current_version,metadata,selection_priority,applicability
    )
    values(
      'evidence_management_to_checklist_item',
      'Gestão histórica de evidências → item de checklist canônico',
      'Cria itens de checklist de coleta de evidências a partir dos requisitos históricos, preservando maturidade e status de origem sem convertê-los em avaliação atual.',
      'evidence_management','evidence_checklist_item',
      'create_new','direct_entity','a1_object_and_fields',
      true,true,true,false,'active',1,
      jsonb_build_object(
        'checklist_code','HIST-EVIDENCE-MGMT-V26',
        'checklist_kind','evidence_collection',
        'requirement_mode','methodology_required',
        'current_collection_state_inferred',false,
        'current_assessment_state_inferred',false,
        'evidence_file_created',false,
        'semantic_inference',false
      ),
      100,
      jsonb_build_object('module','SK-PE','semantic_family','evidence_management')
    )
    returning id into v_catalog_id;
  end if;

  select id into v_version_id
  from public.skpe_incorporation_mapping_versions
  where catalog_id=v_catalog_id and version_number=1;

  if v_version_id is null then
    insert into public.skpe_incorporation_mapping_versions(
      catalog_id,version_number,version_status,effective_from,target_table,
      target_key_strategy,target_key_template,resolver_function_name,
      materializer_function_name,provenance_function_name,validation_profile,
      mapping_definition,activated_at,metadata
    )
    values(
      v_catalog_id,1,'active',timezone('utc',now()),
      'skpe_evidence_checklist_items','create_new_entity','evidence_checklist_item:{id}',
      'skpe_execute_import_resolution_rules',
      'skpe_materialize_import_request_as_evidence_checklist_item',
      null,
      jsonb_build_object(
        'requires_human_review',true,
        'allows_semantic_inference',false,
        'require_valid_import_record',true,
        'require_approved_incorporation_items',true,
        'require_governed_incorporation_decision',true
      ),
      jsonb_build_object(
        'source_key','id',
        'name_field','evidencia_necessaria',
        'description_field','conclusao_da_consultoria',
        'request_reason_field','por_que_e_necessaria',
        'responsible_area_field','responsavel',
        'historical_status_policy','preserve_in_metadata_only',
        'historical_maturity_policy','preserve_in_metadata_only',
        'current_collection_status','not_requested',
        'current_assessment_status','not_assessed',
        'checklist_code','HIST-EVIDENCE-MGMT-V26'
      ),
      timezone('utc',now()),
      jsonb_build_object(
        'historical_evidence_management_import',true,
        'common_finalizer','skpe_finalize_governed_import_materialization'
      )
    )
    returning id into v_version_id;
  end if;

  if not exists(
    select 1
    from public.skpe_incorporation_resolution_rules
    where mapping_version_id=v_version_id
      and rule_code='evidence_management_create_by_source_id'
  ) then
    insert into public.skpe_incorporation_resolution_rules(
      mapping_version_id,rule_sequence,rule_code,rule_type,source_field_name,
      target_entity_type,operator,expected_value,resolution_output,is_blocking,
      stop_on_match,metadata,resolver_handler_code,resolver_config,execution_mode,
      output_key,depends_on_rule_code
    )
    values(
      v_version_id,1,'evidence_management_create_by_source_id','custom','id',
      'evidence_checklist_item','exists',null,'{}'::jsonb,true,false,
      jsonb_build_object('deterministic_source_key',true,'semantic_inference',false),
      'create_new_entity_by_source_key',
      jsonb_build_object(
        'target_external_key_template','evidence_checklist_item:{source_value}',
        'resolution_status','resolved',
        'resolution_mode','create_new_entity',
        'requires_human_review',true
      ),
      'terminal','canonical_target',null
    );
  end if;
end $$;

alter function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
rename to skpe_execute_governed_import_materialization_methodology_artifact_v1;

create function public.skpe_execute_governed_import_materialization(
  p_request_id uuid,
  p_materialized_by_actor_type text,
  p_materialized_by_user_id uuid default null,
  p_metadata jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_request public.skpe_import_incorporation_requests%rowtype;
  v_record public.skpe_import_records%rowtype;
  v_entity_id uuid;
  v_finalize jsonb;
begin
  if p_request_id is null then
    raise exception using errcode='22023',message='p_request_id é obrigatório.';
  end if;

  select * into v_request
  from public.skpe_import_incorporation_requests
  where id=p_request_id;

  if v_request.id is null then
    raise exception using errcode='22023',message='Incorporation Request não encontrado.';
  end if;

  select * into v_record
  from public.skpe_import_records
  where id=v_request.import_record_id;

  if v_record.id is null then
    raise exception using errcode='55000',message='ImportRecord do Request não encontrado.';
  end if;

  if v_record.entity_code <> 'evidence_management' then
    return public.skpe_execute_governed_import_materialization_methodology_artifact_v1(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,p_metadata
    );
  end if;

  if v_request.request_status='applied' then
    begin
      v_entity_id:=nullif(v_request.metadata->>'materialized_target_entity_id','')::uuid;
    exception when invalid_text_representation then
      raise exception using errcode='55000',
        message='Request evidence_management applied possui materialized_target_entity_id inválido.';
    end;

    if v_request.metadata->>'materialized_target_entity_type' <> 'evidence_checklist_item'
       or v_entity_id is null
       or not exists(
         select 1
         from public.skpe_evidence_checklist_items i
         join public.skpe_evidence_checklists c on c.id=i.checklist_id
         where i.id=v_entity_id
           and c.organization_id=v_request.organization_id
           and c.project_id=v_request.project_id
       ) then
      raise exception using errcode='55000',
        message='Request evidence_management applied não possui item de checklist verificável.';
    end if;

    return jsonb_build_object(
      'request_id',v_request.id,
      'import_record_id',v_record.id,
      'source_family','evidence_management',
      'handler_name','skpe_materialize_import_request_as_evidence_checklist_item',
      'materialized_entity_type','evidence_checklist_item',
      'materialized_entity_id',v_entity_id,
      'request_status','applied',
      'already_materialized',true,
      'already_finalized',true,
      'dispatcher','skpe_execute_governed_import_materialization',
      'dispatcher_version','COOTAQUARA-EVIDENCE-CHECKLIST-V1'
    );
  end if;

  v_entity_id:=public.skpe_materialize_import_request_as_evidence_checklist_item(
    p_request_id,
    p_materialized_by_actor_type,
    p_materialized_by_user_id,
    p_metadata||jsonb_build_object(
      'dispatcher_version','COOTAQUARA-EVIDENCE-CHECKLIST-V1',
      'historical_evidence_management_import',true,
      'semantic_inference',false
    )
  );

  v_finalize:=public.skpe_finalize_governed_import_materialization(
    p_request_id,
    'evidence_checklist_item',
    v_entity_id,
    p_materialized_by_actor_type,
    p_materialized_by_user_id,
    p_metadata||jsonb_build_object(
      'dispatcher','skpe_execute_governed_import_materialization',
      'dispatcher_version','COOTAQUARA-EVIDENCE-CHECKLIST-V1',
      'handler_name','skpe_materialize_import_request_as_evidence_checklist_item',
      'historical_evidence_management_import',true,
      'semantic_inference',false
    )
  );

  return jsonb_build_object(
    'request_id',v_request.id,
    'import_record_id',v_record.id,
    'source_family','evidence_management',
    'handler_name','skpe_materialize_import_request_as_evidence_checklist_item',
    'materialized_entity_type','evidence_checklist_item',
    'materialized_entity_id',v_entity_id,
    'request_status','applied',
    'already_materialized',false,
    'already_finalized',false,
    'finalization',v_finalize,
    'dispatcher','skpe_execute_governed_import_materialization',
    'dispatcher_version','COOTAQUARA-EVIDENCE-CHECKLIST-V1'
  );
end;
$function$;

revoke all on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
from public,anon,authenticated;
grant execute on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
to service_role;
