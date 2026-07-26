-- ============================================================
-- SK-PE SaaS
-- Migration: Fundação de Acesso Modular da Plataforma SPARKs
-- ============================================================

create table public.modules (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  short_name text not null,
  description text,
  status text not null default 'planned' check (status in ('planned','active','inactive','deprecated')),
  is_core boolean not null default false,
  display_order integer not null default 0,
  icon_name text,
  route_path text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.organization_modules (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  module_id uuid not null references public.modules(id) on delete restrict,
  status text not null default 'active' check (status in ('trial','active','suspended','cancelled')),
  enabled boolean not null default true,
  enabled_at timestamptz,
  disabled_at timestamptz,
  valid_from timestamptz not null default timezone('utc', now()),
  valid_until timestamptz,
  configuration jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  unique (organization_id, module_id),
  check (valid_until is null or valid_until >= valid_from)
);

create table public.module_roles (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references public.modules(id) on delete cascade,
  code text not null,
  name text not null,
  description text,
  role_level integer not null default 10,
  is_system_role boolean not null default true,
  active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (module_id, code)
);

create table public.module_permissions (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references public.modules(id) on delete cascade,
  code text not null,
  name text not null,
  description text,
  permission_group text not null default 'general',
  active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (module_id, code)
);

create table public.role_permissions (
  module_role_id uuid not null references public.module_roles(id) on delete cascade,
  module_permission_id uuid not null references public.module_permissions(id) on delete cascade,
  granted_at timestamptz not null default timezone('utc', now()),
  primary key (module_role_id, module_permission_id)
);

create table public.user_module_roles (
  id uuid primary key default gen_random_uuid(),
  organization_module_id uuid not null references public.organization_modules(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  module_role_id uuid not null references public.module_roles(id) on delete restrict,
  status text not null default 'active' check (status in ('invited','active','suspended','revoked')),
  valid_from timestamptz not null default timezone('utc', now()),
  valid_until timestamptz,
  assigned_at timestamptz not null default timezone('utc', now()),
  assigned_by uuid references public.profiles(id),
  revoked_at timestamptz,
  revoked_by uuid references public.profiles(id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (organization_module_id, user_id, module_role_id),
  check (valid_until is null or valid_until >= valid_from)
);

create index idx_modules_status on public.modules(status);
create index idx_organization_modules_organization on public.organization_modules(organization_id);
create index idx_organization_modules_module on public.organization_modules(module_id);
create index idx_module_roles_module on public.module_roles(module_id);
create index idx_module_permissions_module on public.module_permissions(module_id);
create index idx_user_module_roles_org_module on public.user_module_roles(organization_module_id);
create index idx_user_module_roles_user on public.user_module_roles(user_id);

create trigger set_modules_updated_at before update on public.modules for each row execute function public.set_updated_at();
create trigger set_organization_modules_updated_at before update on public.organization_modules for each row execute function public.set_updated_at();
create trigger set_module_roles_updated_at before update on public.module_roles for each row execute function public.set_updated_at();
create trigger set_module_permissions_updated_at before update on public.module_permissions for each row execute function public.set_updated_at();
create trigger set_user_module_roles_updated_at before update on public.user_module_roles for each row execute function public.set_updated_at();

create or replace function public.validate_user_module_role()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  organization_module_module_id uuid;
  selected_role_module_id uuid;
begin
  select module_id into organization_module_module_id
  from public.organization_modules where id = new.organization_module_id;

  select module_id into selected_role_module_id
  from public.module_roles where id = new.module_role_id;

  if organization_module_module_id is null then
    raise exception 'O módulo da organização informado não existe.';
  end if;

  if selected_role_module_id is null then
    raise exception 'O papel de módulo informado não existe.';
  end if;

  if organization_module_module_id <> selected_role_module_id then
    raise exception 'O papel selecionado não pertence ao módulo habilitado para a organização.';
  end if;

  return new;
end;
$$;

create trigger validate_user_module_role_trigger
before insert or update on public.user_module_roles
for each row execute function public.validate_user_module_role();

create or replace function public.has_module_access(target_organization_id uuid, target_module_code text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.organization_modules om
    join public.modules m on m.id = om.module_id
    join public.user_module_roles umr on umr.organization_module_id = om.id
    join public.module_roles mr on mr.id = umr.module_role_id
    where om.organization_id = target_organization_id
      and m.code = upper(trim(target_module_code))
      and m.status = 'active'
      and om.enabled = true
      and om.status in ('trial','active')
      and om.valid_from <= timezone('utc', now())
      and (om.valid_until is null or om.valid_until >= timezone('utc', now()))
      and umr.user_id = auth.uid()
      and umr.status = 'active'
      and umr.valid_from <= timezone('utc', now())
      and (umr.valid_until is null or umr.valid_until >= timezone('utc', now()))
      and mr.active = true
      and public.is_active_member(om.organization_id)
  );
$$;

create or replace function public.has_module_permission(target_organization_id uuid, target_module_code text, target_permission_code text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.organization_modules om
    join public.modules m on m.id = om.module_id
    join public.user_module_roles umr on umr.organization_module_id = om.id
    join public.module_roles mr on mr.id = umr.module_role_id
    join public.role_permissions rp on rp.module_role_id = mr.id
    join public.module_permissions mp on mp.id = rp.module_permission_id
    where om.organization_id = target_organization_id
      and m.code = upper(trim(target_module_code))
      and mp.code = lower(trim(target_permission_code))
      and m.status = 'active'
      and mp.active = true
      and mr.active = true
      and om.enabled = true
      and om.status in ('trial','active')
      and om.valid_from <= timezone('utc', now())
      and (om.valid_until is null or om.valid_until >= timezone('utc', now()))
      and umr.user_id = auth.uid()
      and umr.status = 'active'
      and umr.valid_from <= timezone('utc', now())
      and (umr.valid_until is null or umr.valid_until >= timezone('utc', now()))
      and public.is_active_member(om.organization_id)
  );
$$;

create or replace function public.get_my_modules(target_organization_id uuid)
returns table (
  organization_module_id uuid,
  module_id uuid,
  module_code text,
  module_name text,
  module_short_name text,
  module_description text,
  module_route_path text,
  module_icon_name text,
  role_code text,
  role_name text
)
language sql
stable
security definer
set search_path = ''
as $$
  select distinct om.id, m.id, m.code, m.name, m.short_name,
    m.description, m.route_path, m.icon_name, mr.code, mr.name
  from public.organization_modules om
  join public.modules m on m.id = om.module_id
  join public.user_module_roles umr on umr.organization_module_id = om.id
  join public.module_roles mr on mr.id = umr.module_role_id
  where om.organization_id = target_organization_id
    and umr.user_id = auth.uid()
    and m.status = 'active'
    and om.enabled = true
    and om.status in ('trial','active')
    and om.valid_from <= timezone('utc', now())
    and (om.valid_until is null or om.valid_until >= timezone('utc', now()))
    and umr.status = 'active'
    and umr.valid_from <= timezone('utc', now())
    and (umr.valid_until is null or umr.valid_until >= timezone('utc', now()))
    and mr.active = true
    and public.is_active_member(om.organization_id)
  order by m.name;
$$;

alter table public.modules enable row level security;
alter table public.organization_modules enable row level security;
alter table public.module_roles enable row level security;
alter table public.module_permissions enable row level security;
alter table public.role_permissions enable row level security;
alter table public.user_module_roles enable row level security;

create policy modules_select_authorized on public.modules for select to authenticated using (
  exists (select 1 from public.organization_modules om where om.module_id = modules.id and public.is_active_member(om.organization_id))
);
create policy organization_modules_select_member on public.organization_modules for select to authenticated using (public.is_active_member(organization_id));
create policy organization_modules_insert_admin on public.organization_modules for insert to authenticated with check (public.is_organization_admin(organization_id));
create policy organization_modules_update_admin on public.organization_modules for update to authenticated using (public.is_organization_admin(organization_id)) with check (public.is_organization_admin(organization_id));
create policy organization_modules_delete_admin on public.organization_modules for delete to authenticated using (public.is_organization_admin(organization_id));
create policy module_roles_select_member on public.module_roles for select to authenticated using (
  exists (select 1 from public.organization_modules om where om.module_id = module_roles.module_id and public.is_active_member(om.organization_id))
);
create policy module_permissions_select_member on public.module_permissions for select to authenticated using (
  exists (select 1 from public.organization_modules om where om.module_id = module_permissions.module_id and public.is_active_member(om.organization_id))
);
create policy role_permissions_select_member on public.role_permissions for select to authenticated using (
  exists (
    select 1 from public.module_roles mr
    join public.organization_modules om on om.module_id = mr.module_id
    where mr.id = role_permissions.module_role_id
      and public.is_active_member(om.organization_id)
  )
);
create policy user_module_roles_select_own_or_admin on public.user_module_roles for select to authenticated using (
  user_id = auth.uid() or exists (
    select 1 from public.organization_modules om
    where om.id = user_module_roles.organization_module_id
      and public.is_organization_admin(om.organization_id)
  )
);
create policy user_module_roles_insert_admin on public.user_module_roles for insert to authenticated with check (
  exists (select 1 from public.organization_modules om where om.id = user_module_roles.organization_module_id and public.is_organization_admin(om.organization_id))
);
create policy user_module_roles_update_admin on public.user_module_roles for update to authenticated using (
  exists (select 1 from public.organization_modules om where om.id = user_module_roles.organization_module_id and public.is_organization_admin(om.organization_id))
) with check (
  exists (select 1 from public.organization_modules om where om.id = user_module_roles.organization_module_id and public.is_organization_admin(om.organization_id))
);
create policy user_module_roles_delete_admin on public.user_module_roles for delete to authenticated using (
  exists (select 1 from public.organization_modules om where om.id = user_module_roles.organization_module_id and public.is_organization_admin(om.organization_id))
);

revoke all on table public.modules, public.organization_modules, public.module_roles, public.module_permissions, public.role_permissions, public.user_module_roles from anon;
grant select on table public.modules, public.module_roles, public.module_permissions, public.role_permissions to authenticated;
grant select, insert, update, delete on table public.organization_modules, public.user_module_roles to authenticated;

revoke all on function public.has_module_access(uuid,text) from public;
revoke all on function public.has_module_permission(uuid,text,text) from public;
revoke all on function public.get_my_modules(uuid) from public;
grant execute on function public.has_module_access(uuid,text) to authenticated, service_role;
grant execute on function public.has_module_permission(uuid,text,text) to authenticated, service_role;
grant execute on function public.get_my_modules(uuid) to authenticated, service_role;

insert into public.modules (id, code, name, short_name, description, status, is_core, display_order, icon_name, route_path) values
('aaae1276-65bb-49cb-9efb-7f9e87a8bca8','SK-PE','Planejamento Estratégico','SK-PE','Gestão completa da jornada de planejamento estratégico.','active',false,10,'strategy','/modules/sk-pe'),
('86206ef1-3bfc-4c44-b48b-50adfd8a5126','SK-FIN','Gestão Financeira','SK-FIN','Planejamento, controle e monitoramento financeiro.','planned',false,20,'finance','/modules/sk-fin'),
('f63296f3-da0e-46d8-8a34-0852c3341599','SK-ASM','Gestão Assemblear','SK-ASM','Planejamento e gestão do processo assemblear.','planned',false,30,'assembly','/modules/sk-asm'),
('8ddc0929-fcde-45bf-abce-6da35a5d6115','SK-DOC','Gestão Documental','SK-DOC','Gestão documental e arquitetura normativa transversal.','planned',true,40,'documents','/modules/sk-doc'),
('09da5f1e-6b43-4392-b4e6-08c74c0c54f4','SK-DA','Diagnóstico Assistido','SK-DA','Avaliação de maturidade, diagnóstico e oportunidades de melhoria.','planned',false,50,'assessment','/modules/sk-da'),
('0f1f1b4d-c52a-43e3-8624-aa28178fa9ba','SK-PN','Plano de Negócios','SK-PN','Desenvolvimento, validação e gestão de planos de negócios.','planned',false,60,'business-plan','/modules/sk-pn')
on conflict (code) do update set name=excluded.name, short_name=excluded.short_name, description=excluded.description, status=excluded.status, is_core=excluded.is_core, display_order=excluded.display_order, icon_name=excluded.icon_name, route_path=excluded.route_path, updated_at=timezone('utc',now());

insert into public.module_roles (id,module_id,code,name,description,role_level,is_system_role,active) values
('40b8abc6-696a-4960-b93f-11a643423abe','aaae1276-65bb-49cb-9efb-7f9e87a8bca8','administrator','Administrador do SK-PE','Administra usuários, configurações e conteúdo do módulo.',100,true,true),
('da98dd04-ff64-4fc9-a881-ee1d727a837c','aaae1276-65bb-49cb-9efb-7f9e87a8bca8','manager','Gestor Estratégico','Gerencia e acompanha a jornada estratégica.',80,true,true),
('e372f49f-3e5f-41be-94cb-3de6423c2baa','aaae1276-65bb-49cb-9efb-7f9e87a8bca8','editor','Editor','Cria e edita conteúdos autorizados.',60,true,true),
('12f954b4-6976-46da-914d-75f2a4865f6d','aaae1276-65bb-49cb-9efb-7f9e87a8bca8','approver','Aprovador','Analisa e aprova conteúdos e entregas.',50,true,true),
('90e5322a-0586-4582-88f5-a3e57aa0c829','aaae1276-65bb-49cb-9efb-7f9e87a8bca8','viewer','Leitor','Consulta conteúdos autorizados sem editar.',10,true,true)
on conflict (module_id,code) do update set name=excluded.name, description=excluded.description, role_level=excluded.role_level, is_system_role=excluded.is_system_role, active=excluded.active, updated_at=timezone('utc',now());

insert into public.module_permissions (id,module_id,code,name,description,permission_group,active) values
('b521fa1a-36df-476c-984a-09300b35b61d','aaae1276-65bb-49cb-9efb-7f9e87a8bca8','content.approve','Aprovar conteúdos','Permite aprovar ou rejeitar entregas estratégicas.','content',true),
('582d3e27-5ca0-458b-838a-4ced4640aeb1','aaae1276-65bb-49cb-9efb-7f9e87a8bca8','content.create','Criar conteúdos','Permite criar conteúdos estratégicos.','content',true),
('9e9e3ac4-0c6c-462c-980c-4a8a8f51437e','aaae1276-65bb-49cb-9efb-7f9e87a8bca8','content.delete','Excluir conteúdos','Permite excluir conteúdos estratégicos conforme as regras aplicáveis.','content',true),
('87486079-9fe5-4047-90b8-a137e91a8d80','aaae1276-65bb-49cb-9efb-7f9e87a8bca8','content.edit','Editar conteúdos','Permite editar conteúdos estratégicos.','content',true),
('4d820ecc-c231-4452-a772-a89d149d5445','aaae1276-65bb-49cb-9efb-7f9e87a8bca8','content.view','Consultar conteúdos','Permite consultar conteúdos estratégicos.','content',true),
('8dd72671-12ae-4e2d-a768-25a6bf80e06f','aaae1276-65bb-49cb-9efb-7f9e87a8bca8','module.manage','Administrar o módulo','Permite administrar o SK-PE.','module',true),
('e2fdf29e-bb0d-4668-b527-12cbdac51fd3','aaae1276-65bb-49cb-9efb-7f9e87a8bca8','module.view','Acessar o módulo','Permite acessar o SK-PE.','module',true),
('ad1e1316-0a26-4266-918a-da800ae7fcd1','aaae1276-65bb-49cb-9efb-7f9e87a8bca8','reports.export','Exportar relatórios','Permite exportar relatórios e evidências.','reports',true),
('6e8793b9-2aaa-4284-b91e-173c51c83f7c','aaae1276-65bb-49cb-9efb-7f9e87a8bca8','reports.view','Consultar relatórios','Permite consultar relatórios e painéis.','reports',true),
('2abedad0-785b-430d-b7df-f25c704b17b1','aaae1276-65bb-49cb-9efb-7f9e87a8bca8','settings.manage','Administrar configurações','Permite alterar configurações do SK-PE.','settings',true),
('cc4886a1-95e9-4d90-bc3c-9a520d2fa0af','aaae1276-65bb-49cb-9efb-7f9e87a8bca8','users.manage','Administrar usuários','Permite conceder, alterar e revogar acessos.','users',true),
('6a4b17a2-e28e-43bb-8abb-dd613f1215a3','aaae1276-65bb-49cb-9efb-7f9e87a8bca8','users.view','Consultar usuários','Permite consultar usuários vinculados ao módulo.','users',true)
on conflict (module_id,code) do update set name=excluded.name, description=excluded.description, permission_group=excluded.permission_group, active=excluded.active, updated_at=timezone('utc',now());

with grants(role_code,permission_code) as (values
('administrator','content.approve'),('administrator','content.create'),('administrator','content.delete'),('administrator','content.edit'),('administrator','content.view'),('administrator','module.manage'),('administrator','module.view'),('administrator','reports.export'),('administrator','reports.view'),('administrator','settings.manage'),('administrator','users.manage'),('administrator','users.view'),
('manager','content.approve'),('manager','content.create'),('manager','content.edit'),('manager','content.view'),('manager','module.view'),('manager','reports.export'),('manager','reports.view'),('manager','users.view'),
('editor','content.create'),('editor','content.edit'),('editor','content.view'),('editor','module.view'),('editor','reports.view'),
('approver','content.approve'),('approver','content.view'),('approver','module.view'),('approver','reports.view'),
('viewer','content.view'),('viewer','module.view'),('viewer','reports.view'))
insert into public.role_permissions(module_role_id,module_permission_id)
select mr.id,mp.id from grants g
join public.module_roles mr on mr.module_id='aaae1276-65bb-49cb-9efb-7f9e87a8bca8' and mr.code=g.role_code
join public.module_permissions mp on mp.module_id='aaae1276-65bb-49cb-9efb-7f9e87a8bca8' and mp.code=g.permission_code
on conflict do nothing;

insert into public.organization_modules(organization_id,module_id,status,enabled,enabled_at,valid_from,configuration)
select o.id,m.id,'active',true,timezone('utc',now()),timezone('utc',now()),jsonb_build_object('initial_module',true,'implementation_stage','foundation')
from public.organizations o join public.modules m on m.code='SK-PE'
where o.code='COOTAQUARA'
on conflict (organization_id,module_id) do update set status=excluded.status, enabled=excluded.enabled, configuration=excluded.configuration, updated_at=timezone('utc',now());

insert into public.user_module_roles(organization_module_id,user_id,module_role_id,status,valid_from)
select om.id,p.id,mr.id,'active',timezone('utc',now())
from public.organization_modules om
join public.organizations o on o.id=om.organization_id
join public.modules m on m.id=om.module_id
join public.module_roles mr on mr.module_id=m.id and mr.code='administrator'
join public.profiles p on lower(p.email) in ('ricardo.rodrigues@sparkoop.com','rr.gestao@gmail.com')
where o.code='COOTAQUARA' and m.code='SK-PE'
on conflict (organization_module_id,user_id,module_role_id) do update set status='active', valid_until=null, updated_at=timezone('utc',now());
