begin;

-- ============================================================
-- Plataforma SPARKs
-- Acesso hierarquico de gestao + catalogo oficial CNAE
-- Data: 2026-07-29
--
-- Objetivos:
--   1. Permitir que administradores de organizacoes superiores
--      visualizem organizacoes subordinadas sem receber poder de edicao.
--   2. Preservar politicas explicitas de acesso descendente.
--   3. Criar catalogo mestre versionado de CNAE e preparar o saneamento
--      dos CNAEs livres atualmente associados as organizacoes.
-- ============================================================

create extension if not exists pg_trgm;

-- ============================================================
-- 1. APERFEICOAMENTO DAS POLITICAS DE ACESSO DESCENDENTE
-- ============================================================

alter table public.organization_descendant_access_policies
  add column if not exists applies_to_source_admins_only boolean not null default true,
  add column if not exists assigned_user_id uuid references auth.users(id) on delete cascade;

create index if not exists idx_descendant_policy_assigned_user
  on public.organization_descendant_access_policies(assigned_user_id, status)
  where assigned_user_id is not null;

comment on column public.organization_descendant_access_policies.applies_to_source_admins_only is
  'Quando verdadeiro, a politica somente beneficia administradores ativos da organizacao de origem.';

comment on column public.organization_descendant_access_policies.assigned_user_id is
  'Permite conceder a politica a um usuario especifico da organizacao de origem.';

-- ------------------------------------------------------------
-- Acesso minimo de gestao por hierarquia.
--
-- Um administrador ativo da organizacao superior pode consultar
-- descendentes quando todos os relacionamentos do caminho autorizarem
-- visao consolidada, seja no relacionamento ou no tipo de relacionamento.
-- Esse acesso nunca autoriza criar, alterar, excluir ou gerir usuarios.
-- ------------------------------------------------------------

create or replace function public.has_hierarchical_management_read_access(
  target_organization_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  with recursive accessible_tree as (
    select
      membership.organization_id as source_organization_id,
      relationship.child_organization_id as organization_id,
      1 as depth,
      array[
        relationship.parent_organization_id,
        relationship.child_organization_id
      ]::uuid[] as path,
      (
        relationship.allows_consolidated_view
        or relationship_type.allows_consolidated_view
      ) as path_allows_view
    from public.organization_memberships membership
    join public.organization_relationships relationship
      on relationship.parent_organization_id = membership.organization_id
    join public.organization_relationship_types relationship_type
      on relationship_type.id = relationship.relationship_type_id
    where membership.user_id = auth.uid()
      and membership.status = 'active'
      and membership.is_organization_admin = true
      and membership.valid_from <= timezone('utc', now())
      and (
        membership.valid_until is null
        or membership.valid_until >= timezone('utc', now())
      )
      and relationship_type.is_hierarchical = true
      and relationship.status = 'active'
      and relationship.valid_from <= current_date
      and (
        relationship.valid_until is null
        or relationship.valid_until >= current_date
      )

    union all

    select
      tree.source_organization_id,
      relationship.child_organization_id,
      tree.depth + 1,
      tree.path || relationship.child_organization_id,
      tree.path_allows_view
        and (
          relationship.allows_consolidated_view
          or relationship_type.allows_consolidated_view
        )
    from accessible_tree tree
    join public.organization_relationships relationship
      on relationship.parent_organization_id = tree.organization_id
    join public.organization_relationship_types relationship_type
      on relationship_type.id = relationship.relationship_type_id
    where relationship_type.is_hierarchical = true
      and relationship.status = 'active'
      and relationship.valid_from <= current_date
      and (
        relationship.valid_until is null
        or relationship.valid_until >= current_date
      )
      and tree.depth < 50
      and not (relationship.child_organization_id = any(tree.path))
  )
  select exists (
    select 1
    from accessible_tree tree
    where tree.organization_id = target_organization_id
      and tree.path_allows_view = true
  );
$$;

create or replace function public.can_access_descendant_organization(
  target_organization_id uuid,
  target_module_code text default null,
  requested_action text default 'read'
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  with source_memberships as (
    select
      membership.id as membership_id,
      membership.organization_id,
      membership.is_organization_admin
    from public.organization_memberships membership
    where membership.user_id = auth.uid()
      and membership.status = 'active'
      and membership.valid_from <= timezone('utc', now())
      and (
        membership.valid_until is null
        or membership.valid_until >= timezone('utc', now())
      )
  ), candidate_policies as (
    select policy.*
    from public.organization_descendant_access_policies policy
    join source_memberships source_membership
      on source_membership.organization_id = policy.source_organization_id
    where policy.status = 'active'
      and policy.valid_from <= current_date
      and (
        policy.valid_until is null
        or policy.valid_until >= current_date
      )
      and (
        policy.module_code is null
        or upper(policy.module_code) = upper(coalesce(target_module_code, policy.module_code))
      )
      and (
        policy.requires_child_consent = false
        or policy.child_consent_status in ('not_required', 'approved')
      )
      and (
        policy.assigned_user_id = auth.uid()
        or (
          policy.assigned_user_id is null
          and (
            policy.applies_to_source_admins_only = false
            or source_membership.is_organization_admin = true
          )
        )
      )
      and (
        (
          policy.relationship_scope = 'specific_organization'
          and policy.target_organization_id = target_organization_id
        )
        or (
          policy.relationship_scope = 'direct_children'
          and exists (
            select 1
            from public.organization_relationships relationship
            join public.organization_relationship_types relationship_type
              on relationship_type.id = relationship.relationship_type_id
            where relationship.parent_organization_id = policy.source_organization_id
              and relationship.child_organization_id = target_organization_id
              and relationship_type.is_hierarchical = true
              and relationship.status = 'active'
              and relationship.valid_from <= current_date
              and (
                relationship.valid_until is null
                or relationship.valid_until >= current_date
              )
          )
        )
        or (
          policy.relationship_scope = 'all_descendants'
          and public.is_organization_descendant(
            policy.source_organization_id,
            target_organization_id
          )
        )
      )
  )
  select
    public.is_platform_super_admin()
    or public.is_organization_admin(target_organization_id)
    or exists (
      select 1
      from source_memberships own_membership
      where own_membership.organization_id = target_organization_id
    )
    or (
      lower(coalesce(requested_action, 'read')) in ('read', 'consolidated')
      and public.has_hierarchical_management_read_access(target_organization_id)
    )
    or exists (
      select 1
      from candidate_policies candidate_policy
      where case lower(coalesce(requested_action, 'read'))
        when 'consolidated' then candidate_policy.can_view_consolidated
        when 'read' then candidate_policy.can_view_detail or candidate_policy.can_view_consolidated
        when 'create' then candidate_policy.can_create
        when 'update' then candidate_policy.can_update
        when 'delete' then candidate_policy.can_delete
        when 'manage_users' then candidate_policy.can_manage_users
        else false
      end
    );
$$;

create or replace function public.can_read_organization(
  target_organization_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.can_access_descendant_organization(
    target_organization_id,
    null,
    'read'
  );
$$;

-- ------------------------------------------------------------
-- Nova API de organizacoes acessiveis.
-- Mantem os campos utilizados pela aplicacao e acrescenta contexto
-- para diferenciar acesso direto, hierarquico e global.
-- ------------------------------------------------------------

create or replace function public.get_my_organizations_v2()
returns table (
  organization_id uuid,
  organization_code text,
  legal_name text,
  trade_name text,
  organization_level text,
  membership_status text,
  is_organization_admin boolean,
  access_origin text,
  access_mode text,
  source_organization_id uuid,
  source_organization_name text,
  hierarchy_depth integer,
  can_manage_organization boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    organization.id::uuid as organization_id,
    organization.code::text as organization_code,
    organization.legal_name::text,
    organization.trade_name::text,
    organization.organization_level::text,
    coalesce(direct_membership.status::text, 'hierarchical') as membership_status,
    (
      public.is_platform_super_admin()
      or coalesce(direct_membership.is_organization_admin, false)
    ) as is_organization_admin,
    case
      when direct_membership.id is not null then 'direct_membership'
      when public.is_platform_super_admin() then 'platform_super_admin'
      else 'hierarchical_management'
    end::text as access_origin,
    case
      when public.is_platform_super_admin() then 'administrative'
      when direct_membership.is_organization_admin = true then 'administrative'
      when direct_membership.id is not null then 'direct'
      else 'read_only'
    end::text as access_mode,
    hierarchy_source.organization_id::uuid as source_organization_id,
    hierarchy_source.organization_name::text as source_organization_name,
    hierarchy_source.depth::integer as hierarchy_depth,
    (
      public.is_platform_super_admin()
      or coalesce(direct_membership.is_organization_admin, false)
    ) as can_manage_organization
  from public.organizations organization
  left join public.organization_memberships direct_membership
    on direct_membership.organization_id = organization.id
   and direct_membership.user_id = auth.uid()
   and direct_membership.status = 'active'
   and direct_membership.valid_from <= timezone('utc', now())
   and (
     direct_membership.valid_until is null
     or direct_membership.valid_until >= timezone('utc', now())
   )
  left join lateral (
    select
      ancestor.organization_id,
      coalesce(source.trade_name, source.legal_name, source.code) as organization_name,
      ancestor.depth
    from public.get_organization_ancestors(organization.id, 50) ancestor
    join public.organization_memberships source_membership
      on source_membership.organization_id = ancestor.organization_id
     and source_membership.user_id = auth.uid()
     and source_membership.status = 'active'
     and source_membership.is_organization_admin = true
     and source_membership.valid_from <= timezone('utc', now())
     and (
       source_membership.valid_until is null
       or source_membership.valid_until >= timezone('utc', now())
     )
    join public.organizations source
      on source.id = ancestor.organization_id
    order by ancestor.depth
    limit 1
  ) hierarchy_source on true
  where organization.status = 'active'
    and (
      public.is_platform_super_admin()
      or public.can_access_descendant_organization(organization.id, null, 'read')
    )
  order by coalesce(organization.trade_name, organization.legal_name, organization.code);
$$;

revoke all on function public.has_hierarchical_management_read_access(uuid) from public;
revoke all on function public.can_access_descendant_organization(uuid, text, text) from public;
revoke all on function public.can_read_organization(uuid) from public;
revoke all on function public.get_my_organizations_v2() from public;

grant execute on function public.has_hierarchical_management_read_access(uuid) to authenticated, service_role;
grant execute on function public.can_access_descendant_organization(uuid, text, text) to authenticated, service_role;
grant execute on function public.can_read_organization(uuid) to authenticated, service_role;
grant execute on function public.get_my_organizations_v2() to authenticated, service_role;

comment on function public.get_my_organizations_v2() is
  'Retorna organizacoes acessiveis por vinculo direto, SUPER-ADMIN ou acesso hierarquico de gestao, informando origem e modo do acesso.';

-- ============================================================
-- 2. CATALOGO MESTRE OFICIAL DE CNAE
-- ============================================================

create table if not exists public.cnae_catalog_versions (
  version_code text primary key,
  version_name text not null,
  source_organization text not null default 'IBGE/CONCLA',
  source_url text not null,
  official_reference text,
  effective_from date,
  effective_until date,
  is_current boolean not null default false,
  active boolean not null default true,
  source_checksum text,
  imported_at timestamptz,
  imported_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists uq_cnae_catalog_current_version
  on public.cnae_catalog_versions(is_current)
  where is_current = true and active = true;

insert into public.cnae_catalog_versions (
  version_code,
  version_name,
  source_organization,
  source_url,
  official_reference,
  effective_from,
  is_current,
  active
)
values (
  '2.3',
  'CNAE-Subclasses 2.3',
  'IBGE/CONCLA',
  'https://cnae.ibge.gov.br/classificacoes/download-concla/8265-download',
  'Resolucao CONCLA de 2018 que divulga a CNAE-Subclasses versao 2.3',
  date '2019-01-01',
  true,
  true
)
on conflict (version_code) do update set
  version_name = excluded.version_name,
  source_organization = excluded.source_organization,
  source_url = excluded.source_url,
  official_reference = excluded.official_reference,
  effective_from = excluded.effective_from,
  is_current = true,
  active = true,
  updated_at = timezone('utc', now());

create table if not exists public.cnae_catalog (
  id uuid primary key default gen_random_uuid(),
  version_code text not null references public.cnae_catalog_versions(version_code) on delete restrict,
  subclass_code text not null,
  formatted_code text generated always as (
    substr(subclass_code, 1, 2)
    || '.' || substr(subclass_code, 3, 2)
    || '-' || substr(subclass_code, 5, 1)
    || '/' || substr(subclass_code, 6, 2)
  ) stored,
  description text not null,
  section_code text,
  section_name text,
  division_code text,
  division_name text,
  group_code text,
  group_name text,
  class_code text,
  class_name text,
  active boolean not null default true,
  source_row_number integer,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references auth.users(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references auth.users(id) on delete set null,
  constraint cnae_catalog_subclass_code_format
    check (subclass_code ~ '^[0-9]{7}$'),
  constraint cnae_catalog_description_not_blank
    check (length(trim(description)) > 0),
  constraint cnae_catalog_version_code_unique
    unique (version_code, subclass_code)
);

create index if not exists idx_cnae_catalog_code
  on public.cnae_catalog(version_code, subclass_code);

create index if not exists idx_cnae_catalog_description_trgm
  on public.cnae_catalog using gin (lower(description) gin_trgm_ops);

create index if not exists idx_cnae_catalog_hierarchy
  on public.cnae_catalog(version_code, section_code, division_code, group_code, class_code);

alter table public.cnae_catalog_versions enable row level security;
alter table public.cnae_catalog enable row level security;

drop policy if exists cnae_catalog_versions_select on public.cnae_catalog_versions;
create policy cnae_catalog_versions_select
on public.cnae_catalog_versions
for select
to authenticated
using (active = true);

drop policy if exists cnae_catalog_select on public.cnae_catalog;
create policy cnae_catalog_select
on public.cnae_catalog
for select
to authenticated
using (active = true);

drop policy if exists cnae_catalog_versions_manage on public.cnae_catalog_versions;
create policy cnae_catalog_versions_manage
on public.cnae_catalog_versions
for all
to authenticated
using (public.is_platform_super_admin())
with check (public.is_platform_super_admin());

drop policy if exists cnae_catalog_manage on public.cnae_catalog;
create policy cnae_catalog_manage
on public.cnae_catalog
for all
to authenticated
using (public.is_platform_super_admin())
with check (public.is_platform_super_admin());

grant select, insert, update, delete on table public.cnae_catalog_versions to authenticated;
grant select, insert, update, delete on table public.cnae_catalog to authenticated;
grant select, insert, update, delete on table public.cnae_catalog_versions to service_role;
grant select, insert, update, delete on table public.cnae_catalog to service_role;

-- ============================================================
-- 3. EVOLUCAO DAS ASSOCIACOES ORGANIZACAO x CNAE
-- ============================================================

alter table public.organization_economic_activities
  add column if not exists cnae_catalog_id uuid references public.cnae_catalog(id) on delete restrict,
  add column if not exists verification_status text not null default 'unverified',
  add column if not exists source_type text,
  add column if not exists source_reference text,
  add column if not exists verified_at timestamptz,
  add column if not exists verified_by uuid references auth.users(id) on delete set null,
  add column if not exists valid_from date not null default current_date,
  add column if not exists valid_until date;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'organization_economic_activities_verification_status_check'
      and conrelid = 'public.organization_economic_activities'::regclass
  ) then
    alter table public.organization_economic_activities
      add constraint organization_economic_activities_verification_status_check
      check (verification_status in ('unverified', 'needs_review', 'verified', 'rejected'));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'organization_economic_activities_validity_check'
      and conrelid = 'public.organization_economic_activities'::regclass
  ) then
    alter table public.organization_economic_activities
      add constraint organization_economic_activities_validity_check
      check (valid_until is null or valid_until >= valid_from);
  end if;
end
$$;

update public.organization_economic_activities
set
  verification_status = case
    when cnae_catalog_id is null then 'needs_review'
    else verification_status
  end,
  source_type = coalesce(source_type, 'legacy_manual'),
  source_reference = coalesce(
    source_reference,
    'Registro anterior a implantacao do catalogo oficial CNAE'
  ),
  updated_at = timezone('utc', now())
where cnae_catalog_id is null;

-- Garante no maximo um CNAE principal ativo por organizacao.
with ranked_primary as (
  select
    activity.id,
    row_number() over (
      partition by activity.organization_id
      order by activity.updated_at desc, activity.created_at desc, activity.id
    ) as primary_order
  from public.organization_economic_activities activity
  where activity.status = 'active'
    and activity.is_primary = true
)
update public.organization_economic_activities activity
set
  is_primary = false,
  verification_status = case
    when activity.verification_status = 'verified' then 'needs_review'
    else activity.verification_status
  end,
  updated_at = timezone('utc', now())
from ranked_primary ranked
where activity.id = ranked.id
  and ranked.primary_order > 1;

create unique index if not exists uq_org_economic_activity_active_primary
  on public.organization_economic_activities(organization_id)
  where status = 'active' and is_primary = true;

create index if not exists idx_org_economic_activity_catalog
  on public.organization_economic_activities(cnae_catalog_id, status);

create index if not exists idx_org_economic_activity_review
  on public.organization_economic_activities(organization_id, verification_status, status);

-- Leitura hierarquica; alteracao permanece restrita a administracao direta.
drop policy if exists organization_economic_activities_select on public.organization_economic_activities;
create policy organization_economic_activities_select
on public.organization_economic_activities
for select
to authenticated
using (public.can_read_organization(organization_id));

drop policy if exists organization_economic_activities_manage on public.organization_economic_activities;
create policy organization_economic_activities_manage
on public.organization_economic_activities
for all
to authenticated
using (
  public.is_platform_super_admin()
  or public.can_manage_organization(organization_id)
)
with check (
  public.is_platform_super_admin()
  or public.can_manage_organization(organization_id)
);

create table if not exists public.organization_cnae_audit (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  actor_user_id uuid references auth.users(id) on delete set null,
  action_code text not null,
  reason text not null,
  previous_data jsonb,
  new_data jsonb,
  occurred_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_organization_cnae_audit_org
  on public.organization_cnae_audit(organization_id, occurred_at desc);

alter table public.organization_cnae_audit enable row level security;

drop policy if exists organization_cnae_audit_select on public.organization_cnae_audit;
create policy organization_cnae_audit_select
on public.organization_cnae_audit
for select
to authenticated
using (public.can_read_organization(organization_id));

drop policy if exists organization_cnae_audit_insert on public.organization_cnae_audit;
create policy organization_cnae_audit_insert
on public.organization_cnae_audit
for insert
to authenticated
with check (
  public.is_platform_super_admin()
  or public.can_manage_organization(organization_id)
);

grant select on table public.organization_cnae_audit to authenticated;

-- ============================================================
-- 4. APIs PARA PESQUISA E ASSOCIACAO OFICIAL
-- ============================================================

create or replace function public.search_cnae_catalog(
  search_term text default null,
  result_limit integer default 25,
  result_offset integer default 0
)
returns table (
  cnae_catalog_id uuid,
  version_code text,
  subclass_code text,
  formatted_code text,
  description text,
  section_code text,
  section_name text,
  division_code text,
  division_name text,
  group_code text,
  group_name text,
  class_code text,
  class_name text
)
language sql
stable
security definer
set search_path = ''
as $$
  with parameters as (
    select
      trim(coalesce(search_term, '')) as text_term,
      regexp_replace(coalesce(search_term, ''), '[^0-9]', '', 'g') as digit_term,
      least(greatest(coalesce(result_limit, 25), 1), 100) as safe_limit,
      greatest(coalesce(result_offset, 0), 0) as safe_offset
  )
  select
    catalog.id,
    catalog.version_code,
    catalog.subclass_code,
    catalog.formatted_code,
    catalog.description,
    catalog.section_code,
    catalog.section_name,
    catalog.division_code,
    catalog.division_name,
    catalog.group_code,
    catalog.group_name,
    catalog.class_code,
    catalog.class_name
  from public.cnae_catalog catalog
  join public.cnae_catalog_versions version
    on version.version_code = catalog.version_code
  cross join parameters
  where catalog.active = true
    and version.active = true
    and version.is_current = true
    and (
      parameters.text_term = ''
      or (
        parameters.digit_term <> ''
        and catalog.subclass_code like parameters.digit_term || '%'
      )
      or lower(catalog.description) like '%' || lower(parameters.text_term) || '%'
      or lower(coalesce(catalog.section_name, '')) like '%' || lower(parameters.text_term) || '%'
      or lower(coalesce(catalog.division_name, '')) like '%' || lower(parameters.text_term) || '%'
    )
  order by
    case
      when catalog.subclass_code = parameters.digit_term then 0
      when parameters.digit_term <> '' and catalog.subclass_code like parameters.digit_term || '%' then 1
      when lower(catalog.description) like lower(parameters.text_term) || '%' then 2
      else 3
    end,
    catalog.subclass_code
  limit (select safe_limit from parameters)
  offset (select safe_offset from parameters);
$$;

create or replace function public.get_organization_cnaes_v3(
  target_organization_id uuid
)
returns table (
  organization_activity_id uuid,
  cnae_catalog_id uuid,
  version_code text,
  subclass_code text,
  formatted_code text,
  description text,
  is_primary boolean,
  verification_status text,
  source_type text,
  source_reference text,
  verified_at timestamptz,
  verified_by uuid,
  is_official_catalog_entry boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.can_read_organization(target_organization_id) then
    raise exception
      'Acesso negado: o usuario nao pode consultar os CNAEs desta organizacao.'
      using errcode = '42501';
  end if;

  return query
  select
    activity.id,
    activity.cnae_catalog_id,
    catalog.version_code,
    activity.cnae_code,
    coalesce(
      catalog.formatted_code,
      substr(activity.cnae_code, 1, 2)
      || '.' || substr(activity.cnae_code, 3, 2)
      || '-' || substr(activity.cnae_code, 5, 1)
      || '/' || substr(activity.cnae_code, 6, 2)
    ),
    coalesce(catalog.description, activity.description),
    activity.is_primary,
    activity.verification_status,
    activity.source_type,
    activity.source_reference,
    activity.verified_at,
    activity.verified_by,
    (activity.cnae_catalog_id is not null)
  from public.organization_economic_activities activity
  left join public.cnae_catalog catalog
    on catalog.id = activity.cnae_catalog_id
  where activity.organization_id = target_organization_id
    and activity.status = 'active'
  order by activity.is_primary desc, activity.cnae_code;
end;
$$;

create or replace function public.replace_organization_cnaes_v3(
  target_organization_id uuid,
  selected_cnaes jsonb,
  target_source_type text,
  target_source_reference text,
  change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  selected_item jsonb;
  selected_catalog_id uuid;
  selected_is_primary boolean;
  selected_count integer;
  primary_count integer;
  distinct_count integer;
  valid_catalog_count integer;
  previous_data jsonb;
  new_data jsonb;
  primary_description text;
  normalized_source_type text;
  catalog_row record;
begin
  if not (
    public.is_platform_super_admin()
    or public.can_manage_organization(target_organization_id)
  ) then
    raise exception
      'Acesso negado: somente administradores diretos podem alterar os CNAEs desta organizacao.'
      using errcode = '42501';
  end if;

  if length(trim(coalesce(change_reason, ''))) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.';
  end if;

  if jsonb_typeof(coalesce(selected_cnaes, '[]'::jsonb)) <> 'array' then
    raise exception 'A selecao de CNAEs deve ser enviada como uma lista.';
  end if;

  normalized_source_type := lower(trim(coalesce(target_source_type, 'manual_confirmed')));

  if normalized_source_type not in (
    'official_cnpj',
    'official_ibge',
    'official_document',
    'manual_confirmed'
  ) then
    raise exception 'Origem de verificacao dos CNAEs invalida.';
  end if;

  selected_count := jsonb_array_length(coalesce(selected_cnaes, '[]'::jsonb));

  select count(*)
  into primary_count
  from jsonb_array_elements(coalesce(selected_cnaes, '[]'::jsonb)) item
  where lower(coalesce(item ->> 'is_primary', 'false')) in ('true', '1', 'yes', 'sim');

  if selected_count > 0 and primary_count <> 1 then
    raise exception 'Selecione exatamente um CNAE principal.';
  end if;

  select count(distinct (item ->> 'cnae_catalog_id'))
  into distinct_count
  from jsonb_array_elements(coalesce(selected_cnaes, '[]'::jsonb)) item;

  if distinct_count <> selected_count then
    raise exception 'A lista contem CNAEs duplicados ou sem identificador oficial.';
  end if;

  select count(*)
  into valid_catalog_count
  from public.cnae_catalog catalog
  join public.cnae_catalog_versions version
    on version.version_code = catalog.version_code
  where catalog.id in (
    select (item ->> 'cnae_catalog_id')::uuid
    from jsonb_array_elements(coalesce(selected_cnaes, '[]'::jsonb)) item
  )
    and catalog.active = true
    and version.active = true
    and version.is_current = true;

  if valid_catalog_count <> selected_count then
    raise exception 'Um ou mais CNAEs nao pertencem ao catalogo oficial vigente.';
  end if;

  select coalesce(jsonb_agg(to_jsonb(activity) order by activity.is_primary desc, activity.cnae_code), '[]'::jsonb)
  into previous_data
  from public.organization_economic_activities activity
  where activity.organization_id = target_organization_id
    and activity.status = 'active';

  update public.organization_economic_activities
  set
    status = 'inactive',
    valid_until = current_date,
    updated_at = timezone('utc', now()),
    updated_by = auth.uid()
  where organization_id = target_organization_id
    and status = 'active';

  for selected_item in
    select item
    from jsonb_array_elements(coalesce(selected_cnaes, '[]'::jsonb)) item
  loop
    selected_catalog_id := (selected_item ->> 'cnae_catalog_id')::uuid;
    selected_is_primary := lower(coalesce(selected_item ->> 'is_primary', 'false'))
      in ('true', '1', 'yes', 'sim');

    select catalog.*
    into catalog_row
    from public.cnae_catalog catalog
    join public.cnae_catalog_versions version
      on version.version_code = catalog.version_code
    where catalog.id = selected_catalog_id
      and catalog.active = true
      and version.active = true
      and version.is_current = true;

    if catalog_row.id is null then
      raise exception 'CNAE oficial nao encontrado durante a gravacao.';
    end if;

    insert into public.organization_economic_activities (
      organization_id,
      cnae_code,
      description,
      is_primary,
      status,
      cnae_catalog_id,
      verification_status,
      source_type,
      source_reference,
      verified_at,
      verified_by,
      valid_from,
      valid_until,
      created_by,
      updated_by
    )
    values (
      target_organization_id,
      catalog_row.subclass_code,
      catalog_row.description,
      selected_is_primary,
      'active',
      catalog_row.id,
      'verified',
      normalized_source_type,
      nullif(trim(target_source_reference), ''),
      timezone('utc', now()),
      auth.uid(),
      current_date,
      null,
      auth.uid(),
      auth.uid()
    )
    on conflict (organization_id, cnae_code) do update set
      description = excluded.description,
      is_primary = excluded.is_primary,
      status = 'active',
      cnae_catalog_id = excluded.cnae_catalog_id,
      verification_status = 'verified',
      source_type = excluded.source_type,
      source_reference = excluded.source_reference,
      verified_at = excluded.verified_at,
      verified_by = excluded.verified_by,
      valid_from = current_date,
      valid_until = null,
      updated_at = timezone('utc', now()),
      updated_by = auth.uid();

    if selected_is_primary then
      primary_description := catalog_row.description;
    end if;
  end loop;

  update public.organizations
  set
    primary_activity_description = primary_description,
    institutional_profile_updated_at = timezone('utc', now()),
    institutional_profile_updated_by = auth.uid(),
    updated_at = timezone('utc', now()),
    updated_by = auth.uid()
  where id = target_organization_id;

  select coalesce(jsonb_agg(to_jsonb(activity) order by activity.is_primary desc, activity.cnae_code), '[]'::jsonb)
  into new_data
  from public.organization_economic_activities activity
  where activity.organization_id = target_organization_id
    and activity.status = 'active';

  insert into public.organization_cnae_audit (
    organization_id,
    actor_user_id,
    action_code,
    reason,
    previous_data,
    new_data
  )
  values (
    target_organization_id,
    auth.uid(),
    'cnaes_replaced_from_official_catalog',
    trim(change_reason),
    previous_data,
    new_data
  );

  return target_organization_id;
end;
$$;

revoke all on function public.search_cnae_catalog(text, integer, integer) from public;
revoke all on function public.get_organization_cnaes_v3(uuid) from public;
revoke all on function public.replace_organization_cnaes_v3(uuid, jsonb, text, text, text) from public;

grant execute on function public.search_cnae_catalog(text, integer, integer) to authenticated, service_role;
grant execute on function public.get_organization_cnaes_v3(uuid) to authenticated, service_role;
grant execute on function public.replace_organization_cnaes_v3(uuid, jsonb, text, text, text) to authenticated, service_role;

comment on table public.cnae_catalog is
  'Catalogo mestre versionado de subclasses CNAE importado de fonte oficial IBGE/CONCLA.';

comment on table public.organization_economic_activities is
  'Associacoes entre organizacoes e CNAEs. Registros sem cnae_catalog_id sao legados e exigem saneamento.';

comment on function public.search_cnae_catalog(text, integer, integer) is
  'Pesquisa CNAEs oficiais vigentes por codigo, descricao ou hierarquia.';

comment on function public.replace_organization_cnaes_v3(uuid, jsonb, text, text, text) is
  'Substitui os CNAEs ativos de uma organizacao usando exclusivamente o catalogo oficial vigente, com auditoria.';

commit;
