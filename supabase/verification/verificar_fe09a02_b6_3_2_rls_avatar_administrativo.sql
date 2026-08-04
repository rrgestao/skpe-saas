do $verification$
declare
  helper_exists boolean;
  helper_security_definer boolean;
  policy_count integer;
begin
  select to_regprocedure(
    'public.can_platform_admin_manage_user_avatar(uuid)'
  ) is not null
  into helper_exists;

  if not helper_exists then
    raise exception 'Helper can_platform_admin_manage_user_avatar não encontrado.';
  end if;

  select p.prosecdef
  from pg_proc as p
  join pg_namespace as n
    on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'can_platform_admin_manage_user_avatar'
  into helper_security_definer;

  if helper_security_definer is distinct from true then
    raise exception 'Helper não está como SECURITY DEFINER.';
  end if;

  select count(*)
  from pg_policies
  where schemaname = 'storage'
    and tablename = 'objects'
    and policyname in (
      'user_avatars_select_super_admin',
      'user_avatars_insert_super_admin',
      'user_avatars_update_super_admin',
      'user_avatars_delete_super_admin'
    )
  into policy_count;

  if policy_count <> 4 then
    raise exception 'Políticas administrativas incompletas. Total: %', policy_count;
  end if;

  raise notice 'OK - B6.3.2 RLS do avatar administrativo validada.';
end;
$verification$;

select
  policyname,
  cmd,
  qual,
  with_check
from pg_policies
where schemaname = 'storage'
  and tablename = 'objects'
  and policyname like 'user_avatars_%super_admin'
order by policyname;