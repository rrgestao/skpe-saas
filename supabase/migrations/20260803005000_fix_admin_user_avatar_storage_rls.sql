begin;

create or replace function public.can_platform_admin_manage_user_avatar(
  target_user_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select
    auth.uid() is not null
    and public.is_platform_super_admin()
    and exists (
      select 1
      from public.profiles as p
      where p.id = target_user_id
    );
$function$;

revoke all on function public.can_platform_admin_manage_user_avatar(uuid)
from public;

grant execute on function public.can_platform_admin_manage_user_avatar(uuid)
to authenticated;

drop policy if exists user_avatars_select_super_admin
on storage.objects;

create policy user_avatars_select_super_admin
on storage.objects
for select
to authenticated
using (
  bucket_id = 'user-avatars'
  and public.can_platform_admin_manage_user_avatar(
    nullif((storage.foldername(name))[1], '')::uuid
  )
);

drop policy if exists user_avatars_insert_super_admin
on storage.objects;

create policy user_avatars_insert_super_admin
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'user-avatars'
  and public.can_platform_admin_manage_user_avatar(
    nullif((storage.foldername(name))[1], '')::uuid
  )
);

drop policy if exists user_avatars_update_super_admin
on storage.objects;

create policy user_avatars_update_super_admin
on storage.objects
for update
to authenticated
using (
  bucket_id = 'user-avatars'
  and public.can_platform_admin_manage_user_avatar(
    nullif((storage.foldername(name))[1], '')::uuid
  )
)
with check (
  bucket_id = 'user-avatars'
  and public.can_platform_admin_manage_user_avatar(
    nullif((storage.foldername(name))[1], '')::uuid
  )
);

drop policy if exists user_avatars_delete_super_admin
on storage.objects;

create policy user_avatars_delete_super_admin
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'user-avatars'
  and public.can_platform_admin_manage_user_avatar(
    nullif((storage.foldername(name))[1], '')::uuid
  )
);

comment on function public.can_platform_admin_manage_user_avatar(uuid)
is 'Valida, sob SECURITY DEFINER, se o usuário autenticado é SUPER-ADMIN e pode gerenciar o avatar do usuário-alvo.';

commit;