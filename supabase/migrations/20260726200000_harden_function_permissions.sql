-- ============================================================
-- SK-PE SaaS
-- Migration: Endurecimento de Permissões de Funções
-- ============================================================

revoke all on function public.current_user_id() from public,anon;
revoke all on function public.is_active_member(uuid) from public,anon;
revoke all on function public.is_organization_admin(uuid) from public,anon;
revoke all on function public.can_read_organization(uuid) from public,anon;
revoke all on function public.can_manage_organization(uuid) from public,anon;
revoke all on function public.get_my_organizations() from public,anon;
revoke all on function public.has_module_access(uuid,text) from public,anon;
revoke all on function public.has_module_permission(uuid,text,text) from public,anon;
revoke all on function public.get_my_modules(uuid) from public,anon;
revoke all on function public.has_platform_role(text) from public,anon;
revoke all on function public.is_platform_super_admin() from public,anon;
revoke all on function public.get_my_platform_roles() from public,anon;
revoke all on function public.has_active_privileged_access(uuid) from public,anon;
revoke all on function public.get_organization_user_access(uuid) from public,anon;

grant execute on function public.current_user_id() to authenticated,service_role;
grant execute on function public.is_active_member(uuid) to authenticated,service_role;
grant execute on function public.is_organization_admin(uuid) to authenticated,service_role;
grant execute on function public.can_read_organization(uuid) to authenticated,service_role;
grant execute on function public.can_manage_organization(uuid) to authenticated,service_role;
grant execute on function public.get_my_organizations() to authenticated,service_role;
grant execute on function public.has_module_access(uuid,text) to authenticated,service_role;
grant execute on function public.has_module_permission(uuid,text,text) to authenticated,service_role;
grant execute on function public.get_my_modules(uuid) to authenticated,service_role;
grant execute on function public.has_platform_role(text) to authenticated,service_role;
grant execute on function public.is_platform_super_admin() to authenticated,service_role;
grant execute on function public.get_my_platform_roles() to authenticated,service_role;
grant execute on function public.has_active_privileged_access(uuid) to authenticated,service_role;
grant execute on function public.get_organization_user_access(uuid) to authenticated,service_role;

revoke all on function public.set_updated_at() from public,anon,authenticated;
revoke all on function public.handle_new_user() from public,anon,authenticated;
revoke all on function public.validate_user_module_role() from public,anon,authenticated;
grant execute on function public.set_updated_at() to postgres,service_role;
grant execute on function public.handle_new_user() to postgres,service_role;
grant execute on function public.validate_user_module_role() to postgres,service_role;

revoke all on table public.modules, public.organization_modules, public.module_roles,
  public.module_permissions, public.role_permissions, public.user_module_roles,
  public.platform_roles, public.user_platform_roles,
  public.privileged_access_sessions, public.privileged_access_audit from anon;
