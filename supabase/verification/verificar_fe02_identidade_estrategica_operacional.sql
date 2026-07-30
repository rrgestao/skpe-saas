-- ============================================================
-- FE-02 — Verificação consolidada
-- Identidade Estratégica Operacional
-- SOMENTE LEITURA — retorna um único grid.
-- ============================================================

with
expected_indexes(index_name) as (
  values
    ('idx_skpe_value_behaviors_value'),
    ('idx_skpe_identity_items_validation')
),
expected_functions(function_signature) as (
  values
    ('public.ensure_skpe_strategic_identity(uuid)'),
    ('public.update_skpe_strategic_identity(uuid,text,jsonb,text)'),
    ('public.upsert_skpe_identity_item(uuid,text,text,text,integer,jsonb,text)'),
    ('public.delete_skpe_identity_item(uuid,text,text)'),
    ('public.upsert_skpe_strategic_value(uuid,text,text,text,uuid,integer,text,jsonb,text)'),
    ('public.archive_skpe_strategic_value(uuid,text)'),
    ('public.upsert_skpe_value_behavior(uuid,text,text,uuid,integer,jsonb,text)'),
    ('public.delete_skpe_value_behavior(uuid,text)'),
    ('public.get_skpe_identity_readiness(uuid)'),
    ('public.transition_skpe_strategic_identity(uuid,text,text,text)'),
    ('public.skpe_guard_formulation_identity_ready()'),
    ('public.get_skpe_strategic_identity(uuid)'),
    ('public.get_skpe_identity_audit(uuid)')
),
public_rpc_functions(function_signature) as (
  values
    ('public.update_skpe_strategic_identity(uuid,text,jsonb,text)'),
    ('public.upsert_skpe_identity_item(uuid,text,text,text,integer,jsonb,text)'),
    ('public.delete_skpe_identity_item(uuid,text,text)'),
    ('public.upsert_skpe_strategic_value(uuid,text,text,text,uuid,integer,text,jsonb,text)'),
    ('public.archive_skpe_strategic_value(uuid,text)'),
    ('public.upsert_skpe_value_behavior(uuid,text,text,uuid,integer,jsonb,text)'),
    ('public.delete_skpe_value_behavior(uuid,text)'),
    ('public.get_skpe_identity_readiness(uuid)'),
    ('public.transition_skpe_strategic_identity(uuid,text,text,text)'),
    ('public.get_skpe_strategic_identity(uuid)'),
    ('public.get_skpe_identity_audit(uuid)')
),
checks as (
  select
    'INDICE'::text as check_group,
    expected_indexes.index_name as check_item,
    'EXISTE'::text as expected_value,
    case when exists (
      select 1
      from pg_indexes index_info
      where index_info.schemaname = 'public'
        and index_info.indexname = expected_indexes.index_name
    ) then 'EXISTE' else 'AUSENTE' end as actual_value
  from expected_indexes

  union all

  select
    'FUNCAO',
    expected_functions.function_signature,
    'EXISTE',
    case when to_regprocedure(expected_functions.function_signature) is not null
      then 'EXISTE'
      else 'AUSENTE'
    end
  from expected_functions

  union all

  select
    'SEGURANCA_FUNCAO',
    expected_functions.function_signature,
    'SECURITY DEFINER',
    case when exists (
      select 1
      from pg_proc procedure_info
      where procedure_info.oid = to_regprocedure(expected_functions.function_signature)
        and procedure_info.prosecdef
    ) then 'SECURITY DEFINER' else 'REVISAR' end
  from expected_functions

  union all

  select
    'EXECUCAO_AUTHENTICATED',
    public_rpc_functions.function_signature,
    'CONCEDIDA',
    case when has_function_privilege(
      'authenticated',
      to_regprocedure(public_rpc_functions.function_signature),
      'EXECUTE'
    ) then 'CONCEDIDA' else 'AUSENTE' end
  from public_rpc_functions

  union all

  select
    'FUNCAO_INTERNA',
    'authenticated não executa ensure_skpe_strategic_identity',
    'NAO',
    case when has_function_privilege(
      'authenticated',
      to_regprocedure('public.ensure_skpe_strategic_identity(uuid)'),
      'EXECUTE'
    ) then 'SIM' else 'NAO' end

  union all

  select
    'FUNCAO_INTERNA',
    'authenticated não executa skpe_guard_formulation_identity_ready',
    'NAO',
    case when has_function_privilege(
      'authenticated',
      to_regprocedure('public.skpe_guard_formulation_identity_ready()'),
      'EXECUTE'
    ) then 'SIM' else 'NAO' end

  union all

  select
    'TRIGGER',
    'skpe_strategic_formulations_guard_identity_ready',
    'EXISTE',
    case when exists (
      select 1
      from pg_trigger trigger_info
      where trigger_info.tgrelid =
        'public.skpe_strategic_formulations'::regclass
        and trigger_info.tgname =
          'skpe_strategic_formulations_guard_identity_ready'
        and not trigger_info.tgisinternal
    ) then 'EXISTE' else 'AUSENTE' end

  union all

  select
    'REGRA_METODOLOGICA',
    'Missão obrigatória na prontidão',
    'SIM',
    case when pg_get_functiondef(
      to_regprocedure('public.get_skpe_identity_readiness(uuid)')
    ) ilike '%MISSION_MISSING%'
    then 'SIM' else 'NAO' end

  union all

  select
    'REGRA_METODOLOGICA',
    'Visão obrigatória na prontidão',
    'SIM',
    case when pg_get_functiondef(
      to_regprocedure('public.get_skpe_identity_readiness(uuid)')
    ) ilike '%VISION_MISSING%'
    then 'SIM' else 'NAO' end

  union all

  select
    'REGRA_METODOLOGICA',
    'Comportamento esperado obrigatório por Valor',
    'SIM',
    case when pg_get_functiondef(
      to_regprocedure('public.get_skpe_identity_readiness(uuid)')
    ) ilike '%VALUE_WITHOUT_EXPECTED_BEHAVIOR%'
    then 'SIM' else 'NAO' end

  union all

  select
    'REGRA_METODOLOGICA',
    'Comportamento incompatível obrigatório por Valor',
    'SIM',
    case when pg_get_functiondef(
      to_regprocedure('public.get_skpe_identity_readiness(uuid)')
    ) ilike '%VALUE_WITHOUT_INCOMPATIBLE_BEHAVIOR%'
    then 'SIM' else 'NAO' end

  union all

  select
    'PRIVILEGIO_DIRETO',
    'authenticated pode inserir diretamente em skpe_strategic_identity_items',
    'NAO',
    case when has_table_privilege(
      'authenticated',
      'public.skpe_strategic_identity_items',
      'INSERT'
    ) then 'SIM' else 'NAO' end

  union all

  select
    'PRIVILEGIO_DIRETO',
    'authenticated pode atualizar diretamente skpe_strategic_values',
    'NAO',
    case when has_table_privilege(
      'authenticated',
      'public.skpe_strategic_values',
      'UPDATE'
    ) then 'SIM' else 'NAO' end

  union all

  select
    'PRIVILEGIO_DIRETO',
    'authenticated pode excluir diretamente comportamentos',
    'NAO',
    case when has_table_privilege(
      'authenticated',
      'public.skpe_strategic_value_behaviors',
      'DELETE'
    ) then 'SIM' else 'NAO' end

  union all

  select
    'INTEGRIDADE',
    'Identidades duplicadas por Formulação',
    '0',
    count(*)::text
  from (
    select formulation_id
    from public.skpe_strategic_identity
    group by formulation_id
    having count(*) > 1
  ) duplicated_identity

  union all

  select
    'INTEGRIDADE',
    'Itens de Identidade fora do escopo da Formulação',
    '0',
    count(*)::text
  from public.skpe_strategic_identity_items item
  join public.skpe_strategic_formulations formulation
    on formulation.id = item.formulation_id
  where item.organization_id <> formulation.organization_id
     or item.project_id <> formulation.project_id

  union all

  select
    'INTEGRIDADE',
    'Valores fora do escopo da Formulação',
    '0',
    count(*)::text
  from public.skpe_strategic_values value
  join public.skpe_strategic_formulations formulation
    on formulation.id = value.formulation_id
  where value.organization_id <> formulation.organization_id
     or value.project_id <> formulation.project_id

  union all

  select
    'INTEGRIDADE',
    'Comportamentos fora do escopo do Valor',
    '0',
    count(*)::text
  from public.skpe_strategic_value_behaviors behavior
  join public.skpe_strategic_values value
    on value.id = behavior.strategic_value_id
  where behavior.formulation_id <> value.formulation_id
     or behavior.organization_id <> value.organization_id
     or behavior.project_id <> value.project_id

  union all

  select
    'SITUACAO',
    'Pacotes de Identidade atualmente cadastrados',
    count(*)::text,
    count(*)::text
  from public.skpe_strategic_identity
)
select
  check_group,
  check_item,
  expected_value,
  actual_value,
  case
    when expected_value = actual_value then 'OK'
    else 'REVISAR'
  end as verification_status
from checks
order by
  case check_group
    when 'REGRA_METODOLOGICA' then 1
    when 'INDICE' then 2
    when 'FUNCAO' then 3
    when 'SEGURANCA_FUNCAO' then 4
    when 'EXECUCAO_AUTHENTICATED' then 5
    when 'FUNCAO_INTERNA' then 6
    when 'TRIGGER' then 7
    when 'PRIVILEGIO_DIRETO' then 8
    when 'INTEGRIDADE' then 9
    else 10
  end,
  check_item;
