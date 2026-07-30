-- ============================================================
-- FE-00 — Verificação da Formulação Estratégica e da
-- Arquitetura de Negócios Compartilhada
-- SOMENTE LEITURA
-- ============================================================

with expected_objects(object_name) as (
  values
    ('skpe_strategic_formulations'),
    ('skpe_strategic_identity'),
    ('skpe_strategic_identity_items'),
    ('skpe_strategic_values'),
    ('skpe_strategic_value_behaviors'),
    ('platform_business_artifacts'),
    ('platform_business_artifact_versions'),
    ('platform_business_artifact_elements'),
    ('platform_business_artifact_element_relations'),
    ('platform_business_artifact_version_relations'),
    ('skpe_formulation_business_inputs'),
    ('skpe_strategic_themes'),
    ('skpe_bsc_perspectives'),
    ('skpe_objective_relations'),
    ('skpe_okr_cycles'),
    ('skpe_okrs'),
    ('skpe_okr_objectives'),
    ('skpe_indicators'),
    ('skpe_indicator_targets'),
    ('skpe_benchmark_references')
)
select
  object_name,
  case
    when to_regclass(format('public.%I', object_name)) is not null
      then 'OK'
    else 'AUSENTE'
  end as verification_status
from expected_objects
order by object_name;

select
  m.code as module_code,
  mp.code as permission_code,
  mp.name as permission_name,
  mp.permission_group,
  mp.active
from public.modules m
join public.module_permissions mp on mp.module_id = m.id
where m.code = 'SK-PE'
  and mp.code in (
    'strategic_formulation.view',
    'strategic_formulation.manage',
    'strategic_formulation.validate',
    'strategic_formulation.approve',
    'business_architecture.view',
    'business_architecture.manage'
  )
order by mp.permission_group, mp.code;

select
  mr.code as role_code,
  mp.code as permission_code
from public.module_roles mr
join public.role_permissions rp on rp.module_role_id = mr.id
join public.module_permissions mp on mp.id = rp.module_permission_id
join public.modules m on m.id = mr.module_id
where m.code = 'SK-PE'
  and mp.code in (
    'strategic_formulation.view',
    'strategic_formulation.manage',
    'strategic_formulation.validate',
    'strategic_formulation.approve',
    'business_architecture.view',
    'business_architecture.manage'
  )
order by mr.code, mp.code;

select
  table_name,
  column_name,
  data_type,
  is_nullable
from information_schema.columns
where table_schema = 'public'
  and table_name in (
    'platform_business_artifacts',
    'platform_business_artifact_versions',
    'platform_business_artifact_elements',
    'skpe_formulation_business_inputs',
    'skpe_strategic_objectives',
    'skpe_key_results'
  )
order by table_name, ordinal_position;

select
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as arguments,
  pg_get_function_result(p.oid) as result_type,
  p.prosecdef as security_definer
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'can_view_skpe_formulation',
    'can_manage_skpe_formulation',
    'can_validate_skpe_formulation',
    'can_approve_skpe_formulation',
    'can_view_business_architecture',
    'can_manage_business_architecture',
    'get_skpe_projects_for_selection',
    'get_skpe_formulation_readiness'
  )
order by p.proname;

select
  tablename,
  policyname,
  cmd,
  roles,
  qual
from pg_policies
where schemaname = 'public'
  and tablename in (
    'platform_business_artifacts',
    'platform_business_artifact_versions',
    'platform_business_artifact_elements',
    'platform_business_artifact_element_relations',
    'platform_business_artifact_version_relations',
    'skpe_formulation_business_inputs',
    'skpe_strategic_formulations',
    'skpe_strategic_identity',
    'skpe_strategic_themes',
    'skpe_okrs',
    'skpe_indicators'
  )
order by tablename, policyname;

select
  'shared_business_architecture_objects' as check_name,
  count(*) as object_count,
  case when count(*) = 6 then 'OK' else 'REVISAR' end as status
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relkind = 'r'
  and c.relname in (
    'platform_business_artifacts',
    'platform_business_artifact_versions',
    'platform_business_artifact_elements',
    'platform_business_artifact_element_relations',
    'platform_business_artifact_version_relations',
    'skpe_formulation_business_inputs'
  );

select
  'forbidden_local_value_chain_tables' as check_name,
  count(*) as object_count,
  case when count(*) = 0 then 'OK' else 'REVISAR' end as status
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relkind = 'r'
  and c.relname in (
    'skpe_value_chain_elements',
    'skpe_value_chain_relations'
  );

select
  o.code as organization_code,
  p.id as project_id,
  p.code as project_code,
  p.name as project_name,
  p.status,
  p.planning_horizon_start_year,
  p.planning_horizon_end_year,
  p.reference_year,
  p.review_cycle
from public.organizations o
left join public.skpe_projects p
  on p.organization_id = o.id
 and p.archived_at is null
where o.code in ('COOTAQUARA', 'COOPERCOMPANY', 'SESCOOP-DF')
order by o.code, p.updated_at desc;
