-- Adaptive OKR quantity policy: quality and maturity over fixed counts.
alter table public.skpe_okr_packages
  alter column minimum_key_results_per_okr set default 1,
  alter column maximum_key_results_per_okr set default 30;

comment on column public.skpe_okr_packages.minimum_key_results_per_okr is
'Contextual lower guardrail for KRs per OKR. Default 1 avoids imposing a methodological fixed count; calibrate by maturity and complexity.';
comment on column public.skpe_okr_packages.maximum_key_results_per_okr is
'Contextual safety guardrail for KRs per OKR. Default 30 is technical capacity, not a recommended methodological target.';
create or replace function public.configure_skpe_okr_package(
  p_formulation_id uuid,
  p_okr_enabled boolean default false,
  p_okr_required_for_all_objectives boolean default false,
  p_okr_cycle_required boolean default true,
  p_minimum_key_results_per_okr integer default 1,
  p_maximum_key_results_per_okr integer default 30,
  p_key_result_baseline_required boolean default true,
  p_okr_owner_required boolean default false,
  p_key_result_owner_required boolean default false,
  p_key_result_owner_recommended boolean default true,
  p_key_result_weights_required boolean default false,
  p_okr_alignment_enabled boolean default true,
  p_automatic_progress_calculation boolean default true,
  p_allow_manual_progress_override boolean default false,
  p_cycle_overlap_policy text default 'warn',
  p_clone_progress_policy text default 'reset_to_baseline',
  p_metadata jsonb default null,
  p_change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  package_id uuid;
  previous_package public.skpe_okr_packages%rowtype;
  updated_package public.skpe_okr_packages%rowtype;
  normalized_overlap_policy text;
  normalized_clone_policy text;
begin
  perform public.skpe_assert_reason(p_change_reason);
  perform public.skpe_assert_formulation_editable(p_formulation_id);

  if p_minimum_key_results_per_okr not between 1 and 20 then
    raise exception 'O mínimo de Resultados-Chave deve estar entre 1 e 20.'
      using errcode = '22023';
  end if;

  if p_maximum_key_results_per_okr < p_minimum_key_results_per_okr
     or p_maximum_key_results_per_okr > 30 then
    raise exception 'O máximo de Resultados-Chave deve ser maior ou igual ao mínimo e até 30.'
      using errcode = '22023';
  end if;

  normalized_overlap_policy := lower(trim(coalesce(p_cycle_overlap_policy, 'warn')));
  normalized_clone_policy := lower(trim(coalesce(p_clone_progress_policy, 'reset_to_baseline')));

  if normalized_overlap_policy not in ('allow', 'warn', 'block') then
    raise exception 'Política de sobreposição inválida. Use allow, warn ou block.'
      using errcode = '22023';
  end if;

  if normalized_clone_policy not in ('reset_to_baseline', 'inherit_current') then
    raise exception 'Política de clonagem inválida.' using errcode = '22023';
  end if;

  if p_metadata is not null and jsonb_typeof(p_metadata) <> 'object' then
    raise exception 'Os metadados devem ser um objeto JSON.' using errcode = '22023';
  end if;

  package_id := public.ensure_skpe_okr_package(p_formulation_id);

  select * into previous_package
  from public.skpe_okr_packages
  where id = package_id
  for update;

  update public.skpe_okr_packages
  set
    okr_enabled = coalesce(p_okr_enabled, false),
    status = case when coalesce(p_okr_enabled, false)
      then 'in_elaboration' else 'not_applicable' end,
    okr_required_for_all_objectives = coalesce(p_okr_required_for_all_objectives, false),
    okr_cycle_required = coalesce(p_okr_cycle_required, true),
    minimum_key_results_per_okr = p_minimum_key_results_per_okr,
    maximum_key_results_per_okr = p_maximum_key_results_per_okr,
    key_result_baseline_required = coalesce(p_key_result_baseline_required, true),
    okr_owner_required = coalesce(p_okr_owner_required, false),
    key_result_owner_required = coalesce(p_key_result_owner_required, false),
    key_result_owner_recommended = coalesce(p_key_result_owner_recommended, true),
    key_result_weights_required = coalesce(p_key_result_weights_required, false),
    okr_alignment_enabled = coalesce(p_okr_alignment_enabled, true),
    automatic_progress_calculation = coalesce(p_automatic_progress_calculation, true),
    allow_manual_progress_override = coalesce(p_allow_manual_progress_override, false),
    cycle_overlap_policy = normalized_overlap_policy,
    clone_progress_policy = normalized_clone_policy,
    validation_notes = null,
    submitted_for_validation_at = null,
    submitted_for_validation_by = null,
    validated_at = null,
    validated_by = null,
    metadata = coalesce(p_metadata, metadata),
    updated_by = auth.uid()
  where id = package_id
  returning * into updated_package;

  update public.skpe_okrs
  set validation_status = 'draft', updated_by = auth.uid()
  where formulation_id = p_formulation_id and status <> 'cancelled';

  update public.skpe_key_results
  set validation_status = 'draft', updated_by = auth.uid()
  where formulation_id = p_formulation_id and status <> 'cancelled';

  perform public.skpe_record_operational_audit(
    updated_package.organization_id,
    updated_package.project_id,
    'okr_package',
    updated_package.id,
    'okr_package_configured',
    p_change_reason,
    to_jsonb(previous_package),
    to_jsonb(updated_package)
  );

  return updated_package.id;
end;
$$;

create or replace function public.get_skpe_okrs_readiness(
  p_formulation_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  project_row public.skpe_projects%rowtype;
  package_row public.skpe_okr_packages%rowtype;
  horizon_start date;
  horizon_end date;
  issues jsonb := '[]'::jsonb;
  counts jsonb := '{}'::jsonb;
  content_blocking_count integer := 0;
  total_blocking_count integer := 0;
  enabled boolean := false;
begin
  select * into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  if not found then
    raise exception 'Versão da Formulação Estratégica não encontrada.' using errcode = '22023';
  end if;

  if not public.can_view_skpe_formulation(formulation_row.organization_id) then
    raise exception 'Acesso negado à prontidão dos OKRs.' using errcode = '42501';
  end if;

  select * into project_row from public.skpe_projects where id = formulation_row.project_id;
  select * into package_row from public.skpe_okr_packages where formulation_id = p_formulation_id;
  enabled := coalesce(package_row.okr_enabled, false);

  horizon_start := coalesce(
    formulation_row.valid_from,
    case when project_row.planning_horizon_start_year is null then null
      else make_date(project_row.planning_horizon_start_year, 1, 1) end
  );
  horizon_end := coalesce(
    formulation_row.valid_until,
    case when project_row.planning_horizon_end_year is null then null
      else make_date(project_row.planning_horizon_end_year, 12, 31) end
  );

  select jsonb_build_object(
    'cycles', (select count(*) from public.skpe_okr_cycles cycle
      where cycle.formulation_id = p_formulation_id and cycle.status <> 'archived'),
    'activeCycles', (select count(*) from public.skpe_okr_cycles cycle
      where cycle.formulation_id = p_formulation_id and cycle.status = 'active'),
    'okrs', (select count(*) from public.skpe_okrs okr
      where okr.formulation_id = p_formulation_id and okr.status <> 'cancelled'),
    'keyResults', (select count(*) from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'),
    'objectiveLinks', (select count(*) from public.skpe_okr_objectives link
      where link.formulation_id = p_formulation_id),
    'alignments', (select count(*) from public.skpe_okr_alignments alignment
      where alignment.formulation_id = p_formulation_id and alignment.status = 'active'),
    'keyResultsWithOwner', (select count(*) from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and kr.owner_user_id is not null),
    'keyResultsWithLinkedIndicator', (select count(*) from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and length(trim(coalesce(kr.metadata ->> 'linkedIndicatorCode', ''))) > 0),
    'keyResultsWithMeasurementHistory', (select count(distinct audit.entity_id)
      from public.skpe_operational_audit audit
      where audit.organization_id = formulation_row.organization_id
        and audit.project_id = formulation_row.project_id
        and audit.entity_type = 'key_result'
        and audit.action_code = 'key_result_progress_updated'
        and (audit.new_data ->> 'formulation_id') = p_formulation_id::text)
  ) into counts;

  if enabled then
    with issue_rows as (
      select 'OKR_PACKAGE_WITHOUT_VALID_CYCLE'::text code, 'blocking'::text severity,
        'content'::text issue_scope,
        'O pacote de OKRs está habilitado, mas não possui ciclo válido.'::text message,
        1::bigint affected_count
      where coalesce(package_row.okr_cycle_required, true)
        and not exists (
          select 1 from public.skpe_okr_cycles cycle
          where cycle.formulation_id = p_formulation_id
            and cycle.status <> 'archived'
            and cycle.period_end >= cycle.period_start
        )

      union all
      select 'CYCLE_OUTSIDE_FORMULATION_HORIZON', 'blocking', 'content',
        'Existem ciclos fora do horizonte da Formulação.', count(*)
      from public.skpe_okr_cycles cycle
      where cycle.formulation_id = p_formulation_id
        and cycle.status <> 'archived'
        and ((horizon_start is not null and cycle.period_start < horizon_start)
          or (horizon_end is not null and cycle.period_end > horizon_end))
      having count(*) > 0

      union all
      select 'CYCLE_OVERLAP_BLOCKED', 'blocking', 'content',
        'Existem ciclos sobrepostos e a política configurada é block.', count(*)
      from public.skpe_okr_cycles a
      join public.skpe_okr_cycles b
        on b.formulation_id = a.formulation_id and b.id > a.id
       and b.status <> 'archived'
       and daterange(a.period_start, a.period_end, '[]')
         && daterange(b.period_start, b.period_end, '[]')
      where a.formulation_id = p_formulation_id
        and a.status <> 'archived'
        and coalesce(package_row.cycle_overlap_policy, 'warn') = 'block'
      having count(*) > 0

      union all
      select 'DUPLICATE_CYCLE_CODE', 'blocking', 'content',
        'Existem códigos de ciclo duplicados, desconsiderando maiúsculas e minúsculas.', count(*)
      from (
        select lower(trim(cycle.code))
        from public.skpe_okr_cycles cycle
        where cycle.formulation_id = p_formulation_id and cycle.status <> 'archived'
        group by lower(trim(cycle.code)) having count(*) > 1
      ) duplicates
      having count(*) > 0

      union all
      select 'OKR_CODE_MISSING', 'blocking', 'content',
        'Existem OKRs sem código.', count(*)
      from public.skpe_okrs okr
      where okr.formulation_id = p_formulation_id and okr.status <> 'cancelled'
        and length(trim(coalesce(okr.code, ''))) = 0
      having count(*) > 0

      union all
      select 'OKR_TITLE_MISSING', 'blocking', 'content',
        'Existem OKRs sem título.', count(*)
      from public.skpe_okrs okr
      where okr.formulation_id = p_formulation_id and okr.status <> 'cancelled'
        and length(trim(coalesce(okr.title, ''))) = 0
      having count(*) > 0

      union all
      select 'OKR_DESCRIPTION_OR_RATIONALE_INSUFFICIENT', 'blocking', 'content',
        'Todo OKR deve possuir descrição e racional suficientes.', count(*)
      from public.skpe_okrs okr
      where okr.formulation_id = p_formulation_id and okr.status <> 'cancelled'
        and (length(trim(coalesce(okr.description, ''))) < 10
          or length(trim(coalesce(okr.metadata ->> 'rationale', ''))) < 10)
      having count(*) > 0

      union all
      select 'OKR_WITHOUT_STRATEGIC_OBJECTIVE', 'blocking', 'content',
        'Todo OKR deve estar vinculado a pelo menos um Objetivo Estratégico.', count(*)
      from public.skpe_okrs okr
      where okr.formulation_id = p_formulation_id and okr.status <> 'cancelled'
        and not exists (select 1 from public.skpe_okr_objectives link where link.okr_id = okr.id)
      having count(*) > 0

      union all
      select 'OKR_OBJECTIVE_SCOPE_MISMATCH', 'blocking', 'content',
        'Existem vínculos de OKR com Objetivo Estratégico de outro escopo.', count(*)
      from public.skpe_okr_objectives link
      left join public.skpe_okrs okr on okr.id = link.okr_id
      left join public.skpe_strategic_objectives objective
        on objective.id = link.strategic_objective_id
      where link.formulation_id = p_formulation_id
        and (okr.id is null or objective.id is null
          or okr.formulation_id <> p_formulation_id
          or objective.formulation_id <> p_formulation_id
          or link.organization_id <> formulation_row.organization_id
          or link.project_id <> formulation_row.project_id)
      having count(*) > 0

      union all
      select 'OBJECTIVE_WITHOUT_OKR', 'blocking', 'content',
        'A configuração exige ao menos um OKR por Objetivo Estratégico ativo.', count(*)
      from public.skpe_strategic_objectives objective
      where objective.formulation_id = p_formulation_id
        and objective.status = 'active'
        and coalesce(package_row.okr_required_for_all_objectives, false)
        and not exists (
          select 1 from public.skpe_okr_objectives link
          join public.skpe_okrs okr on okr.id = link.okr_id
          where link.strategic_objective_id = objective.id and okr.status <> 'cancelled'
        )
      having count(*) > 0

      union all
      select 'OKR_OWNER_REQUIRED', 'blocking', 'content',
        'Existem OKRs sem responsável, embora a configuração o exija.', count(*)
      from public.skpe_okrs okr
      where okr.formulation_id = p_formulation_id and okr.status <> 'cancelled'
        and coalesce(package_row.okr_owner_required, false)
        and okr.owner_user_id is null
      having count(*) > 0

      union all
      select 'OKR_WITHOUT_KEY_RESULT', 'blocking', 'content',
        'Todo OKR deve possuir Resultado-Chave ativo.', count(*)
      from public.skpe_okrs okr
      where okr.formulation_id = p_formulation_id and okr.status <> 'cancelled'
        and not exists (
          select 1 from public.skpe_key_results kr
          where kr.okr_id = okr.id and kr.status <> 'cancelled'
        )
      having count(*) > 0

      union all
      select 'KEY_RESULTS_BELOW_MINIMUM', 'blocking', 'content',
        'Existem OKRs com quantidade de KRs abaixo do limite mínimo explicitamente configurado para este contexto.', count(*)
      from (
        select okr.id
        from public.skpe_okrs okr
        left join public.skpe_key_results kr
          on kr.okr_id = okr.id and kr.status <> 'cancelled'
        where okr.formulation_id = p_formulation_id and okr.status <> 'cancelled'
        group by okr.id
        having count(kr.id) < coalesce(package_row.minimum_key_results_per_okr, 1)
      ) insufficient
      having count(*) > 0

      union all
      select 'KEY_RESULTS_ABOVE_MAXIMUM', 'blocking', 'content',
        'Existem OKRs com quantidade de KRs acima do limite máximo explicitamente configurado para este contexto.', count(*)
      from (
        select okr.id
        from public.skpe_okrs okr
        join public.skpe_key_results kr
          on kr.okr_id = okr.id and kr.status <> 'cancelled'
        where okr.formulation_id = p_formulation_id and okr.status <> 'cancelled'
        group by okr.id
        having count(kr.id) > coalesce(package_row.maximum_key_results_per_okr, 30)
      ) excess
      having count(*) > 0

      union all
      select 'KEY_RESULT_CODE_MISSING', 'blocking', 'content',
        'Existem Resultados-Chave sem código.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and length(trim(coalesce(kr.code, ''))) = 0
      having count(*) > 0

      union all
      select 'KEY_RESULT_NOT_MEASURABLE', 'blocking', 'content',
        'Existem Resultados-Chave sem definição mensurável ou valor-alvo.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and (length(trim(coalesce(kr.description, ''))) < 10 or kr.target_value is null)
      having count(*) > 0

      union all
      select 'KEY_RESULT_UNIT_MISSING', 'blocking', 'content',
        'Existem Resultados-Chave sem unidade de medida.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and length(trim(coalesce(kr.unit, ''))) = 0
      having count(*) > 0

      union all
      select 'KEY_RESULT_POLARITY_MISSING', 'blocking', 'content',
        'Existem Resultados-Chave sem polaridade válida.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and lower(coalesce(kr.metadata ->> 'polarity', '')) not in (
          'higher_is_better', 'lower_is_better', 'target_is_better', 'range_is_better'
        )
      having count(*) > 0

      union all
      select 'KEY_RESULT_BASELINE_MISSING', 'blocking', 'content',
        'Existem Resultados-Chave sem linha de base, embora exigida.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and coalesce(package_row.key_result_baseline_required, true)
        and kr.baseline_value is null
      having count(*) > 0

      union all
      select 'KEY_RESULT_DATA_SOURCE_MISSING', 'blocking', 'content',
        'Existem Resultados-Chave sem fonte de dados.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and length(trim(coalesce(kr.metadata ->> 'dataSource', ''))) = 0
      having count(*) > 0

      union all
      select 'KEY_RESULT_OUTSIDE_CYCLE', 'blocking', 'content',
        'Existem Resultados-Chave fora do período de seu ciclo.', count(*)
      from public.skpe_key_results kr
      join public.skpe_okrs okr on okr.id = kr.okr_id
      join public.skpe_okr_cycles cycle on cycle.id = okr.okr_cycle_id
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and (kr.period_start < cycle.period_start or kr.period_end > cycle.period_end)
      having count(*) > 0

      union all
      select 'KEY_RESULT_TARGET_POLARITY_MISMATCH', 'blocking', 'content',
        'Existem alvos incompatíveis com polaridade, linha de base ou faixa.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and kr.baseline_value is not null and kr.target_value is not null
        and (
          (kr.metadata ->> 'polarity' = 'higher_is_better' and kr.target_value < kr.baseline_value)
          or (kr.metadata ->> 'polarity' = 'lower_is_better' and kr.target_value > kr.baseline_value)
          or (kr.metadata ->> 'polarity' = 'range_is_better' and (
            nullif(kr.metadata ->> 'rangeLower', '')::numeric is null
            or nullif(kr.metadata ->> 'rangeUpper', '')::numeric is null
            or nullif(kr.metadata ->> 'rangeLower', '')::numeric
              > nullif(kr.metadata ->> 'rangeUpper', '')::numeric
            or kr.target_value < nullif(kr.metadata ->> 'rangeLower', '')::numeric
            or kr.target_value > nullif(kr.metadata ->> 'rangeUpper', '')::numeric
          ))
        )
      having count(*) > 0

      union all
      select 'KEY_RESULT_SCOPE_MISMATCH', 'blocking', 'content',
        'Existem Resultados-Chave vinculados a OKR, Objetivo ou Formulação de outro escopo.', count(*)
      from public.skpe_key_results kr
      left join public.skpe_okrs okr on okr.id = kr.okr_id
      left join public.skpe_strategic_objectives objective
        on objective.id = kr.strategic_objective_id
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and (okr.id is null or objective.id is null
          or okr.formulation_id <> p_formulation_id
          or objective.formulation_id <> p_formulation_id
          or kr.organization_id <> formulation_row.organization_id
          or kr.project_id <> formulation_row.project_id)
      having count(*) > 0

      union all
      select 'LINKED_INDICATOR_SCOPE_MISMATCH', 'blocking', 'content',
        'Existem KRs com código de Indicador que não resolve na mesma Formulação.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and length(trim(coalesce(kr.metadata ->> 'linkedIndicatorCode', ''))) > 0
        and not exists (
          select 1 from public.skpe_indicators indicator
          where indicator.formulation_id = p_formulation_id
            and indicator.code = kr.metadata ->> 'linkedIndicatorCode'
            and indicator.status <> 'archived'
        )
      having count(*) > 0

      union all
      select 'KEY_RESULT_OWNER_REQUIRED', 'blocking', 'content',
        'Existem KRs sem responsável, embora a configuração o exija.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and coalesce(package_row.key_result_owner_required, false)
        and kr.owner_user_id is null
      having count(*) > 0

      union all
      select 'KEY_RESULT_WEIGHTS_INVALID', 'blocking', 'content',
        'Quando pesos são obrigatórios, todos os KRs devem ter peso e somar 100% por OKR.', count(*)
      from (
        select okr.id
        from public.skpe_okrs okr
        join public.skpe_key_results kr
          on kr.okr_id = okr.id and kr.status <> 'cancelled'
        where okr.formulation_id = p_formulation_id and okr.status <> 'cancelled'
          and coalesce(package_row.key_result_weights_required, false)
        group by okr.id
        having count(*) filter (where kr.contribution_weight is null) > 0
          or round(coalesce(sum(kr.contribution_weight), 0), 2) <> 100.00
      ) invalid_weights
      having count(*) > 0

      union all
      select 'DUPLICATE_OKR_CODE', 'blocking', 'content',
        'Existem códigos de OKR duplicados no mesmo ciclo.', count(*)
      from (
        select okr.okr_cycle_id, lower(trim(okr.code))
        from public.skpe_okrs okr
        where okr.formulation_id = p_formulation_id and okr.status <> 'cancelled'
        group by okr.okr_cycle_id, lower(trim(okr.code)) having count(*) > 1
      ) duplicates
      having count(*) > 0

      union all
      select 'DUPLICATE_KEY_RESULT', 'blocking', 'content',
        'Existem Resultados-Chave duplicados por código ou nome dentro do mesmo OKR.', count(*)
      from (
        select kr.okr_id, lower(trim(kr.code)) key_value
        from public.skpe_key_results kr
        where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        group by kr.okr_id, lower(trim(kr.code)) having count(*) > 1
        union all
        select kr.okr_id, lower(trim(kr.name)) key_value
        from public.skpe_key_results kr
        where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        group by kr.okr_id, lower(trim(kr.name)) having count(*) > 1
      ) duplicates
      having count(*) > 0

      union all
      select 'OKR_PACKAGE_NOT_VALIDATED', 'blocking', 'formulation',
        'O pacote FE-06 deve estar validado antes do avanço da Formulação.', 1
      where package_row.id is null or package_row.status <> 'validated'

      union all
      select 'OKR_WITHOUT_OWNER', 'recommendation', 'content',
        'Recomenda-se indicar responsável para cada OKR.', count(*)
      from public.skpe_okrs okr
      where okr.formulation_id = p_formulation_id and okr.status <> 'cancelled'
        and okr.owner_user_id is null and not coalesce(package_row.okr_owner_required, false)
      having count(*) > 0

      union all
      select 'KEY_RESULT_WITHOUT_OWNER', 'recommendation', 'content',
        'Recomenda-se indicar responsável para cada Resultado-Chave.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and kr.owner_user_id is null
        and coalesce(package_row.key_result_owner_recommended, true)
        and not coalesce(package_row.key_result_owner_required, false)
      having count(*) > 0

      union all
      select 'KEY_RESULT_WITHOUT_LINKED_INDICATOR', 'recommendation', 'content',
        'Quando aplicável, vincule o KR ao Indicador Estratégico para explicitar a contribuição.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and length(trim(coalesce(kr.metadata ->> 'linkedIndicatorCode', ''))) = 0
      having count(*) > 0

      union all
      select 'KEY_RESULT_COLLECTION_NOT_AUTOMATABLE', 'recommendation', 'content',
        'Existem KRs sem método de coleta automatizável ou sem avaliação de automação.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and lower(coalesce(kr.metadata ->> 'collectionAutomatable', 'false')) <> 'true'
      having count(*) > 0

      union all
      select 'KEY_RESULT_FREQUENCY_INCOMPATIBLE', 'recommendation', 'content',
        'Revise KRs cuja frequência de medição é muito baixa para a duração do ciclo.', count(*)
      from public.skpe_key_results kr
      join public.skpe_okrs okr on okr.id = kr.okr_id
      join public.skpe_okr_cycles cycle on cycle.id = okr.okr_cycle_id
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and (
          (cycle.period_end - cycle.period_start < 180
            and kr.metadata ->> 'measurementFrequency' in ('semiannual', 'annual'))
          or (cycle.period_end - cycle.period_start < 90
            and kr.metadata ->> 'measurementFrequency' = 'quarterly')
        )
      having count(*) > 0

      union all
      select 'OKR_WITH_ONLY_ONE_KEY_RESULT', 'recommendation', 'content',
        'OKR com apenas um KR pode não representar adequadamente o resultado esperado.', count(*)
      from (
        select okr.id
        from public.skpe_okrs okr
        join public.skpe_key_results kr on kr.okr_id = okr.id and kr.status <> 'cancelled'
        where okr.formulation_id = p_formulation_id and okr.status <> 'cancelled'
        group by okr.id having count(*) = 1
      ) single_kr
      having count(*) > 0

      union all
      select 'OKR_CONCENTRATION_BY_OBJECTIVE', 'recommendation', 'content',
        'Mais de 60% dos OKRs estão concentrados em um único Objetivo Estratégico.', count(*)
      from (
        select link.strategic_objective_id
        from public.skpe_okr_objectives link
        join public.skpe_okrs okr on okr.id = link.okr_id
        where link.formulation_id = p_formulation_id and okr.status <> 'cancelled'
        group by link.strategic_objective_id
        having count(distinct link.okr_id) * 100.0
          / nullif((select count(*) from public.skpe_okrs x
            where x.formulation_id = p_formulation_id and x.status <> 'cancelled'), 0) > 60
      ) concentrated
      having count(*) > 0

      union all
      select 'OKR_ALIGNMENT_MISSING', 'recommendation', 'content',
        'A carteira possui múltiplos OKRs, mas não há alinhamento registrado.', 1
      where coalesce(package_row.okr_alignment_enabled, true)
        and (select count(*) from public.skpe_okrs okr
          where okr.formulation_id = p_formulation_id and okr.status <> 'cancelled') > 1
        and not exists (select 1 from public.skpe_okr_alignments alignment
          where alignment.formulation_id = p_formulation_id and alignment.status = 'active')

      union all
      select 'KEY_RESULT_WEIGHTS_MISSING', 'recommendation', 'content',
        'A ponderação dos KRs pode melhorar a leitura do progresso do OKR.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and not coalesce(package_row.key_result_weights_required, false)
        and kr.contribution_weight is null
      having count(*) > 0

      union all
      select 'KEY_RESULT_ACTIVITY_LIKE_WORDING', 'recommendation', 'content',
        'A redação de alguns KRs começa com verbo típico de iniciativa; revise o foco no resultado mensurável.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and lower(trim(coalesce(kr.name, ''))) ~
          '^(implantar|criar|realizar|desenvolver|contratar|executar|promover)([[:space:]]|$)'
      having count(*) > 0

      union all
      select 'KEY_RESULT_STALE_MEASUREMENT', 'recommendation', 'content',
        'Existem KRs ativos sem atualização recente de valor atual.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status in ('active', 'at_risk')
        and (
          kr.current_value is null
          or not (kr.metadata ? 'lastMeasurementAt')
          or nullif(kr.metadata ->> 'lastMeasurementAt', '')::timestamptz
            < timezone('utc', now()) - interval '90 days'
        )
      having count(*) > 0

      union all
      select 'MANUAL_PROGRESS_DIVERGENCE', 'recommendation', 'content',
        'Existem substituições manuais com divergência superior a 10 pontos do cálculo automático.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and abs(coalesce(nullif(kr.metadata ->> 'progressDivergence', '')::numeric, 0)) > 10
      having count(*) > 0

      union all
      select 'KEY_RESULT_WITHOUT_PROGRESS_HISTORY', 'recommendation', 'content',
        'Existem KRs ativos sem histórico auditável de acompanhamento.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status in ('active', 'at_risk')
        and not exists (
          select 1 from public.skpe_operational_audit audit
          where audit.entity_type = 'key_result'
            and audit.entity_id = kr.id
            and audit.action_code = 'key_result_progress_updated'
        )
      having count(*) > 0

      union all
      select 'CYCLE_OVERLAP_WARNING', 'recommendation', 'content',
        'Existem ciclos sobrepostos; confirme se a sobreposição é intencional.', count(*)
      from public.skpe_okr_cycles a
      join public.skpe_okr_cycles b
        on b.formulation_id = a.formulation_id and b.id > a.id
       and b.status <> 'archived'
       and daterange(a.period_start, a.period_end, '[]')
         && daterange(b.period_start, b.period_end, '[]')
      where a.formulation_id = p_formulation_id
        and a.status <> 'archived'
        and coalesce(package_row.cycle_overlap_policy, 'warn') = 'warn'
      having count(*) > 0
    )
    select
      coalesce(jsonb_agg(jsonb_build_object(
        'code', code,
        'severity', severity,
        'scope', issue_scope,
        'message', message,
        'affectedCount', affected_count
      ) order by
        case severity when 'blocking' then 1 else 2 end,
        case issue_scope when 'content' then 1 else 2 end,
        code
      ), '[]'::jsonb),
      count(*) filter (where severity = 'blocking' and issue_scope = 'content')::integer,
      count(*) filter (where severity = 'blocking')::integer
    into issues, content_blocking_count, total_blocking_count
    from issue_rows;
  end if;

  return jsonb_build_object(
    'formulationId', formulation_row.id,
    'okrPackageId', package_row.id,
    'okrEnabled', enabled,
    'applicability', case when enabled then 'applicable' else 'not_applicable' end,
    'packageStatus', case
      when package_row.id is null then 'not_created'
      else package_row.status
    end,
    'readyForValidation', case when enabled then content_blocking_count = 0 else true end,
    'validated', case when enabled then coalesce(package_row.status = 'validated', false) else true end,
    'readyForFormulation', case when enabled then
      content_blocking_count = 0 and coalesce(package_row.status = 'validated', false)
      else true end,
    'contentBlockingIssueCount', content_blocking_count,
    'blockingIssueCount', total_blocking_count,
    'planningHorizon', jsonb_build_object('startDate', horizon_start, 'endDate', horizon_end),
    'counts', counts,
    'issues', issues,
    'methodologyRules', jsonb_build_object(
      'okrEnabled', enabled,
      'okrRequiredForAllObjectives', coalesce(package_row.okr_required_for_all_objectives, false),
      'okrCycleRequired', coalesce(package_row.okr_cycle_required, true),
      'quantityPolicy', 'adaptive_by_maturity_and_complexity',
      'minimumKeyResultsPerOkr', coalesce(package_row.minimum_key_results_per_okr, 1),
      'maximumKeyResultsPerOkr', coalesce(package_row.maximum_key_results_per_okr, 30),
      'keyResultBaselineRequired', coalesce(package_row.key_result_baseline_required, true),
      'okrOwnerRequired', coalesce(package_row.okr_owner_required, false),
      'keyResultOwnerRequired', coalesce(package_row.key_result_owner_required, false),
      'keyResultOwnerRecommended', coalesce(package_row.key_result_owner_recommended, true),
      'keyResultWeightsRequired', coalesce(package_row.key_result_weights_required, false),
      'okrAlignmentEnabled', coalesce(package_row.okr_alignment_enabled, true),
      'automaticProgressCalculation', coalesce(package_row.automatic_progress_calculation, true),
      'allowManualProgressOverride', coalesce(package_row.allow_manual_progress_override, false),
      'cycleOverlapPolicy', coalesce(package_row.cycle_overlap_policy, 'warn'),
      'cloneProgressPolicy', coalesce(package_row.clone_progress_policy, 'reset_to_baseline'),
      'initiativeRequiredInFe06', false
    )
  );
end;
$$;
