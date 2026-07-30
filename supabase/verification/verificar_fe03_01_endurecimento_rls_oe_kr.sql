-- ============================================================
-- FE-03.01 — Verificação consolidada
-- Endurecimento de RLS dos Objetivos Estratégicos e KRs
-- SOMENTE LEITURA — retorna um único grid.
-- ============================================================

with controlled_tables(table_name, select_policy_name) as (
  values
    ('skpe_strategic_objectives', 'skpe_strategic_objectives_select'),
    ('skpe_key_results', 'skpe_key_results_select')
),
checks as (
  select
    'RLS'::text as check_group,
    controlled.table_name as check_item,
    'HABILITADA'::text as expected_value,
    case when class.relrowsecurity
      then 'HABILITADA'
      else 'DESABILITADA'
    end as actual_value
  from controlled_tables controlled
  join pg_namespace namespace
    on namespace.nspname = 'public'
  join pg_class class
    on class.relnamespace = namespace.oid
   and class.relname = controlled.table_name
   and class.relkind in ('r', 'p')

  union all

  select
    'POLITICA_SELECT',
    controlled.select_policy_name,
    'EXISTE',
    case when exists (
      select 1
      from pg_policies policy
      where policy.schemaname = 'public'
        and policy.tablename = controlled.table_name
        and policy.policyname = controlled.select_policy_name
        and policy.cmd = 'SELECT'
        and policy.roles::text ilike '%authenticated%'
    ) then 'EXISTE' else 'AUSENTE' end
  from controlled_tables controlled

  union all

  select
    'AUTORIZACAO_LEITURA',
    controlled.table_name || ' aceita permissão de Iniciativas',
    'SIM',
    case when exists (
      select 1
      from pg_policies policy
      where policy.schemaname = 'public'
        and policy.tablename = controlled.table_name
        and policy.policyname = controlled.select_policy_name
        and coalesce(policy.qual, '') ilike
          '%can_view_skpe_initiatives%'
    ) then 'SIM' else 'NAO' end
  from controlled_tables controlled

  union all

  select
    'AUTORIZACAO_LEITURA',
    controlled.table_name || ' aceita permissão de Formulação',
    'SIM',
    case when exists (
      select 1
      from pg_policies policy
      where policy.schemaname = 'public'
        and policy.tablename = controlled.table_name
        and policy.policyname = controlled.select_policy_name
        and coalesce(policy.qual, '') ilike
          '%can_view_skpe_formulation%'
    ) then 'SIM' else 'NAO' end
  from controlled_tables controlled

  union all

  select
    'POLITICA_ESCRITA',
    controlled.table_name || ' sem política DML para authenticated',
    'SIM',
    case when not exists (
      select 1
      from pg_policies policy
      where policy.schemaname = 'public'
        and policy.tablename = controlled.table_name
        and policy.cmd in ('ALL', 'INSERT', 'UPDATE', 'DELETE')
        and (
          policy.roles::text ilike '%authenticated%'
          or policy.roles::text ilike '%public%'
        )
    ) then 'SIM' else 'NAO' end
  from controlled_tables controlled

  union all

  select
    'PRIVILEGIO_AUTHENTICATED',
    controlled.table_name || ' SELECT',
    'CONCEDIDO',
    case when has_table_privilege(
      'authenticated',
      format('public.%I', controlled.table_name),
      'SELECT'
    ) then 'CONCEDIDO' else 'AUSENTE' end
  from controlled_tables controlled

  union all

  select
    'PRIVILEGIO_AUTHENTICATED',
    controlled.table_name || ' INSERT',
    'NEGADO',
    case when has_table_privilege(
      'authenticated',
      format('public.%I', controlled.table_name),
      'INSERT'
    ) then 'CONCEDIDO' else 'NEGADO' end
  from controlled_tables controlled

  union all

  select
    'PRIVILEGIO_AUTHENTICATED',
    controlled.table_name || ' UPDATE',
    'NEGADO',
    case when has_table_privilege(
      'authenticated',
      format('public.%I', controlled.table_name),
      'UPDATE'
    ) then 'CONCEDIDO' else 'NEGADO' end
  from controlled_tables controlled

  union all

  select
    'PRIVILEGIO_AUTHENTICATED',
    controlled.table_name || ' DELETE',
    'NEGADO',
    case when has_table_privilege(
      'authenticated',
      format('public.%I', controlled.table_name),
      'DELETE'
    ) then 'CONCEDIDO' else 'NEGADO' end
  from controlled_tables controlled

  union all

  select
    'PRIVILEGIO_SERVICE_ROLE',
    controlled.table_name || ' escrita operacional',
    'CONCEDIDA',
    case when
      has_table_privilege(
        'service_role',
        format('public.%I', controlled.table_name),
        'INSERT'
      )
      and has_table_privilege(
        'service_role',
        format('public.%I', controlled.table_name),
        'UPDATE'
      )
      and has_table_privilege(
        'service_role',
        format('public.%I', controlled.table_name),
        'DELETE'
      )
    then 'CONCEDIDA' else 'AUSENTE' end
  from controlled_tables controlled

  union all

  select
    'POLITICA_LEGADA',
    'skpe_key_results_manage',
    'AUSENTE',
    case when exists (
      select 1
      from pg_policies policy
      where policy.schemaname = 'public'
        and policy.tablename = 'skpe_key_results'
        and policy.policyname = 'skpe_key_results_manage'
    ) then 'EXISTE' else 'AUSENTE' end

  union all

  select
    'RESUMO',
    'Tabelas com escrita direta para authenticated',
    '0',
    count(*)::text
  from controlled_tables controlled
  where
    has_table_privilege(
      'authenticated',
      format('public.%I', controlled.table_name),
      'INSERT'
    )
    or has_table_privilege(
      'authenticated',
      format('public.%I', controlled.table_name),
      'UPDATE'
    )
    or has_table_privilege(
      'authenticated',
      format('public.%I', controlled.table_name),
      'DELETE'
    )
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
    when 'RESUMO' then 1
    when 'RLS' then 2
    when 'POLITICA_SELECT' then 3
    when 'AUTORIZACAO_LEITURA' then 4
    when 'POLITICA_ESCRITA' then 5
    when 'PRIVILEGIO_AUTHENTICATED' then 6
    when 'PRIVILEGIO_SERVICE_ROLE' then 7
    else 8
  end,
  check_item;
