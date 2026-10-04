-- SK-PE - Add explicit human-review field maps to active incorporation mappings
-- that previously covered readiness but could not generate incorporation review items.
-- Semantics, target resolution and materializers are preserved; only review contracts evolve.

do $$
declare
  v_catalog public.skpe_incorporation_mapping_catalogs%rowtype;
  v_old public.skpe_incorporation_mapping_versions%rowtype;
  v_new_id uuid;
  v_new_number integer;
  v_field_map jsonb;
begin
  for v_catalog in
    select *
    from public.skpe_incorporation_mapping_catalogs
    where mapping_code in (
      'client_validation_to_deliberative_context',
      'decision_to_gate_decision',
      'deliberative_gate_to_deliberative_context',
      'evidence_to_existing_evidence_asset',
      'evidence_management_to_checklist_item',
      'methodology_artifact_to_canonical_artifact',
      'pending_item_to_project_pending_context',
      'pmvv_institutionalization_to_project_input_context',
      'traceability_to_project_snapshot_context'
    )
      and status='active'
    order by mapping_code
  loop
    select * into v_old
    from public.skpe_incorporation_mapping_versions
    where catalog_id=v_catalog.id
      and version_number=v_catalog.current_version;

    if v_old.id is null then
      raise exception using errcode='55000',
        message='Mapping ativo sem versão corrente: '||v_catalog.mapping_code;
    end if;

    if jsonb_typeof(v_old.mapping_definition->'field_map')='object'
       and exists(select 1 from jsonb_each(v_old.mapping_definition->'field_map')) then
      continue;
    end if;

    case v_catalog.mapping_code
      when 'client_validation_to_deliberative_context' then
        v_field_map:=jsonb_build_object(
          'artefato_tema','artefato_tema',
          'codigo','codigo',
          'condicao_ajuste','condicao_ajuste',
          'conteudo_submetido','conteudo_submetido',
          'data','data',
          'decisao_esperada','decisao_esperada',
          'evidencia_justificativa','evidencia_justificativa',
          'prazo','prazo',
          'registro_em_ata','registro_em_ata',
          'responsavel','responsavel',
          'situacao','situacao'
        );

      when 'decision_to_gate_decision' then
        v_field_map:=jsonb_build_object(
          'alternativas','alternativas',
          'codigo','codigo',
          'condicoes','condicoes',
          'data','data',
          'decisao','decisao',
          'evidencias','evidencias',
          'macrofase','macrofase',
          'prazo','prazo',
          'questao_decisoria','questao_decisoria',
          'responsavel','responsavel',
          'situacao','situacao',
          'tema','tema'
        );

      when 'deliberative_gate_to_deliberative_context' then
        v_field_map:=jsonb_build_object(
          'codigo','codigo',
          'impacto_no_avanco','impacto_no_avanco',
          'justificativa_condicao','justificativa_condicao',
          'prazo','prazo',
          'recomendacao','recomendacao',
          'registro_em_ata','registro_em_ata',
          'responsavel','responsavel',
          'situacao','situacao',
          'tema','tema',
          'tipo','tipo'
        );

      when 'evidence_to_existing_evidence_asset' then
        v_field_map:=jsonb_build_object(
          'acao_de_validacao','acao_de_validacao',
          'afirmacao_constatacao','afirmacao_constatacao',
          'classificacao','classificacao',
          'codigo','codigo',
          'confiabilidade','confiabilidade',
          'criticidade','criticidade',
          'data_periodo','data_periodo',
          'fonte','fonte',
          'limitacoes_lacuna','limitacoes_lacuna',
          'macrofase','macrofase',
          'oe_relacionado','oe_relacionado',
          'prazo','prazo',
          'responsavel','responsavel',
          'risco_relacionado','risco_relacionado',
          'status','status',
          'tema','tema'
        );

      when 'evidence_management_to_checklist_item' then
        v_field_map:=jsonb_build_object(
          'alerta','alerta',
          'atendimento','atendimento',
          'conclusao_da_consultoria','conclusao_da_consultoria',
          'data_versao','data_versao',
          'declaracao_da_organizacao','declaracao_da_organizacao',
          'evidencia_necessaria','evidencia_necessaria',
          'id','id',
          'lacuna_acao','lacuna_acao',
          'link_localizacao','link_localizacao',
          'macrofase','macrofase',
          'maturidade','maturidade',
          'nivel_e0_e5','nivel_e0_e5',
          'obrigatoria','obrigatoria',
          'por_que_e_necessaria','por_que_e_necessaria',
          'prazo','prazo',
          'responsavel','responsavel',
          'status','status',
          'tema_processo','tema_processo'
        );

      when 'methodology_artifact_to_canonical_artifact' then
        v_field_map:=jsonb_build_object(
          'artefato','artefato',
          'codigo','codigo',
          'data','data',
          'dependencia','dependencia',
          'local_repositorio','local_repositorio',
          'macrofase','macrofase',
          'proxima_revisao','proxima_revisao',
          'responsavel','responsavel',
          'status','status',
          'tipo','tipo',
          'validador','validador',
          'versao','versao'
        );

      when 'pending_item_to_project_pending_context' then
        v_field_map:=jsonb_build_object(
          'categoria','categoria',
          'codigo','codigo',
          'criticidade','criticidade',
          'dependencia','dependencia',
          'evidencia_de_conclusao','evidencia_de_conclusao',
          'macrofase','macrofase',
          'origem','origem',
          'pendencia_acao','pendencia_acao',
          'prazo','prazo',
          'responsavel','responsavel',
          'status','status'
        );

      when 'pmvv_institutionalization_to_project_input_context' then
        v_field_map:=jsonb_build_object(
          'como','como',
          'evidencia','evidencia',
          'id','id',
          'indicador','indicador',
          'meta','meta',
          'o_que','o_que',
          'observacao','observacao',
          'onde_canal','onde_canal',
          'para_quem','para_quem',
          'por_que','por_que',
          'quando','quando',
          'quanto','quanto',
          'quem','quem',
          'status','status'
        );

      when 'traceability_to_project_snapshot_context' then
        v_field_map:=jsonb_build_object(
          'aprendizado_revisao','aprendizado_revisao',
          'decisao','decisao',
          'desvio_acao','desvio_acao',
          'diagnostico','diagnostico',
          'eixo','eixo',
          'evidencia','evidencia',
          'id','id',
          'indicador','indicador',
          'iniciativa','iniciativa',
          'linha_de_base','linha_de_base',
          'meta','meta',
          'objetivo','objetivo',
          'resultado','resultado',
          'risco','risco',
          'status_de_integridade','status_de_integridade'
        );

      else
        raise exception using errcode='55000',
          message='Mapping sem field_map explícito nesta migration: '||v_catalog.mapping_code;
    end case;

    v_new_number:=v_old.version_number+1;

    select id into v_new_id
    from public.skpe_incorporation_mapping_versions
    where catalog_id=v_catalog.id
      and version_number=v_new_number;

    if v_new_id is null then
      update public.skpe_incorporation_mapping_versions
      set version_status='superseded',
          effective_until=coalesce(effective_until,timezone('utc',now())),
          metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object(
            'superseded_for_review_contract',true
          )
      where id=v_old.id
        and version_status='active';

      insert into public.skpe_incorporation_mapping_versions(
        catalog_id,
        version_number,
        version_status,
        effective_from,
        effective_until,
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
      values(
        v_catalog.id,
        v_new_number,
        'active',
        timezone('utc',now()),
        null,
        v_old.target_table,
        v_old.target_key_strategy,
        v_old.target_key_template,
        v_old.resolver_function_name,
        v_old.materializer_function_name,
        v_old.provenance_function_name,
        v_old.validation_profile,
        v_old.mapping_definition || jsonb_build_object(
          'field_map',v_field_map,
          'human_review_contract','explicit_source_fields_v1'
        ),
        v_old.created_by,
        timezone('utc',now()),
        v_old.activated_by,
        v_old.id,
        coalesce(v_old.metadata,'{}'::jsonb) || jsonb_build_object(
          'review_preparation_enabled',true,
          'review_field_map_added',true,
          'semantic_inference',false
        )
      )
      returning id into v_new_id;

      insert into public.skpe_incorporation_resolution_rules(
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
      select
        v_new_id,
        r.rule_sequence,
        r.rule_code,
        r.rule_type,
        r.source_field_name,
        r.target_entity_type,
        r.operator,
        r.expected_value,
        r.resolution_output,
        r.is_blocking,
        r.stop_on_match,
        coalesce(r.metadata,'{}'::jsonb)||jsonb_build_object(
          'copied_for_review_contract_v2',true
        ),
        r.resolver_handler_code,
        r.resolver_config,
        r.execution_mode,
        r.output_key,
        r.depends_on_rule_code
      from public.skpe_incorporation_resolution_rules r
      where r.mapping_version_id=v_old.id
      order by r.rule_sequence;
    end if;

    update public.skpe_incorporation_mapping_versions
    set version_status='superseded',
        effective_until=coalesce(effective_until,timezone('utc',now())),
        metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object(
          'superseded_for_review_contract',true
        )
    where id=v_old.id
      and id<>v_new_id
      and version_status='active';

    update public.skpe_incorporation_mapping_catalogs
    set current_version=v_new_number,
        metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object(
          'review_preparation_enabled',true,
          'current_review_contract','explicit_source_fields_v1'
        )
    where id=v_catalog.id;
  end loop;
end $$;
