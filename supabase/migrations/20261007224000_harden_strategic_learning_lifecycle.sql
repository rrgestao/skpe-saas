-- V1-B03: harden strategic-learning lifecycle used by Monitoring / RAE.
-- Preserve explicit human governance; no learning is accepted or incorporated automatically.

create or replace function public.transition_skpe_strategic_learning(
  p_learning_id uuid,
  p_action text,
  p_governance_decision text,
  p_change_reason text
)
returns text
language plpgsql
security definer
set search_path = ''
as $function$
declare
  previous_row public.skpe_strategic_learnings%rowtype;
  updated_row public.skpe_strategic_learnings%rowtype;
  action_value text := lower(trim(p_action));
  next_status text;
  decision_text text := nullif(trim(p_governance_decision), '');
begin
  perform public.skpe_assert_reason(p_change_reason);

  select *
    into previous_row
  from public.skpe_strategic_learnings
  where id = p_learning_id
  for update;

  if not found then
    raise exception 'Aprendizado estratégico não encontrado.' using errcode = '22023';
  end if;

  if action_value = 'incorporate' then
    if not public.can_ratify_skpe_governance(previous_row.organization_id) then
      raise exception 'Acesso negado para incorporar aprendizado.' using errcode = '42501';
    end if;
    if previous_row.status <> 'accepted' then
      raise exception 'Somente aprendizado aceito pode ser incorporado.' using errcode = '55000';
    end if;
    if length(coalesce(decision_text, '')) < 10 then
      raise exception 'A incorporação exige decisão de governança explícita.' using errcode = '22023';
    end if;
    next_status := 'incorporated';
  else
    if not public.can_manage_skpe_governance(previous_row.organization_id) then
      raise exception 'Acesso negado para transicionar aprendizado.' using errcode = '42501';
    end if;

    next_status := case action_value
      when 'analyze' then 'under_analysis'
      when 'accept' then 'accepted'
      when 'reject' then 'rejected'
      when 'archive' then 'archived'
      when 'reopen' then 'identified'
      else null
    end;

    if next_status is null then
      raise exception 'Ação inválida para aprendizado estratégico.' using errcode = '22023';
    end if;

    if action_value = 'analyze' and previous_row.status <> 'identified' then
      raise exception 'Somente aprendizado identificado pode ser encaminhado para análise.' using errcode = '55000';
    end if;

    if action_value in ('accept', 'reject') and previous_row.status <> 'under_analysis' then
      raise exception 'Aceite ou rejeição exige aprendizado em análise.' using errcode = '55000';
    end if;

    if action_value = 'reopen' and previous_row.status not in ('rejected', 'archived') then
      raise exception 'Somente aprendizado rejeitado ou arquivado pode ser reaberto.' using errcode = '55000';
    end if;

    if action_value = 'archive' and previous_row.status not in ('identified', 'under_analysis', 'rejected') then
      raise exception 'Somente aprendizado não incorporado pode ser arquivado nesta transição.' using errcode = '55000';
    end if;

    if action_value = 'accept'
       and previous_row.impact_level in ('high', 'critical')
       and length(coalesce(decision_text, '')) < 10 then
      raise exception 'Aprendizado de alto impacto exige decisão de governança explícita para aceite.' using errcode = '22023';
    end if;
  end if;

  update public.skpe_strategic_learnings
  set
    status = next_status,
    governance_decision = coalesce(decision_text, governance_decision),
    incorporated_at = case
      when next_status = 'incorporated' then timezone('utc', now())
      else incorporated_at
    end,
    incorporated_by = case
      when next_status = 'incorporated' then auth.uid()
      else incorporated_by
    end,
    updated_by = auth.uid(),
    updated_at = timezone('utc', now())
  where id = previous_row.id
  returning * into updated_row;

  perform public.skpe_record_operational_audit(
    updated_row.organization_id,
    updated_row.project_id,
    'strategic_learning',
    updated_row.id,
    'fe08.strategic_learning_' || action_value,
    p_change_reason,
    to_jsonb(previous_row),
    to_jsonb(updated_row)
  );

  return updated_row.status;
end;
$function$;

comment on function public.transition_skpe_strategic_learning(uuid,text,text,text) is
  'Governed strategic-learning lifecycle: identified -> under_analysis -> accepted/rejected -> incorporated, with controlled reopen/archive and explicit human governance decisions.';
