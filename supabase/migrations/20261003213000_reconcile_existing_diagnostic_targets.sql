-- SK-PE - Reconcile existing diagnostic targets by canonical code
-- Extends the canonical resolver to diagnostic entities and upgrades
-- PESTEL/SWOT/TOWS/RISK mappings to prefer existing entities by code.
-- Human review remains mandatory. Missing targets may still be created
-- only after the governed review/decision/materialization gates.

create or replace function public.skpe_execute_resolution_handler_canonical_entity_by_code(
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
  v_source_value text;
  v_target_entity_type text;
  v_formulation_id uuid;
  v_same_project boolean;
  v_same_formulation boolean;
  v_status_found text;
  v_mode_found text;
  v_status_missing text;
  v_mode_missing text;
  v_match_count integer := 0;
  v_target_id uuid;
  v_target_code text;
  v_target_name text;
begin
  if p_config is null or jsonb_typeof(p_config) <> 'object' then
    raise exception using errcode='22023', message='Configuração do handler deve ser objeto JSON.';
  end if;

  if p_project_id is null then
    raise exception using errcode='22023', message='project_id é obrigatório para canonical_entity_by_code.';
  end if;

  v_target_entity_type := nullif(btrim(p_config ->> 'target_entity_type'),'');
  if v_target_entity_type is null then
    raise exception using errcode='22023', message='resolver_config.target_entity_type é obrigatório.';
  end if;

  if v_target_entity_type not in (
    'strategic_objective',
    'pestel_item',
    'swot_item',
    'tows_item',
    'strategic_risk_item'
  ) then
    raise exception using errcode='0A000', message='canonical_entity_by_code não suporta o target_entity_type informado.';
  end if;

  v_same_project := coalesce((p_config ->> 'same_project')::boolean,true);
  if v_same_project <> true then
    raise exception using errcode='0A000', message='canonical_entity_by_code exige same_project=true.';
  end if;

  v_same_formulation := coalesce(
    (p_config ->> 'same_formulation')::boolean,
    v_target_entity_type = 'strategic_objective'
  );

  if v_target_entity_type = 'strategic_objective' and v_same_formulation <> true then
    raise exception using errcode='0A000', message='strategic_objective exige same_formulation=true.';
  end if;

  if v_same_formulation then
    begin
      v_formulation_id := nullif(btrim(p_config ->> 'formulation_id'),'')::uuid;
    exception when others then
      raise exception using errcode='22023', message='resolver_config.formulation_id deve ser UUID válido.';
    end;

    if v_formulation_id is null then
      raise exception using errcode='22023', message='resolver_config.formulation_id é obrigatório.';
    end if;
  end if;

  v_status_found := coalesce(nullif(btrim(p_config ->> 'resolution_status_if_found'),''),'resolved');
  v_mode_found := coalesce(nullif(btrim(p_config ->> 'resolution_mode_if_found'),''),'existing_entity');
  v_status_missing := coalesce(nullif(btrim(p_config ->> 'resolution_status_if_missing'),''),'requires_review');
  v_mode_missing := coalesce(nullif(btrim(p_config ->> 'resolution_mode_if_missing'),''),'unresolved');

  if v_status_found not in ('resolved','requires_review','unresolved','blocked')
     or v_status_missing not in ('resolved','requires_review','unresolved','blocked') then
    raise exception using errcode='22023', message='resolution_status inválido.';
  end if;

  if v_mode_found not in ('existing_entity','create_new_entity','unresolved')
     or v_mode_missing not in ('existing_entity','create_new_entity','unresolved') then
    raise exception using errcode='22023', message='resolution_mode inválido.';
  end if;

  if v_mode_found <> 'existing_entity' then
    raise exception using errcode='22023', message='canonical_entity_by_code exige resolution_mode_if_found=existing_entity.';
  end if;

  v_source_value := nullif(btrim(p_source_value),'');
  if v_source_value is null then
    return jsonb_build_object(
      'resolution_status','blocked',
      'resolution_mode','unresolved',
      'target_entity_id',null,
      'target_external_key',null,
      'target_reference','{}'::jsonb,
      'resolution_details',jsonb_build_object(
        'target_entity_type',v_target_entity_type,
        'project_id',p_project_id,
        'formulation_id',v_formulation_id
      ),
      'warnings','[]'::jsonb,
      'blockers',jsonb_build_array(jsonb_build_object(
        'code','RESOLUTION_SOURCE_VALUE_MISSING',
        'message','Código necessário para resolução canônica não foi informado.'
      )),
      'requires_human_review',true
    );
  end if;

  if v_target_entity_type = 'strategic_objective' then
    select count(*) into v_match_count
    from public.skpe_strategic_objectives x
    where x.project_id=p_project_id
      and x.formulation_id=v_formulation_id
      and x.code=v_source_value;

    if v_match_count = 1 then
      select x.id,x.code,x.name into v_target_id,v_target_code,v_target_name
      from public.skpe_strategic_objectives x
      where x.project_id=p_project_id
        and x.formulation_id=v_formulation_id
        and x.code=v_source_value;
    end if;

  elsif v_target_entity_type = 'pestel_item' then
    select count(*) into v_match_count
    from public.skpe_pestel_items x
    where x.project_id=p_project_id and x.code=v_source_value;

    if v_match_count = 1 then
      select x.id,x.code into v_target_id,v_target_code
      from public.skpe_pestel_items x
      where x.project_id=p_project_id and x.code=v_source_value;
    end if;

  elsif v_target_entity_type = 'swot_item' then
    select count(*) into v_match_count
    from public.skpe_swot_items x
    where x.project_id=p_project_id and x.code=v_source_value;

    if v_match_count = 1 then
      select x.id,x.code into v_target_id,v_target_code
      from public.skpe_swot_items x
      where x.project_id=p_project_id and x.code=v_source_value;
    end if;

  elsif v_target_entity_type = 'tows_item' then
    select count(*) into v_match_count
    from public.skpe_tows_items x
    where x.project_id=p_project_id and x.code=v_source_value;

    if v_match_count = 1 then
      select x.id,x.code into v_target_id,v_target_code
      from public.skpe_tows_items x
      where x.project_id=p_project_id and x.code=v_source_value;
    end if;

  elsif v_target_entity_type = 'strategic_risk_item' then
    select count(*) into v_match_count
    from public.skpe_strategic_risk_items x
    where x.project_id=p_project_id and x.code=v_source_value;

    if v_match_count = 1 then
      select x.id,x.code into v_target_id,v_target_code
      from public.skpe_strategic_risk_items x
      where x.project_id=p_project_id and x.code=v_source_value;
    end if;
  end if;

  if v_match_count = 0 then
    return jsonb_build_object(
      'resolution_status',v_status_missing,
      'resolution_mode',v_mode_missing,
      'target_entity_id',null,
      'target_external_key',v_source_value,
      'target_reference',jsonb_strip_nulls(jsonb_build_object(
        'entity_type',v_target_entity_type,
        'code',v_source_value,
        'project_id',p_project_id,
        'formulation_id',v_formulation_id
      )),
      'resolution_details',jsonb_build_object(
        'source_value',v_source_value,
        'match_count',0,
        'match_strategy',case when v_same_formulation
          then 'exact_code_same_project_same_formulation'
          else 'exact_code_same_project'
        end
      ),
      'warnings',jsonb_build_array(jsonb_build_object(
        'code','TARGET_CANONICAL_ENTITY_NOT_FOUND',
        'target_entity_type',v_target_entity_type,
        'target_code',v_source_value,
        'message','Entidade canônica não foi localizada no escopo governado.'
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
      'target_external_key',v_source_value,
      'target_reference',jsonb_build_object(
        'entity_type',v_target_entity_type,
        'code',v_source_value,
        'project_id',p_project_id
      ),
      'resolution_details',jsonb_build_object(
        'source_value',v_source_value,
        'match_count',v_match_count,
        'match_strategy',case when v_same_formulation
          then 'exact_code_same_project_same_formulation'
          else 'exact_code_same_project'
        end
      ),
      'warnings','[]'::jsonb,
      'blockers',jsonb_build_array(jsonb_build_object(
        'code','TARGET_CANONICAL_ENTITY_AMBIGUOUS',
        'target_entity_type',v_target_entity_type,
        'target_code',v_source_value,
        'match_count',v_match_count,
        'message','Mais de uma entidade canônica corresponde ao código informado.'
      )),
      'requires_human_review',true
    );
  end if;

  return jsonb_build_object(
    'resolution_status',v_status_found,
    'resolution_mode',v_mode_found,
    'target_entity_id',v_target_id,
    'target_external_key',v_target_code,
    'target_reference',jsonb_strip_nulls(jsonb_build_object(
      'entity_type',v_target_entity_type,
      'entity_id',v_target_id,
      'code',v_target_code,
      'name',v_target_name,
      'project_id',p_project_id,
      'formulation_id',v_formulation_id
    )),
    'resolution_details',jsonb_build_object(
      'source_value',v_source_value,
      'target_code',v_target_code,
      'target_entity_id',v_target_id,
      'match_count',1,
      'match_strategy',case when v_same_formulation
        then 'exact_code_same_project_same_formulation'
        else 'exact_code_same_project'
      end
    ),
    'warnings','[]'::jsonb,
    'blockers','[]'::jsonb,
    'requires_human_review',true
  );
end;
$function$;

do $$
declare
  c record;
  v_old public.skpe_incorporation_mapping_versions%rowtype;
  v_new_id uuid;
begin
  for c in
    select *
    from public.skpe_incorporation_mapping_catalogs
    where mapping_code in (
      'pestel_to_pestel_item',
      'swot_to_swot_item',
      'tows_to_tows_item',
      'risk_to_strategic_risk_item'
    )
    order by mapping_code
  loop
    if c.current_version >= 2 then
      continue;
    end if;

    select * into v_old
    from public.skpe_incorporation_mapping_versions
    where catalog_id=c.id
      and version_number=c.current_version
      and version_status='active';

    if v_old.id is null then
      raise exception 'Mapping % não possui versão ativa.', c.mapping_code;
    end if;

    update public.skpe_incorporation_mapping_versions
    set version_status='superseded',
        effective_until=timezone('utc',now())
    where id=v_old.id;

    insert into public.skpe_incorporation_mapping_versions (
      catalog_id,
      version_number,
      version_status,
      effective_from,
      target_table,
      target_key_strategy,
      target_key_template,
      resolver_function_name,
      materializer_function_name,
      provenance_function_name,
      validation_profile,
      mapping_definition,
      created_by,
      activated_at,
      activated_by,
      supersedes_version_id,
      metadata
    )
    values (
      c.id,
      2,
      'active',
      timezone('utc',now()),
      v_old.target_table,
      v_old.target_key_strategy,
      v_old.target_key_template,
      v_old.resolver_function_name,
      v_old.materializer_function_name,
      v_old.provenance_function_name,
      v_old.validation_profile,
      v_old.mapping_definition || jsonb_build_object(
        'target_resolution','canonical_entity_by_code_or_create'
      ),
      auth.uid(),
      timezone('utc',now()),
      auth.uid(),
      v_old.id,
      coalesce(v_old.metadata,'{}'::jsonb) || jsonb_build_object(
        'upgrade_reason','Reconcile existing diagnostic entity by exact canonical code before proposing creation.',
        'semantic_inference',false,
        'requires_human_review',true
      )
    )
    returning id into v_new_id;

    insert into public.skpe_incorporation_resolution_rules (
      mapping_version_id,
      rule_sequence,
      rule_code,
      rule_type,
      source_field_name,
      target_entity_type,
      operator,
      expected_value,
      resolution_output,
      is_blocking,
      stop_on_match,
      metadata,
      resolver_handler_code,
      resolver_config,
      execution_mode,
      output_key,
      depends_on_rule_code
    )
    values (
      v_new_id,
      1,
      replace(c.mapping_code,'_to_','_') || '_existing_or_create',
      'custom',
      'codigo',
      c.target_entity_type,
      'exists',
      null,
      '{}'::jsonb,
      true,
      false,
      jsonb_build_object(
        'purpose','Use existing canonical diagnostic entity by exact code; create only when no exact target exists.',
        'semantic_inference',false,
        'materializes_entity',false
      ),
      'canonical_entity_by_code',
      jsonb_build_object(
        'target_entity_type',c.target_entity_type,
        'same_project',true,
        'same_formulation',false,
        'resolution_status_if_found','resolved',
        'resolution_mode_if_found','existing_entity',
        'resolution_status_if_missing','resolved',
        'resolution_mode_if_missing','create_new_entity'
      ),
      'terminal',
      'canonical_target',
      null
    );

    update public.skpe_incorporation_mapping_catalogs
    set current_version=2,
        allows_create_new=true,
        allows_existing_entity=true,
        resolution_strategy='hybrid',
        metadata=coalesce(metadata,'{}'::jsonb) || jsonb_build_object(
          'existing_target_reconciliation',true,
          'existing_target_match','exact_code_same_project',
          'upgraded_at',timezone('utc',now())
        )
    where id=c.id;
  end loop;
end $$;
