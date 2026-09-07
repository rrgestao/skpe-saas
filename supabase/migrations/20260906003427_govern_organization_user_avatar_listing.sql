create or replace function public.list_managed_organization_user_avatars(
  context_organization_id uuid
)
returns table(user_id uuid, avatar_storage_path text)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if auth.uid() is null then
    raise exception 'Usuário não autenticado.';
  end if;

  if not public.is_platform_super_admin()
     and not public.is_organization_admin(context_organization_id) then
    raise exception 'Apenas SUPER-ADMIN ou Administrador da Organização pode consultar avatares desta organização.';
  end if;

  return query
  select
    membership.user_id,
    profile.avatar_url
  from public.organization_memberships membership
  join public.profiles profile
    on profile.id = membership.user_id
  where membership.organization_id = context_organization_id
    and membership.status = 'active'
    and membership.valid_from <= timezone('utc', now())
    and (
      membership.valid_until is null
      or membership.valid_until >= timezone('utc', now())
    );
end;
$function$;

grant execute on function public.list_managed_organization_user_avatars(uuid) to authenticated;
