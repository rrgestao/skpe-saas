-- ============================================================
-- SK-PE SaaS
-- Migration: Fundação de Administração da Plataforma SPARKs
-- ============================================================

create table public.platform_roles (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text,
  role_level integer not null default 10 check (role_level >= 0),
  active boolean not null default true,
  is_system_role boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.user_platform_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  platform_role_id uuid not null references public.platform_roles(id) on delete restrict,
  status text not null default 'active' check (status in ('invited','active','suspended','revoked')),
  valid_from timestamptz not null default timezone('utc', now()),
  valid_until timestamptz,
  assigned_at timestamptz not null default timezone('utc', now()),
  assigned_by uuid references public.profiles(id),
  suspended_at timestamptz,
  suspended_by uuid references public.profiles(id),
  revoked_at timestamptz,
  revoked_by uuid references public.profiles(id),
  assignment_reason text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (user_id, platform_role_id),
  check (valid_until is null or valid_until >= valid_from)
);

create table public.privileged_access_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete restrict,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  status text not null default 'requested' check (status in ('requested','approved','active','expired','revoked','rejected')),
  reason text not null check (char_length(trim(reason)) >= 10),
  ticket_reference text,
  requested_at timestamptz not null default timezone('utc', now()),
  requested_by uuid references public.profiles(id),
  approved_at timestamptz,
  approved_by uuid references public.profiles(id),
  activated_at timestamptz,
  expires_at timestamptz,
  revoked_at timestamptz,
  revoked_by uuid references public.profiles(id),
  revocation_reason text,
  mfa_verified boolean not null default false,
  mfa_verified_at timestamptz,
  source_ip inet,
  user_agent text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check (expires_at is null or expires_at > requested_at)
);

create table public.privileged_access_audit (
  id uuid primary key default gen_random_uuid(),
  privileged_access_session_id uuid references public.privileged_access_sessions(id) on delete set null,
  actor_user_id uuid references public.profiles(id) on delete set null,
  organization_id uuid references public.organizations(id) on delete set null,
  event_type text not null check (event_type in ('session_requested','session_approved','session_activated','session_expired','session_revoked','session_rejected','data_viewed','data_created','data_updated','data_deleted','data_exported','configuration_changed')),
  event_description text,
  entity_schema text,
  entity_table text,
  entity_id text,
  previous_data jsonb,
  new_data jsonb,
  metadata jsonb not null default '{}'::jsonb,
  source_ip inet,
  user_agent text,
  occurred_at timestamptz not null default timezone('utc', now())
);

create index idx_user_platform_roles_user on public.user_platform_roles(user_id);
create index idx_user_platform_roles_role on public.user_platform_roles(platform_role_id);
create index idx_privileged_sessions_user on public.privileged_access_sessions(user_id);
create index idx_privileged_sessions_organization on public.privileged_access_sessions(organization_id);
create index idx_privileged_sessions_status on public.privileged_access_sessions(status);
create index idx_privileged_sessions_expiration on public.privileged_access_sessions(expires_at);
create index idx_privileged_audit_session on public.privileged_access_audit(privileged_access_session_id);
create index idx_privileged_audit_actor on public.privileged_access_audit(actor_user_id);
create index idx_privileged_audit_organization on public.privileged_access_audit(organization_id);
create index idx_privileged_audit_occurred_at on public.privileged_access_audit(occurred_at desc);

create trigger set_platform_roles_updated_at before update on public.platform_roles for each row execute function public.set_updated_at();
create trigger set_user_platform_roles_updated_at before update on public.user_platform_roles for each row execute function public.set_updated_at();
create trigger set_privileged_access_sessions_updated_at before update on public.privileged_access_sessions for each row execute function public.set_updated_at();

create or replace function public.has_platform_role(target_role_code text)
returns boolean language sql stable security definer set search_path=''
as $$
  select exists (
    select 1 from public.user_platform_roles upr
    join public.platform_roles pr on pr.id=upr.platform_role_id
    where upr.user_id=auth.uid()
      and pr.code=lower(trim(target_role_code))
      and pr.active=true
      and upr.status='active'
      and upr.valid_from <= timezone('utc',now())
      and (upr.valid_until is null or upr.valid_until >= timezone('utc',now()))
  );
$$;

create or replace function public.is_platform_super_admin()
returns boolean language sql stable security definer set search_path=''
as $$ select public.has_platform_role('super_admin'); $$;

create or replace function public.get_my_platform_roles()
returns table(role_code text, role_name text, role_level integer, valid_from timestamptz, valid_until timestamptz)
language sql stable security definer set search_path=''
as $$
  select pr.code,pr.name,pr.role_level,upr.valid_from,upr.valid_until
  from public.user_platform_roles upr
  join public.platform_roles pr on pr.id=upr.platform_role_id
  where upr.user_id=auth.uid()
    and upr.status='active'
    and pr.active=true
    and upr.valid_from <= timezone('utc',now())
    and (upr.valid_until is null or upr.valid_until >= timezone('utc',now()))
  order by pr.role_level desc;
$$;

create or replace function public.has_active_privileged_access(target_organization_id uuid)
returns boolean language sql stable security definer set search_path=''
as $$
  select exists (
    select 1 from public.privileged_access_sessions pas
    where pas.user_id=auth.uid()
      and pas.organization_id=target_organization_id
      and pas.status='active'
      and pas.mfa_verified=true
      and pas.activated_at is not null
      and pas.activated_at <= timezone('utc',now())
      and pas.expires_at is not null
      and pas.expires_at > timezone('utc',now())
      and public.is_platform_super_admin()
  );
$$;

alter table public.platform_roles enable row level security;
alter table public.user_platform_roles enable row level security;
alter table public.privileged_access_sessions enable row level security;
alter table public.privileged_access_audit enable row level security;

create policy platform_roles_select_authenticated on public.platform_roles for select to authenticated using (active=true or public.is_platform_super_admin());
create policy platform_roles_manage_super_admin on public.platform_roles to authenticated using (public.is_platform_super_admin()) with check (public.is_platform_super_admin());
create policy user_platform_roles_select_own on public.user_platform_roles for select to authenticated using (user_id=auth.uid());
create policy user_platform_roles_select_super_admin on public.user_platform_roles for select to authenticated using (public.is_platform_super_admin());
create policy user_platform_roles_manage_super_admin on public.user_platform_roles to authenticated using (public.is_platform_super_admin()) with check (public.is_platform_super_admin());
create policy privileged_sessions_select_own on public.privileged_access_sessions for select to authenticated using (user_id=auth.uid());
create policy privileged_sessions_select_super_admin on public.privileged_access_sessions for select to authenticated using (public.is_platform_super_admin());
create policy privileged_sessions_insert_super_admin on public.privileged_access_sessions for insert to authenticated with check (user_id=auth.uid() and public.is_platform_super_admin());
create policy privileged_sessions_update_super_admin on public.privileged_access_sessions for update to authenticated using (public.is_platform_super_admin()) with check (public.is_platform_super_admin());
create policy privileged_audit_select_super_admin on public.privileged_access_audit for select to authenticated using (public.is_platform_super_admin());
create policy privileged_audit_insert_super_admin on public.privileged_access_audit for insert to authenticated with check (actor_user_id=auth.uid() and public.is_platform_super_admin());

revoke all on table public.platform_roles, public.user_platform_roles, public.privileged_access_sessions, public.privileged_access_audit from anon;
grant select,insert,update,delete on table public.platform_roles, public.user_platform_roles to authenticated;
grant select,insert,update on table public.privileged_access_sessions to authenticated;
grant select,insert on table public.privileged_access_audit to authenticated;

revoke all on function public.has_platform_role(text) from public;
revoke all on function public.is_platform_super_admin() from public;
revoke all on function public.get_my_platform_roles() from public;
revoke all on function public.has_active_privileged_access(uuid) from public;
grant execute on function public.has_platform_role(text) to authenticated,service_role;
grant execute on function public.is_platform_super_admin() to authenticated,service_role;
grant execute on function public.get_my_platform_roles() to authenticated,service_role;
grant execute on function public.has_active_privileged_access(uuid) to authenticated,service_role;

insert into public.platform_roles(id,code,name,description,role_level,active,is_system_role) values
('9eaafbfb-b4cc-492c-858f-c3f8859f13d9','super_admin','SUPER-ADMIN da Plataforma','Administra a infraestrutura global da Plataforma SPARKs.',100,true,true),
('9ae67dad-070f-44c0-8575-39ea01800ac7','platform_admin','Administrador da Plataforma','Administra operações globais delegadas da plataforma.',80,true,true),
('af0be528-de37-47a9-a6ee-795261ca1a56','support_admin','Administrador de Suporte','Realiza suporte técnico controlado e auditado.',50,true,true),
('13042ecc-f807-4161-92d3-e852e6fd001b','auditor','Auditor da Plataforma','Consulta trilhas de auditoria e evidências autorizadas.',30,true,true)
on conflict (code) do update set name=excluded.name,description=excluded.description,role_level=excluded.role_level,active=excluded.active,is_system_role=excluded.is_system_role,updated_at=timezone('utc',now());

insert into public.user_platform_roles(user_id,platform_role_id,status,valid_from,assignment_reason)
select p.id,pr.id,'active',timezone('utc',now()),'Usuário fundador e administrador inicial da Plataforma SPARKs.'
from public.profiles p join public.platform_roles pr on pr.code='super_admin'
where lower(p.email)='rr.gestao@gmail.com'
on conflict (user_id,platform_role_id) do update set status='active',valid_until=null,assignment_reason=excluded.assignment_reason,updated_at=timezone('utc',now());
