begin;

-- ============================================================
-- COMPATIBILIDADE COM A ESTRUTURA LEGADA
-- A tabela organization_relationships já existia no banco com
-- source_organization_id, target_organization_id, relationship_type
-- e active. A nova arquitetura usa parent_organization_id,
-- child_organization_id, relationship_type_id e status.
--
-- Para preservar integralmente qualquer dado anterior, a tabela
-- legada é renomeada somente quando a nova estrutura ainda não existe.
-- Nenhum registro é apagado.
-- ============================================================

do $$
begin
  if to_regclass('public.organization_relationships') is not null
     and not exists (
       select 1
       from information_schema.columns
       where table_schema = 'public'
         and table_name = 'organization_relationships'
         and column_name = 'status'
     ) then
    if to_regclass('public.organization_relationships_legacy_20260727') is null then
      alter table public.organization_relationships
        rename to organization_relationships_legacy_20260727;
    else
      raise exception 'Já existe public.organization_relationships_legacy_20260727. Revise a estrutura antes de continuar.';
    end if;
  end if;
end
$$;

-- ============================================================
-- Plataforma SPARKs
-- Hierarquia organizacional multinivel e acesso descendente
-- parametrizavel.
-- ============================================================

create table if not exists public.organization_relationship_types (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text,
  relationship_nature text not null default 'hierarchical'
    check (relationship_nature in ('hierarchical','institutional','support','partnership')),
  is_hierarchical boolean not null default true,
  allows_consolidated_view boolean not null default false,
  allows_delegated_administration boolean not null default false,
  active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null
);

create table if not exists public.organization_relationships (
  id uuid primary key default gen_random_uuid(),
  parent_organization_id uuid not null references public.organizations(id) on delete restrict,
  child_organization_id uuid not null references public.organizations(id) on delete restrict,
  relationship_type_id uuid not null references public.organization_relationship_types(id) on delete restrict,
  is_primary boolean not null default false,
  allows_consolidated_view boolean not null default false,
  allows_delegated_administration boolean not null default false,
  valid_from date not null default current_date,
  valid_until date,
  status text not null default 'active'
    check (status in ('pending','active','suspended','ended')),
  notes text,
  metadata jsonb not null default '{}'::jsonb,
  approved_at timestamptz,
  approved_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,
  constraint organization_relationship_no_self check (parent_organization_id <> child_organization_id),
  constraint organization_relationship_validity check (valid_until is null or valid_until >= valid_from)
);

create unique index if not exists uq_org_relationship_active_type
  on public.organization_relationships(parent_organization_id, child_organization_id, relationship_type_id)
  where status in ('pending','active') and valid_until is null;

create unique index if not exists uq_org_relationship_primary_child
  on public.organization_relationships(child_organization_id)
  where is_primary = true and status = 'active' and valid_until is null;

create index if not exists idx_org_relationship_parent
  on public.organization_relationships(parent_organization_id, status, valid_from, valid_until);

create index if not exists idx_org_relationship_child
  on public.organization_relationships(child_organization_id, status, valid_from, valid_until);

create table if not exists public.organization_descendant_access_policies (
  id uuid primary key default gen_random_uuid(),
  source_organization_id uuid not null references public.organizations(id) on delete cascade,
  relationship_scope text not null default 'all_descendants'
    check (relationship_scope in ('direct_children','all_descendants','specific_organization')),
  target_organization_id uuid references public.organizations(id) on delete cascade,
  module_code text,
  access_mode text not null default 'consolidated'
    check (access_mode in ('consolidated','read_only','operational_delegated','administrative_delegated')),
  can_view_consolidated boolean not null default true,
  can_view_detail boolean not null default false,
  can_create boolean not null default false,
  can_update boolean not null default false,
  can_delete boolean not null default false,
  can_manage_users boolean not null default false,
  includes_confidential_data boolean not null default false,
  requires_child_consent boolean not null default true,
  child_consent_status text not null default 'pending'
    check (child_consent_status in ('not_required','pending','approved','rejected','revoked')),
  valid_from date not null default current_date,
  valid_until date,
  status text not null default 'active'
    check (status in ('draft','active','suspended','ended')),
  reason text,
  metadata jsonb not null default '{}'::jsonb,
  approved_at timestamptz,
  approved_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,
  constraint descendant_policy_specific_target check (
    (relationship_scope = 'specific_organization' and target_organization_id is not null)
    or (relationship_scope <> 'specific_organization' and target_organization_id is null)
  ),
  constraint descendant_policy_validity check (valid_until is null or valid_until >= valid_from),
  constraint descendant_policy_not_self check (
    target_organization_id is null or target_organization_id <> source_organization_id
  )
);

create index if not exists idx_descendant_policy_source
  on public.organization_descendant_access_policies(source_organization_id, status, module_code);

create index if not exists idx_descendant_policy_target
  on public.organization_descendant_access_policies(target_organization_id, status);

create table if not exists public.organization_hierarchy_audit (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references public.organizations(id) on delete set null,
  relationship_id uuid references public.organization_relationships(id) on delete set null,
  policy_id uuid references public.organization_descendant_access_policies(id) on delete set null,
  actor_user_id uuid references public.profiles(id) on delete set null,
  action_code text not null,
  reason text,
  previous_data jsonb,
  new_data jsonb,
  occurred_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_org_hierarchy_audit_org
  on public.organization_hierarchy_audit(organization_id, occurred_at desc);

-- ------------------------------------------------------------
-- Catalogo inicial de relacionamentos
-- ------------------------------------------------------------
insert into public.organization_relationship_types (
  code, name, description, relationship_nature, is_hierarchical,
  allows_consolidated_view, allows_delegated_administration, metadata
)
values
  ('MATRIX_BRANCH', 'Matriz e filial', 'Relaciona uma matriz às suas filiais ou unidades.', 'hierarchical', true, true, true, '{"public_label":"Matriz e filial"}'::jsonb),
  ('SYSTEM_NATIONAL_STATE', 'Sistema nacional e organização estadual', 'Relaciona a organização nacional às organizações estaduais.', 'hierarchical', true, true, true, '{"public_label":"Nacional e estadual"}'::jsonb),
  ('SYSTEM_STATE_MUNICIPAL', 'Sistema estadual e organização municipal', 'Relaciona a organização estadual às organizações municipais.', 'hierarchical', true, true, true, '{"public_label":"Estadual e municipal"}'::jsonb),
  ('SYSTEM_MUNICIPAL_UNIT', 'Organização municipal e unidade', 'Relaciona a organização municipal às suas unidades.', 'hierarchical', true, true, true, '{"public_label":"Municipal e unidade"}'::jsonb),
  ('CONFEDERATION_CENTRAL', 'Confederação e central', 'Relaciona uma confederação de cooperativas às centrais ou federações.', 'hierarchical', true, true, true, '{"public_label":"Confederação e central"}'::jsonb),
  ('CENTRAL_SINGULAR', 'Central e singular', 'Relaciona uma central ou federação às cooperativas singulares.', 'hierarchical', true, true, true, '{"public_label":"Central e singular"}'::jsonb),
  ('CONFEDERATION_SINGULAR', 'Confederação e singular', 'Relaciona diretamente uma confederação a uma singular quando aplicável.', 'hierarchical', true, true, false, '{"public_label":"Confederação e singular"}'::jsonb),
  ('AFFILIATION', 'Afiliação institucional', 'Vínculo institucional não necessariamente hierárquico.', 'institutional', false, true, false, '{"public_label":"Afiliação institucional"}'::jsonb),
  ('SUPERVISION', 'Supervisão', 'Vínculo de acompanhamento ou supervisão institucional.', 'institutional', false, true, true, '{"public_label":"Supervisão"}'::jsonb),
  ('SUPPORT', 'Apoio institucional', 'Vínculo de apoio técnico, metodológico ou operacional.', 'support', false, false, true, '{"public_label":"Apoio institucional"}'::jsonb),
  ('PARTNERSHIP', 'Parceria', 'Vínculo de parceria sem relação hierárquica.', 'partnership', false, false, false, '{"public_label":"Parceria"}'::jsonb)
on conflict (code) do update set
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
-- Funcoes de arvore
-- ------------------------------------------------------------
create or replace function public.get_organization_descendants(
  root_organization_id uuid,
  maximum_depth integer default 50
)
returns table (
  organization_id uuid,
  parent_organization_id uuid,
  depth integer,
  path uuid[]
)
language sql
stable
security definer
set search_path = ''
as $$
  with recursive descendants as (
    select
      r.child_organization_id as organization_id,
      r.parent_organization_id,
      1 as depth,
      array[r.parent_organization_id, r.child_organization_id]::uuid[] as path
    from public.organization_relationships r
    join public.organization_relationship_types rt on rt.id = r.relationship_type_id
    where r.parent_organization_id = root_organization_id
      and rt.is_hierarchical = true
      and r.status = 'active'
      and r.valid_from <= current_date
      and (r.valid_until is null or r.valid_until >= current_date)

    union all

    select
      r.child_organization_id,
      r.parent_organization_id,
      d.depth + 1,
      d.path || r.child_organization_id
    from descendants d
    join public.organization_relationships r
      on r.parent_organization_id = d.organization_id
    join public.organization_relationship_types rt on rt.id = r.relationship_type_id
    where rt.is_hierarchical = true
      and r.status = 'active'
      and r.valid_from <= current_date
      and (r.valid_until is null or r.valid_until >= current_date)
      and d.depth < greatest(coalesce(maximum_depth, 50), 1)
      and not (r.child_organization_id = any(d.path))
  )
  select d.organization_id, d.parent_organization_id, d.depth, d.path
  from descendants d;
$$;

create or replace function public.get_organization_ancestors(
  leaf_organization_id uuid,
  maximum_depth integer default 50
)
returns table (
  organization_id uuid,
  child_organization_id uuid,
  depth integer,
  path uuid[]
)
language sql
stable
security definer
set search_path = ''
as $$
  with recursive ancestors as (
    select
      r.parent_organization_id as organization_id,
      r.child_organization_id,
      1 as depth,
      array[r.child_organization_id, r.parent_organization_id]::uuid[] as path
    from public.organization_relationships r
    join public.organization_relationship_types rt on rt.id = r.relationship_type_id
    where r.child_organization_id = leaf_organization_id
      and rt.is_hierarchical = true
      and r.status = 'active'
      and r.valid_from <= current_date
      and (r.valid_until is null or r.valid_until >= current_date)

    union all

    select
      r.parent_organization_id,
      r.child_organization_id,
      a.depth + 1,
      a.path || r.parent_organization_id
    from ancestors a
    join public.organization_relationships r
      on r.child_organization_id = a.organization_id
    join public.organization_relationship_types rt on rt.id = r.relationship_type_id
    where rt.is_hierarchical = true
      and r.status = 'active'
      and r.valid_from <= current_date
      and (r.valid_until is null or r.valid_until >= current_date)
      and a.depth < greatest(coalesce(maximum_depth, 50), 1)
      and not (r.parent_organization_id = any(a.path))
  )
  select a.organization_id, a.child_organization_id, a.depth, a.path
  from ancestors a;
$$;

create or replace function public.is_organization_descendant(
  ancestor_organization_id uuid,
  descendant_organization_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.get_organization_descendants(ancestor_organization_id, 50) d
    where d.organization_id = descendant_organization_id
  );
$$;

-- ------------------------------------------------------------
-- Impedir ciclos hierarquicos
-- ------------------------------------------------------------
create or replace function public.prevent_organization_relationship_cycle()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  is_hierarchy boolean;
begin
  select rt.is_hierarchical
    into is_hierarchy
  from public.organization_relationship_types rt
  where rt.id = new.relationship_type_id;

  if coalesce(is_hierarchy, false)
     and new.status in ('pending','active')
     and public.is_organization_descendant(new.child_organization_id, new.parent_organization_id) then
    raise exception 'O relacionamento criaria um ciclo na hierarquia organizacional.' using errcode = '23514';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_prevent_organization_relationship_cycle on public.organization_relationships;
create trigger trg_prevent_organization_relationship_cycle
before insert or update of parent_organization_id, child_organization_id, relationship_type_id, status
on public.organization_relationships
for each row execute function public.prevent_organization_relationship_cycle();

-- ------------------------------------------------------------
-- Sincronizar relacao hierarquica primaria com parent_organization_id
-- ------------------------------------------------------------
create or replace function public.sync_primary_parent_organization()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  is_hierarchy boolean;
begin
  select rt.is_hierarchical into is_hierarchy
  from public.organization_relationship_types rt
  where rt.id = coalesce(new.relationship_type_id, old.relationship_type_id);

  if tg_op in ('INSERT','UPDATE') then
    if coalesce(is_hierarchy, false)
       and new.is_primary = true
       and new.status = 'active'
       and new.valid_from <= current_date
       and (new.valid_until is null or new.valid_until >= current_date) then
      update public.organizations
      set parent_organization_id = new.parent_organization_id,
          updated_at = timezone('utc', now()),
          updated_by = auth.uid()
      where id = new.child_organization_id;
    elsif tg_op = 'UPDATE'
       and old.is_primary = true
       and (new.is_primary = false or new.status <> 'active' or (new.valid_until is not null and new.valid_until < current_date)) then
      update public.organizations
      set parent_organization_id = null,
          updated_at = timezone('utc', now()),
          updated_by = auth.uid()
      where id = old.child_organization_id
        and parent_organization_id = old.parent_organization_id;
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_sync_primary_parent_organization on public.organization_relationships;
create trigger trg_sync_primary_parent_organization
after insert or update on public.organization_relationships
for each row execute function public.sync_primary_parent_organization();

-- ------------------------------------------------------------
-- Autorizacao descendente parametrizavel
-- ------------------------------------------------------------
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
  with user_source_organizations as (
    select om.organization_id
    from public.organization_memberships om
    where om.user_id = auth.uid()
      and om.status = 'active'
      and om.valid_from <= timezone('utc', now())
      and (om.valid_until is null or om.valid_until >= timezone('utc', now()))
  ), candidate_policies as (
    select p.*
    from public.organization_descendant_access_policies p
    join user_source_organizations uso on uso.organization_id = p.source_organization_id
    where p.status = 'active'
      and p.valid_from <= current_date
      and (p.valid_until is null or p.valid_until >= current_date)
      and (p.module_code is null or upper(p.module_code) = upper(coalesce(target_module_code, p.module_code)))
      and (
        p.requires_child_consent = false
        or p.child_consent_status in ('not_required','approved')
      )
      and (
        (p.relationship_scope = 'specific_organization' and p.target_organization_id = target_organization_id)
        or (
          p.relationship_scope = 'direct_children'
          and exists (
            select 1
            from public.organization_relationships r
            join public.organization_relationship_types rt on rt.id = r.relationship_type_id
            where r.parent_organization_id = p.source_organization_id
              and r.child_organization_id = target_organization_id
              and rt.is_hierarchical = true
              and r.status = 'active'
              and r.valid_from <= current_date
              and (r.valid_until is null or r.valid_until >= current_date)
          )
        )
        or (
          p.relationship_scope = 'all_descendants'
          and public.is_organization_descendant(p.source_organization_id, target_organization_id)
        )
      )
  )
  select
    public.is_platform_super_admin()
    or public.is_organization_admin(target_organization_id)
    or exists (
      select 1 from public.organization_memberships own_membership
      where own_membership.organization_id = target_organization_id
        and own_membership.user_id = auth.uid()
        and own_membership.status = 'active'
        and own_membership.valid_from <= timezone('utc', now())
        and (own_membership.valid_until is null or own_membership.valid_until >= timezone('utc', now()))
    )
    or exists (
      select 1
      from candidate_policies cp
      where case lower(coalesce(requested_action, 'read'))
        when 'consolidated' then cp.can_view_consolidated
        when 'read' then cp.can_view_detail or cp.can_view_consolidated
        when 'create' then cp.can_create
        when 'update' then cp.can_update
        when 'delete' then cp.can_delete
        when 'manage_users' then cp.can_manage_users
        else false
      end
    );
$$;

create or replace function public.get_accessible_organizations(
  target_module_code text default null,
  requested_action text default 'read'
)
returns table (
  organization_id uuid,
  code text,
  trade_name text,
  legal_name text,
  access_origin text
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    accessible.organization_id,
    accessible.code,
    accessible.trade_name,
    accessible.legal_name,
    accessible.access_origin
  from (
    select distinct
      o.id as organization_id,
      o.code,
      o.trade_name,
      o.legal_name,
      case
        when exists (
          select 1
          from public.organization_memberships om
          where om.organization_id = o.id
            and om.user_id = auth.uid()
            and om.status = 'active'
        ) then 'direct_membership'
        else 'descendant_policy'
      end as access_origin
    from public.organizations o
    where public.can_access_descendant_organization(
      o.id,
      target_module_code,
      requested_action
    )
  ) accessible
  order by coalesce(
    accessible.trade_name,
    accessible.legal_name,
    accessible.code
  );
$$;

-- ------------------------------------------------------------
-- Funcoes administrativas de manutencao
-- ------------------------------------------------------------
create or replace function public.can_manage_organization_hierarchy(
  target_organization_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    public.is_platform_super_admin()
    or public.is_organization_admin(target_organization_id)
    or public.has_module_permission(target_organization_id, 'SK-ASM', 'organization_hierarchy.manage');
$$;

create or replace function public.upsert_organization_relationship(
  relationship_id uuid,
  parent_id uuid,
  child_id uuid,
  relationship_type_code text,
  primary_relationship boolean,
  consolidated_view boolean,
  delegated_administration boolean,
  starts_on date,
  ends_on date,
  relationship_status text,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  result_id uuid;
  type_id uuid;
  previous_row jsonb;
begin
  if not (public.can_manage_organization_hierarchy(parent_id) or public.can_manage_organization_hierarchy(child_id)) then
    raise exception 'Acesso negado para manter a hierarquia organizacional.' using errcode = '42501';
  end if;

  select id into type_id
  from public.organization_relationship_types
  where code = upper(trim(relationship_type_code)) and active = true;

  if type_id is null then
    raise exception 'Tipo de relacionamento organizacional inválido: %.', relationship_type_code;
  end if;

  if relationship_id is null then
    insert into public.organization_relationships (
      parent_organization_id, child_organization_id, relationship_type_id,
      is_primary, allows_consolidated_view, allows_delegated_administration,
      valid_from, valid_until, status, notes, created_by, updated_by
    ) values (
      parent_id, child_id, type_id,
      coalesce(primary_relationship, false), coalesce(consolidated_view, false), coalesce(delegated_administration, false),
      coalesce(starts_on, current_date), ends_on, lower(coalesce(relationship_status, 'active')),
      nullif(trim(change_reason), ''), auth.uid(), auth.uid()
    ) returning id into result_id;
  else
    select to_jsonb(r) into previous_row
    from public.organization_relationships r where r.id = relationship_id for update;

    if previous_row is null then
      raise exception 'Relacionamento organizacional não encontrado.';
    end if;

    update public.organization_relationships
    set parent_organization_id = parent_id,
        child_organization_id = child_id,
        relationship_type_id = type_id,
        is_primary = coalesce(primary_relationship, false),
        allows_consolidated_view = coalesce(consolidated_view, false),
        allows_delegated_administration = coalesce(delegated_administration, false),
        valid_from = coalesce(starts_on, current_date),
        valid_until = ends_on,
        status = lower(coalesce(relationship_status, 'active')),
        notes = nullif(trim(change_reason), ''),
        updated_at = timezone('utc', now()),
        updated_by = auth.uid()
    where id = relationship_id
    returning id into result_id;
  end if;

  insert into public.organization_hierarchy_audit (
    organization_id, relationship_id, actor_user_id, action_code, reason, previous_data, new_data
  )
  select parent_id, result_id, auth.uid(),
         case when relationship_id is null then 'relationship_created' else 'relationship_updated' end,
         nullif(trim(change_reason), ''), previous_row, to_jsonb(r)
  from public.organization_relationships r where r.id = result_id;

  return result_id;
end;
$$;

create or replace function public.upsert_descendant_access_policy(
  policy_id uuid,
  source_org_id uuid,
  scope_code text,
  target_org_id uuid,
  module_code_value text,
  access_mode_value text,
  view_consolidated boolean,
  view_detail boolean,
  allow_create boolean,
  allow_update boolean,
  allow_delete boolean,
  allow_manage_users boolean,
  include_confidential boolean,
  require_child_consent boolean,
  consent_status text,
  starts_on date,
  ends_on date,
  policy_status text,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  result_id uuid;
  previous_row jsonb;
begin
  if not public.can_manage_organization_hierarchy(source_org_id) then
    raise exception 'Acesso negado para manter políticas de acesso descendente.' using errcode = '42501';
  end if;

  if policy_id is null then
    insert into public.organization_descendant_access_policies (
      source_organization_id, relationship_scope, target_organization_id, module_code,
      access_mode, can_view_consolidated, can_view_detail, can_create, can_update,
      can_delete, can_manage_users, includes_confidential_data, requires_child_consent,
      child_consent_status, valid_from, valid_until, status, reason, created_by, updated_by
    ) values (
      source_org_id, lower(trim(scope_code)), target_org_id, nullif(upper(trim(module_code_value)), ''),
      lower(trim(access_mode_value)), coalesce(view_consolidated, true), coalesce(view_detail, false),
      coalesce(allow_create, false), coalesce(allow_update, false), coalesce(allow_delete, false),
      coalesce(allow_manage_users, false), coalesce(include_confidential, false),
      coalesce(require_child_consent, true), lower(coalesce(consent_status, 'pending')),
      coalesce(starts_on, current_date), ends_on, lower(coalesce(policy_status, 'active')),
      nullif(trim(change_reason), ''), auth.uid(), auth.uid()
    ) returning id into result_id;
  else
    select to_jsonb(p) into previous_row
    from public.organization_descendant_access_policies p where p.id = policy_id for update;

    if previous_row is null then
      raise exception 'Política de acesso descendente não encontrada.';
    end if;

    update public.organization_descendant_access_policies
    set source_organization_id = source_org_id,
        relationship_scope = lower(trim(scope_code)),
        target_organization_id = target_org_id,
        module_code = nullif(upper(trim(module_code_value)), ''),
        access_mode = lower(trim(access_mode_value)),
        can_view_consolidated = coalesce(view_consolidated, true),
        can_view_detail = coalesce(view_detail, false),
        can_create = coalesce(allow_create, false),
        can_update = coalesce(allow_update, false),
        can_delete = coalesce(allow_delete, false),
        can_manage_users = coalesce(allow_manage_users, false),
        includes_confidential_data = coalesce(include_confidential, false),
        requires_child_consent = coalesce(require_child_consent, true),
        child_consent_status = lower(coalesce(consent_status, 'pending')),
        valid_from = coalesce(starts_on, current_date),
        valid_until = ends_on,
        status = lower(coalesce(policy_status, 'active')),
        reason = nullif(trim(change_reason), ''),
        updated_at = timezone('utc', now()),
        updated_by = auth.uid()
    where id = policy_id
    returning id into result_id;
  end if;

  insert into public.organization_hierarchy_audit (
    organization_id, policy_id, actor_user_id, action_code, reason, previous_data, new_data
  )
  select source_org_id, result_id, auth.uid(),
         case when policy_id is null then 'descendant_policy_created' else 'descendant_policy_updated' end,
         nullif(trim(change_reason), ''), previous_row, to_jsonb(p)
  from public.organization_descendant_access_policies p where p.id = result_id;

  return result_id;
end;
$$;

-- ------------------------------------------------------------
-- RLS
-- ------------------------------------------------------------
alter table public.organization_relationship_types enable row level security;
alter table public.organization_relationships enable row level security;
alter table public.organization_descendant_access_policies enable row level security;
alter table public.organization_hierarchy_audit enable row level security;

drop policy if exists organization_relationship_types_read on public.organization_relationship_types;
create policy organization_relationship_types_read
on public.organization_relationship_types for select
to authenticated
using (active = true or public.is_platform_super_admin());

drop policy if exists organization_relationships_read on public.organization_relationships;
create policy organization_relationships_read
on public.organization_relationships for select
to authenticated
using (
  public.is_platform_super_admin()
  or public.can_access_descendant_organization(parent_organization_id, null, 'read')
  or public.can_access_descendant_organization(child_organization_id, null, 'read')
);

drop policy if exists organization_relationships_manage on public.organization_relationships;
create policy organization_relationships_manage
on public.organization_relationships for all
to authenticated
using (
  public.can_manage_organization_hierarchy(parent_organization_id)
  or public.can_manage_organization_hierarchy(child_organization_id)
)
with check (
  public.can_manage_organization_hierarchy(parent_organization_id)
  or public.can_manage_organization_hierarchy(child_organization_id)
);

drop policy if exists descendant_access_policies_read on public.organization_descendant_access_policies;
create policy descendant_access_policies_read
on public.organization_descendant_access_policies for select
to authenticated
using (
  public.is_platform_super_admin()
  or public.can_manage_organization_hierarchy(source_organization_id)
  or (target_organization_id is not null and public.is_organization_admin(target_organization_id))
);

drop policy if exists descendant_access_policies_manage on public.organization_descendant_access_policies;
create policy descendant_access_policies_manage
on public.organization_descendant_access_policies for all
to authenticated
using (public.can_manage_organization_hierarchy(source_organization_id))
with check (public.can_manage_organization_hierarchy(source_organization_id));

drop policy if exists organization_hierarchy_audit_read on public.organization_hierarchy_audit;
create policy organization_hierarchy_audit_read
on public.organization_hierarchy_audit for select
to authenticated
using (
  public.is_platform_super_admin()
  or (organization_id is not null and public.can_manage_organization_hierarchy(organization_id))
);

-- Permissoes de execucao
grant select on public.organization_relationship_types to authenticated;
grant select on public.organization_relationships to authenticated;
grant select on public.organization_descendant_access_policies to authenticated;
grant select on public.organization_hierarchy_audit to authenticated;

grant execute on function public.get_organization_descendants(uuid, integer) to authenticated;
grant execute on function public.get_organization_ancestors(uuid, integer) to authenticated;
grant execute on function public.is_organization_descendant(uuid, uuid) to authenticated;
grant execute on function public.can_access_descendant_organization(uuid, text, text) to authenticated;
grant execute on function public.get_accessible_organizations(text, text) to authenticated;
grant execute on function public.can_manage_organization_hierarchy(uuid) to authenticated;
grant execute on function public.upsert_organization_relationship(uuid, uuid, uuid, text, boolean, boolean, boolean, date, date, text, text) to authenticated;
grant execute on function public.upsert_descendant_access_policy(uuid, uuid, text, uuid, text, text, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, text, date, date, text, text) to authenticated;

comment on table public.organization_relationships is
  'Vínculos hierárquicos e institucionais entre organizações, com vigência e histórico.';
comment on table public.organization_descendant_access_policies is
  'Políticas parametrizáveis de acesso de uma organização superior às organizações inferiores.';
comment on function public.can_access_descendant_organization(uuid, text, text) is
  'Verifica acesso próprio ou descendente por organização, módulo, ação, vigência e consentimento.';

commit;

-- ============================================================
-- Verificacao final
-- ============================================================
select
  (select count(*) from public.organization_relationship_types where active = true) as tipos_relacionamento_ativos,
  (select count(*) from public.organization_relationships) as relacionamentos_cadastrados,
  (select count(*) from public.organization_descendant_access_policies) as politicas_acesso_cadastradas;
