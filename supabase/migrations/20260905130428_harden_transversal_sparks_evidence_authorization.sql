begin;

create or replace function public.can_view_sparks_evidence(target_organization_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select
    public.is_platform_super_admin()
    or public.is_organization_admin(target_organization_id)
    or exists (
      select 1
      from public.organization_modules om
      join public.modules m on m.id = om.module_id
      join public.user_module_roles umr on umr.organization_module_id = om.id
      join public.module_roles mr on mr.id = umr.module_role_id
      join public.role_permissions rp on rp.module_role_id = mr.id
      join public.module_permissions mp on mp.id = rp.module_permission_id
      where om.organization_id = target_organization_id
        and mp.code in ('evidence.view', 'evidence_checklist.view')
        and m.status = 'active'
        and mp.active = true
        and mr.active = true
        and om.enabled = true
        and om.status in ('trial', 'active')
        and om.valid_from <= timezone('utc', now())
        and (om.valid_until is null or om.valid_until >= timezone('utc', now()))
        and umr.user_id = auth.uid()
        and umr.status = 'active'
        and umr.valid_from <= timezone('utc', now())
        and (umr.valid_until is null or umr.valid_until >= timezone('utc', now()))
        and public.is_active_member(om.organization_id)
    )
    or (
      public.is_platform_visitor()
      and public.is_active_member(target_organization_id)
      and exists (
        select 1
        from public.organization_modules om
        join public.modules m on m.id = om.module_id
        join public.module_permissions mp on mp.module_id = m.id
        where om.organization_id = target_organization_id
          and mp.code in ('evidence.view', 'evidence_checklist.view')
          and m.status = 'active'
          and mp.active = true
          and om.enabled = true
          and om.status in ('trial', 'active')
          and om.valid_from <= timezone('utc', now())
          and (om.valid_until is null or om.valid_until >= timezone('utc', now()))
      )
    );
$function$;

create or replace function public.can_manage_sparks_evidence(target_organization_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select
    public.is_platform_super_admin()
    or public.is_organization_admin(target_organization_id)
    or exists (
      select 1
      from public.organization_modules om
      join public.modules m on m.id = om.module_id
      join public.user_module_roles umr on umr.organization_module_id = om.id
      join public.module_roles mr on mr.id = umr.module_role_id
      join public.role_permissions rp on rp.module_role_id = mr.id
      join public.module_permissions mp on mp.id = rp.module_permission_id
      where om.organization_id = target_organization_id
        and mp.code in ('evidence.manage', 'evidence_checklist.manage')
        and m.status = 'active'
        and mp.active = true
        and mr.active = true
        and om.enabled = true
        and om.status in ('trial', 'active')
        and om.valid_from <= timezone('utc', now())
        and (om.valid_until is null or om.valid_until >= timezone('utc', now()))
        and umr.user_id = auth.uid()
        and umr.status = 'active'
        and umr.valid_from <= timezone('utc', now())
        and (umr.valid_until is null or umr.valid_until >= timezone('utc', now()))
        and public.is_active_member(om.organization_id)
    );
$function$;

comment on function public.can_view_sparks_evidence(uuid) is
  'AutorizaÃ§Ã£o transversal de leitura de evidÃªncias da organizaÃ§Ã£o, independente do mÃ³dulo consumidor.';
comment on function public.can_manage_sparks_evidence(uuid) is
  'AutorizaÃ§Ã£o transversal de gestÃ£o de evidÃªncias da organizaÃ§Ã£o, independente do mÃ³dulo consumidor.';

revoke all on function public.can_view_sparks_evidence(uuid) from public;
revoke all on function public.can_manage_sparks_evidence(uuid) from public;
grant execute on function public.can_view_sparks_evidence(uuid) to authenticated;
grant execute on function public.can_manage_sparks_evidence(uuid) to authenticated;

drop policy if exists sparks_evidence_assets_select on public.sparks_evidence_assets;
create policy sparks_evidence_assets_select
on public.sparks_evidence_assets
for select
to authenticated
using (public.can_view_sparks_evidence(organization_id));

drop policy if exists sparks_evidence_assets_manage on public.sparks_evidence_assets;
create policy sparks_evidence_assets_manage
on public.sparks_evidence_assets
for all
to authenticated
using (public.can_manage_sparks_evidence(organization_id))
with check (public.can_manage_sparks_evidence(organization_id));

drop policy if exists sparks_evidence_links_select on public.sparks_evidence_links;
create policy sparks_evidence_links_select
on public.sparks_evidence_links
for select
to authenticated
using (public.can_view_sparks_evidence(organization_id));

drop policy if exists sparks_evidence_links_manage on public.sparks_evidence_links;
create policy sparks_evidence_links_manage
on public.sparks_evidence_links
for all
to authenticated
using (public.can_manage_sparks_evidence(organization_id))
with check (public.can_manage_sparks_evidence(organization_id));

drop policy if exists sparks_evidence_versions_select on public.sparks_evidence_versions;
create policy sparks_evidence_versions_select
on public.sparks_evidence_versions
for select
to authenticated
using (
  exists (
    select 1
    from public.sparks_evidence_assets evidence
    where evidence.id = sparks_evidence_versions.evidence_asset_id
      and public.can_view_sparks_evidence(evidence.organization_id)
  )
);

drop policy if exists sparks_evidence_versions_manage on public.sparks_evidence_versions;
create policy sparks_evidence_versions_manage
on public.sparks_evidence_versions
for all
to authenticated
using (
  exists (
    select 1
    from public.sparks_evidence_assets evidence
    where evidence.id = sparks_evidence_versions.evidence_asset_id
      and public.can_manage_sparks_evidence(evidence.organization_id)
  )
)
with check (
  exists (
    select 1
    from public.sparks_evidence_assets evidence
    where evidence.id = sparks_evidence_versions.evidence_asset_id
      and public.can_manage_sparks_evidence(evidence.organization_id)
  )
);

drop policy if exists sparks_evidence_usage_assessments_select on public.sparks_evidence_usage_assessments;
create policy sparks_evidence_usage_assessments_select
on public.sparks_evidence_usage_assessments
for select
to authenticated
using (
  exists (
    select 1
    from public.sparks_evidence_links link
    where link.id = sparks_evidence_usage_assessments.evidence_link_id
      and public.can_view_sparks_evidence(link.organization_id)
  )
);

drop policy if exists sparks_evidence_usage_assessments_manage on public.sparks_evidence_usage_assessments;
create policy sparks_evidence_usage_assessments_manage
on public.sparks_evidence_usage_assessments
for all
to authenticated
using (
  exists (
    select 1
    from public.sparks_evidence_links link
    where link.id = sparks_evidence_usage_assessments.evidence_link_id
      and public.can_manage_sparks_evidence(link.organization_id)
  )
)
with check (
  exists (
    select 1
    from public.sparks_evidence_links link
    where link.id = sparks_evidence_usage_assessments.evidence_link_id
      and public.can_manage_sparks_evidence(link.organization_id)
  )
);

create or replace function public.register_sparks_evidence_asset(
  target_organization_id uuid,
  evidence_title text,
  evidence_description text,
  target_evidence_type text,
  target_source_type text,
  target_origin_module_code text,
  target_reference_date date,
  target_validity_date date,
  target_confidentiality_level text,
  target_content_hash text,
  target_file_name text,
  target_mime_type text,
  target_file_size_bytes bigint,
  target_storage_bucket text,
  target_storage_path text,
  change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  asset_id uuid;
  version_id uuid;
begin
  if not public.can_manage_sparks_evidence(target_organization_id) then
    raise exception 'Acesso administrativo necessÃ¡rio para cadastrar evidÃªncias.' using errcode = '42501';
  end if;

  if length(trim(coalesce(evidence_title, ''))) = 0 then
    raise exception 'Informe o tÃ­tulo da evidÃªncia.';
  end if;

  if length(trim(coalesce(change_reason, ''))) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.';
  end if;

  if target_content_hash is not null then
    select evidence.id into asset_id
    from public.sparks_evidence_assets evidence
    where evidence.organization_id = target_organization_id
      and evidence.content_hash = target_content_hash
      and evidence.archived_at is null
    limit 1;
  end if;

  if asset_id is not null then
    return asset_id;
  end if;

  insert into public.sparks_evidence_assets (
    organization_id, title, description, evidence_type, source_type,
    origin_module_code, reference_date, validity_date, confidentiality_level,
    content_hash, created_by, updated_by, metadata
  ) values (
    target_organization_id, trim(evidence_title), nullif(trim(coalesce(evidence_description, '')), ''),
    target_evidence_type, coalesce(target_source_type, 'internal'), target_origin_module_code,
    target_reference_date, target_validity_date, coalesce(target_confidentiality_level, 'internal'),
    target_content_hash, auth.uid(), auth.uid(), jsonb_build_object('creation_reason', trim(change_reason))
  ) returning id into asset_id;

  if target_file_name is not null then
    insert into public.sparks_evidence_versions (
      evidence_asset_id, version_number, version_label, storage_bucket, storage_path,
      file_name, mime_type, file_size_bytes, content_hash, change_summary, created_by
    ) values (
      asset_id, 1, '1.0', target_storage_bucket, target_storage_path,
      target_file_name, target_mime_type, target_file_size_bytes, target_content_hash,
      trim(change_reason), auth.uid()
    ) returning id into version_id;

    update public.sparks_evidence_assets
      set current_version_id = version_id
    where id = asset_id;
  end if;

  return asset_id;
end;
$function$;

create or replace function public.link_sparks_evidence(
  target_organization_id uuid,
  target_evidence_asset_id uuid,
  target_module_code text,
  target_type text,
  target_id uuid,
  target_usage_purpose text,
  target_relevance_level text,
  target_is_primary boolean,
  change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  link_id uuid;
begin
  if not public.can_manage_sparks_evidence(target_organization_id) then
    raise exception 'Acesso administrativo necessÃ¡rio para vincular evidÃªncias.' using errcode = '42501';
  end if;

  if length(trim(coalesce(change_reason, ''))) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.';
  end if;

  if not exists (
    select 1 from public.sparks_evidence_assets evidence
    where evidence.id = target_evidence_asset_id
      and evidence.organization_id = target_organization_id
      and evidence.archived_at is null
  ) then
    raise exception 'EvidÃªncia nÃ£o encontrada para a organizaÃ§Ã£o informada.';
  end if;

  insert into public.sparks_evidence_links (
    organization_id, evidence_asset_id, module_code, target_type, target_id,
    usage_purpose, relevance_level, is_primary, created_by, metadata
  ) values (
    target_organization_id, target_evidence_asset_id, trim(target_module_code), trim(target_type), target_id,
    target_usage_purpose, coalesce(target_relevance_level, 'important'), coalesce(target_is_primary, false),
    auth.uid(), jsonb_build_object('link_reason', trim(change_reason))
  )
  on conflict (evidence_asset_id, module_code, target_type, target_id)
  do update set
    usage_status = 'active',
    usage_purpose = excluded.usage_purpose,
    relevance_level = excluded.relevance_level,
    is_primary = excluded.is_primary,
    notes = trim(change_reason)
  returning id into link_id;

  return link_id;
end;
$function$;

revoke all on function public.register_sparks_evidence_asset(uuid,text,text,text,text,text,date,date,text,text,text,text,bigint,text,text,text) from public;
revoke all on function public.link_sparks_evidence(uuid,uuid,text,text,uuid,text,text,boolean,text) from public;
grant execute on function public.register_sparks_evidence_asset(uuid,text,text,text,text,text,date,date,text,text,text,text,bigint,text,text,text) to authenticated;
grant execute on function public.link_sparks_evidence(uuid,uuid,text,text,uuid,text,text,boolean,text) to authenticated;

commit;