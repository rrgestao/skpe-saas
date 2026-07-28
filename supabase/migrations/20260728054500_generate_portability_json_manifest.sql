begin;

create extension if not exists pgcrypto;

-- Retorna registros de uma tabela permitida, filtrando pelo projeto.
-- A função é tolerante a módulos ainda não instalados: tabelas ausentes
-- ou sem a coluna project_id retornam um array vazio.
create or replace function public.portability_project_rows(
  target_table_name text,
  target_project_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_allowed_tables constant text[] := array[
    'skpe_journey_items',
    'skpe_project_canvases',
    'skpe_project_canvas_blocks',
    'skpe_project_canvas_items',
    'skpe_evidence_sources',
    'skpe_assessment_findings',
    'skpe_action_plans',
    'skpe_action_plan_items',
    'skpe_action_followups',
    'skpe_initiatives',
    'skpe_strategic_objectives',
    'skpe_initiative_objectives',
    'skpe_initiative_instruments',
    'skpe_key_results',
    'skpe_initiative_key_results',
    'skpe_business_artifacts',
    'skpe_business_artifact_blocks',
    'skpe_business_artifact_items',
    'skpe_business_artifact_links',
    'skpe_evidence_checklists',
    'skpe_evidence_checklist_items',
    'skpe_evidence_checklist_item_files',
    'skpe_evidence_checklist_assessments'
  ];
  v_result jsonb;
begin
  if target_table_name is null or not (target_table_name = any(v_allowed_tables)) then
    raise exception 'Tabela não autorizada para exportação: %', coalesce(target_table_name, '(nula)');
  end if;

  if to_regclass(format('public.%I', target_table_name)) is null then
    return '[]'::jsonb;
  end if;

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = target_table_name
      and column_name = 'project_id'
  ) then
    return '[]'::jsonb;
  end if;

  execute format(
    'select coalesce(jsonb_agg(to_jsonb(t)), ''[]''::jsonb) from public.%I t where t.project_id = $1',
    target_table_name
  ) into v_result using target_project_id;

  return coalesce(v_result, '[]'::jsonb);
end;
$$;

create or replace function public.generate_portability_json_export(
  target_package_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_package public.sparks_portability_packages%rowtype;
  v_project public.skpe_projects%rowtype;
  v_organization jsonb;
  v_data jsonb;
  v_counts jsonb;
  v_manifest jsonb;
  v_document jsonb;
  v_hash text;
  v_file_name text;
  v_now timestamptz := clock_timestamp();
  v_section jsonb;
  target_table_name text;
begin
  select * into v_package
  from public.sparks_portability_packages
  where id = target_package_id;

  if not found then
    raise exception 'Pacote de portabilidade não encontrado.';
  end if;

  if v_package.direction <> 'export' then
    raise exception 'O pacote informado não é uma exportação.';
  end if;

  if v_package.module_code <> 'SK-PE' then
    raise exception 'Esta versão gera somente exportações do módulo SK-PE.';
  end if;

  if not (
    public.is_platform_super_admin()
    or public.can_view_skpe_governance(v_package.organization_id)
  ) then
    raise exception 'Acesso negado para gerar esta exportação.' using errcode = '42501';
  end if;

  select to_jsonb(o) into v_organization
  from public.organizations o
  where o.id = v_package.organization_id;

  if v_organization is null then
    raise exception 'Organização do pacote não encontrada.';
  end if;

  if v_package.project_id is not null then
    select * into v_project
    from public.skpe_projects p
    where p.id = v_package.project_id
      and p.organization_id = v_package.organization_id;
  else
    select * into v_project
    from public.skpe_projects p
    where p.organization_id = v_package.organization_id
      and p.archived_at is null
    order by
      case p.status when 'active' then 0 when 'draft' then 1 else 2 end,
      p.updated_at desc
    limit 1;
  end if;

  if not found then
    raise exception 'A organização selecionada ainda não possui projeto de Planejamento Estratégico para exportação.';
  end if;

  -- Bloqueio explícito de vazamento entre organizações.
  if v_project.organization_id <> v_package.organization_id then
    raise exception 'O projeto não pertence à organização do pacote.' using errcode = '42501';
  end if;

  v_data := jsonb_build_object(
    'organizacao', v_organization,
    'projeto', to_jsonb(v_project)
  );
  v_counts := jsonb_build_object('organizacoes', 1, 'projetos', 1);

  foreach target_table_name in array array[
    'skpe_journey_items',
    'skpe_project_canvases',
    'skpe_project_canvas_blocks',
    'skpe_project_canvas_items',
    'skpe_evidence_sources',
    'skpe_assessment_findings',
    'skpe_action_plans',
    'skpe_action_plan_items',
    'skpe_action_followups',
    'skpe_initiatives',
    'skpe_strategic_objectives',
    'skpe_initiative_objectives',
    'skpe_initiative_instruments',
    'skpe_key_results',
    'skpe_initiative_key_results',
    'skpe_business_artifacts',
    'skpe_business_artifact_blocks',
    'skpe_business_artifact_items',
    'skpe_business_artifact_links',
    'skpe_evidence_checklists',
    'skpe_evidence_checklist_items',
    'skpe_evidence_checklist_item_files',
    'skpe_evidence_checklist_assessments'
  ]
  loop
    v_section := public.portability_project_rows(target_table_name, v_project.id);
    v_data := v_data || jsonb_build_object(target_table_name, v_section);
    v_counts := v_counts || jsonb_build_object(target_table_name, jsonb_array_length(v_section));
  end loop;

  v_file_name := concat(
    'SPARKs_PE_',
    regexp_replace(upper(coalesce(v_organization->>'code', v_organization->>'trade_name', 'ORGANIZACAO')), '[^A-Z0-9]+', '_', 'g'),
    '_', to_char(v_now, 'YYYYMMDD_HH24MISS'), '.json'
  );

  v_manifest := jsonb_build_object(
    'schema', 'SPARKS_PE_STRUCTURED_JSON',
    'schema_version', '1.0.0',
    'package_id', v_package.id,
    'package_code', v_package.package_code,
    'package_type', v_package.package_type,
    'module_code', v_package.module_code,
    'organization_id', v_package.organization_id,
    'organization_code', v_organization->>'code',
    'project_id', v_project.id,
    'project_code', v_project.code,
    'generated_at', v_now,
    'generated_by', auth.uid(),
    'source_environment', coalesce(v_package.source_environment, 'SPARKs SaaS'),
    'source_system', coalesce(v_package.source_system, 'Plataforma SPARKs'),
    'language', 'pt-BR',
    'confidentiality_level', v_package.confidentiality_level,
    'record_counts', v_counts,
    'file_name', v_file_name
  );

  v_document := jsonb_build_object(
    'manifesto', v_manifest,
    'dados', v_data
  );

  v_hash := encode(digest(convert_to(v_document::text, 'UTF8'), 'sha256'), 'hex');
  v_manifest := v_manifest || jsonb_build_object('sha256', v_hash);
  v_document := jsonb_build_object('manifesto', v_manifest, 'dados', v_data);

  update public.sparks_portability_packages
  set project_id = v_project.id,
      status = 'completed',
      file_name = v_file_name,
      manifest = v_manifest,
      record_counts = v_counts,
      integrity_hash = v_hash,
      started_at = coalesce(started_at, v_now),
      completed_at = v_now,
      error_message = null,
      metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
        'generated_format', 'json',
        'generated_locally_by_browser', true,
        'last_generation_at', v_now
      ),
      updated_at = v_now,
      updated_by = auth.uid()
  where id = v_package.id;

  insert into public.sparks_portability_audit (
    package_id, organization_id, actor_user_id, action_code,
    action_description, new_data, metadata
  ) values (
    v_package.id, v_package.organization_id, auth.uid(),
    'JSON_EXPORT_GENERATED',
    'Dados estruturados e manifesto gerados para download.',
    jsonb_build_object('file_name', v_file_name, 'sha256', v_hash, 'record_counts', v_counts),
    jsonb_build_object('project_id', v_project.id)
  );

  return v_document;
exception
  when others then
    update public.sparks_portability_packages
    set status = 'failed',
        error_message = sqlerrm,
        updated_at = clock_timestamp(),
        updated_by = auth.uid()
    where id = target_package_id;
    raise;
end;
$$;

revoke all on function public.portability_project_rows(text,uuid) from public, anon, authenticated;
grant execute on function public.portability_project_rows(text,uuid) to service_role;

grant execute on function public.generate_portability_json_export(uuid) to authenticated, service_role;

commit;

select
  to_regprocedure('public.generate_portability_json_export(uuid)') is not null as funcao_geracao_json,
  to_regprocedure('public.portability_project_rows(text,uuid)') is not null as funcao_coleta_controlada;
