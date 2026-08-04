do $verification$
declare
  function_definition text;
begin
  select pg_get_functiondef(p.oid)
    into function_definition
  from pg_proc as p
  join pg_namespace as n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'get_platform_admin_user_audit'
    and pg_get_function_identity_arguments(p.oid) = 'target_user_id uuid, limit_count integer';

  if function_definition is null then
    raise exception 'RPC get_platform_admin_user_audit(uuid, integer) nao encontrada.';
  end if;

  if position('fn.target_user_id' in function_definition) = 0 then
    raise exception 'Parametro target_user_id ainda nao esta qualificado pelo bloco fn.';
  end if;

  if position('fn.limit_count' in function_definition) = 0 then
    raise exception 'Parametro limit_count ainda nao esta qualificado pelo bloco fn.';
  end if;

  if position('access_audit.target_user_id = fn.target_user_id' in function_definition) = 0 then
    raise exception 'Comparacao qualificada da auditoria organizacional nao localizada.';
  end if;

  raise notice 'OK - RPC de auditoria corrigida e estruturalmente validada.';
end;
$verification$;

select
  p.oid::regprocedure::text as assinatura,
  p.prosecdef as security_definer,
  p.provolatile as volatilidade,
  pg_get_function_identity_arguments(p.oid) as argumentos,
  obj_description(p.oid, 'pg_proc') as comentario
from pg_proc as p
join pg_namespace as n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname = 'get_platform_admin_user_audit'
order by p.oid;