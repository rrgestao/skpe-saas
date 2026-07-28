begin;

-- Fundação de Importação, Exportação e Portabilidade da Plataforma SPARKs.
-- Esta migration cria somente a infraestrutura de governança, versionamento,
-- preparação e auditoria. Não importa nem exporta dados automaticamente.

create table if not exists public.sparks_portability_layouts (
  id uuid primary key default gen_random_uuid(),
  module_code text not null,
  layout_code text not null,
  layout_name text not null,
  layout_version text not null,
  file_type text not null check (file_type in ('xlsx','html','json','zip')),
  direction text not null check (direction in ('import','export','both')),
  description text,
  minimum_platform_version text,
  schema_definition jsonb not null default '{}'::jsonb,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id),
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id),
  unique (module_code, layout_code, layout_version, file_type)
);

create table if not exists public.sparks_portability_packages (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id),
  project_id uuid,
  module_code text not null,
  package_code text not null unique,
  package_type text not null check (package_type in (
    'empty_template','complete_project','current_phase','phase_closure',
    'execution_monitoring','portable_portal','portable_backup',
    'network_consolidated','anonymized','import_package'
  )),
  direction text not null check (direction in ('import','export')),
  status text not null default 'draft' check (status in (
    'draft','preparing','validating','ready','processing','completed',
    'completed_with_warnings','failed','cancelled','archived'
  )),
  layout_id uuid references public.sparks_portability_layouts(id),
  layout_version text,
  source_environment text,
  source_system text,
  file_name text,
  storage_bucket text,
  storage_path text,
  manifest jsonb not null default '{}'::jsonb,
  record_counts jsonb not null default '{}'::jsonb,
  integrity_hash text,
  confidentiality_level smallint not null default 1,
  requested_at timestamptz not null default now(),
  requested_by uuid references auth.users(id),
  started_at timestamptz,
  completed_at timestamptz,
  error_message text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id),
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id)
);

create table if not exists public.sparks_portability_package_items (
  id uuid primary key default gen_random_uuid(),
  package_id uuid not null references public.sparks_portability_packages(id) on delete cascade,
  object_type text not null,
  object_code text,
  external_id text,
  source_object_id uuid,
  target_object_id uuid,
  item_status text not null default 'pending' check (item_status in (
    'pending','new','unchanged','update_available','conflict','duplicate',
    'missing_reference','invalid','blocked_other_organization','incompatible',
    'accepted','rejected','imported','exported','failed'
  )),
  severity text not null default 'info' check (severity in ('info','warning','error','critical')),
  source_data jsonb not null default '{}'::jsonb,
  target_data jsonb not null default '{}'::jsonb,
  differences jsonb not null default '{}'::jsonb,
  validation_messages jsonb not null default '[]'::jsonb,
  resolution_action text,
  resolved_at timestamptz,
  resolved_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.sparks_portability_jobs (
  id uuid primary key default gen_random_uuid(),
  package_id uuid not null references public.sparks_portability_packages(id) on delete cascade,
  job_type text not null check (job_type in ('validate','prepare_export','generate_files','stage_import','apply_import','rollback_import')),
  status text not null default 'queued' check (status in ('queued','running','completed','completed_with_warnings','failed','cancelled')),
  progress_percentage numeric(5,2) not null default 0 check (progress_percentage between 0 and 100),
  current_step text,
  result_summary jsonb not null default '{}'::jsonb,
  error_details jsonb not null default '{}'::jsonb,
  queued_at timestamptz not null default now(),
  started_at timestamptz,
  completed_at timestamptz,
  executed_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists public.sparks_portability_audit (
  id uuid primary key default gen_random_uuid(),
  package_id uuid references public.sparks_portability_packages(id) on delete cascade,
  organization_id uuid references public.organizations(id),
  actor_user_id uuid references auth.users(id),
  action_code text not null,
  action_description text,
  previous_data jsonb,
  new_data jsonb,
  metadata jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null default now()
);

create index if not exists idx_sparks_portability_packages_org on public.sparks_portability_packages(organization_id, created_at desc);
create index if not exists idx_sparks_portability_packages_status on public.sparks_portability_packages(status, direction);
create index if not exists idx_sparks_portability_items_package_status on public.sparks_portability_package_items(package_id, item_status);
create index if not exists idx_sparks_portability_jobs_package on public.sparks_portability_jobs(package_id, created_at desc);

insert into public.sparks_portability_layouts (
  module_code, layout_code, layout_name, layout_version, file_type, direction, description, schema_definition, active
) values
  ('SK-PE','SPARKS_PE_CANONICAL_XLSX','Planilha Canônica de Gestão Estratégica','1.0.0','xlsx','both','Planilha estruturada para operação offline, exportação e importação controlada do Planejamento Estratégico.', jsonb_build_object('scope','complete_project','language','pt-BR'), true),
  ('SK-PE','SPARKS_PE_PORTABLE_HTML','Portal Estratégico Portátil','1.0.0','html','export','Portal HTML somente leitura para acompanhamento executivo offline.', jsonb_build_object('scope','executive_portal','read_only',true,'language','pt-BR'), true),
  ('SK-PE','SPARKS_PE_PACKAGE','Pacote Estratégico Portável SPARKs','1.0.0','zip','both','Pacote versionado contendo manifesto, dados estruturados, planilha, portal HTML, documentos e relatório de validação.', jsonb_build_object('manifest_required',true,'hash_required',true,'language','pt-BR'), true),
  ('SK-PE','SPARKS_PE_STRUCTURED_JSON','Dados Estruturados do Planejamento Estratégico','1.0.0','json','both','Representação estruturada e rastreável dos dados da jornada estratégica.', jsonb_build_object('scope','structured_data','language','pt-BR'), true)
on conflict (module_code, layout_code, layout_version, file_type) do update
set layout_name = excluded.layout_name,
    direction = excluded.direction,
    description = excluded.description,
    schema_definition = excluded.schema_definition,
    active = true,
    updated_at = now();

create or replace function public.create_portability_package(
  target_organization_id uuid,
  target_project_id uuid,
  target_module_code text,
  target_package_type text,
  target_direction text,
  target_layout_code text,
  target_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_layout_id uuid;
  v_layout_version text;
  v_package_id uuid;
  v_package_code text;
begin
  if target_organization_id is null then
    raise exception 'A organização é obrigatória.';
  end if;

  if target_direction not in ('import','export') then
    raise exception 'Direção inválida.';
  end if;

  if not (
    public.is_platform_super_admin()
    or public.can_manage_skpe_governance(target_organization_id)
  ) then
    raise exception 'Acesso negado para criar pacote de portabilidade.' using errcode = '42501';
  end if;

  select id, layout_version
    into v_layout_id, v_layout_version
  from public.sparks_portability_layouts
  where module_code = target_module_code
    and layout_code = target_layout_code
    and active = true
    and direction in (target_direction, 'both')
  order by created_at desc
  limit 1;

  if v_layout_id is null then
    raise exception 'Leiaute ativo não encontrado para o módulo e direção informados.';
  end if;

  v_package_code := concat(
    'PKG-', upper(target_module_code), '-',
    to_char(clock_timestamp(), 'YYYYMMDDHH24MISSMS'), '-',
    upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6))
  );

  insert into public.sparks_portability_packages (
    organization_id, project_id, module_code, package_code, package_type,
    direction, status, layout_id, layout_version, source_environment,
    source_system, requested_by, created_by, metadata
  ) values (
    target_organization_id, target_project_id, target_module_code, v_package_code,
    target_package_type, target_direction, 'draft', v_layout_id, v_layout_version,
    'SPARKs SaaS', 'Plataforma SPARKs', auth.uid(), auth.uid(),
    jsonb_build_object('reason', target_reason)
  ) returning id into v_package_id;

  insert into public.sparks_portability_audit (
    package_id, organization_id, actor_user_id, action_code, action_description, new_data
  ) values (
    v_package_id, target_organization_id, auth.uid(), 'PACKAGE_CREATED',
    'Pacote de portabilidade criado.',
    jsonb_build_object('package_code', v_package_code, 'direction', target_direction, 'package_type', target_package_type)
  );

  return v_package_id;
end;
$$;

create or replace function public.get_portability_packages(
  target_organization_id uuid default null,
  target_direction text default null,
  target_status text default null
)
returns table (
  package_id uuid,
  organization_id uuid,
  organization_name text,
  project_id uuid,
  module_code text,
  package_code text,
  package_type text,
  direction text,
  status text,
  layout_name text,
  layout_version text,
  file_name text,
  requested_at timestamptz,
  requested_by uuid,
  completed_at timestamptz,
  error_message text,
  record_counts jsonb
)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  select
    p.id,
    p.organization_id,
    coalesce(o.trade_name, o.legal_name, o.code),
    p.project_id,
    p.module_code,
    p.package_code,
    p.package_type,
    p.direction,
    p.status,
    l.layout_name,
    p.layout_version,
    p.file_name,
    p.requested_at,
    p.requested_by,
    p.completed_at,
    p.error_message,
    p.record_counts
  from public.sparks_portability_packages p
  join public.organizations o on o.id = p.organization_id
  left join public.sparks_portability_layouts l on l.id = p.layout_id
  where (target_organization_id is null or p.organization_id = target_organization_id)
    and (target_direction is null or p.direction = target_direction)
    and (target_status is null or p.status = target_status)
    and (
      public.is_platform_super_admin()
      or public.can_view_skpe_governance(p.organization_id)
    )
  order by p.requested_at desc;
end;
$$;

alter table public.sparks_portability_layouts enable row level security;
alter table public.sparks_portability_packages enable row level security;
alter table public.sparks_portability_package_items enable row level security;
alter table public.sparks_portability_jobs enable row level security;
alter table public.sparks_portability_audit enable row level security;

-- Acesso direto às tabelas permanece restrito. A aplicação deve usar funções controladas.
revoke all on public.sparks_portability_layouts from anon, authenticated;
revoke all on public.sparks_portability_packages from anon, authenticated;
revoke all on public.sparks_portability_package_items from anon, authenticated;
revoke all on public.sparks_portability_jobs from anon, authenticated;
revoke all on public.sparks_portability_audit from anon, authenticated;

grant execute on function public.create_portability_package(uuid,uuid,text,text,text,text,text) to authenticated, service_role;
grant execute on function public.get_portability_packages(uuid,text,text) to authenticated, service_role;

commit;

select
  (select count(*) from public.sparks_portability_layouts where active = true) as layouts_ativos,
  (select count(*) from public.sparks_portability_packages) as pacotes_cadastrados,
  (select count(*) from public.sparks_portability_jobs) as jobs_cadastrados;
