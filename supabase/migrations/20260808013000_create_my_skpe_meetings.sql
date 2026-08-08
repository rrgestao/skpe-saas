begin;

-- ============================================================
-- FE-09.A.12 — Meu Espaço de Trabalho — Reuniões
--
-- Contrato pessoal comprovado nesta entrega:
-- - chair_user_id = auth.uid()
-- - secretary_user_id = auth.uid()
--
-- O campo participants permanece somente informativo.
-- Ele NÃO é utilizado para inferir pertencimento ao usuário,
-- pois ainda não existe contrato estrutural comprovado para o JSON.
-- ============================================================

create or replace function public.get_my_skpe_meetings(
  target_organization_id uuid,
  target_project_id uuid default null,
  target_formulation_id uuid default null
)
returns table (
  strategy_review_id uuid,
  organization_id uuid,
  project_id uuid,
  formulation_id uuid,

  formulation_version_number integer,
  formulation_version_label text,
  formulation_status text,

  monitoring_cycle_id uuid,
  cycle_code text,
  cycle_name text,
  cycle_type text,
  cycle_period_start date,
  cycle_period_end date,
  cycle_status text,

  code text,
  title text,
  review_type text,
  status text,

  scheduled_at timestamptz,
  held_at timestamptz,

  chair_user_id uuid,
  secretary_user_id uuid,
  current_user_role text,

  participants jsonb,
  participant_count integer,

  executive_summary text,
  conclusions text,
  minutes_reference text,

  ratified_at timestamptz,
  ratified_by uuid,
  is_ratified boolean,

  is_scheduled boolean,
  is_today boolean,
  is_upcoming boolean,
  is_overdue boolean,
  days_until_meeting integer,

  review_item_count integer,
  open_review_item_count integer,
  decision_count integer,
  open_decision_count integer,

  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'Usuário não autenticado.'
      using errcode = '42501';
  end if;

  if target_organization_id is null then
    raise exception 'Informe a organização.'
      using errcode = '22023';
  end if;

  if not (
    public.is_active_member(target_organization_id)
    and public.has_module_access(target_organization_id, 'SK-PE')
  ) then
    raise exception
      'Acesso negado: o usuário não pode consultar reuniões do SK-PE nesta organização.'
      using errcode = '42501';
  end if;

  return query
  select
    review.id as strategy_review_id,
    review.organization_id,
    review.project_id,
    review.formulation_id,

    formulation.version_number as formulation_version_number,
    formulation.version_label as formulation_version_label,
    formulation.status as formulation_status,

    cycle.id as monitoring_cycle_id,
    cycle.code as cycle_code,
    cycle.name as cycle_name,
    cycle.cycle_type,
    cycle.period_start as cycle_period_start,
    cycle.period_end as cycle_period_end,
    cycle.status as cycle_status,

    review.code,
    review.title,
    review.review_type,
    review.status,

    review.scheduled_at,
    review.held_at,

    review.chair_user_id,
    review.secretary_user_id,

    case
      when review.chair_user_id = current_user_id
       and review.secretary_user_id = current_user_id
        then 'chair_and_secretary'
      when review.chair_user_id = current_user_id
        then 'chair'
      when review.secretary_user_id = current_user_id
        then 'secretary'
      else 'none'
    end::text as current_user_role,

    review.participants,

    case
      when jsonb_typeof(review.participants) = 'array'
        then jsonb_array_length(review.participants)
      else null
    end::integer as participant_count,

    review.executive_summary,
    review.conclusions,
    review.minutes_reference,

    review.ratified_at,
    review.ratified_by,
    review.ratified_at is not null as is_ratified,

    (
      review.scheduled_at is not null
      and review.status not in ('cancelled', 'closed')
    ) as is_scheduled,

    (
      review.scheduled_at is not null
      and review.scheduled_at::date = current_date
      and review.status not in ('cancelled', 'closed')
    ) as is_today,

    (
      review.scheduled_at is not null
      and review.scheduled_at > now()
      and review.status not in ('cancelled', 'closed')
    ) as is_upcoming,

    (
      review.scheduled_at is not null
      and review.scheduled_at < now()
      and review.held_at is null
      and review.status in ('draft', 'scheduled')
    ) as is_overdue,

    case
      when review.scheduled_at is null then null
      else (review.scheduled_at::date - current_date)
    end::integer as days_until_meeting,

    (
      select count(*)::integer
      from public.skpe_strategy_review_items review_item
      where review_item.strategy_review_id = review.id
    ) as review_item_count,

    (
      select count(*)::integer
      from public.skpe_strategy_review_items review_item
      where review_item.strategy_review_id = review.id
        and review_item.status in ('open', 'analyzed')
    ) as open_review_item_count,

    (
      select count(*)::integer
      from public.skpe_governance_decisions decision
      where decision.strategy_review_id = review.id
    ) as decision_count,

    (
      select count(*)::integer
      from public.skpe_governance_decisions decision
      where decision.strategy_review_id = review.id
        and decision.status not in ('completed', 'cancelled')
    ) as open_decision_count,

    review.created_at,
    review.updated_at

  from public.skpe_strategy_reviews review

  join public.skpe_strategic_formulations formulation
    on formulation.id = review.formulation_id

  join public.skpe_monitoring_cycles cycle
    on cycle.id = review.monitoring_cycle_id

  where review.organization_id = target_organization_id
    and (
      review.chair_user_id = current_user_id
      or review.secretary_user_id = current_user_id
    )
    and (
      target_project_id is null
      or review.project_id = target_project_id
    )
    and (
      target_formulation_id is null
      or review.formulation_id = target_formulation_id
    )

  order by
    case
      when review.status = 'in_progress' then 0
      when review.scheduled_at is not null
       and review.scheduled_at::date = current_date
       and review.status not in ('cancelled', 'closed')
        then 1
      when review.scheduled_at is not null
       and review.scheduled_at < now()
       and review.held_at is null
       and review.status in ('draft', 'scheduled')
        then 2
      when review.scheduled_at is not null
       and review.scheduled_at > now()
       and review.status not in ('cancelled', 'closed')
        then 3
      when review.status = 'pending_ratification' then 4
      when review.status = 'ratified' then 5
      when review.status = 'closed' then 6
      when review.status = 'cancelled' then 7
      else 8
    end,
    case
      when review.scheduled_at >= now() then review.scheduled_at
      else null
    end nulls last,
    review.scheduled_at desc nulls last,
    review.title,
    review.code;

end;
$$;

comment on function public.get_my_skpe_meetings(uuid, uuid, uuid) is
'FE-09.A.12: consulta gerencial somente leitura das reuniões estratégicas em que o usuário autenticado exerce papel comprovado de presidência ou secretaria, com contexto de Formulação, ciclo de monitoramento, agenda, itens de análise e decisões. O JSON participants não é utilizado para inferir pertencimento pessoal enquanto não houver contrato estrutural formalizado.';

revoke all on function public.get_my_skpe_meetings(uuid, uuid, uuid)
from public, anon;

grant execute on function public.get_my_skpe_meetings(uuid, uuid, uuid)
to authenticated, service_role;

commit;
