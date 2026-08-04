do $verification$
declare
  function_source text;
begin
  select pg_get_functiondef(p.oid)
  into function_source
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'set_platform_admin_user_avatar'
    and pg_get_function_identity_arguments(p.oid)
      = 'target_user_id uuid, input_avatar_storage_path text, change_reason text';

  if function_source is null then
    raise exception 'RPC set_platform_admin_user_avatar não encontrada.';
  end if;

  if position('data_updated' in function_source) = 0 then
    raise exception 'RPC não utiliza o event_type canônico data_updated.';
  end if;

  if position('avatar_updated' in function_source) = 0
     or position('avatar_removed' in function_source) = 0 then
    raise exception 'Metadados operacionais do avatar não foram preservados.';
  end if;

  raise notice 'OK - B6.3.3 auditoria do avatar administrativo validada.';
end;
$verification$;