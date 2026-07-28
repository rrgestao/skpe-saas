begin;

-- Plataforma SPARKs / SK-PE
-- Bloco 1.9 - Gestão Operacional de Artefatos e Evidências

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'methodology-artifacts',
  'methodology-artifacts',
  false,
  52428800,
  array[
    'application/pdf',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'text/plain','text/markdown','text/html','application/json','application/zip',
    'image/png','image/jpeg'
  ]
)
on conflict (id) do update
set file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create or replace function public.get_methodology_artifact_detail(target_artifact_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_artifact public.sparks_methodology_artifacts%rowtype;
  v_result jsonb;
begin
  select * into v_artifact
  from public.sparks_methodology_artifacts
  where id = target_artifact_id;

  if v_artifact.id is null then
    raise exception 'Artefato não encontrado.';
  end if;

  if not public.can_view_methodology_artifacts(v_artifact.organization_id) then
    raise exception 'Acesso negado ao artefato.' using errcode = '42501';
  end if;

  select jsonb_build_object(
    'artifact', to_jsonb(a) || jsonb_build_object(
      'artifact_type_code', t.artifact_type_code,
      'artifact_type_name', t.artifact_type_name,
      'category', t.category,
      'requires_validation', t.requires_validation,
      'default_file_extensions', t.default_file_extensions,
      'requirement_code', r.requirement_code,
      'requirement_name', r.requirement_name
    ),
    'versions', coalesce((
      select jsonb_agg(to_jsonb(v) order by v.version_number desc)
      from public.sparks_methodology_artifact_versions v
      where v.artifact_id = a.id
    ), '[]'::jsonb),
    'validations', coalesce((
      select jsonb_agg(to_jsonb(x) order by x.validated_at desc)
      from public.sparks_methodology_artifact_validations x
      where x.artifact_id = a.id
    ), '[]'::jsonb),
    'evidence_links', coalesce((
      select jsonb_agg(to_jsonb(e) order by e.created_at desc)
      from public.sparks_methodology_artifact_evidence_links e
      where e.artifact_id = a.id
    ), '[]'::jsonb),
    'audit', coalesce((
      select jsonb_agg(to_jsonb(h) order by h.occurred_at desc)
      from public.sparks_methodology_artifact_audit h
      where h.artifact_id = a.id
      limit 100
    ), '[]'::jsonb)
  ) into v_result
  from public.sparks_methodology_artifacts a
  join public.sparks_methodology_artifact_types t on t.id = a.artifact_type_id
  left join public.sparks_methodology_delivery_requirements r on r.id = a.requirement_id
  where a.id = target_artifact_id;

  return v_result;
end;
$$;

create or replace function public.update_methodology_artifact_status(
  target_artifact_id uuid,
  target_status text,
  target_reason text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_artifact public.sparks_methodology_artifacts%rowtype;
  v_previous jsonb;
begin
  select * into v_artifact from public.sparks_methodology_artifacts where id = target_artifact_id;
  if v_artifact.id is null then raise exception 'Artefato não encontrado.'; end if;
  if not public.can_manage_methodology_artifacts(v_artifact.organization_id) then
    raise exception 'Acesso negado para alterar o artefato.' using errcode = '42501';
  end if;
  if coalesce(trim(target_reason),'') = '' then raise exception 'Informe a justificativa.'; end if;
  if target_status not in ('planned','in_preparation','in_review','submitted','validated','validated_with_reservations','rejected','superseded','archived','waived') then
    raise exception 'Situação inválida.';
  end if;

  v_previous := jsonb_build_object('status', v_artifact.status, 'waiver_reason', v_artifact.waiver_reason);

  update public.sparks_methodology_artifacts
  set status = target_status,
      submitted_at = case when target_status = 'submitted' then now() else submitted_at end,
      validated_at = case when target_status in ('validated','validated_with_reservations') then now() else validated_at end,
      waived_at = case when target_status = 'waived' then now() else waived_at end,
      waiver_reason = case when target_status = 'waived' then target_reason else waiver_reason end,
      updated_at = now(), updated_by = auth.uid()
  where id = target_artifact_id;

  insert into public.sparks_methodology_artifact_audit(
    organization_id, project_id, artifact_id, actor_user_id,
    action_code, action_description, previous_data, new_data
  ) values (
    v_artifact.organization_id, v_artifact.project_id, v_artifact.id, auth.uid(),
    'STATUS_CHANGED', target_reason, v_previous,
    jsonb_build_object('status', target_status)
  );
end;
$$;

create or replace function public.get_methodology_artifact_audit(
  target_organization_id uuid,
  target_project_id uuid
)
returns table(
  audit_id uuid,
  artifact_id uuid,
  artifact_code text,
  artifact_title text,
  action_code text,
  action_description text,
  actor_user_id uuid,
  occurred_at timestamptz,
  previous_data jsonb,
  new_data jsonb
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.can_view_methodology_artifacts(target_organization_id) then
    raise exception 'Acesso negado à auditoria.' using errcode = '42501';
  end if;
  return query
  select h.id, h.artifact_id, a.artifact_code, a.title, h.action_code,
         h.action_description, h.actor_user_id, h.occurred_at,
         h.previous_data, h.new_data
  from public.sparks_methodology_artifact_audit h
  left join public.sparks_methodology_artifacts a on a.id = h.artifact_id
  where h.organization_id = target_organization_id
    and h.project_id = target_project_id
  order by h.occurred_at desc
  limit 500;
end;
$$;

drop policy if exists p_methodology_storage_read on storage.objects;
create policy p_methodology_storage_read on storage.objects
for select to authenticated
using (
  bucket_id = 'methodology-artifacts'
  and public.can_view_methodology_artifacts((storage.foldername(name))[1]::uuid)
);

drop policy if exists p_methodology_storage_insert on storage.objects;
create policy p_methodology_storage_insert on storage.objects
for insert to authenticated
with check (
  bucket_id = 'methodology-artifacts'
  and public.can_manage_methodology_artifacts((storage.foldername(name))[1]::uuid)
);

drop policy if exists p_methodology_storage_update on storage.objects;
create policy p_methodology_storage_update on storage.objects
for update to authenticated
using (
  bucket_id = 'methodology-artifacts'
  and public.can_manage_methodology_artifacts((storage.foldername(name))[1]::uuid)
)
with check (
  bucket_id = 'methodology-artifacts'
  and public.can_manage_methodology_artifacts((storage.foldername(name))[1]::uuid)
);

drop policy if exists p_methodology_storage_delete on storage.objects;
create policy p_methodology_storage_delete on storage.objects
for delete to authenticated
using (
  bucket_id = 'methodology-artifacts'
  and public.can_manage_methodology_artifacts((storage.foldername(name))[1]::uuid)
);

grant execute on function public.get_methodology_artifact_detail(uuid) to authenticated;
grant execute on function public.update_methodology_artifact_status(uuid,text,text) to authenticated;
grant execute on function public.get_methodology_artifact_audit(uuid,uuid) to authenticated;

select
  (select count(*) from public.sparks_methodology_artifact_types where active) as tipos_ativos,
  (select count(*) from public.sparks_methodology_delivery_requirements where active) as requisitos_ativos,
  exists(select 1 from storage.buckets where id = 'methodology-artifacts') as bucket_criado;

commit;
