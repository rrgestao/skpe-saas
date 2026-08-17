create table public.skpe_strategic_horizon_proposals (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  project_id uuid not null references public.skpe_projects(id) on delete cascade,
  version_number integer not null,
  status text not null default 'draft',
  proposed_start_year integer not null,
  proposed_end_year integer not null,
  origin_type text not null default 'consultancy_suggestion',
  rationale text,
  source_reference text,
  supersedes_proposal_id uuid references public.skpe_strategic_horizon_proposals(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,
  constraint skpe_strategic_horizon_proposals_version_positive check (version_number > 0),
  constraint skpe_strategic_horizon_proposals_years_check check (proposed_end_year >= proposed_start_year),
  constraint skpe_strategic_horizon_proposals_status_check check (
    status = any (array['draft','proposed','under_review','approved','adjusted','rejected','superseded'])
  ),
  constraint skpe_strategic_horizon_proposals_origin_check check (
    origin_type = any (array['consultancy_suggestion','organization','diagnostic','historical_import','system'])
  ),
  constraint skpe_strategic_horizon_proposals_metadata_check check (jsonb_typeof(metadata) = 'object'),
  constraint skpe_strategic_horizon_proposals_unique_version unique (project_id, version_number)
);

create index idx_skpe_strategic_horizon_proposals_scope
  on public.skpe_strategic_horizon_proposals (organization_id, project_id, status, version_number desc);

create unique index ux_skpe_strategic_horizon_proposals_open
  on public.skpe_strategic_horizon_proposals (project_id)
  where status in ('draft','proposed','under_review','adjusted');

alter table public.skpe_strategic_horizon_proposals enable row level security;

create policy skpe_strategic_horizon_proposals_select
  on public.skpe_strategic_horizon_proposals
  for select
  to authenticated
  using (public.can_view_skpe_journey(organization_id));

revoke all on table public.skpe_strategic_horizon_proposals from anon, authenticated;
grant select on table public.skpe_strategic_horizon_proposals to authenticated;
grant all on table public.skpe_strategic_horizon_proposals to service_role;

create table public.skpe_strategic_horizons (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  project_id uuid not null references public.skpe_projects(id) on delete cascade,
  proposal_id uuid references public.skpe_strategic_horizon_proposals(id) on delete set null,
  version_number integer not null,
  horizon_start_year integer not null,
  horizon_end_year integer not null,
  valid_from date,
  valid_until date,
  governance_status text not null default 'approved',
  is_current boolean not null default false,
  decision_origin_type text not null default 'native_platform',
  decision_gate_id uuid references public.skpe_gate_decisions(id) on delete set null,
  source_reference text,
  regularization_status text not null default 'not_required',
  supersedes_horizon_id uuid references public.skpe_strategic_horizons(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  approved_at timestamptz,
  approved_by uuid references public.profiles(id) on delete set null,
  superseded_at timestamptz,
  superseded_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,
  constraint skpe_strategic_horizons_version_positive check (version_number > 0),
  constraint skpe_strategic_horizons_years_check check (horizon_end_year >= horizon_start_year),
  constraint skpe_strategic_horizons_dates_check check (
    valid_until is null or valid_from is null or valid_until >= valid_from
  ),
  constraint skpe_strategic_horizons_governance_status_check check (
    governance_status = any (array['approved','historical_recognized','superseded','closed'])
  ),
  constraint skpe_strategic_horizons_origin_check check (
    decision_origin_type = any (array['native_platform','imported_historical','migrated','system_generated'])
  ),
  constraint skpe_strategic_horizons_regularization_check check (
    regularization_status = any (array['not_required','pending_review','evidence_gap','regularized'])
  ),
  constraint skpe_strategic_horizons_metadata_check check (jsonb_typeof(metadata) = 'object'),
  constraint skpe_strategic_horizons_unique_version unique (project_id, version_number)
);

create index idx_skpe_strategic_horizons_scope
  on public.skpe_strategic_horizons (
    organization_id,
    project_id,
    governance_status,
    version_number desc
  );

create index idx_skpe_strategic_horizons_proposal
  on public.skpe_strategic_horizons (proposal_id)
  where proposal_id is not null;

create index idx_skpe_strategic_horizons_decision_gate
  on public.skpe_strategic_horizons (decision_gate_id)
  where decision_gate_id is not null;

create unique index ux_skpe_strategic_horizons_current
  on public.skpe_strategic_horizons (project_id)
  where is_current = true;

alter table public.skpe_strategic_horizons enable row level security;

create policy skpe_strategic_horizons_select
  on public.skpe_strategic_horizons
  for select
  to authenticated
  using (public.can_view_skpe_journey(organization_id));

revoke all on table public.skpe_strategic_horizons from anon, authenticated;
grant select on table public.skpe_strategic_horizons to authenticated;
grant all on table public.skpe_strategic_horizons to service_role;

insert into public.skpe_strategic_horizons (
  organization_id,
  project_id,
  version_number,
  horizon_start_year,
  horizon_end_year,
  valid_from,
  valid_until,
  governance_status,
  is_current,
  decision_origin_type,
  source_reference,
  regularization_status,
  metadata,
  created_at,
  updated_at
)
select
  p.organization_id,
  p.id,
  1,
  p.planning_horizon_start_year,
  p.planning_horizon_end_year,
  p.valid_from,
  p.valid_until,
  'historical_recognized',
  true,
  'migrated',
  'skpe_projects legacy horizon projection',
  'pending_review',
  jsonb_build_object(
    'migration_gate', '17-B.2',
    'source_table', 'skpe_projects',
    'source_project_code', p.code,
    'brownfield_preservation', true
  ),
  p.created_at,
  timezone('utc', now())
from public.skpe_projects p
where p.archived_at is null
  and p.planning_horizon_start_year is not null
  and p.planning_horizon_end_year is not null
  and p.planning_horizon_end_year >= p.planning_horizon_start_year
  and not exists (
    select 1
    from public.skpe_strategic_horizons h
    where h.project_id = p.id
  );
