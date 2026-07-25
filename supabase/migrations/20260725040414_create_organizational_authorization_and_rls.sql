-- ============================================================
-- SK-PE SaaS
-- Migration: Autorização Organizacional e Políticas RLS
-- ============================================================

-- ============================================================
-- FUNÇÕES DE AUTORIZAÇÃO
-- ============================================================

create or replace function public.current_user_id()
returns uuid
language sql
stable
security invoker
set search_path = ''
as $$
  select auth.uid();
$$;

create or replace function public.is_active_member(
  target_organization_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.organization_memberships membership
    where membership.organization_id = target_organization_id
      and membership.user_id = auth.uid()
      and membership.status = 'active'
      and membership.valid_from <= timezone('utc', now())
      and (
        membership.valid_until is null
        or membership.valid_until >= timezone('utc', now())
      )
  );
$$;

create or replace function public.is_organization_admin(
  target_organization_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.organization_memberships membership
    where membership.organization_id = target_organization_id
      and membership.user_id = auth.uid()
      and membership.status = 'active'
      and membership.is_organization_admin = true
      and membership.valid_from <= timezone('utc', now())
      and (
        membership.valid_until is null
        or membership.valid_until >= timezone('utc', now())
      )
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
  select public.is_active_member(target_organization_id);
$$;

create or replace function public.can_manage_organization(
  target_organization_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_organization_admin(target_organization_id);
$$;

-- ============================================================
-- PERMISSÕES DAS FUNÇÕES
-- ============================================================

revoke all on function public.current_user_id() from public;
revoke all on function public.is_active_member(uuid) from public;
revoke all on function public.is_organization_admin(uuid) from public;
revoke all on function public.can_read_organization(uuid) from public;
revoke all on function public.can_manage_organization(uuid) from public;

grant execute on function public.current_user_id()
to authenticated;

grant execute on function public.is_active_member(uuid)
to authenticated;

grant execute on function public.is_organization_admin(uuid)
to authenticated;

grant execute on function public.can_read_organization(uuid)
to authenticated;

grant execute on function public.can_manage_organization(uuid)
to authenticated;

-- ============================================================
-- PROFILES
-- ============================================================

create policy profiles_select_own
on public.profiles
for select
to authenticated
using (
  id = (select auth.uid())
);

create policy profiles_update_own
on public.profiles
for update
to authenticated
using (
  id = (select auth.uid())
)
with check (
  id = (select auth.uid())
);

-- ============================================================
-- ORGANIZATION MEMBERSHIPS
-- ============================================================

create policy memberships_select_own
on public.organization_memberships
for select
to authenticated
using (
  user_id = (select auth.uid())
);

create policy memberships_select_by_organization_admin
on public.organization_memberships
for select
to authenticated
using (
  public.is_organization_admin(organization_id)
);

create policy memberships_insert_by_organization_admin
on public.organization_memberships
for insert
to authenticated
with check (
  public.is_organization_admin(organization_id)
);

create policy memberships_update_by_organization_admin
on public.organization_memberships
for update
to authenticated
using (
  public.is_organization_admin(organization_id)
)
with check (
  public.is_organization_admin(organization_id)
);

create policy memberships_delete_by_organization_admin
on public.organization_memberships
for delete
to authenticated
using (
  public.is_organization_admin(organization_id)
);

-- ============================================================
-- ORGANIZATIONS
-- ============================================================

create policy organizations_select_active_member
on public.organizations
for select
to authenticated
using (
  public.can_read_organization(id)
);

create policy organizations_update_admin
on public.organizations
for update
to authenticated
using (
  public.can_manage_organization(id)
)
with check (
  public.can_manage_organization(id)
);

-- ============================================================
-- ECOSYSTEMS
-- ============================================================

create policy ecosystems_select_through_membership
on public.ecosystems
for select
to authenticated
using (
  exists (
    select 1
    from public.organizations organization
    where organization.ecosystem_id = ecosystems.id
      and public.can_read_organization(organization.id)
  )
);

-- ============================================================
-- ORGANIZATION RELATIONSHIPS
-- ============================================================

create policy organization_relationships_select_member
on public.organization_relationships
for select
to authenticated
using (
  public.can_read_organization(source_organization_id)
  or public.can_read_organization(target_organization_id)
);

create policy organization_relationships_insert_admin
on public.organization_relationships
for insert
to authenticated
with check (
  public.can_manage_organization(source_organization_id)
);

create policy organization_relationships_update_admin
on public.organization_relationships
for update
to authenticated
using (
  public.can_manage_organization(source_organization_id)
)
with check (
  public.can_manage_organization(source_organization_id)
);

create policy organization_relationships_delete_admin
on public.organization_relationships
for delete
to authenticated
using (
  public.can_manage_organization(source_organization_id)
);

-- ============================================================
-- BLOQUEIO DE ACESSO ANÔNIMO
-- ============================================================

revoke all on table public.ecosystems from anon;
revoke all on table public.organizations from anon;
revoke all on table public.organization_relationships from anon;
revoke all on table public.profiles from anon;
revoke all on table public.organization_memberships from anon;

-- ============================================================
-- ACESSO BÁSICO PARA USUÁRIOS AUTENTICADOS
-- A RLS continuará decidindo quais linhas podem ser acessadas.
-- ============================================================

grant select on table public.ecosystems
to authenticated;

grant select, update on table public.organizations
to authenticated;

grant select, insert, update, delete
on table public.organization_relationships
to authenticated;

grant select, update on table public.profiles
to authenticated;

grant select, insert, update, delete
on table public.organization_memberships
to authenticated;

-- ============================================================
-- COMENTÁRIOS
-- ============================================================

comment on function public.is_active_member(uuid) is
  'Verifica se o usuário autenticado possui vínculo ativo com a organização.';

comment on function public.is_organization_admin(uuid) is
  'Verifica se o usuário autenticado é administrador ativo da organização.';

comment on function public.can_read_organization(uuid) is
  'Autoriza leitura da organização somente mediante vínculo ativo.';

comment on function public.can_manage_organization(uuid) is
  'Autoriza gestão da organização somente para administrador ativo.';