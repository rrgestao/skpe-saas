begin;

create table if not exists public.skpe_sparks_initiative_strategic_links (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  project_id uuid not null references public.skpe_projects(id) on delete cascade,
  formulation_id uuid not null references public.skpe_strategic_formulations(id) on delete cascade,
  sparks_initiative_id uuid not null references public.sparks_initiatives(id) on delete cascade,
  strategic_objective_id uuid references public.skpe_strategic_objectives(id) on delete cascade,
  key_result_id uuid references public.skpe_key_results(id) on delete cascade,
  contribution_type text not null default 'primary',
  contribution_weight numeric,
  validation_status text not null default 'draft',
  notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id),
  constraint skpe_sparks_initiative_strategic_links_target_check check (
    (strategic_objective_id is not null and key_result_id is null)
    or (strategic_objective_id is null and key_result_id is not null)
  ),
  constraint skpe_sparks_initiative_strategic_links_contribution_type_check check (
    contribution_type in ('primary', 'secondary', 'supporting')
  ),
  constraint skpe_sparks_initiative_strategic_links_weight_check check (
    contribution_weight is null or (contribution_weight >= 0 and contribution_weight <= 100)
  ),
  constraint skpe_sparks_initiative_strategic_links_validation_status_check check (
    validation_status in ('draft', 'pending_validation', 'validated', 'validated_with_adjustments', 'rejected')
  )
);

create unique index if not exists skpe_sparks_initiative_strategic_links_objective_uidx
  on public.skpe_sparks_initiative_strategic_links (
    formulation_id, sparks_initiative_id, strategic_objective_id
  )
  where strategic_objective_id is not null;

create unique index if not exists skpe_sparks_initiative_strategic_links_key_result_uidx
  on public.skpe_sparks_initiative_strategic_links (
    formulation_id, sparks_initiative_id, key_result_id
  )
  where key_result_id is not null;

create index if not exists skpe_sparks_initiative_strategic_links_project_idx
  on public.skpe_sparks_initiative_strategic_links (organization_id, project_id, formulation_id);

create index if not exists skpe_sparks_initiative_strategic_links_initiative_idx
  on public.skpe_sparks_initiative_strategic_links (sparks_initiative_id);

alter table public.skpe_sparks_initiative_strategic_links enable row level security;

revoke all on table public.skpe_sparks_initiative_strategic_links from public, anon;
grant select, insert, update, delete on table public.skpe_sparks_initiative_strategic_links to authenticated, service_role;

drop policy if exists skpe_sparks_initiative_strategic_links_select on public.skpe_sparks_initiative_strategic_links;
create policy skpe_sparks_initiative_strategic_links_select
on public.skpe_sparks_initiative_strategic_links
for select
to authenticated
using (
  public.can_view_skpe_formulation(organization_id)
  or public.can_view_skpe_initiatives(organization_id)
);

drop policy if exists skpe_sparks_initiative_strategic_links_insert on public.skpe_sparks_initiative_strategic_links;
create policy skpe_sparks_initiative_strategic_links_insert
on public.skpe_sparks_initiative_strategic_links
for insert
to authenticated
with check (
  public.can_manage_skpe_formulation(organization_id)
);

drop policy if exists skpe_sparks_initiative_strategic_links_update on public.skpe_sparks_initiative_strategic_links;
create policy skpe_sparks_initiative_strategic_links_update
on public.skpe_sparks_initiative_strategic_links
for update
to authenticated
using (
  public.can_manage_skpe_formulation(organization_id)
)
with check (
  public.can_manage_skpe_formulation(organization_id)
);

drop policy if exists skpe_sparks_initiative_strategic_links_delete on public.skpe_sparks_initiative_strategic_links;
create policy skpe_sparks_initiative_strategic_links_delete
on public.skpe_sparks_initiative_strategic_links
for delete
to authenticated
using (
  public.can_manage_skpe_formulation(organization_id)
);

comment on table public.skpe_sparks_initiative_strategic_links is
  'Vinculo especializado SK-PE entre a identidade transversal canonica de Iniciativa em sparks_initiatives e Objetivos Estrategicos ou Resultados-Chave da Formulacao. Nao duplica a Iniciativa.';

comment on column public.skpe_sparks_initiative_strategic_links.sparks_initiative_id is
  'Identidade canonica da Iniciativa na Plataforma SPARKs.';

comment on column public.skpe_sparks_initiative_strategic_links.contribution_type is
  'Papel da contribuicao estrategica: primary, secondary ou supporting.';

commit;
