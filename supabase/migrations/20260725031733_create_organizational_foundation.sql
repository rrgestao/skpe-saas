-- ============================================================
-- SK-PE SaaS
-- Migration: Fundação Organizacional
-- ============================================================

create extension if not exists "pgcrypto";

-- ============================================================
-- TIPOS
-- ============================================================

create type public.organization_status as enum (
  'draft',
  'active',
  'suspended',
  'inactive',
  'archived'
);

create type public.organization_level as enum (
  'singular',
  'federation_central',
  'confederation',
  'system_guardian'
);

create type public.organization_relationship_type as enum (
  'affiliation',
  'representation',
  'coordination',
  'supervision',
  'partnership',
  'service_provision',
  'other'
);

create type public.membership_status as enum (
  'invited',
  'active',
  'suspended',
  'revoked'
);

-- ============================================================
-- FUNÇÃO PADRÃO DE ATUALIZAÇÃO
-- ============================================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

-- ============================================================
-- ECOSSISTEMAS
-- ============================================================

create table public.ecosystems (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  name text not null,
  description text,
  status public.organization_status not null default 'active',
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references auth.users(id),
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references auth.users(id),
  archived_at timestamptz,

  constraint ecosystems_code_unique unique (code),
  constraint ecosystems_code_not_blank check (length(trim(code)) > 0),
  constraint ecosystems_name_not_blank check (length(trim(name)) > 0)
);

create trigger ecosystems_set_updated_at
before update on public.ecosystems
for each row
execute function public.set_updated_at();

-- ============================================================
-- ORGANIZAÇÕES
-- ============================================================

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  ecosystem_id uuid references public.ecosystems(id),
  parent_organization_id uuid references public.organizations(id),
  code text not null,
  legal_name text not null,
  trade_name text,
  tax_identifier text,
  organization_level public.organization_level not null,
  external_classification_code text,
  status public.organization_status not null default 'draft',
  description text,
  email text,
  phone text,
  website text,
  country_code char(2) not null default 'BR',
  state_code char(2),
  city text,
  timezone_name text not null default 'America/Sao_Paulo',
  confidentiality_level smallint not null default 1,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references auth.users(id),
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references auth.users(id),
  archived_at timestamptz,

  constraint organizations_code_unique unique (code),
  constraint organizations_code_not_blank check (length(trim(code)) > 0),
  constraint organizations_legal_name_not_blank
    check (length(trim(legal_name)) > 0),
  constraint organizations_confidentiality_level_range
    check (confidentiality_level between 1 and 5),
  constraint organizations_not_own_parent
    check (parent_organization_id is null or parent_organization_id <> id)
);

create index organizations_ecosystem_id_idx
  on public.organizations(ecosystem_id);

create index organizations_parent_organization_id_idx
  on public.organizations(parent_organization_id);

create index organizations_status_idx
  on public.organizations(status);

create index organizations_level_idx
  on public.organizations(organization_level);

create trigger organizations_set_updated_at
before update on public.organizations
for each row
execute function public.set_updated_at();

-- ============================================================
-- RELACIONAMENTOS INSTITUCIONAIS
-- ============================================================

create table public.organization_relationships (
  id uuid primary key default gen_random_uuid(),
  source_organization_id uuid not null
    references public.organizations(id) on delete restrict,
  target_organization_id uuid not null
    references public.organizations(id) on delete restrict,
  relationship_type public.organization_relationship_type not null,
  description text,
  valid_from date,
  valid_until date,
  active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references auth.users(id),
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references auth.users(id),

  constraint organization_relationships_distinct_organizations
    check (source_organization_id <> target_organization_id),

  constraint organization_relationships_valid_period
    check (
      valid_until is null
      or valid_from is null
      or valid_until >= valid_from
    ),

  constraint organization_relationships_unique
    unique (
      source_organization_id,
      target_organization_id,
      relationship_type
    )
);

create index organization_relationships_source_idx
  on public.organization_relationships(source_organization_id);

create index organization_relationships_target_idx
  on public.organization_relationships(target_organization_id);

create trigger organization_relationships_set_updated_at
before update on public.organization_relationships
for each row
execute function public.set_updated_at();

-- ============================================================
-- PERFIS DOS USUÁRIOS
-- ============================================================

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  display_name text,
  email text,
  phone text,
  avatar_url text,
  active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),

  constraint profiles_full_name_not_blank
    check (full_name is null or length(trim(full_name)) > 0)
);

create trigger profiles_set_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

-- ============================================================
-- VÍNCULOS ENTRE USUÁRIOS E ORGANIZAÇÕES
-- ============================================================

create table public.organization_memberships (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations(id) on delete restrict,
  user_id uuid not null
    references auth.users(id) on delete cascade,
  status public.membership_status not null default 'invited',
  is_organization_admin boolean not null default false,
  job_title text,
  valid_from timestamptz not null default timezone('utc', now()),
  valid_until timestamptz,
  invited_by uuid references auth.users(id),
  activated_at timestamptz,
  suspended_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references auth.users(id),
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references auth.users(id),

  constraint organization_memberships_unique
    unique (organization_id, user_id),

  constraint organization_memberships_valid_period
    check (valid_until is null or valid_until >= valid_from)
);

create index organization_memberships_organization_id_idx
  on public.organization_memberships(organization_id);

create index organization_memberships_user_id_idx
  on public.organization_memberships(user_id);

create index organization_memberships_status_idx
  on public.organization_memberships(status);

create trigger organization_memberships_set_updated_at
before update on public.organization_memberships
for each row
execute function public.set_updated_at();

-- ============================================================
-- CRIAÇÃO AUTOMÁTICA DO PERFIL
-- ============================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (
    id,
    full_name,
    display_name,
    email
  )
  values (
    new.id,
    new.raw_user_meta_data ->> 'full_name',
    coalesce(
      new.raw_user_meta_data ->> 'display_name',
      new.raw_user_meta_data ->> 'full_name'
    ),
    new.email
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();

-- ============================================================
-- RLS
-- Nesta migration, a RLS será ativada sem políticas públicas.
-- As políticas detalhadas serão criadas na migration seguinte.
-- ============================================================

alter table public.ecosystems enable row level security;
alter table public.organizations enable row level security;
alter table public.organization_relationships enable row level security;
alter table public.profiles enable row level security;
alter table public.organization_memberships enable row level security;

-- ============================================================
-- COMENTÁRIOS
-- ============================================================

comment on table public.ecosystems is
  'Agrupamentos institucionais e ecossistemas atendidos pelo SK-PE SaaS.';

comment on table public.organizations is
  'Organizações usuárias ou relacionadas à plataforma.';

comment on table public.organization_relationships is
  'Relacionamentos institucionais sem concessão automática de acesso.';

comment on table public.profiles is
  'Perfis complementares dos usuários autenticados.';

comment on table public.organization_memberships is
  'Vínculos explícitos entre usuários e organizações.';