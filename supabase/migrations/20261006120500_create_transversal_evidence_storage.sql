-- SPARKs transversal evidence storage
-- Creates the private bucket used by the canonical sparks_evidence_* service.
-- No evidence business record is created by this migration.

begin;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'sparks-evidence',
  'sparks-evidence',
  false,
  52428800,
  array[
    'application/pdf',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'text/plain',
    'text/markdown',
    'text/csv',
    'application/json',
    'application/zip',
    'image/png',
    'image/jpeg',
    'image/webp'
  ]
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists sparks_evidence_storage_read on storage.objects;
create policy sparks_evidence_storage_read
on storage.objects
for select
to authenticated
using (
  bucket_id = 'sparks-evidence'
  and public.can_view_sparks_evidence(((storage.foldername(name))[1])::uuid)
);

drop policy if exists sparks_evidence_storage_insert on storage.objects;
create policy sparks_evidence_storage_insert
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'sparks-evidence'
  and public.can_manage_sparks_evidence(((storage.foldername(name))[1])::uuid)
);

drop policy if exists sparks_evidence_storage_update on storage.objects;
create policy sparks_evidence_storage_update
on storage.objects
for update
to authenticated
using (
  bucket_id = 'sparks-evidence'
  and public.can_manage_sparks_evidence(((storage.foldername(name))[1])::uuid)
)
with check (
  bucket_id = 'sparks-evidence'
  and public.can_manage_sparks_evidence(((storage.foldername(name))[1])::uuid)
);

drop policy if exists sparks_evidence_storage_delete on storage.objects;
create policy sparks_evidence_storage_delete
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'sparks-evidence'
  and public.can_manage_sparks_evidence(((storage.foldername(name))[1])::uuid)
);

commit;
