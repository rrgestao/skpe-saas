-- ============================================================
-- Plataforma SPARKs / SK-PE-CONT-01
-- 17-B.5F.3B.3C - Fundação canônica do vínculo SK-PE <-> Iniciativa
--
-- Decisões canônicas:
-- - sparks_initiatives é a identidade organizacional transversal.
-- - skpe_projects permanece o workspace metodológico especializado do SK-PE.
-- - O vínculo é explícito, 1:1 e protegido por escopo organizacional.
-- - Não há sincronização bidirecional de status, nome, código ou progresso.
-- - O backfill é materialização histórica, set-based e sem UUIDs hardcoded.
-- ============================================================

begin;

-- ============================================================
-- 1. IDENTIDADE DE ESCOPO EM skpe_projects
-- ============================================================

alter table public.skpe_projects
  add constraint skpe_projects_scope_identity
  unique (id, organization_id);

-- ============================================================
-- 2. BINDING ESPECIALIZADO 1:1
-- ============================================================

create table public.skpe_project_initiative_bindings (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete cascade,

  initiative_id uuid not null,

  skpe_project_id uuid not null,

  binding_type text not null
    default 'strategic_plan_implementation',

  created_at timestamptz not null
    default timezone('utc', now()),

  created_by uuid
    references public.profiles(id)
    on delete set null,

  constraint skpe_project_initiative_bindings_type_check
    check (
      binding_type in (
        'strategic_plan_implementation'
      )
    ),

  constraint skpe_project_initiative_bindings_initiative_unique
    unique (initiative_id),

  constraint skpe_project_initiative_bindings_project_unique
    unique (skpe_project_id),

  constraint skpe_project_initiative_bindings_initiative_scope_fkey
    foreign key (initiative_id, organization_id)
    references public.sparks_initiatives(id, organization_id)
    on delete restrict,

  constraint skpe_project_initiative_bindings_project_scope_fkey
    foreign key (skpe_project_id, organization_id)
    references public.skpe_projects(id, organization_id)
    on delete restrict
);

comment on table public.skpe_project_initiative_bindings is
  'Vínculo especializado 1:1 entre o projeto organizacional transversal da Plataforma SPARKs e o workspace metodológico correspondente do SK-PE.';

comment on column public.skpe_project_initiative_bindings.binding_type is
  'Tipo canônico do vínculo especializado entre iniciativa transversal e projeto SK-PE.';

create index idx_skpe_project_initiative_bindings_organization
  on public.skpe_project_initiative_bindings(organization_id);

-- ============================================================
-- 3. RLS E PRIVILÉGIOS
-- ============================================================

alter table public.skpe_project_initiative_bindings
  enable row level security;

create policy skpe_project_initiative_bindings_select_authorized
on public.skpe_project_initiative_bindings
for select
to authenticated
using (
  public.can_read_organization(organization_id)
);

revoke all
on table public.skpe_project_initiative_bindings
from anon;

revoke all
on table public.skpe_project_initiative_bindings
from authenticated;

grant select
on table public.skpe_project_initiative_bindings
to authenticated;

grant all
on table public.skpe_project_initiative_bindings
to service_role;

-- ============================================================
-- 4. GUARDA SEMÂNTICA
-- ============================================================

create or replace function public.validate_skpe_project_initiative_binding()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if not exists (
    select 1
    from public.sparks_initiatives si
    join public.sparks_domain_values dv
      on dv.id = si.category_id
    join public.sparks_domains d
      on d.id = dv.domain_id
    where si.id = new.initiative_id
      and si.organization_id = new.organization_id
      and si.initiative_class = 'project'
      and si.archived_at is null
      and dv.code = 'strategic'
      and dv.active
      and d.code = 'INITIATIVE_CATEGORY'
      and d.active
      and d.scope_type = 'global'
      and d.organization_id is null
      and d.module_code is null
  ) then
    raise exception
      'O vínculo SK-PE exige uma iniciativa ativa da classe Projeto e categoria Estratégica pertencente à mesma organização.'
      using errcode = '22023';
  end if;

  return new;
end;
$$;

revoke all
on function public.validate_skpe_project_initiative_binding()
from public;

revoke all
on function public.validate_skpe_project_initiative_binding()
from anon;

revoke all
on function public.validate_skpe_project_initiative_binding()
from authenticated;

create trigger skpe_project_initiative_bindings_validate_semantics
before insert or update of
  organization_id,
  initiative_id,
  skpe_project_id
on public.skpe_project_initiative_bindings
for each row
execute function public.validate_skpe_project_initiative_binding();

-- ============================================================
-- 5. PRECONDIÇÕES BLOQUEANTES DO BACKFILL
-- ============================================================

do $$
declare
  strategic_category_count integer;
  collision_count integer;
begin
  select count(*)
    into strategic_category_count
  from public.sparks_domain_values dv
  join public.sparks_domains d
    on d.id = dv.domain_id
  where d.code = 'INITIATIVE_CATEGORY'
    and d.scope_type = 'global'
    and d.organization_id is null
    and d.module_code is null
    and d.active
    and dv.code = 'strategic'
    and dv.active;

  if strategic_category_count <> 1 then
    raise exception
      'Backfill bloqueado: esperado exatamente 1 valor ativo strategic no domínio INITIATIVE_CATEGORY; encontrados %.',
      strategic_category_count
      using errcode = '22023';
  end if;

  select count(*)
    into collision_count
  from public.skpe_projects p
  where not exists (
    select 1
    from public.skpe_project_initiative_bindings b
    where b.skpe_project_id = p.id
  )
  and exists (
    select 1
    from public.sparks_initiatives si
    where si.organization_id = p.organization_id
      and si.code = p.code
  );

  if collision_count > 0 then
    raise exception
      'Backfill bloqueado: existe iniciativa transversal com o mesmo código de projeto SK-PE ainda não vinculado.'
      using errcode = '23505';
  end if;
end;
$$;

-- ============================================================
-- 6. MATERIALIZAÇÃO HISTÓRICA GOVERNADA
-- ============================================================

with strategic_category as (
  select dv.id
  from public.sparks_domain_values dv
  join public.sparks_domains d
    on d.id = dv.domain_id
  where d.code = 'INITIATIVE_CATEGORY'
    and d.scope_type = 'global'
    and d.organization_id is null
    and d.module_code is null
    and d.active
    and dv.code = 'strategic'
    and dv.active
  limit 1
),
unbound_projects as (
  select p.*
  from public.skpe_projects p
  where not exists (
    select 1
    from public.skpe_project_initiative_bindings b
    where b.skpe_project_id = p.id
  )
),
materialized as (
  insert into public.sparks_initiatives (
    organization_id,
    category_id,
    code,
    name,
    description,
    initiative_class,
    status,
    proposal_origin,
    source_module_code,
    proposal_source_reference,
    validation_status,
    start_date,
    target_end_date,
    progress,
    metadata,
    created_at,
    created_by,
    updated_at,
    updated_by
  )
  select
    p.organization_id,
    sc.id,
    p.code,
    p.name,
    p.description,
    'project',

    case p.status
      when 'draft'     then 'proposed'
      when 'active'    then 'in_progress'
      when 'suspended' then 'on_hold'
      when 'completed' then 'completed'
      when 'archived'  then 'archived'
      else 'proposed'
    end,

    'legacy',
    'SK-PE',
    'skpe_projects:' || p.id::text,
    'not_required',

    p.start_date,
    p.target_end_date,
    p.progress,

    jsonb_build_object(
      'materialization_gate', '17-B.5F.3B.3B',
      'legacy_source', 'skpe_projects',
      'legacy_project_id', p.id,
      'legacy_project_code', p.code,
      'legacy_project_name', p.name,
      'legacy_project_status', p.status,
      'specialization', 'SK-PE',
      'binding_type', 'strategic_plan_implementation'
    ),

    timezone('utc', now()),
    p.created_by,
    timezone('utc', now()),
    p.updated_by

  from unbound_projects p
  cross join strategic_category sc

  returning
    id,
    organization_id,
    proposal_source_reference
)
insert into public.skpe_project_initiative_bindings (
  organization_id,
  initiative_id,
  skpe_project_id,
  binding_type,
  created_by
)
select
  m.organization_id,
  m.id,
  p.id,
  'strategic_plan_implementation',
  p.created_by
from materialized m
join public.skpe_projects p
  on m.proposal_source_reference =
     'skpe_projects:' || p.id::text;

commit;
