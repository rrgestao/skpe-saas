-- ============================================================
-- Plataforma SPARKs
-- Vinculo sistemico SESCOOP/DF -> COOTAQUARA
-- Acesso hierarquico somente leitura para administradores da origem
-- V2 - correcao de ambiguidade de variaveis PL/pgSQL
-- Data: 2026-07-29
--
-- IMPORTANTE:
-- Este vinculo representa supervisao/acompanhamento sistemico para
-- navegacao e acesso na Plataforma SPARKs. Nao representa subordinacao
-- societaria, legal, estatutaria ou administrativa da cooperativa.
-- ============================================================

begin;

-- ------------------------------------------------------------
-- 1. Validacoes de existencia e unicidade
-- ------------------------------------------------------------
do $$
declare
  v_source_count integer;
  v_target_count integer;
begin
  select count(*)
    into v_source_count
  from public.organizations
  where code = 'SESCOOP-DF';

  select count(*)
    into v_target_count
  from public.organizations
  where code = 'COOTAQUARA';

  if v_source_count <> 1 then
    raise exception
      'Esperada exatamente uma organizacao com codigo SESCOOP-DF; encontradas: %.',
      v_source_count;
  end if;

  if v_target_count <> 1 then
    raise exception
      'Esperada exatamente uma organizacao com codigo COOTAQUARA; encontradas: %.',
      v_target_count;
  end if;
end
$$;

-- ------------------------------------------------------------
-- 2. Tipo de relacionamento sistemico
-- ------------------------------------------------------------
insert into public.organization_relationship_types (
  code,
  name,
  description,
  relationship_nature,
  is_hierarchical,
  allows_consolidated_view,
  allows_delegated_administration,
  active,
  metadata,
  created_by,
  updated_by
)
values (
  'SYSTEM_STATE_COOPERATIVE',
  'Sistema estadual e cooperativa atendida',
  'Vinculo institucional de supervisao, monitoramento, apoio e acompanhamento entre uma organizacao estadual do sistema e uma cooperativa atendida. Nao implica subordinacao juridica ou societaria.',
  'institutional',
  true,
  true,
  false,
  true,
  jsonb_build_object(
    'public_label', 'Sistema estadual e cooperativa atendida',
    'access_hierarchy', true,
    'legal_subordination', false,
    'allows_management_read', true
  ),
  auth.uid(),
  auth.uid()
)
on conflict (code) do update
set
  name = excluded.name,
  description = excluded.description,
  relationship_nature = excluded.relationship_nature,
  is_hierarchical = excluded.is_hierarchical,
  allows_consolidated_view = excluded.allows_consolidated_view,
  allows_delegated_administration = excluded.allows_delegated_administration,
  active = true,
  metadata = excluded.metadata,
  updated_at = timezone('utc', now()),
  updated_by = auth.uid();

-- ------------------------------------------------------------
-- 3. Relacionamento SESCOOP/DF -> COOTAQUARA
-- ------------------------------------------------------------
do $$
declare
  v_source_id uuid;
  v_target_id uuid;
  v_relationship_type_id uuid;
  v_relationship_id uuid;
begin
  select organization.id
    into v_source_id
  from public.organizations organization
  where organization.code = 'SESCOOP-DF';

  select organization.id
    into v_target_id
  from public.organizations organization
  where organization.code = 'COOTAQUARA';

  select relationship_type.id
    into v_relationship_type_id
  from public.organization_relationship_types relationship_type
  where relationship_type.code = 'SYSTEM_STATE_COOPERATIVE'
    and relationship_type.active = true;

  select relationship.id
    into v_relationship_id
  from public.organization_relationships relationship
  where relationship.parent_organization_id = v_source_id
    and relationship.child_organization_id = v_target_id
    and relationship.relationship_type_id = v_relationship_type_id
    and relationship.status in ('pending', 'active')
    and relationship.valid_until is null
  order by relationship.created_at desc
  limit 1;

  if v_relationship_id is null then
    insert into public.organization_relationships (
      parent_organization_id,
      child_organization_id,
      relationship_type_id,
      is_primary,
      allows_consolidated_view,
      allows_delegated_administration,
      valid_from,
      valid_until,
      status,
      notes,
      metadata,
      approved_at,
      approved_by,
      created_by,
      updated_by
    )
    values (
      v_source_id,
      v_target_id,
      v_relationship_type_id,
      false,
      true,
      false,
      current_date,
      null,
      'active',
      'Vinculo sistemico para acompanhamento e visualizacao hierarquica na Plataforma SPARKs; sem subordinacao juridica ou societaria.',
      jsonb_build_object(
        'relationship_key', 'sescoop-df-cootaquara-system-supervision',
        'access_purpose', 'management_read',
        'legal_subordination', false
      ),
      timezone('utc', now()),
      auth.uid(),
      auth.uid(),
      auth.uid()
    )
    returning id into v_relationship_id;
  else
    update public.organization_relationships relationship
    set
      is_primary = false,
      allows_consolidated_view = true,
      allows_delegated_administration = false,
      valid_from = least(relationship.valid_from, current_date),
      valid_until = null,
      status = 'active',
      notes = 'Vinculo sistemico para acompanhamento e visualizacao hierarquica na Plataforma SPARKs; sem subordinacao juridica ou societaria.',
      metadata = coalesce(relationship.metadata, '{}'::jsonb) || jsonb_build_object(
        'relationship_key', 'sescoop-df-cootaquara-system-supervision',
        'access_purpose', 'management_read',
        'legal_subordination', false
      ),
      approved_at = coalesce(relationship.approved_at, timezone('utc', now())),
      updated_at = timezone('utc', now()),
      updated_by = auth.uid()
    where relationship.id = v_relationship_id;
  end if;

  insert into public.organization_hierarchy_audit (
    organization_id,
    relationship_id,
    actor_user_id,
    action_code,
    reason,
    new_data
  )
  select
    v_source_id,
    v_relationship_id,
    auth.uid(),
    'system_supervision_relationship_initialized',
    'Instituicao do vinculo sistemico de leitura entre SESCOOP/DF e COOTAQUARA.',
    to_jsonb(relationship)
  from public.organization_relationships relationship
  where relationship.id = v_relationship_id
    and not exists (
      select 1
      from public.organization_hierarchy_audit audit
      where audit.relationship_id = v_relationship_id
        and audit.action_code = 'system_supervision_relationship_initialized'
    );
end
$$;

-- ------------------------------------------------------------
-- 4. Politica explicita de leitura para toda a rede descendente
-- ------------------------------------------------------------
do $$
declare
  v_source_id uuid;
  v_policy_id uuid;
begin
  select organization.id
    into v_source_id
  from public.organizations organization
  where organization.code = 'SESCOOP-DF';

  select policy.id
    into v_policy_id
  from public.organization_descendant_access_policies policy
  where policy.source_organization_id = v_source_id
    and policy.metadata ->> 'policy_key'
      = 'system-management-read-all-descendants'
  order by policy.created_at desc
  limit 1;

  if v_policy_id is null then
    insert into public.organization_descendant_access_policies (
      source_organization_id,
      relationship_scope,
      target_organization_id,
      module_code,
      access_mode,
      can_view_consolidated,
      can_view_detail,
      can_create,
      can_update,
      can_delete,
      can_manage_users,
      includes_confidential_data,
      requires_child_consent,
      child_consent_status,
      valid_from,
      valid_until,
      status,
      reason,
      metadata,
      applies_to_source_admins_only,
      assigned_user_id,
      approved_at,
      approved_by,
      created_by,
      updated_by
    )
    values (
      v_source_id,
      'all_descendants',
      null,
      null,
      'read_only',
      true,
      true,
      false,
      false,
      false,
      false,
      false,
      false,
      'not_required',
      current_date,
      null,
      'active',
      'Administradores do SESCOOP/DF podem visualizar e acompanhar organizacoes sistemicamente vinculadas, sem poder de alteracao.',
      jsonb_build_object(
        'policy_key', 'system-management-read-all-descendants',
        'access_purpose', 'management_read',
        'confidential_data', false
      ),
      true,
      null,
      timezone('utc', now()),
      auth.uid(),
      auth.uid(),
      auth.uid()
    )
    returning id into v_policy_id;
  else
    update public.organization_descendant_access_policies policy
    set
      relationship_scope = 'all_descendants',
      target_organization_id = null,
      module_code = null,
      access_mode = 'read_only',
      can_view_consolidated = true,
      can_view_detail = true,
      can_create = false,
      can_update = false,
      can_delete = false,
      can_manage_users = false,
      includes_confidential_data = false,
      requires_child_consent = false,
      child_consent_status = 'not_required',
      valid_from = least(policy.valid_from, current_date),
      valid_until = null,
      status = 'active',
      reason = 'Administradores do SESCOOP/DF podem visualizar e acompanhar organizacoes sistemicamente vinculadas, sem poder de alteracao.',
      metadata = coalesce(policy.metadata, '{}'::jsonb) || jsonb_build_object(
        'policy_key', 'system-management-read-all-descendants',
        'access_purpose', 'management_read',
        'confidential_data', false
      ),
      applies_to_source_admins_only = true,
      assigned_user_id = null,
      approved_at = coalesce(policy.approved_at, timezone('utc', now())),
      updated_at = timezone('utc', now()),
      updated_by = auth.uid()
    where policy.id = v_policy_id;
  end if;

  insert into public.organization_hierarchy_audit (
    organization_id,
    policy_id,
    actor_user_id,
    action_code,
    reason,
    new_data
  )
  select
    v_source_id,
    v_policy_id,
    auth.uid(),
    'system_management_read_policy_initialized',
    'Politica somente leitura para administradores do SESCOOP/DF sobre a rede vinculada.',
    to_jsonb(policy)
  from public.organization_descendant_access_policies policy
  where policy.id = v_policy_id
    and not exists (
      select 1
      from public.organization_hierarchy_audit audit
      where audit.policy_id = v_policy_id
        and audit.action_code = 'system_management_read_policy_initialized'
    );
end
$$;

commit;

-- ============================================================
-- 5. VERIFICACAO
-- ============================================================

select
  parent.code as organizacao_superior,
  coalesce(parent.trade_name, parent.legal_name) as nome_superior,
  child.code as organizacao_vinculada,
  coalesce(child.trade_name, child.legal_name) as nome_vinculada,
  relationship_type.code as tipo_relacionamento,
  relationship_type.name as nome_tipo,
  relationship_type.relationship_nature,
  relationship_type.is_hierarchical,
  relationship.is_primary,
  relationship.allows_consolidated_view,
  relationship.allows_delegated_administration,
  relationship.status,
  relationship.valid_from,
  relationship.valid_until,
  relationship.metadata
from public.organization_relationships relationship
join public.organization_relationship_types relationship_type
  on relationship_type.id = relationship.relationship_type_id
join public.organizations parent
  on parent.id = relationship.parent_organization_id
join public.organizations child
  on child.id = relationship.child_organization_id
where parent.code = 'SESCOOP-DF'
  and child.code = 'COOTAQUARA'
  and relationship_type.code = 'SYSTEM_STATE_COOPERATIVE';

select
  source.code as organizacao_origem,
  policy.relationship_scope,
  policy.access_mode,
  policy.can_view_consolidated,
  policy.can_view_detail,
  policy.can_create,
  policy.can_update,
  policy.can_delete,
  policy.can_manage_users,
  policy.includes_confidential_data,
  policy.requires_child_consent,
  policy.child_consent_status,
  policy.applies_to_source_admins_only,
  policy.status,
  policy.valid_from,
  policy.valid_until,
  policy.metadata
from public.organization_descendant_access_policies policy
join public.organizations source
  on source.id = policy.source_organization_id
where source.code = 'SESCOOP-DF'
  and policy.metadata ->> 'policy_key'
    = 'system-management-read-all-descendants';

select
  descendant.organization_id,
  descendant.parent_organization_id,
  descendant.depth,
  organization.code,
  coalesce(organization.trade_name, organization.legal_name) as organization_name
from public.get_organization_descendants(
  (select id from public.organizations where code = 'SESCOOP-DF'),
  50
) descendant
join public.organizations organization
  on organization.id = descendant.organization_id
order by descendant.depth, organization.code;
