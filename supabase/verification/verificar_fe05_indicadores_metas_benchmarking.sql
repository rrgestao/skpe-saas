-- ============================================================
-- FE-05 — Verificação consolidada
-- Indicadores Estratégicos, Metas de Longo Prazo e Benchmarking
-- SOMENTE LEITURA — retorna um único grid.
-- ============================================================

with
expected_indexes(index_name) as (
  values
    ('idx_skpe_indicator_packages_scope'),
    ('idx_skpe_indicators_objective_readiness'),
    ('idx_skpe_targets_readiness'),
    ('idx_skpe_benchmarks_readiness')
),
expected_functions(function_signature, api_class) as (
  values
    ('public.ensure_skpe_indicator_package(uuid)', 'internal'),
    ('public.skpe_invalidate_indicator_package(uuid,text)', 'internal'),
    ('public.skpe_guard_formulation_indicators_ready()', 'internal'),
    ('public.configure_skpe_indicator_package(uuid,boolean,boolean,boolean,boolean,integer,numeric,integer,jsonb,text)', 'public'),
    ('public.upsert_skpe_strategic_indicator(uuid,text,text,text,uuid,text,text,text,text,text,text,numeric,date,uuid,text,text,boolean,text,boolean,text,uuid,jsonb,text)', 'public'),
    ('public.archive_skpe_strategic_indicator(uuid,text)', 'public'),
    ('public.upsert_skpe_indicator_target(uuid,text,date,date,numeric,numeric,numeric,numeric,numeric,uuid,text,uuid,jsonb,text)', 'public'),
    ('public.supersede_skpe_indicator_target(uuid,text)', 'public'),
    ('public.upsert_skpe_benchmark_reference(uuid,text,text,text,text,text,numeric,text,text,text,uuid,uuid,jsonb,text)', 'public'),
    ('public.transition_skpe_benchmark_reference(uuid,text,text,text)', 'public'),
    ('public.get_skpe_indicators_readiness(uuid)', 'public'),
    ('public.transition_skpe_indicator_package(uuid,text,text,text)', 'public'),
    ('public.get_skpe_indicators_package(uuid)', 'public'),
    ('public.get_skpe_indicators_audit(uuid)', 'public')
),
controlled_tables(table_name) as (
  values
    ('skpe_indicator_packages'),
    ('skpe_indicators'),
    ('skpe_indicator_targets'),
    ('skpe_benchmark_references')
),
checks as (
  select
    'TABELA'::text as check_group,
    'public.skpe_indicator_packages'::text as check_item,
    'EXISTE'::text as expected_value,
    case
      when to_regclass('public.skpe_indicator_packages') is not null then 'EXISTE'
      else 'AUSENTE'
    end::text as actual_value,
    null::text as details

  union all

  select
    'ESTRUTURA_REUTILIZADA',
    controlled_tables.table_name,
    'EXISTE',
    case
      when to_regclass('public.' || controlled_tables.table_name) is not null then 'EXISTE'
      else 'AUSENTE'
    end,
    case
      when controlled_tables.table_name = 'skpe_indicator_packages'
        then 'Cabeçalho de governança criado pela FE-05.'
      else 'Tabela preexistente reutilizada; não deve haver duplicação.'
    end
  from controlled_tables

  union all

  select
    'RLS',
    controlled_tables.table_name || ' com RLS habilitada',
    'SIM',
    case when exists (
      select 1
      from pg_class table_info
      join pg_namespace namespace_info
        on namespace_info.oid = table_info.relnamespace
      where namespace_info.nspname = 'public'
        and table_info.relname = controlled_tables.table_name
        and table_info.relkind in ('r', 'p')
        and table_info.relrowsecurity
    ) then 'SIM' else 'NAO' end,
    null
  from controlled_tables

  union all

  select
    'RLS',
    controlled_tables.table_name || ' com política SELECT para authenticated',
    'SIM',
    case when exists (
      select 1
      from pg_policies policy_info
      where policy_info.schemaname = 'public'
        and policy_info.tablename = controlled_tables.table_name
        and policy_info.cmd = 'SELECT'
        and policy_info.roles::text ilike '%authenticated%'
    ) then 'SIM' else 'NAO' end,
    null
  from controlled_tables

  union all

  select
    'RLS',
    controlled_tables.table_name || ' sem política DML para authenticated/public',
    '0',
    count(policy_info.policyname)::text,
    string_agg(policy_info.policyname || '[' || policy_info.cmd || ']', ', ')
  from controlled_tables
  left join pg_policies policy_info
    on policy_info.schemaname = 'public'
   and policy_info.tablename = controlled_tables.table_name
   and policy_info.cmd in ('INSERT', 'UPDATE', 'DELETE', 'ALL')
   and (
     policy_info.roles::text ilike '%authenticated%'
     or policy_info.roles::text ilike '%public%'
   )
  group by controlled_tables.table_name

  union all

  select
    'PRIVILEGIO_TABELA',
    controlled_tables.table_name || ' sem DML direto para authenticated',
    'NEGADO',
    case when
      has_table_privilege('authenticated', 'public.' || controlled_tables.table_name, 'INSERT')
      or has_table_privilege('authenticated', 'public.' || controlled_tables.table_name, 'UPDATE')
      or has_table_privilege('authenticated', 'public.' || controlled_tables.table_name, 'DELETE')
      then 'CONCEDIDO'
      else 'NEGADO'
    end,
    null
  from controlled_tables

  union all

  select
    'PRIVILEGIO_TABELA',
    controlled_tables.table_name || ' com SELECT para authenticated',
    'CONCEDIDO',
    case when has_table_privilege(
      'authenticated',
      'public.' || controlled_tables.table_name,
      'SELECT'
    ) then 'CONCEDIDO' else 'NEGADO' end,
    null
  from controlled_tables

  union all

  select
    'RLS',
    'Política SELECT do pacote FE-05 usa autorização da Formulação',
    'SIM',
    case when exists (
      select 1
      from pg_policies policy_info
      where policy_info.schemaname = 'public'
        and policy_info.tablename = 'skpe_indicator_packages'
        and policy_info.cmd = 'SELECT'
        and policy_info.roles::text ilike '%authenticated%'
        and coalesce(policy_info.qual, '') ilike '%can_view_skpe_formulation%'
    ) then 'SIM' else 'NAO' end,
    null

  union all

  select
    'INDICE',
    expected_indexes.index_name,
    'EXISTE',
    case when exists (
      select 1
      from pg_indexes index_info
      where index_info.schemaname = 'public'
        and index_info.indexname = expected_indexes.index_name
    ) then 'EXISTE' else 'AUSENTE' end,
    null
  from expected_indexes

  union all

  select
    'FUNCAO',
    expected_functions.function_signature,
    'EXISTE',
    case when to_regprocedure(expected_functions.function_signature) is not null
      then 'EXISTE'
      else 'AUSENTE'
    end,
    expected_functions.api_class
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
    ) then 'SECURITY DEFINER' else 'REVISAR' end,
    expected_functions.api_class
  from expected_functions

  union all

  select
    'SEARCH_PATH',
    expected_functions.function_signature,
    'VAZIO_CONTROLADO',
    case when exists (
      select 1
      from pg_proc procedure_info
      where procedure_info.oid = to_regprocedure(expected_functions.function_signature)
        and exists (
          select 1
          from unnest(coalesce(procedure_info.proconfig, array[]::text[])) config
          where config in ('search_path=', 'search_path=""')
        )
    ) then 'VAZIO_CONTROLADO' else 'REVISAR' end,
    null
  from expected_functions

  union all

  select
    'EXECUCAO_AUTHENTICATED',
    expected_functions.function_signature,
    case when expected_functions.api_class = 'public' then 'CONCEDIDA' else 'NEGADA' end,
    case
      when has_function_privilege(
        'authenticated',
        to_regprocedure(expected_functions.function_signature),
        'EXECUTE'
      ) then 'CONCEDIDA'
      else 'NEGADA'
    end,
    expected_functions.api_class
  from expected_functions

  union all

  select
    'TRIGGER',
    'updated_at das tabelas operacionais da FE-05',
    '3',
    count(*)::text,
    string_agg(trigger_info.tgname, ', ' order by trigger_info.tgname)
  from pg_trigger trigger_info
  where not trigger_info.tgisinternal
    and trigger_info.tgname in (
      'skpe_indicators_set_updated_at',
      'skpe_indicator_targets_set_updated_at',
      'skpe_benchmark_references_set_updated_at'
    )

  union all

  select
    'TRIGGER',
    'skpe_indicator_packages_guard_formulation',
    'EXISTE',
    case when exists (
      select 1
      from pg_trigger trigger_info
      where trigger_info.tgrelid = 'public.skpe_indicator_packages'::regclass
        and trigger_info.tgname = 'skpe_indicator_packages_guard_formulation'
        and not trigger_info.tgisinternal
    ) then 'EXISTE' else 'AUSENTE' end,
    'Proteção transversal da editabilidade da Formulação.'

  union all

  select
    'TRIGGER',
    'skpe_strategic_formulations_guard_indicators_ready',
    'EXISTE',
    case when exists (
      select 1
      from pg_trigger trigger_info
      where trigger_info.tgrelid = 'public.skpe_strategic_formulations'::regclass
        and trigger_info.tgname = 'skpe_strategic_formulations_guard_indicators_ready'
        and not trigger_info.tgisinternal
    ) then 'EXISTE' else 'AUSENTE' end,
    'Bloqueia avanço enquanto a FE-05 estiver incompleta ou não validada.'

  union all

  select
    'CONSTRAINT',
    'Situações do pacote FE-05',
    'in_elaboration,pending_validation,validated',
    case when exists (
      select 1
      from pg_constraint constraint_info
      where constraint_info.conname = 'skpe_indicator_packages_status_check'
        and constraint_info.conrelid = 'public.skpe_indicator_packages'::regclass
        and pg_get_constraintdef(constraint_info.oid) ilike '%in_elaboration%'
        and pg_get_constraintdef(constraint_info.oid) ilike '%pending_validation%'
        and pg_get_constraintdef(constraint_info.oid) ilike '%validated%'
    ) then 'in_elaboration,pending_validation,validated' else 'REVISAR' end,
    null

  union all

  select
    'CONSTRAINT',
    'Unicidade do pacote por Formulação',
    'SIM',
    case when exists (
      select 1
      from pg_constraint constraint_info
      where constraint_info.conname = 'skpe_indicator_packages_unique'
        and constraint_info.conrelid = 'public.skpe_indicator_packages'::regclass
        and constraint_info.contype = 'u'
    ) then 'SIM' else 'NAO' end,
    null

  union all

  select
    'REGRA_METODOLOGICA',
    'Objetivo ativo sem Indicador é bloqueante',
    'SIM',
    case when pg_get_functiondef(
      to_regprocedure('public.get_skpe_indicators_readiness(uuid)')
    ) ilike '%OBJECTIVE_WITHOUT_INDICATOR%'
    then 'SIM' else 'NAO' end,
    null

  union all

  select
    'REGRA_METODOLOGICA',
    'Definição, fórmula, método, unidade, polaridade, frequência e fonte são verificadas',
    'SIM',
    case when
      pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_readiness(uuid)')) ilike '%INDICATOR_DEFINITION_MISSING%'
      and pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_readiness(uuid)')) ilike '%INDICATOR_FORMULA_MISSING%'
      and pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_readiness(uuid)')) ilike '%INDICATOR_CALCULATION_METHOD_MISSING%'
      and pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_readiness(uuid)')) ilike '%INDICATOR_UNIT_MISSING%'
      and pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_readiness(uuid)')) ilike '%INDICATOR_POLARITY_INVALID%'
      and pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_readiness(uuid)')) ilike '%INDICATOR_FREQUENCY_MISSING%'
      and pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_readiness(uuid)')) ilike '%INDICATOR_DATA_SOURCE_MISSING%'
    then 'SIM' else 'NAO' end,
    null

  union all

  select
    'REGRA_METODOLOGICA',
    'Linha de base é exigida conforme pacote ou sobrescrita do Indicador',
    'SIM',
    case when
      pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_readiness(uuid)')) ilike '%INDICATOR_BASELINE_MISSING%'
      and pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_readiness(uuid)')) ilike '%baselineRequired%'
      and pg_get_functiondef(to_regprocedure('public.configure_skpe_indicator_package(uuid,boolean,boolean,boolean,boolean,integer,numeric,integer,jsonb,text)')) ilike '%baseline_required%'
    then 'SIM' else 'NAO' end,
    null

  union all

  select
    'REGRA_METODOLOGICA',
    'Meta de Longo Prazo, polaridade e horizonte são bloqueantes',
    'SIM',
    case when
      pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_readiness(uuid)')) ilike '%INDICATOR_WITHOUT_LONG_TERM_TARGET%'
      and pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_readiness(uuid)')) ilike '%TARGET_POLARITY_MISMATCH%'
      and pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_readiness(uuid)')) ilike '%TARGET_OUTSIDE_FORMULATION_HORIZON%'
    then 'SIM' else 'NAO' end,
    null

  union all

  select
    'REGRA_ESCOPO',
    'Escopo de Indicadores, Metas e Benchmarking é validado',
    'SIM',
    case when
      pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_readiness(uuid)')) ilike '%INDICATOR_SCOPE_MISMATCH%'
      and pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_readiness(uuid)')) ilike '%TARGET_SCOPE_MISMATCH%'
      and pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_readiness(uuid)')) ilike '%BENCHMARK_SCOPE_MISMATCH%'
    then 'SIM' else 'NAO' end,
    null

  union all

  select
    'REGRA_DUPLICIDADE',
    'Duplicidades impeditivas são verificadas',
    'SIM',
    case when
      pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_readiness(uuid)')) ilike '%INDICATOR_DUPLICATE_NAME_IN_OBJECTIVE%'
      and pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_readiness(uuid)')) ilike '%BENCHMARK_DUPLICATE%'
      and pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_readiness(uuid)')) ilike '%MULTIPLE_LONG_TERM_TARGETS%'
    then 'SIM' else 'NAO' end,
    null

  union all

  select
    'REGRA_RECOMENDACAO',
    'Responsável, benchmarking, metas intermediárias, equilíbrio e coleta são recomendados',
    'SIM',
    case when
      pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_readiness(uuid)')) ilike '%INDICATOR_WITHOUT_OWNER%'
      and pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_readiness(uuid)')) ilike '%INDICATOR_WITHOUT_VERIFIED_BENCHMARK%'
      and pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_readiness(uuid)')) ilike '%INTERMEDIATE_TARGETS_MISSING%'
      and pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_readiness(uuid)')) ilike '%EXCESS_INDICATORS_PER_OBJECTIVE%'
      and pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_readiness(uuid)')) ilike '%FINANCIAL_INDICATOR_CONCENTRATION%'
      and pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_readiness(uuid)')) ilike '%COLLECTION_AUTOMATION_RECOMMENDED%'
      and pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_readiness(uuid)')) ilike '%BASELINE_OUTDATED%'
    then 'SIM' else 'NAO' end,
    null

  union all

  select
    'REGRA_METODOLOGICA',
    'FE-05 não antecipa OKRs, KRs ou Iniciativas',
    'SIM',
    case when
      pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_readiness(uuid)')) ilike '%keyResultIndicatorsRequiredInFe05%false%'
      and pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_readiness(uuid)')) ilike '%okrRequiredInFe05%false%'
      and pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_readiness(uuid)')) ilike '%initiativeRequiredInFe05%false%'
    then 'SIM' else 'NAO' end,
    null

  union all

  select
    'REGRA_GOVERNANCA',
    'Mutações invalidam a validação anterior do pacote',
    'SIM',
    case when
      pg_get_functiondef(to_regprocedure('public.upsert_skpe_strategic_indicator(uuid,text,text,text,uuid,text,text,text,text,text,text,numeric,date,uuid,text,text,boolean,text,boolean,text,uuid,jsonb,text)')) ilike '%skpe_invalidate_indicator_package%'
      and pg_get_functiondef(to_regprocedure('public.upsert_skpe_indicator_target(uuid,text,date,date,numeric,numeric,numeric,numeric,numeric,uuid,text,uuid,jsonb,text)')) ilike '%skpe_invalidate_indicator_package%'
      and pg_get_functiondef(to_regprocedure('public.upsert_skpe_benchmark_reference(uuid,text,text,text,text,text,numeric,text,text,text,uuid,uuid,jsonb,text)')) ilike '%skpe_invalidate_indicator_package%'
      and pg_get_functiondef(to_regprocedure('public.transition_skpe_benchmark_reference(uuid,text,text,text)')) ilike '%skpe_invalidate_indicator_package%'
    then 'SIM' else 'NAO' end,
    null

  union all

  select
    'REGRA_GOVERNANCA',
    'Situação de validação dos Indicadores acompanha o pacote',
    'SIM',
    case when
      pg_get_functiondef(to_regprocedure('public.transition_skpe_indicator_package(uuid,text,text,text)')) ilike '%validationStatus%pending_validation%'
      and pg_get_functiondef(to_regprocedure('public.transition_skpe_indicator_package(uuid,text,text,text)')) ilike '%validationStatus%validated%'
      and pg_get_functiondef(to_regprocedure('public.skpe_invalidate_indicator_package(uuid,text)')) ilike '%validationStatus%draft%'
    then 'SIM' else 'NAO' end,
    null

  union all

  select
    'REGRA_GOVERNANCA',
    'Fluxo de validação do pacote está completo',
    'SIM',
    case when
      pg_get_functiondef(to_regprocedure('public.transition_skpe_indicator_package(uuid,text,text,text)')) ilike '%submit_validation%'
      and pg_get_functiondef(to_regprocedure('public.transition_skpe_indicator_package(uuid,text,text,text)')) ilike '%validate%'
      and pg_get_functiondef(to_regprocedure('public.transition_skpe_indicator_package(uuid,text,text,text)')) ilike '%return_for_adjustments%'
    then 'SIM' else 'NAO' end,
    null

  union all

  select
    'REGRA_SEGURANCA',
    'RPCs de mutação exigem justificativa',
    'SIM',
    case when
      pg_get_functiondef(to_regprocedure('public.upsert_skpe_strategic_indicator(uuid,text,text,text,uuid,text,text,text,text,text,text,numeric,date,uuid,text,text,boolean,text,boolean,text,uuid,jsonb,text)')) ilike '%skpe_assert_reason%'
      and pg_get_functiondef(to_regprocedure('public.upsert_skpe_indicator_target(uuid,text,date,date,numeric,numeric,numeric,numeric,numeric,uuid,text,uuid,jsonb,text)')) ilike '%skpe_assert_reason%'
      and pg_get_functiondef(to_regprocedure('public.upsert_skpe_benchmark_reference(uuid,text,text,text,text,text,numeric,text,text,text,uuid,uuid,jsonb,text)')) ilike '%skpe_assert_reason%'
      and pg_get_functiondef(to_regprocedure('public.transition_skpe_indicator_package(uuid,text,text,text)')) ilike '%skpe_assert_reason%'
    then 'SIM' else 'NAO' end,
    null

  union all

  select
    'REGRA_SEGURANCA',
    'Verificação de benchmarking respeita autorização de validação sem exigir gestão',
    'SIM',
    case when
      pg_get_functiondef(to_regprocedure('public.transition_skpe_benchmark_reference(uuid,text,text,text)')) ilike '%can_validate_skpe_formulation%'
      and pg_get_functiondef(to_regprocedure('public.transition_skpe_benchmark_reference(uuid,text,text,text)')) not ilike '%perform public.skpe_assert_formulation_editable%'
      and pg_get_functiondef(to_regprocedure('public.transition_skpe_benchmark_reference(uuid,text,text,text)')) ilike '%formulation_status not in%'
    then 'SIM' else 'NAO' end,
    'Evita exigir cumulativamente a permissão manage de quem possui validate.'

  union all

  select
    'VERSIONAMENTO',
    'Clonagem existente inclui Indicadores, Metas e Benchmarking',
    'SIM',
    case when
      pg_get_functiondef(to_regprocedure('public.clone_skpe_formulation_content(uuid,uuid)')) ilike '%insert into public.skpe_indicators%'
      and pg_get_functiondef(to_regprocedure('public.clone_skpe_formulation_content(uuid,uuid)')) ilike '%insert into public.skpe_indicator_targets%'
      and pg_get_functiondef(to_regprocedure('public.clone_skpe_formulation_content(uuid,uuid)')) ilike '%insert into public.skpe_benchmark_references%'
    then 'SIM' else 'NAO' end,
    'A FE-05 não deve substituir a função de clonagem consolidada.'

  union all

  select
    'AUDITORIA',
    'Consulta da FE-05 usa skpe_operational_audit',
    'SIM',
    case when
      pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_audit(uuid)')) ilike '%skpe_operational_audit%'
      and pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_audit(uuid)')) ilike '%indicator_package%'
      and pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_audit(uuid)')) ilike '%strategic_indicator%'
      and pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_audit(uuid)')) ilike '%indicator_target%'
      and pg_get_functiondef(to_regprocedure('public.get_skpe_indicators_audit(uuid)')) ilike '%benchmark_reference%'
    then 'SIM' else 'NAO' end,
    null
),
normalized as (
  select
    check_group,
    check_item,
    expected_value,
    actual_value,
    case
      when actual_value = expected_value then 'OK'
      else 'FALHA'
    end as status,
    details
  from checks
)
select
  check_group,
  check_item,
  expected_value,
  actual_value,
  status,
  details
from normalized
order by
  case status when 'FALHA' then 1 else 2 end,
  check_group,
  check_item;
