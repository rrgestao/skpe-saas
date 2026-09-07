create table if not exists public.skpe_sparks_initiative_indicator_links (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  project_id uuid not null references public.skpe_projects(id) on delete cascade,
  formulation_id uuid not null references public.skpe_strategic_formulations(id) on delete cascade,
  sparks_initiative_id uuid not null,
  indicator_id uuid not null,
  relation_role text not null default 'success_measure',
  contribution_type text not null default 'supporting',
  attribution_mode text not null default 'contribution',
  validation_status text not null default 'draft',
  rationale text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id),
  constraint skpe_sparks_initiative_indicator_links_initiative_scope_fkey
    foreign key (sparks_initiative_id, organization_id)
    references public.sparks_initiatives(id, organization_id)
    on delete cascade,
  constraint skpe_sparks_initiative_indicator_links_indicator_scope_fkey
    foreign key (indicator_id, organization_id, project_id, formulation_id)
    references public.skpe_indicators(id, organization_id, project_id, formulation_id)
    on delete cascade,
  constraint skpe_sparks_initiative_indicator_links_role_check
    check (relation_role in ('success_measure', 'outcome_evidence', 'monitoring_context')),
  constraint skpe_sparks_initiative_indicator_links_contribution_check
    check (contribution_type in ('primary', 'secondary', 'supporting')),
  constraint skpe_sparks_initiative_indicator_links_attribution_check
    check (attribution_mode in ('contribution', 'correlation', 'causal')),
  constraint skpe_sparks_initiative_indicator_links_validation_check
    check (validation_status in ('draft', 'pending_validation', 'validated', 'rejected')),
  constraint skpe_sparks_initiative_indicator_links_unique
    unique (formulation_id, sparks_initiative_id, indicator_id, relation_role)
);

create index if not exists skpe_sparks_initiative_indicator_links_initiative_idx
  on public.skpe_sparks_initiative_indicator_links (organization_id, project_id, formulation_id, sparks_initiative_id);

create index if not exists skpe_sparks_initiative_indicator_links_indicator_idx
  on public.skpe_sparks_initiative_indicator_links (organization_id, project_id, formulation_id, indicator_id);

alter table public.skpe_sparks_initiative_indicator_links enable row level security;

drop policy if exists skpe_sparks_initiative_indicator_links_select on public.skpe_sparks_initiative_indicator_links;
create policy skpe_sparks_initiative_indicator_links_select
on public.skpe_sparks_initiative_indicator_links
for select
to authenticated
using (
  public.can_view_skpe_formulation(organization_id)
  or public.can_view_skpe_initiatives(organization_id)
);

drop policy if exists skpe_sparks_initiative_indicator_links_insert on public.skpe_sparks_initiative_indicator_links;
create policy skpe_sparks_initiative_indicator_links_insert
on public.skpe_sparks_initiative_indicator_links
for insert
to authenticated
with check (public.can_manage_skpe_formulation(organization_id));

drop policy if exists skpe_sparks_initiative_indicator_links_update on public.skpe_sparks_initiative_indicator_links;
create policy skpe_sparks_initiative_indicator_links_update
on public.skpe_sparks_initiative_indicator_links
for update
to authenticated
using (public.can_manage_skpe_formulation(organization_id))
with check (public.can_manage_skpe_formulation(organization_id));

drop policy if exists skpe_sparks_initiative_indicator_links_delete on public.skpe_sparks_initiative_indicator_links;
create policy skpe_sparks_initiative_indicator_links_delete
on public.skpe_sparks_initiative_indicator_links
for delete
to authenticated
using (public.can_manage_skpe_formulation(organization_id));

comment on table public.skpe_sparks_initiative_indicator_links is
'Contextual SK-PE many-to-many relation between canonical sparks_initiatives and skpe_indicators. It does not own initiative identity or indicator measurements.';

comment on column public.skpe_sparks_initiative_indicator_links.attribution_mode is
'Interpretation discipline for initiative-indicator association: contribution, correlation, or causal. Causal must only be used when institutionally justified; the schema does not infer causality.';