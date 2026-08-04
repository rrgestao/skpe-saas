do $verification$
declare
  avatar_column_exists boolean;
  bucket_exists boolean;
  get_profile_exists boolean;
  update_profile_exists boolean;
  direct_update_granted boolean;
begin
  select exists(
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'avatar_url'
  )
  into avatar_column_exists;

  if not avatar_column_exists then
    raise exception 'Campo public.profiles.avatar_url não encontrado.';
  end if;

  select exists(
    select 1
    from storage.buckets
    where id = 'user-avatars'
      and public = false
  )
  into bucket_exists;

  if not bucket_exists then
    raise exception 'Bucket privado user-avatars não encontrado.';
  end if;

  select to_regprocedure(
    'public.get_my_transversal_profile()'
  ) is not null
  into get_profile_exists;

  if not get_profile_exists then
    raise exception 'RPC get_my_transversal_profile não encontrada.';
  end if;

  select to_regprocedure(
    'public.update_my_transversal_profile(text,text,text,text,text)'
  ) is not null
  into update_profile_exists;

  if not update_profile_exists then
    raise exception 'RPC update_my_transversal_profile não encontrada.';
  end if;

  select has_table_privilege(
    'authenticated',
    'public.profiles',
    'UPDATE'
  )
  into direct_update_granted;

  if direct_update_granted then
    raise exception 'UPDATE direto em public.profiles ainda está concedido a authenticated.';
  end if;

  raise notice 'OK - Fundação B6.1 validada.';
end;
$verification$;

select
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
from storage.buckets
where id = 'user-avatars';

select
  p.oid::regprocedure::text as assinatura,
  p.prosecdef as security_definer,
  p.provolatile as volatilidade
from pg_proc as p
join pg_namespace as n
  on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'get_my_transversal_profile',
    'update_my_transversal_profile'
  )
order by p.proname;