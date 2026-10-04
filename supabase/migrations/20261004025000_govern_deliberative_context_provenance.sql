-- SK-PE - Preserve client validation and deliberative gate rows as historical deliberative context.
-- Formal gate decisions remain governed exclusively by the canonical decision entity/materializer.

create or replace function public.skpe_materialize_import_request_as_deliberative_context_provenance(
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
begin
  perform public.skpe_assert_governed_import_materialization(p_request_id);

  select * into v_request
  from public.skpe_import_incorporation_requests
  where id=p_request_id;

  select * into v_record
  from public.skpe_import_records
  where id=v_request.import_record_id;

  if v_record.id is null
     or v_record.entity_code not in ('client_validation','deliberative_gate') then
    raise exception using errcode='55000',
      message='Materializador de contexto deliberativo não suporta este entity_code.';
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
      message='Decisão vigente não permite finalização do contexto deliberativo histórico.';
  end if;

  select * into v_resolution
  from public.skpe_import_target_resolution_events e
  where e.import_record_id=v_record.id
    and e.organization_id=v_request.organization_id
    and e.project_id=v_request.project_id
    and e.formulation_id is not distinct from v_request.formulation_id
    and e.target_entity_type='deliberative_context_provenance'
    and e.resolution_status='resolved'
    and e.resolution_mode='existing_entity'
    and e.target_entity_id is not null
    and coalesce(jsonb_array_length(e.blockers),0)=0
  order by e.resolved_at desc,e.resolution_sequence desc
  limit 1;

  if v_resolution.id is null then
    raise exception using errcode='55000',
      message='Contexto deliberativo não possui projeto canônico resolvido.';
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
      message='Âncora do contexto deliberativo não corresponde ao projeto canônico.';
  end if;

  insert into public.skpe_import_events(
    batch_id,organization_id,project_id,actor_user_id,event_code,event_data
  )
  values(
    v_record.batch_id,
    v_record.organization_id,
    v_record.project_id,
    p_materialized_by_user_id,
    'DELIBERATIVE_CONTEXT_RECONCILED',
    jsonb_build_object(
      'importRecordId',v_record.id,
      'incorporationRequestId',v_request.id,
      'incorporationDecisionId',v_decision.id,
      'targetResolutionEventId',v_resolution.id,
      'canonicalProjectId',v_project_id,
      'sourceEntityCode',v_record.entity_code,
      'sourceExternalKey',v_record.external_key,
      'formalGateDecisionCreated',false,
      'formalGovernanceDecisionCreated',false,
      'canonicalDecisionAuthority','entity_code=decision',
      'historicalContextPreserved',true,
      'semanticInference',false
    )||p_metadata
  );

  return v_project_id;
end;
$function$;

revoke all on function public.skpe_materialize_import_request_as_deliberative_context_provenance(uuid,text,uuid,jsonb)
from public,anon,authenticated;
grant execute on function public.skpe_materialize_import_request_as_deliberative_context_provenance(uuid,text,uuid,jsonb)
to service_role;

do $$
declare
  v_source_code text;
  v_mapping_code text;
  v_mapping_name text;
  v_description text;
  v_source_field text;
  v_catalog_id uuid;
  v_version_id uuid;
begin
  foreach v_source_code in array array['client_validation','deliberative_gate']
  loop
    if v_source_code='client_validation' then
      v_mapping_code:='client_validation_to_deliberative_context';
      v_mapping_name:='Validação do cliente → contexto deliberativo histórico';
      v_description:='Preserva registros históricos de validação do cliente como contexto/proveniência. Decisões formais permanecem sob a autoridade do entity_code decision.';
      v_source_field:='codigo';
    else
      v_mapping_code:='deliberative_gate_to_deliberative_context';
      v_mapping_name:='Itens do gate deliberativo → contexto deliberativo histórico';
      v_description:='Preserva a decomposição ABR/MOD/RIS do gate como contexto deliberativo, sem criar decisões formais duplicadas. A decisão ocorrida permanece sob a autoridade do entity_code decision.';
      v_source_field:='codigo';
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
        v_mapping_code,v_mapping_name,v_description,
        v_source_code,'deliberative_context_provenance',
        'existing_entity','evidence_only','a1_object',
        true,false,true,false,'active',1,
        jsonb_build_object(
          'historical_context_only',true,
          'formal_gate_decision_created',false,
          'formal_governance_decision_created',false,
          'canonical_decision_authority','entity_code=decision',
          'semantic_inference',false
        ),
        100,
        jsonb_build_object('module','SK-PE','semantic_family','deliberative_context')
      )
      returning id into v_catalog_id;
    else
      update public.skpe_incorporation_mapping_catalogs
      set mapping_name=v_mapping_name,
          description=v_description,
          source_entity_code=v_source_code,
          target_entity_type='deliberative_context_provenance',
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
          applicability=jsonb_build_object('module','SK-PE','semantic_family','deliberative_context'),
          metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object(
            'historical_context_only',true,
            'formal_gate_decision_created',false,
            'formal_governance_decision_created',false,
            'canonical_decision_authority','entity_code=decision',
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
        'skpe_materialize_import_request_as_deliberative_context_provenance',
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
          'formal_decision_policy','do_not_create',
          'canonical_decision_authority','entity_code=decision',
          'source_key_field',v_source_field
        ),
        timezone('utc',now()),
        jsonb_build_object(
          'historical_context_only',true,
          'common_finalizer','skpe_finalize_governed_import_materialization'
        )
      )
      returning id into v_version_id;
    end if;

    if not exists(
      select 1
      from public.skpe_incorporation_resolution_rules
      where mapping_version_id=v_version_id
        and rule_code=v_source_code||'_current_project_context'
    ) then
      insert into public.skpe_incorporation_resolution_rules(
        mapping_version_id,rule_sequence,rule_code,rule_type,source_field_name,
        target_entity_type,operator,expected_value,resolution_output,is_blocking,
        stop_on_match,metadata,resolver_handler_code,resolver_config,execution_mode,
        output_key,depends_on_rule_code
      )
      values(
        v_version_id,1,v_source_code||'_current_project_context','custom',v_source_field,
        'deliberative_context_provenance','exists',null,'{}'::jsonb,true,false,
        jsonb_build_object(
          'historical_context_only',true,
          'formal_decision_policy','do_not_create',
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
rename to skpe_execute_governed_import_materialization_evidence_recon_v1;

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

  if v_record.entity_code not in ('client_validation','deliberative_gate') then
    return public.skpe_execute_governed_import_materialization_evidence_recon_v1(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,p_metadata
    );
  end if;

  if v_request.request_status='applied' then
    begin
      v_entity_id:=nullif(v_request.metadata->>'materialized_target_entity_id','')::uuid;
    exception when invalid_text_representation then
      raise exception using errcode='55000',
        message='Request de contexto deliberativo applied possui materialized_target_entity_id inválido.';
    end;

    if v_request.metadata->>'materialized_target_entity_type' <> 'deliberative_context_provenance'
       or v_entity_id is null
       or not exists(
         select 1
         from public.skpe_projects p
         where p.id=v_entity_id
           and p.organization_id=v_request.organization_id
       ) then
      raise exception using errcode='55000',
        message='Request de contexto deliberativo applied não possui projeto canônico verificável.';
    end if;

    return jsonb_build_object(
      'request_id',v_request.id,
      'import_record_id',v_record.id,
      'source_family',v_record.entity_code,
      'handler_name','skpe_materialize_import_request_as_deliberative_context_provenance',
      'materialized_entity_type','deliberative_context_provenance',
      'materialized_entity_id',v_entity_id,
      'request_status','applied',
      'already_materialized',true,
      'already_finalized',true,
      'dispatcher','skpe_execute_governed_import_materialization',
      'dispatcher_version','COOTAQUARA-DELIBERATIVE-CONTEXT-V1'
    );
  end if;

  v_entity_id:=public.skpe_materialize_import_request_as_deliberative_context_provenance(
    p_request_id,
    p_materialized_by_actor_type,
    p_materialized_by_user_id,
    p_metadata||jsonb_build_object(
      'dispatcher_version','COOTAQUARA-DELIBERATIVE-CONTEXT-V1',
      'historical_context_only',true,
      'formal_gate_decision_created',false,
      'formal_governance_decision_created',false,
      'canonical_decision_authority','entity_code=decision',
      'semantic_inference',false
    )
  );

  v_finalize:=public.skpe_finalize_governed_import_materialization(
    p_request_id,
    'deliberative_context_provenance',
    v_entity_id,
    p_materialized_by_actor_type,
    p_materialized_by_user_id,
    p_metadata||jsonb_build_object(
      'dispatcher','skpe_execute_governed_import_materialization',
      'dispatcher_version','COOTAQUARA-DELIBERATIVE-CONTEXT-V1',
      'handler_name','skpe_materialize_import_request_as_deliberative_context_provenance',
      'historical_context_only',true,
      'formal_gate_decision_created',false,
      'formal_governance_decision_created',false,
      'canonical_decision_authority','entity_code=decision',
      'semantic_inference',false
    )
  );

  return jsonb_build_object(
    'request_id',v_request.id,
    'import_record_id',v_record.id,
    'source_family',v_record.entity_code,
    'handler_name','skpe_materialize_import_request_as_deliberative_context_provenance',
    'materialized_entity_type','deliberative_context_provenance',
    'materialized_entity_id',v_entity_id,
    'request_status','applied',
    'already_materialized',false,
    'already_finalized',false,
    'finalization',v_finalize,
    'dispatcher','skpe_execute_governed_import_materialization',
    'dispatcher_version','COOTAQUARA-DELIBERATIVE-CONTEXT-V1'
  );
end;
$function$;

revoke all on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
from public,anon,authenticated;
grant execute on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
to service_role;
