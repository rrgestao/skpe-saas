create table if not exists public.skpe_indicator_reference_catalog (
  id uuid primary key default gen_random_uuid(),
  catalog_code text not null,
  version_number integer not null default 1,
  name text not null,
  description text,
  purpose text,
  formula_text text,
  unit text not null,
  polarity text not null,
  measurement_frequency text,
  indicator_category text,
  applicability jsonb not null default '{}'::jsonb,
  excellence_criteria jsonb not null default '[]'::jsonb,
  reference_sources jsonb not null default '[]'::jsonb,
  status text not null default 'draft',
  is_current boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid,
  constraint skpe_indicator_reference_catalog_code_version_uk unique (catalog_code, version_number),
  constraint skpe_indicator_reference_catalog_version_ck check (version_number > 0),
  constraint skpe_indicator_reference_catalog_polarity_ck check (polarity in ('higher_is_better','lower_is_better','target_is_better','range_is_better')),
  constraint skpe_indicator_reference_catalog_frequency_ck check (
    measurement_frequency is null or measurement_frequency in ('daily','weekly','monthly','bimonthly','quarterly','semiannual','annual','on_demand')
  ),
  constraint skpe_indicator_reference_catalog_category_ck check (
    indicator_category is null or indicator_category in ('financial','customer_market','internal_process','people_learning','governance','social','environmental','sustainability','other')
  ),
  constraint skpe_indicator_reference_catalog_status_ck check (status in ('draft','active','inactive','archived')),
  constraint skpe_indicator_reference_catalog_applicability_ck check (jsonb_typeof(applicability) = 'object'),
  constraint skpe_indicator_reference_catalog_excellence_ck check (jsonb_typeof(excellence_criteria) = 'array'),
  constraint skpe_indicator_reference_catalog_sources_ck check (jsonb_typeof(reference_sources) = 'array'),
  constraint skpe_indicator_reference_catalog_metadata_ck check (jsonb_typeof(metadata) = 'object')
);

create unique index if not exists skpe_indicator_reference_catalog_current_uk
  on public.skpe_indicator_reference_catalog (lower(catalog_code))
  where is_current = true and status <> 'archived';

create index if not exists skpe_indicator_reference_catalog_status_idx
  on public.skpe_indicator_reference_catalog (status, is_current);

create index if not exists skpe_indicator_reference_catalog_name_idx
  on public.skpe_indicator_reference_catalog (lower(name));

create table if not exists public.skpe_indicator_reference_benchmarks (
  id uuid primary key default gen_random_uuid(),
  reference_indicator_id uuid not null references public.skpe_indicator_reference_catalog(id) on delete restrict,
  benchmark_type text not null,
  source_name text not null,
  source_reference text,
  reference_period text,
  population_context text,
  benchmark_value numeric,
  lower_bound numeric,
  upper_bound numeric,
  applicability text,
  comparability_notes text,
  confidence_level text,
  verified_at timestamptz,
  verified_by uuid,
  status text not null default 'draft',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid,
  constraint skpe_indicator_reference_benchmark_type_ck check (benchmark_type in ('internal','sector','market','best_practice','regulatory')),
  constraint skpe_indicator_reference_benchmark_confidence_ck check (confidence_level is null or confidence_level in ('low','medium','high')),
  constraint skpe_indicator_reference_benchmark_status_ck check (status in ('draft','active','inactive','archived')),
  constraint skpe_indicator_reference_benchmark_value_ck check (
    benchmark_value is not null or lower_bound is not null or upper_bound is not null
  ),
  constraint skpe_indicator_reference_benchmark_range_ck check (
    lower_bound is null or upper_bound is null or lower_bound <= upper_bound
  ),
  constraint skpe_indicator_reference_benchmark_metadata_ck check (jsonb_typeof(metadata) = 'object')
);

create index if not exists skpe_indicator_reference_benchmarks_indicator_idx
  on public.skpe_indicator_reference_benchmarks (reference_indicator_id, status);

create index if not exists skpe_indicator_reference_benchmarks_source_idx
  on public.skpe_indicator_reference_benchmarks (lower(source_name));

alter table public.skpe_indicators
  add column if not exists reference_catalog_id uuid references public.skpe_indicator_reference_catalog(id) on delete set null,
  add column if not exists reference_adaptation_notes text;

create index if not exists skpe_indicators_reference_catalog_idx
  on public.skpe_indicators (reference_catalog_id)
  where reference_catalog_id is not null;

drop trigger if exists skpe_indicator_reference_catalog_set_updated_at on public.skpe_indicator_reference_catalog;
create trigger skpe_indicator_reference_catalog_set_updated_at
before update on public.skpe_indicator_reference_catalog
for each row execute function public.set_updated_at();

drop trigger if exists skpe_indicator_reference_benchmarks_set_updated_at on public.skpe_indicator_reference_benchmarks;
create trigger skpe_indicator_reference_benchmarks_set_updated_at
before update on public.skpe_indicator_reference_benchmarks
for each row execute function public.set_updated_at();

alter table public.skpe_indicator_reference_catalog enable row level security;
alter table public.skpe_indicator_reference_benchmarks enable row level security;

drop policy if exists skpe_indicator_reference_catalog_select on public.skpe_indicator_reference_catalog;
create policy skpe_indicator_reference_catalog_select
on public.skpe_indicator_reference_catalog
for select
to authenticated
using (status = 'active' and is_current = true);

drop policy if exists skpe_indicator_reference_catalog_manage on public.skpe_indicator_reference_catalog;
create policy skpe_indicator_reference_catalog_manage
on public.skpe_indicator_reference_catalog
for all
to authenticated
using (public.is_platform_super_admin())
with check (public.is_platform_super_admin());

drop policy if exists skpe_indicator_reference_benchmarks_select on public.skpe_indicator_reference_benchmarks;
create policy skpe_indicator_reference_benchmarks_select
on public.skpe_indicator_reference_benchmarks
for select
to authenticated
using (
  status = 'active'
  and exists (
    select 1
    from public.skpe_indicator_reference_catalog catalog
    where catalog.id = reference_indicator_id
      and catalog.status = 'active'
      and catalog.is_current = true
  )
);

drop policy if exists skpe_indicator_reference_benchmarks_manage on public.skpe_indicator_reference_benchmarks;
create policy skpe_indicator_reference_benchmarks_manage
on public.skpe_indicator_reference_benchmarks
for all
to authenticated
using (public.is_platform_super_admin())
with check (public.is_platform_super_admin());

revoke all on table public.skpe_indicator_reference_catalog from anon;
revoke all on table public.skpe_indicator_reference_benchmarks from anon;
grant select, insert, update, delete on table public.skpe_indicator_reference_catalog to authenticated;
grant select, insert, update, delete on table public.skpe_indicator_reference_benchmarks to authenticated;
