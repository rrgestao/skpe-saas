-- FE-09.A.01-C1.8.2-A - verification script
-- Run in Supabase SQL Editor after applying the migration.

select
  to_regprocedure('public.get_organization_scope_explorer(uuid,text,text,boolean)') is not null as rpc_exists;

select
  p.prosecdef as security_definer,
  p.provolatile = 's' as stable,
  p.proconfig
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname = 'get_organization_scope_explorer';

select
  has_function_privilege('authenticated', 'public.get_organization_scope_explorer(uuid,text,text,boolean)', 'EXECUTE') as authenticated_can_execute,
  has_function_privilege('anon', 'public.get_organization_scope_explorer(uuid,text,text,boolean)', 'EXECUTE') as anon_can_execute;

-- Replace the UUID below with an organization accessible to the logged-in user.
-- select public.get_organization_scope_explorer(
--   '<ROOT_ORGANIZATION_UUID>'::uuid,
--   'SK-PE',
--   'users',
--   false
-- );

-- Optional domain checks:
-- select public.get_organization_scope_explorer('<ROOT_ORGANIZATION_UUID>'::uuid, 'SK-PE', 'areas', false);
-- select public.get_organization_scope_explorer('<ROOT_ORGANIZATION_UUID>'::uuid, 'SK-PE', 'roles', false);
-- select public.get_organization_scope_explorer('<ROOT_ORGANIZATION_UUID>'::uuid, 'SK-PE', 'responsibilities', false);