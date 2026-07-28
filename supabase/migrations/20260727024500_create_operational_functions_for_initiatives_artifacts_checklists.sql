-- ============================================================
-- Plataforma SPARKs / SK-PE
-- Migration: Funções operacionais auditadas para iniciativas,
--            BMC/VPC e checklist inteligente da PEM-00
-- Idioma dos conteúdos funcionais: Português do Brasil
-- ============================================================

begin;

-- ============================================================
-- 1. AUDITORIA OPERACIONAL DO SK-PE
-- ============================================================

create table if not exists public.skpe_operational_audit (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations(id) on delete cascade,
  project_id uuid
    references public.skpe_projects(id) on delete cascade,
  entity_type text not null,
  entity_id uuid not null,
  action_code text not null,
  reason text,
  previous_data jsonb,
  new_data jsonb,
  occurred_at timestamptz not null default timezone('utc', now()),
  actor_user_id uuid references public.profiles(id) on delete set null
);

comment on table public.skpe_operational_audit is
  'Trilha de auditoria operacional das iniciativas, artefatos de negócio e checklists do SK-PE.';

create index if not exists idx_skpe_operational_audit_entity
  on public.skpe_operational_audit(entity_type, entity_id, occurred_at desc);

create index if not exists idx_skpe_operational_audit_organization
  on public.skpe_operational_audit(organization_id, occurred_at desc);

alter table public.skpe_operational_audit enable row level security;

drop policy if exists skpe_operational_audit_select
  on public.skpe_operational_audit;

create policy skpe_operational_audit_select
on public.skpe_operational_audit
for select to authenticated
using (
  public.can_view_skpe_initiatives(organization_id)
  or public.can_view_skpe_business_artifacts(organization_id)
  or public.can_view_skpe_evidence_checklist(organization_id)
);

revoke all on table public.skpe_operational_audit from anon;

-- ============================================================
-- 2. FUNÇÕES AUXILIARES INTERNAS
-- ============================================================

create or replace function public.skpe_assert_reason(
  change_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if change_reason is null or length(trim(change_reason)) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.';
  end if;
end;
$$;

create or replace function public.skpe_record_operational_audit(
  target_organization_id uuid,
  target_project_id uuid,
  target_entity_type text,
  target_entity_id uuid,
  target_action_code text,
  change_reason text,
  previous_data jsonb,
  new_data jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  audit_id uuid;
begin
  insert into public.skpe_operational_audit (
    organization_id,
    project_id,
    entity_type,
    entity_id,
    action_code,
    reason,
    previous_data,
    new_data,
    actor_user_id
  )
  values (
    target_organization_id,
    target_project_id,
    target_entity_type,
    target_entity_id,
    target_action_code,
    nullif(trim(change_reason), ''),
    previous_data,
    new_data,
    auth.uid()
  )
  returning id into audit_id;

  return audit_id;
end;
$$;

-- ============================================================
-- 3. INICIATIVAS — CRIAÇÃO E ATUALIZAÇÃO
-- ============================================================

create or replace function public.create_skpe_initiative(
  target_project_id uuid,
  initiative_code text,
  initiative_name text,
  initiative_description text,
  initiative_type text,
  initiative_priority text default 'medium',
  responsible_area text default null,
  owner_user_id uuid default null,
  sponsor_user_id uuid default null,
  start_date date default null,
  due_date date default null,
  planned_cost numeric default null,
  planned_benefit numeric default null,
  strategic_theme text default null,
  linked_journey_item_id uuid default null,
  parent_initiative_id uuid default null,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_organization_id uuid;
  new_initiative_id uuid;
  new_row jsonb;
begin
  perform public.skpe_assert_reason(change_reason);

  select project.organization_id
  into target_organization_id
  from public.skpe_projects project
  where project.id = target_project_id;

  if target_organization_id is null then
    raise exception 'Projeto estratégico não encontrado.';
  end if;

  if not public.can_manage_skpe_initiatives(target_organization_id) then
    raise exception 'Você não possui permissão para gerenciar iniciativas desta organização.';
  end if;

  insert into public.skpe_initiatives (
    organization_id,
    project_id,
    parent_initiative_id,
    linked_journey_item_id,
    code,
    name,
    description,
    initiative_type,
    priority,
    responsible_area,
    owner_user_id,
    sponsor_user_id,
    start_date,
    due_date,
    planned_cost,
    planned_benefit,
    strategic_theme,
    status,
    progress,
    last_update_at,
    created_by,
    updated_by
  )
  values (
    target_organization_id,
    target_project_id,
    parent_initiative_id,
    linked_journey_item_id,
    trim(initiative_code),
    trim(initiative_name),
    nullif(trim(initiative_description), ''),
    initiative_type,
    initiative_priority,
    nullif(trim(responsible_area), ''),
    owner_user_id,
    sponsor_user_id,
    start_date,
    due_date,
    planned_cost,
    planned_benefit,
    nullif(trim(strategic_theme), ''),
    'proposed',
    0,
    timezone('utc', now()),
    auth.uid(),
    auth.uid()
  )
  returning id into new_initiative_id;

  select to_jsonb(initiative)
  into new_row
  from public.skpe_initiatives initiative
  where initiative.id = new_initiative_id;

  perform public.skpe_record_operational_audit(
    target_organization_id,
    target_project_id,
    'initiative',
    new_initiative_id,
    'initiative.created',
    change_reason,
    null,
    new_row
  );

  return new_initiative_id;
end;
$$;

create or replace function public.update_skpe_initiative_status(
  target_initiative_id uuid,
  target_status text,
  target_progress numeric,
  target_health_status text default null,
  target_actual_cost numeric default null,
  target_realized_benefit numeric default null,
  change_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  initiative_row public.skpe_initiatives%rowtype;
  previous_data jsonb;
  new_data jsonb;
begin
  perform public.skpe_assert_reason(change_reason);

  select *
  into initiative_row
  from public.skpe_initiatives
  where id = target_initiative_id
  for update;

  if initiative_row.id is null then
    raise exception 'Iniciativa não encontrada.';
  end if;

  if not public.can_manage_skpe_initiatives(initiative_row.organization_id) then
    raise exception 'Você não possui permissão para alterar esta iniciativa.';
  end if;

  previous_data := to_jsonb(initiative_row);

  update public.skpe_initiatives
  set
    status = target_status,
    progress = target_progress,
    health_status = coalesce(target_health_status, health_status),
    actual_cost = coalesce(target_actual_cost, actual_cost),
    realized_benefit = coalesce(target_realized_benefit, realized_benefit),
    completed_at = case
      when target_status = 'completed' then timezone('utc', now())
      else null
    end,
    last_update_at = timezone('utc', now()),
    updated_by = auth.uid()
  where id = target_initiative_id
  returning to_jsonb(skpe_initiatives)
  into new_data;

  perform public.skpe_record_operational_audit(
    initiative_row.organization_id,
    initiative_row.project_id,
    'initiative',
    target_initiative_id,
    'initiative.status_updated',
    change_reason,
    previous_data,
    new_data
  );
end;
$$;

create or replace function public.link_skpe_initiative_objective(
  target_initiative_id uuid,
  target_strategic_objective_id uuid,
  target_contribution_type text default 'direct',
  target_contribution_weight numeric default null,
  target_notes text default null,
  change_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  initiative_row public.skpe_initiatives%rowtype;
  objective_row public.skpe_strategic_objectives%rowtype;
begin
  perform public.skpe_assert_reason(change_reason);

  select * into initiative_row
  from public.skpe_initiatives
  where id = target_initiative_id;

  select * into objective_row
  from public.skpe_strategic_objectives
  where id = target_strategic_objective_id;

  if initiative_row.id is null or objective_row.id is null then
    raise exception 'Iniciativa ou Objetivo Estratégico — OKRs não encontrado.';
  end if;

  if initiative_row.project_id <> objective_row.project_id then
    raise exception 'A iniciativa e o Objetivo Estratégico — OKRs devem pertencer ao mesmo projeto.';
  end if;

  if not public.can_manage_skpe_initiatives(initiative_row.organization_id) then
    raise exception 'Você não possui permissão para vincular objetivos a esta iniciativa.';
  end if;

  insert into public.skpe_initiative_objectives (
    initiative_id,
    strategic_objective_id,
    contribution_type,
    contribution_weight,
    notes,
    created_by
  )
  values (
    target_initiative_id,
    target_strategic_objective_id,
    target_contribution_type,
    target_contribution_weight,
    nullif(trim(target_notes), ''),
    auth.uid()
  )
  on conflict (initiative_id, strategic_objective_id)
  do update set
    contribution_type = excluded.contribution_type,
    contribution_weight = excluded.contribution_weight,
    notes = excluded.notes;

  perform public.skpe_record_operational_audit(
    initiative_row.organization_id,
    initiative_row.project_id,
    'initiative_objective',
    target_initiative_id,
    'initiative.objective_linked',
    change_reason,
    null,
    jsonb_build_object(
      'strategic_objective_id', target_strategic_objective_id,
      'contribution_type', target_contribution_type,
      'contribution_weight', target_contribution_weight,
      'notes', target_notes
    )
  );
end;
$$;

-- ============================================================
-- 4. INSTRUMENTOS CONTEXTUAIS DAS INICIATIVAS
-- ============================================================

create or replace function public.create_skpe_initiative_instrument(
  target_initiative_id uuid,
  target_instrument_type text,
  target_instrument_code text default null,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  initiative_row public.skpe_initiatives%rowtype;
  reference_id uuid;
  new_instrument_id uuid;
  existing_instrument_id uuid;
begin
  perform public.skpe_assert_reason(change_reason);

  select * into initiative_row
  from public.skpe_initiatives
  where id = target_initiative_id;

  if initiative_row.id is null then
    raise exception 'Iniciativa não encontrada.';
  end if;

  if not public.can_manage_skpe_initiatives(initiative_row.organization_id) then
    raise exception 'Você não possui permissão para criar instrumentos desta iniciativa.';
  end if;

  select instrument.id
  into existing_instrument_id
  from public.skpe_initiative_instruments instrument
  where instrument.initiative_id = target_initiative_id
    and instrument.instrument_type = target_instrument_type
    and instrument.status <> 'archived'
  order by instrument.created_at desc
  limit 1;

  if existing_instrument_id is not null then
    return existing_instrument_id;
  end if;

  if target_instrument_type = 'project_canvas' then
    reference_id := public.create_skpe_project_canvas(
      initiative_row.project_id,
      initiative_row.name || ' — Canvas do Projeto'
    );
  end if;

  insert into public.skpe_initiative_instruments (
    organization_id,
    project_id,
    initiative_id,
    instrument_type,
    instrument_reference_id,
    instrument_code,
    status,
    is_primary,
    created_by,
    updated_by
  )
  values (
    initiative_row.organization_id,
    initiative_row.project_id,
    target_initiative_id,
    target_instrument_type,
    reference_id,
    coalesce(
      nullif(trim(target_instrument_code), ''),
      initiative_row.code || '-' || upper(target_instrument_type)
    ),
    'active',
    true,
    auth.uid(),
    auth.uid()
  )
  returning id into new_instrument_id;

  perform public.skpe_record_operational_audit(
    initiative_row.organization_id,
    initiative_row.project_id,
    'initiative_instrument',
    new_instrument_id,
    'initiative.instrument_created',
    change_reason,
    null,
    jsonb_build_object(
      'initiative_id', target_initiative_id,
      'instrument_type', target_instrument_type,
      'instrument_reference_id', reference_id
    )
  );

  return new_instrument_id;
end;
$$;

-- ============================================================
-- 5. BMC/VPC — CRIAÇÃO, IMPORTAÇÃO E ESTRUTURAÇÃO
-- ============================================================

create or replace function public.create_skpe_business_artifact(
  target_organization_id uuid,
  target_project_id uuid,
  artifact_type text,
  artifact_code text,
  artifact_name text,
  artifact_description text default null,
  source_module text default 'external',
  import_method text default 'manual',
  source_reference_id uuid default null,
  source_reference_code text default null,
  source_file_name text default null,
  source_storage_path text default null,
  source_mime_type text default null,
  reference_date date default null,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_artifact_id uuid;
  next_version integer;
  new_row jsonb;
begin
  perform public.skpe_assert_reason(change_reason);

  if not public.can_manage_skpe_business_artifacts(target_organization_id) then
    raise exception 'Você não possui permissão para gerenciar BMC/VPC desta organização.';
  end if;

  if target_project_id is not null and not exists (
    select 1
    from public.skpe_projects project
    where project.id = target_project_id
      and project.organization_id = target_organization_id
  ) then
    raise exception 'O projeto informado não pertence à organização.';
  end if;

  select coalesce(max(version_number), 0) + 1
  into next_version
  from public.skpe_business_artifacts artifact
  where artifact.organization_id = target_organization_id
    and artifact.artifact_type = create_skpe_business_artifact.artifact_type
    and artifact.code = trim(artifact_code);

  update public.skpe_business_artifacts
  set
    is_current = false,
    status = case when status = 'validated' then 'outdated' else status end,
    updated_by = auth.uid()
  where public.skpe_business_artifacts.organization_id = target_organization_id
    and public.skpe_business_artifacts.artifact_type = create_skpe_business_artifact.artifact_type
    and public.skpe_business_artifacts.code = trim(artifact_code)
    and public.skpe_business_artifacts.is_current = true;

  insert into public.skpe_business_artifacts (
    organization_id,
    project_id,
    artifact_type,
    code,
    name,
    description,
    source_module,
    source_reference_id,
    source_reference_code,
    source_file_name,
    source_storage_path,
    source_mime_type,
    import_method,
    version_number,
    status,
    is_current,
    reference_date,
    created_by,
    updated_by
  )
  values (
    target_organization_id,
    target_project_id,
    artifact_type,
    trim(artifact_code),
    trim(artifact_name),
    nullif(trim(artifact_description), ''),
    source_module,
    source_reference_id,
    nullif(trim(source_reference_code), ''),
    nullif(trim(source_file_name), ''),
    nullif(trim(source_storage_path), ''),
    nullif(trim(source_mime_type), ''),
    import_method,
    next_version,
    'draft',
    true,
    reference_date,
    auth.uid(),
    auth.uid()
  )
  returning id into new_artifact_id;

  select to_jsonb(artifact)
  into new_row
  from public.skpe_business_artifacts artifact
  where artifact.id = new_artifact_id;

  if artifact_type = 'bmc' then
    insert into public.skpe_business_artifact_blocks (
      artifact_id, code, name, display_order, created_by, updated_by
    )
    select new_artifact_id, data.code, data.name, data.display_order, auth.uid(), auth.uid()
    from (
      values
        ('KEY_PARTNERS', 'Parcerias Principais', 10),
        ('KEY_ACTIVITIES', 'Atividades-Chave', 20),
        ('KEY_RESOURCES', 'Recursos Principais', 30),
        ('VALUE_PROPOSITIONS', 'Propostas de Valor', 40),
        ('CUSTOMER_RELATIONSHIPS', 'Relacionamento com Clientes', 50),
        ('CHANNELS', 'Canais', 60),
        ('CUSTOMER_SEGMENTS', 'Segmentos de Clientes', 70),
        ('COST_STRUCTURE', 'Estrutura de Custos', 80),
        ('REVENUE_STREAMS', 'Fontes de Receita', 90)
    ) as data(code, name, display_order);
  else
    insert into public.skpe_business_artifact_blocks (
      artifact_id, code, name, display_order, created_by, updated_by
    )
    select new_artifact_id, data.code, data.name, data.display_order, auth.uid(), auth.uid()
    from (
      values
        ('CUSTOMER_JOBS', 'Tarefas do Cliente', 10),
        ('PAINS', 'Dores', 20),
        ('GAINS', 'Ganhos', 30),
        ('PRODUCTS_SERVICES', 'Produtos e Serviços', 40),
        ('PAIN_RELIEVERS', 'Aliviadores de Dores', 50),
        ('GAIN_CREATORS', 'Criadores de Ganhos', 60)
    ) as data(code, name, display_order);
  end if;

  perform public.skpe_record_operational_audit(
    target_organization_id,
    target_project_id,
    'business_artifact',
    new_artifact_id,
    'business_artifact.created',
    change_reason,
    null,
    new_row
  );

  return new_artifact_id;
end;
$$;

create or replace function public.add_skpe_business_artifact_item(
  target_block_id uuid,
  item_content text,
  item_description text default null,
  item_type text default 'statement',
  item_priority text default 'medium',
  linked_journey_item_id uuid default null,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  artifact_row public.skpe_business_artifacts%rowtype;
  new_item_id uuid;
  next_order integer;
begin
  perform public.skpe_assert_reason(change_reason);

  select artifact.*
  into artifact_row
  from public.skpe_business_artifact_blocks block
  join public.skpe_business_artifacts artifact
    on artifact.id = block.artifact_id
  where block.id = target_block_id;

  if artifact_row.id is null then
    raise exception 'Bloco de BMC/VPC não encontrado.';
  end if;

  if not public.can_manage_skpe_business_artifacts(artifact_row.organization_id) then
    raise exception 'Você não possui permissão para alterar este BMC/VPC.';
  end if;

  select coalesce(max(display_order), 0) + 10
  into next_order
  from public.skpe_business_artifact_items
  where block_id = target_block_id;

  insert into public.skpe_business_artifact_items (
    block_id,
    content,
    description,
    item_type,
    priority,
    validation_status,
    linked_journey_item_id,
    display_order,
    created_by,
    updated_by
  )
  values (
    target_block_id,
    trim(item_content),
    nullif(trim(item_description), ''),
    item_type,
    item_priority,
    'not_assessed',
    linked_journey_item_id,
    next_order,
    auth.uid(),
    auth.uid()
  )
  returning id into new_item_id;

  perform public.skpe_record_operational_audit(
    artifact_row.organization_id,
    artifact_row.project_id,
    'business_artifact_item',
    new_item_id,
    'business_artifact.item_added',
    change_reason,
    null,
    jsonb_build_object(
      'artifact_id', artifact_row.id,
      'block_id', target_block_id,
      'content', item_content,
      'item_type', item_type,
      'priority', item_priority
    )
  );

  return new_item_id;
end;
$$;

create or replace function public.set_skpe_business_artifact_status(
  target_artifact_id uuid,
  target_status text,
  change_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  artifact_row public.skpe_business_artifacts%rowtype;
  previous_data jsonb;
  new_data jsonb;
begin
  perform public.skpe_assert_reason(change_reason);

  select * into artifact_row
  from public.skpe_business_artifacts
  where id = target_artifact_id
  for update;

  if artifact_row.id is null then
    raise exception 'BMC/VPC não encontrado.';
  end if;

  if not public.can_manage_skpe_business_artifacts(artifact_row.organization_id) then
    raise exception 'Você não possui permissão para alterar este BMC/VPC.';
  end if;

  previous_data := to_jsonb(artifact_row);

  update public.skpe_business_artifacts
  set
    status = target_status,
    validated_at = case when target_status = 'validated' then timezone('utc', now()) else null end,
    validated_by = case when target_status = 'validated' then auth.uid() else null end,
    updated_by = auth.uid()
  where id = target_artifact_id
  returning to_jsonb(skpe_business_artifacts)
  into new_data;

  perform public.skpe_record_operational_audit(
    artifact_row.organization_id,
    artifact_row.project_id,
    'business_artifact',
    target_artifact_id,
    'business_artifact.status_updated',
    change_reason,
    previous_data,
    new_data
  );
end;
$$;

-- ============================================================
-- 6. CHECKLIST INTELIGENTE DA PEM-00
-- ============================================================

create or replace function public.create_skpe_evidence_checklist(
  target_project_id uuid,
  checklist_code text,
  checklist_name text,
  checklist_description text default null,
  template_code text default null,
  organization_profile_snapshot jsonb default '{}'::jsonb,
  due_date date default null,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_organization_id uuid;
  new_checklist_id uuid;
begin
  perform public.skpe_assert_reason(change_reason);

  select organization_id
  into target_organization_id
  from public.skpe_projects
  where id = target_project_id;

  if target_organization_id is null then
    raise exception 'Projeto estratégico não encontrado.';
  end if;

  if not public.can_manage_skpe_evidence_checklist(target_organization_id) then
    raise exception 'Você não possui permissão para gerenciar o checklist desta organização.';
  end if;

  insert into public.skpe_evidence_checklists (
    organization_id,
    project_id,
    code,
    name,
    description,
    template_code,
    organization_profile_snapshot,
    status,
    due_date,
    created_by,
    updated_by
  )
  values (
    target_organization_id,
    target_project_id,
    trim(checklist_code),
    trim(checklist_name),
    nullif(trim(checklist_description), ''),
    nullif(trim(template_code), ''),
    coalesce(organization_profile_snapshot, '{}'::jsonb),
    'draft',
    due_date,
    auth.uid(),
    auth.uid()
  )
  returning id into new_checklist_id;

  perform public.skpe_record_operational_audit(
    target_organization_id,
    target_project_id,
    'evidence_checklist',
    new_checklist_id,
    'evidence_checklist.created',
    change_reason,
    null,
    jsonb_build_object(
      'code', checklist_code,
      'name', checklist_name,
      'template_code', template_code,
      'due_date', due_date
    )
  );

  return new_checklist_id;
end;
$$;

create or replace function public.add_skpe_evidence_checklist_item(
  target_checklist_id uuid,
  item_code text,
  item_name text,
  item_description text default null,
  request_reason text default null,
  is_required boolean default false,
  is_applicable boolean default true,
  responsible_area text default null,
  responsible_user_id uuid default null,
  due_date date default null,
  journey_item_id uuid default null,
  parent_item_id uuid default null,
  applicability_rule jsonb default '{}'::jsonb,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  checklist_row public.skpe_evidence_checklists%rowtype;
  new_item_id uuid;
  next_order integer;
begin
  perform public.skpe_assert_reason(change_reason);

  select * into checklist_row
  from public.skpe_evidence_checklists
  where id = target_checklist_id;

  if checklist_row.id is null then
    raise exception 'Checklist não encontrado.';
  end if;

  if not public.can_manage_skpe_evidence_checklist(checklist_row.organization_id) then
    raise exception 'Você não possui permissão para alterar este checklist.';
  end if;

  select coalesce(max(display_order), 0) + 10
  into next_order
  from public.skpe_evidence_checklist_items
  where checklist_id = target_checklist_id;

  insert into public.skpe_evidence_checklist_items (
    checklist_id,
    journey_item_id,
    parent_item_id,
    code,
    name,
    description,
    request_reason,
    applicability_rule,
    is_required,
    is_applicable,
    responsible_area,
    responsible_user_id,
    due_date,
    collection_status,
    assessment_status,
    display_order,
    created_by,
    updated_by
  )
  values (
    target_checklist_id,
    journey_item_id,
    parent_item_id,
    trim(item_code),
    trim(item_name),
    nullif(trim(item_description), ''),
    nullif(trim(request_reason), ''),
    coalesce(applicability_rule, '{}'::jsonb),
    is_required,
    is_applicable,
    nullif(trim(responsible_area), ''),
    responsible_user_id,
    due_date,
    case when is_applicable then 'not_requested' else 'not_applicable' end,
    case when is_applicable then 'not_assessed' else 'not_applicable' end,
    next_order,
    auth.uid(),
    auth.uid()
  )
  returning id into new_item_id;

  perform public.skpe_record_operational_audit(
    checklist_row.organization_id,
    checklist_row.project_id,
    'evidence_checklist_item',
    new_item_id,
    'evidence_checklist.item_added',
    change_reason,
    null,
    jsonb_build_object(
      'checklist_id', target_checklist_id,
      'code', item_code,
      'name', item_name,
      'is_required', is_required,
      'is_applicable', is_applicable
    )
  );

  return new_item_id;
end;
$$;

create or replace function public.register_skpe_checklist_item_file(
  target_checklist_item_id uuid,
  file_name text,
  storage_bucket text default null,
  storage_path text default null,
  mime_type text default null,
  file_size_bytes bigint default null,
  evidence_source_id uuid default null,
  skdoc_document_id uuid default null,
  document_date date default null,
  reference_period_start date default null,
  reference_period_end date default null,
  version_label text default null,
  confidentiality_level text default 'internal',
  notes text default null,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  checklist_row public.skpe_evidence_checklists%rowtype;
  new_file_id uuid;
  received_count bigint;
begin
  perform public.skpe_assert_reason(change_reason);

  select checklist.*
  into checklist_row
  from public.skpe_evidence_checklist_items item
  join public.skpe_evidence_checklists checklist
    on checklist.id = item.checklist_id
  where item.id = target_checklist_item_id;

  if checklist_row.id is null then
    raise exception 'Item do checklist não encontrado.';
  end if;

  if not public.can_manage_skpe_evidence_checklist(checklist_row.organization_id) then
    raise exception 'Você não possui permissão para registrar evidências neste item.';
  end if;

  insert into public.skpe_evidence_checklist_item_files (
    organization_id,
    project_id,
    checklist_item_id,
    evidence_source_id,
    skdoc_document_id,
    storage_bucket,
    storage_path,
    file_name,
    mime_type,
    file_size_bytes,
    document_date,
    reference_period_start,
    reference_period_end,
    version_label,
    validation_status,
    confidentiality_level,
    uploaded_by,
    notes
  )
  values (
    checklist_row.organization_id,
    checklist_row.project_id,
    target_checklist_item_id,
    evidence_source_id,
    skdoc_document_id,
    nullif(trim(storage_bucket), ''),
    nullif(trim(storage_path), ''),
    trim(file_name),
    nullif(trim(mime_type), ''),
    file_size_bytes,
    document_date,
    reference_period_start,
    reference_period_end,
    nullif(trim(version_label), ''),
    'pending',
    confidentiality_level,
    auth.uid(),
    nullif(trim(notes), '')
  )
  returning id into new_file_id;

  select count(*)
  into received_count
  from public.skpe_evidence_checklist_item_files
  where checklist_item_id = target_checklist_item_id;

  update public.skpe_evidence_checklist_items
  set
    collection_status = case
      when received_count = 1 then 'received'
      else 'received'
    end,
    updated_by = auth.uid()
  where id = target_checklist_item_id;

  perform public.skpe_record_operational_audit(
    checklist_row.organization_id,
    checklist_row.project_id,
    'evidence_checklist_file',
    new_file_id,
    'evidence_checklist.file_registered',
    change_reason,
    null,
    jsonb_build_object(
      'checklist_item_id', target_checklist_item_id,
      'file_name', file_name,
      'skdoc_document_id', skdoc_document_id,
      'validation_status', 'pending'
    )
  );

  return new_file_id;
end;
$$;

create or replace function public.assess_skpe_evidence_checklist_item(
  target_checklist_item_id uuid,
  compliance_level integer,
  quality_score numeric default null,
  completeness_score numeric default null,
  currentness_score numeric default null,
  reliability_score numeric default null,
  overall_score numeric default null,
  strengths text default null,
  gaps text default null,
  risks text default null,
  recommendations text default null,
  assessment_basis text default null,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  checklist_row public.skpe_evidence_checklists%rowtype;
  item_row public.skpe_evidence_checklist_items%rowtype;
  next_version integer;
  new_assessment_id uuid;
  target_assessment_status text;
  applicable_count bigint;
  received_or_closed_count bigint;
  calculated_completion numeric;
  calculated_readiness numeric;
begin
  perform public.skpe_assert_reason(change_reason);

  select item.*
  into item_row
  from public.skpe_evidence_checklist_items item
  where item.id = target_checklist_item_id;

  select checklist.*
  into checklist_row
  from public.skpe_evidence_checklist_items item
  join public.skpe_evidence_checklists checklist
    on checklist.id = item.checklist_id
  where item.id = target_checklist_item_id;

  if checklist_row.id is null then
    raise exception 'Item do checklist não encontrado.';
  end if;

  if not public.can_manage_skpe_evidence_checklist(checklist_row.organization_id) then
    raise exception 'Você não possui permissão para avaliar este item.';
  end if;

  target_assessment_status := case compliance_level
    when 0 then 'not_met'
    when 1 then 'not_met'
    when 2 then 'partially_met'
    when 3 then 'met'
    when 4 then 'good_practice'
    when 5 then 'mature_practice'
  end;

  select coalesce(max(assessment_version), 0) + 1
  into next_version
  from public.skpe_evidence_checklist_assessments
  where checklist_item_id = target_checklist_item_id;

  insert into public.skpe_evidence_checklist_assessments (
    organization_id,
    project_id,
    checklist_item_id,
    assessment_version,
    compliance_level,
    quality_score,
    completeness_score,
    currentness_score,
    reliability_score,
    overall_score,
    strengths,
    gaps,
    risks,
    recommendations,
    assessment_basis,
    assessed_by
  )
  values (
    checklist_row.organization_id,
    checklist_row.project_id,
    target_checklist_item_id,
    next_version,
    compliance_level,
    quality_score,
    completeness_score,
    currentness_score,
    reliability_score,
    overall_score,
    nullif(trim(strengths), ''),
    nullif(trim(gaps), ''),
    nullif(trim(risks), ''),
    nullif(trim(recommendations), ''),
    nullif(trim(assessment_basis), ''),
    auth.uid()
  )
  returning id into new_assessment_id;

  update public.skpe_evidence_checklist_items
  set
    assessment_status = target_assessment_status,
    compliance_level = assess_skpe_evidence_checklist_item.compliance_level,
    quality_score = assess_skpe_evidence_checklist_item.quality_score,
    completeness_score = assess_skpe_evidence_checklist_item.completeness_score,
    currentness_score = assess_skpe_evidence_checklist_item.currentness_score,
    reliability_score = assess_skpe_evidence_checklist_item.reliability_score,
    overall_score = assess_skpe_evidence_checklist_item.overall_score,
    strengths = nullif(trim(assess_skpe_evidence_checklist_item.strengths), ''),
    gaps = nullif(trim(assess_skpe_evidence_checklist_item.gaps), ''),
    risks = nullif(trim(assess_skpe_evidence_checklist_item.risks), ''),
    recommendations = nullif(trim(assess_skpe_evidence_checklist_item.recommendations), ''),
    analyst_notes = nullif(trim(assessment_basis), ''),
    last_assessed_at = timezone('utc', now()),
    assessed_by = auth.uid(),
    collection_status = case
      when collection_status = 'not_requested' then 'under_review'
      else collection_status
    end,
    updated_by = auth.uid()
  where id = target_checklist_item_id;

  select
    count(*) filter (where is_applicable),
    count(*) filter (
      where is_applicable
        and collection_status in ('received', 'under_review', 'closed')
    ),
    coalesce(avg(overall_score) filter (where is_applicable and overall_score is not null), 0)
  into applicable_count, received_or_closed_count, calculated_readiness
  from public.skpe_evidence_checklist_items
  where checklist_id = checklist_row.id;

  calculated_completion := case
    when applicable_count = 0 then 0
    else round((received_or_closed_count::numeric / applicable_count::numeric) * 100, 2)
  end;

  update public.skpe_evidence_checklists
  set
    completion_percentage = calculated_completion,
    readiness_score = calculated_readiness,
    status = case
      when calculated_completion >= 100 then 'completed'
      when calculated_completion > 0 then 'under_review'
      else status
    end,
    updated_by = auth.uid()
  where id = checklist_row.id;

  perform public.skpe_record_operational_audit(
    checklist_row.organization_id,
    checklist_row.project_id,
    'evidence_checklist_assessment',
    new_assessment_id,
    'evidence_checklist.item_assessed',
    change_reason,
    to_jsonb(item_row),
    jsonb_build_object(
      'checklist_item_id', target_checklist_item_id,
      'assessment_version', next_version,
      'compliance_level', compliance_level,
      'assessment_status', target_assessment_status,
      'overall_score', overall_score,
      'completion_percentage', calculated_completion,
      'readiness_score', calculated_readiness
    )
  );

  return new_assessment_id;
end;
$$;

create or replace function public.set_skpe_checklist_item_collection_status(
  target_checklist_item_id uuid,
  target_collection_status text,
  change_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  checklist_row public.skpe_evidence_checklists%rowtype;
  previous_data jsonb;
  new_data jsonb;
begin
  perform public.skpe_assert_reason(change_reason);

  select checklist.*
  into checklist_row
  from public.skpe_evidence_checklist_items item
  join public.skpe_evidence_checklists checklist
    on checklist.id = item.checklist_id
  where item.id = target_checklist_item_id;

  if checklist_row.id is null then
    raise exception 'Item do checklist não encontrado.';
  end if;

  if not public.can_manage_skpe_evidence_checklist(checklist_row.organization_id) then
    raise exception 'Você não possui permissão para alterar este item.';
  end if;

  select to_jsonb(item.*)
  into previous_data
  from public.skpe_evidence_checklist_items item
  where item.id = target_checklist_item_id;

  update public.skpe_evidence_checklist_items
  set
    collection_status = target_collection_status,
    is_applicable = case when target_collection_status = 'not_applicable' then false else is_applicable end,
    assessment_status = case when target_collection_status = 'not_applicable' then 'not_applicable' else assessment_status end,
    updated_by = auth.uid()
  where id = target_checklist_item_id
  returning to_jsonb(skpe_evidence_checklist_items)
  into new_data;

  perform public.skpe_record_operational_audit(
    checklist_row.organization_id,
    checklist_row.project_id,
    'evidence_checklist_item',
    target_checklist_item_id,
    'evidence_checklist.collection_status_updated',
    change_reason,
    previous_data,
    new_data
  );
end;
$$;

-- ============================================================
-- 7. PRIVILÉGIOS
-- ============================================================

revoke all on function public.skpe_assert_reason(text) from public, anon;
revoke all on function public.skpe_record_operational_audit(uuid, uuid, text, uuid, text, text, jsonb, jsonb) from public, anon;

revoke all on function public.create_skpe_initiative(uuid, text, text, text, text, text, text, uuid, uuid, date, date, numeric, numeric, text, uuid, uuid, text) from public, anon;
revoke all on function public.update_skpe_initiative_status(uuid, text, numeric, text, numeric, numeric, text) from public, anon;
revoke all on function public.link_skpe_initiative_objective(uuid, uuid, text, numeric, text, text) from public, anon;
revoke all on function public.create_skpe_initiative_instrument(uuid, text, text, text) from public, anon;

revoke all on function public.create_skpe_business_artifact(uuid, uuid, text, text, text, text, text, text, uuid, text, text, text, text, date, text) from public, anon;
revoke all on function public.add_skpe_business_artifact_item(uuid, text, text, text, text, uuid, text) from public, anon;
revoke all on function public.set_skpe_business_artifact_status(uuid, text, text) from public, anon;

revoke all on function public.create_skpe_evidence_checklist(uuid, text, text, text, text, jsonb, date, text) from public, anon;
revoke all on function public.add_skpe_evidence_checklist_item(uuid, text, text, text, text, boolean, boolean, text, uuid, date, uuid, uuid, jsonb, text) from public, anon;
revoke all on function public.register_skpe_checklist_item_file(uuid, text, text, text, text, bigint, uuid, uuid, date, date, date, text, text, text, text) from public, anon;
revoke all on function public.assess_skpe_evidence_checklist_item(uuid, integer, numeric, numeric, numeric, numeric, numeric, text, text, text, text, text, text) from public, anon;
revoke all on function public.set_skpe_checklist_item_collection_status(uuid, text, text) from public, anon;

grant execute on function public.create_skpe_initiative(uuid, text, text, text, text, text, text, uuid, uuid, date, date, numeric, numeric, text, uuid, uuid, text) to authenticated, service_role;
grant execute on function public.update_skpe_initiative_status(uuid, text, numeric, text, numeric, numeric, text) to authenticated, service_role;
grant execute on function public.link_skpe_initiative_objective(uuid, uuid, text, numeric, text, text) to authenticated, service_role;
grant execute on function public.create_skpe_initiative_instrument(uuid, text, text, text) to authenticated, service_role;

grant execute on function public.create_skpe_business_artifact(uuid, uuid, text, text, text, text, text, text, uuid, text, text, text, text, date, text) to authenticated, service_role;
grant execute on function public.add_skpe_business_artifact_item(uuid, text, text, text, text, uuid, text) to authenticated, service_role;
grant execute on function public.set_skpe_business_artifact_status(uuid, text, text) to authenticated, service_role;

grant execute on function public.create_skpe_evidence_checklist(uuid, text, text, text, text, jsonb, date, text) to authenticated, service_role;
grant execute on function public.add_skpe_evidence_checklist_item(uuid, text, text, text, text, boolean, boolean, text, uuid, date, uuid, uuid, jsonb, text) to authenticated, service_role;
grant execute on function public.register_skpe_checklist_item_file(uuid, text, text, text, text, bigint, uuid, uuid, date, date, date, text, text, text, text) to authenticated, service_role;
grant execute on function public.assess_skpe_evidence_checklist_item(uuid, integer, numeric, numeric, numeric, numeric, numeric, text, text, text, text, text, text) to authenticated, service_role;
grant execute on function public.set_skpe_checklist_item_collection_status(uuid, text, text) to authenticated, service_role;

commit;
