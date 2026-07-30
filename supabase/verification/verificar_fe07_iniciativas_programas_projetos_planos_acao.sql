-- ============================================================
-- Plataforma SPARKs / SK-PE
-- Verificador consolidado da FE-07
-- Iniciativas Estratégicas, Programas, Projetos e Planos de Ação
--
-- Execute somente após a migration da FE-07 no Supabase Web.
-- Resultado esperado: todos os registros com status = 'OK'.
-- ============================================================

with
expected_tables(table_name) as (
  values
    ('skpe_initiative_packages'),
    ('skpe_initiative_portfolio_items'),
    ('skpe_initiative_actions'),
    ('skpe_initiative_dependencies'),
    ('skpe_initiative_risks'),
    ('skpe_initiative_outcomes')
),
expected_initiative_columns(column_name) as (
  values
    ('initiative_class'),
    ('strategic_problem'),
    ('strategic_rationale'),
    ('criticality'),
    ('responsible_area_id'),
    ('backup_owner_user_id'),
    ('estimated_effort'),
    ('effort_unit'),
    ('resource_estimate'),
    ('currency_code'),
    ('estimate_confidence'),
    ('constraints_text')
),
expected_link_columns(table_name, column_name) as (
  values
    ('skpe_initiative_objectives', 'organization_id'),
    ('skpe_initiative_objectives', 'project_id'),
    ('skpe_initiative_objectives', 'formulation_id'),
    ('skpe_initiative_objectives', 'portfolio_item_id'),
    ('skpe_initiative_objectives', 'validation_status'),
    ('skpe_initiative_objectives', 'metadata'),
    ('skpe_initiative_key_results', 'organization_id'),
    ('skpe_initiative_key_results', 'project_id'),
    ('skpe_initiative_key_results', 'formulation_id'),
    ('skpe_initiative_key_results', 'portfolio_item_id'),
    ('skpe_initiative_key_results', 'validation_status'),
    ('skpe_initiative_key_results', 'metadata')
),
expected_public_functions(signature) as (
  values
    ('public.configure_skpe_initiative_package(uuid,jsonb,text)'),
    ('public.upsert_skpe_initiative(uuid,uuid,jsonb,text)'),
    ('public.archive_skpe_initiative(uuid,uuid,text)'),
    ('public.update_skpe_initiative_operational_progress(uuid,text,numeric,numeric,numeric,text,text,text)'),
    ('public.upsert_skpe_initiative_portfolio_item(uuid,uuid,jsonb,text)'),
    ('public.recalculate_skpe_initiative_portfolio_scores(uuid,text)'),
    ('public.set_skpe_initiative_parent(uuid,uuid,uuid,text)'),
    ('public.set_skpe_initiative_portfolio_decision(uuid,uuid,text,text,integer,text,text)'),
    ('public.reorder_skpe_initiative_portfolio(uuid,jsonb,text)'),
    ('public.link_skpe_initiative_objective(uuid,uuid,uuid,text,numeric,text,text)'),
    ('public.unlink_skpe_initiative_objective(uuid,uuid,uuid,text)'),
    ('public.link_skpe_initiative_key_result(uuid,uuid,uuid,text,numeric,text,text)'),
    ('public.unlink_skpe_initiative_key_result(uuid,uuid,uuid,text)'),
    ('public.upsert_skpe_initiative_action(uuid,uuid,jsonb,text)'),
    ('public.update_skpe_initiative_action_progress(uuid,text,numeric,numeric,text)'),
    ('public.archive_skpe_initiative_action(uuid,text)'),
    ('public.set_skpe_initiative_action_parent(uuid,uuid,text)'),
    ('public.upsert_skpe_initiative_dependency(uuid,uuid,jsonb,text)'),
    ('public.transition_skpe_initiative_dependency(uuid,text,text)'),
    ('public.upsert_skpe_initiative_risk(uuid,uuid,jsonb,text)'),
    ('public.transition_skpe_initiative_risk(uuid,text,text)'),
    ('public.update_skpe_initiative_risk_assessment(uuid,integer,integer,integer,integer,text,text,uuid,text)'),
    ('public.upsert_skpe_initiative_outcome(uuid,uuid,uuid,jsonb,text)'),
    ('public.update_skpe_initiative_outcome_progress(uuid,numeric,text,text)'),
    ('public.archive_skpe_initiative_outcome(uuid,uuid,text)'),
    ('public.transition_skpe_initiative_package(uuid,text,text,text)'),
    ('public.get_skpe_initiatives_readiness(uuid,boolean)'),
    ('public.get_skpe_initiatives_package(uuid)'),
    ('public.get_skpe_initiatives_portfolio(uuid)'),
    ('public.get_skpe_initiatives_audit(uuid)')
),
expected_internal_functions(signature) as (
  values
    ('public.skpe_assert_fe07_responsible_area(uuid,uuid)'),
    ('public.skpe_initiative_hierarchy_would_create_cycle(uuid,uuid)'),
    ('public.skpe_assert_initiative_hierarchy(uuid,uuid,uuid,uuid,text)'),
    ('public.skpe_calculate_initiative_portfolio_score(uuid)'),
    ('public.skpe_dependency_would_create_cycle(uuid,uuid,uuid,uuid)'),
    ('public.ensure_skpe_initiative_package(uuid)'),
    ('public.skpe_invalidate_initiative_package(uuid,text)'),
    ('public.skpe_capture_initiative_validation_snapshot(uuid)'),
    ('public.skpe_guard_initiative_versioned_operational_content()'),
    ('public.skpe_guard_formulation_initiatives_ready()')
),
expected_triggers(table_name, trigger_name) as (
  values
    ('skpe_initiative_packages', 'skpe_initiative_packages_set_updated_at'),
    ('skpe_initiative_packages', 'skpe_initiative_packages_guard_formulation'),
    ('skpe_initiative_portfolio_items', 'skpe_initiative_portfolio_items_set_updated_at'),
    ('skpe_initiative_portfolio_items', 'skpe_initiative_portfolio_guard_formulation'),
    ('skpe_initiative_actions', 'skpe_initiative_actions_set_updated_at'),
    ('skpe_initiative_dependencies', 'skpe_initiative_dependencies_set_updated_at'),
    ('skpe_initiative_dependencies', 'skpe_initiative_dependencies_guard_formulation'),
    ('skpe_initiative_risks', 'skpe_initiative_risks_set_updated_at'),
    ('skpe_initiative_outcomes', 'skpe_initiative_outcomes_set_updated_at'),
    ('skpe_initiative_outcomes', 'skpe_initiative_outcomes_guard_formulation'),
    ('skpe_initiative_objectives', 'skpe_initiative_objectives_guard_formulation'),
    ('skpe_initiative_key_results', 'skpe_initiative_key_results_guard_formulation'),
    ('skpe_strategic_formulations', 'skpe_strategic_formulations_guard_fe07')
),
checks as (
  select
    '01_TABLES_EXIST'::text as controle,
    case when count(*) = 6 then 'OK' else 'FALHA' end as status,
    format('%s de 6 tabelas encontradas.', count(*)) as detalhe
  from expected_tables expected
  where to_regclass('public.' || expected.table_name) is not null

  union all

  select
    '02_INITIATIVE_COLUMNS_EXIST',
    case when count(*) = 12 then 'OK' else 'FALHA' end,
    format('%s de 12 colunas encontradas em skpe_initiatives.', count(*))
  from expected_initiative_columns expected
  join information_schema.columns columns_info
    on columns_info.table_schema = 'public'
   and columns_info.table_name = 'skpe_initiatives'
   and columns_info.column_name = expected.column_name

  union all

  select
    '03_LINK_COLUMNS_EXIST',
    case when count(*) = 12 then 'OK' else 'FALHA' end,
    format('%s de 12 colunas de vínculo encontradas.', count(*))
  from expected_link_columns expected
  join information_schema.columns columns_info
    on columns_info.table_schema = 'public'
   and columns_info.table_name = expected.table_name
   and columns_info.column_name = expected.column_name

  union all

  select
    '04_RLS_ENABLED',
    case when count(*) = 6 then 'OK' else 'FALHA' end,
    format('%s de 6 tabelas novas com RLS habilitada.', count(*))
  from expected_tables expected
  join pg_class table_class
    on table_class.oid = to_regclass('public.' || expected.table_name)
   and table_class.relrowsecurity

  union all

  select
    '05_SELECT_POLICIES_EXIST',
    case when count(distinct policy.tablename) = 6 then 'OK' else 'FALHA' end,
    format('%s de 6 tabelas novas com política SELECT para authenticated.', count(distinct policy.tablename))
  from expected_tables expected
  join pg_policies policy
    on policy.schemaname = 'public'
   and policy.tablename = expected.table_name
   and policy.roles @> array['authenticated']::name[]
   and policy.cmd = 'SELECT'

  union all

  select
    '06_NO_ALL_POLICY_FOR_AUTHENTICATED',
    case when count(*) = 0 then 'OK' else 'FALHA' end,
    format('%s política(s) ALL encontrada(s) para authenticated nas tabelas FE-07.', count(*))
  from pg_policies policy
  where policy.schemaname = 'public'
    and policy.tablename in (
      'skpe_initiatives',
      'skpe_initiative_objectives',
      'skpe_initiative_instruments',
      'skpe_initiative_key_results',
      'skpe_initiative_packages',
      'skpe_initiative_portfolio_items',
      'skpe_initiative_actions',
      'skpe_initiative_dependencies',
      'skpe_initiative_risks',
      'skpe_initiative_outcomes'
    )
    and policy.roles @> array['authenticated']::name[]
    and policy.cmd = 'ALL'

  union all

  select
    '07_LEGACY_KR_LINK_MANAGE_POLICY_REMOVED',
    case when count(*) = 0 then 'OK' else 'FALHA' end,
    format('%s política(s) legada(s) de escrita encontrada(s).', count(*))
  from pg_policies policy
  where policy.schemaname = 'public'
    and policy.tablename = 'skpe_initiative_key_results'
    and policy.policyname = 'skpe_initiative_key_results_manage'

  union all

  select
    '08_NO_AUTHENTICATED_DML',
    case when count(*) = 0 then 'OK' else 'FALHA' end,
    format('%s privilégio(s) DML direto(s) encontrado(s) para authenticated.', count(*))
  from (
    select table_name, privilege_type
    from information_schema.role_table_grants
    where grantee = 'authenticated'
      and table_schema = 'public'
      and table_name in (
        'skpe_initiatives',
        'skpe_initiative_objectives',
        'skpe_initiative_instruments',
        'skpe_initiative_key_results',
        'skpe_initiative_packages',
        'skpe_initiative_portfolio_items',
        'skpe_initiative_actions',
        'skpe_initiative_dependencies',
        'skpe_initiative_risks',
        'skpe_initiative_outcomes'
      )
      and privilege_type in ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE')
  ) direct_dml

  union all

  select
    '09_PUBLIC_FUNCTIONS_EXIST',
    case when count(*) = 30 then 'OK' else 'FALHA' end,
    format('%s de 30 RPCs públicas encontradas.', count(*))
  from expected_public_functions expected
  where to_regprocedure(expected.signature) is not null

  union all

  select
    '10_INTERNAL_FUNCTIONS_EXIST',
    case when count(*) = 10 then 'OK' else 'FALHA' end,
    format('%s de 10 funções internas encontradas.', count(*))
  from expected_internal_functions expected
  where to_regprocedure(expected.signature) is not null

  union all

  select
    '11_SECURITY_DEFINER_AND_SEARCH_PATH',
    case when count(*) = 40 then 'OK' else 'FALHA' end,
    format('%s de 40 funções com SECURITY DEFINER e search_path vazio.', count(*))
  from (
    select signature from expected_public_functions
    union all
    select signature from expected_internal_functions
  ) expected
  join pg_proc procedure_info
    on procedure_info.oid = to_regprocedure(expected.signature)
  where procedure_info.prosecdef
    and coalesce(array_to_string(procedure_info.proconfig, ','), '') like '%search_path=%'

  union all

  select
    '12_INTERNAL_FUNCTIONS_NOT_EXECUTABLE_BY_AUTHENTICATED',
    case when count(*) = 0 then 'OK' else 'FALHA' end,
    format('%s função(ões) interna(s) executável(is) por authenticated.', count(*))
  from expected_internal_functions expected
  where to_regprocedure(expected.signature) is not null
    and has_function_privilege('authenticated', expected.signature, 'EXECUTE')

  union all

  select
    '13_PUBLIC_FUNCTIONS_EXECUTABLE_BY_AUTHENTICATED',
    case when count(*) = 30 then 'OK' else 'FALHA' end,
    format('%s de 30 RPCs públicas executáveis por authenticated.', count(*))
  from expected_public_functions expected
  where to_regprocedure(expected.signature) is not null
    and has_function_privilege('authenticated', expected.signature, 'EXECUTE')

  union all

  select
    '14_LEGACY_MUTATION_FUNCTIONS_REVOKED',
    case when count(*) = 0 then 'OK' else 'FALHA' end,
    format('%s RPC(s) legada(s) ainda executável(is) por authenticated.', count(*))
  from (
    values
      ('public.create_skpe_initiative(uuid,text,text,text,text,text,text,uuid,uuid,date,date,numeric,numeric,text,uuid,uuid,text)'),
      ('public.create_skpe_initiative_v2(uuid,text,text,text,text,text,text,text,text,uuid,uuid,date,date,numeric,numeric,text,text,text,text,text,text,text,text,uuid,uuid,text)'),
      ('public.update_skpe_initiative_status(uuid,text,numeric,text,numeric,numeric,text)'),
      ('public.link_skpe_initiative_objective(uuid,uuid,text,numeric,text,text)'),
      ('public.link_skpe_initiative_key_result(uuid,uuid,text,numeric,text,text)')
  ) legacy(signature)
  where to_regprocedure(legacy.signature) is not null
    and has_function_privilege('authenticated', legacy.signature, 'EXECUTE')

  union all

  select
    '15_TRIGGERS_EXIST',
    case when count(*) = 13 then 'OK' else 'FALHA' end,
    format('%s de 13 gatilhos encontrados.', count(*))
  from expected_triggers expected
  join pg_trigger trigger_info
    on trigger_info.tgrelid = to_regclass('public.' || expected.table_name)
   and trigger_info.tgname = expected.trigger_name
   and not trigger_info.tgisinternal

  union all

  select
    '16_PACKAGE_WEIGHT_CONSTRAINT',
    case when count(*) = 1 then 'OK' else 'FALHA' end,
    format('%s constraint de soma dos pesos encontrada.', count(*))
  from pg_constraint constraint_info
  where constraint_info.conrelid = 'public.skpe_initiative_packages'::regclass
    and constraint_info.conname = 'skpe_initiative_packages_weights_sum_check'

  union all

  select
    '17_PORTFOLIO_SCOPE_UNIQUENESS',
    case when count(*) = 1 then 'OK' else 'FALHA' end,
    format('%s constraint de unicidade Iniciativa/Formulação encontrada.', count(*))
  from pg_constraint constraint_info
  where constraint_info.conrelid = 'public.skpe_initiative_portfolio_items'::regclass
    and constraint_info.conname = 'skpe_initiative_portfolio_items_unique'

  union all

  select
    '18_DEPENDENCY_SELF_LINK_BLOCKED',
    case when count(*) = 1 then 'OK' else 'FALHA' end,
    format('%s constraint de autorrelacionamento encontrada.', count(*))
  from pg_constraint constraint_info
  where constraint_info.conrelid = 'public.skpe_initiative_dependencies'::regclass
    and constraint_info.conname = 'skpe_initiative_dependencies_no_self'

  union all

  select
    '19_ACTION_COMPLETION_CONSTRAINT',
    case when count(*) = 1 then 'OK' else 'FALHA' end,
    format('%s constraint de conclusão de ação encontrada.', count(*))
  from pg_constraint constraint_info
  where constraint_info.conrelid = 'public.skpe_initiative_actions'::regclass
    and constraint_info.conname = 'skpe_initiative_actions_completion_check'

  union all

  select
    '20_OUTCOME_MEASUREMENT_CONSTRAINT',
    case when count(*) = 1 then 'OK' else 'FALHA' end,
    format('%s constraint de conteúdo de medição encontrada.', count(*))
  from pg_constraint constraint_info
  where constraint_info.conrelid = 'public.skpe_initiative_outcomes'::regclass
    and constraint_info.conname = 'skpe_initiative_outcomes_measurement_content_check'

  union all

  select
    '21_PORTFOLIO_RANK_INDEX',
    case when count(*) = 1 then 'OK' else 'FALHA' end,
    format('%s índice de ranking único encontrado.', count(*))
  from pg_indexes index_info
  where index_info.schemaname = 'public'
    and index_info.indexname = 'ux_skpe_initiative_portfolio_rank'

  union all

  select
    '22_NO_COOTAQUARA_SPECIFIC_DATA',
    case when count(*) = 0 then 'OK' else 'FALHA' end,
    format('%s registro(s) específico(s) da COOTAQUARA encontrado(s) nas estruturas FE-07.', count(*))
  from (
    select metadata::text as searchable_text from public.skpe_initiative_packages
    union all
    select metadata::text from public.skpe_initiative_portfolio_items
    union all
    select metadata::text from public.skpe_initiative_actions
    union all
    select metadata::text from public.skpe_initiative_dependencies
    union all
    select metadata::text from public.skpe_initiative_risks
    union all
    select metadata::text from public.skpe_initiative_outcomes
  ) content
  where upper(coalesce(searchable_text, '')) like '%COOTAQUARA%'

  union all

  select
    '23_FORMULATION_GUARD_INTEGRATED',
    case when count(*) = 1 then 'OK' else 'FALHA' end,
    format('%s gatilho de prontidão integrado à Formulação.', count(*))
  from pg_trigger trigger_info
  where trigger_info.tgrelid = 'public.skpe_strategic_formulations'::regclass
    and trigger_info.tgname = 'skpe_strategic_formulations_guard_fe07'
    and not trigger_info.tgisinternal

  union all

  select
    '24_OPERATIONAL_AUDIT_REUSED',
    case when to_regclass('public.skpe_operational_audit') is not null then 'OK' else 'FALHA' end,
    case
      when to_regclass('public.skpe_operational_audit') is not null
        then 'Trilha transversal skpe_operational_audit disponível.'
      else 'Trilha transversal skpe_operational_audit ausente.'
    end
)
select controle, status, detalhe
from checks
order by controle;
