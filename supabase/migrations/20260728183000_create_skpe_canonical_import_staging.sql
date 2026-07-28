-- ============================================================
-- SPARKs PE - Bloco 1.10B-1
-- Staging e simulacao segura de importacao canonica
-- Nao grava em tabelas estrategicas definitivas.
-- ============================================================

create table if not exists public.skpe_import_batches (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  project_id uuid not null references public.skpe_projects(id) on delete cascade,
  schema_code text not null,
  schema_version text not null,
  source_file text not null,
  source_file_fingerprint text not null,
  organization_label text,
  horizon text,
  sheet_count integer not null default 0,
  mapped_sheet_count integer not null default 0,
  declared_record_count integer not null default 0,
  staged_record_count integer not null default 0,
  valid_record_count integer not null default 0,
  quarantined_record_count integer not null default 0,
  blocked_record_count integer not null default 0,
  conflict_count integer not null default 0,
  status text not null default 'draft',
  journey_snapshot jsonb not null default '{}'::jsonb,
  payload_metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid default auth.uid(),
  staged_at timestamptz,
  confirmed_at timestamptz,
  confirmed_by uuid,
  cancelled_at timestamptz,
  cancelled_by uuid,
  cancellation_reason text,
  constraint skpe_import_batches_status_check check (
    status in ('draft','staged','reviewed','ready','cancelled','applied','rolled_back','failed')
  ),
  constraint skpe_import_batches_source_unique unique (
    organization_id, project_id, source_file_fingerprint, schema_version
  )
);

create index if not exists idx_skpe_import_batches_org_project
  on public.skpe_import_batches(organization_id, project_id, created_at desc);

create table if not exists public.skpe_import_records (
  id uuid primary key default gen_random_uuid(),
  batch_id uuid not null references public.skpe_import_batches(id) on delete cascade,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  project_id uuid not null references public.skpe_projects(id) on delete cascade,
  entity_code text not null,
  entity_name text,
  source_sheet text not null,
  source_row integer,
  external_key text not null,
  fingerprint text,
  quality_status text not null default 'valid',
  simulation_status text not null default 'pending_mapping',
  target_table text,
  target_record_id uuid,
  values_json jsonb not null default '{}'::jsonb,
  validation_messages jsonb not null default '[]'::jsonb,
  proposed_action text not null default 'review',
  reviewed boolean not null default false,
  review_decision text,
  review_notes text,
  reviewed_at timestamptz,
  reviewed_by uuid,
  created_at timestamptz not null default timezone('utc', now()),
  constraint skpe_import_records_quality_check check (
    quality_status in ('valid','quarantined','invalid')
  ),
  constraint skpe_import_records_simulation_check check (
    simulation_status in ('pending_mapping','new','update','unchanged','conflict','blocked','invalid','quarantined')
  ),
  constraint skpe_import_records_action_check check (
    proposed_action in ('insert','update','ignore','block','review')
  ),
  constraint skpe_import_records_batch_key_unique unique (batch_id, external_key)
);

create index if not exists idx_skpe_import_records_batch
  on public.skpe_import_records(batch_id, simulation_status, entity_code);

create index if not exists idx_skpe_import_records_external_key
  on public.skpe_import_records(organization_id, project_id, external_key);

create table if not exists public.skpe_import_conflicts (
  id uuid primary key default gen_random_uuid(),
  batch_id uuid not null references public.skpe_import_batches(id) on delete cascade,
  conflict_code text not null,
  severity text not null,
  topic text not null,
  source_a text,
  value_a text,
  source_b text,
  value_b text,
  canonical_value text,
  resolution_rule text,
  proposed_decision text,
  final_decision text,
  status text not null default 'accepted_from_payload',
  reviewed_at timestamptz,
  reviewed_by uuid,
  notes text,
  created_at timestamptz not null default timezone('utc', now()),
  constraint skpe_import_conflicts_severity_check check (severity in ('low','medium','high','critical')),
  constraint skpe_import_conflicts_status_check check (
    status in ('pending','accepted_from_payload','approved','adjusted','rejected')
  ),
  constraint skpe_import_conflicts_batch_code_unique unique (batch_id, conflict_code)
);

create table if not exists public.skpe_import_events (
  id uuid primary key default gen_random_uuid(),
  batch_id uuid not null references public.skpe_import_batches(id) on delete cascade,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  project_id uuid not null references public.skpe_projects(id) on delete cascade,
  actor_user_id uuid default auth.uid(),
  event_code text not null,
  event_data jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null default timezone('utc', now())
);

alter table public.skpe_import_batches enable row level security;
alter table public.skpe_import_records enable row level security;
alter table public.skpe_import_conflicts enable row level security;
alter table public.skpe_import_events enable row level security;

do $$
begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='skpe_import_batches' and policyname='skpe_import_batches_select') then
    create policy skpe_import_batches_select on public.skpe_import_batches
      for select using (public.can_view_skpe_journey(organization_id));
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='skpe_import_batches' and policyname='skpe_import_batches_manage') then
    create policy skpe_import_batches_manage on public.skpe_import_batches
      for all using (public.can_manage_skpe_journey(organization_id))
      with check (public.can_manage_skpe_journey(organization_id));
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='skpe_import_records' and policyname='skpe_import_records_select') then
    create policy skpe_import_records_select on public.skpe_import_records
      for select using (public.can_view_skpe_journey(organization_id));
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='skpe_import_records' and policyname='skpe_import_records_manage') then
    create policy skpe_import_records_manage on public.skpe_import_records
      for all using (public.can_manage_skpe_journey(organization_id))
      with check (public.can_manage_skpe_journey(organization_id));
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='skpe_import_conflicts' and policyname='skpe_import_conflicts_select') then
    create policy skpe_import_conflicts_select on public.skpe_import_conflicts
      for select using (exists (
        select 1 from public.skpe_import_batches b
        where b.id = batch_id and public.can_view_skpe_journey(b.organization_id)
      ));
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='skpe_import_conflicts' and policyname='skpe_import_conflicts_manage') then
    create policy skpe_import_conflicts_manage on public.skpe_import_conflicts
      for all using (exists (
        select 1 from public.skpe_import_batches b
        where b.id = batch_id and public.can_manage_skpe_journey(b.organization_id)
      )) with check (exists (
        select 1 from public.skpe_import_batches b
        where b.id = batch_id and public.can_manage_skpe_journey(b.organization_id)
      ));
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='skpe_import_events' and policyname='skpe_import_events_select') then
    create policy skpe_import_events_select on public.skpe_import_events
      for select using (public.can_view_skpe_journey(organization_id));
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='skpe_import_events' and policyname='skpe_import_events_manage') then
    create policy skpe_import_events_manage on public.skpe_import_events
      for all using (public.can_manage_skpe_journey(organization_id))
      with check (public.can_manage_skpe_journey(organization_id));
  end if;
end $$;

create or replace function public.skpe_stage_canonical_import(
  p_organization_id uuid,
  p_project_id uuid,
  p_payload jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_batch_id uuid;
  v_entity jsonb;
  v_record jsonb;
  v_conflict jsonb;
  v_schema text;
  v_version text;
  v_count integer := 0;
  v_valid integer := 0;
  v_quarantined integer := 0;
  v_blocked integer := 0;
  v_quality text;
  v_simulation text;
  v_action text;
  v_messages jsonb;
begin
  if not public.can_manage_skpe_journey(p_organization_id) then
    raise exception 'Usuario sem permissao para gerenciar importacoes nesta organizacao.';
  end if;

  if not exists (
    select 1 from public.skpe_projects
    where id = p_project_id and organization_id = p_organization_id and archived_at is null
  ) then
    raise exception 'Projeto nao pertence a organizacao informada ou esta arquivado.';
  end if;

  v_schema := p_payload->>'schema';
  v_version := p_payload->>'schemaVersion';

  if v_schema <> 'SPARKS_PE_CANONICAL_IMPORT_PREVIEW' then
    raise exception 'Schema de payload invalido: %', coalesce(v_schema, '<nulo>');
  end if;

  if v_version not in ('2.0.1') then
    raise exception 'Versao de payload nao suportada: %', coalesce(v_version, '<nulo>');
  end if;

  insert into public.skpe_import_batches (
    organization_id, project_id, schema_code, schema_version,
    source_file, source_file_fingerprint, organization_label, horizon,
    sheet_count, mapped_sheet_count, declared_record_count,
    journey_snapshot, payload_metadata, status
  ) values (
    p_organization_id, p_project_id, v_schema, v_version,
    p_payload->>'sourceFile', p_payload->>'sourceFileFingerprint',
    p_payload->>'organization', p_payload->>'horizon',
    coalesce((p_payload->>'sheetCount')::integer,0),
    coalesce((p_payload->>'mappedSheetCount')::integer,0),
    coalesce((p_payload->>'totalPayloadRecords')::integer,0),
    coalesce(p_payload->'journey','{}'::jsonb),
    jsonb_build_object(
      'generatedAt', p_payload->'generatedAt',
      'databaseWrites', p_payload->'databaseWrites',
      'validPayloadRecords', p_payload->'validPayloadRecords',
      'quarantinedRecords', p_payload->'quarantinedRecords'
    ),
    'draft'
  )
  returning id into v_batch_id;

  for v_entity in select value from jsonb_array_elements(coalesce(p_payload->'entities','[]'::jsonb))
  loop
    for v_record in select value from jsonb_array_elements(coalesce(v_entity->'records','[]'::jsonb))
    loop
      v_count := v_count + 1;
      v_quality := coalesce(v_record->>'qualityStatus','valid');
      v_messages := '[]'::jsonb;
      v_simulation := 'pending_mapping';
      v_action := 'review';

      if v_quality = 'quarantined' then
        v_simulation := 'quarantined';
        v_action := 'block';
        v_quarantined := v_quarantined + 1;
      elsif v_quality = 'invalid' then
        v_simulation := 'invalid';
        v_action := 'block';
        v_blocked := v_blocked + 1;
      else
        v_valid := v_valid + 1;
      end if;

      -- Regra semantica conhecida: registro v17 deslocado na aba de controle de versoes.
      if v_record->>'externalKey' = 'version_control:v17' then
        v_simulation := 'blocked';
        v_action := 'block';
        v_blocked := v_blocked + 1;
        v_valid := greatest(v_valid - 1, 0);
        v_messages := jsonb_build_array(
          jsonb_build_object(
            'code','SEMANTIC_COLUMN_SHIFT',
            'severity','high',
            'message','Registro v17 possui campos desalinhados na origem e exige revisao manual.'
          )
        );
      end if;

      insert into public.skpe_import_records (
        batch_id, organization_id, project_id,
        entity_code, entity_name, source_sheet, source_row,
        external_key, fingerprint, quality_status,
        simulation_status, values_json, validation_messages, proposed_action
      ) values (
        v_batch_id, p_organization_id, p_project_id,
        coalesce(v_record->>'entityCode', v_entity->>'entityCode'),
        v_entity->>'entityName',
        v_record->>'sourceSheet',
        nullif(v_record->>'sourceRow','')::integer,
        v_record->>'externalKey',
        v_record->>'fingerprint',
        v_quality,
        v_simulation,
        coalesce(v_record->'values','{}'::jsonb),
        v_messages,
        v_action
      );
    end loop;
  end loop;

  for v_conflict in select value from jsonb_array_elements(coalesce(p_payload->'conflicts','[]'::jsonb))
  loop
    insert into public.skpe_import_conflicts (
      batch_id, conflict_code, severity, topic,
      source_a, value_a, source_b, value_b,
      canonical_value, resolution_rule, proposed_decision, status
    ) values (
      v_batch_id,
      v_conflict->>'id',
      v_conflict->>'severity',
      v_conflict->>'topic',
      v_conflict->>'sourceA',
      v_conflict->>'valueA',
      v_conflict->>'sourceB',
      v_conflict->>'valueB',
      v_conflict->>'canonicalValue',
      v_conflict->>'rule',
      v_conflict->>'decision',
      'accepted_from_payload'
    );
  end loop;

  update public.skpe_import_batches
  set staged_record_count = v_count,
      valid_record_count = v_valid,
      quarantined_record_count = v_quarantined,
      blocked_record_count = v_blocked,
      conflict_count = jsonb_array_length(coalesce(p_payload->'conflicts','[]'::jsonb)),
      status = 'staged',
      staged_at = timezone('utc', now())
  where id = v_batch_id;

  insert into public.skpe_import_events (
    batch_id, organization_id, project_id, event_code, event_data
  ) values (
    v_batch_id, p_organization_id, p_project_id, 'IMPORT_STAGED',
    jsonb_build_object(
      'records', v_count,
      'valid', v_valid,
      'quarantined', v_quarantined,
      'blocked', v_blocked
    )
  );

  return v_batch_id;
exception
  when unique_violation then
    raise exception 'Este arquivo e esta versao ja foram preparados anteriormente para o mesmo projeto.';
end;
$$;

create or replace function public.skpe_get_import_batch_summary(p_batch_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'batch', to_jsonb(b),
    'bySimulationStatus', coalesce((
      select jsonb_object_agg(x.simulation_status, x.total)
      from (
        select simulation_status, count(*) total
        from public.skpe_import_records r
        where r.batch_id = b.id
        group by simulation_status
      ) x
    ), '{}'::jsonb),
    'byEntity', coalesce((
      select jsonb_agg(to_jsonb(x) order by x.entity_code)
      from (
        select entity_code, count(*) total,
               count(*) filter (where simulation_status='blocked') blocked,
               count(*) filter (where simulation_status='quarantined') quarantined
        from public.skpe_import_records r
        where r.batch_id = b.id
        group by entity_code
      ) x
    ), '[]'::jsonb),
    'conflicts', coalesce((
      select jsonb_agg(to_jsonb(c) order by c.conflict_code)
      from public.skpe_import_conflicts c where c.batch_id=b.id
    ), '[]'::jsonb)
  )
  from public.skpe_import_batches b
  where b.id = p_batch_id
    and public.can_view_skpe_journey(b.organization_id);
$$;

create or replace function public.skpe_cancel_import_batch(
  p_batch_id uuid,
  p_reason text
)
returns boolean
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_org uuid;
  v_status text;
begin
  select organization_id, status into v_org, v_status
  from public.skpe_import_batches where id=p_batch_id;

  if v_org is null then raise exception 'Lote nao encontrado.'; end if;
  if not public.can_manage_skpe_journey(v_org) then raise exception 'Sem permissao.'; end if;
  if v_status in ('applied','rolled_back') then
    raise exception 'Lote ja aplicado ou revertido nao pode ser apenas cancelado.';
  end if;

  update public.skpe_import_batches
  set status='cancelled', cancelled_at=timezone('utc',now()),
      cancelled_by=auth.uid(), cancellation_reason=p_reason
  where id=p_batch_id;

  insert into public.skpe_import_events(batch_id,organization_id,project_id,event_code,event_data)
  select id,organization_id,project_id,'IMPORT_CANCELLED',jsonb_build_object('reason',p_reason)
  from public.skpe_import_batches where id=p_batch_id;

  return true;
end;
$$;

grant execute on function public.skpe_stage_canonical_import(uuid,uuid,jsonb) to authenticated;
grant execute on function public.skpe_get_import_batch_summary(uuid) to authenticated;
grant execute on function public.skpe_cancel_import_batch(uuid,text) to authenticated;
