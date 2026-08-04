begin;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'user-avatars',
  'user-avatars',
  false,
  5242880,
  array[
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

drop policy if exists user_avatars_select_own
on storage.objects;

create policy user_avatars_select_own
on storage.objects
for select
to authenticated
using (
  bucket_id = 'user-avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists user_avatars_insert_own
on storage.objects;

create policy user_avatars_insert_own
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'user-avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists user_avatars_update_own
on storage.objects;

create policy user_avatars_update_own
on storage.objects
for update
to authenticated
using (
  bucket_id = 'user-avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'user-avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists user_avatars_delete_own
on storage.objects;

create policy user_avatars_delete_own
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'user-avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create or replace function public.get_my_transversal_profile()
returns table(
  user_id uuid,
  email text,
  full_name text,
  display_name text,
  phone text,
  avatar_storage_path text,
  active boolean,
  updated_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $function$
  select
    p.id as user_id,
    p.email,
    p.full_name,
    p.display_name,
    p.phone,
    p.avatar_url as avatar_storage_path,
    p.active,
    p.updated_at
  from public.profiles as p
  where p.id = auth.uid();
$function$;

create or replace function public.update_my_transversal_profile(
  input_full_name text,
  input_display_name text default null,
  input_phone text default null,
  input_avatar_storage_path text default null,
  change_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  current_user_id uuid := auth.uid();
  normalized_avatar_path text;
begin
  if current_user_id is null then
    raise exception 'Usuário não autenticado.';
  end if;

  if nullif(trim(coalesce(change_reason, '')), '') is null then
    raise exception 'O motivo da alteração é obrigatório.';
  end if;

  normalized_avatar_path := nullif(trim(input_avatar_storage_path), '');

  if normalized_avatar_path is not null
     and normalized_avatar_path !~ ('^' || current_user_id::text || '/[A-Za-z0-9._/-]+$') then
    raise exception 'O caminho do avatar não pertence ao usuário autenticado.';
  end if;

  update public.profiles
  set
    full_name = nullif(trim(input_full_name), ''),
    display_name = coalesce(
      nullif(trim(input_display_name), ''),
      nullif(trim(input_full_name), '')
    ),
    phone = nullif(trim(input_phone), ''),
    avatar_url = normalized_avatar_path,
    updated_at = timezone('utc', now())
  where id = current_user_id;

  if not found then
    raise exception 'Perfil do usuário autenticado não encontrado.';
  end if;

  insert into public.privileged_access_audit (
    actor_user_id,
    event_type,
    event_description,
    entity_schema,
    entity_table,
    entity_id,
    metadata
  )
  values (
    current_user_id,
    'data_updated',
    'Perfil transversal atualizado pelo próprio usuário.',
    'public',
    'profiles',
    current_user_id::text,
    jsonb_build_object(
      'source', 'transversal_user_profile',
      'reason', trim(change_reason),
      'avatar_changed', true
    )
  );
end;
$function$;

revoke all on function public.get_my_transversal_profile()
from public;

revoke all on function public.update_my_transversal_profile(
  text,
  text,
  text,
  text,
  text
)
from public;

grant execute on function public.get_my_transversal_profile()
to authenticated;

grant execute on function public.update_my_transversal_profile(
  text,
  text,
  text,
  text,
  text
)
to authenticated;

revoke update on table public.profiles
from authenticated;

drop policy if exists profiles_update_own
on public.profiles;

comment on function public.get_my_transversal_profile()
is 'Retorna o perfil transversal do usuário autenticado.';

comment on function public.update_my_transversal_profile(
  text,
  text,
  text,
  text,
  text
)
is 'Atualiza o perfil transversal do usuário autenticado exclusivamente por RPC, com motivo e auditoria.';

commit;