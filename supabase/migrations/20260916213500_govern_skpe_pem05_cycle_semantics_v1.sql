-- SPARKs PE - Semantica v1 do ciclo PEM-05 Monitoramento e Aprendizado.
-- PEM-05 e concorrente/ciclica; nao deve ser repartida em blocos sequenciais.
begin;

with latest as (
  select v.id from public.skpe_methodology_template_versions v
  join public.skpe_methodology_templates t on t.id=v.template_id
  where t.code='SKPE-OFICIAL' and t.is_recommended=true and v.status='published'
  order by v.effective_from desc nulls last,v.created_at desc limit 1
), modes(code,execution_mode) as (
  values
    ('PEM-05.01','continuous'),
    ('PEM-05.02','recurring_review'),
    ('PEM-05.03','continuous_learning'),
    ('PEM-05.04','event_driven')
)
update public.skpe_methodology_template_items i
set metadata=coalesce(i.metadata,'{}'::jsonb)||jsonb_build_object(
  'cadence_role','post_delivery_cycle_phase',
  'cycle_parameter','SKPE.JOURNEY.POST_DELIVERY_FOLLOWUP',
  'execution_mode',m.execution_mode,
  'frequency_status','pending_governance_decision',
  'cadence_source','SPARKs PE monitoring cycle semantics v1'
)
from latest,modes m
where i.template_version_id=latest.id and i.code=m.code and i.item_type='phase';
with latest as (
  select v.id from public.skpe_methodology_template_versions v
  join public.skpe_methodology_templates t on t.id=v.template_id
  where t.code='SKPE-OFICIAL' and t.is_recommended=true and v.status='published'
  order by v.effective_from desc nulls last,v.created_at desc limit 1
)
update public.skpe_methodology_template_items i
set metadata=coalesce(i.metadata,'{}'::jsonb)||jsonb_build_object(
  'cadence_role','post_delivery_cycle_gate',
  'cycle_parameter','SKPE.JOURNEY.POST_DELIVERY_FOLLOWUP',
  'execution_mode','cycle_close_milestone',
  'cadence_source','SPARKs PE monitoring cycle semantics v1'
)
from latest
where i.template_version_id=latest.id and i.code='PEM-05.GATE' and i.item_type='gate';

comment on function public.initialize_skpe_journey_business_day_baseline(uuid) is
  'Cria Linha de Base Proposta: PEM-00..PEM-04 por Fase; Gates como marcos; PEM-05 como ciclo pos-entrega concorrente governado por POST_DELIVERY_FOLLOWUP.';

commit;
