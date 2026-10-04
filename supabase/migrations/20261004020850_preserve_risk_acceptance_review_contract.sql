-- SK-PE - Preserve explicit COOTAQUARA risk acceptance facts in governed review.
-- This migration evolves only the human-review contract for the active risk mapping.
-- It does not create incorporation decisions, materialize entities, or alter business approval.

do $$
declare
  v_catalog public.skpe_incorporation_mapping_catalogs%rowtype;
  v_old public.skpe_incorporation_mapping_versions%rowtype;
  v_new_id uuid;
  v_new_number integer;
  v_field_map jsonb;
begin
  select * into v_catalog
  from public.skpe_incorporation_mapping_catalogs
  where mapping_code='risk_to_strategic_risk_item'
    and status='active';

  if v_catalog.id is null then
    raise exception using errcode='55000',
      message='Mapping risk_to_strategic_risk_item ativo não encontrado.';
  end if;

  select * into v_old
  from public.skpe_incorporation_mapping_versions
  where catalog_id=v_catalog.id
    and version_number=v_catalog.current_version;

  if v_old.id is null then
    raise exception using errcode='55000',
      message='Mapping de risco ativo sem versão corrente.';
  end if;

  v_field_map := coalesce(v_old.mapping_definition->'field_map','{}'::jsonb)
    || jsonb_build_object(
      'aceite_do_risco','risk_acceptance',
      'evidencia_do_aceite','acceptance_evidence',
      'reconhecimento_pela_direcao','management_recognition',
      'ciclo_de_implementacao','implementation_cycle',
      'destino_no_portfolio','portfolio_destination'
    );

  v_new_number := v_old.version_number + 1;

  select id into v_new_id
  from public.skpe_incorporation_mapping_versions
  where catalog_id=v_catalog.id
    and version_number=v_new_number;

  if v_new_id is null then
    update public.skpe_incorporation_mapping_versions
    set version_status='superseded',
        effective_until=coalesce(effective_until,timezone('utc',now())),
        metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object(
          'superseded_for_risk_acceptance_review_contract',true
        )
    where id=v_old.id
      and version_status='active';

    insert into public.skpe_incorporation_mapping_versions(
      catalog_id,version_number,version_status,effective_from,effective_until,
      target_table,target_key_strategy,target_key_template,resolver_function_name,
      materializer_function_name,provenance_function_name,validation_profile,
      mapping_definition,created_by,activated_at,activated_by,
      supersedes_version_id,metadata
    )
    values(
      v_catalog.id,v_new_number,'active',timezone('utc',now()),null,
      v_old.target_table,v_old.target_key_strategy,v_old.target_key_template,
      v_old.resolver_function_name,v_old.materializer_function_name,
      v_old.provenance_function_name,v_old.validation_profile,
      v_old.mapping_definition || jsonb_build_object(
        'field_map',v_field_map,
        'human_review_contract','explicit_risk_acceptance_fields_v1',
        'risk_acceptance_policy','preserve_explicit_source_fact',
        'formal_evidence_policy','do_not_fabricate'
      ),
      v_old.created_by,timezone('utc',now()),v_old.activated_by,
      v_old.id,
      coalesce(v_old.metadata,'{}'::jsonb)||jsonb_build_object(
        'review_preparation_enabled',true,
        'risk_acceptance_fields_preserved',true,
        'semantic_inference',false
      )
    )
    returning id into v_new_id;

    insert into public.skpe_incorporation_resolution_rules(
      mapping_version_id,rule_sequence,rule_code,rule_type,source_field_name,
      target_entity_type,operator,expected_value,resolution_output,is_blocking,
      stop_on_match,metadata,resolver_handler_code,resolver_config,
      execution_mode,output_key,depends_on_rule_code
    )
    select
      v_new_id,r.rule_sequence,r.rule_code,r.rule_type,r.source_field_name,
      r.target_entity_type,r.operator,r.expected_value,r.resolution_output,
      r.is_blocking,r.stop_on_match,
      coalesce(r.metadata,'{}'::jsonb)||jsonb_build_object(
        'copied_for_risk_acceptance_review_contract',true
      ),
      r.resolver_handler_code,r.resolver_config,r.execution_mode,
      r.output_key,r.depends_on_rule_code
    from public.skpe_incorporation_resolution_rules r
    where r.mapping_version_id=v_old.id
    order by r.rule_sequence;
  end if;

  update public.skpe_incorporation_mapping_versions
  set version_status='superseded',
      effective_until=coalesce(effective_until,timezone('utc',now()))
  where catalog_id=v_catalog.id
    and id<>v_new_id
    and version_status='active';

  update public.skpe_incorporation_mapping_catalogs
  set current_version=v_new_number,
      metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object(
        'current_review_contract','explicit_risk_acceptance_fields_v1',
        'risk_acceptance_fields_preserved',true,
        'semantic_inference',false
      )
  where id=v_catalog.id;
end $$;
