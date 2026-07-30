-- ============================================================
-- FE-04 — Verificação consolidada
-- Temas, Perspectivas, Objetivos Estratégicos e Mapa
-- SOMENTE LEITURA — retorna um único grid.
-- ============================================================

with
expected_indexes(index_name) as (
  values
    ('idx_skpe_strategic_map_packages_scope'),
    ('idx_skpe_strategic_themes_map'),
    ('idx_skpe_bsc_perspectives_map'),
    ('idx_skpe_strategic_objectives_map'),
    ('idx_skpe_objective_relations_map')
),
expected_functions(function_signature, api_class) as (
  values
    ('public.ensure_skpe_strategic_map_package(uuid)', 'internal'),
    ('public.skpe_invalidate_strategic_map_package(uuid,text)', 'internal'),
    ('public.skpe_objective_relation_would_create_cycle(uuid,uuid,uuid,uuid)', 'internal'),
    ('public.skpe_guard_formulation_strategic_map_ready()', 'internal'),
    ('public.configure_skpe_strategic_map(uuid,boolean,text,boolean,jsonb,text)', 'public'),
    ('public.upsert_skpe_strategic_theme(uuid,text,text,text,text,uuid,text,integer,date,date,uuid,text,text,jsonb,text)', 'public'),
    ('public.archive_skpe_strategic_theme(uuid,text)', 'public'),
    ('public.upsert_skpe_bsc_perspective(uuid,text,text,text,uuid,integer,text,text,text,text,jsonb,text)', 'public'),
    ('public.archive_skpe_bsc_perspective(uuid,text)', 'public'),
    ('public.upsert_skpe_strategic_objective(uuid,text,text,text,text,text,uuid,uuid,uuid,text,date,date,uuid,text,integer,jsonb,text,jsonb,text)', 'public'),
    ('public.archive_skpe_strategic_objective(uuid,text)', 'public'),
    ('public.upsert_skpe_objective_relation(uuid,uuid,uuid,text,text,numeric,text,integer,uuid,jsonb,text)', 'public'),
    ('public.delete_skpe_objective_relation(uuid,text)', 'public'),
    ('public.get_skpe_strategic_map_readiness(uuid)', 'public'),
    ('public.transition_skpe_strategic_map(uuid,text,text,text)', 'public'),
    ('public.get_skpe_strategic_map(uuid)', 'public'),
    ('public.get_skpe_strategic_map_audit(uuid)', 'public')
),
controlled_tables(table_name) as (
  values
    ('skpe_strategic_map_packages'),
    ('skpe_strategic_themes'),
    ('skpe_bsc_perspectives'),
    ('skpe_strategic_objectives'),
    ('skpe_objective_relations')
),
checks as (
  select
    'TABELA'::text as check_group,
    'public.skpe_strategic_map_packages'::text as check_item,
    'EXISTE'::text as expected_value,
    case when to_regclass('public.skpe_strategic_map_packages') is not null
      then 'EXISTE'
      else 'AUSENTE'
    end as actual_value,
    null::text as details

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
        and (
          policy_info.roles::text ilike '%authenticated%'
          or policy_info.roles::text ilike '%public%'
        )
    ) then 'SIM' else 'NAO' end,
    null
  from controlled_tables

  union all

  select
    'RLS',
    controlled_tables.table_name || ' sem política DML para authenticated',
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
    'RLS',
    'Política SELECT da FE-04 usa autorização da Formulação',
    'SIM',
    case when exists (
      select 1
      from pg_policies policy_info
      where policy_info.schemaname = 'public'
        and policy_info.tablename = 'skpe_strategic_map_packages'
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
      where procedure_info.oid =
        to_regprocedure(expected_functions.function_signature)
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
      where procedure_info.oid =
        to_regprocedure(expected_functions.function_signature)
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
    case when expected_functions.api_class = 'public'
      then 'CONCEDIDA'
      else 'NEGADA'
    end,
    case
      when has_function_privilege(
        'authenticated',
        to_regprocedure(expected_functions.function_signature),
        'EXECUTE'
      )
        then 'CONCEDIDA'
      else 'NEGADA'
    end,
    expected_functions.api_class
  from expected_functions

  union all

  select
    'TRIGGER',
    'skpe_strategic_map_packages_guard_approved_formulation',
    'EXISTE',
    case when exists (
      select 1
      from pg_trigger trigger_info
      where trigger_info.tgrelid =
        'public.skpe_strategic_map_packages'::regclass
        and trigger_info.tgname =
          'skpe_strategic_map_packages_guard_approved_formulation'
        and not trigger_info.tgisinternal
    ) then 'EXISTE' else 'AUSENTE' end,
    null

  union all

  select
    'TRIGGER',
    'skpe_strategic_formulations_guard_strategic_map_ready',
    'EXISTE',
    case when exists (
      select 1
      from pg_trigger trigger_info
      where trigger_info.tgrelid =
        'public.skpe_strategic_formulations'::regclass
        and trigger_info.tgname =
          'skpe_strategic_formulations_guard_strategic_map_ready'
        and not trigger_info.tgisinternal
    ) then 'EXISTE' else 'AUSENTE' end,
    null

  union all

  select
    'CONSTRAINT',
    'Tipos de relação causal ampliados',
    'SIM',
    case when exists (
      select 1
      from pg_constraint constraint_info
      where constraint_info.conname = 'skpe_objective_relations_type_check'
        and constraint_info.conrelid =
          'public.skpe_objective_relations'::regclass
        and pg_get_constraintdef(constraint_info.oid) ilike '%contributes_to%'
        and pg_get_constraintdef(constraint_info.oid) ilike '%depends_on%'
        and pg_get_constraintdef(constraint_info.oid) ilike '%influences%'
    ) then 'SIM' else 'NAO' end,
    null

  union all

  select
    'REGRA_METODOLOGICA',
    'Readiness separa FE-04 de Indicadores, OKRs e Iniciativas',
    'SIM',
    case when pg_get_functiondef(
      to_regprocedure('public.get_skpe_strategic_map_readiness(uuid)')
    ) ilike '%indicatorRequiredInFe04%false%'
      and pg_get_functiondef(
        to_regprocedure('public.get_skpe_strategic_map_readiness(uuid)')
      ) ilike '%okrRequiredInFe04%false%'
      and pg_get_functiondef(
        to_regprocedure('public.get_skpe_strategic_map_readiness(uuid)')
      ) ilike '%initiativeRequiredInFe04%false%'
    then 'SIM' else 'NAO' end,
    null

  union all

  select
    'REGRA_METODOLOGICA',
    'Ordenação impeditiva de Temas, Perspectivas e Objetivos é verificada',
    'SIM',
    case when pg_get_functiondef(
      to_regprocedure('public.get_skpe_strategic_map_readiness(uuid)')
    ) ilike '%THEME_ORDER_DUPLICATE%'
      and pg_get_functiondef(
        to_regprocedure('public.get_skpe_strategic_map_readiness(uuid)')
      ) ilike '%PERSPECTIVE_ORDER_DUPLICATE%'
      and pg_get_functiondef(
        to_regprocedure('public.get_skpe_strategic_map_readiness(uuid)')
      ) ilike '%OBJECTIVE_ORDER_DUPLICATE_IN_PERSPECTIVE%'
    then 'SIM' else 'NAO' end,
    null

  union all

  select
    'REGRA_METODOLOGICA',
    'Objetivo exige Perspectiva, resultado esperado e racional',
    'SIM',
    case when pg_get_functiondef(
      to_regprocedure('public.get_skpe_strategic_map_readiness(uuid)')
    ) ilike '%OBJECTIVE_WITHOUT_PERSPECTIVE%'
      and pg_get_functiondef(
        to_regprocedure('public.get_skpe_strategic_map_readiness(uuid)')
      ) ilike '%OBJECTIVE_WITHOUT_EXPECTED_RESULT%'
      and pg_get_functiondef(
        to_regprocedure('public.get_skpe_strategic_map_readiness(uuid)')
      ) ilike '%OBJECTIVE_WITHOUT_RATIONALE%'
    then 'SIM' else 'NAO' end,
    null

  union all

  select
    'REGRA_METODOLOGICA',
    'Tema obrigatório é configurável por Formulação',
    'SIM',
    case when pg_get_functiondef(
      to_regprocedure('public.configure_skpe_strategic_map(uuid,boolean,text,boolean,jsonb,text)')
    ) ilike '%theme_required%'
      and pg_get_functiondef(
        to_regprocedure('public.get_skpe_strategic_map_readiness(uuid)')
      ) ilike '%OBJECTIVE_WITHOUT_THEME%'
    then 'SIM' else 'NAO' end,
    null

  union all

  select
    'REGRA_METODOLOGICA',
    'Ciclos causais podem ser sinalizados ou bloqueados',
    'SIM',
    case when pg_get_functiondef(
      to_regprocedure('public.upsert_skpe_objective_relation(uuid,uuid,uuid,text,text,numeric,text,integer,uuid,jsonb,text)')
    ) ilike '%causal_cycle_policy%'
      and pg_get_functiondef(
        to_regprocedure('public.get_skpe_strategic_map_readiness(uuid)')
      ) ilike '%CAUSAL_CYCLE_WARNING%'
      and pg_get_functiondef(
        to_regprocedure('public.get_skpe_strategic_map_readiness(uuid)')
      ) ilike '%CAUSAL_CYCLE_BLOCKED%'
    then 'SIM' else 'NAO' end,
    null

  union all

  select
    'REGRA_GOVERNANCA',
    'Toda mutação invalida validação anterior',
    'SIM',
    case when pg_get_functiondef(
      to_regprocedure('public.upsert_skpe_strategic_theme(uuid,text,text,text,text,uuid,text,integer,date,date,uuid,text,text,jsonb,text)')
    ) ilike '%skpe_invalidate_strategic_map_package%'
      and pg_get_functiondef(
        to_regprocedure('public.upsert_skpe_bsc_perspective(uuid,text,text,text,uuid,integer,text,text,text,text,jsonb,text)')
      ) ilike '%skpe_invalidate_strategic_map_package%'
      and pg_get_functiondef(
        to_regprocedure('public.upsert_skpe_strategic_objective(uuid,text,text,text,text,text,uuid,uuid,uuid,text,date,date,uuid,text,integer,jsonb,text,jsonb,text)')
      ) ilike '%skpe_invalidate_strategic_map_package%'
      and pg_get_functiondef(
        to_regprocedure('public.upsert_skpe_objective_relation(uuid,uuid,uuid,text,text,numeric,text,integer,uuid,jsonb,text)')
      ) ilike '%skpe_invalidate_strategic_map_package%'
    then 'SIM' else 'NAO' end,
    null

  union all

  select
    'REGRA_GOVERNANCA',
    'Avanço da Formulação exige pacote FE-04 validado',
    'SIM',
    case when pg_get_functiondef(
      to_regprocedure('public.skpe_guard_formulation_strategic_map_ready()')
    ) ilike '%readyForFormulation%'
      and pg_get_functiondef(
        to_regprocedure('public.skpe_guard_formulation_strategic_map_ready()')
      ) ilike '%pending_validation%'
      and pg_get_functiondef(
        to_regprocedure('public.skpe_guard_formulation_strategic_map_ready()')
      ) ilike '%approved%'
    then 'SIM' else 'NAO' end,
    null

  union all

  select
    'REGRA_GOVERNANCA',
    'Códigos legados dos Objetivos permanecem sincronizados',
    'SIM',
    case when pg_get_functiondef(
      to_regprocedure('public.upsert_skpe_strategic_theme(uuid,text,text,text,text,uuid,text,integer,date,date,uuid,text,text,jsonb,text)')
    ) ilike '%strategic_objective_theme_code_synchronized%'
      and pg_get_functiondef(
        to_regprocedure('public.upsert_skpe_bsc_perspective(uuid,text,text,text,uuid,integer,text,text,text,text,jsonb,text)')
      ) ilike '%strategic_objective_perspective_code_synchronized%'
    then 'SIM' else 'NAO' end,
    null

  union all

  select
    'REGRA_VERSIONAMENTO',
    'Configuração do pacote é preservada em revisão derivada',
    'SIM',
    case when pg_get_functiondef(
      to_regprocedure('public.ensure_skpe_strategic_map_package(uuid)')
    ) ilike '%derived_from_formulation_id%'
      and pg_get_functiondef(
        to_regprocedure('public.ensure_skpe_strategic_map_package(uuid)')
      ) ilike '%clonedFromStrategicMapPackageId%'
    then 'SIM' else 'NAO' end,
    null

  union all

  select
    'AUDITORIA',
    expected_functions.function_signature,
    'USA_AUDITORIA',
    case
      when expected_functions.api_class = 'internal'
        then 'NAO_APLICAVEL'
      when expected_functions.function_signature like '%get_skpe_%'
        then 'NAO_APLICAVEL'
      when pg_get_functiondef(
        to_regprocedure(expected_functions.function_signature)
      ) ilike '%skpe_record_operational_audit%'
        then 'USA_AUDITORIA'
      else 'REVISAR'
    end,
    null
  from expected_functions
  where expected_functions.api_class = 'public'
    and expected_functions.function_signature not like
      'public.get_skpe_strategic_map_readiness%'
    and expected_functions.function_signature not like
      'public.get_skpe_strategic_map(%'
    and expected_functions.function_signature not like
      'public.get_skpe_strategic_map_audit%'

  union all

  select
    'JUSTIFICATIVA',
    expected_functions.function_signature,
    'OBRIGATORIA',
    case when pg_get_functiondef(
      to_regprocedure(expected_functions.function_signature)
    ) ilike '%skpe_assert_reason%'
      then 'OBRIGATORIA'
      else 'REVISAR'
    end,
    null
  from expected_functions
  where expected_functions.api_class = 'public'
    and expected_functions.function_signature not like
      'public.get_skpe_strategic_map_readiness%'
    and expected_functions.function_signature not like
      'public.get_skpe_strategic_map(%'
    and expected_functions.function_signature not like
      'public.get_skpe_strategic_map_audit%'

  union all

  select
    'PRIVILEGIO_DIRETO',
    controlled_tables.table_name || ' sem INSERT para authenticated',
    'NAO',
    case when has_table_privilege(
      'authenticated',
      format('public.%I', controlled_tables.table_name),
      'INSERT'
    ) then 'SIM' else 'NAO' end,
    null
  from controlled_tables

  union all

  select
    'PRIVILEGIO_DIRETO',
    controlled_tables.table_name || ' sem UPDATE para authenticated',
    'NAO',
    case when has_table_privilege(
      'authenticated',
      format('public.%I', controlled_tables.table_name),
      'UPDATE'
    ) then 'SIM' else 'NAO' end,
    null
  from controlled_tables

  union all

  select
    'PRIVILEGIO_DIRETO',
    controlled_tables.table_name || ' sem DELETE para authenticated',
    'NAO',
    case when has_table_privilege(
      'authenticated',
      format('public.%I', controlled_tables.table_name),
      'DELETE'
    ) then 'SIM' else 'NAO' end,
    null
  from controlled_tables

  union all

  select
    'PRIVILEGIO_SERVICE_ROLE',
    controlled_tables.table_name || ' com escrita para service_role',
    'SIM',
    case when
      has_table_privilege(
        'service_role',
        format('public.%I', controlled_tables.table_name),
        'INSERT'
      )
      and has_table_privilege(
        'service_role',
        format('public.%I', controlled_tables.table_name),
        'UPDATE'
      )
      and has_table_privilege(
        'service_role',
        format('public.%I', controlled_tables.table_name),
        'DELETE'
      )
    then 'SIM' else 'NAO' end,
    null
  from controlled_tables

  union all

  select
    'INTEGRIDADE',
    'Pacotes duplicados por Formulação',
    '0',
    count(*)::text,
    null
  from (
    select formulation_id
    from public.skpe_strategic_map_packages
    group by formulation_id
    having count(*) > 1
  ) duplicated_packages

  union all

  select
    'INTEGRIDADE',
    'Objetivos fora do escopo da Formulação',
    '0',
    count(*)::text,
    null
  from public.skpe_strategic_objectives objective
  join public.skpe_strategic_formulations formulation
    on formulation.id = objective.formulation_id
  where objective.organization_id <> formulation.organization_id
     or objective.project_id <> formulation.project_id

  union all

  select
    'INTEGRIDADE',
    'Relações entre Objetivos de Formulações diferentes',
    '0',
    count(*)::text,
    null
  from public.skpe_objective_relations relation
  join public.skpe_strategic_objectives source_objective
    on source_objective.id = relation.source_objective_id
  join public.skpe_strategic_objectives target_objective
    on target_objective.id = relation.target_objective_id
  where source_objective.formulation_id <> relation.formulation_id
     or target_objective.formulation_id <> relation.formulation_id
     or source_objective.formulation_id <> target_objective.formulation_id

  union all

  select
    'INTEGRIDADE',
    'Relações apontando para Objetivo arquivado',
    '0',
    count(*)::text,
    null
  from public.skpe_objective_relations relation
  join public.skpe_strategic_objectives source_objective
    on source_objective.id = relation.source_objective_id
  join public.skpe_strategic_objectives target_objective
    on target_objective.id = relation.target_objective_id
  where source_objective.status = 'archived'
     or target_objective.status = 'archived'

  union all

  select
    'INTEGRIDADE',
    'Relações causais do Objetivo consigo próprio',
    '0',
    count(*)::text,
    null
  from public.skpe_objective_relations relation
  where relation.source_objective_id = relation.target_objective_id

  union all

  select
    'INTEGRIDADE',
    'Relações causais duplicadas',
    '0',
    count(*)::text,
    null
  from (
    select
      source_objective_id,
      target_objective_id,
      relation_type
    from public.skpe_objective_relations
    group by
      source_objective_id,
      target_objective_id,
      relation_type
    having count(*) > 1
  ) duplicated_relations

  union all

  select
    'SITUACAO',
    'Pacotes FE-04 atualmente cadastrados',
    count(*)::text,
    count(*)::text,
    null
  from public.skpe_strategic_map_packages

  union all

  select
    'SITUACAO',
    'Objetivos Estratégicos vinculados a Formulações',
    count(*)::text,
    count(*)::text,
    null
  from public.skpe_strategic_objectives
  where formulation_id is not null
)
select
  check_group,
  check_item,
  expected_value,
  actual_value,
  case
    when expected_value = actual_value then 'OK'
    else 'ERRO'
  end as status,
  details
from checks
order by
  case check_group
    when 'TABELA' then 1
    when 'RLS' then 2
    when 'INDICE' then 3
    when 'FUNCAO' then 4
    when 'SEGURANCA_FUNCAO' then 5
    when 'SEARCH_PATH' then 6
    when 'EXECUCAO_AUTHENTICATED' then 7
    when 'TRIGGER' then 8
    when 'CONSTRAINT' then 9
    when 'REGRA_METODOLOGICA' then 10
    when 'REGRA_GOVERNANCA' then 11
    when 'REGRA_VERSIONAMENTO' then 12
    when 'AUDITORIA' then 13
    when 'JUSTIFICATIVA' then 14
    when 'PRIVILEGIO_DIRETO' then 15
    when 'PRIVILEGIO_SERVICE_ROLE' then 16
    when 'INTEGRIDADE' then 17
    when 'SITUACAO' then 18
    else 19
  end,
  check_item;
