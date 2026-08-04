do $verification$
declare
  read_rpc boolean;
  write_rpc boolean;
  bucket_private boolean;
  admin_policy_count integer;
begin
  select to_regprocedure(
    'public.get_platform_admin_user_avatar(uuid)'
  ) is not null
  into read_rpc;

  select to_regprocedure(
    'public.set_platform_admin_user_avatar(uuid,text,text)'
  ) is not null
  into write_rpc;

  if not read_rpc or not write_rpc then
    raise exception 'RPCs administrativas de avatar não encontradas.';
  end if;

  select exists(
    select 1
    from storage.buckets
    where id = 'user-avatars'
      and public = false
  )
  into bucket_private;

  if not bucket_private then
    raise exception 'Bucket privado user-avatars não encontrado.';
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
  into admin_policy_count;

  if admin_policy_count <> 4 then
    raise exception 'Políticas administrativas incompletas. Total: %', admin_policy_count;
  end if;

  raise notice 'OK - B6.3 avatar administrativo validado.';
end;
$verification$;

select
  p.oid::regprocedure::text as assinatura,
  p.prosecdef as security_definer,
  p.provolatile as volatilidade
from pg_proc as p
join pg_namespace as n
  on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'get_platform_admin_user_avatar',
    'set_platform_admin_user_avatar'
  )
order by p.proname;