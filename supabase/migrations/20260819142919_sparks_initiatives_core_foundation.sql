-- ============================================================
-- Plataforma SPARKs / SK-PE-CONT-01
-- 17-B.5F.3A - Fundacao Transversal de Gestao de Iniciativas
--
-- Decisoes canonicas:
-- - Iniciativa pertence a Organizacao.
-- - SK-PE pode vincular/especializar, mas nao possui a existencia da Iniciativa.
-- - Classe e distinta de Categoria/Natureza.
-- - Responsabilidades sao geridas pelo nucleo sparks_responsibility_assignments.
-- - Nenhum DML direto e concedido a authenticated nesta fundacao.
-- - O vinculo especializado com skpe_projects sera criado no 17-B.5F.3B.
-- ============================================================

begin;

insert into public.sparks_domains (
  code, name, description, scope_type, module_code, organization_id,
  allow_organization_extension, protected, active
)
values (
  'INITIATIVE_CATEGORY',
  'Categorias de iniciativas',
  'Natureza gerencial da iniciativa, independente de sua classe metodologica.',
  'global', null, null, true, true, true
)
on conflict do nothing;

with domain as (
  select id
  from public.sparks_domains
  where code = 'INITIATIVE_CATEGORY'
    and scope_type = 'global'
    and module_code is null
    and organization_id is null
)
insert into public.sparks_domain_values (
  domain_id, code, name, description, display_order, protected, active
)
select
  domain.id, value_data.code, value_data.name, value_data.description,
  value_data.display_order, true, true
from domain
cross join (values
  ('strategic', 'Estrategica', 'Iniciativa diretamente vinculada a escolhas e prioridades estrategicas da organizacao.', 10),
  ('operational', 'Operacional', 'Iniciativa de melhoria ou evolucao da operacao.', 20),
  ('process', 'Processo', 'Iniciativa associada a desenho, melhoria ou transformacao de processos.', 30),
  ('transformation', 'Transformacao', 'Iniciativa de transformacao organizacional, digital ou institucional.', 40),
  ('sustainability_esg', 'Sustentabilidade / ESG', 'Iniciativa relacionada a sustentabilidade, ESG, impacto ou materialidade.', 50),
  ('communication_marketing', 'Comunicacao / Marketing', 'Iniciativa de comunicacao, posicionamento, relacionamento ou marketing.', 60)
) as value_data(code, name, description, display_order)
on conflict (domain_id, code) do update
set name = excluded.name,
    description = excluded.description,
    display_order = excluded.display_order,
    active = true;

create table if not exists public.sparks_initiatives (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  parent_initiative_id uuid,
  category_id uuid not null references public.sparks_domain_values(id) on delete restrict,
  responsible_area_id uuid references public.sparks_domain_values(id) on delete set null,

  code text not null,
  name text not null,
  description text,
  initiative_class text not null default 'initiative',
  status text not null default 'proposed',
  priority text not null default 'medium',
  criticality text not null default 'medium',

  strategic_problem text,
  strategic_rationale text,
  strategic_theme text,
  constraints_text text,

  proposal_origin text not null default 'organization',
  source_module_code text,
  proposal_source_reference text,
  validation_status text not null default 'not_required',
  validation_notes text,
  validated_at timestamptz,
  validated_by uuid references public.profiles(id) on delete set null,

  what_text text,
  why_text text,
  where_text text,
  when_text text,
  who_text text,
  how_text text,
  how_much_text text,

  start_date date,
  target_end_date date,
  completed_at timestamptz,
  progress numeric(5,2) not null default 0,

  planned_cost numeric(18,2),
  actual_cost numeric(18,2),
  planned_benefit numeric(18,2),
  realized_benefit numeric(18,2),
  currency_code text not null default 'BRL',

  estimated_effort numeric(18,2),
  effort_unit text,
  resource_estimate text,
  estimate_confidence text not null default 'medium',

  risk_level text not null default 'not_assessed',
  health_status text not null default 'not_assessed',
  last_update_at timestamptz,

  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,
  archived_at timestamptz,
  archived_by uuid references public.profiles(id) on delete set null,

  constraint sparks_initiatives_code_not_blank check (length(trim(code)) > 0),
  constraint sparks_initiatives_name_not_blank check (length(trim(name)) > 0),
  constraint sparks_initiatives_class_check
    check (initiative_class in ('initiative', 'program', 'project', 'structuring_action')),
  constraint sparks_initiatives_status_check
    check (status in ('proposed','under_analysis','approved','planned','in_progress','on_hold','blocked','completed','cancelled','archived')),
  constraint sparks_initiatives_priority_check
    check (priority in ('low','medium','high','critical')),
  constraint sparks_initiatives_criticality_check
    check (criticality in ('low','medium','high','critical')),
  constraint sparks_initiatives_progress_check check (progress between 0 and 100),
  constraint sparks_initiatives_risk_check
    check (risk_level in ('not_assessed','low','medium','high','critical')),
  constraint sparks_initiatives_health_check
    check (health_status in ('not_assessed','on_track','attention','critical','completed')),
  constraint sparks_initiatives_costs_check
    check (
      coalesce(planned_cost,0) >= 0 and coalesce(actual_cost,0) >= 0
      and coalesce(planned_benefit,0) >= 0 and coalesce(realized_benefit,0) >= 0
    ),
  constraint sparks_initiatives_dates_check
    check (target_end_date is null or start_date is null or target_end_date >= start_date),
  constraint sparks_initiatives_currency_code_check check (currency_code ~ '^[A-Z]{3}$'),
  constraint sparks_initiatives_effort_check check (estimated_effort is null or estimated_effort >= 0),
  constraint sparks_initiatives_effort_unit_check
    check (effort_unit is null or effort_unit in ('hours','days','weeks','months','points','custom')),
  constraint sparks_initiatives_estimate_confidence_check
    check (estimate_confidence in ('low','medium','high')),
  constraint sparks_initiatives_proposal_origin_check
    check (proposal_origin in (
      'sparks_suggestion','organization','joint_construction','previous_plan',
      'assessment','action_plan','bmc_vpc','benchmark','module','import','integration','legacy'
    )),
  constraint sparks_initiatives_validation_status_check
    check (validation_status in (
      'pending_validation','under_review','validated','validated_with_adjustments',
      'rejected','replaced','not_required'
    )),
  constraint sparks_initiatives_source_module_not_blank
    check (source_module_code is null or length(trim(source_module_code)) > 0),
  constraint sparks_initiatives_scope_identity unique (id, organization_id),
  constraint sparks_initiatives_unique_code unique (organization_id, code),
  constraint sparks_initiatives_parent_scope_fkey
    foreign key (parent_initiative_id, organization_id)
    references public.sparks_initiatives(id, organization_id)
    on delete restrict
);

comment on table public.sparks_initiatives is
  'Nucleo organizacional transversal de Programas, Projetos, Iniciativas e Acoes Estruturantes da Plataforma SPARKs.';
comment on column public.sparks_initiatives.initiative_class is
  'Classe canonica e estrutural: program, project, initiative ou structuring_action.';
comment on column public.sparks_initiatives.category_id is
  'Categoria/Natureza extensivel pelo dominio global INITIATIVE_CATEGORY.';
comment on column public.sparks_initiatives.parent_initiative_id is
  'Hierarquia organizacional entre iniciativas; nao representa vinculo com Formulacao ou modulo especialista.';
comment on column public.sparks_initiatives.source_module_code is
  'Modulo que originou ou materializou a iniciativa; nao define sua propriedade existencial.';
comment on column public.sparks_initiatives.responsible_area_id is
  'Area organizacional de referencia. Responsabilidades pessoais usam sparks_responsibility_assignments.';
comment on column public.sparks_initiatives.start_date is
  'Inicio de alto nivel da iniciativa. Cronogramas detalhados permanecem em capacidades especializadas.';
comment on column public.sparks_initiatives.target_end_date is
  'Termino-alvo de alto nivel. Nao substitui baseline, rebaseline ou forecast de cronogramas especializados.';

create index if not exists idx_sparks_initiatives_portfolio
  on public.sparks_initiatives(organization_id, initiative_class, category_id, status, priority, criticality)
  where archived_at is null;
create index if not exists idx_sparks_initiatives_parent
  on public.sparks_initiatives(parent_initiative_id) where archived_at is null;
create index if not exists idx_sparks_initiatives_area
  on public.sparks_initiatives(organization_id, responsible_area_id) where archived_at is null;
create index if not exists idx_sparks_initiatives_origin_validation
  on public.sparks_initiatives(organization_id, source_module_code, proposal_origin, validation_status)
  where archived_at is null;

-- ============================================================
-- GUARDA SEMANTICA DE DOMINIOS TRANSVERSAIS
-- ============================================================
-- A FK para sparks_domain_values garante existÃªncia, mas nÃ£o o
-- domÃ­nio semÃ¢ntico correto. Esta guarda impede category_id de
-- apontar para taxonomia alheia e responsible_area_id de apontar
-- para Ã¡rea de outra organizaÃ§Ã£o ou domÃ­nio.

create or replace function public.sparks_validate_initiative_domain_scope()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if not exists (
    select 1
    from public.sparks_domain_values category_value
    join public.sparks_domains category_domain
      on category_domain.id = category_value.domain_id
    where category_value.id = new.category_id
      and category_value.active
      and category_domain.active
      and category_domain.code = 'INITIATIVE_CATEGORY'
      and (
        (
          category_domain.scope_type = 'global'
          and category_domain.organization_id is null
          and category_domain.module_code is null
        )
        or (
          category_domain.scope_type = 'organization'
          and category_domain.organization_id = new.organization_id
        )
      )
  ) then
    raise exception 'Categoria de iniciativa invÃ¡lida ou inativa para esta organizaÃ§Ã£o.'
      using errcode = '22023';
  end if;

  if new.responsible_area_id is not null and not exists (
    select 1
    from public.sparks_domain_values area_value
    join public.sparks_domains area_domain
      on area_domain.id = area_value.domain_id
    where area_value.id = new.responsible_area_id
      and area_value.active
      and area_domain.active
      and area_domain.scope_type = 'organization'
      and area_domain.organization_id = new.organization_id
      and area_domain.code = 'ORGANIZATIONAL_AREA'
  ) then
    raise exception 'Ãrea responsÃ¡vel invÃ¡lida ou inativa para esta organizaÃ§Ã£o.'
      using errcode = '22023';
  end if;

  return new;
end;
$$;

revoke all on function public.sparks_validate_initiative_domain_scope() from public;
revoke all on function public.sparks_validate_initiative_domain_scope() from anon;
revoke all on function public.sparks_validate_initiative_domain_scope() from authenticated;

create trigger sparks_initiatives_validate_domain_scope
before insert or update of organization_id, category_id, responsible_area_id
on public.sparks_initiatives
for each row
execute function public.sparks_validate_initiative_domain_scope();
create trigger sparks_initiatives_set_updated_at
before update on public.sparks_initiatives
for each row execute function public.set_updated_at();

alter table public.sparks_initiatives enable row level security;

drop policy if exists sparks_initiatives_select_member on public.sparks_initiatives;
create policy sparks_initiatives_select_member
on public.sparks_initiatives
for select to authenticated
using (public.can_read_organization(organization_id));

-- Sem DML direto para authenticated no 17-B.5F.3A.
-- Operacoes governadas serao introduzidas nos subgates seguintes.
revoke all on table public.sparks_initiatives from anon;
revoke all on table public.sparks_initiatives from authenticated;
grant select on table public.sparks_initiatives to authenticated;
grant all on table public.sparks_initiatives to service_role;

commit;