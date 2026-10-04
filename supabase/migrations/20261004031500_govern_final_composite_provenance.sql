-- SK-PE - Final composite mappings for pending items, PMVV institutionalization and traceability.
-- These historical composite rows are preserved as governed project provenance.
-- No action plan, initiative, identity content or cross-entity traceability links are fabricated.

create or replace function public.skpe_materialize_import_request_as_composite_project_provenance(
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
  v_project_id uuid;
  v_expected_target_type text;
  v_event_code text;
  v_requires_future_curation boolean := false;
  v_source_code text;
begin
  perform public.skpe_assert_governed_import_materialization(p_request_id);

  select * into v_request
  from public.skpe_import_incorporation_requests
  where id=p_request_id;

  select * into v_record
  from public.skpe_import_records
  where id=v_request.import_record_id;

  if v_record.id is null
     or v_record.entity_code not in ('pending_item','pmvv_institutionalization','traceability') then
    raise exception using errcode='55000',
      message='Materializador de proveniência composta não suporta este entity_code.';
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
      message='Decisão vigente não permite finalização da proveniência composta.';
  end if;

  if v_record.entity_code='pending_item' then
    v_expected_target_type:='pending_context_provenance';
    v_event_code:='HISTORICAL_PENDING_CONTEXT_RECONCILED';
    v_source_code:=nullif(btrim(v_record.values_json->>'codigo'),'');
    v_requires_future_curation :=
      lower(btrim(coalesce(v_record.values_json->>'status',''))) not in ('concluído','concluido')
      or v_source_code is null
      or nullif(btrim(v_record.values_json->>'pendencia_acao'),'') is null;
  elsif v_record.entity_code='pmvv_institutionalization' then
    v_expected_target_type:='pmvv_institutionalization_input_provenance';
    v_event_code:='PMVV_INSTITUTIONALIZATION_INPUT_RECONCILED';
    v_source_code:=nullif(btrim(v_record.values_json->>'id'),'');
    v_requires_future_curation :=
      lower(btrim(coalesce(v_record.values_json->>'status',''))) not in ('concluído','concluido');
  else
    v_expected_target_type:='traceability_snapshot_provenance';
    v_event_code:='HISTORICAL_TRACEABILITY_SNAPSHOT_RECONCILED';
    v_source_code:=nullif(btrim(v_record.values_json->>'id'),'');
    v_requires_future_curation := true;
  end if;

  select * into v_resolution
  from public.skpe_import_target_resolution_events e
  where e.import_record_id=v_record.id
    and e.organization_id=v_request.organization_id
    and e.project_id=v_request.project_id
    and e.formulation_id is not distinct from v_request.formulation_id
    and e.target_entity_type=v_expected_target_type
    and e.resolution_status='resolved'
    and e.resolution_mode='existing_entity'
    and e.target_entity_id is not null
    and coalesce(jsonb_array_length(e.blockers),0)=0
  order by e.resolved_at desc,e.resolution_sequence desc
  limit 1;

  if v_resolution.id is null then
    raise exception using errcode='55000',
      message='Registro composto não possui projeto canônico resolvido.';
  end if;

  v_project_id:=v_resolution.target_entity_id;

  if v_project_id <> v_record.project_id
     or not exists(
       select 1
       from public.skpe_projects p
       where p.id=v_project_id
         and p.organization_id=v_request.organization_id
     ) then
    raise exception using errcode='55000',
      message='Âncora de proveniência composta não corresponde ao projeto canônico.';
  end if;

  insert into public.skpe_import_events(
    batch_id,organization_id,project_id,actor_user_id,event_code,event_data
  )
  values(
    v_record.batch_id,
    v_record.organization_id,
    v_record.project_id,
    p_materialized_by_user_id,
    v_event_code,
    jsonb_build_object(
      'importRecordId',v_record.id,
      'incorporationRequestId',v_request.id,
      'incorporationDecisionId',v_decision.id,
      'targetResolutionEventId',v_resolution.id,
      'canonicalProjectId',v_project_id,
      'sourceEntityCode',v_record.entity_code,
      'sourceCode',v_source_code,
      'sourceExternalKey',v_record.external_key,
      'requiresFutureCuration',v_requires_future_curation,
      'businessEntityCreated',false,
      'businessEntityUpdated',false,
      'actionPlanCreated',false,
      'initiativeCreated',false,
      'identityUpdated',false,
      'traceabilityLinksCreated',false,
      'historicalPayloadPreservedInImportRecord',true,
      'semanticInference',false
    )||p_metadata
  );

  return v_project_id;
end;
$function$;

revoke all on function public.skpe_materialize_import_request_as_composite_project_provenance(uuid,text,uuid,jsonb)
from public,anon,authenticated;
grant execute on function public.skpe_materialize_import_request_as_composite_project_provenance(uuid,text,uuid,jsonb)
to service_role;

do $$
declare
  v_source_code text;
  v_mapping_code text;
  v_mapping_name text;
  v_description text;
  v_target_type text;
  v_source_field text;
  v_semantic_family text;
  v_catalog_id uuid;
  v_version_id uuid;
begin
  foreach v_source_code in array array['pending_item','pmvv_institutionalization','traceability']
  loop
    if v_source_code='pending_item' then
      v_mapping_code:='pending_item_to_project_pending_context';
      v_mapping_name:='Pendência histórica → contexto governado do projeto';
      v_description:='Preserva pendências históricas heterogêneas, inclusive itens concluídos, ativos e linhas incompletas, sem criar plano de ação sem plano-pai e curadoria.';
      v_target_type:='pending_context_provenance';
      v_source_field:='codigo';
      v_semantic_family:='pending_context';
    elsif v_source_code='pmvv_institutionalization' then
      v_mapping_code:='pmvv_institutionalization_to_project_input_context';
      v_mapping_name:='Institucionalização PMVV → insumo governado do projeto';
      v_description:='Preserva ações históricas/concebidas de institucionalização do PMVV como insumos para desenvolvimento posterior, sem alterar Identidade ou criar ação executiva automaticamente.';
      v_target_type:='pmvv_institutionalization_input_provenance';
      v_source_field:='id';
      v_semantic_family:='pmvv_institutionalization_input';
    else
      v_mapping_code:='traceability_to_project_snapshot_context';
      v_mapping_name:='Rastreabilidade histórica → snapshot governado do projeto';
      v_description:='Preserva linhas históricas compostas de rastreabilidade sem fabricar vínculos entre decisão, risco, OE, indicador, iniciativa ou evidência ainda não consolidados.';
      v_target_type:='traceability_snapshot_provenance';
      v_source_field:='id';
      v_semantic_family:='traceability_snapshot';
    end if;

    select id into v_catalog_id
    from public.skpe_incorporation_mapping_catalogs
    where mapping_code=v_mapping_code;

    if v_catalog_id is null then
      insert into public.skpe_incorporation_mapping_catalogs(
        mapping_code,mapping_name,description,source_entity_code,target_entity_type,
        resolution_strategy,materialization_strategy,provenance_strategy,
        requires_human_review,allows_create_new,allows_existing_entity,
        allows_semantic_inference,status,current_version,metadata,selection_priority,applicability
      )
      values(
        v_mapping_code,v_mapping_name,v_description,v_source_code,v_target_type,
        'existing_entity','evidence_only','a1_object',
        true,false,true,false,'active',1,
        jsonb_build_object(
          'composite_historical_context',true,
          'business_entity_created',false,
          'business_entity_updated',false,
          'requires_future_curation',
            case when v_source_code='traceability' then true else null end,
          'semantic_inference',false
        ),
        100,
        jsonb_build_object('module','SK-PE','semantic_family',v_semantic_family)
      )
      returning id into v_catalog_id;
    else
      update public.skpe_incorporation_mapping_catalogs
      set mapping_name=v_mapping_name,
          description=v_description,
          source_entity_code=v_source_code,
          target_entity_type=v_target_type,
          resolution_strategy='existing_entity',
          materialization_strategy='evidence_only',
          provenance_strategy='a1_object',
          requires_human_review=true,
          allows_create_new=false,
          allows_existing_entity=true,
          allows_semantic_inference=false,
          status='active',
          current_version=1,
          selection_priority=100,
          applicability=jsonb_build_object('module','SK-PE','semantic_family',v_semantic_family),
          metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object(
            'composite_historical_context',true,
            'business_entity_created',false,
            'business_entity_updated',false,
            'semantic_inference',false
          )
      where id=v_catalog_id;
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
        'skpe_projects','existing_entity','{project_id}',
        'skpe_execute_import_resolution_rules',
        'skpe_materialize_import_request_as_composite_project_provenance',
        null,
        jsonb_build_object(
          'requires_human_review',true,
          'allows_semantic_inference',false,
          'require_valid_import_record',true,
          'require_approved_incorporation_items',true,
          'require_governed_incorporation_decision',true
        ),
        jsonb_build_object(
          'target_resolution','current_canonical_project',
          'historical_payload_policy','preserve_in_import_record',
          'source_key_field',v_source_field,
          'business_materialization','none',
          'future_curation_required',
            case
              when v_source_code='traceability' then true
              when v_source_code='pending_item' then 'record_dependent'
              when v_source_code='pmvv_institutionalization' then 'record_dependent'
            end,
          'guardrail',
            case
              when v_source_code='pending_item'
                then 'do_not_create_action_plan_or_action_item_without_curated_parent_plan'
              when v_source_code='pmvv_institutionalization'
                then 'do_not_change_identity_or_create_execution_action_automatically'
              else 'do_not_create_cross_entity_links_from_composite_historical_row'
            end
        ),
        timezone('utc',now()),
        jsonb_build_object(
          'composite_historical_context',true,
          'common_finalizer','skpe_finalize_governed_import_materialization'
        )
      )
      returning id into v_version_id;
    end if;

    if not exists(
      select 1
      from public.skpe_incorporation_resolution_rules
      where mapping_version_id=v_version_id
        and rule_code=v_source_code||'_current_project_provenance'
    ) then
      insert into public.skpe_incorporation_resolution_rules(
        mapping_version_id,rule_sequence,rule_code,rule_type,source_field_name,
        target_entity_type,operator,expected_value,resolution_output,is_blocking,
        stop_on_match,metadata,resolver_handler_code,resolver_config,execution_mode,
        output_key,depends_on_rule_code
      )
      values(
        v_version_id,1,v_source_code||'_current_project_provenance','custom',v_source_field,
        v_target_type,'exists',null,'{}'::jsonb,true,false,
        jsonb_build_object(
          'composite_historical_context',true,
          'semantic_inference',false
        ),
        'current_project_reference','{}'::jsonb,'terminal','canonical_target',null
      );
    end if;

    v_catalog_id:=null;
    v_version_id:=null;
  end loop;
end $$;

alter function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
rename to skpe_execute_governed_import_materialization_deliberative_context_v1;

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
  v_target_type text;
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

  if v_record.entity_code not in ('pending_item','pmvv_institutionalization','traceability') then
    return public.skpe_execute_governed_import_materialization_deliberative_context_v1(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,p_metadata
    );
  end if;

  if v_record.entity_code='pending_item' then
    v_target_type:='pending_context_provenance';
  elsif v_record.entity_code='pmvv_institutionalization' then
    v_target_type:='pmvv_institutionalization_input_provenance';
  else
    v_target_type:='traceability_snapshot_provenance';
  end if;

  if v_request.request_status='applied' then
    begin
      v_entity_id:=nullif(v_request.metadata->>'materialized_target_entity_id','')::uuid;
    exception when invalid_text_representation then
      raise exception using errcode='55000',
        message='Request de proveniência composta applied possui materialized_target_entity_id inválido.';
    end;

    if v_request.metadata->>'materialized_target_entity_type' <> v_target_type
       or v_entity_id is null
       or not exists(
         select 1
         from public.skpe_projects p
         where p.id=v_entity_id
           and p.organization_id=v_request.organization_id
       ) then
      raise exception using errcode='55000',
        message='Request de proveniência composta applied não possui projeto canônico verificável.';
    end if;

    return jsonb_build_object(
      'request_id',v_request.id,
      'import_record_id',v_record.id,
      'source_family',v_record.entity_code,
      'handler_name','skpe_materialize_import_request_as_composite_project_provenance',
      'materialized_entity_type',v_target_type,
      'materialized_entity_id',v_entity_id,
      'request_status','applied',
      'already_materialized',true,
      'already_finalized',true,
      'dispatcher','skpe_execute_governed_import_materialization',
      'dispatcher_version','COOTAQUARA-COMPOSITE-PROVENANCE-V1'
    );
  end if;

  v_entity_id:=public.skpe_materialize_import_request_as_composite_project_provenance(
    p_request_id,
    p_materialized_by_actor_type,
    p_materialized_by_user_id,
    p_metadata||jsonb_build_object(
      'dispatcher_version','COOTAQUARA-COMPOSITE-PROVENANCE-V1',
      'composite_historical_context',true,
      'business_entity_created',false,
      'business_entity_updated',false,
      'semantic_inference',false
    )
  );

  v_finalize:=public.skpe_finalize_governed_import_materialization(
    p_request_id,
    v_target_type,
    v_entity_id,
    p_materialized_by_actor_type,
    p_materialized_by_user_id,
    p_metadata||jsonb_build_object(
      'dispatcher','skpe_execute_governed_import_materialization',
      'dispatcher_version','COOTAQUARA-COMPOSITE-PROVENANCE-V1',
      'handler_name','skpe_materialize_import_request_as_composite_project_provenance',
      'composite_historical_context',true,
      'business_entity_created',false,
      'business_entity_updated',false,
      'semantic_inference',false
    )
  );

  return jsonb_build_object(
    'request_id',v_request.id,
    'import_record_id',v_record.id,
    'source_family',v_record.entity_code,
    'handler_name','skpe_materialize_import_request_as_composite_project_provenance',
    'materialized_entity_type',v_target_type,
    'materialized_entity_id',v_entity_id,
    'request_status','applied',
    'already_materialized',false,
    'already_finalized',false,
    'finalization',v_finalize,
    'dispatcher','skpe_execute_governed_import_materialization',
    'dispatcher_version','COOTAQUARA-COMPOSITE-PROVENANCE-V1'
  );
end;
$function$;

revoke all on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
from public,anon,authenticated;
grant execute on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
to service_role;
