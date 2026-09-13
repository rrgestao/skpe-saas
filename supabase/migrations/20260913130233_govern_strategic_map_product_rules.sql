-- Plataforma SPARKs / SK-PE
-- Governa decisões Product de 2026-09-13 para o Mapa Estratégico.
-- Mantém a Formulação como escopo e cria histórico imutável próprio do ME.

begin;

-- ============================================================
-- 1. VERSÕES OFICIAIS IMUTÁVEIS DO MAPA ESTRATÉGICO
-- ============================================================

create table if not exists public.skpe_strategic_map_versions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  package_id uuid not null,
  version_number integer not null,
  status text not null default 'official',
  source_validated_at timestamptz not null,
  validated_by uuid references public.profiles(id) on delete set null,
  validation_notes text,
  payload jsonb not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  constraint skpe_strategic_map_versions_status_check
    check (status = 'official'),
  constraint skpe_strategic_map_versions_formulation_fkey
    foreign key (formulation_id, organization_id, project_id)
    references public.skpe_strategic_formulations(
      id,
      organization_id,
      project_id
    ) on delete cascade,
  constraint skpe_strategic_map_versions_package_fkey
    foreign key (package_id)
    references public.skpe_strategic_map_packages(id)
    on delete restrict,
  constraint skpe_strategic_map_versions_number_unique
    unique (formulation_id, version_number),
  constraint skpe_strategic_map_versions_validation_unique
    unique (formulation_id, source_validated_at)
);

comment on table public.skpe_strategic_map_versions is
  'Snapshots imutáveis das versões oficiais do Mapa Estratégico validadas humanamente.';

create index if not exists idx_skpe_strategic_map_versions_scope
  on public.skpe_strategic_map_versions(
    organization_id,
    project_id,
    formulation_id,
    version_number desc
  );

alter table public.skpe_strategic_map_versions enable row level security;
drop policy if exists skpe_strategic_map_versions_select
  on public.skpe_strategic_map_versions;

create policy skpe_strategic_map_versions_select
on public.skpe_strategic_map_versions
for select to authenticated
using (public.can_view_skpe_formulation(organization_id));

revoke insert, update, delete on public.skpe_strategic_map_versions
  from authenticated;
grant select on public.skpe_strategic_map_versions
  to authenticated, service_role;

-- ============================================================
-- 2. READINESS PRODUCT
-- ============================================================

alter function public.get_skpe_strategic_map_readiness(uuid)
  rename to get_skpe_strategic_map_readiness_legacy_20260913;

revoke execute on function public.get_skpe_strategic_map_readiness_legacy_20260913(uuid)
  from public, authenticated;
grant execute on function public.get_skpe_strategic_map_readiness_legacy_20260913(uuid)
  to service_role;

create or replace function public.get_skpe_strategic_map_readiness(
  target_formulation_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  base_readiness jsonb;
  product_issues jsonb;
  product_rules jsonb;
  theme_without_objectives_count integer := 0;
  objective_without_theme_count integer := 0;
  objective_without_owner_count integer := 0;
  objective_without_horizon_count integer := 0;
  content_blocking_count integer := 0;
  total_blocking_count integer := 0;
begin
  base_readiness := public.get_skpe_strategic_map_readiness_legacy_20260913(
    target_formulation_id
  );

  select coalesce(jsonb_agg(issue_item), '[]'::jsonb)
  into product_issues
  from jsonb_array_elements(
    coalesce(base_readiness -> 'issues', '[]'::jsonb)
  ) issue_item
  where issue_item ->> 'code' not in (
    'THEME_WITHOUT_OBJECTIVES',
    'OBJECTIVE_WITHOUT_THEME',
    'OBJECTIVE_WITHOUT_OWNER',
    'OBJECTIVE_WITHOUT_HORIZON'
  );
  select count(*)
  into theme_without_objectives_count
  from public.skpe_strategic_themes theme
  where theme.formulation_id = target_formulation_id
    and theme.status = 'active'
    and not exists (
      select 1
      from public.skpe_strategic_objectives objective
      where objective.formulation_id = target_formulation_id
        and objective.strategic_theme_id = theme.id
        and objective.status = 'active'
    );

  select count(*)
  into objective_without_theme_count
  from public.skpe_strategic_objectives objective
  left join public.skpe_strategic_themes theme
    on theme.id = objective.strategic_theme_id
   and theme.formulation_id = target_formulation_id
   and theme.status = 'active'
  where objective.formulation_id = target_formulation_id
    and objective.status = 'active'
    and theme.id is null;

  select count(*)
  into objective_without_owner_count
  from public.skpe_strategic_objectives objective
  where objective.formulation_id = target_formulation_id
    and objective.status = 'active'
    and objective.owner_user_id is null;
  select count(*)
  into objective_without_horizon_count
  from public.skpe_strategic_objectives objective
  where objective.formulation_id = target_formulation_id
    and objective.status = 'active'
    and (
      objective.horizon_start is null
      or objective.horizon_end is null
    );

  if theme_without_objectives_count > 0 then
    product_issues := product_issues || jsonb_build_array(
      jsonb_build_object(
        'code', 'THEME_WITHOUT_OBJECTIVES',
        'severity', 'blocking',
        'scope', 'content',
        'message', 'Todo Tema Estratégico ativo deve possuir ao menos um Objetivo Estratégico ativo.',
        'affectedCount', theme_without_objectives_count
      )
    );
  end if;

  if objective_without_theme_count > 0 then
    product_issues := product_issues || jsonb_build_array(
      jsonb_build_object(
        'code', 'OBJECTIVE_WITHOUT_THEME',
        'severity', 'blocking',
        'scope', 'content',
        'message', 'Todo Objetivo Estratégico ativo deve pertencer a um Tema Estratégico ativo.',
        'affectedCount', objective_without_theme_count
      )
    );
  end if;

  if objective_without_owner_count > 0 then
    product_issues := product_issues || jsonb_build_array(
      jsonb_build_object(
        'code', 'OBJECTIVE_WITHOUT_OWNER',
        'severity', 'blocking',
        'scope', 'content',
        'message', 'Todo Objetivo Estratégico ativo deve possuir responsável definido.',
        'affectedCount', objective_without_owner_count
      )
    );
  end if;

  if objective_without_horizon_count > 0 then
    product_issues := product_issues || jsonb_build_array(
      jsonb_build_object(
        'code', 'OBJECTIVE_WITHOUT_HORIZON',
        'severity', 'blocking',
        'scope', 'content',
        'message', 'Todo Objetivo Estratégico ativo deve possuir horizonte inicial e final definidos.',
        'affectedCount', objective_without_horizon_count
      )
    );
  end if;

  select
    count(*) filter (
      where issue_item ->> 'severity' = 'blocking'
        and issue_item ->> 'scope' = 'content'
    )::integer,
    count(*) filter (
      where issue_item ->> 'severity' = 'blocking'
    )::integer
  into content_blocking_count, total_blocking_count
  from jsonb_array_elements(product_issues) issue_item;

  product_rules := coalesce(
    base_readiness -> 'methodologyRules',
    '{}'::jsonb
  ) || jsonb_build_object(
    'themeRequired', true,
    'ownerRequired', true,
    'ownerRecommended', false,
    'horizonRequired', true,
    'officialVersionImmutableAfterValidation', true,
    'revisionRequiredAfterValidation', true
  );

  return base_readiness || jsonb_build_object(
    'issues', product_issues,
    'contentBlockingIssueCount', content_blocking_count,
    'blockingIssueCount', total_blocking_count,
    'readyForValidation', content_blocking_count = 0,
    'readyForFormulation',
      content_blocking_count = 0
      and coalesce((base_readiness ->> 'validated')::boolean, false),
    'methodologyRules', product_rules
  );
end;
$$;

comment on function public.get_skpe_strategic_map_readiness(uuid) is
  'Readiness Product da FE-04: Tema->OE, OE->Tema, responsável e horizonte são bloqueantes.';

grant execute on function public.get_skpe_strategic_map_readiness(uuid)
  to authenticated, service_role;

-- ============================================================
-- 3. CAPTURA IMUTÁVEL DA VERSÃO OFICIAL
-- ============================================================
create or replace function public.capture_skpe_strategic_map_version(
  target_formulation_id uuid,
  capture_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  package_row public.skpe_strategic_map_packages%rowtype;
  formulation_row public.skpe_strategic_formulations%rowtype;
  existing_version_id uuid;
  next_version_number integer;
  saved_version_id uuid;
  map_payload jsonb;
begin
  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = target_formulation_id;

  if not found then
    raise exception 'Formulação Estratégica não encontrada.'
      using errcode = '22023';
  end if;

  -- Função interna: a autorização é exercida pela fachada de workflow que a chama.
  -- EXECUTE direto permanece restrito a service_role.
  select *
  into package_row
  from public.skpe_strategic_map_packages
  where formulation_id = target_formulation_id
  for update;

  if not found or package_row.status <> 'validated' then
    raise exception 'Somente um Mapa Estratégico validado pode gerar versão oficial.'
      using errcode = '55000';
  end if;

  select version_row.id
  into existing_version_id
  from public.skpe_strategic_map_versions version_row
  where version_row.formulation_id = target_formulation_id
    and version_row.source_validated_at = package_row.validated_at;

  if existing_version_id is not null then
    return existing_version_id;
  end if;

  select coalesce(max(version_row.version_number), 0) + 1
  into next_version_number
  from public.skpe_strategic_map_versions version_row
  where version_row.formulation_id = target_formulation_id;

  map_payload := public.get_skpe_strategic_map(target_formulation_id);

  insert into public.skpe_strategic_map_versions (
    organization_id,
    project_id,
    formulation_id,
    package_id,
    version_number,
    status,
    source_validated_at,
    validated_by,
    validation_notes,
    payload,
    metadata,
    created_by
  )
  values (
    formulation_row.organization_id,
    formulation_row.project_id,
    target_formulation_id,
    package_row.id,
    next_version_number,
    'official',
    package_row.validated_at,
    package_row.validated_by,
    package_row.validation_notes,
    map_payload,
    jsonb_build_object(
      'capturedReason', nullif(trim(capture_reason), ''),
      'formulationVersionNumber', formulation_row.version_number
    ),
    auth.uid()
  )
  returning id into saved_version_id;

  perform public.skpe_record_operational_audit(
    formulation_row.organization_id,
    formulation_row.project_id,
    'strategic_map_version',
    saved_version_id,
    'strategic_map_official_version_captured',
    coalesce(
      nullif(trim(capture_reason), ''),
      'Mapa Estratégico validado humanamente e registrado como versão oficial.'
    ),
    null,
    jsonb_build_object(
      'formulation_id', target_formulation_id,
      'package_id', package_row.id,
      'version_number', next_version_number,
      'source_validated_at', package_row.validated_at
    )
  );

  return saved_version_id;
end;
$$;

comment on function public.capture_skpe_strategic_map_version(uuid, text) is
  'Captura uma versão oficial imutável do ME validado, sem criar nova Formulação.';

revoke execute on function public.capture_skpe_strategic_map_version(uuid, text)
  from public, authenticated;
grant execute on function public.capture_skpe_strategic_map_version(uuid, text)
  to service_role;

-- ============================================================
-- 4. INVALIDAÇÃO: ME VALIDADO EXIGE REVISÃO EXPLÍCITA
-- ============================================================

alter function public.skpe_invalidate_strategic_map_package(uuid, text)
  rename to skpe_invalidate_strategic_map_package_legacy_20260913;

revoke execute on function public.skpe_invalidate_strategic_map_package_legacy_20260913(uuid, text)
  from public, authenticated;
grant execute on function public.skpe_invalidate_strategic_map_package_legacy_20260913(uuid, text)
  to service_role;

create or replace function public.skpe_invalidate_strategic_map_package(
  target_formulation_id uuid,
  invalidation_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_status text;
begin
  select package.status
  into current_status
  from public.skpe_strategic_map_packages package
  where package.formulation_id = target_formulation_id;

  if current_status = 'validated' then
    raise exception
      'O Mapa Estratégico validado é versão oficial. Inicie uma revisão do ME antes de alterar seu conteúdo.'
      using errcode = '55000';
  end if;

  return public.skpe_invalidate_strategic_map_package_legacy_20260913(
    target_formulation_id,
    invalidation_reason
  );
end;
$$;

comment on function public.skpe_invalidate_strategic_map_package(uuid, text) is
  'Impede reabertura destrutiva de ME validado; alterações exigem revisão explícita do ME.';

grant execute on function public.skpe_invalidate_strategic_map_package(uuid, text)
  to service_role;

-- ============================================================
-- 5. WORKFLOW: VALIDAR, VERSIONAR E ABRIR REVISÃO
-- ============================================================

alter function public.transition_skpe_strategic_map(uuid, text, text, text)
  rename to transition_skpe_strategic_map_legacy_20260913;

revoke execute on function public.transition_skpe_strategic_map_legacy_20260913(uuid, text, text, text)
  from public, authenticated;
grant execute on function public.transition_skpe_strategic_map_legacy_20260913(uuid, text, text, text)
  to service_role;

create or replace function public.transition_skpe_strategic_map(
  target_formulation_id uuid,
  transition_action text,
  decision_notes text default null,
  change_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  normalized_action text;
  formulation_row public.skpe_strategic_formulations%rowtype;
  previous_package public.skpe_strategic_map_packages%rowtype;
  updated_package public.skpe_strategic_map_packages%rowtype;
  transition_result jsonb;
  official_version_id uuid;
  official_version_number integer;
begin
  normalized_action := lower(trim(coalesce(transition_action, '')));

  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = target_formulation_id;

  if not found then
    raise exception 'Formulação Estratégica não encontrada.'
      using errcode = '22023';
  end if;

  if normalized_action = 'begin_revision' then
    perform public.skpe_assert_reason(change_reason);
    perform public.skpe_assert_formulation_editable(target_formulation_id);

    if not public.can_manage_skpe_formulation(formulation_row.organization_id) then
      raise exception 'Acesso negado para iniciar revisão do Mapa Estratégico.'
        using errcode = '42501';
    end if;

    if length(trim(coalesce(decision_notes, ''))) < 10 then
      raise exception 'Informe a motivação da revisão do Mapa, com no mínimo 10 caracteres.'
        using errcode = '22023';
    end if;

    select *
    into previous_package
    from public.skpe_strategic_map_packages
    where formulation_id = target_formulation_id
    for update;

    if not found or previous_package.status <> 'validated' then
      raise exception 'Somente um Mapa Estratégico validado pode iniciar revisão.'
        using errcode = '55000';
    end if;

    official_version_id := public.capture_skpe_strategic_map_version(
      target_formulation_id,
      'Preservação da versão oficial antes da abertura de revisão.'
    );

    select version_row.version_number
    into official_version_number
    from public.skpe_strategic_map_versions version_row
    where version_row.id = official_version_id;

    update public.skpe_strategic_map_packages
    set
      status = 'in_elaboration',
      validation_notes = null,
      submitted_for_validation_at = null,
      submitted_for_validation_by = null,
      validated_at = null,
      validated_by = null,
      metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
        'revisionOfOfficialVersionId', official_version_id,
        'revisionOfOfficialVersionNumber', official_version_number,
        'revisionOpenedAt', timezone('utc', now()),
        'revisionOpenedBy', auth.uid(),
        'revisionReason', trim(decision_notes)
      ),
      updated_by = auth.uid()
    where id = previous_package.id
    returning * into updated_package;

    update public.skpe_strategic_objectives
    set
      validation_status = 'draft',
      approved_at = null,
      approved_by = null,
      updated_by = auth.uid()
    where formulation_id = target_formulation_id
      and status <> 'archived';

    perform public.skpe_record_operational_audit(
      updated_package.organization_id,
      updated_package.project_id,
      'strategic_map_package',
      updated_package.id,
      'strategic_map_revision_started',
      change_reason,
      to_jsonb(previous_package),
      to_jsonb(updated_package)
    );

    return jsonb_build_object(
      'formulationId', target_formulation_id,
      'strategicMapPackageId', updated_package.id,
      'previousStatus', previous_package.status,
      'currentStatus', updated_package.status,
      'transitionAction', normalized_action,
      'revisionOfOfficialVersionId', official_version_id,
      'revisionOfOfficialVersionNumber', official_version_number
    );
  end if;

  select *
  into previous_package
  from public.skpe_strategic_map_packages
  where formulation_id = target_formulation_id;

  if normalized_action = 'return_for_adjustments'
     and previous_package.status = 'validated' then
    raise exception
      'Mapa Estratégico validado não pode ser reaberto diretamente. Use begin_revision para preservar a versão oficial.'
      using errcode = '55000';
  end if;

  transition_result := public.transition_skpe_strategic_map_legacy_20260913(
    target_formulation_id,
    transition_action,
    decision_notes,
    change_reason
  );

  if normalized_action = 'validate' then
    official_version_id := public.capture_skpe_strategic_map_version(
      target_formulation_id,
      change_reason
    );

    select version_row.version_number
    into official_version_number
    from public.skpe_strategic_map_versions version_row
    where version_row.id = official_version_id;

    transition_result := transition_result || jsonb_build_object(
      'officialMapVersionId', official_version_id,
      'officialMapVersionNumber', official_version_number
    );
  end if;

  return transition_result;
end;
$$;

comment on function public.transition_skpe_strategic_map(uuid, text, text, text) is
  'Workflow Product do ME: valida e captura versão oficial; revisão posterior exige begin_revision.';

grant execute on function public.transition_skpe_strategic_map(uuid, text, text, text)
  to authenticated, service_role;

-- ============================================================
-- 6. CONFIGURAÇÃO NÃO PODE ENFRAQUECER REGRAS DE OURO
-- ============================================================

alter function public.configure_skpe_strategic_map(
  uuid, boolean, text, boolean, jsonb, text
)
  rename to configure_skpe_strategic_map_legacy_20260913;

revoke execute on function public.configure_skpe_strategic_map_legacy_20260913(
  uuid, boolean, text, boolean, jsonb, text
) from public, authenticated;
grant execute on function public.configure_skpe_strategic_map_legacy_20260913(
  uuid, boolean, text, boolean, jsonb, text
) to service_role;

create or replace function public.configure_skpe_strategic_map(
  target_formulation_id uuid,
  require_theme boolean default true,
  cycle_policy text default 'warn',
  recommend_owner boolean default true,
  package_metadata jsonb default null,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  package_status text;
begin
  if not coalesce(require_theme, false) then
    raise exception 'Tema principal é obrigatório no Mapa Estratégico SPARKs PE.'
      using errcode = '22023';
  end if;

  if not coalesce(recommend_owner, false) then
    raise exception 'Responsável de Objetivo Estratégico é obrigatório no SPARKs PE.'
      using errcode = '22023';
  end if;

  select package.status
  into package_status
  from public.skpe_strategic_map_packages package
  where package.formulation_id = target_formulation_id;

  if package_status = 'validated' then
    raise exception
      'Mapa Estratégico validado exige begin_revision antes de qualquer alteração de configuração.'
      using errcode = '55000';
  end if;

  return public.configure_skpe_strategic_map_legacy_20260913(
    target_formulation_id,
    true,
    cycle_policy,
    true,
    package_metadata,
    change_reason
  );
end;
$$;

comment on function public.configure_skpe_strategic_map(
  uuid, boolean, text, boolean, jsonb, text
) is
  'Mantém compatibilidade da assinatura, mas Tema e responsável são obrigatórios por decisão Product.';

grant execute on function public.configure_skpe_strategic_map(
  uuid, boolean, text, boolean, jsonb, text
) to authenticated, service_role;

-- ============================================================
-- 7. CONSULTA DE HISTÓRICO OFICIAL
-- ============================================================

create or replace function public.get_skpe_strategic_map_versions(
  target_formulation_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
begin
  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = target_formulation_id;

  if not found then
    raise exception 'Formulação Estratégica não encontrada.'
      using errcode = '22023';
  end if;

  if not public.can_view_skpe_formulation(formulation_row.organization_id) then
    raise exception 'Acesso negado ao histórico do Mapa Estratégico.'
      using errcode = '42501';
  end if;

  return coalesce((
    select jsonb_agg(
      jsonb_build_object(
        'id', version_row.id,
        'versionNumber', version_row.version_number,
        'status', version_row.status,
        'sourceValidatedAt', version_row.source_validated_at,
        'validatedBy', version_row.validated_by,
        'validationNotes', version_row.validation_notes,
        'metadata', version_row.metadata,
        'createdAt', version_row.created_at
      )
      order by version_row.version_number desc
    )
    from public.skpe_strategic_map_versions version_row
    where version_row.formulation_id = target_formulation_id
  ), '[]'::jsonb);
end;
$$;

comment on function public.get_skpe_strategic_map_versions(uuid) is
  'Lista versões oficiais imutáveis do Mapa Estratégico da Formulação.';

grant execute on function public.get_skpe_strategic_map_versions(uuid)
  to authenticated, service_role;

create or replace function public.get_skpe_strategic_map_version(
  target_version_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  version_row public.skpe_strategic_map_versions%rowtype;
begin
  select *
  into version_row
  from public.skpe_strategic_map_versions
  where id = target_version_id;

  if not found then
    raise exception 'Versão oficial do Mapa Estratégico não encontrada.'
      using errcode = '22023';
  end if;

  if not public.can_view_skpe_formulation(version_row.organization_id) then
    raise exception 'Acesso negado à versão oficial do Mapa Estratégico.'
      using errcode = '42501';
  end if;

  return jsonb_build_object(
    'id', version_row.id,
    'formulationId', version_row.formulation_id,
    'versionNumber', version_row.version_number,
    'status', version_row.status,
    'sourceValidatedAt', version_row.source_validated_at,
    'validatedBy', version_row.validated_by,
    'validationNotes', version_row.validation_notes,
    'payload', version_row.payload,
    'metadata', version_row.metadata,
    'createdAt', version_row.created_at
  );
end;
$$;

comment on function public.get_skpe_strategic_map_version(uuid) is
  'Retorna o snapshot imutável de uma versão oficial do Mapa Estratégico.';

grant execute on function public.get_skpe_strategic_map_version(uuid)
  to authenticated, service_role;

-- Funções legadas renomeadas permanecem internas para compatibilidade
-- e rastreabilidade; consumidores autenticados usam somente as fachadas Product.

-- ============================================================
-- 8. AUDITORIA INCLUI VERSÕES OFICIAIS DO ME
-- ============================================================

create or replace function public.get_skpe_strategic_map_audit(
  target_formulation_id uuid
)
returns table (
  audit_id uuid,
  entity_type text,
  entity_id uuid,
  action_code text,
  reason text,
  previous_data jsonb,
  new_data jsonb,
  occurred_at timestamptz,
  actor_user_id uuid
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
begin
  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = target_formulation_id;

  if not found then
    raise exception 'Versão da Formulação Estratégica não encontrada.'
      using errcode = '22023';
  end if;

  if not public.can_view_skpe_formulation(formulation_row.organization_id) then
    raise exception 'Acesso negado ao histórico do Mapa Estratégico.'
      using errcode = '42501';
  end if;

  return query
  select
    audit.id,
    audit.entity_type,
    audit.entity_id,
    audit.action_code,
    audit.reason,
    audit.previous_data,
    audit.new_data,
    audit.occurred_at,
    audit.actor_user_id
  from public.skpe_operational_audit audit
  where audit.organization_id = formulation_row.organization_id
    and audit.project_id = formulation_row.project_id
    and audit.entity_type in (
      'strategic_map_package',
      'strategic_map_version',
      'strategic_theme',
      'bsc_perspective',
      'strategic_objective',
      'objective_relation'
    )
    and (
      audit.previous_data ->> 'formulation_id' = target_formulation_id::text
      or audit.new_data ->> 'formulation_id' = target_formulation_id::text
    )
  order by audit.occurred_at desc, audit.id desc;
end;
$$;

comment on function public.get_skpe_strategic_map_audit(uuid) is
  'Histórico auditável do ME, incluindo captura das versões oficiais imutáveis.';

grant execute on function public.get_skpe_strategic_map_audit(uuid)
  to authenticated, service_role;

commit;
