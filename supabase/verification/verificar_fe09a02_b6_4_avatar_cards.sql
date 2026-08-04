do $verification$
declare
  function_exists boolean;
  is_security_definer boolean;
  is_stable boolean;
begin
  select to_regprocedure(
    'public.list_platform_admin_user_avatars()'
  ) is not null
  into function_exists;

  if not function_exists then
    raise exception 'RPC list_platform_admin_user_avatars não encontrada.';
  end if;

  select
    p.prosecdef,
    p.provolatile = 's'
  into
    is_security_definer,
    is_stable
  from pg_proc as p
  join pg_namespace as n
    on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'list_platform_admin_user_avatars'
    and pg_get_function_identity_arguments(p.oid) = '';

  if is_security_definer is distinct from true then
    raise exception 'RPC não está como SECURITY DEFINER.';
  end if;

  if is_stable is distinct from true then
    raise exception 'RPC não está como STABLE.';
  end if;

  raise notice 'OK - B6.4 listagem desacoplada de avatares validada.';
end;
$verification$;