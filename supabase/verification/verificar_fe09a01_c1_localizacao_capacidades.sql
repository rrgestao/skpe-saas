-- Verificação FE-09.A.01-C1 — somente leitura.
select to_regclass('public.sparks_domain_value_translations') is not null as tabela_traducoes_criada,
       to_regclass('public.sparks_message_catalog') is not null as catalogo_mensagens_criado,
       to_regprocedure('public.get_sparks_ui_catalog(text)') is not null as rpc_catalogo_criada,
       to_regprocedure('public.get_skpe_effective_capabilities(uuid)') is not null as rpc_capacidades_criada,
       to_regprocedure('public.get_organization_user_access(uuid)') is not null as rpc_usuarios_skpe_alinhada;

select domain.code, count(*) as valores_ativos
from public.sparks_domains domain
join public.sparks_domain_values value on value.domain_id = domain.id and value.active
where domain.code in ('GENERIC_STATUS','MEMBERSHIP_STATUS','JOURNEY_STATUS','VALIDATION_STATUS','ARTIFACT_STATUS','READINESS_STATUS','PORTABILITY_STATUS','AUDIT_EVENT_TYPE','MESSAGE_SEVERITY')
group by domain.code
order by domain.code;

select code, name, description
from public.platform_roles
where code in ('super_admin','platform_admin','support_admin','auditor','visitor')
order by role_level desc;

select module.code as module_code, role.code as role_code, role.name, role.description
from public.module_roles role
join public.modules module on module.id = role.module_id
where role.is_system_role
  and role.code in ('administrator','manager','editor','validator','approver','monitor','ratifier','viewer','visitor')
order by module.code, role.role_level desc;

select count(*) as descricoes_suspeitas_em_ingles
from (
  select name, description from public.platform_roles
  union all
  select name, description from public.module_roles where is_system_role
  union all
  select name, description from public.module_permissions
) catalog
where coalesce(name,'') ~* '\m(system role|viewer|manager|administrator)\M'
   or coalesce(description,'') ~* '\m(unrestricted|read only|permission|manage users|system role)\M';

select public.get_sparks_ui_catalog('pt-BR') -> 'messages' -> 'PHASE_PROTECTED' as mensagem_fase_protegida;

select capabilities.*
from public.organizations organization
cross join lateral public.get_skpe_effective_capabilities(organization.id) capabilities
where organization.code = 'COOTAQUARA';
