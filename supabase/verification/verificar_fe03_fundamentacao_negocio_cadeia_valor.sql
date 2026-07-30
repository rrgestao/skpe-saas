-- ============================================================
-- FE-03 — Verificação consolidada
-- Fundamentação do Negócio e Cadeia de Valor Essencial
-- SOMENTE LEITURA — retorna um único grid.
-- ============================================================

with
expected_indexes(index_name) as (
  values
    ('idx_platform_business_elements_readiness'),
    ('idx_platform_business_element_relations_version'),
    ('idx_platform_business_versions_source_project')
),
expected_functions(function_signature) as (
  values
    ('public.skpe_assert_business_artifact_version_editable(uuid)'),
    ('public.skpe_guard_business_artifact_version_content()'),
    ('public.create_skpe_business_artifact(uuid,text,text,text,text,text,text,text,text,text)'),
    ('public.update_skpe_business_artifact_version(uuid,text,text,text,jsonb,jsonb,text)'),
    ('public.upsert_skpe_business_artifact_element(uuid,text,text,text,text,text,jsonb,uuid,integer,uuid,text)'),
    ('public.archive_skpe_business_artifact_element(uuid,text)'),
    ('public.upsert_skpe_business_element_relation(uuid,uuid,uuid,text,numeric,text,jsonb,uuid,text)'),
    ('public.delete_skpe_business_element_relation(uuid,text)'),
    ('public.get_skpe_business_artifact_version_readiness(uuid)'),
    ('public.transition_skpe_business_artifact_version(uuid,text,text,text)'),
    ('public.create_skpe_business_artifact_revision(uuid,text,text,text)'),
    ('public.capture_skpe_business_artifact_snapshot(uuid)'),
    ('public.link_skpe_business_input(uuid,uuid,text,text,text,boolean,text,boolean,text,text)'),
    ('public.dismiss_skpe_business_input(uuid,text)'),
    ('public.get_skpe_business_foundation_readiness(uuid)'),
    ('public.skpe_guard_formulation_business_ready()'),
    ('public.get_skpe_formulation_business_architecture(uuid)'),
    ('public.get_skpe_business_architecture_audit(uuid)')
),
public_rpc_functions(function_signature) as (
  values
    ('public.create_skpe_business_artifact(uuid,text,text,text,text,text,text,text,text,text)'),
    ('public.update_skpe_business_artifact_version(uuid,text,text,text,jsonb,jsonb,text)'),
    ('public.upsert_skpe_business_artifact_element(uuid,text,text,text,text,text,jsonb,uuid,integer,uuid,text)'),
    ('public.archive_skpe_business_artifact_element(uuid,text)'),
    ('public.upsert_skpe_business_element_relation(uuid,uuid,uuid,text,numeric,text,jsonb,uuid,text)'),
    ('public.delete_skpe_business_element_relation(uuid,text)'),
    ('public.get_skpe_business_artifact_version_readiness(uuid)'),
    ('public.transition_skpe_business_artifact_version(uuid,text,text,text)'),
    ('public.create_skpe_business_artifact_revision(uuid,text,text,text)'),
    ('public.link_skpe_business_input(uuid,uuid,text,text,text,boolean,text,boolean,text,text)'),
    ('public.dismiss_skpe_business_input(uuid,text)'),
    ('public.get_skpe_business_foundation_readiness(uuid)'),
    ('public.get_skpe_formulation_business_architecture(uuid)'),
    ('public.get_skpe_business_architecture_audit(uuid)')
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
      where procedure_info.oid =
        to_regprocedure(expected_functions.function_signature)
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
    'authenticated não executa skpe_assert_business_artifact_version_editable',
    'NAO',
    case when has_function_privilege(
      'authenticated',
      to_regprocedure(
        'public.skpe_assert_business_artifact_version_editable(uuid)'
      ),
      'EXECUTE'
    ) then 'SIM' else 'NAO' end

  union all

  select
    'FUNCAO_INTERNA',
    'authenticated não executa capture_skpe_business_artifact_snapshot',
    'NAO',
    case when has_function_privilege(
      'authenticated',
      to_regprocedure(
        'public.capture_skpe_business_artifact_snapshot(uuid)'
      ),
      'EXECUTE'
    ) then 'SIM' else 'NAO' end

  union all

  select
    'TRIGGER',
    'platform_business_artifact_elements_guard_version',
    'EXISTE',
    case when exists (
      select 1
      from pg_trigger trigger_info
      where trigger_info.tgrelid =
        'public.platform_business_artifact_elements'::regclass
        and trigger_info.tgname =
          'platform_business_artifact_elements_guard_version'
        and not trigger_info.tgisinternal
    ) then 'EXISTE' else 'AUSENTE' end

  union all

  select
    'TRIGGER',
    'platform_business_artifact_element_relations_guard_version',
    'EXISTE',
    case when exists (
      select 1
      from pg_trigger trigger_info
      where trigger_info.tgrelid =
        'public.platform_business_artifact_element_relations'::regclass
        and trigger_info.tgname =
          'platform_business_artifact_element_relations_guard_version'
        and not trigger_info.tgisinternal
    ) then 'EXISTE' else 'AUSENTE' end

  union all

  select
    'TRIGGER',
    'skpe_strategic_formulations_guard_business_ready',
    'EXISTE',
    case when exists (
      select 1
      from pg_trigger trigger_info
      where trigger_info.tgrelid =
        'public.skpe_strategic_formulations'::regclass
        and trigger_info.tgname =
          'skpe_strategic_formulations_guard_business_ready'
        and not trigger_info.tgisinternal
    ) then 'EXISTE' else 'AUSENTE' end

  union all

  select
    'REGRA_METODOLOGICA',
    'Fundamentação possui nove blocos essenciais',
    'SIM',
    case when pg_get_functiondef(
      to_regprocedure(
        'public.get_skpe_business_artifact_version_readiness(uuid)'
      )
    ) ilike '%risks_hypotheses%'
      and pg_get_functiondef(
        to_regprocedure(
          'public.get_skpe_business_artifact_version_readiness(uuid)'
        )
      ) ilike '%customer_segments%'
    then 'SIM' else 'NAO' end

  union all

  select
    'REGRA_METODOLOGICA',
    'Cadeia de Valor possui gestão, negócio e apoio',
    'SIM',
    case when pg_get_functiondef(
      to_regprocedure(
        'public.get_skpe_business_artifact_version_readiness(uuid)'
      )
    ) ilike '%governance_management%'
      and pg_get_functiondef(
        to_regprocedure(
          'public.get_skpe_business_artifact_version_readiness(uuid)'
        )
      ) ilike '%core_business%'
      and pg_get_functiondef(
        to_regprocedure(
          'public.get_skpe_business_artifact_version_readiness(uuid)'
        )
      ) ilike '%support%'
    then 'SIM' else 'NAO' end

  union all

  select
    'REGRA_METODOLOGICA',
    'Fluxo obrigatório na Cadeia de Valor',
    'SIM',
    case when pg_get_functiondef(
      to_regprocedure(
        'public.get_skpe_business_artifact_version_readiness(uuid)'
      )
    ) ilike '%VALUE_CHAIN_FLOW_MISSING%'
    then 'SIM' else 'NAO' end

  union all

  select
    'REGRA_ARQUITETURAL',
    'SK-PN não é requisito para a prontidão',
    'SIM',
    case when pg_get_functiondef(
      to_regprocedure(
        'public.get_skpe_business_foundation_readiness(uuid)'
      )
    ) not ilike '%has_module_permission%SK-PN%'
    then 'SIM' else 'NAO' end

  union all

  select
    'REGRA_ARQUITETURAL',
    'Snapshot da versão é preservado no vínculo',
    'SIM',
    case when pg_get_functiondef(
      to_regprocedure(
        'public.link_skpe_business_input(uuid,uuid,text,text,text,boolean,text,boolean,text,text)'
      )
    ) ilike '%capture_skpe_business_artifact_snapshot%'
    then 'SIM' else 'NAO' end

  union all

  select
    'PRIVILEGIO_DIRETO',
    'authenticated pode inserir diretamente em platform_business_artifacts',
    'NAO',
    case when has_table_privilege(
      'authenticated',
      'public.platform_business_artifacts',
      'INSERT'
    ) then 'SIM' else 'NAO' end

  union all

  select
    'PRIVILEGIO_DIRETO',
    'authenticated pode atualizar diretamente elementos de negócio',
    'NAO',
    case when has_table_privilege(
      'authenticated',
      'public.platform_business_artifact_elements',
      'UPDATE'
    ) then 'SIM' else 'NAO' end

  union all

  select
    'PRIVILEGIO_DIRETO',
    'authenticated pode inserir diretamente vínculos da Formulação',
    'NAO',
    case when has_table_privilege(
      'authenticated',
      'public.skpe_formulation_business_inputs',
      'INSERT'
    ) then 'SIM' else 'NAO' end

  union all

  select
    'INTEGRIDADE',
    'Versões abertas duplicadas por artefato',
    '0',
    count(*)::text
  from (
    select artifact_id
    from public.platform_business_artifact_versions
    where status in (
      'draft',
      'in_elaboration',
      'pending_validation',
      'validated'
    )
    group by artifact_id
    having count(*) > 1
  ) duplicated_open

  union all

  select
    'INTEGRIDADE',
    'Versões publicadas duplicadas por artefato',
    '0',
    count(*)::text
  from (
    select artifact_id
    from public.platform_business_artifact_versions
    where status = 'published'
    group by artifact_id
    having count(*) > 1
  ) duplicated_published

  union all

  select
    'INTEGRIDADE',
    'Elementos fora do escopo da versão',
    '0',
    count(*)::text
  from public.platform_business_artifact_elements element
  join public.platform_business_artifact_versions version
    on version.id = element.artifact_version_id
  where element.organization_id <> version.organization_id
     or element.artifact_id <> version.artifact_id

  union all

  select
    'INTEGRIDADE',
    'Relações fora do escopo da versão',
    '0',
    count(*)::text
  from public.platform_business_artifact_element_relations relation
  join public.platform_business_artifact_versions version
    on version.id = relation.artifact_version_id
  where relation.organization_id <> version.organization_id
     or relation.artifact_id <> version.artifact_id

  union all

  select
    'INTEGRIDADE',
    'Vínculos ativos primários duplicados por papel',
    '0',
    count(*)::text
  from (
    select formulation_id, input_role
    from public.skpe_formulation_business_inputs
    where status = 'active'
      and is_primary
    group by formulation_id, input_role
    having count(*) > 1
  ) duplicated_primary

  union all

  select
    'SITUACAO',
    'Artefatos compartilhados atualmente cadastrados',
    count(*)::text,
    count(*)::text
  from public.platform_business_artifacts

  union all

  select
    'SITUACAO',
    'Vínculos ativos com Formulações',
    count(*)::text,
    count(*)::text
  from public.skpe_formulation_business_inputs
  where status = 'active'
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
    when 'REGRA_METODOLOGICA' then 2
    when 'INDICE' then 3
    when 'FUNCAO' then 4
    when 'SEGURANCA_FUNCAO' then 5
    when 'EXECUCAO_AUTHENTICATED' then 6
    when 'FUNCAO_INTERNA' then 7
    when 'TRIGGER' then 8
    when 'PRIVILEGIO_DIRETO' then 9
    when 'INTEGRIDADE' then 10
    else 11
  end,
  check_item;
