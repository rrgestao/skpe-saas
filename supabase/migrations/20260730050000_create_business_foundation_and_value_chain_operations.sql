-- ============================================================
-- Plataforma SPARKs / SK-PE
-- FE-03 — Fundamentação do Negócio e Cadeia de Valor Essencial
--
-- Princípios:
-- 1. O SK-PE é autossuficiente para criar os insumos essenciais.
-- 2. A contratação do SK-PN não é requisito para a Formulação.
-- 3. Os artefatos pertencem ao domínio compartilhado da Plataforma.
-- 4. O SK-PN poderá aprofundar as mesmas versões ou criar revisões.
-- 5. A Formulação preserva a versão exata e o snapshot utilizado.
-- 6. Escritas ocorrem somente por funções auditadas.
-- 7. Versões validadas ou publicadas são imutáveis.
-- 8. A Formulação somente avança com Fundamentação e Cadeia de
--    Valor completas, validadas e vinculadas.
-- ============================================================

begin;

-- ============================================================
-- 1. ÍNDICES COMPLEMENTARES
-- ============================================================

create index if not exists idx_platform_business_elements_readiness
  on public.platform_business_artifact_elements(
    artifact_version_id,
    block_code,
    status
  );

create index if not exists idx_platform_business_element_relations_version
  on public.platform_business_artifact_element_relations(
    artifact_version_id,
    relation_type
  );

create index if not exists idx_platform_business_versions_source_project
  on public.platform_business_artifact_versions(
    source_skpe_project_id,
    status,
    maturity_level
  );

-- ============================================================
-- 2. VALIDAÇÃO DE EDITABILIDADE DA VERSÃO
-- ============================================================

create or replace function public.skpe_assert_business_artifact_version_editable(
  target_artifact_version_id uuid
)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  version_row public.platform_business_artifact_versions%rowtype;
begin
  select *
  into version_row
  from public.platform_business_artifact_versions
  where id = target_artifact_version_id;

  if not found then
    raise exception 'Versão do artefato de negócio não encontrada.'
      using errcode = '22023';
  end if;

  if not public.can_manage_business_architecture(version_row.organization_id) then
    raise exception
      'Acesso negado: o usuário não pode alterar este artefato de negócio.'
      using errcode = '42501';
  end if;

  if version_row.status not in ('draft', 'in_elaboration') then
    raise exception
      'A versão do artefato está bloqueada na situação "%". Crie uma revisão ou devolva-a para elaboração.',
      version_row.status
      using errcode = '55000';
  end if;
end;
$$;

comment on function public.skpe_assert_business_artifact_version_editable(uuid) is
  'Valida existência, autorização e situação editável da versão compartilhada do artefato de negócio.';

-- ============================================================
-- 3. PROTEÇÃO DO CONTEÚDO DAS VERSÕES
-- ============================================================

create or replace function public.skpe_guard_business_artifact_version_content()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_version_id uuid;
  version_status text;
begin
  if tg_op = 'DELETE' then
    target_version_id := old.artifact_version_id;
  else
    target_version_id := new.artifact_version_id;
  end if;

  select version.status
  into version_status
  from public.platform_business_artifact_versions version
  where version.id = target_version_id;

  if version_status is null then
    raise exception 'Versão do artefato de negócio não encontrada.'
      using errcode = '22023';
  end if;

  if version_status not in ('draft', 'in_elaboration') then
    raise exception
      'O conteúdo do artefato está bloqueado na situação "%".',
      version_status
      using errcode = '55000';
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;

  return new;
end;
$$;

drop trigger if exists platform_business_artifact_elements_guard_version
  on public.platform_business_artifact_elements;

create trigger platform_business_artifact_elements_guard_version
before insert or update or delete
on public.platform_business_artifact_elements
for each row
execute function public.skpe_guard_business_artifact_version_content();

drop trigger if exists platform_business_artifact_element_relations_guard_version
  on public.platform_business_artifact_element_relations;

create trigger platform_business_artifact_element_relations_guard_version
before insert or update or delete
on public.platform_business_artifact_element_relations
for each row
execute function public.skpe_guard_business_artifact_version_content();

comment on function public.skpe_guard_business_artifact_version_content() is
  'Bloqueia alterações dos elementos e relações quando a versão não estiver em rascunho ou elaboração.';

-- ============================================================
-- 4. CRIAÇÃO DO ARTEFATO E DA PRIMEIRA VERSÃO
-- ============================================================

create or replace function public.create_skpe_business_artifact(
  target_formulation_id uuid,
  new_artifact_code text,
  new_artifact_name text,
  new_artifact_description text,
  new_artifact_type text,
  new_methodology_code text,
  new_version_label text,
  new_version_summary text default null,
  new_maturity_level text default 'essential',
  change_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  artifact_row public.platform_business_artifacts%rowtype;
  version_row public.platform_business_artifact_versions%rowtype;
  normalized_type text;
  normalized_maturity text;
begin
  perform public.skpe_assert_reason(change_reason);
  perform public.skpe_assert_formulation_editable(target_formulation_id);

  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = target_formulation_id;

  if not found then
    raise exception 'Versão da Formulação Estratégica não encontrada.'
      using errcode = '22023';
  end if;

  if not public.can_manage_business_architecture(formulation_row.organization_id) then
    raise exception
      'Acesso negado para criar artefatos compartilhados de negócio.'
      using errcode = '42501';
  end if;

  if length(trim(coalesce(new_artifact_code, ''))) = 0 then
    raise exception 'Informe o código do artefato de negócio.'
      using errcode = '22023';
  end if;

  if length(trim(coalesce(new_artifact_name, ''))) = 0 then
    raise exception 'Informe o nome do artefato de negócio.'
      using errcode = '22023';
  end if;

  if length(trim(coalesce(new_version_label, ''))) = 0 then
    raise exception 'Informe o rótulo da versão.'
      using errcode = '22023';
  end if;

  normalized_type := lower(trim(coalesce(new_artifact_type, '')));
  normalized_maturity := lower(trim(coalesce(new_maturity_level, 'essential')));

  if normalized_type not in (
    'business_foundation',
    'value_proposition_canvas',
    'business_model_canvas',
    'value_chain',
    'stakeholder_map',
    'product_service_portfolio',
    'market_analysis',
    'capability_map',
    'process_architecture',
    'financial_model',
    'risk_hypothesis_map',
    'other_canvas'
  ) then
    raise exception 'Tipo inválido para o artefato de negócio.'
      using errcode = '22023';
  end if;

  if normalized_maturity not in (
    'essential',
    'structured',
    'complete',
    'validated',
    'published'
  ) then
    raise exception 'Nível de maturidade inválido.'
      using errcode = '22023';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      formulation_row.organization_id::text || ':' || lower(trim(new_artifact_code)),
      0
    )
  );

  if exists (
    select 1
    from public.platform_business_artifacts artifact
    where artifact.organization_id = formulation_row.organization_id
      and lower(artifact.code) = lower(trim(new_artifact_code))
  ) then
    raise exception
      'Já existe um artefato de negócio com este código na organização.'
      using errcode = '23505';
  end if;

  insert into public.platform_business_artifacts (
    organization_id,
    code,
    name,
    description,
    artifact_type,
    methodology_code,
    status,
    metadata,
    created_by,
    updated_by
  )
  values (
    formulation_row.organization_id,
    trim(new_artifact_code),
    trim(new_artifact_name),
    new_artifact_description,
    normalized_type,
    new_methodology_code,
    'active',
    jsonb_build_object(
      'createdFromSkpeFormulationId', formulation_row.id,
      'createdFromSkpeProjectId', formulation_row.project_id
    ),
    auth.uid(),
    auth.uid()
  )
  returning *
  into artifact_row;

  insert into public.platform_business_artifact_versions (
    organization_id,
    artifact_id,
    version_number,
    version_label,
    methodology_version,
    origin_module,
    origin_service_type,
    source_entity_type,
    source_entity_id,
    source_skpe_project_id,
    maturity_level,
    completeness_percent,
    status,
    summary,
    content_payload,
    metadata,
    created_by,
    updated_by
  )
  values (
    formulation_row.organization_id,
    artifact_row.id,
    1,
    trim(new_version_label),
    null,
    'SK-PE',
    'strategic_planning',
    'skpe_strategic_formulation',
    formulation_row.id,
    formulation_row.project_id,
    normalized_maturity,
    0,
    'draft',
    new_version_summary,
    '{}'::jsonb,
    jsonb_build_object(
      'createdInSkpe', true,
      'skpnLicenseRequired', false
    ),
    auth.uid(),
    auth.uid()
  )
  returning *
  into version_row;

  perform public.skpe_record_operational_audit(
    artifact_row.organization_id,
    formulation_row.project_id,
    'platform_business_artifact',
    artifact_row.id,
    'business_artifact_created',
    change_reason,
    null,
    to_jsonb(artifact_row)
  );

  perform public.skpe_record_operational_audit(
    version_row.organization_id,
    formulation_row.project_id,
    'platform_business_artifact_version',
    version_row.id,
    'business_artifact_version_created',
    change_reason,
    null,
    to_jsonb(version_row)
  );

  return jsonb_build_object(
    'artifactId', artifact_row.id,
    'artifactVersionId', version_row.id,
    'artifactType', artifact_row.artifact_type,
    'versionNumber', version_row.version_number,
    'status', version_row.status
  );
end;
$$;

-- ============================================================
-- 5. ATUALIZAÇÃO DO CABEÇALHO DA VERSÃO
-- ============================================================

create or replace function public.update_skpe_business_artifact_version(
  target_artifact_version_id uuid,
  new_version_label text,
  new_version_summary text,
  new_maturity_level text,
  new_content_payload jsonb default null,
  new_metadata jsonb default null,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_version public.platform_business_artifact_versions%rowtype;
  updated_version public.platform_business_artifact_versions%rowtype;
  normalized_maturity text;
begin
  perform public.skpe_assert_reason(change_reason);

  select *
  into previous_version
  from public.platform_business_artifact_versions
  where id = target_artifact_version_id
  for update;

  if not found then
    raise exception 'Versão do artefato de negócio não encontrada.'
      using errcode = '22023';
  end if;

  perform public.skpe_assert_business_artifact_version_editable(
    target_artifact_version_id
  );

  if length(trim(coalesce(new_version_label, ''))) = 0 then
    raise exception 'Informe o rótulo da versão.'
      using errcode = '22023';
  end if;

  normalized_maturity := lower(trim(coalesce(new_maturity_level, 'essential')));

  if normalized_maturity not in (
    'essential',
    'structured',
    'complete',
    'validated',
    'published'
  ) then
    raise exception 'Nível de maturidade inválido.'
      using errcode = '22023';
  end if;

  if new_content_payload is not null
     and jsonb_typeof(new_content_payload) <> 'object' then
    raise exception 'O conteúdo estruturado deve ser um objeto JSON.'
      using errcode = '22023';
  end if;

  if new_metadata is not null
     and jsonb_typeof(new_metadata) <> 'object' then
    raise exception 'Os metadados devem ser um objeto JSON.'
      using errcode = '22023';
  end if;

  update public.platform_business_artifact_versions
  set
    version_label = trim(new_version_label),
    summary = new_version_summary,
    maturity_level = normalized_maturity,
    content_payload = coalesce(new_content_payload, content_payload),
    metadata = coalesce(new_metadata, metadata),
    status = case
      when status = 'draft' then 'in_elaboration'
      else status
    end,
    validation_notes = null,
    updated_by = auth.uid()
  where id = target_artifact_version_id
  returning *
  into updated_version;

  perform public.skpe_record_operational_audit(
    updated_version.organization_id,
    updated_version.source_skpe_project_id,
    'platform_business_artifact_version',
    updated_version.id,
    'business_artifact_version_updated',
    change_reason,
    to_jsonb(previous_version),
    to_jsonb(updated_version)
  );

  return updated_version.id;
end;
$$;

-- ============================================================
-- 6. ELEMENTOS DO ARTEFATO
-- ============================================================

create or replace function public.upsert_skpe_business_artifact_element(
  target_artifact_version_id uuid,
  new_element_code text,
  new_block_code text,
  new_element_type text,
  new_title text,
  new_description text default null,
  new_structured_payload jsonb default null,
  new_parent_element_id uuid default null,
  new_display_order integer default 100,
  target_element_id uuid default null,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  version_row public.platform_business_artifact_versions%rowtype;
  previous_element public.platform_business_artifact_elements%rowtype;
  saved_element public.platform_business_artifact_elements%rowtype;
  parent_element public.platform_business_artifact_elements%rowtype;
  action_code text;
begin
  perform public.skpe_assert_reason(change_reason);
  perform public.skpe_assert_business_artifact_version_editable(
    target_artifact_version_id
  );

  select *
  into version_row
  from public.platform_business_artifact_versions
  where id = target_artifact_version_id;

  if length(trim(coalesce(new_element_code, ''))) = 0 then
    raise exception 'Informe o código do elemento.'
      using errcode = '22023';
  end if;

  if length(trim(coalesce(new_element_type, ''))) = 0 then
    raise exception 'Informe o tipo do elemento.'
      using errcode = '22023';
  end if;

  if length(trim(coalesce(new_title, ''))) = 0 then
    raise exception 'Informe o título do elemento.'
      using errcode = '22023';
  end if;

  if new_display_order < 0 then
    raise exception 'A ordem de exibição não pode ser negativa.'
      using errcode = '22023';
  end if;

  if new_structured_payload is not null
     and jsonb_typeof(new_structured_payload) <> 'object' then
    raise exception 'O conteúdo estruturado do elemento deve ser um objeto JSON.'
      using errcode = '22023';
  end if;

  if new_parent_element_id is not null then
    select *
    into parent_element
    from public.platform_business_artifact_elements
    where id = new_parent_element_id
      and artifact_version_id = target_artifact_version_id;

    if not found then
      raise exception
        'O elemento pai deve pertencer à mesma versão do artefato.'
        using errcode = '22023';
    end if;

    if target_element_id is not null
       and new_parent_element_id = target_element_id then
      raise exception 'Um elemento não pode ser pai de si próprio.'
        using errcode = '22023';
    end if;
  end if;

  if target_element_id is not null then
    select *
    into previous_element
    from public.platform_business_artifact_elements
    where id = target_element_id
      and artifact_version_id = target_artifact_version_id
    for update;

    if not found then
      raise exception 'Elemento não encontrado nesta versão.'
        using errcode = '22023';
    end if;

    update public.platform_business_artifact_elements
    set
      parent_element_id = new_parent_element_id,
      block_code = nullif(trim(coalesce(new_block_code, '')), ''),
      element_code = trim(new_element_code),
      element_type = trim(new_element_type),
      title = trim(new_title),
      description = new_description,
      structured_payload = coalesce(
        new_structured_payload,
        structured_payload
      ),
      display_order = new_display_order,
      status = 'active',
      updated_by = auth.uid()
    where id = previous_element.id
    returning *
    into saved_element;

    action_code := 'business_artifact_element_updated';
  else
    insert into public.platform_business_artifact_elements (
      organization_id,
      artifact_id,
      artifact_version_id,
      parent_element_id,
      block_code,
      element_code,
      element_type,
      title,
      description,
      structured_payload,
      display_order,
      status,
      metadata,
      created_by,
      updated_by
    )
    values (
      version_row.organization_id,
      version_row.artifact_id,
      version_row.id,
      new_parent_element_id,
      nullif(trim(coalesce(new_block_code, '')), ''),
      trim(new_element_code),
      trim(new_element_type),
      trim(new_title),
      new_description,
      coalesce(new_structured_payload, '{}'::jsonb),
      new_display_order,
      'active',
      '{}'::jsonb,
      auth.uid(),
      auth.uid()
    )
    returning *
    into saved_element;

    action_code := 'business_artifact_element_created';
  end if;

  update public.platform_business_artifact_versions
  set
    status = case
      when status = 'draft' then 'in_elaboration'
      else status
    end,
    validation_notes = null,
    updated_by = auth.uid()
  where id = target_artifact_version_id;

  perform public.skpe_record_operational_audit(
    saved_element.organization_id,
    version_row.source_skpe_project_id,
    'platform_business_artifact_element',
    saved_element.id,
    action_code,
    change_reason,
    case
      when previous_element.id is null then null
      else to_jsonb(previous_element)
    end,
    to_jsonb(saved_element)
  );

  return saved_element.id;
end;
$$;

create or replace function public.archive_skpe_business_artifact_element(
  target_element_id uuid,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_element public.platform_business_artifact_elements%rowtype;
  archived_element public.platform_business_artifact_elements%rowtype;
  version_row public.platform_business_artifact_versions%rowtype;
begin
  perform public.skpe_assert_reason(change_reason);

  select *
  into previous_element
  from public.platform_business_artifact_elements
  where id = target_element_id
  for update;

  if not found then
    raise exception 'Elemento do artefato não encontrado.'
      using errcode = '22023';
  end if;

  perform public.skpe_assert_business_artifact_version_editable(
    previous_element.artifact_version_id
  );

  select *
  into version_row
  from public.platform_business_artifact_versions
  where id = previous_element.artifact_version_id;

  update public.platform_business_artifact_elements
  set
    status = 'archived',
    updated_by = auth.uid()
  where id = previous_element.id
  returning *
  into archived_element;

  update public.platform_business_artifact_versions
  set
    validation_notes = null,
    updated_by = auth.uid()
  where id = previous_element.artifact_version_id;

  perform public.skpe_record_operational_audit(
    archived_element.organization_id,
    version_row.source_skpe_project_id,
    'platform_business_artifact_element',
    archived_element.id,
    'business_artifact_element_archived',
    change_reason,
    to_jsonb(previous_element),
    to_jsonb(archived_element)
  );

  return archived_element.id;
end;
$$;

-- ============================================================
-- 7. RELAÇÕES ENTRE ELEMENTOS
-- ============================================================

create or replace function public.upsert_skpe_business_element_relation(
  target_artifact_version_id uuid,
  new_source_element_id uuid,
  new_target_element_id uuid,
  new_relation_type text,
  new_contribution_weight numeric default null,
  new_rationale text default null,
  new_metadata jsonb default null,
  target_relation_id uuid default null,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  version_row public.platform_business_artifact_versions%rowtype;
  source_element public.platform_business_artifact_elements%rowtype;
  target_element public.platform_business_artifact_elements%rowtype;
  previous_relation public.platform_business_artifact_element_relations%rowtype;
  saved_relation public.platform_business_artifact_element_relations%rowtype;
  normalized_type text;
  action_code text;
begin
  perform public.skpe_assert_reason(change_reason);
  perform public.skpe_assert_business_artifact_version_editable(
    target_artifact_version_id
  );

  select *
  into version_row
  from public.platform_business_artifact_versions
  where id = target_artifact_version_id;

  if new_source_element_id = new_target_element_id then
    raise exception 'Uma relação não pode conectar o elemento a ele próprio.'
      using errcode = '22023';
  end if;

  normalized_type := lower(trim(coalesce(new_relation_type, '')));

  if normalized_type not in (
    'flow',
    'supports',
    'enables',
    'delivers',
    'contributes_to',
    'derives_from',
    'validates',
    'conflicts_with',
    'impacts'
  ) then
    raise exception 'Tipo inválido para a relação entre elementos.'
      using errcode = '22023';
  end if;

  if new_contribution_weight is not null
     and (
       new_contribution_weight < 0
       or new_contribution_weight > 100
     ) then
    raise exception 'O peso da contribuição deve estar entre 0 e 100.'
      using errcode = '22023';
  end if;

  if new_metadata is not null
     and jsonb_typeof(new_metadata) <> 'object' then
    raise exception 'Os metadados da relação devem ser um objeto JSON.'
      using errcode = '22023';
  end if;

  select *
  into source_element
  from public.platform_business_artifact_elements
  where id = new_source_element_id
    and artifact_version_id = target_artifact_version_id
    and status <> 'archived';

  if not found then
    raise exception 'Elemento de origem inválido ou arquivado.'
      using errcode = '22023';
  end if;

  select *
  into target_element
  from public.platform_business_artifact_elements
  where id = new_target_element_id
    and artifact_version_id = target_artifact_version_id
    and status <> 'archived';

  if not found then
    raise exception 'Elemento de destino inválido ou arquivado.'
      using errcode = '22023';
  end if;

  if target_relation_id is not null then
    select *
    into previous_relation
    from public.platform_business_artifact_element_relations
    where id = target_relation_id
      and artifact_version_id = target_artifact_version_id
    for update;

    if not found then
      raise exception 'Relação não encontrada nesta versão.'
        using errcode = '22023';
    end if;

    update public.platform_business_artifact_element_relations
    set
      source_element_id = new_source_element_id,
      target_element_id = new_target_element_id,
      relation_type = normalized_type,
      contribution_weight = new_contribution_weight,
      rationale = new_rationale,
      metadata = coalesce(new_metadata, metadata)
    where id = previous_relation.id
    returning *
    into saved_relation;

    action_code := 'business_element_relation_updated';
  else
    insert into public.platform_business_artifact_element_relations (
      organization_id,
      artifact_id,
      artifact_version_id,
      source_element_id,
      target_element_id,
      relation_type,
      contribution_weight,
      rationale,
      metadata,
      created_by
    )
    values (
      version_row.organization_id,
      version_row.artifact_id,
      version_row.id,
      new_source_element_id,
      new_target_element_id,
      normalized_type,
      new_contribution_weight,
      new_rationale,
      coalesce(new_metadata, '{}'::jsonb),
      auth.uid()
    )
    returning *
    into saved_relation;

    action_code := 'business_element_relation_created';
  end if;

  update public.platform_business_artifact_versions
  set
    status = case
      when status = 'draft' then 'in_elaboration'
      else status
    end,
    validation_notes = null,
    updated_by = auth.uid()
  where id = target_artifact_version_id;

  perform public.skpe_record_operational_audit(
    saved_relation.organization_id,
    version_row.source_skpe_project_id,
    'platform_business_artifact_element_relation',
    saved_relation.id,
    action_code,
    change_reason,
    case
      when previous_relation.id is null then null
      else to_jsonb(previous_relation)
    end,
    to_jsonb(saved_relation)
  );

  return saved_relation.id;
end;
$$;

create or replace function public.delete_skpe_business_element_relation(
  target_relation_id uuid,
  change_reason text default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_relation public.platform_business_artifact_element_relations%rowtype;
  version_row public.platform_business_artifact_versions%rowtype;
begin
  perform public.skpe_assert_reason(change_reason);

  select *
  into previous_relation
  from public.platform_business_artifact_element_relations
  where id = target_relation_id
  for update;

  if not found then
    return false;
  end if;

  perform public.skpe_assert_business_artifact_version_editable(
    previous_relation.artifact_version_id
  );

  select *
  into version_row
  from public.platform_business_artifact_versions
  where id = previous_relation.artifact_version_id;

  delete from public.platform_business_artifact_element_relations
  where id = previous_relation.id;

  update public.platform_business_artifact_versions
  set
    validation_notes = null,
    updated_by = auth.uid()
  where id = previous_relation.artifact_version_id;

  perform public.skpe_record_operational_audit(
    previous_relation.organization_id,
    version_row.source_skpe_project_id,
    'platform_business_artifact_element_relation',
    previous_relation.id,
    'business_element_relation_deleted',
    change_reason,
    to_jsonb(previous_relation),
    null
  );

  return true;
end;
$$;

-- ============================================================
-- 8. PRONTIDÃO DA VERSÃO DO ARTEFATO
-- ============================================================

create or replace function public.get_skpe_business_artifact_version_readiness(
  target_artifact_version_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  version_row public.platform_business_artifact_versions%rowtype;
  artifact_row public.platform_business_artifacts%rowtype;
  issues jsonb;
  blocking_count integer;
  active_elements integer;
  active_relations integer;
  required_blocks integer;
  fulfilled_blocks integer;
  completeness numeric;
begin
  select *
  into version_row
  from public.platform_business_artifact_versions
  where id = target_artifact_version_id;

  if not found then
    raise exception 'Versão do artefato de negócio não encontrada.'
      using errcode = '22023';
  end if;

  select *
  into artifact_row
  from public.platform_business_artifacts
  where id = version_row.artifact_id;

  if not public.can_view_business_architecture(version_row.organization_id) then
    raise exception 'Acesso negado ao artefato de negócio.'
      using errcode = '42501';
  end if;

  select count(*)
  into active_elements
  from public.platform_business_artifact_elements element
  where element.artifact_version_id = target_artifact_version_id
    and element.status <> 'archived';

  select count(*)
  into active_relations
  from public.platform_business_artifact_element_relations relation
  where relation.artifact_version_id = target_artifact_version_id;

  if artifact_row.artifact_type = 'business_foundation' then
    required_blocks := 9;

    select count(*)
    into fulfilled_blocks
    from (
      select required.block_code
      from (
        values
          ('customer_segments'),
          ('needs_jobs'),
          ('value_offering'),
          ('products_services'),
          ('channels_relationships'),
          ('capabilities_resources'),
          ('partners'),
          ('economic_logic'),
          ('risks_hypotheses')
      ) as required(block_code)
      where exists (
        select 1
        from public.platform_business_artifact_elements element
        where element.artifact_version_id = target_artifact_version_id
          and element.block_code = required.block_code
          and element.status <> 'archived'
      )
    ) fulfilled;

  elsif artifact_row.artifact_type = 'value_chain' then
    required_blocks := 3;

    select count(*)
    into fulfilled_blocks
    from (
      select required.block_code
      from (
        values
          ('governance_management'),
          ('core_business'),
          ('support')
      ) as required(block_code)
      where exists (
        select 1
        from public.platform_business_artifact_elements element
        where element.artifact_version_id = target_artifact_version_id
          and element.block_code = required.block_code
          and element.status <> 'archived'
      )
    ) fulfilled;
  else
    required_blocks := 1;
    fulfilled_blocks := case when active_elements > 0 then 1 else 0 end;
  end if;

  completeness := case
    when required_blocks = 0 then 0
    else round((fulfilled_blocks::numeric / required_blocks::numeric) * 100, 2)
  end;

  with issue_rows as (
    select
      'ELEMENTS_MISSING'::text as code,
      'blocking'::text as severity,
      'Registre os elementos essenciais do artefato.'::text as message,
      1::bigint as affected_count
    where active_elements = 0

    union all

    select
      'BUSINESS_FOUNDATION_BLOCK_MISSING_' || required.block_code,
      'blocking',
      'Bloco obrigatório não preenchido na Fundamentação do Negócio: ' ||
        required.block_code || '.',
      1
    from (
      values
        ('customer_segments'),
        ('needs_jobs'),
        ('value_offering'),
        ('products_services'),
        ('channels_relationships'),
        ('capabilities_resources'),
        ('partners'),
        ('economic_logic'),
        ('risks_hypotheses')
    ) as required(block_code)
    where artifact_row.artifact_type = 'business_foundation'
      and not exists (
        select 1
        from public.platform_business_artifact_elements element
        where element.artifact_version_id = target_artifact_version_id
          and element.block_code = required.block_code
          and element.status <> 'archived'
      )

    union all

    select
      'VALUE_CHAIN_BLOCK_MISSING_' || required.block_code,
      'blocking',
      'Bloco obrigatório não preenchido na Cadeia de Valor: ' ||
        required.block_code || '.',
      1
    from (
      values
        ('governance_management'),
        ('core_business'),
        ('support')
    ) as required(block_code)
    where artifact_row.artifact_type = 'value_chain'
      and not exists (
        select 1
        from public.platform_business_artifact_elements element
        where element.artifact_version_id = target_artifact_version_id
          and element.block_code = required.block_code
          and element.status <> 'archived'
      )

    union all

    select
      'VALUE_CHAIN_FLOW_MISSING',
      'blocking',
      'A Cadeia de Valor deve possuir ao menos uma relação de fluxo entre seus elementos.',
      1
    where artifact_row.artifact_type = 'value_chain'
      and not exists (
        select 1
        from public.platform_business_artifact_element_relations relation
        join public.platform_business_artifact_elements source_element
          on source_element.id = relation.source_element_id
        join public.platform_business_artifact_elements target_element
          on target_element.id = relation.target_element_id
        where relation.artifact_version_id = target_artifact_version_id
          and relation.relation_type = 'flow'
          and source_element.status <> 'archived'
          and target_element.status <> 'archived'
      )

    union all

    select
      'ELEMENT_WITHOUT_DESCRIPTION',
      'recommendation',
      'Descreva os elementos para tornar o artefato compreensível e reutilizável.',
      count(*)
    from public.platform_business_artifact_elements element
    where element.artifact_version_id = target_artifact_version_id
      and element.status <> 'archived'
      and length(trim(coalesce(element.description, ''))) = 0
    having count(*) > 0
  )
  select
    coalesce(
      jsonb_agg(
        jsonb_build_object(
          'code', issue.code,
          'severity', issue.severity,
          'message', issue.message,
          'affectedCount', issue.affected_count
        )
        order by
          case issue.severity
            when 'blocking' then 1
            else 2
          end,
          issue.code
      ),
      '[]'::jsonb
    ),
    count(*) filter (where issue.severity = 'blocking')::integer
  into issues, blocking_count
  from issue_rows issue;

  return jsonb_build_object(
    'artifactId', artifact_row.id,
    'artifactVersionId', version_row.id,
    'artifactType', artifact_row.artifact_type,
    'versionNumber', version_row.version_number,
    'versionStatus', version_row.status,
    'maturityLevel', version_row.maturity_level,
    'readyForValidation', blocking_count = 0,
    'blockingIssueCount', blocking_count,
    'activeElementCount', active_elements,
    'relationCount', active_relations,
    'requiredBlockCount', required_blocks,
    'fulfilledBlockCount', fulfilled_blocks,
    'calculatedCompletenessPercent', completeness,
    'issues', issues,
    'methodologyRules', case
      when artifact_row.artifact_type = 'business_foundation' then
        jsonb_build_object(
          'requiredBlocks', jsonb_build_array(
            'customer_segments',
            'needs_jobs',
            'value_offering',
            'products_services',
            'channels_relationships',
            'capabilities_resources',
            'partners',
            'economic_logic',
            'risks_hypotheses'
          ),
          'skpnLicenseRequired', false
        )
      when artifact_row.artifact_type = 'value_chain' then
        jsonb_build_object(
          'requiredBlocks', jsonb_build_array(
            'governance_management',
            'core_business',
            'support'
          ),
          'flowRelationRequired', true,
          'skpnLicenseRequired', false
        )
      else
        jsonb_build_object(
          'minimumActiveElements', 1,
          'skpnLicenseRequired', false
        )
    end
  );
end;
$$;

-- ============================================================
-- 9. TRANSIÇÕES DA VERSÃO DO ARTEFATO
-- ============================================================

create or replace function public.transition_skpe_business_artifact_version(
  target_artifact_version_id uuid,
  transition_action text,
  decision_notes text default null,
  change_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  normalized_action text;
  previous_version public.platform_business_artifact_versions%rowtype;
  updated_version public.platform_business_artifact_versions%rowtype;
  current_published public.platform_business_artifact_versions%rowtype;
  superseded_version public.platform_business_artifact_versions%rowtype;
  readiness jsonb;
  calculated_completeness numeric;
begin
  perform public.skpe_assert_reason(change_reason);

  normalized_action := lower(trim(coalesce(transition_action, '')));

  select *
  into previous_version
  from public.platform_business_artifact_versions
  where id = target_artifact_version_id
  for update;

  if not found then
    raise exception 'Versão do artefato de negócio não encontrada.'
      using errcode = '22023';
  end if;

  if normalized_action = 'begin_elaboration' then
    if not public.can_manage_business_architecture(previous_version.organization_id) then
      raise exception 'Acesso negado para iniciar a elaboração.'
        using errcode = '42501';
    end if;

    if previous_version.status <> 'draft' then
      raise exception 'Somente uma versão em rascunho pode iniciar a elaboração.'
        using errcode = '55000';
    end if;

    update public.platform_business_artifact_versions
    set
      status = 'in_elaboration',
      validation_notes = null,
      updated_by = auth.uid()
    where id = target_artifact_version_id
    returning *
    into updated_version;

  elsif normalized_action = 'submit_validation' then
    if not public.can_manage_business_architecture(previous_version.organization_id) then
      raise exception 'Acesso negado para submeter o artefato à validação.'
        using errcode = '42501';
    end if;

    if previous_version.status not in ('draft', 'in_elaboration') then
      raise exception 'O artefato deve estar em elaboração para ser submetido.'
        using errcode = '55000';
    end if;

    readiness := public.get_skpe_business_artifact_version_readiness(
      target_artifact_version_id
    );

    if not coalesce((readiness ->> 'readyForValidation')::boolean, false) then
      raise exception
        'O artefato possui pendências bloqueantes.'
        using errcode = '55000', detail = readiness::text;
    end if;

    calculated_completeness :=
      coalesce((readiness ->> 'calculatedCompletenessPercent')::numeric, 0);

    update public.platform_business_artifact_versions
    set
      status = 'pending_validation',
      completeness_percent = calculated_completeness,
      validation_notes = null,
      updated_by = auth.uid()
    where id = target_artifact_version_id
    returning *
    into updated_version;

  elsif normalized_action = 'validate' then
    if not public.can_validate_skpe_formulation(previous_version.organization_id) then
      raise exception 'Acesso negado para validar o artefato.'
        using errcode = '42501';
    end if;

    if previous_version.status <> 'pending_validation' then
      raise exception 'Somente uma versão pendente pode ser validada.'
        using errcode = '55000';
    end if;

    readiness := public.get_skpe_business_artifact_version_readiness(
      target_artifact_version_id
    );

    if not coalesce((readiness ->> 'readyForValidation')::boolean, false) then
      raise exception
        'O artefato possui pendências bloqueantes.'
        using errcode = '55000', detail = readiness::text;
    end if;

    update public.platform_business_artifact_versions
    set
      status = 'validated',
      maturity_level = case
        when maturity_level in ('essential', 'structured', 'complete')
          then 'validated'
        else maturity_level
      end,
      completeness_percent = 100,
      validation_notes = decision_notes,
      validated_at = timezone('utc', now()),
      validated_by = auth.uid(),
      updated_by = auth.uid()
    where id = target_artifact_version_id
    returning *
    into updated_version;

  elsif normalized_action = 'return_for_adjustments' then
    if not (
      public.can_validate_skpe_formulation(previous_version.organization_id)
      or public.can_approve_skpe_formulation(previous_version.organization_id)
    ) then
      raise exception 'Acesso negado para devolver o artefato para ajustes.'
        using errcode = '42501';
    end if;

    if previous_version.status not in (
      'pending_validation',
      'validated'
    ) then
      raise exception
        'O artefato não está em situação que permita devolução.'
        using errcode = '55000';
    end if;

    if length(trim(coalesce(decision_notes, ''))) < 10 then
      raise exception
        'Informe as orientações para os ajustes, com no mínimo 10 caracteres.'
        using errcode = '22023';
    end if;

    update public.platform_business_artifact_versions
    set
      status = 'in_elaboration',
      validation_notes = decision_notes,
      validated_at = null,
      validated_by = null,
      published_at = null,
      published_by = null,
      maturity_level = case
        when maturity_level in ('validated', 'published') then 'essential'
        else maturity_level
      end,
      updated_by = auth.uid()
    where id = target_artifact_version_id
    returning *
    into updated_version;

  elsif normalized_action = 'publish' then
    if not public.can_approve_skpe_formulation(previous_version.organization_id) then
      raise exception 'Acesso negado para publicar o artefato.'
        using errcode = '42501';
    end if;

    if previous_version.status <> 'validated' then
      raise exception 'Somente uma versão validada pode ser publicada.'
        using errcode = '55000';
    end if;

    readiness := public.get_skpe_business_artifact_version_readiness(
      target_artifact_version_id
    );

    if not coalesce((readiness ->> 'readyForValidation')::boolean, false) then
      raise exception
        'O artefato possui pendências bloqueantes.'
        using errcode = '55000', detail = readiness::text;
    end if;

    select *
    into current_published
    from public.platform_business_artifact_versions
    where artifact_id = previous_version.artifact_id
      and status = 'published'
      and id <> target_artifact_version_id
    for update;

    if found then
      update public.platform_business_artifact_versions
      set
        status = 'superseded',
        superseded_at = timezone('utc', now()),
        superseded_by = auth.uid(),
        updated_by = auth.uid()
      where id = current_published.id
      returning *
      into superseded_version;

      perform public.skpe_record_operational_audit(
        superseded_version.organization_id,
        superseded_version.source_skpe_project_id,
        'platform_business_artifact_version',
        superseded_version.id,
        'business_artifact_version_superseded',
        change_reason,
        to_jsonb(current_published),
        to_jsonb(superseded_version)
      );
    end if;

    update public.platform_business_artifact_versions
    set
      status = 'published',
      maturity_level = 'published',
      completeness_percent = 100,
      published_at = timezone('utc', now()),
      published_by = auth.uid(),
      updated_by = auth.uid()
    where id = target_artifact_version_id
    returning *
    into updated_version;

  elsif normalized_action = 'archive' then
    if not public.can_manage_business_architecture(previous_version.organization_id) then
      raise exception 'Acesso negado para arquivar o artefato.'
        using errcode = '42501';
    end if;

    if previous_version.status not in ('draft', 'in_elaboration') then
      raise exception
        'Somente versões em rascunho ou elaboração podem ser arquivadas diretamente.'
        using errcode = '55000';
    end if;

    update public.platform_business_artifact_versions
    set
      status = 'archived',
      updated_by = auth.uid()
    where id = target_artifact_version_id
    returning *
    into updated_version;

  else
    raise exception
      'Transição inválida. Use begin_elaboration, submit_validation, validate, return_for_adjustments, publish ou archive.'
      using errcode = '22023';
  end if;

  perform public.skpe_record_operational_audit(
    updated_version.organization_id,
    updated_version.source_skpe_project_id,
    'platform_business_artifact_version',
    updated_version.id,
    'business_artifact_version_' || normalized_action,
    change_reason,
    to_jsonb(previous_version),
    to_jsonb(updated_version)
  );

  return jsonb_build_object(
    'artifactVersionId', updated_version.id,
    'artifactId', updated_version.artifact_id,
    'previousStatus', previous_version.status,
    'currentStatus', updated_version.status,
    'transitionAction', normalized_action,
    'maturityLevel', updated_version.maturity_level,
    'completenessPercent', updated_version.completeness_percent
  );
end;
$$;

-- ============================================================
-- 10. REVISÃO DO ARTEFATO COM CLONAGEM
-- ============================================================

create or replace function public.create_skpe_business_artifact_revision(
  source_artifact_version_id uuid,
  new_version_label text,
  new_version_summary text default null,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  source_version public.platform_business_artifact_versions%rowtype;
  new_version public.platform_business_artifact_versions%rowtype;
  next_version_number integer;
begin
  perform public.skpe_assert_reason(change_reason);

  if length(trim(coalesce(new_version_label, ''))) = 0 then
    raise exception 'Informe o rótulo da revisão.'
      using errcode = '22023';
  end if;

  select *
  into source_version
  from public.platform_business_artifact_versions
  where id = source_artifact_version_id
  for update;

  if not found then
    raise exception 'Versão de origem não encontrada.'
      using errcode = '22023';
  end if;

  if source_version.status not in ('published', 'superseded') then
    raise exception
      'A revisão deve ser derivada de uma versão publicada ou substituída. Versões apenas validadas devem ser devolvidas para ajustes.'
      using errcode = '55000';
  end if;

  if not public.can_manage_business_architecture(source_version.organization_id) then
    raise exception 'Acesso negado para criar a revisão.'
      using errcode = '42501';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(source_version.artifact_id::text, 0)
  );

  if exists (
    select 1
    from public.platform_business_artifact_versions version
    where version.artifact_id = source_version.artifact_id
      and version.status in (
        'draft',
        'in_elaboration',
        'pending_validation',
        'validated'
      )
      and version.id <> source_version.id
  ) then
    raise exception
      'Já existe uma versão aberta deste artefato.'
      using errcode = '23505';
  end if;

  if exists (
    select 1
    from public.platform_business_artifact_versions current_version
    where current_version.artifact_id = source_version.artifact_id
      and current_version.status = 'published'
      and current_version.id <> source_version.id
  ) then
    raise exception
      'Existe uma versão publicada vigente. A revisão deve ser derivada dessa versão.'
      using errcode = '55000';
  end if;

  select coalesce(max(version.version_number), 0) + 1
  into next_version_number
  from public.platform_business_artifact_versions version
  where version.artifact_id = source_version.artifact_id;

  insert into public.platform_business_artifact_versions (
    organization_id,
    artifact_id,
    version_number,
    version_label,
    methodology_version,
    origin_module,
    origin_service_type,
    source_entity_type,
    source_entity_id,
    source_skpe_project_id,
    maturity_level,
    completeness_percent,
    status,
    summary,
    content_payload,
    derived_from_version_id,
    metadata,
    created_by,
    updated_by
  )
  values (
    source_version.organization_id,
    source_version.artifact_id,
    next_version_number,
    trim(new_version_label),
    source_version.methodology_version,
    'SK-PE',
    'strategic_planning',
    source_version.source_entity_type,
    source_version.source_entity_id,
    source_version.source_skpe_project_id,
    'essential',
    0,
    'draft',
    new_version_summary,
    source_version.content_payload,
    source_version.id,
    coalesce(source_version.metadata, '{}'::jsonb)
      || jsonb_build_object(
        'derivedFromVersionId', source_version.id,
        'derivedFromVersionNumber', source_version.version_number
      ),
    auth.uid(),
    auth.uid()
  )
  returning *
  into new_version;

  insert into public.platform_business_artifact_elements (
    organization_id,
    artifact_id,
    artifact_version_id,
    parent_element_id,
    block_code,
    element_code,
    element_type,
    title,
    description,
    structured_payload,
    display_order,
    status,
    metadata,
    created_by,
    updated_by
  )
  select
    new_version.organization_id,
    new_version.artifact_id,
    new_version.id,
    null,
    element.block_code,
    element.element_code,
    element.element_type,
    element.title,
    element.description,
    element.structured_payload,
    element.display_order,
    case
      when element.status = 'archived' then 'archived'
      else 'active'
    end,
    coalesce(element.metadata, '{}'::jsonb)
      || jsonb_build_object('clonedFromId', element.id),
    auth.uid(),
    auth.uid()
  from public.platform_business_artifact_elements element
  where element.artifact_version_id = source_version.id;

  update public.platform_business_artifact_elements child
  set parent_element_id = new_parent.id
  from public.platform_business_artifact_elements old_child
  join public.platform_business_artifact_elements old_parent
    on old_parent.id = old_child.parent_element_id
  join public.platform_business_artifact_elements new_parent
    on new_parent.artifact_version_id = new_version.id
   and new_parent.element_code = old_parent.element_code
  where child.artifact_version_id = new_version.id
    and old_child.artifact_version_id = source_version.id
    and child.element_code = old_child.element_code;

  insert into public.platform_business_artifact_element_relations (
    organization_id,
    artifact_id,
    artifact_version_id,
    source_element_id,
    target_element_id,
    relation_type,
    contribution_weight,
    rationale,
    metadata,
    created_by
  )
  select
    new_version.organization_id,
    new_version.artifact_id,
    new_version.id,
    new_source.id,
    new_target.id,
    relation.relation_type,
    relation.contribution_weight,
    relation.rationale,
    coalesce(relation.metadata, '{}'::jsonb)
      || jsonb_build_object('clonedFromId', relation.id),
    auth.uid()
  from public.platform_business_artifact_element_relations relation
  join public.platform_business_artifact_elements old_source
    on old_source.id = relation.source_element_id
  join public.platform_business_artifact_elements new_source
    on new_source.artifact_version_id = new_version.id
   and new_source.element_code = old_source.element_code
  join public.platform_business_artifact_elements old_target
    on old_target.id = relation.target_element_id
  join public.platform_business_artifact_elements new_target
    on new_target.artifact_version_id = new_version.id
   and new_target.element_code = old_target.element_code
  where relation.artifact_version_id = source_version.id;

  perform public.skpe_record_operational_audit(
    new_version.organization_id,
    new_version.source_skpe_project_id,
    'platform_business_artifact_version',
    new_version.id,
    'business_artifact_revision_created',
    change_reason,
    to_jsonb(source_version),
    to_jsonb(new_version)
  );

  return new_version.id;
end;
$$;

-- ============================================================
-- 11. SNAPSHOT CANÔNICO DA VERSÃO
-- ============================================================

create or replace function public.capture_skpe_business_artifact_snapshot(
  target_artifact_version_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  version_row public.platform_business_artifact_versions%rowtype;
  artifact_row public.platform_business_artifacts%rowtype;
begin
  select *
  into version_row
  from public.platform_business_artifact_versions
  where id = target_artifact_version_id;

  if not found then
    raise exception 'Versão do artefato de negócio não encontrada.'
      using errcode = '22023';
  end if;

  select *
  into artifact_row
  from public.platform_business_artifacts
  where id = version_row.artifact_id;

  if not public.can_view_business_architecture(version_row.organization_id) then
    raise exception 'Acesso negado ao artefato de negócio.'
      using errcode = '42501';
  end if;

  return jsonb_build_object(
    'snapshotSchemaVersion', '1.0',
    'capturedAt', timezone('utc', now()),
    'artifact', jsonb_build_object(
      'id', artifact_row.id,
      'organizationId', artifact_row.organization_id,
      'code', artifact_row.code,
      'name', artifact_row.name,
      'description', artifact_row.description,
      'artifactType', artifact_row.artifact_type,
      'methodologyCode', artifact_row.methodology_code,
      'status', artifact_row.status
    ),
    'version', jsonb_build_object(
      'id', version_row.id,
      'versionNumber', version_row.version_number,
      'versionLabel', version_row.version_label,
      'originModule', version_row.origin_module,
      'originServiceType', version_row.origin_service_type,
      'maturityLevel', version_row.maturity_level,
      'completenessPercent', version_row.completeness_percent,
      'status', version_row.status,
      'summary', version_row.summary,
      'contentPayload', version_row.content_payload,
      'validatedAt', version_row.validated_at,
      'publishedAt', version_row.published_at
    ),
    'elements', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', element.id,
          'parentElementId', element.parent_element_id,
          'blockCode', element.block_code,
          'elementCode', element.element_code,
          'elementType', element.element_type,
          'title', element.title,
          'description', element.description,
          'structuredPayload', element.structured_payload,
          'displayOrder', element.display_order,
          'status', element.status,
          'metadata', element.metadata
        )
        order by element.display_order, element.element_code
      )
      from public.platform_business_artifact_elements element
      where element.artifact_version_id = target_artifact_version_id
    ), '[]'::jsonb),
    'relations', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', relation.id,
          'sourceElementId', relation.source_element_id,
          'targetElementId', relation.target_element_id,
          'relationType', relation.relation_type,
          'contributionWeight', relation.contribution_weight,
          'rationale', relation.rationale,
          'metadata', relation.metadata
        )
        order by relation.created_at, relation.id
      )
      from public.platform_business_artifact_element_relations relation
      where relation.artifact_version_id = target_artifact_version_id
    ), '[]'::jsonb)
  );
end;
$$;

-- ============================================================
-- 12. VÍNCULO E SNAPSHOT NA FORMULAÇÃO
-- ============================================================

create or replace function public.link_skpe_business_input(
  target_formulation_id uuid,
  target_artifact_version_id uuid,
  new_input_role text,
  new_usage_mode text default 'created_in_skpe',
  new_requirement_level text default 'required',
  new_is_primary boolean default true,
  new_gap_summary text default null,
  new_handoff_to_skpn_recommended boolean default false,
  new_handoff_notes text default null,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  version_row public.platform_business_artifact_versions%rowtype;
  artifact_row public.platform_business_artifacts%rowtype;
  existing_input public.skpe_formulation_business_inputs%rowtype;
  saved_input public.skpe_formulation_business_inputs%rowtype;
  snapshot jsonb;
  readiness jsonb;
  normalized_role text;
  normalized_usage text;
  normalized_requirement text;
  action_code text;
begin
  perform public.skpe_assert_reason(change_reason);
  perform public.skpe_assert_formulation_editable(target_formulation_id);

  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = target_formulation_id;

  select *
  into version_row
  from public.platform_business_artifact_versions
  where id = target_artifact_version_id;

  if not found then
    raise exception 'Versão do artefato de negócio não encontrada.'
      using errcode = '22023';
  end if;

  select *
  into artifact_row
  from public.platform_business_artifacts
  where id = version_row.artifact_id;

  if version_row.organization_id <> formulation_row.organization_id then
    raise exception
      'O artefato e a Formulação devem pertencer à mesma organização.'
      using errcode = '22023';
  end if;

  if version_row.status not in ('validated', 'published') then
    raise exception
      'Somente versões validadas ou publicadas podem ser vinculadas à Formulação.'
      using errcode = '55000';
  end if;

  normalized_role := lower(trim(coalesce(new_input_role, '')));
  normalized_usage := lower(trim(coalesce(new_usage_mode, 'created_in_skpe')));
  normalized_requirement :=
    lower(trim(coalesce(new_requirement_level, 'required')));

  if normalized_role not in (
    'business_foundation',
    'value_proposition',
    'business_model',
    'value_chain',
    'stakeholders',
    'market',
    'products_services',
    'capabilities',
    'processes',
    'financial_viability',
    'risks_hypotheses',
    'other'
  ) then
    raise exception 'Papel inválido para o insumo de negócio.'
      using errcode = '22023';
  end if;

  if normalized_usage not in (
    'created_in_skpe',
    'reused_from_skpn',
    'reused_from_platform',
    'imported',
    'provisional'
  ) then
    raise exception 'Modo de uso inválido.'
      using errcode = '22023';
  end if;

  if normalized_requirement not in (
    'required',
    'recommended',
    'optional'
  ) then
    raise exception 'Nível de requisito inválido.'
      using errcode = '22023';
  end if;

  if normalized_role = 'business_foundation'
     and artifact_row.artifact_type <> 'business_foundation' then
    raise exception
      'O papel business_foundation exige artefato do tipo business_foundation.'
      using errcode = '22023';
  end if;

  if normalized_role = 'value_chain'
     and artifact_row.artifact_type <> 'value_chain' then
    raise exception
      'O papel value_chain exige artefato do tipo value_chain.'
      using errcode = '22023';
  end if;

  if normalized_role = 'value_proposition'
     and artifact_row.artifact_type <> 'value_proposition_canvas' then
    raise exception
      'O papel value_proposition exige um Value Proposition Canvas.'
      using errcode = '22023';
  end if;

  if normalized_role = 'business_model'
     and artifact_row.artifact_type <> 'business_model_canvas' then
    raise exception
      'O papel business_model exige um Business Model Canvas.'
      using errcode = '22023';
  end if;

  readiness := public.get_skpe_business_artifact_version_readiness(
    target_artifact_version_id
  );

  if not coalesce((readiness ->> 'readyForValidation')::boolean, false) then
    raise exception
      'A versão do artefato possui pendências bloqueantes.'
      using errcode = '55000', detail = readiness::text;
  end if;

  snapshot := public.capture_skpe_business_artifact_snapshot(
    target_artifact_version_id
  );

  if new_is_primary then
    update public.skpe_formulation_business_inputs
    set
      is_primary = false,
      status = 'superseded',
      updated_by = auth.uid()
    where formulation_id = target_formulation_id
      and input_role = normalized_role
      and is_primary
      and status = 'active'
      and artifact_version_id <> target_artifact_version_id;
  end if;

  select *
  into existing_input
  from public.skpe_formulation_business_inputs
  where formulation_id = target_formulation_id
    and artifact_version_id = target_artifact_version_id
    and input_role = normalized_role
  for update;

  if found then
    update public.skpe_formulation_business_inputs
    set
      usage_mode = normalized_usage,
      requirement_level = normalized_requirement,
      is_primary = new_is_primary,
      status = 'active',
      source_version_number = version_row.version_number,
      snapshot_payload = snapshot,
      snapshot_schema_version = '1.0',
      snapshot_captured_at = timezone('utc', now()),
      gap_summary = new_gap_summary,
      handoff_to_skpn_recommended = new_handoff_to_skpn_recommended,
      handoff_notes = new_handoff_notes,
      updated_by = auth.uid()
    where id = existing_input.id
    returning *
    into saved_input;

    action_code := 'business_input_relinked';
  else
    insert into public.skpe_formulation_business_inputs (
      organization_id,
      project_id,
      formulation_id,
      artifact_id,
      artifact_version_id,
      input_role,
      usage_mode,
      requirement_level,
      is_primary,
      status,
      source_version_number,
      snapshot_payload,
      snapshot_schema_version,
      snapshot_captured_at,
      gap_summary,
      handoff_to_skpn_recommended,
      handoff_notes,
      metadata,
      created_by,
      updated_by
    )
    values (
      formulation_row.organization_id,
      formulation_row.project_id,
      formulation_row.id,
      artifact_row.id,
      version_row.id,
      normalized_role,
      normalized_usage,
      normalized_requirement,
      new_is_primary,
      'active',
      version_row.version_number,
      snapshot,
      '1.0',
      timezone('utc', now()),
      new_gap_summary,
      new_handoff_to_skpn_recommended,
      new_handoff_notes,
      jsonb_build_object(
        'artifactType', artifact_row.artifact_type,
        'originModule', version_row.origin_module
      ),
      auth.uid(),
      auth.uid()
    )
    returning *
    into saved_input;

    action_code := 'business_input_linked';
  end if;

  perform public.skpe_record_operational_audit(
    saved_input.organization_id,
    saved_input.project_id,
    'skpe_formulation_business_input',
    saved_input.id,
    action_code,
    change_reason,
    case
      when existing_input.id is null then null
      else to_jsonb(existing_input)
    end,
    to_jsonb(saved_input)
  );

  return saved_input.id;
end;
$$;

create or replace function public.dismiss_skpe_business_input(
  target_business_input_id uuid,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_input public.skpe_formulation_business_inputs%rowtype;
  dismissed_input public.skpe_formulation_business_inputs%rowtype;
begin
  perform public.skpe_assert_reason(change_reason);

  select *
  into previous_input
  from public.skpe_formulation_business_inputs
  where id = target_business_input_id
  for update;

  if not found then
    raise exception 'Vínculo do insumo de negócio não encontrado.'
      using errcode = '22023';
  end if;

  perform public.skpe_assert_formulation_editable(
    previous_input.formulation_id
  );

  update public.skpe_formulation_business_inputs
  set
    status = 'dismissed',
    is_primary = false,
    updated_by = auth.uid()
  where id = previous_input.id
  returning *
  into dismissed_input;

  perform public.skpe_record_operational_audit(
    dismissed_input.organization_id,
    dismissed_input.project_id,
    'skpe_formulation_business_input',
    dismissed_input.id,
    'business_input_dismissed',
    change_reason,
    to_jsonb(previous_input),
    to_jsonb(dismissed_input)
  );

  return dismissed_input.id;
end;
$$;

-- ============================================================
-- 13. PRONTIDÃO DA FUNDAMENTAÇÃO DO NEGÓCIO NA FORMULAÇÃO
-- ============================================================

create or replace function public.get_skpe_business_foundation_readiness(
  target_formulation_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  foundation_input public.skpe_formulation_business_inputs%rowtype;
  value_chain_input public.skpe_formulation_business_inputs%rowtype;
  foundation_version public.platform_business_artifact_versions%rowtype;
  value_chain_version public.platform_business_artifact_versions%rowtype;
  foundation_readiness jsonb;
  value_chain_readiness jsonb;
  issues jsonb := '[]'::jsonb;
  blocking_count integer := 0;
begin
  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = target_formulation_id;

  if not found then
    raise exception 'Versão da Formulação Estratégica não encontrada.'
      using errcode = '22023';
  end if;

  if not public.can_view_skpe_formulation(formulation_row.organization_id) then
    raise exception 'Acesso negado à Fundamentação do Negócio.'
      using errcode = '42501';
  end if;

  select *
  into foundation_input
  from public.skpe_formulation_business_inputs input
  where input.formulation_id = target_formulation_id
    and input.input_role = 'business_foundation'
    and input.status = 'active'
    and input.is_primary
  order by input.updated_at desc
  limit 1;

  select *
  into value_chain_input
  from public.skpe_formulation_business_inputs input
  where input.formulation_id = target_formulation_id
    and input.input_role = 'value_chain'
    and input.status = 'active'
    and input.is_primary
  order by input.updated_at desc
  limit 1;

  if foundation_input.id is null then
    blocking_count := blocking_count + 1;
    issues := issues || jsonb_build_array(
      jsonb_build_object(
        'code', 'BUSINESS_FOUNDATION_MISSING',
        'severity', 'blocking',
        'message', 'Crie ou vincule a Fundamentação do Negócio em nível essencial.',
        'affectedCount', 1
      )
    );
  else
    select *
    into foundation_version
    from public.platform_business_artifact_versions
    where id = foundation_input.artifact_version_id;

    foundation_readiness :=
      public.get_skpe_business_artifact_version_readiness(
        foundation_input.artifact_version_id
      );

    if foundation_version.status not in ('validated', 'published') then
      blocking_count := blocking_count + 1;
      issues := issues || jsonb_build_array(
        jsonb_build_object(
          'code', 'BUSINESS_FOUNDATION_NOT_VALIDATED',
          'severity', 'blocking',
          'message', 'A Fundamentação do Negócio deve estar validada ou publicada.',
          'affectedCount', 1
        )
      );
    end if;

    if not coalesce(
      (foundation_readiness ->> 'readyForValidation')::boolean,
      false
    ) then
      blocking_count := blocking_count + 1;
      issues := issues || jsonb_build_array(
        jsonb_build_object(
          'code', 'BUSINESS_FOUNDATION_INCOMPLETE',
          'severity', 'blocking',
          'message', 'A Fundamentação do Negócio possui blocos essenciais incompletos.',
          'affectedCount',
          coalesce(
            (foundation_readiness ->> 'blockingIssueCount')::integer,
            1
          )
        )
      );
    end if;
  end if;

  if value_chain_input.id is null then
    blocking_count := blocking_count + 1;
    issues := issues || jsonb_build_array(
      jsonb_build_object(
        'code', 'VALUE_CHAIN_MISSING',
        'severity', 'blocking',
        'message', 'Crie ou vincule a Cadeia de Valor essencial.',
        'affectedCount', 1
      )
    );
  else
    select *
    into value_chain_version
    from public.platform_business_artifact_versions
    where id = value_chain_input.artifact_version_id;

    value_chain_readiness :=
      public.get_skpe_business_artifact_version_readiness(
        value_chain_input.artifact_version_id
      );

    if value_chain_version.status not in ('validated', 'published') then
      blocking_count := blocking_count + 1;
      issues := issues || jsonb_build_array(
        jsonb_build_object(
          'code', 'VALUE_CHAIN_NOT_VALIDATED',
          'severity', 'blocking',
          'message', 'A Cadeia de Valor deve estar validada ou publicada.',
          'affectedCount', 1
        )
      );
    end if;

    if not coalesce(
      (value_chain_readiness ->> 'readyForValidation')::boolean,
      false
    ) then
      blocking_count := blocking_count + 1;
      issues := issues || jsonb_build_array(
        jsonb_build_object(
          'code', 'VALUE_CHAIN_INCOMPLETE',
          'severity', 'blocking',
          'message', 'A Cadeia de Valor possui elementos ou fluxos incompletos.',
          'affectedCount',
          coalesce(
            (value_chain_readiness ->> 'blockingIssueCount')::integer,
            1
          )
        )
      );
    end if;
  end if;

  return jsonb_build_object(
    'formulationId', formulation_row.id,
    'readyForValidation', blocking_count = 0,
    'blockingIssueCount', blocking_count,
    'businessFoundationInputId', foundation_input.id,
    'businessFoundationVersionId', foundation_input.artifact_version_id,
    'businessFoundationReadiness', foundation_readiness,
    'valueChainInputId', value_chain_input.id,
    'valueChainVersionId', value_chain_input.artifact_version_id,
    'valueChainReadiness', value_chain_readiness,
    'issues', issues,
    'architectureRules', jsonb_build_object(
      'sharedPlatformDomain', true,
      'skpeAutonomous', true,
      'skpnLicenseRequired', false,
      'snapshotPreserved', true,
      'futureSkpnDeepeningSupported', true
    )
  );
end;
$$;

-- ============================================================
-- 14. BLOQUEIO DA FORMULAÇÃO SEM INSUMOS VALIDADOS
-- ============================================================

create or replace function public.skpe_guard_formulation_business_ready()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  readiness jsonb;
begin
  if new.status is not distinct from old.status then
    return new;
  end if;

  if new.status not in (
    'pending_validation',
    'validated',
    'pending_approval',
    'approved'
  ) then
    return new;
  end if;

  readiness := public.get_skpe_business_foundation_readiness(new.id);

  if not coalesce((readiness ->> 'readyForValidation')::boolean, false) then
    raise exception
      'A Formulação não pode avançar: complete e valide a Fundamentação do Negócio e a Cadeia de Valor.'
      using errcode = '55000', detail = readiness::text;
  end if;

  return new;
end;
$$;

drop trigger if exists skpe_strategic_formulations_guard_business_ready
  on public.skpe_strategic_formulations;

create trigger skpe_strategic_formulations_guard_business_ready
before update of status on public.skpe_strategic_formulations
for each row
execute function public.skpe_guard_formulation_business_ready();

comment on function public.skpe_guard_formulation_business_ready() is
  'Impede o avanço da Formulação sem Fundamentação do Negócio e Cadeia de Valor essenciais, validadas e vinculadas.';

-- ============================================================
-- 15. CONSULTA CONSOLIDADA
-- ============================================================

create or replace function public.get_skpe_formulation_business_architecture(
  target_formulation_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  readiness jsonb;
begin
  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = target_formulation_id;

  if not found then
    raise exception 'Versão da Formulação Estratégica não encontrada.'
      using errcode = '22023';
  end if;

  if not public.can_view_skpe_formulation(formulation_row.organization_id) then
    raise exception 'Acesso negado à Arquitetura de Negócios.'
      using errcode = '42501';
  end if;

  readiness := public.get_skpe_business_foundation_readiness(
    target_formulation_id
  );

  return jsonb_build_object(
    'formulation', jsonb_build_object(
      'id', formulation_row.id,
      'organizationId', formulation_row.organization_id,
      'projectId', formulation_row.project_id,
      'versionNumber', formulation_row.version_number,
      'versionLabel', formulation_row.version_label,
      'status', formulation_row.status
    ),
    'inputs', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'inputId', input.id,
          'inputRole', input.input_role,
          'usageMode', input.usage_mode,
          'requirementLevel', input.requirement_level,
          'isPrimary', input.is_primary,
          'inputStatus', input.status,
          'artifactId', artifact.id,
          'artifactCode', artifact.code,
          'artifactName', artifact.name,
          'artifactType', artifact.artifact_type,
          'artifactVersionId', version.id,
          'versionNumber', version.version_number,
          'versionLabel', version.version_label,
          'versionStatus', version.status,
          'maturityLevel', version.maturity_level,
          'completenessPercent', version.completeness_percent,
          'originModule', version.origin_module,
          'sourceVersionNumber', input.source_version_number,
          'snapshotSchemaVersion', input.snapshot_schema_version,
          'snapshotCapturedAt', input.snapshot_captured_at,
          'gapSummary', input.gap_summary,
          'handoffToSkpnRecommended',
            input.handoff_to_skpn_recommended,
          'handoffNotes', input.handoff_notes
        )
        order by
          case input.input_role
            when 'business_foundation' then 1
            when 'value_chain' then 2
            when 'value_proposition' then 3
            when 'business_model' then 4
            else 5
          end,
          input.is_primary desc,
          version.version_number desc
      )
      from public.skpe_formulation_business_inputs input
      join public.platform_business_artifacts artifact
        on artifact.id = input.artifact_id
      join public.platform_business_artifact_versions version
        on version.id = input.artifact_version_id
      where input.formulation_id = target_formulation_id
        and input.status = 'active'
    ), '[]'::jsonb),
    'readiness', readiness
  );
end;
$$;

create or replace function public.get_skpe_business_architecture_audit(
  target_formulation_id uuid
)
returns table (
  audit_id uuid,
  entity_type text,
  entity_id uuid,
  action_code text,
  reason text,
  previous_data jsonb,
  new_data jsonb,
  occurred_at timestamptz,
  actor_user_id uuid
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
begin
  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = target_formulation_id;

  if not found then
    raise exception 'Versão da Formulação Estratégica não encontrada.'
      using errcode = '22023';
  end if;

  if not public.can_view_skpe_formulation(formulation_row.organization_id) then
    raise exception 'Acesso negado ao histórico da Arquitetura de Negócios.'
      using errcode = '42501';
  end if;

  return query
  select
    audit.id,
    audit.entity_type,
    audit.entity_id,
    audit.action_code,
    audit.reason,
    audit.previous_data,
    audit.new_data,
    audit.occurred_at,
    audit.actor_user_id
  from public.skpe_operational_audit audit
  where audit.organization_id = formulation_row.organization_id
    and (
      audit.project_id = formulation_row.project_id
      or audit.project_id is null
    )
    and audit.entity_type in (
      'platform_business_artifact',
      'platform_business_artifact_version',
      'platform_business_artifact_element',
      'platform_business_artifact_element_relation',
      'skpe_formulation_business_input'
    )
    and (
      audit.previous_data ->> 'source_entity_id' =
        target_formulation_id::text
      or audit.new_data ->> 'source_entity_id' =
        target_formulation_id::text
      or audit.previous_data ->> 'formulation_id' =
        target_formulation_id::text
      or audit.new_data ->> 'formulation_id' =
        target_formulation_id::text
      or audit.entity_id in (
        select input.id
        from public.skpe_formulation_business_inputs input
        where input.formulation_id = target_formulation_id
      )
    )
  order by audit.occurred_at desc, audit.id desc;
end;
$$;

-- ============================================================
-- 16. PRIVILÉGIOS
-- ============================================================

revoke all on function
  public.skpe_assert_business_artifact_version_editable(uuid)
from public, anon, authenticated;

revoke all on function
  public.skpe_guard_business_artifact_version_content()
from public, anon, authenticated;

revoke all on function
  public.capture_skpe_business_artifact_snapshot(uuid)
from public, anon, authenticated;

revoke all on function
  public.skpe_guard_formulation_business_ready()
from public, anon, authenticated;

revoke all on function public.create_skpe_business_artifact(
  uuid, text, text, text, text, text, text, text, text, text
) from public, anon;

revoke all on function public.update_skpe_business_artifact_version(
  uuid, text, text, text, jsonb, jsonb, text
) from public, anon;

revoke all on function public.upsert_skpe_business_artifact_element(
  uuid, text, text, text, text, text, jsonb, uuid, integer, uuid, text
) from public, anon;

revoke all on function public.archive_skpe_business_artifact_element(
  uuid, text
) from public, anon;

revoke all on function public.upsert_skpe_business_element_relation(
  uuid, uuid, uuid, text, numeric, text, jsonb, uuid, text
) from public, anon;

revoke all on function public.delete_skpe_business_element_relation(
  uuid, text
) from public, anon;

revoke all on function public.get_skpe_business_artifact_version_readiness(
  uuid
) from public, anon;

revoke all on function public.transition_skpe_business_artifact_version(
  uuid, text, text, text
) from public, anon;

revoke all on function public.create_skpe_business_artifact_revision(
  uuid, text, text, text
) from public, anon;

revoke all on function public.link_skpe_business_input(
  uuid, uuid, text, text, text, boolean, text, boolean, text, text
) from public, anon;

revoke all on function public.dismiss_skpe_business_input(
  uuid, text
) from public, anon;

revoke all on function public.get_skpe_business_foundation_readiness(
  uuid
) from public, anon;

revoke all on function public.get_skpe_formulation_business_architecture(
  uuid
) from public, anon;

revoke all on function public.get_skpe_business_architecture_audit(
  uuid
) from public, anon;

grant execute on function public.create_skpe_business_artifact(
  uuid, text, text, text, text, text, text, text, text, text
) to authenticated, service_role;

grant execute on function public.update_skpe_business_artifact_version(
  uuid, text, text, text, jsonb, jsonb, text
) to authenticated, service_role;

grant execute on function public.upsert_skpe_business_artifact_element(
  uuid, text, text, text, text, text, jsonb, uuid, integer, uuid, text
) to authenticated, service_role;

grant execute on function public.archive_skpe_business_artifact_element(
  uuid, text
) to authenticated, service_role;

grant execute on function public.upsert_skpe_business_element_relation(
  uuid, uuid, uuid, text, numeric, text, jsonb, uuid, text
) to authenticated, service_role;

grant execute on function public.delete_skpe_business_element_relation(
  uuid, text
) to authenticated, service_role;

grant execute on function public.get_skpe_business_artifact_version_readiness(
  uuid
) to authenticated, service_role;

grant execute on function public.transition_skpe_business_artifact_version(
  uuid, text, text, text
) to authenticated, service_role;

grant execute on function public.create_skpe_business_artifact_revision(
  uuid, text, text, text
) to authenticated, service_role;

grant execute on function public.link_skpe_business_input(
  uuid, uuid, text, text, text, boolean, text, boolean, text, text
) to authenticated, service_role;

grant execute on function public.dismiss_skpe_business_input(
  uuid, text
) to authenticated, service_role;

grant execute on function public.get_skpe_business_foundation_readiness(
  uuid
) to authenticated, service_role;

grant execute on function public.get_skpe_formulation_business_architecture(
  uuid
) to authenticated, service_role;

grant execute on function public.get_skpe_business_architecture_audit(
  uuid
) to authenticated, service_role;

grant execute on function
  public.skpe_assert_business_artifact_version_editable(uuid)
to service_role;

grant execute on function
  public.capture_skpe_business_artifact_snapshot(uuid)
to service_role;

commit;
