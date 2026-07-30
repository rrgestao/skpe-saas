-- ============================================================
-- Plataforma SPARKs / SK-PE
-- Verificação transversal final de RLS — FE-00 a FE-03
--
-- SOMENTE LEITURA.
--
-- Finalidade:
-- 1. Confirmar existência das 22 tabelas da Formulação e do domínio
--    compartilhado de Arquitetura de Negócios.
-- 2. Confirmar RLS habilitada.
-- 3. Confirmar política SELECT para authenticated.
-- 4. Confirmar permissão SELECT e ausência de escrita direta.
-- 5. Confirmar que as políticas utilizam funções de autorização
--    compatíveis com o domínio de cada tabela.
--
-- A consulta retorna um único grid.
-- ============================================================

with expected_tables (
  table_name,
  domain_group,
  expected_authorization
) as (
  values
    ('platform_business_artifacts',
      'ARQUITETURA_NEGOCIOS',
      'can_view_business_architecture'),
    ('platform_business_artifact_versions',
      'ARQUITETURA_NEGOCIOS',
      'can_view_business_architecture'),
    ('platform_business_artifact_elements',
      'ARQUITETURA_NEGOCIOS',
      'can_view_business_architecture'),
    ('platform_business_artifact_element_relations',
      'ARQUITETURA_NEGOCIOS',
      'can_view_business_architecture'),
    ('platform_business_artifact_version_relations',
      'ARQUITETURA_NEGOCIOS',
      'can_view_business_architecture'),

    ('skpe_formulation_business_inputs',
      'FORMULACAO',
      'can_view_skpe_formulation'),
    ('skpe_strategic_formulations',
      'FORMULACAO',
      'can_view_skpe_formulation'),
    ('skpe_strategic_identity',
      'FORMULACAO',
      'can_view_skpe_formulation'),
    ('skpe_strategic_identity_items',
      'FORMULACAO',
      'can_view_skpe_formulation'),
    ('skpe_strategic_values',
      'FORMULACAO',
      'can_view_skpe_formulation'),
    ('skpe_strategic_value_behaviors',
      'FORMULACAO',
      'can_view_skpe_formulation'),
    ('skpe_strategic_themes',
      'FORMULACAO',
      'can_view_skpe_formulation'),
    ('skpe_bsc_perspectives',
      'FORMULACAO',
      'can_view_skpe_formulation'),
    ('skpe_objective_relations',
      'FORMULACAO',
      'can_view_skpe_formulation'),
    ('skpe_okr_cycles',
      'FORMULACAO',
      'can_view_skpe_formulation'),
    ('skpe_okrs',
      'FORMULACAO',
      'can_view_skpe_formulation'),
    ('skpe_okr_objectives',
      'FORMULACAO',
      'can_view_skpe_formulation'),
    ('skpe_indicators',
      'FORMULACAO',
      'can_view_skpe_formulation'),
    ('skpe_indicator_targets',
      'FORMULACAO',
      'can_view_skpe_formulation'),
    ('skpe_benchmark_references',
      'FORMULACAO',
      'can_view_skpe_formulation'),

    ('skpe_strategic_objectives',
      'COMPARTILHADA_LEGADO_FORMULACAO',
      'autorizacao_escopada'),
    ('skpe_key_results',
      'COMPARTILHADA_LEGADO_FORMULACAO',
      'autorizacao_escopada')
),
table_inventory as (
  select
    expected.table_name,
    expected.domain_group,
    expected.expected_authorization,
    class.oid as table_oid,
    class.relrowsecurity as rls_enabled,
    class.relforcerowsecurity as force_rls_enabled
  from expected_tables expected
  left join pg_namespace namespace
    on namespace.nspname = 'public'
  left join pg_class class
    on class.relnamespace = namespace.oid
   and class.relname = expected.table_name
   and class.relkind in ('r', 'p')
),
policy_inventory as (
  select
    expected.table_name,
    count(*) filter (
      where policy.cmd = 'SELECT'
        and (
          policy.roles::text ilike '%authenticated%'
          or policy.roles::text ilike '%public%'
        )
    ) as authenticated_select_policy_count,
    count(*) as policy_count,
    string_agg(
      policy.policyname || ' [' || policy.cmd || '] roles=' ||
      policy.roles::text || ' using=' ||
      coalesce(policy.qual, '<sem USING>'),
      E'\n'
      order by policy.policyname
    ) as policy_details,
    bool_or(
      coalesce(policy.qual, '') ilike
        '%can_view_business_architecture%'
    ) as uses_business_architecture_permission,
    bool_or(
      coalesce(policy.qual, '') ilike
        '%can_view_skpe_formulation%'
    ) as uses_formulation_permission,
    bool_or(
      coalesce(policy.qual, '') ilike
        '%can_view_skpe_initiatives%'
      or coalesce(policy.qual, '') ilike
        '%can_view_skpe_journey%'
      or coalesce(policy.qual, '') ilike
        '%can_view_skpe_formulation%'
    ) as uses_scoped_skpe_permission
  from expected_tables expected
  left join pg_policies policy
    on policy.schemaname = 'public'
   and policy.tablename = expected.table_name
  group by expected.table_name
),
table_checks as (
  select
    inventory.domain_group,
    inventory.table_name,
    'TABELA_EXISTE'::text as check_item,
    'SIM'::text as expected_value,
    case when inventory.table_oid is not null
      then 'SIM'
      else 'NAO'
    end as actual_value,
    null::text as details
  from table_inventory inventory

  union all

  select
    inventory.domain_group,
    inventory.table_name,
    'RLS_HABILITADA',
    'SIM',
    case when coalesce(inventory.rls_enabled, false)
      then 'SIM'
      else 'NAO'
    end,
    'FORCE_RLS=' ||
      case when coalesce(inventory.force_rls_enabled, false)
        then 'SIM'
        else 'NAO'
      end
  from table_inventory inventory

  union all

  select
    inventory.domain_group,
    inventory.table_name,
    'POLITICA_SELECT_AUTHENTICATED',
    'SIM',
    case when coalesce(policy.authenticated_select_policy_count, 0) > 0
      then 'SIM'
      else 'NAO'
    end,
    coalesce(policy.policy_details, '<nenhuma política>')
  from table_inventory inventory
  left join policy_inventory policy
    on policy.table_name = inventory.table_name

  union all

  select
    inventory.domain_group,
    inventory.table_name,
    'AUTORIZACAO_ESCOPADA_NA_POLITICA',
    'SIM',
    case
      when inventory.expected_authorization =
        'can_view_business_architecture'
        and coalesce(
          policy.uses_business_architecture_permission,
          false
        )
        then 'SIM'
      when inventory.expected_authorization =
        'can_view_skpe_formulation'
        and coalesce(
          policy.uses_formulation_permission,
          false
        )
        then 'SIM'
      when inventory.expected_authorization =
        'autorizacao_escopada'
        and coalesce(
          policy.uses_scoped_skpe_permission,
          false
        )
        then 'SIM'
      else 'NAO'
    end,
    'esperado=' || inventory.expected_authorization ||
      E'\n' || coalesce(policy.policy_details, '<nenhuma política>')
  from table_inventory inventory
  left join policy_inventory policy
    on policy.table_name = inventory.table_name

  union all

  select
    inventory.domain_group,
    inventory.table_name,
    'SELECT_CONCEDIDO_AUTHENTICATED',
    'SIM',
    case
      when inventory.table_oid is not null
       and has_table_privilege(
         'authenticated',
         format('public.%I', inventory.table_name),
         'SELECT'
       )
        then 'SIM'
      else 'NAO'
    end,
    null
  from table_inventory inventory

  union all

  select
    inventory.domain_group,
    inventory.table_name,
    'ESCRITA_DIRETA_AUTHENTICATED',
    'NAO',
    case
      when inventory.table_oid is null then 'TABELA_AUSENTE'
      when has_table_privilege(
        'authenticated',
        format('public.%I', inventory.table_name),
        'INSERT'
      )
      or has_table_privilege(
        'authenticated',
        format('public.%I', inventory.table_name),
        'UPDATE'
      )
      or has_table_privilege(
        'authenticated',
        format('public.%I', inventory.table_name),
        'DELETE'
      )
        then 'SIM'
      else 'NAO'
    end,
    'INSERT=' ||
      case
        when inventory.table_oid is not null
         and has_table_privilege(
           'authenticated',
           format('public.%I', inventory.table_name),
           'INSERT'
         )
          then 'SIM'
        else 'NAO'
      end ||
      '; UPDATE=' ||
      case
        when inventory.table_oid is not null
         and has_table_privilege(
           'authenticated',
           format('public.%I', inventory.table_name),
           'UPDATE'
         )
          then 'SIM'
        else 'NAO'
      end ||
      '; DELETE=' ||
      case
        when inventory.table_oid is not null
         and has_table_privilege(
           'authenticated',
           format('public.%I', inventory.table_name),
           'DELETE'
         )
          then 'SIM'
        else 'NAO'
      end
  from table_inventory inventory
),
summary_checks as (
  select
    'RESUMO'::text as domain_group,
    '22_TABELAS_CONTROLADAS'::text as table_name,
    'TABELAS_EXISTENTES'::text as check_item,
    '22'::text as expected_value,
    count(*) filter (where table_oid is not null)::text as actual_value,
    null::text as details
  from table_inventory

  union all

  select
    'RESUMO',
    '22_TABELAS_CONTROLADAS',
    'TABELAS_COM_RLS',
    '22',
    count(*) filter (where coalesce(rls_enabled, false))::text,
    null
  from table_inventory

  union all

  select
    'RESUMO',
    '22_TABELAS_CONTROLADAS',
    'TABELAS_COM_POLITICA_SELECT_AUTHENTICATED',
    '22',
    count(*) filter (
      where coalesce(
        policy.authenticated_select_policy_count,
        0
      ) > 0
    )::text,
    null
  from table_inventory inventory
  left join policy_inventory policy
    on policy.table_name = inventory.table_name

  union all

  select
    'RESUMO',
    '22_TABELAS_CONTROLADAS',
    'TABELAS_COM_ESCRITA_DIRETA_AUTHENTICATED',
    '0',
    count(*) filter (
      where inventory.table_oid is not null
        and (
          has_table_privilege(
            'authenticated',
            format('public.%I', inventory.table_name),
            'INSERT'
          )
          or has_table_privilege(
            'authenticated',
            format('public.%I', inventory.table_name),
            'UPDATE'
          )
          or has_table_privilege(
            'authenticated',
            format('public.%I', inventory.table_name),
            'DELETE'
          )
        )
    )::text,
    null
  from table_inventory inventory
),
all_checks as (
  select * from summary_checks
  union all
  select * from table_checks
)
select
  domain_group as check_group,
  table_name,
  check_item,
  expected_value,
  actual_value,
  case
    when expected_value = actual_value then 'OK'
    else 'REVISAR'
  end as verification_status,
  details
from all_checks
order by
  case domain_group
    when 'RESUMO' then 1
    when 'ARQUITETURA_NEGOCIOS' then 2
    when 'FORMULACAO' then 3
    else 4
  end,
  table_name,
  case check_item
    when 'TABELA_EXISTE' then 1
    when 'RLS_HABILITADA' then 2
    when 'POLITICA_SELECT_AUTHENTICATED' then 3
    when 'AUTORIZACAO_ESCOPADA_NA_POLITICA' then 4
    when 'SELECT_CONCEDIDO_AUTHENTICATED' then 5
    when 'ESCRITA_DIRETA_AUTHENTICATED' then 6
    else 7
  end;
