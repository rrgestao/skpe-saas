do $migration$
declare
  template_row public.sparks_checklist_templates%rowtype;
  source_version public.sparks_checklist_template_versions%rowtype;
  target_version_id uuid;
begin
  select * into template_row
  from public.sparks_checklist_templates
  where code = 'SPARKS-PEM00-GERAL';

  if template_row.id is null then
    raise exception 'Template SPARKS-PEM00-GERAL nÃ£o encontrado.';
  end if;

  select * into source_version
  from public.sparks_checklist_template_versions
  where template_id = template_row.id
    and version_code = '2026.1';

  if source_version.id is null then
    raise exception 'VersÃ£o fonte 2026.1 nÃ£o encontrada.';
  end if;

  select id into target_version_id
  from public.sparks_checklist_template_versions
  where template_id = template_row.id
    and version_code = '2026.2';

  if target_version_id is null then
    insert into public.sparks_checklist_template_versions (
      template_id, version_code, name, description, status,
      applicability_rule, effective_from, effective_until,
      published_at, created_by, updated_by
    ) values (
      template_row.id,
      '2026.2',
      'PadrÃ£o Geral 2026.2',
      'EvoluÃ§Ã£o versionada do checklist PEM-00 para diagnÃ³stico transversal de evidÃªncias, preservando os quinze eixos da versÃ£o 2026.1 e acrescentando semÃ¢ntica de disponibilidade, reutilizaÃ§Ã£o, validade, qualidade, suficiÃªncia, uso analÃ­tico, lacuna e benchmark.',
      'draft',
      source_version.applicability_rule || jsonb_build_object(
        'evidence_semantics_version', '2026.2',
        'preserves_taxonomy_from', '2026.1',
        'publication_requires_validation', true
      ),
      null,
      null,
      null,
      source_version.created_by,
      source_version.updated_by
    ) returning id into target_version_id;
  end if;

  if not exists (
    select 1 from public.sparks_checklist_template_items
    where template_version_id = target_version_id
  ) then
    insert into public.sparks_checklist_template_items (
      template_version_id, parent_item_id, code, item_type, name, description,
      request_reason, evidence_importance, is_required, applicability_rule,
      possible_evidences, best_practice_criteria, benchmark_guidance,
      absence_impact, display_order, metadata, created_by, updated_by
    )
    select
      target_version_id,
      null,
      src.code,
      src.item_type,
      src.name,
      src.description,
      src.request_reason,
      src.evidence_importance,
      src.is_required,
      src.applicability_rule,
      src.possible_evidences,
      src.best_practice_criteria,
      src.benchmark_guidance,
      src.absence_impact,
      src.display_order,
      src.metadata || jsonb_build_object(
        'derived_from_version', '2026.1',
        'executive_macro_category', case
          when src.code like 'EIXO-01%' or src.code like 'EIXO-02%' or src.code like 'EIXO-11%' or src.code like 'EIXO-15%' then 'governance'
          when src.code like 'EIXO-03%' or src.code like 'EIXO-04%' then 'strategy_and_business'
          else 'management'
        end,
        'evidence_diagnostic_semantics', jsonb_build_object(
          'expected', true,
          'availability', jsonb_build_array('available','partially_available','missing','not_applicable'),
          'reuse', jsonb_build_array('original','reused_from_other_process','not_reused'),
          'validity', jsonb_build_array('current','expired','undated','not_assessed'),
          'quality', jsonb_build_array('high','moderate','low','not_assessed'),
          'sufficiency', jsonb_build_array('sufficient','partial','insufficient','not_assessed'),
          'analytical_usage', jsonb_build_array('used','not_used','candidate'),
          'gap', jsonb_build_array('none','partial','material'),
          'benchmark_support', jsonb_build_array('none','internal_anonymized','external','normative')
        ),
        'semantic_rules', jsonb_build_object(
          'available_does_not_mean_used', true,
          'missing_does_not_automatically_block_planning', true,
          'benchmark_is_not_organization_factual_evidence', true
        )
      ),
      src.created_by,
      src.updated_by
    from public.sparks_checklist_template_items src
    where src.template_version_id = source_version.id
    order by src.display_order, src.code;

    update public.sparks_checklist_template_items tgt
    set parent_item_id = parent_tgt.id
    from public.sparks_checklist_template_items src,
         public.sparks_checklist_template_items parent_src,
         public.sparks_checklist_template_items parent_tgt
    where tgt.template_version_id = target_version_id
      and src.template_version_id = source_version.id
      and src.code = tgt.code
      and src.parent_item_id = parent_src.id
      and parent_src.template_version_id = source_version.id
      and parent_tgt.template_version_id = target_version_id
      and parent_tgt.code = parent_src.code;
  end if;
end
$migration$;