-- ============================================================
-- FE-01 — Verificação consolidada
-- Governança e versionamento da Formulação Estratégica
-- SOMENTE LEITURA — retorna um único grid.
-- ============================================================

with
expected_columns(column_name) as (
  values
    ('status_changed_at'),
    ('status_changed_by'),
    ('submitted_for_validation_at'),
    ('submitted_for_validation_by'),
    ('validated_at'),
    ('validated_by'),
    ('validation_notes'),
    ('submitted_for_approval_at'),
    ('submitted_for_approval_by'),
    ('approval_notes'),
    ('archived_at'),
    ('archived_by')
),
expected_indexes(index_name) as (
  values
    ('ux_skpe_objectives_formulation_code'),
    ('ux_skpe_objectives_legacy_project_code'),
    ('ux_skpe_indicators_formulation_code'),
    ('ux_skpe_indicators_legacy_project_code')
),
expected_functions(function_signature) as (
  values
    ('public.skpe_assert_formulation_editable(uuid)'),
    ('public.clone_skpe_formulation_content(uuid,uuid)'),
    ('public.create_skpe_formulation(uuid,text,text,text,date,date,text)'),
    ('public.update_skpe_formulation(uuid,text,text,text,date,date,jsonb,text)'),
    ('public.create_skpe_formulation_revision(uuid,text,text,date,date,text)'),
    ('public.transition_skpe_formulation(uuid,text,text,text)'),
    ('public.get_skpe_formulations(uuid,uuid)'),
    ('public.get_skpe_formulation_audit(uuid)')
),
public_rpc_functions(function_signature) as (
  values
    ('public.create_skpe_formulation(uuid,text,text,text,date,date,text)'),
    ('public.update_skpe_formulation(uuid,text,text,text,date,date,jsonb,text)'),
    ('public.create_skpe_formulation_revision(uuid,text,text,date,date,text)'),
    ('public.transition_skpe_formulation(uuid,text,text,text)'),
    ('public.get_skpe_formulations(uuid,uuid)'),
    ('public.get_skpe_formulation_audit(uuid)')
),
checks as (
  select
    'COLUNA'::text as check_group,
    'skpe_strategic_formulations.' || expected_columns.column_name as check_item,
    'EXISTE'::text as expected_value,
    case when exists (
      select 1
      from information_schema.columns column_info
      where column_info.table_schema = 'public'
        and column_info.table_name = 'skpe_strategic_formulations'
        and column_info.column_name = expected_columns.column_name
    ) then 'EXISTE' else 'AUSENTE' end as actual_value
  from expected_columns

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
    ) then 'EXISTE' else 'AUSENTE' end
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
    'REGRA_ARQUITETURAL',
    'Constraint legada de código do Objetivo por projeto',
    'AUSENTE',
    case when exists (
      select 1
      from pg_constraint
      where conname = 'skpe_strategic_objectives_unique_code'
        and conrelid = 'public.skpe_strategic_objectives'::regclass
    ) then 'EXISTE' else 'AUSENTE' end

  union all

  select
    'REGRA_ARQUITETURAL',
    'Constraint legada de código do Indicador por projeto',
    'AUSENTE',
    case when exists (
      select 1
      from pg_constraint
      where conname = 'skpe_indicators_unique'
        and conrelid = 'public.skpe_indicators'::regclass
    ) then 'EXISTE' else 'AUSENTE' end

  union all

  select
    'PROTECAO',
    'Triggers de bloqueio do conteúdo versionado',
    '16',
    count(*)::text
  from pg_trigger trigger_info
  where not trigger_info.tgisinternal
    and trigger_info.tgname like '%_guard_approved_formulation'

  union all

  select
    'PROTECAO',
    'Função de bloqueio exige estado editável',
    'SIM',
    case when pg_get_functiondef(
      to_regprocedure('public.skpe_guard_approved_formulation_content()')
    ) ilike '%not in (''draft'', ''in_elaboration'')%'
    then 'SIM' else 'NAO' end

  union all

  select
    'AUDITORIA',
    'Política de leitura inclui a Formulação Estratégica',
    'SIM',
    case when exists (
      select 1
      from pg_policies policy_info
      where policy_info.schemaname = 'public'
        and policy_info.tablename = 'skpe_operational_audit'
        and policy_info.policyname = 'skpe_operational_audit_select'
        and policy_info.qual ilike '%can_view_skpe_formulation%'
    ) then 'SIM' else 'NAO' end

  union all

  select
    'PRIVILEGIO_DIRETO',
    'authenticated pode inserir diretamente em skpe_strategic_formulations',
    'NAO',
    case when has_table_privilege(
      'authenticated',
      'public.skpe_strategic_formulations',
      'INSERT'
    ) then 'SIM' else 'NAO' end

  union all

  select
    'PRIVILEGIO_DIRETO',
    'authenticated pode atualizar diretamente skpe_strategic_formulations',
    'NAO',
    case when has_table_privilege(
      'authenticated',
      'public.skpe_strategic_formulations',
      'UPDATE'
    ) then 'SIM' else 'NAO' end

  union all

  select
    'INTEGRIDADE',
    'Projetos com mais de uma versão aberta',
    '0',
    count(*)::text
  from (
    select project_id
    from public.skpe_strategic_formulations
    where status in (
      'draft',
      'in_elaboration',
      'pending_validation',
      'validated',
      'pending_approval'
    )
    group by project_id
    having count(*) > 1
  ) duplicated_open

  union all

  select
    'INTEGRIDADE',
    'Projetos com mais de uma versão aprovada',
    '0',
    count(*)::text
  from (
    select project_id
    from public.skpe_strategic_formulations
    where status = 'approved'
    group by project_id
    having count(*) > 1
  ) duplicated_approved

  union all

  select
    'SITUACAO',
    'Versões da Formulação atualmente cadastradas',
    count(*)::text,
    count(*)::text
  from public.skpe_strategic_formulations
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
    when 'REGRA_ARQUITETURAL' then 1
    when 'COLUNA' then 2
    when 'INDICE' then 3
    when 'FUNCAO' then 4
    when 'SEGURANCA_FUNCAO' then 5
    when 'EXECUCAO_AUTHENTICATED' then 6
    when 'PROTECAO' then 7
    when 'AUDITORIA' then 8
    when 'PRIVILEGIO_DIRETO' then 9
    when 'INTEGRIDADE' then 10
    else 11
  end,
  check_item;
