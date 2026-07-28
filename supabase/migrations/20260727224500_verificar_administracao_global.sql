-- Verificação somente de leitura da Administração Global

select
  session_user as sessao_sql,
  auth.uid() as usuario_autenticado,
  auth.role() as papel_jwt;

select
  to_regclass('public.platform_user_invitations') as tabela_convites,
  to_regprocedure('public.require_platform_super_admin()') as funcao_autorizacao,
  to_regprocedure('public.get_platform_admin_summary()') as funcao_resumo,
  to_regprocedure('public.get_platform_admin_organizations()') as funcao_organizacoes,
  to_regprocedure('public.get_platform_admin_users()') as funcao_usuarios,
  to_regprocedure('public.get_platform_admin_memberships(uuid,uuid)') as funcao_vinculos,
  to_regprocedure('public.get_platform_admin_modules()') as funcao_modulos,
  to_regprocedure('public.get_platform_admin_platform_roles()') as funcao_perfis_globais;

select * from public.get_platform_admin_summary();
