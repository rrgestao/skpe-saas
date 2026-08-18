-- SK-PE-CONT-01
-- GATE-17-B.4C.4C — Evolution Cycles Canonical Foundation
--
-- Contrato canônico:
--
-- Strategic Horizon
--   -> Evolution Scenario (proposta / recomendação)
--      -> Evolution Scenario Cycles
--   -> Evolution Plan (trajetória institucional aprovada)
--      -> Evolution Cycles
--
-- Regras semânticas:
--
-- Strategic Period
--   != Governance Effective Period
--   != Execution Period
--   != Measurement / Reference Period
--
-- Ciclo de Evolução
--   != Ciclo de OKR
--   != Ciclo de Monitoramento
--   != Cronograma de Execução
--
-- A SPARKs pode recomendar uma trajetória.
-- A organização decide qual trajetória institucionalizar.


-- ============================================================
-- 01. IDENTIDADE DE ESCOPO DO HORIZONTE
-- ============================================================
--
-- A PK do Horizonte é id, mas as entidades deste domínio usam
-- FKs compostas para impedir drift de organization/project.
-- O índice abaixo habilita esse contrato sem alterar a PK.
-- ============================================================

create unique index if not exists
  ux_skpe_strategic_horizons_scope_identity
on public.skpe_strategic_horizons (
  id,
  organization_id,
  project_id
);


-- ============================================================
-- 02. EVOLUTION SCENARIOS
-- ============================================================
--
-- Representa a proposta completa de trajetória de evolução.
-- É o espaço de recomendação, elaboração, revisão e ajuste.
-- Não representa ainda uma decisão institucional.
-- ============================================================

create table public.skpe_evolution_scenarios (

  id uuid
    primary key
    default gen_random_uuid(),

  organization_id uuid
    not null
    references public.organizations(id)
    on delete cascade,

  project_id uuid
    not null
    references public.skpe_projects(id)
    on delete cascade,

  strategic_horizon_id uuid
    not null,

  version_number integer
    not null,

  status text
    not null
    default 'draft',

  title text
    not null,

  description text,

  strategic_rationale text,

  origin_type text
    not null,

  source_reference text,

  coverage_policy text
    not null
    default 'allow_gaps',

  supersedes_scenario_id uuid,

  metadata jsonb
    not null
    default '{}'::jsonb,

  created_at timestamptz
    not null
    default timezone('utc', now()),

  created_by uuid
    references public.profiles(id)
    on delete set null,

  updated_at timestamptz
    not null
    default timezone('utc', now()),

  updated_by uuid
    references public.profiles(id)
    on delete set null,

  constraint skpe_evolution_scenarios_version_positive
    check (
      version_number > 0
    ),

  constraint skpe_evolution_scenarios_title_not_blank
    check (
      length(trim(title)) > 0
    ),

  constraint skpe_evolution_scenarios_status_check
    check (
      status in (
        'draft',
        'proposed',
        'under_review',
        'adjusted',
        'deferred',
        'approved',
        'rejected',
        'superseded'
      )
    ),

  constraint skpe_evolution_scenarios_origin_check
    check (
      origin_type in (
        'consultancy_suggestion',
        'organization',
        'diagnostic',
        'historical_import',
        'system'
      )
    ),

  constraint skpe_evolution_scenarios_coverage_policy_check
    check (
      coverage_policy in (
        'allow_gaps',
        'require_continuous'
      )
    ),

  constraint skpe_evolution_scenarios_metadata_check
    check (
      jsonb_typeof(metadata) = 'object'
    ),

  constraint skpe_evolution_scenarios_unique_version
    unique (
      strategic_horizon_id,
      version_number
    ),

  constraint skpe_evolution_scenarios_scope_unique
    unique (
      id,
      strategic_horizon_id,
      organization_id,
      project_id
    ),

  constraint skpe_evolution_scenarios_horizon_fkey
    foreign key (
      strategic_horizon_id,
      organization_id,
      project_id
    )
    references public.skpe_strategic_horizons (
      id,
      organization_id,
      project_id
    )
    on delete cascade,

  constraint skpe_evolution_scenarios_supersedes_fkey
    foreign key (
      supersedes_scenario_id,
      strategic_horizon_id,
      organization_id,
      project_id
    )
    references public.skpe_evolution_scenarios (
      id,
      strategic_horizon_id,
      organization_id,
      project_id
    )
    on delete set null (
      supersedes_scenario_id
    )
);


create unique index
  ux_skpe_evolution_scenarios_open
on public.skpe_evolution_scenarios (
  strategic_horizon_id
)
where status in (
  'draft',
  'proposed',
  'under_review',
  'adjusted',
  'deferred'
);


create index
  idx_skpe_evolution_scenarios_scope
on public.skpe_evolution_scenarios (
  organization_id,
  project_id,
  strategic_horizon_id,
  status,
  version_number desc
);


-- ============================================================
-- 03. EVOLUTION SCENARIO CYCLES
-- ============================================================
--
-- Representa cada Ciclo de Evolução pertencente ao cenário.
--
-- period_start / period_end são exclusivamente Strategic Period.
--
-- NÃO representam:
-- - vigência institucional;
-- - execução;
-- - agenda;
-- - período de medição.
-- ============================================================

create table public.skpe_evolution_scenario_cycles (

  id uuid
    primary key
    default gen_random_uuid(),

  organization_id uuid
    not null
    references public.organizations(id)
    on delete cascade,

  project_id uuid
    not null
    references public.skpe_projects(id)
    on delete cascade,

  strategic_horizon_id uuid
    not null,

  scenario_id uuid
    not null,

  sequence_number integer
    not null,

  title text
    not null,

  description text,

  period_start date
    not null,

  period_end date
    not null,

  strategic_intent text,

  expected_outcome text,

  target_maturity jsonb
    not null
    default '{}'::jsonb,

  assumptions jsonb
    not null
    default '[]'::jsonb,

  entry_criteria jsonb
    not null
    default '[]'::jsonb,

  exit_criteria jsonb
    not null
    default '[]'::jsonb,

  strategic_focus jsonb
    not null
    default '[]'::jsonb,

  rationale text,

  metadata jsonb
    not null
    default '{}'::jsonb,

  created_at timestamptz
    not null
    default timezone('utc', now()),

  created_by uuid
    references public.profiles(id)
    on delete set null,

  updated_at timestamptz
    not null
    default timezone('utc', now()),

  updated_by uuid
    references public.profiles(id)
    on delete set null,

  constraint skpe_evolution_scenario_cycles_sequence_positive
    check (
      sequence_number > 0
    ),

  constraint skpe_evolution_scenario_cycles_title_not_blank
    check (
      length(trim(title)) > 0
    ),

  constraint skpe_evolution_scenario_cycles_dates_check
    check (
      period_end >= period_start
    ),

  constraint skpe_evolution_scenario_cycles_target_maturity_check
    check (
      jsonb_typeof(target_maturity) = 'object'
    ),

  constraint skpe_evolution_scenario_cycles_assumptions_check
    check (
      jsonb_typeof(assumptions) = 'array'
    ),

  constraint skpe_evolution_scenario_cycles_entry_criteria_check
    check (
      jsonb_typeof(entry_criteria) = 'array'
    ),

  constraint skpe_evolution_scenario_cycles_exit_criteria_check
    check (
      jsonb_typeof(exit_criteria) = 'array'
    ),

  constraint skpe_evolution_scenario_cycles_strategic_focus_check
    check (
      jsonb_typeof(strategic_focus) = 'array'
    ),

  constraint skpe_evolution_scenario_cycles_metadata_check
    check (
      jsonb_typeof(metadata) = 'object'
    ),

  constraint skpe_evolution_scenario_cycles_sequence_unique
    unique (
      scenario_id,
      sequence_number
    ),

  constraint skpe_evolution_scenario_cycles_identity_unique
    unique (
      id,
      strategic_horizon_id,
      organization_id,
      project_id
    ),

  constraint skpe_evolution_scenario_cycles_scope_unique
    unique (
      id,
      scenario_id,
      strategic_horizon_id,
      organization_id,
      project_id
    ),

  constraint skpe_evolution_scenario_cycles_scenario_fkey
    foreign key (
      scenario_id,
      strategic_horizon_id,
      organization_id,
      project_id
    )
    references public.skpe_evolution_scenarios (
      id,
      strategic_horizon_id,
      organization_id,
      project_id
    )
    on delete cascade
);


create index
  idx_skpe_evolution_scenario_cycles_period
on public.skpe_evolution_scenario_cycles (
  scenario_id,
  period_start,
  period_end
);


-- ============================================================
-- 04. EVOLUTION PLANS
-- ============================================================
--
-- Representa a versão institucional aprovada da trajetória.
--
-- valid_from / valid_until representam Governance Effective
-- Period e não redefinem os períodos estratégicos dos ciclos.
-- ============================================================

create table public.skpe_evolution_plans (

  id uuid
    primary key
    default gen_random_uuid(),

  organization_id uuid
    not null
    references public.organizations(id)
    on delete cascade,

  project_id uuid
    not null
    references public.skpe_projects(id)
    on delete cascade,

  strategic_horizon_id uuid
    not null,

  source_scenario_id uuid,

  version_number integer
    not null,

  governance_status text
    not null,

  is_current boolean
    not null
    default true,

  decision_origin_type text
    not null,

  decision_gate_id uuid
    references public.skpe_gate_decisions(id)
    on delete set null,

  source_reference text,

  valid_from date,

  valid_until date,

  supersedes_plan_id uuid,

  approved_at timestamptz,

  approved_by uuid
    references public.profiles(id)
    on delete set null,

  superseded_at timestamptz,

  superseded_by uuid
    references public.profiles(id)
    on delete set null,

  metadata jsonb
    not null
    default '{}'::jsonb,

  created_at timestamptz
    not null
    default timezone('utc', now()),

  created_by uuid
    references public.profiles(id)
    on delete set null,

  updated_at timestamptz
    not null
    default timezone('utc', now()),

  updated_by uuid
    references public.profiles(id)
    on delete set null,

  constraint skpe_evolution_plans_version_positive
    check (
      version_number > 0
    ),

  constraint skpe_evolution_plans_governance_status_check
    check (
      governance_status in (
        'approved',
        'historical_recognized',
        'superseded',
        'closed'
      )
    ),

  constraint skpe_evolution_plans_origin_check
    check (
      decision_origin_type in (
        'native_platform',
        'imported_historical',
        'migrated',
        'system_generated'
      )
    ),

  constraint skpe_evolution_plans_dates_check
    check (
      valid_until is null
      or valid_from is null
      or valid_until >= valid_from
    ),

  constraint skpe_evolution_plans_metadata_check
    check (
      jsonb_typeof(metadata) = 'object'
    ),

  constraint skpe_evolution_plans_unique_version
    unique (
      strategic_horizon_id,
      version_number
    ),

  constraint skpe_evolution_plans_scope_unique
    unique (
      id,
      strategic_horizon_id,
      organization_id,
      project_id
    ),

  constraint skpe_evolution_plans_horizon_fkey
    foreign key (
      strategic_horizon_id,
      organization_id,
      project_id
    )
    references public.skpe_strategic_horizons (
      id,
      organization_id,
      project_id
    )
    on delete cascade,

  constraint skpe_evolution_plans_source_scenario_fkey
    foreign key (
      source_scenario_id,
      strategic_horizon_id,
      organization_id,
      project_id
    )
    references public.skpe_evolution_scenarios (
      id,
      strategic_horizon_id,
      organization_id,
      project_id
    )
    on delete set null (
      source_scenario_id
    ),

  constraint skpe_evolution_plans_supersedes_fkey
    foreign key (
      supersedes_plan_id,
      strategic_horizon_id,
      organization_id,
      project_id
    )
    references public.skpe_evolution_plans (
      id,
      strategic_horizon_id,
      organization_id,
      project_id
    )
    on delete set null (
      supersedes_plan_id
    )
);


create unique index
  ux_skpe_evolution_plans_current
on public.skpe_evolution_plans (
  strategic_horizon_id
)
where is_current = true;


create index
  idx_skpe_evolution_plans_scope
on public.skpe_evolution_plans (
  organization_id,
  project_id,
  strategic_horizon_id,
  governance_status,
  version_number desc
);


-- ============================================================
-- 05. EVOLUTION CYCLES
-- ============================================================
--
-- Representa cada Ciclo de Evolução já institucionalizado.
--
-- A vigência institucional pertence ao Evolution Plan.
-- O ciclo guarda apenas seu período estratégico.
-- ============================================================

create table public.skpe_evolution_cycles (

  id uuid
    primary key
    default gen_random_uuid(),

  organization_id uuid
    not null
    references public.organizations(id)
    on delete cascade,

  project_id uuid
    not null
    references public.skpe_projects(id)
    on delete cascade,

  strategic_horizon_id uuid
    not null,

  evolution_plan_id uuid
    not null,

  source_scenario_cycle_id uuid,

  sequence_number integer
    not null,

  title text
    not null,

  description text,

  period_start date
    not null,

  period_end date
    not null,

  strategic_intent text,

  expected_outcome text,

  target_maturity jsonb
    not null
    default '{}'::jsonb,

  assumptions jsonb
    not null
    default '[]'::jsonb,

  entry_criteria jsonb
    not null
    default '[]'::jsonb,

  exit_criteria jsonb
    not null
    default '[]'::jsonb,

  strategic_focus jsonb
    not null
    default '[]'::jsonb,

  metadata jsonb
    not null
    default '{}'::jsonb,

  created_at timestamptz
    not null
    default timezone('utc', now()),

  created_by uuid
    references public.profiles(id)
    on delete set null,

  updated_at timestamptz
    not null
    default timezone('utc', now()),

  updated_by uuid
    references public.profiles(id)
    on delete set null,

  constraint skpe_evolution_cycles_sequence_positive
    check (
      sequence_number > 0
    ),

  constraint skpe_evolution_cycles_title_not_blank
    check (
      length(trim(title)) > 0
    ),

  constraint skpe_evolution_cycles_dates_check
    check (
      period_end >= period_start
    ),

  constraint skpe_evolution_cycles_target_maturity_check
    check (
      jsonb_typeof(target_maturity) = 'object'
    ),

  constraint skpe_evolution_cycles_assumptions_check
    check (
      jsonb_typeof(assumptions) = 'array'
    ),

  constraint skpe_evolution_cycles_entry_criteria_check
    check (
      jsonb_typeof(entry_criteria) = 'array'
    ),

  constraint skpe_evolution_cycles_exit_criteria_check
    check (
      jsonb_typeof(exit_criteria) = 'array'
    ),

  constraint skpe_evolution_cycles_strategic_focus_check
    check (
      jsonb_typeof(strategic_focus) = 'array'
    ),

  constraint skpe_evolution_cycles_metadata_check
    check (
      jsonb_typeof(metadata) = 'object'
    ),

  constraint skpe_evolution_cycles_sequence_unique
    unique (
      evolution_plan_id,
      sequence_number
    ),

  constraint skpe_evolution_cycles_plan_fkey
    foreign key (
      evolution_plan_id,
      strategic_horizon_id,
      organization_id,
      project_id
    )
    references public.skpe_evolution_plans (
      id,
      strategic_horizon_id,
      organization_id,
      project_id
    )
    on delete cascade,

  constraint skpe_evolution_cycles_source_scenario_cycle_fkey
    foreign key (
      source_scenario_cycle_id,
      strategic_horizon_id,
      organization_id,
      project_id
    )
    references public.skpe_evolution_scenario_cycles (
      id,
      strategic_horizon_id,
      organization_id,
      project_id
    )
    on delete set null (
      source_scenario_cycle_id
    )
);


create index
  idx_skpe_evolution_cycles_period
on public.skpe_evolution_cycles (
  evolution_plan_id,
  period_start,
  period_end
);


-- ============================================================
-- 06. TEMPORAL INTEGRITY — PROPOSED CYCLES
-- ============================================================
--
-- CHECK constraints não conseguem validar:
--
-- 1. período do ciclo dentro do Horizonte;
-- 2. ausência de sobreposição entre registros diferentes.
--
-- Por isso essas duas regras são concentradas neste trigger.
--
-- Advisory transaction lock serializa alterações concorrentes
-- dentro do mesmo cenário sem introduzir btree_gist.
-- ============================================================

create or replace function
  public.skpe_validate_evolution_scenario_cycle_temporality()
returns trigger
language plpgsql
set search_path = ''
as $function$

declare

  v_start date;
  v_end date;

begin

  select
    make_date(h.horizon_start_year, 1, 1),
    make_date(h.horizon_end_year, 12, 31)

  into
    v_start,
    v_end

  from public.skpe_strategic_horizons h

  where h.id = new.strategic_horizon_id;


  if v_start is null then

    raise exception
      'Horizonte Estratégico não encontrado.'
      using errcode = '23503';

  end if;


  if new.period_start < v_start
     or new.period_end > v_end then

    raise exception
      'Ciclo de Evolução proposto deve permanecer dentro do período estratégico do Horizonte.'
      using errcode = '23514';

  end if;


  perform pg_advisory_xact_lock(
    hashtextextended(
      new.scenario_id::text,
      0
    )
  );


  if exists (

    select 1

    from public.skpe_evolution_scenario_cycles c

    where c.scenario_id = new.scenario_id

      and c.id <> new.id

      and daterange(
        c.period_start,
        c.period_end,
        '[]'
      )
      &&
      daterange(
        new.period_start,
        new.period_end,
        '[]'
      )

  ) then

    raise exception
      'Ciclos de Evolução propostos não podem se sobrepor no mesmo cenário.'
      using errcode = '23P01';

  end if;


  return new;

end;

$function$;


create trigger
  trg_skpe_validate_evolution_scenario_cycle_temporality

before insert
or update of
  scenario_id,
  strategic_horizon_id,
  period_start,
  period_end

on public.skpe_evolution_scenario_cycles

for each row

execute function
  public.skpe_validate_evolution_scenario_cycle_temporality();


-- ============================================================
-- 07. TEMPORAL INTEGRITY — INSTITUTIONAL CYCLES
-- ============================================================

create or replace function
  public.skpe_validate_evolution_cycle_temporality()
returns trigger
language plpgsql
set search_path = ''
as $function$

declare

  v_start date;
  v_end date;

  v_source_scenario_id uuid;
  v_source_cycle_scenario_id uuid;

begin

  select
    make_date(h.horizon_start_year, 1, 1),
    make_date(h.horizon_end_year, 12, 31)

  into
    v_start,
    v_end

  from public.skpe_strategic_horizons h

  where h.id = new.strategic_horizon_id;


  if v_start is null then

    raise exception
      'Horizonte Estratégico não encontrado.'
      using errcode = '23503';

  end if;


  if new.period_start < v_start
     or new.period_end > v_end then

    raise exception
      'Ciclo de Evolução institucional deve permanecer dentro do período estratégico do Horizonte.'
      using errcode = '23514';

  end if;


  if new.source_scenario_cycle_id is not null then

    select
      p.source_scenario_id

    into
      v_source_scenario_id

    from public.skpe_evolution_plans p

    where p.id = new.evolution_plan_id;


    select
      c.scenario_id

    into
      v_source_cycle_scenario_id

    from public.skpe_evolution_scenario_cycles c

    where c.id = new.source_scenario_cycle_id;


    if v_source_scenario_id is null
       or v_source_cycle_scenario_id
          is distinct from
          v_source_scenario_id then

      raise exception
        'O ciclo de origem deve pertencer ao cenário que originou o Plano de Evolução.'
        using errcode = '23514';

    end if;

  end if;


  perform pg_advisory_xact_lock(
    hashtextextended(
      new.evolution_plan_id::text,
      0
    )
  );


  if exists (

    select 1

    from public.skpe_evolution_cycles c

    where c.evolution_plan_id =
          new.evolution_plan_id

      and c.id <> new.id

      and daterange(
        c.period_start,
        c.period_end,
        '[]'
      )
      &&
      daterange(
        new.period_start,
        new.period_end,
        '[]'
      )

  ) then

    raise exception
      'Ciclos de Evolução institucionais não podem se sobrepor no mesmo plano.'
      using errcode = '23P01';

  end if;


  return new;

end;

$function$;


create trigger
  trg_skpe_validate_evolution_cycle_temporality

before insert
or update of
  evolution_plan_id,
  strategic_horizon_id,
  source_scenario_cycle_id,
  period_start,
  period_end

on public.skpe_evolution_cycles

for each row

execute function
  public.skpe_validate_evolution_cycle_temporality();


-- ============================================================
-- 08. ROW LEVEL SECURITY
-- ============================================================

alter table
  public.skpe_evolution_scenarios
enable row level security;


alter table
  public.skpe_evolution_scenario_cycles
enable row level security;


alter table
  public.skpe_evolution_plans
enable row level security;


alter table
  public.skpe_evolution_cycles
enable row level security;


create policy
  skpe_evolution_scenarios_select

on public.skpe_evolution_scenarios

for select

to authenticated

using (
  public.can_view_skpe_journey(
    organization_id
  )
);


create policy
  skpe_evolution_scenario_cycles_select

on public.skpe_evolution_scenario_cycles

for select

to authenticated

using (
  public.can_view_skpe_journey(
    organization_id
  )
);


create policy
  skpe_evolution_plans_select

on public.skpe_evolution_plans

for select

to authenticated

using (
  public.can_view_skpe_journey(
    organization_id
  )
);


create policy
  skpe_evolution_cycles_select

on public.skpe_evolution_cycles

for select

to authenticated

using (
  public.can_view_skpe_journey(
    organization_id
  )
);


-- ============================================================
-- 09. TABLE PRIVILEGES
-- ============================================================
--
-- Usuários autenticados:
-- leitura governada por RLS.
--
-- Escrita direta:
-- não é o caminho operacional.
--
-- As operações governadas serão introduzidas no 17-B.4C.4D.
-- ============================================================

revoke all
on table public.skpe_evolution_scenarios
from public, anon, authenticated;


revoke all
on table public.skpe_evolution_scenario_cycles
from public, anon, authenticated;


revoke all
on table public.skpe_evolution_plans
from public, anon, authenticated;


revoke all
on table public.skpe_evolution_cycles
from public, anon, authenticated;


grant select
on table public.skpe_evolution_scenarios
to authenticated;


grant select
on table public.skpe_evolution_scenario_cycles
to authenticated;


grant select
on table public.skpe_evolution_plans
to authenticated;


grant select
on table public.skpe_evolution_cycles
to authenticated;


grant all
on table public.skpe_evolution_scenarios
to service_role;


grant all
on table public.skpe_evolution_scenario_cycles
to service_role;


grant all
on table public.skpe_evolution_plans
to service_role;


grant all
on table public.skpe_evolution_cycles
to service_role;


-- ============================================================
-- 10. TRIGGER FUNCTION PRIVILEGES
-- ============================================================

revoke all
on function
  public.skpe_validate_evolution_scenario_cycle_temporality()
from public, anon, authenticated;


revoke all
on function
  public.skpe_validate_evolution_cycle_temporality()
from public, anon, authenticated;


grant execute
on function
  public.skpe_validate_evolution_scenario_cycle_temporality()
to service_role;


grant execute
on function
  public.skpe_validate_evolution_cycle_temporality()
to service_role;


-- ============================================================
-- 11. SEMANTIC DOCUMENTATION
-- ============================================================

comment on table
  public.skpe_evolution_scenarios
is
  'Propostas governadas de trajetórias de evolução dentro de um Horizonte Estratégico. SPARKs pode recomendar; a organização decide.';


comment on table
  public.skpe_evolution_scenario_cycles
is
  'Ciclos de Evolução pertencentes a uma proposta de trajetória. Seus períodos representam exclusivamente tempo estratégico.';


comment on column
  public.skpe_evolution_scenario_cycles.period_start
is
  'Início do período estratégico do ciclo proposto. Não representa vigência institucional, execução ou medição.';


comment on column
  public.skpe_evolution_scenario_cycles.period_end
is
  'Fim do período estratégico do ciclo proposto. Não representa vigência institucional, execução ou medição.';


comment on table
  public.skpe_evolution_plans
is
  'Versões institucionais aprovadas da trajetória de evolução vinculada a um Horizonte Estratégico.';


comment on column
  public.skpe_evolution_plans.valid_from
is
  'Início da vigência institucional do Plano de Evolução. Não redefine o período estratégico dos ciclos.';


comment on column
  public.skpe_evolution_plans.valid_until
is
  'Fim da vigência institucional do Plano de Evolução. Não redefine o período estratégico dos ciclos.';


comment on table
  public.skpe_evolution_cycles
is
  'Ciclos de Evolução institucionalizados pertencentes a um Plano de Evolução aprovado.';


comment on column
  public.skpe_evolution_cycles.period_start
is
  'Início do período estratégico do Ciclo de Evolução institucional.';


comment on column
  public.skpe_evolution_cycles.period_end
is
  'Fim do período estratégico do Ciclo de Evolução institucional.';