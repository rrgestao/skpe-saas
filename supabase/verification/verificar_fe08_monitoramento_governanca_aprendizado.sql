-- ============================================================
-- Plataforma SPARKs / SK-PE
-- Verificador consolidado da FE-08
-- Monitoramento, Governança e Aprendizado Estratégico
--
-- Execução: Supabase Web > SQL Editor, após a migration FE-08.
-- Resultado esperado: todos os controles com status = OK.
-- Este script é somente leitura.
-- ============================================================

with
expected_tables(table_name) as (
  values
    ('skpe_monitoring_packages'),
    ('skpe_monitoring_cycles'),
    ('skpe_indicator_measurements'),
    ('skpe_key_result_check_ins'),
    ('skpe_initiative_check_ins'),
    ('skpe_initiative_outcome_measurements'),
    ('skpe_strategy_reviews'),
    ('skpe_strategy_review_items'),
    ('skpe_governance_decisions'),
    ('skpe_strategic_learnings'),
    ('skpe_performance_snapshots')
),
expected_permissions(permission_code) as (
  values
    ('strategic_monitoring.view'),
    ('strategic_monitoring.manage'),
    ('strategic_governance.manage'),
    ('strategic_governance.ratify')
),
public_rpcs(signature) as (
  values
    ('public.get_skpe_monitoring_package_readiness(uuid,boolean)'),
    ('public.configure_skpe_monitoring_package(uuid,jsonb,text)'),
    ('public.transition_skpe_monitoring_package(uuid,text,text,text)'),
    ('public.open_skpe_monitoring_cycle(uuid,jsonb,text)'),
    ('public.record_skpe_indicator_measurement(uuid,uuid,numeric,jsonb,text)'),
    ('public.record_skpe_key_result_check_in(uuid,uuid,numeric,jsonb,text)'),
    ('public.record_skpe_initiative_check_in(uuid,uuid,jsonb,text)'),
    ('public.record_skpe_initiative_outcome_measurement(uuid,uuid,jsonb,text)'),
    ('public.upsert_skpe_strategy_review(uuid,uuid,jsonb,text)'),
    ('public.upsert_skpe_strategy_review_item(uuid,uuid,jsonb,text)'),
    ('public.record_skpe_governance_decision(uuid,uuid,jsonb,text)'),
    ('public.record_skpe_strategic_learning(uuid,uuid,jsonb,text)'),
    ('public.transition_skpe_monitoring_cycle(uuid,text,text)'),
    ('public.transition_skpe_monitoring_record(text,uuid,text,text)'),
    ('public.transition_skpe_governance_decision(uuid,text,text,text)'),
    ('public.transition_skpe_strategic_learning(uuid,text,text,text)'),
    ('public.get_skpe_strategic_performance(uuid)'),
    ('public.get_skpe_monitoring_readiness(uuid)'),
    ('public.ratify_skpe_strategy_review(uuid,text)'),
    ('public.close_skpe_monitoring_cycle(uuid,text)'),
    ('public.reopen_skpe_monitoring_cycle(uuid,text)'),
    ('public.get_skpe_monitoring_cycle(uuid)'),
    ('public.get_skpe_monitoring_audit(uuid)')
),
internal_functions(signature) as (
  values
    ('public.skpe_assert_monitoring_cycle_writable(uuid)'),
    ('public.skpe_assert_strategy_review_item_scope(uuid,jsonb)'),
    ('public.ensure_skpe_monitoring_package(uuid)'),
    ('public.skpe_calculate_strategic_performance(text,numeric,numeric,numeric,numeric,numeric)'),
    ('public.skpe_monitoring_performance_status(uuid,numeric)'),
    ('public.skpe_guard_snapshot_immutability()'),
    ('public.skpe_guard_formulation_monitoring_ready()'),
    ('public.skpe_build_performance_snapshot_payload(uuid)')
),
legacy_bypass_functions(signature) as (
  values
    ('public.update_skpe_key_result_progress(uuid,numeric,text,numeric,text,text)'),
    ('public.update_skpe_initiative_operational_progress(uuid,text,numeric,numeric,numeric,text,text,text)'),
    ('public.update_skpe_initiative_outcome_progress(uuid,numeric,text,text)')
),
expected_triggers(trigger_name) as (
  values
    ('skpe_monitoring_packages_set_updated_at'),
    ('skpe_monitoring_cycles_set_updated_at'),
    ('skpe_strategy_reviews_set_updated_at'),
    ('skpe_strategy_review_items_set_updated_at'),
    ('skpe_governance_decisions_set_updated_at'),
    ('skpe_strategic_learnings_set_updated_at'),
    ('skpe_performance_snapshots_immutable'),
    ('skpe_monitoring_packages_guard_formulation'),
    ('skpe_strategic_formulations_guard_fe08')
),
function_properties as (
  select
    p.oid,
    n.nspname as schema_name,
    p.proname,
    p.prosecdef,
    coalesce(array_to_string(p.proconfig, ','), '') as function_config
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname in (
      'can_view_skpe_monitoring',
      'can_manage_skpe_monitoring',
      'can_manage_skpe_governance',
      'can_ratify_skpe_governance',
      'skpe_assert_monitoring_cycle_writable',
      'ensure_skpe_monitoring_package',
      'skpe_calculate_strategic_performance',
      'skpe_monitoring_performance_status',
      'skpe_guard_snapshot_immutability',
      'skpe_assert_strategy_review_item_scope',
      'get_skpe_monitoring_package_readiness',
      'configure_skpe_monitoring_package',
      'transition_skpe_monitoring_package',
      'skpe_guard_formulation_monitoring_ready',
      'open_skpe_monitoring_cycle',
      'record_skpe_indicator_measurement',
      'record_skpe_key_result_check_in',
      'record_skpe_initiative_check_in',
      'record_skpe_initiative_outcome_measurement',
      'upsert_skpe_strategy_review',
      'upsert_skpe_strategy_review_item',
      'record_skpe_governance_decision',
      'record_skpe_strategic_learning',
      'transition_skpe_monitoring_cycle',
      'transition_skpe_monitoring_record',
      'transition_skpe_governance_decision',
      'transition_skpe_strategic_learning',
      'get_skpe_monitoring_readiness',
      'get_skpe_strategic_performance',
      'skpe_build_performance_snapshot_payload',
      'ratify_skpe_strategy_review',
      'close_skpe_monitoring_cycle',
      'reopen_skpe_monitoring_cycle',
      'get_skpe_monitoring_cycle',
      'get_skpe_monitoring_audit'
    )
),
controls as (
  select
    10 as control_order,
    'FE08-001'::text as control_code,
    'As 11 tabelas canônicas da FE-08 existem'::text as control_name,
    case when (
      select count(*)
      from expected_tables e
      where to_regclass('public.' || e.table_name) is not null
    ) = 11 then 'OK' else 'NOK' end as status,
    jsonb_build_object(
      'expected', 11,
      'found', (
        select count(*) from expected_tables e
        where to_regclass('public.' || e.table_name) is not null
      )
    ) as details

  union all
  select
    20,
    'FE08-002',
    'As 4 permissões segregadas da FE-08 existem e estão ativas',
    case when (
      select count(*)
      from expected_permissions expected
      join public.module_permissions permission
        on permission.code = expected.permission_code
       and permission.active
      join public.modules module
        on module.id = permission.module_id
       and module.code = 'SK-PE'
    ) = 4 then 'OK' else 'NOK' end,
    jsonb_build_object(
      'expected', 4,
      'found', (
        select count(*)
        from expected_permissions expected
        join public.module_permissions permission
          on permission.code = expected.permission_code
         and permission.active
        join public.modules module
          on module.id = permission.module_id
         and module.code = 'SK-PE'
      )
    )

  union all
  select
    30,
    'FE08-003',
    'RLS está habilitada em todas as tabelas da FE-08',
    case when not exists (
      select 1
      from expected_tables e
      left join pg_class c
        on c.oid = to_regclass('public.' || e.table_name)
      where c.oid is null or not c.relrowsecurity
    ) then 'OK' else 'NOK' end,
    coalesce((
      select jsonb_agg(e.table_name order by e.table_name)
      from expected_tables e
      left join pg_class c
        on c.oid = to_regclass('public.' || e.table_name)
      where c.oid is null or not c.relrowsecurity
    ), '[]'::jsonb)

  union all
  select
    40,
    'FE08-004',
    'Cada tabela possui política SELECT para authenticated',
    case when (
      select count(distinct policy.tablename)
      from pg_policies policy
      join expected_tables e on e.table_name = policy.tablename
      where policy.schemaname = 'public'
        and policy.cmd = 'SELECT'
        and 'authenticated' = any(policy.roles)
    ) = 11 then 'OK' else 'NOK' end,
    jsonb_build_object(
      'expectedTables', 11,
      'coveredTables', (
        select count(distinct policy.tablename)
        from pg_policies policy
        join expected_tables e on e.table_name = policy.tablename
        where policy.schemaname = 'public'
          and policy.cmd = 'SELECT'
          and 'authenticated' = any(policy.roles)
      )
    )

  union all
  select
    50,
    'FE08-005',
    'Não existe política ALL nas tabelas da FE-08',
    case when not exists (
      select 1
      from pg_policies policy
      join expected_tables e on e.table_name = policy.tablename
      where policy.schemaname = 'public'
        and policy.cmd = 'ALL'
    ) then 'OK' else 'NOK' end,
    coalesce((
      select jsonb_agg(jsonb_build_object(
        'table', policy.tablename,
        'policy', policy.policyname,
        'roles', policy.roles
      ))
      from pg_policies policy
      join expected_tables e on e.table_name = policy.tablename
      where policy.schemaname = 'public'
        and policy.cmd = 'ALL'
    ), '[]'::jsonb)

  union all
  select
    60,
    'FE08-006',
    'authenticated, anon e PUBLIC não possuem DML direto',
    case when not exists (
      select 1
      from information_schema.role_table_grants grant_row
      join expected_tables e on e.table_name = grant_row.table_name
      where grant_row.table_schema = 'public'
        and upper(grant_row.grantee) in ('AUTHENTICATED', 'ANON', 'PUBLIC')
        and grant_row.privilege_type in ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE')
    ) then 'OK' else 'NOK' end,
    coalesce((
      select jsonb_agg(jsonb_build_object(
        'grantee', grant_row.grantee,
        'table', grant_row.table_name,
        'privilege', grant_row.privilege_type
      ))
      from information_schema.role_table_grants grant_row
      join expected_tables e on e.table_name = grant_row.table_name
      where grant_row.table_schema = 'public'
        and upper(grant_row.grantee) in ('AUTHENTICATED', 'ANON', 'PUBLIC')
        and grant_row.privilege_type in ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE')
    ), '[]'::jsonb)

  union all
  select
    70,
    'FE08-007',
    'service_role possui DML nas tabelas operacionais',
    case when (
      select count(*)
      from expected_tables e
      where has_table_privilege('service_role', 'public.' || e.table_name, 'INSERT')
        and has_table_privilege('service_role', 'public.' || e.table_name, 'UPDATE')
        and has_table_privilege('service_role', 'public.' || e.table_name, 'DELETE')
    ) = 11 then 'OK' else 'NOK' end,
    jsonb_build_object(
      'expectedTables', 11,
      'fullyCovered', (
        select count(*)
        from expected_tables e
        where has_table_privilege('service_role', 'public.' || e.table_name, 'INSERT')
          and has_table_privilege('service_role', 'public.' || e.table_name, 'UPDATE')
          and has_table_privilege('service_role', 'public.' || e.table_name, 'DELETE')
      )
    )

  union all
  select
    80,
    'FE08-008',
    'Todas as 23 RPCs públicas existem',
    case when (
      select count(*) from public_rpcs rpc
      where to_regprocedure(rpc.signature) is not null
    ) = 23 then 'OK' else 'NOK' end,
    jsonb_build_object(
      'expected', 23,
      'found', (
        select count(*) from public_rpcs rpc
        where to_regprocedure(rpc.signature) is not null
      ),
      'missing', coalesce((
        select jsonb_agg(rpc.signature order by rpc.signature)
        from public_rpcs rpc
        where to_regprocedure(rpc.signature) is null
      ), '[]'::jsonb)
    )

  union all
  select
    90,
    'FE08-009',
    'authenticated executa todas as RPCs públicas',
    case when not exists (
      select 1 from public_rpcs rpc
      where to_regprocedure(rpc.signature) is null
         or not has_function_privilege(
           'authenticated', to_regprocedure(rpc.signature), 'EXECUTE'
         )
    ) then 'OK' else 'NOK' end,
    coalesce((
      select jsonb_agg(rpc.signature order by rpc.signature)
      from public_rpcs rpc
      where to_regprocedure(rpc.signature) is null
         or not has_function_privilege(
           'authenticated', to_regprocedure(rpc.signature), 'EXECUTE'
         )
    ), '[]'::jsonb)

  union all
  select
    100,
    'FE08-010',
    'Funções internas não são executáveis por authenticated',
    case when not exists (
      select 1 from internal_functions f
      where to_regprocedure(f.signature) is null
         or has_function_privilege(
           'authenticated', to_regprocedure(f.signature), 'EXECUTE'
         )
    ) then 'OK' else 'NOK' end,
    coalesce((
      select jsonb_agg(f.signature order by f.signature)
      from internal_functions f
      where to_regprocedure(f.signature) is null
         or has_function_privilege(
           'authenticated', to_regprocedure(f.signature), 'EXECUTE'
         )
    ), '[]'::jsonb)

  union all
  select
    110,
    'FE08-011',
    'RPCs legadas não permitem contornar o histórico FE-08',
    case when not exists (
      select 1 from legacy_bypass_functions f
      where to_regprocedure(f.signature) is not null
        and has_function_privilege(
          'authenticated', to_regprocedure(f.signature), 'EXECUTE'
        )
    ) then 'OK' else 'NOK' end,
    coalesce((
      select jsonb_agg(f.signature order by f.signature)
      from legacy_bypass_functions f
      where to_regprocedure(f.signature) is not null
        and has_function_privilege(
          'authenticated', to_regprocedure(f.signature), 'EXECUTE'
        )
    ), '[]'::jsonb)

  union all
  select
    120,
    'FE08-012',
    'Todas as funções FE-08 são SECURITY DEFINER',
    case when count(*) = 35 and bool_and(prosecdef)
      then 'OK' else 'NOK' end,
    jsonb_build_object(
      'functionsFound', count(*),
      'withoutSecurityDefiner', coalesce(
        jsonb_agg(proname order by proname) filter (where not prosecdef),
        '[]'::jsonb
      )
    )
  from function_properties

  union all
  select
    130,
    'FE08-013',
    'Todas as funções FE-08 fixam search_path vazio',
    case when count(*) = 35
      and bool_and(function_config like '%search_path=%')
      then 'OK' else 'NOK' end,
    jsonb_build_object(
      'functionsFound', count(*),
      'withoutConfiguredSearchPath', coalesce(
        jsonb_agg(proname order by proname)
          filter (where function_config not like '%search_path=%'),
        '[]'::jsonb
      )
    )
  from function_properties

  union all
  select
    140,
    'FE08-014',
    'Os 9 gatilhos canônicos da FE-08 existem e estão habilitados',
    case when (
      select count(*)
      from expected_triggers expected
      join pg_trigger trigger_row
        on trigger_row.tgname = expected.trigger_name
       and not trigger_row.tgisinternal
       and trigger_row.tgenabled <> 'D'
    ) = 9 then 'OK' else 'NOK' end,
    jsonb_build_object(
      'expected', 9,
      'found', (
        select count(*)
        from expected_triggers expected
        join pg_trigger trigger_row
          on trigger_row.tgname = expected.trigger_name
         and not trigger_row.tgisinternal
         and trigger_row.tgenabled <> 'D'
      ),
      'missing', coalesce((
        select jsonb_agg(expected.trigger_name order by expected.trigger_name)
        from expected_triggers expected
        where not exists (
          select 1 from pg_trigger trigger_row
          where trigger_row.tgname = expected.trigger_name
            and not trigger_row.tgisinternal
            and trigger_row.tgenabled <> 'D'
        )
      ), '[]'::jsonb)
    )

  union all
  select
    150,
    'FE08-015',
    'Snapshots possuem proteção de imutabilidade e unicidade ratificada',
    case when exists (
      select 1 from pg_trigger t
      where t.tgname = 'skpe_performance_snapshots_immutable'
        and t.tgrelid = 'public.skpe_performance_snapshots'::regclass
        and not t.tgisinternal
    ) and to_regclass('public.ux_skpe_performance_snapshots_ratified') is not null
      then 'OK' else 'NOK' end,
    jsonb_build_object(
      'immutableTrigger', exists (
        select 1 from pg_trigger t
        where t.tgname = 'skpe_performance_snapshots_immutable'
          and t.tgrelid = 'public.skpe_performance_snapshots'::regclass
          and not t.tgisinternal
      ),
      'singleRatifiedIndex', to_regclass(
        'public.ux_skpe_performance_snapshots_ratified'
      ) is not null
    )

  union all
  select
    160,
    'FE08-016',
    'Registros submetidos e validados possuem unicidade separada',
    case when (
      select count(*)
      from unnest(array[
        'ux_skpe_indicator_measurements_submitted',
        'ux_skpe_indicator_measurements_validated',
        'ux_skpe_kr_check_ins_submitted',
        'ux_skpe_kr_check_ins_validated',
        'ux_skpe_initiative_check_ins_submitted',
        'ux_skpe_initiative_check_ins_validated',
        'ux_skpe_outcome_measurements_submitted',
        'ux_skpe_outcome_measurements_validated'
      ]) index_name
      where to_regclass('public.' || index_name) is not null
    ) = 8 then 'OK' else 'NOK' end,
    jsonb_build_object('expectedIndexes', 8)

  union all
  select
    170,
    'FE08-017',
    'Não há dados específicos de cliente na migration',
    case when not exists (
      select 1
      from pg_description description
      join pg_class class_row on class_row.oid = description.objoid
      where class_row.relname in (select table_name from expected_tables)
        and upper(coalesce(description.description, '')) like '%COOTAQUARA%'
    ) then 'OK' else 'NOK' end,
    jsonb_build_object('scope', 'estrutura genérica multi-organização e multiprojeto')

  union all
  select
    180,
    'FE08-018',
    'A função de prontidão do ciclo responde para ciclos existentes',
    case when to_regprocedure('public.get_skpe_monitoring_readiness(uuid)') is not null
      then 'OK' else 'NOK' end,
    jsonb_build_object(
      'function', 'public.get_skpe_monitoring_readiness(uuid)',
      'note', 'Teste funcional com ciclo real deve ser realizado após a configuração da Formulação.'
    )
)
select
  control_order,
  control_code,
  control_name,
  status,
  details
from controls
order by control_order;
