begin;

alter table public.skpe_initiatives
  add column if not exists suggested_by_module text,
  add column if not exists suggestion_generated_at timestamptz,
  add column if not exists suggestion_snapshot jsonb not null default '{}'::jsonb,
  add column if not exists suggestion_decision text not null default 'not_applicable',
  add column if not exists suggestion_decided_at timestamptz,
  add column if not exists suggestion_decided_by uuid references public.profiles(id) on delete set null,
  add column if not exists suggestion_curation_notes text;

alter table public.skpe_initiatives
  drop constraint if exists skpe_initiatives_suggestion_decision_check;

alter table public.skpe_initiatives
  add constraint skpe_initiatives_suggestion_decision_check
  check (suggestion_decision in (
    'not_applicable',
    'pending',
    'accepted',
    'accepted_with_adjustments',
    'rejected'
  ));

create or replace function public.skpe_assert_sparks_suggested_initiative_governance()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if new.proposal_origin = 'sparks_suggestion' then
    if nullif(btrim(coalesce(new.suggested_by_module, '')), '') is null then
      raise exception 'SPARKs suggested initiative requires suggested_by_module';
    end if;

    if nullif(btrim(coalesce(new.proposal_source_reference, '')), '') is null then
      raise exception 'SPARKs suggested initiative requires proposal_source_reference';
    end if;

    if new.suggestion_generated_at is null then
      raise exception 'SPARKs suggested initiative requires suggestion_generated_at';
    end if;

    if coalesce(new.suggestion_snapshot, '{}'::jsonb) = '{}'::jsonb then
      raise exception 'SPARKs suggested initiative requires immutable suggestion_snapshot';
    end if;

    if new.suggestion_decision = 'not_applicable' then
      raise exception 'SPARKs suggested initiative requires suggestion_decision other than not_applicable';
    end if;

    if new.suggestion_decision = 'pending' then
      if new.status <> 'proposed' then
        raise exception 'Pending SPARKs suggestion must persist with status=proposed';
      end if;
      if new.validation_status <> 'pending_validation' then
        raise exception 'Pending SPARKs suggestion must persist with validation_status=pending_validation';
      end if;
    end if;

    if new.status in ('approved', 'planned', 'in_progress', 'completed') then
      if new.suggestion_decision not in ('accepted', 'accepted_with_adjustments') then
        raise exception 'SPARKs suggestion cannot advance to portfolio execution before user acceptance';
      end if;
      if new.validation_status not in ('validated', 'validated_with_adjustments') then
        raise exception 'SPARKs suggestion cannot advance to portfolio execution before validation';
      end if;
    end if;

    if new.suggestion_decision in ('accepted', 'accepted_with_adjustments', 'rejected') then
      if new.suggestion_decided_at is null then
        raise exception 'Resolved SPARKs suggestion requires suggestion_decided_at';
      end if;
      if new.suggestion_decided_by is null then
        raise exception 'Resolved SPARKs suggestion requires suggestion_decided_by';
      end if;
    end if;

    if new.suggestion_decision = 'rejected' then
      if new.status <> 'proposed' then
        raise exception 'Rejected SPARKs suggestion must remain outside portfolio execution with status=proposed';
      end if;
      if new.validation_status <> 'rejected' then
        raise exception 'Rejected SPARKs suggestion must persist with validation_status=rejected';
      end if;
    end if;
  end if;

  if tg_op = 'UPDATE' and old.proposal_origin = 'sparks_suggestion' then
    if new.proposal_origin is distinct from old.proposal_origin then
      raise exception 'SPARKs suggestion proposal_origin is immutable';
    end if;
    if new.suggested_by_module is distinct from old.suggested_by_module then
      raise exception 'SPARKs suggestion suggested_by_module is immutable';
    end if;
    if new.suggestion_generated_at is distinct from old.suggestion_generated_at then
      raise exception 'SPARKs suggestion suggestion_generated_at is immutable';
    end if;
    if new.proposal_source_reference is distinct from old.proposal_source_reference then
      raise exception 'SPARKs suggestion proposal_source_reference is immutable';
    end if;
    if new.suggestion_snapshot is distinct from old.suggestion_snapshot then
      raise exception 'Original SPARKs suggestion_snapshot is immutable';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_skpe_sparks_suggested_initiative_governance
  on public.skpe_initiatives;

create trigger trg_skpe_sparks_suggested_initiative_governance
before insert or update on public.skpe_initiatives
for each row execute function public.skpe_assert_sparks_suggested_initiative_governance();

create or replace view public.skpe_sparks_suggested_initiative_readiness
with (security_invoker = true)
as
select
  i.id as initiative_id,
  i.organization_id,
  i.project_id,
  i.code as initiative_code,
  i.name as initiative_name,
  i.status,
  i.validation_status,
  i.proposal_origin,
  i.proposal_source_reference,
  i.suggested_by_module,
  i.suggestion_generated_at,
  i.suggestion_decision,
  i.suggestion_decided_at,
  i.suggestion_decided_by,
  i.suggestion_curation_notes,
  case
    when i.proposal_origin = 'sparks_suggestion' and i.suggestion_decision = 'pending' then 'Rascunho'
    when i.suggestion_decision = 'accepted_with_adjustments' then 'Aceita com ajustes'
    when i.suggestion_decision = 'accepted' then 'Aceita'
    when i.suggestion_decision = 'rejected' then 'Rejeitada'
    else i.status
  end as ui_status,
  array_remove(array[
    case when nullif(btrim(coalesce(i.what_text, '')), '') is null then 'what' end,
    case when nullif(btrim(coalesce(i.why_text, '')), '') is null then 'why' end,
    case when nullif(btrim(coalesce(i.where_text, '')), '') is null then 'where' end,
    case when nullif(btrim(coalesce(i.when_text, '')), '') is null then 'when' end,
    case when nullif(btrim(coalesce(i.who_text, '')), '') is null then 'who' end,
    case when nullif(btrim(coalesce(i.how_text, '')), '') is null then 'how' end,
    case when nullif(btrim(coalesce(i.how_much_text, '')), '') is null then 'how_much' end
  ], null) as pending_5w2h_fields,
  (
    nullif(btrim(coalesce(i.what_text, '')), '') is not null and
    nullif(btrim(coalesce(i.why_text, '')), '') is not null and
    nullif(btrim(coalesce(i.where_text, '')), '') is not null and
    nullif(btrim(coalesce(i.when_text, '')), '') is not null and
    nullif(btrim(coalesce(i.who_text, '')), '') is not null and
    nullif(btrim(coalesce(i.how_text, '')), '') is not null and
    nullif(btrim(coalesce(i.how_much_text, '')), '') is not null
  ) as five_w_two_h_complete,
  coalesce(src.risk_codes, '{}'::text[]) as source_risk_codes,
  case
    when coalesce(cardinality(src.risk_codes), 0) > 0
      then 'Mitigação de Risco · ' || array_to_string(src.risk_codes, ' · ')
    else i.proposal_source_reference
  end as source_label
from public.skpe_initiatives i
left join lateral (
  select array_agg(distinct r.code order by r.code) as risk_codes
  from public.skpe_strategic_risk_mitigation_links l
  join public.skpe_strategic_risk_items r on r.id = l.strategic_risk_id
  where l.initiative_id = i.id
    and l.archived_at is null
    and l.link_status <> 'cancelled'
) src on true
where i.proposal_origin = 'sparks_suggestion'
  and i.archived_at is null;

comment on column public.skpe_initiatives.suggestion_snapshot is
  'Immutable original SPARKs suggestion used to compare the generated proposal with later user curation.';

comment on column public.skpe_initiatives.suggestion_decision is
  'User curation decision over a SPARKs-generated proposal. Rascunho is represented by pending + status proposed + validation pending_validation.';

comment on view public.skpe_sparks_suggested_initiative_readiness is
  'Read model for SPARKs suggested initiative drafts, preserving origin, user curation, 5W2H completeness, and source risk traceability.';

commit;
