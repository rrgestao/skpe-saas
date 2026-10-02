-- SPARKs / SK-PE - Faixas governadas para desvio de desempenho
begin;

insert into public.sparks_parameter_definitions (
  parameter_key, parameter_group, name, description, value_type,
  default_value, module_code, unit, validation_rule, metadata
) values
  ('SKPE.PERFORMANCE.DEVIATION.ADEQUATE_MAX_PERCENT', 'skpe.performance.deviation', 'Limite da faixa adequada',
   'Desvio absoluto maximo considerado dentro da faixa adequada de desempenho.',
   'number', '15'::jsonb, 'SK-PE', 'percent', '{"min":0,"max":100}'::jsonb,
   '{"source":"SPARKs PE default","ownership":"parameter_engine"}'::jsonb),
  ('SKPE.PERFORMANCE.DEVIATION.ATTENTION_MAX_PERCENT', 'skpe.performance.deviation', 'Limite da faixa de atencao',
   'Desvio absoluto maximo considerado na faixa de atencao; acima deste limite a leitura e critica.',
   'number', '30'::jsonb, 'SK-PE', 'percent', '{"min":0,"max":100}'::jsonb,
   '{"source":"SPARKs PE default","ownership":"parameter_engine"}'::jsonb)
on conflict (parameter_key) do update set
  parameter_group = excluded.parameter_group,
  name = excluded.name,
  description = excluded.description,
  value_type = excluded.value_type,
  default_value = excluded.default_value,
  module_code = excluded.module_code,
  unit = excluded.unit,
  validation_rule = excluded.validation_rule,
  metadata = excluded.metadata,
  updated_at = timezone('utc', now());

commit;
