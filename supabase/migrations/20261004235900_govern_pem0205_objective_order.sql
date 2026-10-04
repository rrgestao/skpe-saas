-- Reorder Strategic Objectives during PEM-02.05 without resetting approvals.
-- This operation changes only display order metadata and audit fields.

create or replace function public.reorder_skpe_strategic_objective_for_map(
  target_objective_id uuid,
  target_display_order integer,
  change_reason text
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $function$
declare
  objective_row public.skpe_strategic_objectives%rowtype;
  formulation_row public.skpe_strategic_formulations%rowtype;
  journey_row public.skpe_journey_items%rowtype;
  before_row jsonb;
  after_row jsonb;
begin
  if auth.uid() is null then
    raise exception using errcode='42501', message='Operação exige usuário autenticado.';
  end if;

  if target_display_order is null or target_display_order < 0 then
    raise exception using errcode='22023', message='A ordem de exibição deve ser zero ou positiva.';
  end if;

  if length(trim(coalesce(change_reason,''))) < 10 then
    raise exception using errcode='22023', message='Informe justificativa com pelo menos 10 caracteres.';
  end if;

  select * into objective_row
  from public.skpe_strategic_objectives
  where id=target_objective_id
  for update;

  if objective_row.id is null then
    raise exception using errcode='22023', message='Objetivo Estratégico não encontrado.';
  end if;

  select * into formulation_row
  from public.skpe_strategic_formulations
  where id=objective_row.formulation_id;

  if formulation_row.id is null then
    raise exception using errcode='55000', message='Formulação Estratégica do Objetivo não encontrada.';
  end if;

  if not public.can_manage_skpe_formulation(formulation_row.organization_id) then
    raise exception using errcode='42501', message='Acesso negado para ordenar Objetivos Estratégicos.';
  end if;

  select * into journey_row
  from public.skpe_journey_items
  where project_id=formulation_row.project_id
    and code='PEM-02.05'
    and archived_at is null
  limit 1;

  if journey_row.id is null or journey_row.status<>'in_progress' or not journey_row.is_current then
    raise exception using errcode='55000',
      message='A ordem do Mapa só pode ser alterada durante PEM-02.05 em execução.';
  end if;

  before_row:=to_jsonb(objective_row);

  update public.skpe_strategic_objectives
  set
    metadata=jsonb_set(
      coalesce(metadata,'{}'::jsonb),
      '{displayOrder}',
      to_jsonb(target_display_order),
      true
    ),
    updated_at=timezone('utc',now()),
    updated_by=auth.uid()
  where id=objective_row.id
  returning to_jsonb(public.skpe_strategic_objectives.*) into after_row;

  perform public.skpe_record_operational_audit(
    formulation_row.organization_id,
    formulation_row.project_id,
    'strategic_objective',
    objective_row.id,
    'strategic_map_objective_reordered',
    trim(change_reason),
    before_row,
    after_row
  );

  return jsonb_build_object(
    'objectiveId',objective_row.id,
    'code',objective_row.code,
    'displayOrder',target_display_order,
    'validationStatusPreserved',objective_row.validation_status,
    'approvedAtPreserved',objective_row.approved_at,
    'approvedByPreserved',objective_row.approved_by
  );
end;
$function$;

revoke all on function public.reorder_skpe_strategic_objective_for_map(uuid,integer,text)
from public,anon;

grant execute on function public.reorder_skpe_strategic_objective_for_map(uuid,integer,text)
to authenticated,service_role;

comment on function public.reorder_skpe_strategic_objective_for_map(uuid,integer,text) is
'Reorders a Strategic Objective during PEM-02.05 without resetting or recreating its prior human approval.';
