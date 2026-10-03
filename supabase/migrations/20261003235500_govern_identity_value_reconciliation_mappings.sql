-- SK-PE - Governed reconciliation mappings for approved Strategic Identity and Values
-- No strategic business row is created or updated by these mappings.
-- They only resolve historical records to already approved canonical entities.

create or replace function public.skpe_execute_resolution_handler_strategic_identity_item_by_element(
  p_source_value text,
  p_project_id uuid,
  p_config jsonb
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_formulation_id uuid;
  v_element_type text;
  v_match_count integer := 0;
  v_target_id uuid;
  v_target_content text;
begin
  if p_project_id is null then
    raise exception using errcode='22023', message='project_id é obrigatório.';
  end if;

  begin
    v_formulation_id := nullif(btrim(p_config ->> 'formulation_id'),'')::uuid;
  exception when others then
    raise exception using errcode='22023', message='formulation_id inválido.';
  end;

  if v_formulation_id is null then
    raise exception using errcode='22023', message='formulation_id é obrigatório.';
  end if;

  case lower(btrim(coalesce(p_source_value,'')))
    when 'propósito' then v_element_type := 'purpose';
    when 'proposito' then v_element_type := 'purpose';
    when 'missão' then v_element_type := 'mission';
    when 'missao' then v_element_type := 'mission';
    when 'visão' then v_element_type := 'vision';
    when 'visao' then v_element_type := 'vision';
    else
      return jsonb_build_object(
        'resolution_status','blocked',
        'resolution_mode','unresolved',
        'target_entity_id',null,
        'target_external_key',null,
        'target_reference','{}'::jsonb,
        'resolution_details',jsonb_build_object('source_value',p_source_value),
        'warnings','[]'::jsonb,
        'blockers',jsonb_build_array(jsonb_build_object(
          'code','IDENTITY_ELEMENT_UNSUPPORTED',
          'message','Elemento histórico não corresponde a Propósito, Missão ou Visão.'
        )),
        'requires_human_review',true
      );
  end case;

  select count(*)
  into v_match_count
  from public.skpe_strategic_identity_items x
  where x.project_id=p_project_id
    and x.formulation_id=v_formulation_id
    and x.element_type=v_element_type;

  if v_match_count = 1 then
    select x.id,x.content
    into v_target_id,v_target_content
    from public.skpe_strategic_identity_items x
    where x.project_id=p_project_id
      and x.formulation_id=v_formulation_id
      and x.element_type=v_element_type;
  end if;

  if v_match_count = 0 then
    return jsonb_build_object(
      'resolution_status','requires_review',
      'resolution_mode','unresolved',
      'target_entity_id',null,
      'target_external_key',v_element_type,
      'target_reference',jsonb_build_object(
        'entity_type','strategic_identity_item',
        'element_type',v_element_type,
        'project_id',p_project_id,
        'formulation_id',v_formulation_id
      ),
      'resolution_details',jsonb_build_object(
        'source_value',p_source_value,
        'match_count',0,
        'match_strategy','exact_element_same_project_same_formulation'
      ),
      'warnings',jsonb_build_array(jsonb_build_object(
        'code','STRATEGIC_IDENTITY_ITEM_NOT_FOUND',
        'message','Elemento canônico de Identidade não localizado.'
      )),
      'blockers','[]'::jsonb,
      'requires_human_review',true
    );
  end if;

  if v_match_count > 1 then
    return jsonb_build_object(
      'resolution_status','blocked',
      'resolution_mode','unresolved',
      'target_entity_id',null,
      'target_external_key',v_element_type,
      'target_reference','{}'::jsonb,
      'resolution_details',jsonb_build_object(
        'source_value',p_source_value,
        'match_count',v_match_count
      ),
      'warnings','[]'::jsonb,
      'blockers',jsonb_build_array(jsonb_build_object(
        'code','STRATEGIC_IDENTITY_ITEM_AMBIGUOUS',
        'message','Mais de um elemento canônico corresponde ao item histórico.'
      )),
      'requires_human_review',true
    );
  end if;

  return jsonb_build_object(
    'resolution_status','resolved',
    'resolution_mode','existing_entity',
    'target_entity_id',v_target_id,
    'target_external_key',v_element_type,
    'target_reference',jsonb_build_object(
      'entity_type','strategic_identity_item',
      'entity_id',v_target_id,
      'element_type',v_element_type,
      'content',v_target_content,
      'project_id',p_project_id,
      'formulation_id',v_formulation_id
    ),
    'resolution_details',jsonb_build_object(
      'source_value',p_source_value,
      'match_count',1,
      'match_strategy','exact_element_same_project_same_formulation'
    ),
    'warnings','[]'::jsonb,
    'blockers','[]'::jsonb,
    'requires_human_review',true
  );
end;
$function$;

create or replace function public.skpe_execute_resolution_handler_strategic_value_by_name(
  p_source_value text,
  p_project_id uuid,
  p_config jsonb
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_formulation_id uuid;
  v_name text;
  v_match_count integer := 0;
  v_target_id uuid;
  v_target_code text;
begin
  if p_project_id is null then
    raise exception using errcode='22023', message='project_id é obrigatório.';
  end if;

  begin
    v_formulation_id := nullif(btrim(p_config ->> 'formulation_id'),'')::uuid;
  exception when others then
    raise exception using errcode='22023', message='formulation_id inválido.';
  end;

  if v_formulation_id is null then
    raise exception using errcode='22023', message='formulation_id é obrigatório.';
  end if;

  v_name := nullif(btrim(p_source_value),'');
  if v_name is null then
    return jsonb_build_object(
      'resolution_status','blocked',
      'resolution_mode','unresolved',
      'target_entity_id',null,
      'target_external_key',null,
      'target_reference','{}'::jsonb,
      'resolution_details','{}'::jsonb,
      'warnings','[]'::jsonb,
      'blockers',jsonb_build_array(jsonb_build_object(
        'code','STRATEGIC_VALUE_NAME_MISSING',
        'message','Nome do Valor não informado.'
      )),
      'requires_human_review',true
    );
  end if;

  select count(*)
  into v_match_count
  from public.skpe_strategic_values x
  where x.project_id=p_project_id
    and x.formulation_id=v_formulation_id
    and lower(btrim(x.name))=lower(v_name)
    and x.status <> 'archived';

  if v_match_count = 1 then
    select x.id,x.code
    into v_target_id,v_target_code
    from public.skpe_strategic_values x
    where x.project_id=p_project_id
      and x.formulation_id=v_formulation_id
      and lower(btrim(x.name))=lower(v_name)
      and x.status <> 'archived';
  end if;

  if v_match_count = 0 then
    return jsonb_build_object(
      'resolution_status','requires_review',
      'resolution_mode','unresolved',
      'target_entity_id',null,
      'target_external_key',v_name,
      'target_reference',jsonb_build_object(
        'entity_type','strategic_value',
        'name',v_name,
        'project_id',p_project_id,
        'formulation_id',v_formulation_id
      ),
      'resolution_details',jsonb_build_object(
        'source_value',v_name,
        'match_count',0,
        'match_strategy','exact_name_same_project_same_formulation'
      ),
      'warnings',jsonb_build_array(jsonb_build_object(
        'code','STRATEGIC_VALUE_NOT_FOUND',
        'message','Valor canônico não localizado.'
      )),
      'blockers','[]'::jsonb,
      'requires_human_review',true
    );
  end if;

  if v_match_count > 1 then
    return jsonb_build_object(
      'resolution_status','blocked',
      'resolution_mode','unresolved',
      'target_entity_id',null,
      'target_external_key',v_name,
      'target_reference','{}'::jsonb,
      'resolution_details',jsonb_build_object('match_count',v_match_count),
      'warnings','[]'::jsonb,
      'blockers',jsonb_build_array(jsonb_build_object(
        'code','STRATEGIC_VALUE_AMBIGUOUS',
        'message','Mais de um Valor canônico corresponde ao nome histórico.'
      )),
      'requires_human_review',true
    );
  end if;

  return jsonb_build_object(
    'resolution_status','resolved',
    'resolution_mode','existing_entity',
    'target_entity_id',v_target_id,
    'target_external_key',coalesce(v_target_code,v_name),
    'target_reference',jsonb_build_object(
      'entity_type','strategic_value',
      'entity_id',v_target_id,
      'code',v_target_code,
      'name',v_name,
      'project_id',p_project_id,
      'formulation_id',v_formulation_id
    ),
    'resolution_details',jsonb_build_object(
      'source_value',v_name,
      'match_count',1,
      'match_strategy','exact_name_same_project_same_formulation'
    ),
    'warnings','[]'::jsonb,
    'blockers','[]'::jsonb,
    'requires_human_review',true
  );
end;
$function$;

revoke all on function public.skpe_execute_resolution_handler_strategic_identity_item_by_element(text,uuid,jsonb) from public,anon,authenticated;
grant execute on function public.skpe_execute_resolution_handler_strategic_identity_item_by_element(text,uuid,jsonb) to service_role;
revoke all on function public.skpe_execute_resolution_handler_strategic_value_by_name(text,uuid,jsonb) from public,anon,authenticated;
grant execute on function public.skpe_execute_resolution_handler_strategic_value_by_name(text,uuid,jsonb) to service_role;

insert into public.skpe_incorporation_resolution_handlers (
  handler_code,handler_name,description,handler_type,handler_version,status,
  input_contract,output_contract,configuration_contract,allows_semantic_inference,metadata
)
values
(
  'strategic_identity_item_by_element',
  'Identidade Estratégica por elemento',
  'Resolve Propósito, Missão ou Visão já existentes na mesma Formulação, sem criar ou alterar conteúdo.',
  'canonical_lookup',1,'active',
  jsonb_build_object('required',jsonb_build_array('source_value','project_id','formulation_id')),
  jsonb_build_object('fields',jsonb_build_array('target_entity_id','target_external_key','target_reference','resolution_status','resolution_mode','warnings','blockers')),
  jsonb_build_object('required',jsonb_build_array('formulation_id')),
  false,
  jsonb_build_object('deterministic',true,'reconciliation_only',true,'materializes_entity',false)
),
(
  'strategic_value_by_name',
  'Valor Estratégico por nome',
  'Resolve Valor Estratégico já existente por nome exato na mesma Formulação, sem criar ou alterar conteúdo.',
  'canonical_lookup',1,'active',
  jsonb_build_object('required',jsonb_build_array('source_value','project_id','formulation_id')),
  jsonb_build_object('fields',jsonb_build_array('target_entity_id','target_external_key','target_reference','resolution_status','resolution_mode','warnings','blockers')),
  jsonb_build_object('required',jsonb_build_array('formulation_id')),
  false,
  jsonb_build_object('deterministic',true,'reconciliation_only',true,'materializes_entity',false)
)
on conflict (handler_code) do update
set
  handler_name=excluded.handler_name,
  description=excluded.description,
  handler_type=excluded.handler_type,
  handler_version=excluded.handler_version,
  status=excluded.status,
  input_contract=excluded.input_contract,
  output_contract=excluded.output_contract,
  configuration_contract=excluded.configuration_contract,
  allows_semantic_inference=excluded.allows_semantic_inference,
  metadata=coalesce(public.skpe_incorporation_resolution_handlers.metadata,'{}'::jsonb)||excluded.metadata;

create or replace function public.skpe_execute_incorporation_resolution_handler(
  p_handler_code text,
  p_source_value text,
  p_project_id uuid,
  p_config jsonb
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_handler public.skpe_incorporation_resolution_handlers%rowtype;
begin
  if nullif(btrim(p_handler_code),'') is null then
    raise exception using errcode='22023',message='resolver_handler_code é obrigatório.';
  end if;

  select * into v_handler
  from public.skpe_incorporation_resolution_handlers
  where handler_code=p_handler_code;

  if v_handler.id is null then
    raise exception using errcode='55000',message='Handler de resolução não cadastrado.';
  end if;

  if v_handler.status <> 'active' then
    raise exception using errcode='55000',message='Handler de resolução não está ativo.';
  end if;

  case p_handler_code
    when 'journey_item_by_numeric_token' then
      return public.skpe_execute_resolution_handler_journey_item_by_numeric_token(p_source_value,p_project_id,p_config);
    when 'create_new_entity_by_source_key' then
      return public.skpe_execute_resolution_handler_create_new_entity_by_source_key(p_source_value,p_project_id,p_config);
    when 'canonical_entity_by_code' then
      return public.skpe_execute_resolution_handler_canonical_entity_by_code(p_source_value,p_project_id,p_config);
    when 'cross_sheet_positional_create_new_candidate' then
      return public.skpe_execute_resolution_handler_cross_sheet_positional_create_new_candidate(p_source_value,p_project_id,p_config);
    when 'key_result_parent_okr_candidate' then
      return public.skpe_execute_resolution_handler_key_result_parent_okr_candidate(p_source_value,p_project_id,p_config);
    when 'strategic_identity_item_by_element' then
      return public.skpe_execute_resolution_handler_strategic_identity_item_by_element(p_source_value,p_project_id,p_config);
    when 'strategic_value_by_name' then
      return public.skpe_execute_resolution_handler_strategic_value_by_name(p_source_value,p_project_id,p_config);
    else
      raise exception using errcode='0A000',message='Handler cadastrado ainda não possui executor implementado.';
  end case;
end;
$function$;

create or replace function public.skpe_materialize_import_request_as_existing_reference(
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

  if v_record.entity_code not in ('strategic_identity','living_value') then
    raise exception using errcode='55000',message='Materializador de referência não suporta este entity_code.';
  end if;

  select * into v_decision
  from public.skpe_import_incorporation_decisions d
  where d.incorporation_request_id=v_request.id
  order by d.decision_sequence desc
  limit 1;

  if v_decision.id is null
     or v_decision.permits_incorporation <> true
     or v_decision.decision_outcome not in ('approved','approved_with_reservations') then
    raise exception using errcode='55000',message='Decisão vigente não permite finalização da reconciliação.';
  end if;

  select * into v_resolution
  from public.skpe_import_target_resolution_events e
  where e.import_record_id=v_record.id
    and e.organization_id=v_request.organization_id
    and e.project_id=v_request.project_id
    and e.formulation_id is not distinct from v_request.formulation_id
    and e.resolution_status='resolved'
    and e.resolution_mode='existing_entity'
    and e.target_entity_id is not null
    and coalesce(jsonb_array_length(e.blockers),0)=0
  order by e.resolved_at desc,e.resolution_sequence desc
  limit 1;

  if v_resolution.id is null then
    raise exception using errcode='55000',message='Reconciliação não possui alvo canônico existente resolvido.';
  end if;

  v_target_id := v_resolution.target_entity_id;

  if v_record.entity_code='strategic_identity' then
    if v_resolution.target_entity_type <> 'strategic_identity_item'
       or not exists(
         select 1 from public.skpe_strategic_identity_items x
         where x.id=v_target_id
           and x.project_id=v_request.project_id
           and x.formulation_id=v_request.formulation_id
       ) then
      raise exception using errcode='55000',message='Alvo de Identidade não é verificável no escopo do request.';
    end if;
  else
    if v_resolution.target_entity_type <> 'strategic_value'
       or not exists(
         select 1 from public.skpe_strategic_values x
         where x.id=v_target_id
           and x.project_id=v_request.project_id
           and x.formulation_id=v_request.formulation_id
       ) then
      raise exception using errcode='55000',message='Alvo de Valor não é verificável no escopo do request.';
    end if;
  end if;

  insert into public.skpe_import_events(
    batch_id,organization_id,project_id,actor_user_id,event_code,event_data
  )
  values(
    v_record.batch_id,
    v_record.organization_id,
    v_record.project_id,
    p_materialized_by_user_id,
    'EXISTING_CANONICAL_ENTITY_RECONCILED',
    jsonb_build_object(
      'importRecordId',v_record.id,
      'incorporationRequestId',v_request.id,
      'incorporationDecisionId',v_decision.id,
      'targetResolutionEventId',v_resolution.id,
      'targetEntityType',v_resolution.target_entity_type,
      'targetEntityId',v_target_id,
      'businessContentUpdated',false,
      'businessApprovalReopened',false,
      'reconciliationOnly',true,
      'semanticInference',false
    ) || p_metadata
  );

  return v_target_id;
end;
$function$;

revoke all on function public.skpe_materialize_import_request_as_existing_reference(uuid,text,uuid,jsonb) from public,anon,authenticated;
grant execute on function public.skpe_materialize_import_request_as_existing_reference(uuid,text,uuid,jsonb) to service_role;

do $$
declare
  v_catalog_id uuid;
  v_version_id uuid;
begin
  -- Strategic Identity
  select id into v_catalog_id
  from public.skpe_incorporation_mapping_catalogs
  where mapping_code='strategic_identity_to_existing_identity_item';

  if v_catalog_id is null then
    insert into public.skpe_incorporation_mapping_catalogs(
      mapping_code,mapping_name,description,source_entity_code,target_entity_type,
      resolution_strategy,materialization_strategy,provenance_strategy,
      requires_human_review,allows_create_new,allows_existing_entity,
      allows_semantic_inference,status,current_version,metadata,selection_priority,applicability
    )
    values(
      'strategic_identity_to_existing_identity_item',
      'Identidade histórica → elemento canônico já aprovado',
      'Reconcilia Propósito, Missão e Visão históricos com a Identidade Estratégica canônica existente, sem recriar ou alterar conteúdo aprovado.',
      'strategic_identity','strategic_identity_item',
      'existing_entity','direct_entity','a1_object_and_fields',
      true,false,true,false,'active',1,
      jsonb_build_object(
        'reconciliation_only',true,
        'business_content_updated',false,
        'business_approval_reopened',false,
        'semantic_inference',false
      ),
      100,
      jsonb_build_object('module','SK-PE','semantic_family','strategic_identity')
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
      'skpe_strategic_identity_items','existing_entity','{elemento}',
      'skpe_execute_import_resolution_rules',
      'skpe_materialize_import_request_as_existing_reference',
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
        'field_map',jsonb_build_object(
          'definicao_texto','content'
        )
      ),
      timezone('utc',now()),
      jsonb_build_object(
        'reconciliation_only',true,
        'common_finalizer','skpe_finalize_governed_import_materialization'
      )
    )
    returning id into v_version_id;
  end if;

  if not exists(
    select 1 from public.skpe_incorporation_resolution_rules
    where mapping_version_id=v_version_id
      and rule_code='strategic_identity_existing_item'
  ) then
    insert into public.skpe_incorporation_resolution_rules(
      mapping_version_id,rule_sequence,rule_code,rule_type,source_field_name,
      target_entity_type,operator,expected_value,resolution_output,is_blocking,
      stop_on_match,metadata,resolver_handler_code,resolver_config,execution_mode,
      output_key,depends_on_rule_code
    )
    values(
      v_version_id,1,'strategic_identity_existing_item','custom','elemento',
      'strategic_identity_item','exists',null,'{}'::jsonb,true,false,
      jsonb_build_object('reconciliation_only',true,'semantic_inference',false),
      'strategic_identity_item_by_element','{}'::jsonb,'terminal','canonical_target',null
    );
  end if;

  -- Strategic Values
  v_catalog_id := null;
  v_version_id := null;

  select id into v_catalog_id
  from public.skpe_incorporation_mapping_catalogs
  where mapping_code='living_value_to_existing_strategic_value';

  if v_catalog_id is null then
    insert into public.skpe_incorporation_mapping_catalogs(
      mapping_code,mapping_name,description,source_entity_code,target_entity_type,
      resolution_strategy,materialization_strategy,provenance_strategy,
      requires_human_review,allows_create_new,allows_existing_entity,
      allows_semantic_inference,status,current_version,metadata,selection_priority,applicability
    )
    values(
      'living_value_to_existing_strategic_value',
      'Valor histórico → Valor Estratégico canônico já aprovado',
      'Reconcilia Valores históricos com Valores Estratégicos canônicos existentes por nome exato, sem recriar ou alterar conteúdo aprovado.',
      'living_value','strategic_value',
      'existing_entity','direct_entity','a1_object_and_fields',
      true,false,true,false,'active',1,
      jsonb_build_object(
        'reconciliation_only',true,
        'business_content_updated',false,
        'business_approval_reopened',false,
        'semantic_inference',false
      ),
      100,
      jsonb_build_object('module','SK-PE','semantic_family','strategic_value')
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
      'skpe_strategic_values','existing_entity','{valor}',
      'skpe_execute_import_resolution_rules',
      'skpe_materialize_import_request_as_existing_reference',
      null,
      jsonb_build_object(
        'requires_human_review',true,
        'allows_semantic_inference',false,
        'require_valid_import_record',true,
        'require_approved_incorporation_items',true,
        'require_governed_incorporation_decision',true
      ),
      jsonb_build_object(
        'target_resolution','existing_strategic_value_by_name',
        'historical_status_policy','preserve_in_metadata_only',
        'field_map',jsonb_build_object(
          'valor','name',
          'declaracao_inspiradora','description'
        )
      ),
      timezone('utc',now()),
      jsonb_build_object(
        'reconciliation_only',true,
        'common_finalizer','skpe_finalize_governed_import_materialization'
      )
    )
    returning id into v_version_id;
  end if;

  if not exists(
    select 1 from public.skpe_incorporation_resolution_rules
    where mapping_version_id=v_version_id
      and rule_code='living_value_existing_value'
  ) then
    insert into public.skpe_incorporation_resolution_rules(
      mapping_version_id,rule_sequence,rule_code,rule_type,source_field_name,
      target_entity_type,operator,expected_value,resolution_output,is_blocking,
      stop_on_match,metadata,resolver_handler_code,resolver_config,execution_mode,
      output_key,depends_on_rule_code
    )
    values(
      v_version_id,1,'living_value_existing_value','custom','valor',
      'strategic_value','exists',null,'{}'::jsonb,true,false,
      jsonb_build_object('reconciliation_only',true,'semantic_inference',false),
      'strategic_value_by_name','{}'::jsonb,'terminal','canonical_target',null
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
    'key_result','pestel','swot','tows','risk','strategic_identity','living_value'
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
  else
    v_target_type:='strategic_value';
    v_handler:='skpe_materialize_import_request_as_existing_reference';
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
    if v_record.entity_code='strategic_identity'
       and not exists(
         select 1 from public.skpe_strategic_identity_items
         where id=v_entity_id
           and project_id=v_request.project_id
           and formulation_id=v_request.formulation_id
       ) then
      raise exception using errcode='55000',message='Request strategic_identity applied não possui alvo reconciliado verificável.';
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
      'dispatcher_version','COOTAQUARA-RECON-V1'
    );
  end if;

  if v_record.entity_code='key_result' then
    v_entity_id:=public.skpe_materialize_import_request_as_key_result(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object('dispatcher_version','COOTAQUARA-RECON-V1')
    );
  elsif v_record.entity_code='pestel' then
    v_entity_id:=public.skpe_materialize_import_request_as_pestel(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object('dispatcher_version','COOTAQUARA-RECON-V1')
    );
  elsif v_record.entity_code='swot' then
    v_entity_id:=public.skpe_materialize_import_request_as_swot(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object('dispatcher_version','COOTAQUARA-RECON-V1')
    );
  elsif v_record.entity_code='tows' then
    v_entity_id:=public.skpe_materialize_import_request_as_tows(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object('dispatcher_version','COOTAQUARA-RECON-V1')
    );
  elsif v_record.entity_code='risk' then
    v_entity_id:=public.skpe_materialize_import_request_as_strategic_risk(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object('dispatcher_version','COOTAQUARA-RECON-V1')
    );
  else
    v_entity_id:=public.skpe_materialize_import_request_as_existing_reference(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object(
        'dispatcher_version','COOTAQUARA-RECON-V1',
        'reconciliation_only',true,
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
      'dispatcher_version','COOTAQUARA-RECON-V1',
      'handler_name',v_handler,
      'reconciliation_only',v_record.entity_code in ('strategic_identity','living_value'),
      'business_content_updated',case when v_record.entity_code in ('strategic_identity','living_value') then false else true end,
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
    'dispatcher_version','COOTAQUARA-RECON-V1'
  );
end;
$function$;

revoke all on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb) from public,anon,authenticated;
grant execute on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb) to service_role;
