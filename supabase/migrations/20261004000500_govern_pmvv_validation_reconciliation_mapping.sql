-- SK-PE - Reconcile PMVV validation history with approved Strategic Identity items.
-- This migration preserves approved business content and adds only governed provenance.

create or replace function public.skpe_materialize_import_request_as_pmvv_validation_reference(
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
  v_target_id uuid;
begin
  perform public.skpe_assert_governed_import_materialization(p_request_id);

  select * into v_request
  from public.skpe_import_incorporation_requests
  where id=p_request_id;

  select * into v_record
  from public.skpe_import_records
  where id=v_request.import_record_id;

  if v_record.id is null or v_record.entity_code <> 'pmvv_validation' then
    raise exception using errcode='55000',message='Materializador PMVV Validation exige entity_code = pmvv_validation.';
  end if;

  select * into v_decision
  from public.skpe_import_incorporation_decisions d
  where d.incorporation_request_id=v_request.id
  order by d.decision_sequence desc
  limit 1;

  if v_decision.id is null
     or v_decision.permits_incorporation <> true
     or v_decision.decision_outcome not in ('approved','approved_with_reservations') then
    raise exception using errcode='55000',message='Decisão vigente não permite finalização da reconciliação PMVV.';
  end if;

  select * into v_resolution
  from public.skpe_import_target_resolution_events e
  where e.import_record_id=v_record.id
    and e.organization_id=v_request.organization_id
    and e.project_id=v_request.project_id
    and e.formulation_id is not distinct from v_request.formulation_id
    and e.source_entity_code='pmvv_validation'
    and e.target_entity_type='strategic_identity_item'
    and e.resolution_status='resolved'
    and e.resolution_mode='existing_entity'
    and e.target_entity_id is not null
    and coalesce(jsonb_array_length(e.blockers),0)=0
  order by e.resolved_at desc,e.resolution_sequence desc
  limit 1;

  if v_resolution.id is null then
    raise exception using errcode='55000',message='PMVV Validation não possui item de Identidade canônico resolvido.';
  end if;

  v_target_id:=v_resolution.target_entity_id;

  if not exists(
    select 1
    from public.skpe_strategic_identity_items x
    where x.id=v_target_id
      and x.project_id=v_request.project_id
      and x.formulation_id=v_request.formulation_id
      and x.validation_status='approved'
  ) then
    raise exception using errcode='55000',message='Alvo PMVV não é item aprovado de Identidade no mesmo escopo.';
  end if;

  insert into public.skpe_import_events(
    batch_id,organization_id,project_id,actor_user_id,event_code,event_data
  )
  values(
    v_record.batch_id,
    v_record.organization_id,
    v_record.project_id,
    p_materialized_by_user_id,
    'PMVV_VALIDATION_HISTORY_RECONCILED',
    jsonb_build_object(
      'importRecordId',v_record.id,
      'incorporationRequestId',v_request.id,
      'incorporationDecisionId',v_decision.id,
      'targetResolutionEventId',v_resolution.id,
      'targetEntityType','strategic_identity_item',
      'targetEntityId',v_target_id,
      'businessContentUpdated',false,
      'businessApprovalReopened',false,
      'historicalValidationPreserved',true,
      'reconciliationOnly',true,
      'semanticInference',false
    ) || p_metadata
  );

  return v_target_id;
end;
$function$;

revoke all on function public.skpe_materialize_import_request_as_pmvv_validation_reference(uuid,text,uuid,jsonb)
from public,anon,authenticated;
grant execute on function public.skpe_materialize_import_request_as_pmvv_validation_reference(uuid,text,uuid,jsonb)
to service_role;

do $$
declare
  v_catalog_id uuid;
  v_version_id uuid;
begin
  select id into v_catalog_id
  from public.skpe_incorporation_mapping_catalogs
  where mapping_code='pmvv_validation_to_existing_identity_item';

  if v_catalog_id is null then
    insert into public.skpe_incorporation_mapping_catalogs(
      mapping_code,mapping_name,description,source_entity_code,target_entity_type,
      resolution_strategy,materialization_strategy,provenance_strategy,
      requires_human_review,allows_create_new,allows_existing_entity,
      allows_semantic_inference,status,current_version,metadata,selection_priority,applicability
    )
    values(
      'pmvv_validation_to_existing_identity_item',
      'Validação histórica do PMVV → Identidade canônica aprovada',
      'Reconcilia a validação histórica de Propósito, Missão e Visão com os itens de Identidade já aprovados, preservando decisão e evidência sem reabrir o PMVV.',
      'pmvv_validation','strategic_identity_item',
      'existing_entity','direct_entity','a1_object_and_fields',
      true,false,true,false,'active',1,
      jsonb_build_object(
        'reconciliation_only',true,
        'historical_validation_preserved',true,
        'business_content_updated',false,
        'business_approval_reopened',false,
        'semantic_inference',false
      ),
      100,
      jsonb_build_object('module','SK-PE','semantic_family','pmvv_validation')
    )
    returning id into v_catalog_id;
  else
    update public.skpe_incorporation_mapping_catalogs
    set
      mapping_name='Validação histórica do PMVV → Identidade canônica aprovada',
      description='Reconcilia a validação histórica de Propósito, Missão e Visão com os itens de Identidade já aprovados, preservando decisão e evidência sem reabrir o PMVV.',
      source_entity_code='pmvv_validation',
      target_entity_type='strategic_identity_item',
      resolution_strategy='existing_entity',
      materialization_strategy='direct_entity',
      provenance_strategy='a1_object_and_fields',
      requires_human_review=true,
      allows_create_new=false,
      allows_existing_entity=true,
      allows_semantic_inference=false,
      status='active',
      current_version=1,
      selection_priority=100,
      applicability=jsonb_build_object('module','SK-PE','semantic_family','pmvv_validation'),
      metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object(
        'reconciliation_only',true,
        'historical_validation_preserved',true,
        'business_content_updated',false,
        'business_approval_reopened',false,
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
      'skpe_strategic_identity_items','existing_entity','{elemento}',
      'skpe_execute_import_resolution_rules',
      'skpe_materialize_import_request_as_pmvv_validation_reference',
      null,
      jsonb_build_object(
        'requires_human_review',true,
        'allows_semantic_inference',false,
        'require_valid_import_record',true,
        'require_approved_incorporation_items',true,
        'require_governed_incorporation_decision',true
      ),
      jsonb_build_object(
        'target_resolution','existing_identity_item_by_element',
        'historical_status_policy','preserve_in_metadata_only',
        'approval_policy','preserve_existing_business_approval',
        'field_map',jsonb_build_object(
          'redacao_recomendada','content'
        )
      ),
      timezone('utc',now()),
      jsonb_build_object(
        'reconciliation_only',true,
        'historical_validation_preserved',true,
        'common_finalizer','skpe_finalize_governed_import_materialization'
      )
    )
    returning id into v_version_id;
  else
    update public.skpe_incorporation_mapping_versions
    set
      version_status='active',
      effective_from=coalesce(effective_from,timezone('utc',now())),
      effective_until=null,
      target_table='skpe_strategic_identity_items',
      target_key_strategy='existing_entity',
      target_key_template='{elemento}',
      resolver_function_name='skpe_execute_import_resolution_rules',
      materializer_function_name='skpe_materialize_import_request_as_pmvv_validation_reference',
      validation_profile=jsonb_build_object(
        'requires_human_review',true,
        'allows_semantic_inference',false,
        'require_valid_import_record',true,
        'require_approved_incorporation_items',true,
        'require_governed_incorporation_decision',true
      ),
      mapping_definition=jsonb_build_object(
        'target_resolution','existing_identity_item_by_element',
        'historical_status_policy','preserve_in_metadata_only',
        'approval_policy','preserve_existing_business_approval',
        'field_map',jsonb_build_object('redacao_recomendada','content')
      ),
      activated_at=coalesce(activated_at,timezone('utc',now())),
      metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object(
        'reconciliation_only',true,
        'historical_validation_preserved',true,
        'common_finalizer','skpe_finalize_governed_import_materialization'
      )
    where id=v_version_id;
  end if;

  if not exists(
    select 1 from public.skpe_incorporation_resolution_rules
    where mapping_version_id=v_version_id
      and rule_code='pmvv_validation_existing_identity_item'
  ) then
    insert into public.skpe_incorporation_resolution_rules(
      mapping_version_id,rule_sequence,rule_code,rule_type,source_field_name,
      target_entity_type,operator,expected_value,resolution_output,is_blocking,
      stop_on_match,metadata,resolver_handler_code,resolver_config,execution_mode,
      output_key,depends_on_rule_code
    )
    values(
      v_version_id,1,'pmvv_validation_existing_identity_item','custom','elemento',
      'strategic_identity_item','exists',null,'{}'::jsonb,true,false,
      jsonb_build_object(
        'reconciliation_only',true,
        'historical_validation_preserved',true,
        'semantic_inference',false
      ),
      'strategic_identity_item_by_element','{}'::jsonb,'terminal','canonical_target',null
    );
  end if;
end $$;

create or replace function public.skpe_execute_governed_import_materialization(
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
  v_handler text;
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

  if v_record.entity_code not in (
    'key_result','pestel','swot','tows','risk',
    'strategic_identity','living_value','pmvv_validation'
  ) then
    return public.skpe_execute_governed_import_materialization_c8(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,p_metadata
    );
  end if;

  if v_record.entity_code='key_result' then
    v_target_type:='key_result';
    v_handler:='skpe_materialize_import_request_as_key_result';
  elsif v_record.entity_code='pestel' then
    v_target_type:='pestel_item';
    v_handler:='skpe_materialize_import_request_as_pestel';
  elsif v_record.entity_code='swot' then
    v_target_type:='swot_item';
    v_handler:='skpe_materialize_import_request_as_swot';
  elsif v_record.entity_code='tows' then
    v_target_type:='tows_item';
    v_handler:='skpe_materialize_import_request_as_tows';
  elsif v_record.entity_code='risk' then
    v_target_type:='strategic_risk_item';
    v_handler:='skpe_materialize_import_request_as_strategic_risk';
  elsif v_record.entity_code='strategic_identity' then
    v_target_type:='strategic_identity_item';
    v_handler:='skpe_materialize_import_request_as_existing_reference';
  elsif v_record.entity_code='living_value' then
    v_target_type:='strategic_value';
    v_handler:='skpe_materialize_import_request_as_existing_reference';
  else
    v_target_type:='strategic_identity_item';
    v_handler:='skpe_materialize_import_request_as_pmvv_validation_reference';
  end if;

  if v_request.request_status='applied' then
    begin
      v_entity_id:=nullif(v_request.metadata->>'materialized_target_entity_id','')::uuid;
    exception when invalid_text_representation then
      raise exception using errcode='55000',message='Request applied possui materialized_target_entity_id inválido.';
    end;

    if v_request.metadata->>'materialized_target_entity_type' <> v_target_type or v_entity_id is null then
      raise exception using errcode='55000',message='Request applied não possui alvo materializado compatível.';
    end if;

    if v_record.entity_code='key_result'
       and not exists(select 1 from public.skpe_key_results where id=v_entity_id) then
      raise exception using errcode='55000',message='Request key_result applied não possui alvo materializado verificável.';
    end if;
    if v_record.entity_code='pestel'
       and not exists(select 1 from public.skpe_pestel_items where id=v_entity_id) then
      raise exception using errcode='55000',message='Request pestel applied não possui alvo materializado verificável.';
    end if;
    if v_record.entity_code='swot'
       and not exists(select 1 from public.skpe_swot_items where id=v_entity_id) then
      raise exception using errcode='55000',message='Request swot applied não possui alvo materializado verificável.';
    end if;
    if v_record.entity_code='tows'
       and not exists(select 1 from public.skpe_tows_items where id=v_entity_id) then
      raise exception using errcode='55000',message='Request tows applied não possui alvo materializado verificável.';
    end if;
    if v_record.entity_code='risk'
       and not exists(select 1 from public.skpe_strategic_risk_items where id=v_entity_id) then
      raise exception using errcode='55000',message='Request risk applied não possui alvo materializado verificável.';
    end if;
    if v_record.entity_code in ('strategic_identity','pmvv_validation')
       and not exists(
         select 1 from public.skpe_strategic_identity_items
         where id=v_entity_id
           and project_id=v_request.project_id
           and formulation_id=v_request.formulation_id
       ) then
      raise exception using errcode='55000',message='Request de Identidade/PMVV applied não possui alvo reconciliado verificável.';
    end if;
    if v_record.entity_code='living_value'
       and not exists(
         select 1 from public.skpe_strategic_values
         where id=v_entity_id
           and project_id=v_request.project_id
           and formulation_id=v_request.formulation_id
       ) then
      raise exception using errcode='55000',message='Request living_value applied não possui alvo reconciliado verificável.';
    end if;

    return jsonb_build_object(
      'request_id',v_request.id,
      'import_record_id',v_record.id,
      'source_family',v_record.entity_code,
      'handler_name',v_handler,
      'materialized_entity_type',v_target_type,
      'materialized_entity_id',v_entity_id,
      'request_status','applied',
      'already_materialized',true,
      'already_finalized',true,
      'dispatcher','skpe_execute_governed_import_materialization',
      'dispatcher_version','COOTAQUARA-PMVV-RECON-V1'
    );
  end if;

  if v_record.entity_code='key_result' then
    v_entity_id:=public.skpe_materialize_import_request_as_key_result(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object('dispatcher_version','COOTAQUARA-PMVV-RECON-V1')
    );
  elsif v_record.entity_code='pestel' then
    v_entity_id:=public.skpe_materialize_import_request_as_pestel(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object('dispatcher_version','COOTAQUARA-PMVV-RECON-V1')
    );
  elsif v_record.entity_code='swot' then
    v_entity_id:=public.skpe_materialize_import_request_as_swot(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object('dispatcher_version','COOTAQUARA-PMVV-RECON-V1')
    );
  elsif v_record.entity_code='tows' then
    v_entity_id:=public.skpe_materialize_import_request_as_tows(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object('dispatcher_version','COOTAQUARA-PMVV-RECON-V1')
    );
  elsif v_record.entity_code='risk' then
    v_entity_id:=public.skpe_materialize_import_request_as_strategic_risk(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object('dispatcher_version','COOTAQUARA-PMVV-RECON-V1')
    );
  elsif v_record.entity_code in ('strategic_identity','living_value') then
    v_entity_id:=public.skpe_materialize_import_request_as_existing_reference(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object(
        'dispatcher_version','COOTAQUARA-PMVV-RECON-V1',
        'reconciliation_only',true,
        'business_content_updated',false,
        'business_approval_reopened',false,
        'semantic_inference',false
      )
    );
  else
    v_entity_id:=public.skpe_materialize_import_request_as_pmvv_validation_reference(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object(
        'dispatcher_version','COOTAQUARA-PMVV-RECON-V1',
        'reconciliation_only',true,
        'historical_validation_preserved',true,
        'business_content_updated',false,
        'business_approval_reopened',false,
        'semantic_inference',false
      )
    );
  end if;

  v_finalize:=public.skpe_finalize_governed_import_materialization(
    p_request_id,v_target_type,v_entity_id,
    p_materialized_by_actor_type,p_materialized_by_user_id,
    p_metadata||jsonb_build_object(
      'dispatcher','skpe_execute_governed_import_materialization',
      'dispatcher_version','COOTAQUARA-PMVV-RECON-V1',
      'handler_name',v_handler,
      'reconciliation_only',v_record.entity_code in ('strategic_identity','living_value','pmvv_validation'),
      'historical_validation_preserved',v_record.entity_code='pmvv_validation',
      'business_content_updated',case
        when v_record.entity_code in ('strategic_identity','living_value','pmvv_validation') then false
        else true
      end,
      'business_approval_reopened',false,
      'semantic_inference',false
    )
  );

  return jsonb_build_object(
    'request_id',v_request.id,
    'import_record_id',v_record.id,
    'source_family',v_record.entity_code,
    'handler_name',v_handler,
    'materialized_entity_type',v_target_type,
    'materialized_entity_id',v_entity_id,
    'request_status','applied',
    'already_materialized',false,
    'already_finalized',false,
    'finalization',v_finalize,
    'dispatcher','skpe_execute_governed_import_materialization',
    'dispatcher_version','COOTAQUARA-PMVV-RECON-V1'
  );
end;
$function$;

revoke all on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
from public,anon,authenticated;
grant execute on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
to service_role;
