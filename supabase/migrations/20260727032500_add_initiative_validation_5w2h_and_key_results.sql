-- ============================================================
-- Plataforma SPARKs / SK-PE
-- Migration substitutiva: Painel de Iniciativas, origem,
-- validação organizacional, 5W2H e vínculos com OE/KRs
-- Conteúdos funcionais em Português do Brasil
-- ============================================================

begin;

-- ============================================================
-- 1. CORREÇÃO DO PAINEL GERENCIAL
-- ============================================================

create or replace function public.get_skpe_initiatives_dashboard(
  target_organization_id uuid,
  target_project_id uuid default null,
  target_initiative_type text default null,
  target_responsible_area text default null,
  target_strategic_objective_id uuid default null,
  target_status text default null
)
returns table (
  total_initiatives bigint,
  proposed_count bigint,
  in_progress_count bigint,
  completed_count bigint,
  delayed_count bigint,
  blocked_count bigint,
  critical_count bigint,
  without_owner_count bigint,
  without_recent_update_count bigint,
  with_instrument_count bigint,
  without_instrument_count bigint,
  average_progress numeric,
  planned_cost numeric,
  actual_cost numeric,
  planned_benefit numeric,
  realized_benefit numeric
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.can_view_skpe_initiatives(target_organization_id) then
    raise exception
      'Acesso negado: o usuário não pode consultar as iniciativas desta organização.'
      using errcode = '42501';
  end if;

  return query
  with filtered_initiatives as (
    select distinct
      initiative.id,
      initiative.status,
      initiative.priority,
      initiative.owner_user_id,
      initiative.due_date,
      initiative.progress,
      initiative.risk_level,
      initiative.health_status,
      initiative.last_update_at,
      initiative.updated_at,
      initiative.created_at,
      initiative.planned_cost,
      initiative.actual_cost,
      initiative.planned_benefit,
      initiative.realized_benefit
    from public.skpe_initiatives initiative
    left join public.skpe_initiative_objectives initiative_objective
      on initiative_objective.initiative_id = initiative.id
    where initiative.organization_id = target_organization_id
      and initiative.archived_at is null
      and (target_project_id is null or initiative.project_id = target_project_id)
      and (target_initiative_type is null or initiative.initiative_type = target_initiative_type)
      and (target_responsible_area is null or initiative.responsible_area = target_responsible_area)
      and (target_status is null or initiative.status = target_status)
      and (
        target_strategic_objective_id is null
        or initiative_objective.strategic_objective_id = target_strategic_objective_id
      )
  )
  select
    count(*)::bigint,
    count(*) filter (
      where fi.status in ('proposed', 'under_analysis')
    )::bigint,
    count(*) filter (
      where fi.status = 'in_progress'
    )::bigint,
    count(*) filter (
      where fi.status = 'completed'
    )::bigint,
    count(*) filter (
      where fi.due_date < current_date
        and fi.status not in ('completed', 'cancelled', 'archived')
    )::bigint,
    count(*) filter (where fi.status = 'blocked')::bigint,
    count(*) filter (
      where fi.priority = 'critical'
         or fi.risk_level = 'critical'
         or fi.health_status = 'critical'
    )::bigint,
    count(*) filter (where fi.owner_user_id is null)::bigint,
    count(*) filter (
      where fi.status not in ('completed', 'cancelled', 'archived')
        and coalesce(fi.last_update_at, fi.updated_at, fi.created_at)
          < timezone('utc', now()) - interval '30 days'
    )::bigint,
    count(*) filter (
      where exists (
        select 1
        from public.skpe_initiative_instruments instrument
        where instrument.initiative_id = fi.id
          and instrument.status <> 'archived'
      )
    )::bigint,
    count(*) filter (
      where not exists (
        select 1
        from public.skpe_initiative_instruments instrument
        where instrument.initiative_id = fi.id
          and instrument.status <> 'archived'
      )
    )::bigint,
    coalesce(round(avg(fi.progress), 2), 0)::numeric,
    coalesce(sum(fi.planned_cost), 0)::numeric,
    coalesce(sum(fi.actual_cost), 0)::numeric,
    coalesce(sum(fi.planned_benefit), 0)::numeric,
    coalesce(sum(fi.realized_benefit), 0)::numeric
  from filtered_initiatives fi;
end;
$$;

-- ============================================================
-- 2. ORIGEM, VALIDAÇÃO E 5W2H OBRIGATÓRIO
-- ============================================================

alter table public.skpe_initiatives
  add column if not exists proposal_origin text not null default 'organization',
  add column if not exists proposal_source_reference text,
  add column if not exists validation_status text not null default 'not_required',
  add column if not exists validation_notes text,
  add column if not exists validated_at timestamptz,
  add column if not exists validated_by uuid references public.profiles(id) on delete set null,
  add column if not exists replaced_by_initiative_id uuid references public.skpe_initiatives(id) on delete set null,
  add column if not exists what_text text,
  add column if not exists why_text text,
  add column if not exists where_text text,
  add column if not exists when_text text,
  add column if not exists who_text text,
  add column if not exists how_text text,
  add column if not exists how_much_text text;

alter table public.skpe_initiatives
  drop constraint if exists skpe_initiatives_proposal_origin_check;

alter table public.skpe_initiatives
  add constraint skpe_initiatives_proposal_origin_check
  check (proposal_origin in (
    'sparks_suggestion',
    'organization',
    'joint_construction',
    'previous_plan',
    'assessment',
    'action_plan',
    'bmc_vpc',
    'benchmark'
  ));

alter table public.skpe_initiatives
  drop constraint if exists skpe_initiatives_validation_status_check;

alter table public.skpe_initiatives
  add constraint skpe_initiatives_validation_status_check
  check (validation_status in (
    'pending_validation',
    'under_review',
    'validated',
    'validated_with_adjustments',
    'rejected',
    'replaced',
    'not_required'
  ));

create index if not exists idx_skpe_initiatives_origin_validation
  on public.skpe_initiatives(
    organization_id,
    project_id,
    proposal_origin,
    validation_status
  )
  where archived_at is null;

comment on column public.skpe_initiatives.proposal_origin is
  'Origem metodológica da iniciativa: sugestão da SPARKs, organização, construção conjunta ou fonte derivada.';

comment on column public.skpe_initiatives.validation_status is
  'Situação da validação organizacional da iniciativa proposta.';

comment on column public.skpe_initiatives.what_text is '5W2H — O que será feito.';
comment on column public.skpe_initiatives.why_text is '5W2H — Por que será feito.';
comment on column public.skpe_initiatives.where_text is '5W2H — Onde será realizado.';
comment on column public.skpe_initiatives.when_text is '5W2H — Quando será realizado.';
comment on column public.skpe_initiatives.who_text is '5W2H — Quem será responsável e participará.';
comment on column public.skpe_initiatives.how_text is '5W2H — Como será realizado.';
comment on column public.skpe_initiatives.how_much_text is '5W2H — Quanto custará e quais recursos serão necessários.';

-- ============================================================
-- 3. RESULTADOS-CHAVE E VÍNCULOS COM INICIATIVAS
-- ============================================================

create table if not exists public.skpe_key_results (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  project_id uuid not null references public.skpe_projects(id) on delete cascade,
  strategic_objective_id uuid not null references public.skpe_strategic_objectives(id) on delete cascade,
  code text not null,
  name text not null,
  description text,
  baseline_value numeric,
  target_value numeric,
  current_value numeric,
  unit text,
  period_start date,
  period_end date,
  owner_user_id uuid references public.profiles(id) on delete set null,
  status text not null default 'draft',
  progress numeric(5,2) not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_key_results_code_not_blank check (length(trim(code)) > 0),
  constraint skpe_key_results_name_not_blank check (length(trim(name)) > 0),
  constraint skpe_key_results_status_check check (status in (
    'draft', 'active', 'at_risk', 'achieved', 'not_achieved', 'cancelled'
  )),
  constraint skpe_key_results_progress_check check (progress between 0 and 100),
  constraint skpe_key_results_unique_code unique (strategic_objective_id, code)
);

create index if not exists idx_skpe_key_results_objective
  on public.skpe_key_results(strategic_objective_id, status);

create trigger skpe_key_results_set_updated_at
before update on public.skpe_key_results
for each row
execute function public.set_updated_at();

create table if not exists public.skpe_initiative_key_results (
  initiative_id uuid not null references public.skpe_initiatives(id) on delete cascade,
  key_result_id uuid not null references public.skpe_key_results(id) on delete cascade,
  contribution_type text not null default 'direct',
  contribution_weight numeric(5,2),
  notes text,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  primary key (initiative_id, key_result_id),
  constraint skpe_initiative_key_results_type_check
    check (contribution_type in ('direct', 'supporting', 'enabling')),
  constraint skpe_initiative_key_results_weight_check
    check (contribution_weight is null or contribution_weight between 0 and 100)
);

-- ============================================================
-- 4. FUNÇÕES DE APOIO
-- ============================================================

create or replace function public.skpe_assert_complete_5w2h(
  what_text text,
  why_text text,
  where_text text,
  when_text text,
  who_text text,
  how_text text,
  how_much_text text
)
returns void
language plpgsql
immutable
set search_path = ''
as $$
begin
  if length(trim(coalesce(what_text, ''))) < 5 then
    raise exception 'Preencha o campo 5W2H — O que será feito.';
  end if;

  if length(trim(coalesce(why_text, ''))) < 5 then
    raise exception 'Preencha o campo 5W2H — Por que será feito.';
  end if;

  if length(trim(coalesce(where_text, ''))) < 3 then
    raise exception 'Preencha o campo 5W2H — Onde será realizado.';
  end if;

  if length(trim(coalesce(when_text, ''))) < 3 then
    raise exception 'Preencha o campo 5W2H — Quando será realizado.';
  end if;

  if length(trim(coalesce(who_text, ''))) < 3 then
    raise exception 'Preencha o campo 5W2H — Quem será responsável.';
  end if;

  if length(trim(coalesce(how_text, ''))) < 5 then
    raise exception 'Preencha o campo 5W2H — Como será realizado.';
  end if;

  if length(trim(coalesce(how_much_text, ''))) < 3 then
    raise exception 'Preencha o campo 5W2H — Quanto custará e quais recursos serão necessários.';
  end if;
end;
$$;

-- ============================================================
-- 5. CRIAÇÃO DE INICIATIVA NO NOVO PADRÃO
-- ============================================================

create or replace function public.create_skpe_initiative_v2(
  target_project_id uuid,
  initiative_code text,
  initiative_name text,
  initiative_description text,
  initiative_type text,
  initiative_priority text,
  proposal_origin text,
  proposal_source_reference text,
  responsible_area text,
  owner_user_id uuid,
  sponsor_user_id uuid,
  start_date date,
  due_date date,
  planned_cost numeric,
  planned_benefit numeric,
  strategic_theme text,
  what_text text,
  why_text text,
  where_text text,
  when_text text,
  who_text text,
  how_text text,
  how_much_text text,
  linked_journey_item_id uuid default null,
  parent_initiative_id uuid default null,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_organization_id uuid;
  new_initiative_id uuid;
  initial_validation_status text;
  new_row jsonb;
begin
  perform public.skpe_assert_reason(change_reason);
  perform public.skpe_assert_complete_5w2h(
    what_text,
    why_text,
    where_text,
    when_text,
    who_text,
    how_text,
    how_much_text
  );

  select project.organization_id
  into target_organization_id
  from public.skpe_projects project
  where project.id = target_project_id;

  if target_organization_id is null then
    raise exception 'Projeto estratégico não encontrado.';
  end if;

  if not public.can_manage_skpe_initiatives(target_organization_id) then
    raise exception 'Você não possui permissão para gerenciar iniciativas desta organização.';
  end if;

  if proposal_origin not in (
    'sparks_suggestion',
    'organization',
    'joint_construction',
    'previous_plan',
    'assessment',
    'action_plan',
    'bmc_vpc',
    'benchmark'
  ) then
    raise exception 'Origem da iniciativa inválida.';
  end if;

  initial_validation_status := case
    when proposal_origin = 'organization' then 'not_required'
    else 'pending_validation'
  end;

  insert into public.skpe_initiatives (
    organization_id,
    project_id,
    parent_initiative_id,
    linked_journey_item_id,
    code,
    name,
    description,
    initiative_type,
    priority,
    proposal_origin,
    proposal_source_reference,
    validation_status,
    responsible_area,
    owner_user_id,
    sponsor_user_id,
    start_date,
    due_date,
    planned_cost,
    planned_benefit,
    strategic_theme,
    what_text,
    why_text,
    where_text,
    when_text,
    who_text,
    how_text,
    how_much_text,
    status,
    progress,
    last_update_at,
    created_by,
    updated_by
  )
  values (
    target_organization_id,
    target_project_id,
    parent_initiative_id,
    linked_journey_item_id,
    trim(initiative_code),
    trim(initiative_name),
    nullif(trim(initiative_description), ''),
    initiative_type,
    initiative_priority,
    proposal_origin,
    nullif(trim(proposal_source_reference), ''),
    initial_validation_status,
    nullif(trim(responsible_area), ''),
    owner_user_id,
    sponsor_user_id,
    start_date,
    due_date,
    planned_cost,
    planned_benefit,
    nullif(trim(strategic_theme), ''),
    trim(what_text),
    trim(why_text),
    trim(where_text),
    trim(when_text),
    trim(who_text),
    trim(how_text),
    trim(how_much_text),
    'proposed',
    0,
    timezone('utc', now()),
    auth.uid(),
    auth.uid()
  )
  returning id into new_initiative_id;

  select to_jsonb(initiative)
  into new_row
  from public.skpe_initiatives initiative
  where initiative.id = new_initiative_id;

  perform public.skpe_record_operational_audit(
    target_organization_id,
    target_project_id,
    'initiative',
    new_initiative_id,
    'initiative.created_with_5w2h',
    change_reason,
    null,
    new_row
  );

  return new_initiative_id;
end;
$$;

-- ============================================================
-- 6. VALIDAÇÃO ORGANIZACIONAL DA INICIATIVA
-- ============================================================

create or replace function public.validate_skpe_initiative(
  target_initiative_id uuid,
  target_validation_status text,
  validation_notes text,
  replacement_initiative_id uuid default null,
  change_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  initiative_row public.skpe_initiatives%rowtype;
  previous_data jsonb;
  new_data jsonb;
begin
  perform public.skpe_assert_reason(change_reason);

  if target_validation_status not in (
    'under_review',
    'validated',
    'validated_with_adjustments',
    'rejected',
    'replaced'
  ) then
    raise exception 'Situação de validação inválida.';
  end if;

  if target_validation_status in ('rejected', 'replaced', 'validated_with_adjustments')
     and length(trim(coalesce(validation_notes, ''))) < 10 then
    raise exception 'Informe uma justificativa de validação com pelo menos 10 caracteres.';
  end if;

  if target_validation_status = 'replaced' and replacement_initiative_id is null then
    raise exception 'Informe a iniciativa substituta.';
  end if;

  select *
  into initiative_row
  from public.skpe_initiatives
  where id = target_initiative_id
  for update;

  if initiative_row.id is null then
    raise exception 'Iniciativa não encontrada.';
  end if;

  if not public.can_manage_skpe_initiatives(initiative_row.organization_id) then
    raise exception 'Você não possui permissão para validar esta iniciativa.';
  end if;

  previous_data := to_jsonb(initiative_row);

  update public.skpe_initiatives
  set
    validation_status = target_validation_status,
    validation_notes = nullif(trim(validation_notes), ''),
    validated_at = case
      when target_validation_status in (
        'validated',
        'validated_with_adjustments',
        'rejected',
        'replaced'
      ) then timezone('utc', now())
      else null
    end,
    validated_by = case
      when target_validation_status in (
        'validated',
        'validated_with_adjustments',
        'rejected',
        'replaced'
      ) then auth.uid()
      else null
    end,
    replaced_by_initiative_id = case
      when target_validation_status = 'replaced' then replacement_initiative_id
      else null
    end,
    updated_by = auth.uid(),
    last_update_at = timezone('utc', now())
  where id = target_initiative_id
  returning to_jsonb(skpe_initiatives)
  into new_data;

  perform public.skpe_record_operational_audit(
    initiative_row.organization_id,
    initiative_row.project_id,
    'initiative',
    target_initiative_id,
    'initiative.validation_updated',
    change_reason,
    previous_data,
    new_data
  );
end;
$$;

-- ============================================================
-- 7. VÍNCULO COM RESULTADOS-CHAVE
-- ============================================================

create or replace function public.link_skpe_initiative_key_result(
  target_initiative_id uuid,
  target_key_result_id uuid,
  target_contribution_type text default 'direct',
  target_contribution_weight numeric default null,
  target_notes text default null,
  change_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  initiative_row public.skpe_initiatives%rowtype;
  key_result_row public.skpe_key_results%rowtype;
begin
  perform public.skpe_assert_reason(change_reason);

  select * into initiative_row
  from public.skpe_initiatives
  where id = target_initiative_id;

  select * into key_result_row
  from public.skpe_key_results
  where id = target_key_result_id;

  if initiative_row.id is null or key_result_row.id is null then
    raise exception 'Iniciativa ou Resultado-Chave não encontrado.';
  end if;

  if initiative_row.project_id <> key_result_row.project_id then
    raise exception 'A iniciativa e o Resultado-Chave devem pertencer ao mesmo projeto.';
  end if;

  if not public.can_manage_skpe_initiatives(initiative_row.organization_id) then
    raise exception 'Você não possui permissão para vincular Resultados-Chave.';
  end if;

  insert into public.skpe_initiative_key_results (
    initiative_id,
    key_result_id,
    contribution_type,
    contribution_weight,
    notes,
    created_by
  )
  values (
    target_initiative_id,
    target_key_result_id,
    target_contribution_type,
    target_contribution_weight,
    nullif(trim(target_notes), ''),
    auth.uid()
  )
  on conflict (initiative_id, key_result_id)
  do update set
    contribution_type = excluded.contribution_type,
    contribution_weight = excluded.contribution_weight,
    notes = excluded.notes;

  perform public.skpe_record_operational_audit(
    initiative_row.organization_id,
    initiative_row.project_id,
    'initiative',
    target_initiative_id,
    'initiative.key_result_linked',
    change_reason,
    null,
    jsonb_build_object(
      'key_result_id', target_key_result_id,
      'contribution_type', target_contribution_type,
      'contribution_weight', target_contribution_weight
    )
  );
end;
$$;

-- ============================================================
-- 8. CONSULTA COMPLETA PARA O NOVO FRONTEND
-- ============================================================

create or replace function public.get_skpe_initiatives_v2(
  target_organization_id uuid,
  target_project_id uuid default null,
  target_initiative_type text default null,
  target_responsible_area text default null,
  target_strategic_objective_id uuid default null,
  target_key_result_id uuid default null,
  target_status text default null,
  target_validation_status text default null,
  target_proposal_origin text default null
)
returns table (
  initiative_id uuid,
  project_id uuid,
  project_code text,
  initiative_code text,
  initiative_name text,
  initiative_description text,
  initiative_type text,
  initiative_status text,
  priority text,
  responsible_area text,
  owner_user_id uuid,
  owner_name text,
  start_date date,
  due_date date,
  progress numeric,
  planned_cost numeric,
  actual_cost numeric,
  planned_benefit numeric,
  realized_benefit numeric,
  risk_level text,
  health_status text,
  last_update_at timestamptz,
  delayed boolean,
  proposal_origin text,
  proposal_source_reference text,
  validation_status text,
  validation_notes text,
  validated_at timestamptz,
  validated_by_name text,
  what_text text,
  why_text text,
  where_text text,
  when_text text,
  who_text text,
  how_text text,
  how_much_text text,
  five_w_two_h_completion numeric,
  strategic_objectives jsonb,
  key_results jsonb,
  instruments jsonb
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.can_view_skpe_initiatives(target_organization_id) then
    raise exception
      'Acesso negado: o usuário não pode consultar as iniciativas desta organização.'
      using errcode = '42501';
  end if;

  return query
  select
    initiative.id,
    initiative.project_id,
    project.code,
    initiative.code,
    initiative.name,
    initiative.description,
    initiative.initiative_type,
    initiative.status,
    initiative.priority,
    initiative.responsible_area,
    initiative.owner_user_id,
    coalesce(owner.display_name, owner.full_name, owner.email),
    initiative.start_date,
    initiative.due_date,
    initiative.progress,
    initiative.planned_cost,
    initiative.actual_cost,
    initiative.planned_benefit,
    initiative.realized_benefit,
    initiative.risk_level,
    initiative.health_status,
    initiative.last_update_at,
    (
      initiative.due_date < current_date
      and initiative.status not in ('completed', 'cancelled', 'archived')
    ),
    initiative.proposal_origin,
    initiative.proposal_source_reference,
    initiative.validation_status,
    initiative.validation_notes,
    initiative.validated_at,
    coalesce(validator.display_name, validator.full_name, validator.email),
    initiative.what_text,
    initiative.why_text,
    initiative.where_text,
    initiative.when_text,
    initiative.who_text,
    initiative.how_text,
    initiative.how_much_text,
    (
      (
        (case when length(trim(coalesce(initiative.what_text, ''))) > 0 then 1 else 0 end) +
        (case when length(trim(coalesce(initiative.why_text, ''))) > 0 then 1 else 0 end) +
        (case when length(trim(coalesce(initiative.where_text, ''))) > 0 then 1 else 0 end) +
        (case when length(trim(coalesce(initiative.when_text, ''))) > 0 then 1 else 0 end) +
        (case when length(trim(coalesce(initiative.who_text, ''))) > 0 then 1 else 0 end) +
        (case when length(trim(coalesce(initiative.how_text, ''))) > 0 then 1 else 0 end) +
        (case when length(trim(coalesce(initiative.how_much_text, ''))) > 0 then 1 else 0 end)
      ) * 100.0 / 7.0
    )::numeric(5,2),
    coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', objective.id,
          'code', objective.code,
          'name', objective.name,
          'management_model', objective.management_model,
          'contribution_type', link.contribution_type,
          'contribution_weight', link.contribution_weight
        )
        order by objective.code
      )
      from public.skpe_initiative_objectives link
      join public.skpe_strategic_objectives objective
        on objective.id = link.strategic_objective_id
      where link.initiative_id = initiative.id
    ), '[]'::jsonb),
    coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', key_result.id,
          'code', key_result.code,
          'name', key_result.name,
          'status', key_result.status,
          'progress', key_result.progress,
          'contribution_type', key_link.contribution_type,
          'contribution_weight', key_link.contribution_weight
        )
        order by key_result.code
      )
      from public.skpe_initiative_key_results key_link
      join public.skpe_key_results key_result
        on key_result.id = key_link.key_result_id
      where key_link.initiative_id = initiative.id
    ), '[]'::jsonb),
    coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', instrument.id,
          'type', instrument.instrument_type,
          'reference_id', instrument.instrument_reference_id,
          'code', instrument.instrument_code,
          'status', instrument.status,
          'is_primary', instrument.is_primary
        )
        order by instrument.is_primary desc, instrument.created_at
      )
      from public.skpe_initiative_instruments instrument
      where instrument.initiative_id = initiative.id
        and instrument.status <> 'archived'
    ), '[]'::jsonb)
  from public.skpe_initiatives initiative
  join public.skpe_projects project
    on project.id = initiative.project_id
  left join public.profiles owner
    on owner.id = initiative.owner_user_id
  left join public.profiles validator
    on validator.id = initiative.validated_by
  where initiative.organization_id = target_organization_id
    and initiative.archived_at is null
    and (target_project_id is null or initiative.project_id = target_project_id)
    and (target_initiative_type is null or initiative.initiative_type = target_initiative_type)
    and (target_responsible_area is null or initiative.responsible_area = target_responsible_area)
    and (target_status is null or initiative.status = target_status)
    and (target_validation_status is null or initiative.validation_status = target_validation_status)
    and (target_proposal_origin is null or initiative.proposal_origin = target_proposal_origin)
    and (
      target_strategic_objective_id is null
      or exists (
        select 1
        from public.skpe_initiative_objectives objective_link
        where objective_link.initiative_id = initiative.id
          and objective_link.strategic_objective_id = target_strategic_objective_id
      )
    )
    and (
      target_key_result_id is null
      or exists (
        select 1
        from public.skpe_initiative_key_results key_link
        where key_link.initiative_id = initiative.id
          and key_link.key_result_id = target_key_result_id
      )
    )
  order by
    case initiative.validation_status
      when 'pending_validation' then 1
      when 'under_review' then 2
      else 3
    end,
    case initiative.priority
      when 'critical' then 1
      when 'high' then 2
      when 'medium' then 3
      else 4
    end,
    initiative.due_date nulls last,
    initiative.name;
end;
$$;

-- ============================================================
-- 9. RLS PARA NOVAS TABELAS
-- ============================================================

alter table public.skpe_key_results enable row level security;
alter table public.skpe_initiative_key_results enable row level security;

drop policy if exists skpe_key_results_select on public.skpe_key_results;
create policy skpe_key_results_select
on public.skpe_key_results
for select
to authenticated
using (public.can_view_skpe_initiatives(organization_id));

drop policy if exists skpe_key_results_manage on public.skpe_key_results;
create policy skpe_key_results_manage
on public.skpe_key_results
for all
to authenticated
using (public.can_manage_skpe_initiatives(organization_id))
with check (public.can_manage_skpe_initiatives(organization_id));

drop policy if exists skpe_initiative_key_results_select on public.skpe_initiative_key_results;
create policy skpe_initiative_key_results_select
on public.skpe_initiative_key_results
for select
to authenticated
using (
  exists (
    select 1
    from public.skpe_initiatives initiative
    where initiative.id = initiative_id
      and public.can_view_skpe_initiatives(initiative.organization_id)
  )
);

drop policy if exists skpe_initiative_key_results_manage on public.skpe_initiative_key_results;
create policy skpe_initiative_key_results_manage
on public.skpe_initiative_key_results
for all
to authenticated
using (
  exists (
    select 1
    from public.skpe_initiatives initiative
    where initiative.id = initiative_id
      and public.can_manage_skpe_initiatives(initiative.organization_id)
  )
)
with check (
  exists (
    select 1
    from public.skpe_initiatives initiative
    where initiative.id = initiative_id
      and public.can_manage_skpe_initiatives(initiative.organization_id)
  )
);

-- ============================================================
-- 10. PERMISSÕES DE EXECUÇÃO
-- ============================================================

revoke all on function public.get_skpe_initiatives_dashboard(uuid, uuid, text, text, uuid, text)
from public, anon;

revoke all on function public.skpe_assert_complete_5w2h(text, text, text, text, text, text, text)
from public, anon;

revoke all on function public.create_skpe_initiative_v2(uuid, text, text, text, text, text, text, text, text, uuid, uuid, date, date, numeric, numeric, text, text, text, text, text, text, text, text, uuid, uuid, text)
from public, anon;

revoke all on function public.validate_skpe_initiative(uuid, text, text, uuid, text)
from public, anon;

revoke all on function public.link_skpe_initiative_key_result(uuid, uuid, text, numeric, text, text)
from public, anon;

revoke all on function public.get_skpe_initiatives_v2(uuid, uuid, text, text, uuid, uuid, text, text, text)
from public, anon;

grant execute on function public.get_skpe_initiatives_dashboard(uuid, uuid, text, text, uuid, text)
to authenticated, service_role;

grant execute on function public.create_skpe_initiative_v2(uuid, text, text, text, text, text, text, text, text, uuid, uuid, date, date, numeric, numeric, text, text, text, text, text, text, text, text, uuid, uuid, text)
to authenticated, service_role;

grant execute on function public.validate_skpe_initiative(uuid, text, text, uuid, text)
to authenticated, service_role;

grant execute on function public.link_skpe_initiative_key_result(uuid, uuid, text, numeric, text, text)
to authenticated, service_role;

grant execute on function public.get_skpe_initiatives_v2(uuid, uuid, text, text, uuid, uuid, text, text, text)
to authenticated, service_role;

grant select, insert, update, delete on public.skpe_key_results
to authenticated, service_role;

grant select, insert, update, delete on public.skpe_initiative_key_results
to authenticated, service_role;

commit;
