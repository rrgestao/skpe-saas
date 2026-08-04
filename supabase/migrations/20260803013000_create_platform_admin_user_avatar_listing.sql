begin;

create or replace function public.list_platform_admin_user_avatars()
returns table (
  user_id uuid,
  avatar_storage_path text
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if auth.uid() is null then
    raise exception 'Usuário não autenticado.';
  end if;

  if not public.is_platform_super_admin() then
    raise exception 'Apenas SUPER-ADMIN pode consultar avatares administrativos.';
  end if;

  return query
  select
    p.id as user_id,
    p.avatar_url as avatar_storage_path
  from public.profiles as p
  where p.avatar_url is not null
    and trim(p.avatar_url) <> '';
end;
$function$;

revoke all on function public.list_platform_admin_user_avatars()
from public;

grant execute on function public.list_platform_admin_user_avatars()
to authenticated;

comment on function public.list_platform_admin_user_avatars()
is 'Lista, em uma única chamada administrativa, os caminhos de avatar dos usuários para composição dos cards.';

commit;