-- ============================================================
-- FE-06 — Verificação consolidada
-- OKRs, Resultados-Chave e Desdobramento Estratégico
-- SOMENTE LEITURA — retorna um único grid.
-- ============================================================

with
expected_indexes(index_name) as (
  values
    ('idx_skpe_okr_packages_scope'),
    ('idx_skpe_okr_cycles_readiness'),
    ('idx_skpe_okrs_readiness'),
    ('idx_skpe_okr_objectives_readiness'),
    ('idx_skpe_key_results_readiness'),
    ('idx_skpe_okr_alignments_readiness'),
    ('ux_skpe_okr_alignments_single_parent')
),
expected_functions(function_signature, api_class) as (
  values
    ('public.ensure_skpe_okr_package(uuid)', 'internal'),
    ('public.skpe_invalidate_okr_package(uuid,text)', 'internal'),
    ('public.skpe_assert_valid_responsible_area(uuid,uuid)', 'internal'),
    ('public.skpe_calculate_key_result_progress(text,numeric,numeric,numeric,numeric,numeric)', 'internal'),
    ('public.skpe_okr_parent_would_create_cycle(uuid,uuid,uuid,uuid)', 'internal'),
    ('public.skpe_recalculate_okr_progress(uuid,text)', 'internal'),
    ('public.skpe_guard_okr_operational_content()', 'internal'),
    ('public.skpe_guard_formulation_okrs_ready()', 'internal'),
    ('public.configure_skpe_okr_package(uuid,boolean,boolean,boolean,integer,integer,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,text,text,jsonb,text)', 'public'),
    ('public.upsert_skpe_okr_cycle(uuid,text,text,text,text,date,date,integer,uuid,text,uuid,jsonb,text)', 'public'),
    ('public.close_skpe_okr_cycle(uuid,text,text)', 'public'),
    ('public.reopen_skpe_okr_cycle(uuid,text,text)', 'public'),
    ('public.upsert_skpe_okr(uuid,uuid,text,text,text,text,uuid,uuid,text,text,integer,uuid,uuid,jsonb,text)', 'public'),
    ('public.archive_skpe_okr(uuid,text)', 'public'),
    ('public.link_skpe_okr_objective(uuid,uuid,numeric,boolean,text,text)', 'public'),
    ('public.unlink_skpe_okr_objective(uuid,uuid,text)', 'public'),
    ('public.upsert_skpe_key_result(uuid,text,text,text,numeric,numeric,numeric,text,text,text,text,text,text,date,date,uuid,uuid,numeric,uuid,numeric,numeric,boolean,text,uuid,uuid,jsonb,text)', 'public'),
    ('public.archive_skpe_key_result(uuid,text)', 'public'),
    ('public.update_skpe_key_result_progress(uuid,numeric,text,numeric,text,text)', 'public'),
    ('public.upsert_skpe_okr_alignment(uuid,uuid,text,text,uuid,jsonb,text)', 'public'),
    ('public.delete_skpe_okr_alignment(uuid,text)', 'public'),
    ('public.get_skpe_okrs_readiness(uuid)', 'public'),
    ('public.transition_skpe_okr_package(uuid,text,text,text)', 'public'),
    ('public.get_skpe_okrs_package(uuid)', 'public'),
    ('public.get_skpe_okrs_audit(uuid)', 'public')
),
controlled_tables(table_name) as (
  values
    ('skpe_okr_packages'),
    ('skpe_okr_cycles'),
    ('skpe_okrs'),
    ('skpe_okr_objectives'),
    ('skpe_key_results'),
    ('skpe_okr_alignments')
),
checks as (
  select
    'TABELA'::text check_group,
    controlled_tables.table_name::text check_item,
    'EXISTE'::text expected_value,
    case when to_regclass('public.' || controlled_tables.table_name) is not null
      then 'EXISTE' else 'AUSENTE' end::text actual_value,
    (to_regclass('public.' || controlled_tables.table_name) is not null) ok,
    case
      when controlled_tables.table_name in ('skpe_okr_packages', 'skpe_okr_alignments')
        then 'Estrutura nova estritamente necessária na FE-06.'
      else 'Estrutura preexistente reutilizada; não deve haver duplicação.'
    end::text details
  from controlled_tables

  union all

  select
    'COLUNA',
    'skpe_okrs.validation_status',
    'EXISTE',
    case when exists (
      select 1 from information_schema.columns
      where table_schema = 'public' and table_name = 'skpe_okrs'
        and column_name = 'validation_status'
    ) then 'EXISTE' else 'AUSENTE' end,
    exists (
      select 1 from information_schema.columns
      where table_schema = 'public' and table_name = 'skpe_okrs'
        and column_name = 'validation_status'
    ),
    'Complemento mínimo na estrutura existente do OKR.'

  union all

  select
    'RLS',
    controlled_tables.table_name || ' com RLS habilitada',
    'SIM',
    case when exists (
      select 1
      from pg_class table_info
      join pg_namespace namespace_info on namespace_info.oid = table_info.relnamespace
      where namespace_info.nspname = 'public'
        and table_info.relname = controlled_tables.table_name
        and table_info.relrowsecurity
    ) then 'SIM' else 'NAO' end,
    exists (
      select 1
      from pg_class table_info
      join pg_namespace namespace_info on namespace_info.oid = table_info.relnamespace
      where namespace_info.nspname = 'public'
        and table_info.relname = controlled_tables.table_name
        and table_info.relrowsecurity
    ),
    null
  from controlled_tables

  union all

  select
    'RLS',
    controlled_tables.table_name || ' com política SELECT para authenticated',
    'SIM',
    case when exists (
      select 1 from pg_policies policy_info
      where policy_info.schemaname = 'public'
        and policy_info.tablename = controlled_tables.table_name
        and policy_info.cmd = 'SELECT'
        and policy_info.roles::text ilike '%authenticated%'
    ) then 'SIM' else 'NAO' end,
    exists (
      select 1 from pg_policies policy_info
      where policy_info.schemaname = 'public'
        and policy_info.tablename = controlled_tables.table_name
        and policy_info.cmd = 'SELECT'
        and policy_info.roles::text ilike '%authenticated%'
    ),
    null
  from controlled_tables

  union all

  select
    'RLS',
    controlled_tables.table_name || ' sem política DML para authenticated/public',
    '0',
    count(policy_info.policyname)::text,
    count(policy_info.policyname) = 0,
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
      then 'CONCEDIDO' else 'NEGADO' end,
    not (
      has_table_privilege('authenticated', 'public.' || controlled_tables.table_name, 'INSERT')
      or has_table_privilege('authenticated', 'public.' || controlled_tables.table_name, 'UPDATE')
      or has_table_privilege('authenticated', 'public.' || controlled_tables.table_name, 'DELETE')
    ),
    null
  from controlled_tables

  union all

  select
    'PRIVILEGIO_TABELA',
    controlled_tables.table_name || ' com SELECT para authenticated',
    'CONCEDIDO',
    case when has_table_privilege(
      'authenticated', 'public.' || controlled_tables.table_name, 'SELECT'
    ) then 'CONCEDIDO' else 'NEGADO' end,
    has_table_privilege('authenticated', 'public.' || controlled_tables.table_name, 'SELECT'),
    null
  from controlled_tables

  union all

  select
    'INDICE',
    expected_indexes.index_name,
    'EXISTE',
    case when exists (
      select 1 from pg_indexes index_info
      where index_info.schemaname = 'public'
        and index_info.indexname = expected_indexes.index_name
    ) then 'EXISTE' else 'AUSENTE' end,
    exists (
      select 1 from pg_indexes index_info
      where index_info.schemaname = 'public'
        and index_info.indexname = expected_indexes.index_name
    ),
    null
  from expected_indexes

  union all

  select
    'FUNCAO',
    expected_functions.function_signature,
    'EXISTE',
    case when to_regprocedure(expected_functions.function_signature) is not null
      then 'EXISTE' else 'AUSENTE' end,
    to_regprocedure(expected_functions.function_signature) is not null,
    expected_functions.api_class
  from expected_functions

  union all

  select
    'SEGURANCA_FUNCAO',
    expected_functions.function_signature,
    'SECURITY DEFINER',
    case when exists (
      select 1 from pg_proc procedure_info
      where procedure_info.oid = to_regprocedure(expected_functions.function_signature)
        and procedure_info.prosecdef
    ) then 'SECURITY DEFINER' else 'REVISAR' end,
    exists (
      select 1 from pg_proc procedure_info
      where procedure_info.oid = to_regprocedure(expected_functions.function_signature)
        and procedure_info.prosecdef
    ),
    expected_functions.api_class
  from expected_functions

  union all

  select
    'SEARCH_PATH',
    expected_functions.function_signature,
    'VAZIO_CONTROLADO',
    case when exists (
      select 1 from pg_proc procedure_info
      where procedure_info.oid = to_regprocedure(expected_functions.function_signature)
        and exists (
          select 1
          from unnest(coalesce(procedure_info.proconfig, array[]::text[])) config
          where config in ('search_path=', 'search_path=""')
        )
    ) then 'VAZIO_CONTROLADO' else 'REVISAR' end,
    exists (
      select 1 from pg_proc procedure_info
      where procedure_info.oid = to_regprocedure(expected_functions.function_signature)
        and exists (
          select 1
          from unnest(coalesce(procedure_info.proconfig, array[]::text[])) config
          where config in ('search_path=', 'search_path=""')
        )
    ),
    null
  from expected_functions

  union all

  select
    'EXECUCAO_AUTHENTICATED',
    expected_functions.function_signature,
    case when expected_functions.api_class = 'public' then 'CONCEDIDA' else 'NEGADA' end,
    case when to_regprocedure(expected_functions.function_signature) is null then 'AUSENTE'
      when has_function_privilege(
        'authenticated', to_regprocedure(expected_functions.function_signature), 'EXECUTE'
      ) then 'CONCEDIDA' else 'NEGADA' end,
    case
      when to_regprocedure(expected_functions.function_signature) is null then false
      when expected_functions.api_class = 'public' then
        has_function_privilege(
          'authenticated', to_regprocedure(expected_functions.function_signature), 'EXECUTE'
        )
      else not has_function_privilege(
        'authenticated', to_regprocedure(expected_functions.function_signature), 'EXECUTE'
      )
    end,
    expected_functions.api_class
  from expected_functions

  union all

  select
    'TRIGGER',
    trigger_name,
    'EXISTE',
    case when exists (
      select 1 from pg_trigger trigger_info
      where trigger_info.tgname = trigger_name and not trigger_info.tgisinternal
    ) then 'EXISTE' else 'AUSENTE' end,
    exists (
      select 1 from pg_trigger trigger_info
      where trigger_info.tgname = trigger_name and not trigger_info.tgisinternal
    ),
    null
  from (values
    ('skpe_okr_packages_set_updated_at'),
    ('skpe_okr_cycles_set_updated_at'),
    ('skpe_okrs_set_updated_at'),
    ('skpe_key_results_set_updated_at'),
    ('skpe_okr_alignments_set_updated_at'),
    ('skpe_okr_packages_guard_approved_formulation'),
    ('skpe_okr_alignments_guard_approved_formulation'),
    ('skpe_okr_cycles_guard_approved_formulation'),
    ('skpe_okrs_guard_approved_formulation'),
    ('skpe_key_results_guard_approved_formulation'),
    ('skpe_strategic_formulations_guard_okrs_ready')
  ) expected_triggers(trigger_name)

  union all

  select
    'TRIGGER_FUNCAO',
    controlled_table || ' usa guarda operacional especializada',
    'skpe_guard_okr_operational_content',
    coalesce(actual_function, 'AUSENTE'),
    actual_function = 'skpe_guard_okr_operational_content',
    'Campos estruturais ficam congelados; somente medição e situação operacional continuam atualizáveis.'
  from (values
    ('skpe_okr_cycles'), ('skpe_okrs'), ('skpe_key_results')
  ) expected_operational(controlled_table)
  left join lateral (
    select procedure_info.proname actual_function
    from pg_trigger trigger_info
    join pg_proc procedure_info on procedure_info.oid = trigger_info.tgfoid
    where trigger_info.tgrelid = ('public.' || controlled_table)::regclass
      and trigger_info.tgname = controlled_table || '_guard_approved_formulation'
      and not trigger_info.tgisinternal
    limit 1
  ) trigger_function on true

  union all

  select
    'CONSTRAINT',
    'Situações do pacote FE-06',
    'not_applicable,in_elaboration,pending_validation,validated',
    case when exists (
      select 1 from pg_constraint constraint_info
      where constraint_info.conname = 'skpe_okr_packages_status_check'
        and constraint_info.conrelid = 'public.skpe_okr_packages'::regclass
        and pg_get_constraintdef(constraint_info.oid) ilike '%not_applicable%'
        and pg_get_constraintdef(constraint_info.oid) ilike '%in_elaboration%'
        and pg_get_constraintdef(constraint_info.oid) ilike '%pending_validation%'
        and pg_get_constraintdef(constraint_info.oid) ilike '%validated%'
    ) then 'not_applicable,in_elaboration,pending_validation,validated' else 'REVISAR' end,
    exists (
      select 1 from pg_constraint constraint_info
      where constraint_info.conname = 'skpe_okr_packages_status_check'
        and constraint_info.conrelid = 'public.skpe_okr_packages'::regclass
        and pg_get_constraintdef(constraint_info.oid) ilike '%not_applicable%'
        and pg_get_constraintdef(constraint_info.oid) ilike '%in_elaboration%'
        and pg_get_constraintdef(constraint_info.oid) ilike '%pending_validation%'
        and pg_get_constraintdef(constraint_info.oid) ilike '%validated%'
    ),
    null

  union all

  select
    'CONFIGURACAO_PADRAO',
    'OKRs são opt-in por Formulação',
    'false',
    coalesce(pg_get_expr(default_info.adbin, default_info.adrelid), 'AUSENTE'),
    pg_get_expr(default_info.adbin, default_info.adrelid) = 'false',
    'A ausência de adoção não cria bloqueio artificial.'
  from pg_attribute attribute_info
  join pg_class table_info on table_info.oid = attribute_info.attrelid
  join pg_namespace namespace_info on namespace_info.oid = table_info.relnamespace
  left join pg_attrdef default_info
    on default_info.adrelid = attribute_info.attrelid
   and default_info.adnum = attribute_info.attnum
  where namespace_info.nspname = 'public'
    and table_info.relname = 'skpe_okr_packages'
    and attribute_info.attname = 'okr_enabled'

  union all

  select
    'CALCULO_PROGRESSO',
    test_name,
    expected_result,
    actual_result,
    expected_result = actual_result,
    null
  from (
    select 'higher_is_better'::text test_name, '50.00'::text expected_result,
      public.skpe_calculate_key_result_progress(
        'higher_is_better', 0, 50, 100, null, null
      )::text actual_result
    union all
    select 'lower_is_better', '50.00',
      public.skpe_calculate_key_result_progress(
        'lower_is_better', 100, 75, 50, null, null
      )::text
    union all
    select 'target_is_better', '50.00',
      public.skpe_calculate_key_result_progress(
        'target_is_better', 0, 5, 10, null, null
      )::text
    union all
    select 'range_is_better', '100.00',
      public.skpe_calculate_key_result_progress(
        'range_is_better', 0, 15, 15, 10, 20
      )::text
    union all
    select 'divisao_por_zero_protegida', '100.00',
      public.skpe_calculate_key_result_progress(
        'higher_is_better', 10, 10, 10, null, null
      )::text
  ) progress_tests

  union all

  select
    'REGRA_METODOLOGICA',
    rule_name,
    'SIM',
    case when pg_get_functiondef(
      to_regprocedure('public.get_skpe_okrs_readiness(uuid)')
    ) ilike '%' || rule_code || '%' then 'SIM' else 'NAO' end,
    pg_get_functiondef(
      to_regprocedure('public.get_skpe_okrs_readiness(uuid)')
    ) ilike '%' || rule_code || '%',
    null
  from (values
    ('Não aplicabilidade formal', 'not_applicable'),
    ('Ciclo válido', 'OKR_PACKAGE_WITHOUT_VALID_CYCLE'),
    ('Ciclo dentro do horizonte', 'CYCLE_OUTSIDE_FORMULATION_HORIZON'),
    ('Código de ciclo sem duplicidade lógica', 'DUPLICATE_CYCLE_CODE'),
    ('OKR vinculado a OE', 'OKR_WITHOUT_STRATEGIC_OBJECTIVE'),
    ('Quantidade mínima de KRs', 'KEY_RESULTS_BELOW_MINIMUM'),
    ('Quantidade máxima de KRs', 'KEY_RESULTS_ABOVE_MAXIMUM'),
    ('KR mensurável', 'KEY_RESULT_NOT_MEASURABLE'),
    ('Polaridade do KR', 'KEY_RESULT_POLARITY_MISSING'),
    ('Linha de base configurável', 'KEY_RESULT_BASELINE_MISSING'),
    ('Fonte de dados', 'KEY_RESULT_DATA_SOURCE_MISSING'),
    ('KR dentro do ciclo', 'KEY_RESULT_OUTSIDE_CYCLE'),
    ('Escopo do Indicador vinculado', 'LINKED_INDICATOR_SCOPE_MISMATCH'),
    ('Pesos somam 100 quando obrigatórios', 'KEY_RESULT_WEIGHTS_INVALID'),
    ('Redação semelhante a atividade', 'KEY_RESULT_ACTIVITY_LIKE_WORDING'),
    ('Histórico de acompanhamento', 'KEY_RESULT_WITHOUT_PROGRESS_HISTORY'),
    ('Pacote validado', 'OKR_PACKAGE_NOT_VALIDATED')
  ) methodology_rules(rule_name, rule_code)

  union all

  select
    'INTEGRIDADE_HIERARQUIA',
    'Relação parent_child bloqueia ciclos',
    'SIM',
    case when pg_get_functiondef(
      to_regprocedure('public.upsert_skpe_okr_alignment(uuid,uuid,text,text,uuid,jsonb,text)')
    ) ilike '%skpe_okr_parent_would_create_cycle%' then 'SIM' else 'NAO' end,
    pg_get_functiondef(
      to_regprocedure('public.upsert_skpe_okr_alignment(uuid,uuid,text,text,uuid,jsonb,text)')
    ) ilike '%skpe_okr_parent_would_create_cycle%',
    'Cada OKR possui no máximo um pai ativo e não pode formar ciclo hierárquico.'

  union all

  select
    'VERSIONAMENTO',
    'Clonagem FE-01 contempla ciclos, OKRs e KRs',
    'SIM',
    case when
      pg_get_functiondef(to_regprocedure('public.clone_skpe_formulation_content(uuid,uuid)'))
        ilike '%insert into public.skpe_okr_cycles%'
      and pg_get_functiondef(to_regprocedure('public.clone_skpe_formulation_content(uuid,uuid)'))
        ilike '%insert into public.skpe_okrs%'
      and pg_get_functiondef(to_regprocedure('public.clone_skpe_formulation_content(uuid,uuid)'))
        ilike '%insert into public.skpe_key_results%'
      then 'SIM' else 'NAO' end,
    pg_get_functiondef(to_regprocedure('public.clone_skpe_formulation_content(uuid,uuid)'))
        ilike '%insert into public.skpe_okr_cycles%'
      and pg_get_functiondef(to_regprocedure('public.clone_skpe_formulation_content(uuid,uuid)'))
        ilike '%insert into public.skpe_okrs%'
      and pg_get_functiondef(to_regprocedure('public.clone_skpe_formulation_content(uuid,uuid)'))
        ilike '%insert into public.skpe_key_results%',
    'A função extensa existente foi preservada.'

  union all

  select
    'VERSIONAMENTO',
    'Complemento FE-06 clona alinhamentos e normaliza progresso',
    'SIM',
    case when
      pg_get_functiondef(to_regprocedure('public.ensure_skpe_okr_package(uuid)'))
        ilike '%insert into public.skpe_okr_alignments%'
      and pg_get_functiondef(to_regprocedure('public.ensure_skpe_okr_package(uuid)'))
        ilike '%progressResetOnClone%'
      then 'SIM' else 'NAO' end,
    pg_get_functiondef(to_regprocedure('public.ensure_skpe_okr_package(uuid)'))
        ilike '%insert into public.skpe_okr_alignments%'
      and pg_get_functiondef(to_regprocedure('public.ensure_skpe_okr_package(uuid)'))
        ilike '%progressResetOnClone%',
    'Evita reescrever a função extensa de clonagem.'

  union all

  select
    'ESCOPO',
    'Iniciativas não são implementadas integralmente na FE-06',
    'SIM',
    case when pg_get_functiondef(
      to_regprocedure('public.get_skpe_okrs_readiness(uuid)')
    ) ilike '%initiativeRequiredInFe06%false%' then 'SIM' else 'NAO' end,
    pg_get_functiondef(
      to_regprocedure('public.get_skpe_okrs_readiness(uuid)')
    ) ilike '%initiativeRequiredInFe06%false%',
    'Somente referências existentes são devolvidas no contrato consolidado.'
)
select
  check_group,
  check_item,
  expected_value,
  actual_value,
  case when ok then 'OK' else 'FALHA' end as status,
  details
from checks
order by
  case check_group
    when 'TABELA' then 1
    when 'COLUNA' then 2
    when 'RLS' then 3
    when 'PRIVILEGIO_TABELA' then 4
    when 'INDICE' then 5
    when 'FUNCAO' then 6
    when 'SEGURANCA_FUNCAO' then 7
    when 'SEARCH_PATH' then 8
    when 'EXECUCAO_AUTHENTICATED' then 9
    when 'TRIGGER' then 10
    when 'TRIGGER_FUNCAO' then 11
    when 'CONSTRAINT' then 12
    when 'CONFIGURACAO_PADRAO' then 13
    when 'CALCULO_PROGRESSO' then 14
    when 'REGRA_METODOLOGICA' then 15
    when 'INTEGRIDADE_HIERARQUIA' then 16
    when 'VERSIONAMENTO' then 17
    when 'ESCOPO' then 18
    else 99
  end,
  check_item;
