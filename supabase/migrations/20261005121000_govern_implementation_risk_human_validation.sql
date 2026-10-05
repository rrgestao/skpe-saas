-- Govern human validation of implementation risks used by PEM-04.04.
-- No risk is accepted, closed or mitigated automatically.

create or replace function public.transition_skpe_initiative_risk_validation(
  p_risk_id uuid,
  p_action text,
  p_decision_notes text,
  p_change_reason text
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $function$
declare
  risk_row public.skpe_initiative_risks%rowtype;
  previous_data jsonb;
  next_validation_status text;
  score integer;
  acceptance_reason text;
  new_data jsonb;
begin
  if auth.uid() is null then
    raise exception using errcode='42501', message='Usuário não autenticado.';
  end if;

  perform public.skpe_assert_reason(p_change_reason);

  select * into risk_row
  from public.skpe_initiative_risks
  where id=p_risk_id
    and archived_at is null
  for update;

  if risk_row.id is null then
    raise exception using errcode='22023', message='Risco não encontrado.';
  end if;

  if p_action='submit_validation' then
    if not public.can_manage_skpe_initiatives(risk_row.organization_id) then
      raise exception using errcode='42501', message='Acesso negado para submeter o risco à validação.';
    end if;

    if risk_row.validation_status<>'draft' then
      raise exception using errcode='55000', message='Somente risco em elaboração pode ser submetido à validação.';
    end if;

    if risk_row.probability is null or risk_row.impact is null then
      raise exception using errcode='55000', message='Informe probabilidade e impacto antes de submeter o risco à validação.';
    end if;

    score:=coalesce(risk_row.inherent_score,risk_row.probability*risk_row.impact);

    if score>=15 and (
      risk_row.owner_user_id is null
      or risk_row.response_type is null
      or length(trim(coalesce(risk_row.response_plan,'')))<10
      or risk_row.response_due_date is null
    ) then
      raise exception using
        errcode='55000',
        message='Risco alto ou crítico exige responsável, resposta, plano e prazo antes da validação.';
    end if;

    acceptance_reason:=trim(coalesce(risk_row.metadata->>'acceptanceReason',''));
    if risk_row.response_type='accept' and length(acceptance_reason)<10 then
      raise exception using
        errcode='55000',
        message='Risco proposto para aceitação exige justificativa explícita antes da validação.';
    end if;

    next_validation_status:='pending_validation';

  elsif p_action in ('validate','return_for_adjustments') then
    if not public.can_validate_skpe_formulation(risk_row.organization_id) then
      raise exception using errcode='42501', message='Acesso negado para registrar a decisão de validação do risco.';
    end if;

    if risk_row.validation_status<>'pending_validation' then
      raise exception using errcode='55000', message='O risco precisa estar aguardando validação para receber esta decisão.';
    end if;

    if length(trim(coalesce(p_decision_notes,'')))<10 then
      raise exception using errcode='22023', message='Registre a justificativa da decisão com pelo menos 10 caracteres.';
    end if;

    next_validation_status:=case
      when p_action='validate' then 'validated'
      else 'draft'
    end;
  else
    raise exception using errcode='22023', message='Ação de validação de risco inválida.';
  end if;

  previous_data:=to_jsonb(risk_row);

  update public.skpe_initiative_risks
  set
    validation_status=next_validation_status,
    metadata=coalesce(metadata,'{}'::jsonb) || jsonb_build_object(
      'validationDecisionNotes',nullif(trim(coalesce(p_decision_notes,'')),''),
      'validationDecisionAt',timezone('utc',now()),
      'validationDecisionBy',auth.uid(),
      'humanValidationRequired',true
    ),
    updated_at=timezone('utc',now()),
    updated_by=auth.uid()
  where id=risk_row.id
  returning to_jsonb(skpe_initiative_risks) into new_data;

  perform public.skpe_record_operational_audit(
    risk_row.organization_id,
    risk_row.project_id,
    'initiative_risk',
    risk_row.id,
    case
      when p_action='submit_validation' then 'fe07.risk_submitted_for_validation'
      when p_action='validate' then 'fe07.risk_validated'
      else 'fe07.risk_returned_for_adjustment'
    end,
    p_change_reason,
    previous_data,
    new_data
  );

  return jsonb_build_object(
    'riskId',risk_row.id,
    'validationStatus',next_validation_status,
    'institutionalDecisionCreated',false,
    'automaticRiskAcceptance',false
  );
end;
$function$;

revoke all on function public.transition_skpe_initiative_risk_validation(uuid,text,text,text)
from public,anon;
grant execute on function public.transition_skpe_initiative_risk_validation(uuid,text,text,text)
to authenticated,service_role;

comment on function public.transition_skpe_initiative_risk_validation(uuid,text,text,text) is
'Human validation workflow for implementation risks. Submit requires measured risk; high/critical risk additionally requires owner, response plan and due date. Validation never accepts or mitigates risk automatically.';
