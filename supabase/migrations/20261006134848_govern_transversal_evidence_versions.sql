-- SPARKs transversal evidence version lifecycle
-- Adds a governed new-version operation for existing canonical evidence assets.
-- Does not delete prior versions or fabricate validation.

create or replace function public.add_sparks_evidence_version(
  target_organization_id uuid,
  target_evidence_asset_id uuid,
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
  next_version_number integer;
  new_version_id uuid;
  current_hash text;
  existing_version_id uuid;
begin
  if not public.can_manage_sparks_evidence(target_organization_id) then
    raise exception 'Acesso administrativo necessário para versionar evidências.' using errcode = '42501';
  end if;

  if target_evidence_asset_id is null then
    raise exception 'Informe o ativo de evidência.' using errcode = '22023';
  end if;

  if length(trim(coalesce(target_content_hash, ''))) = 0 then
    raise exception 'Informe o hash do arquivo.' using errcode = '22023';
  end if;

  if length(trim(coalesce(target_file_name, ''))) = 0 then
    raise exception 'Informe o nome do arquivo.' using errcode = '22023';
  end if;

  if target_file_size_bytes is null or target_file_size_bytes < 0 then
    raise exception 'Informe o tamanho válido do arquivo.' using errcode = '22023';
  end if;

  if target_storage_bucket is distinct from 'sparks-evidence' then
    raise exception 'A nova versão deve usar o repositório canônico de evidências.' using errcode = '22023';
  end if;

  if length(trim(coalesce(target_storage_path, ''))) = 0
     or target_storage_path not like target_organization_id::text || '/%' then
    raise exception 'O caminho do arquivo deve permanecer no escopo da organização.' using errcode = '22023';
  end if;

  if length(trim(coalesce(change_reason, ''))) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.' using errcode = '22023';
  end if;

  select evidence.content_hash
    into current_hash
  from public.sparks_evidence_assets evidence
  where evidence.id = target_evidence_asset_id
    and evidence.organization_id = target_organization_id
    and evidence.archived_at is null
  for update;

  if not found then
    raise exception 'Ativo de evidência não encontrado na organização.' using errcode = '22023';
  end if;

  if current_hash is not distinct from target_content_hash then
    raise exception 'O arquivo é idêntico à versão atual da evidência.' using errcode = '22023';
  end if;

  select version.id
    into existing_version_id
  from public.sparks_evidence_versions version
  where version.evidence_asset_id = target_evidence_asset_id
    and version.content_hash = target_content_hash
  limit 1;

  if existing_version_id is not null then
    raise exception 'Este conteúdo já existe no histórico de versões da evidência.' using errcode = '22023';
  end if;

  select coalesce(max(version.version_number), 0) + 1
    into next_version_number
  from public.sparks_evidence_versions version
  where version.evidence_asset_id = target_evidence_asset_id;

  insert into public.sparks_evidence_versions (
    evidence_asset_id,
    version_number,
    version_label,
    storage_bucket,
    storage_path,
    file_name,
    mime_type,
    file_size_bytes,
    content_hash,
    change_summary,
    metadata,
    created_by
  ) values (
    target_evidence_asset_id,
    next_version_number,
    next_version_number::text || '.0',
    'sparks-evidence',
    trim(target_storage_path),
    trim(target_file_name),
    nullif(trim(coalesce(target_mime_type, '')), ''),
    target_file_size_bytes,
    trim(target_content_hash),
    trim(change_reason),
    jsonb_build_object(
      'governed_version', true,
      'previous_content_hash', current_hash,
      'human_validation_required', true
    ),
    auth.uid()
  )
  returning id into new_version_id;

  update public.sparks_evidence_assets
  set
    current_version_id = new_version_id,
    content_hash = trim(target_content_hash),
    validation_status = 'pending',
    reliability_level = 'not_assessed',
    quality_score = null,
    completeness_score = null,
    currentness_score = null,
    overall_score = null,
    updated_at = timezone('utc', now()),
    updated_by = auth.uid(),
    metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
      'last_version_reason', trim(change_reason),
      'last_version_number', next_version_number,
      'last_version_at', timezone('utc', now()),
      'human_validation_required', true
    )
  where id = target_evidence_asset_id;

  return new_version_id;
end;
$function$;

revoke all on function public.add_sparks_evidence_version(uuid,uuid,text,text,text,bigint,text,text,text)
from public, anon;

grant execute on function public.add_sparks_evidence_version(uuid,uuid,text,text,text,bigint,text,text,text)
to authenticated, service_role;

comment on function public.add_sparks_evidence_version(uuid,uuid,text,text,text,bigint,text,text,text) is
'Adds an immutable physical version to an existing canonical evidence asset. Prior versions remain available; the new content returns the asset to pending validation.';
