-- ============================================================
-- Plataforma SPARKs / SK-PE
-- FE-09.A.01-C1 — Localização pt-BR, catálogo de mensagens,
-- capacidades efetivas e proteção de navegação
-- ============================================================

begin;

-- A estrutura sparks_domains já é o catálogo canônico para códigos e rótulos.
-- Esta migration a reutiliza para situações e cria somente o complemento
-- necessário para traduções futuras e mensagens parametrizadas.

do $$
begin
  if to_regclass('public.sparks_domains') is null
     or to_regclass('public.sparks_domain_values') is null then
    raise exception 'A fundação de domínios da Plataforma SPARKs não foi localizada.';
  end if;
end;
$$;

create table if not exists public.sparks_domain_value_translations (
  id uuid primary key default gen_random_uuid(),
  domain_value_id uuid not null references public.sparks_domain_values(id) on delete cascade,
  locale_code text not null default 'pt-BR',
  name text not null,
  description text,
  active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint sparks_domain_value_translations_locale_not_blank check (length(trim(locale_code)) > 0),
  constraint sparks_domain_value_translations_name_not_blank check (length(trim(name)) > 0),
  constraint sparks_domain_value_translations_unique unique (domain_value_id, locale_code)
);

drop trigger if exists sparks_domain_value_translations_set_updated_at on public.sparks_domain_value_translations;
create trigger sparks_domain_value_translations_set_updated_at
before update on public.sparks_domain_value_translations
for each row execute function public.set_updated_at();

create table if not exists public.sparks_message_catalog (
  id uuid primary key default gen_random_uuid(),
  message_code text not null,
  locale_code text not null default 'pt-BR',
  title text,
  message_template text not null,
  severity text not null default 'info',
  audience text not null default 'user',
  action_label text,
  active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint sparks_message_catalog_code_not_blank check (length(trim(message_code)) > 0),
  constraint sparks_message_catalog_locale_not_blank check (length(trim(locale_code)) > 0),
  constraint sparks_message_catalog_template_not_blank check (length(trim(message_template)) > 0),
  constraint sparks_message_catalog_severity_check check (severity in ('info','success','warning','error','critical')),
  constraint sparks_message_catalog_audience_check check (audience in ('user','administrator','technical','all')),
  constraint sparks_message_catalog_unique unique (message_code, locale_code)
);

drop trigger if exists sparks_message_catalog_set_updated_at on public.sparks_message_catalog;
create trigger sparks_message_catalog_set_updated_at
before update on public.sparks_message_catalog
for each row execute function public.set_updated_at();

insert into public.sparks_domains (
  code, name, description, scope_type, module_code,
  allow_organization_extension, protected, active
)
values
  ('GENERIC_STATUS', 'Situações gerais', 'Situações transversais utilizadas nos cadastros e fluxos da plataforma.', 'global', null, false, true, true),
  ('MEMBERSHIP_STATUS', 'Situações de vínculo', 'Situações do vínculo entre usuário e organização.', 'global', null, false, true, true),
  ('JOURNEY_STATUS', 'Situações da jornada estratégica', 'Situações dos itens da jornada estratégica.', 'module', 'SK-PE', false, true, true),
  ('ARTIFACT_STATUS', 'Situações de artefatos', 'Situações de artefatos metodológicos e suas entregas.', 'module', 'SK-PE', false, true, true),
  ('READINESS_STATUS', 'Situações de prontidão', 'Situações de atendimento dos requisitos metodológicos.', 'module', 'SK-PE', false, true, true),
  ('PORTABILITY_STATUS', 'Situações de portabilidade', 'Situações de pacotes de importação, exportação e portabilidade.', 'module', 'SK-PE', false, true, true),
  ('AUDIT_EVENT_TYPE', 'Tipos de evento de auditoria', 'Eventos apresentados nas trilhas de auditoria.', 'global', null, false, true, true),
  ('MESSAGE_SEVERITY', 'Severidades de mensagem', 'Classificação das mensagens exibidas pela plataforma.', 'global', null, false, true, true)
on conflict do nothing;

update public.sparks_domains domain
set name = source.name,
    description = source.description,
    active = true,
    updated_at = timezone('utc', now())
from (values
  ('GENERIC_STATUS', 'Situações gerais', 'Situações transversais utilizadas nos cadastros e fluxos da plataforma.'),
  ('MEMBERSHIP_STATUS', 'Situações de vínculo', 'Situações do vínculo entre usuário e organização.'),
  ('JOURNEY_STATUS', 'Situações da jornada estratégica', 'Situações dos itens da jornada estratégica.'),
  ('ARTIFACT_STATUS', 'Situações de artefatos', 'Situações de artefatos metodológicos e suas entregas.'),
  ('READINESS_STATUS', 'Situações de prontidão', 'Situações de atendimento dos requisitos metodológicos.'),
  ('PORTABILITY_STATUS', 'Situações de portabilidade', 'Situações de pacotes de importação, exportação e portabilidade.'),
  ('AUDIT_EVENT_TYPE', 'Tipos de evento de auditoria', 'Eventos apresentados nas trilhas de auditoria.'),
  ('MESSAGE_SEVERITY', 'Severidades de mensagem', 'Classificação das mensagens exibidas pela plataforma.'),
  ('APPROVAL_STATUS', 'Situações de aprovação', 'Estados do fluxo de aprovação de objetos estratégicos.'),
  ('VALIDATION_STATUS', 'Situações de validação', 'Estados do fluxo de validação de conteúdos e entregáveis.')
) as source(code, name, description)
where domain.code = source.code;

with source(domain_code, value_code, name, description, display_order, color_token) as (
  values
    ('GENERIC_STATUS','draft','Rascunho','Registro em elaboração.',10,'neutral'),
    ('GENERIC_STATUS','planned','Planejado','Execução prevista, ainda não iniciada.',20,'neutral'),
    ('GENERIC_STATUS','active','Ativo','Registro ativo e disponível para uso.',30,'success'),
    ('GENERIC_STATUS','inactive','Inativo','Registro temporariamente indisponível.',40,'neutral'),
    ('GENERIC_STATUS','in_progress','Em andamento','Execução iniciada e ainda não concluída.',50,'info'),
    ('GENERIC_STATUS','pending','Pendente','Aguardando ação ou tratamento.',60,'warning'),
    ('GENERIC_STATUS','under_review','Em análise','Em processo de análise ou revisão.',70,'info'),
    ('GENERIC_STATUS','approved','Aprovado','Aprovação formal registrada.',80,'success'),
    ('GENERIC_STATUS','validated','Validado','Validação formal registrada.',90,'success'),
    ('GENERIC_STATUS','rejected','Rejeitado','Registro rejeitado no fluxo aplicável.',100,'danger'),
    ('GENERIC_STATUS','blocked','Bloqueado','Execução impedida por regra, dependência ou gate.',110,'danger'),
    ('GENERIC_STATUS','suspended','Suspenso','Execução temporariamente suspensa.',120,'warning'),
    ('GENERIC_STATUS','completed','Concluído','Execução concluída.',130,'success'),
    ('GENERIC_STATUS','cancelled','Cancelado','Execução cancelada.',140,'neutral'),
    ('GENERIC_STATUS','archived','Arquivado','Registro preservado somente para consulta histórica.',150,'neutral'),
    ('GENERIC_STATUS','revoked','Revogado','Concessão ou autorização revogada.',160,'danger'),
    ('GENERIC_STATUS','failed','Falhou','Operação concluída com falha.',170,'danger'),

    ('MEMBERSHIP_STATUS','invited','Convidado','Convite emitido e ainda não aceito.',10,'info'),
    ('MEMBERSHIP_STATUS','active','Ativo','Vínculo ativo com a organização.',20,'success'),
    ('MEMBERSHIP_STATUS','suspended','Suspenso','Vínculo temporariamente suspenso.',30,'warning'),
    ('MEMBERSHIP_STATUS','revoked','Revogado','Vínculo revogado.',40,'danger'),

    ('JOURNEY_STATUS','not_started','Não iniciado','Item ainda não iniciado.',10,'neutral'),
    ('JOURNEY_STATUS','in_progress','Em andamento','Item em execução.',20,'info'),
    ('JOURNEY_STATUS','blocked','Bloqueado','Item bloqueado por dependência, pendência ou gate.',30,'danger'),
    ('JOURNEY_STATUS','pending_validation','Aguardando validação','Item concluído operacionalmente e aguardando validação.',40,'warning'),
    ('JOURNEY_STATUS','completed','Concluído','Item concluído.',50,'success'),
    ('JOURNEY_STATUS','cancelled','Cancelado','Item cancelado.',60,'neutral'),

    ('VALIDATION_STATUS','not_required','Validação não obrigatória','O objeto não exige validação formal.',10,'neutral'),
    ('VALIDATION_STATUS','pending','Validação pendente','Aguardando validação.',20,'warning'),
    ('VALIDATION_STATUS','under_review','Em análise','Validação em análise.',30,'info'),
    ('VALIDATION_STATUS','approved','Aprovado','Validação aprovada.',40,'success'),
    ('VALIDATION_STATUS','approved_with_reservations','Aprovado com ressalvas','Validação aprovada com ressalvas registradas.',50,'warning'),
    ('VALIDATION_STATUS','rejected','Rejeitado','Validação rejeitada.',60,'danger'),
    ('VALIDATION_STATUS','cancelled','Cancelado','Processo de validação cancelado.',70,'neutral'),

    ('ARTIFACT_STATUS','planned','Previsto','Artefato previsto na metodologia.',10,'neutral'),
    ('ARTIFACT_STATUS','in_preparation','Em elaboração','Artefato em elaboração.',20,'info'),
    ('ARTIFACT_STATUS','in_review','Em revisão','Artefato em revisão.',30,'info'),
    ('ARTIFACT_STATUS','submitted','Submetido à validação','Artefato submetido para validação.',40,'warning'),
    ('ARTIFACT_STATUS','validated','Validado','Artefato validado.',50,'success'),
    ('ARTIFACT_STATUS','validated_with_reservations','Validado com ressalvas','Artefato validado com ressalvas.',60,'warning'),
    ('ARTIFACT_STATUS','rejected','Rejeitado','Artefato rejeitado.',70,'danger'),
    ('ARTIFACT_STATUS','superseded','Substituído','Artefato substituído por versão posterior.',80,'neutral'),
    ('ARTIFACT_STATUS','archived','Arquivado','Artefato arquivado.',90,'neutral'),
    ('ARTIFACT_STATUS','waived','Dispensado','Entrega formalmente dispensada.',100,'neutral'),

    ('READINESS_STATUS','pending','Pendente','Requisito ainda não atendido.',10,'danger'),
    ('READINESS_STATUS','partial','Parcial','Requisito parcialmente atendido.',20,'warning'),
    ('READINESS_STATUS','awaiting_validation','Aguardando validação','Entrega produzida e aguardando validação.',30,'info'),
    ('READINESS_STATUS','satisfied','Atendido','Requisito plenamente atendido.',40,'success'),

    ('PORTABILITY_STATUS','draft','Rascunho','Pacote registrado e ainda não preparado.',10,'neutral'),
    ('PORTABILITY_STATUS','preparing','Em preparação','Pacote em preparação.',20,'info'),
    ('PORTABILITY_STATUS','validating','Em validação','Pacote em validação.',30,'info'),
    ('PORTABILITY_STATUS','ready','Pronto','Pacote pronto para processamento ou download.',40,'success'),
    ('PORTABILITY_STATUS','processing','Processando','Pacote em processamento.',50,'info'),
    ('PORTABILITY_STATUS','completed','Concluído','Processamento concluído.',60,'success'),
    ('PORTABILITY_STATUS','completed_with_warnings','Concluído com alertas','Processamento concluído com alertas.',70,'warning'),
    ('PORTABILITY_STATUS','failed','Falhou','Processamento concluído com falha.',80,'danger'),
    ('PORTABILITY_STATUS','cancelled','Cancelado','Processamento cancelado.',90,'neutral'),
    ('PORTABILITY_STATUS','archived','Arquivado','Pacote arquivado.',100,'neutral'),

    ('AUDIT_EVENT_TYPE','configuration_changed','Configuração alterada','Alteração de configuração registrada.',10,'info'),
    ('AUDIT_EVENT_TYPE','module_role_assigned','Perfil do módulo atribuído','Atribuição de perfil modular registrada.',20,'info'),
    ('AUDIT_EVENT_TYPE','module_role_revoked','Perfil do módulo revogado','Revogação de perfil modular registrada.',30,'warning'),
    ('AUDIT_EVENT_TYPE','membership_created','Vínculo criado','Criação de vínculo organizacional registrada.',40,'info'),
    ('AUDIT_EVENT_TYPE','membership_updated','Vínculo atualizado','Alteração de vínculo organizacional registrada.',50,'info'),
    ('AUDIT_EVENT_TYPE','membership_revoked','Vínculo revogado','Revogação de vínculo organizacional registrada.',60,'warning'),
    ('AUDIT_EVENT_TYPE','user_created','Usuário criado','Criação de usuário registrada.',70,'info'),
    ('AUDIT_EVENT_TYPE','user_updated','Usuário atualizado','Alteração de usuário registrada.',80,'info'),
    ('AUDIT_EVENT_TYPE','status_changed','Situação alterada','Alteração de situação registrada.',90,'info'),
    ('AUDIT_EVENT_TYPE','journey_item_status_changed','Situação da jornada alterada','Alteração de item da jornada registrada.',100,'info'),
    ('AUDIT_EVENT_TYPE','delivery_kit_generated','Kit de Entregas gerado','Geração de Kit de Entregas registrada.',110,'success'),
    ('AUDIT_EVENT_TYPE','phase_reopened','Fase reaberta','Reabertura formal de fase registrada.',120,'warning'),

    ('MESSAGE_SEVERITY','info','Informação','Mensagem informativa.',10,'info'),
    ('MESSAGE_SEVERITY','success','Sucesso','Operação concluída com sucesso.',20,'success'),
    ('MESSAGE_SEVERITY','warning','Atenção','Mensagem que requer atenção.',30,'warning'),
    ('MESSAGE_SEVERITY','error','Erro','Operação não concluída.',40,'danger'),
    ('MESSAGE_SEVERITY','critical','Crítico','Falha crítica ou bloqueio relevante.',50,'critical')
)
insert into public.sparks_domain_values (
  domain_id, code, name, description, display_order, color_token, protected, active
)
select domain.id, source.value_code, source.name, source.description,
       source.display_order, source.color_token, true, true
from source
join public.sparks_domains domain on domain.code = source.domain_code
on conflict (domain_id, code) do update
set name = excluded.name,
    description = excluded.description,
    display_order = excluded.display_order,
    color_token = excluded.color_token,
    protected = true,
    active = true,
    updated_at = timezone('utc', now());

insert into public.sparks_domain_value_translations (
  domain_value_id, locale_code, name, description, active
)
select value.id, 'pt-BR', value.name, value.description, true
from public.sparks_domain_values value
join public.sparks_domains domain on domain.id = value.domain_id
where domain.code in (
  'GENERIC_STATUS','MEMBERSHIP_STATUS','JOURNEY_STATUS','VALIDATION_STATUS',
  'APPROVAL_STATUS','ARTIFACT_STATUS','READINESS_STATUS','PORTABILITY_STATUS',
  'AUDIT_EVENT_TYPE','MESSAGE_SEVERITY'
)
on conflict (domain_value_id, locale_code) do update
set name = excluded.name,
    description = excluded.description,
    active = true,
    updated_at = timezone('utc', now());

insert into public.sparks_message_catalog (
  message_code, locale_code, title, message_template, severity, audience, action_label, active
)
values
  ('ACCESS_DENIED_PLATFORM_ADMIN','pt-BR','Acesso restrito','Seu perfil não possui permissão para administrar a Plataforma SPARKs.','warning','user',null,true),
  ('ACCESS_DENIED_ORGANIZATION_ADMIN','pt-BR','Acesso restrito','Seu perfil não possui permissão para administrar esta organização.','warning','user',null,true),
  ('ACCESS_DENIED_SKPE_ADMIN','pt-BR','Acesso restrito','Seu perfil não possui permissão para administrar o SK-PE nesta organização.','warning','user',null,true),
  ('DATA_LOAD_FAILED','pt-BR','Não foi possível carregar os dados','Atualize a tela. Se o problema persistir, consulte a auditoria ou o administrador responsável.','error','user','Atualizar',true),
  ('STATUS_UPDATED','pt-BR','Situação atualizada','A situação foi atualizada com sucesso.','success','user',null,true),
  ('USER_UPDATED','pt-BR','Usuário atualizado','Os dados do usuário foram atualizados com sucesso.','success','user',null,true),
  ('DELIVERY_KIT_GENERATED','pt-BR','Kit de Entregas gerado','O Kit de Entregas foi gerado com índice, manifesto e hashes de integridade.','success','user',null,true),
  ('PHASE_PROTECTED','pt-BR','Fase concluída e protegida','As entregas permanecem disponíveis para consulta, impressão e download. Para alterar, reabra formalmente a fase.','info','user',null,true),
  ('DATABASE_MIGRATION_REQUIRED','pt-BR','Atualização do banco necessária','A funcionalidade depende de uma atualização ainda não aplicada no banco de dados.','warning','administrator',null,true),
  ('UNKNOWN_OPERATION_ERROR','pt-BR','Operação não concluída','Não foi possível concluir a operação. O detalhe técnico foi preservado na auditoria.','error','user',null,true)
on conflict (message_code, locale_code) do update
set title = excluded.title,
    message_template = excluded.message_template,
    severity = excluded.severity,
    audience = excluded.audience,
    action_label = excluded.action_label,
    active = true,
    updated_at = timezone('utc', now());

-- Corrige descrições que tenham sido substituídas por textos em inglês.
update public.platform_roles role
set name = source.name,
    description = source.description,
    updated_at = timezone('utc', now())
from (values
  ('super_admin','SUPER-ADMIN da Plataforma','Administra a infraestrutura global, os cadastros mestres e as configurações da Plataforma SPARKs.'),
  ('platform_admin','Administrador da Plataforma','Administra operações globais delegadas da Plataforma SPARKs.'),
  ('support_admin','Administrador de Suporte','Realiza suporte técnico controlado, temporário e auditado.'),
  ('auditor','Auditor da Plataforma','Consulta trilhas de auditoria e evidências autorizadas.'),
  ('visitor','Visitante','Acesso somente leitura às funcionalidades autorizadas das organizações com vínculo ativo.')
) as source(code, name, description)
where role.code = source.code;

update public.module_roles role
set name = source.name,
    description = source.description,
    updated_at = timezone('utc', now())
from (values
  ('administrator','Administrador','Administra usuários, configurações e conteúdos do módulo.'),
  ('manager','Gestor','Gerencia e acompanha a execução das atividades autorizadas no módulo.'),
  ('editor','Elaborador','Cria e edita conteúdos autorizados.'),
  ('validator','Validador','Verifica qualidade, aderência e suficiência antes da aprovação.'),
  ('approver','Aprovador','Analisa e aprova conteúdos e entregas autorizadas.'),
  ('monitor','Monitor','Acompanha medições, check-ins, prazos e resultados.'),
  ('ratifier','Ratificador','Ratifica decisões e encerramentos formais de governança.'),
  ('viewer','Visualizador','Consulta conteúdos autorizados sem alterar dados.'),
  ('visitor','Visitante','Consulta o módulo em modo somente leitura.')
) as source(code, name, description)
where role.code = source.code
  and role.is_system_role = true;

update public.module_permissions permission
set name = source.name,
    description = source.description,
    updated_at = timezone('utc', now())
from (values
  ('module.view','Acessar o módulo','Permite acessar o módulo.'),
  ('module.manage','Administrar o módulo','Permite administrar o módulo.'),
  ('content.view','Consultar conteúdos','Permite consultar conteúdos autorizados.'),
  ('content.create','Criar conteúdos','Permite criar conteúdos autorizados.'),
  ('content.edit','Editar conteúdos','Permite editar conteúdos autorizados.'),
  ('content.delete','Excluir conteúdos','Permite excluir conteúdos conforme as regras aplicáveis.'),
  ('content.approve','Aprovar conteúdos','Permite aprovar ou rejeitar conteúdos e entregas.'),
  ('reports.view','Consultar relatórios','Permite consultar relatórios, painéis e entregas.'),
  ('reports.export','Exportar relatórios','Permite exportar relatórios, evidências e Kits de Entregas.'),
  ('settings.manage','Administrar configurações','Permite alterar configurações do módulo.'),
  ('users.view','Consultar usuários','Permite consultar usuários vinculados ao módulo.'),
  ('users.manage','Administrar usuários','Permite conceder, alterar e revogar acessos.'),
  ('journey.view','Consultar jornada estratégica','Permite consultar os itens da jornada estratégica.'),
  ('journey.manage','Gerenciar jornada estratégica','Permite atualizar e administrar a jornada estratégica.'),
  ('initiatives.view','Consultar iniciativas','Permite consultar iniciativas, programas, projetos e planos de ação.'),
  ('initiatives.manage','Gerenciar iniciativas','Permite criar, alterar, priorizar e acompanhar iniciativas.'),
  ('governance_roles.view','Consultar papéis e responsabilidades','Permite consultar papéis e responsabilidades organizacionais e estratégicas.'),
  ('governance_roles.manage','Gerenciar papéis e responsabilidades','Permite criar, atribuir, delegar e encerrar responsabilidades.'),
  ('domains.view','Consultar tabelas de domínio','Permite consultar domínios e valores padronizados.'),
  ('domains.manage','Gerenciar extensões de domínio','Permite gerenciar valores de domínio personalizáveis pela organização.')
) as source(code, name, description)
where permission.code = source.code;

create or replace function public.get_sparks_ui_catalog(
  target_locale text default 'pt-BR'
)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'locale', coalesce(nullif(trim(target_locale), ''), 'pt-BR'),
    'domains', coalesce((
      select jsonb_object_agg(grouped.domain_code, grouped.values_json)
      from (
        select
          domain.code as domain_code,
          jsonb_object_agg(
            value.code,
            jsonb_build_object(
              'name', coalesce(translation.name, value.name),
              'description', coalesce(translation.description, value.description),
              'color_token', value.color_token,
              'icon_name', value.icon_name
            ) order by value.display_order, value.code
          ) as values_json
        from public.sparks_domains domain
        join public.sparks_domain_values value on value.domain_id = domain.id and value.active = true
        left join public.sparks_domain_value_translations translation
          on translation.domain_value_id = value.id
         and translation.locale_code = coalesce(nullif(trim(target_locale), ''), 'pt-BR')
         and translation.active = true
        where domain.active = true
        group by domain.code
      ) grouped
    ), '{}'::jsonb),
    'messages', coalesce((
      select jsonb_object_agg(
        message.message_code,
        jsonb_build_object(
          'title', message.title,
          'message', message.message_template,
          'severity', message.severity,
          'audience', message.audience,
          'action_label', message.action_label
        )
      )
      from public.sparks_message_catalog message
      where message.locale_code = coalesce(nullif(trim(target_locale), ''), 'pt-BR')
        and message.active = true
    ), '{}'::jsonb)
  );
$$;

create or replace function public.get_skpe_effective_capabilities(
  target_organization_id uuid
)
returns table (
  can_view_overview boolean,
  can_view_journey boolean,
  can_view_initiatives boolean,
  can_view_artifacts boolean,
  can_generate_delivery_kit boolean,
  can_view_governance boolean,
  can_manage_journey boolean,
  can_manage_artifacts boolean,
  can_manage_skpe boolean,
  can_administer_users boolean,
  can_administer_memberships boolean,
  can_administer_settings boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  with access as (
    select
      public.is_platform_super_admin() as super_admin,
      public.is_organization_admin(target_organization_id) as organization_admin,
      public.has_module_permission(target_organization_id, 'SK-PE', 'module.view') as module_view,
      public.has_module_permission(target_organization_id, 'SK-PE', 'module.manage') as module_manage,
      public.has_module_permission(target_organization_id, 'SK-PE', 'content.view') as content_view,
      public.has_module_permission(target_organization_id, 'SK-PE', 'content.edit') as content_edit,
      public.has_module_permission(target_organization_id, 'SK-PE', 'journey.view') as journey_view,
      public.has_module_permission(target_organization_id, 'SK-PE', 'journey.manage') as journey_manage,
      public.has_module_permission(target_organization_id, 'SK-PE', 'initiatives.view') as initiatives_view,
      public.has_module_permission(target_organization_id, 'SK-PE', 'initiatives.manage') as initiatives_manage,
      public.has_module_permission(target_organization_id, 'SK-PE', 'reports.view') as reports_view,
      public.has_module_permission(target_organization_id, 'SK-PE', 'reports.export') as reports_export,
      public.has_module_permission(target_organization_id, 'SK-PE', 'evidence_checklist.view') as evidence_view,
      public.has_module_permission(target_organization_id, 'SK-PE', 'evidence_checklist.manage') as evidence_manage,
      public.has_module_permission(target_organization_id, 'SK-PE', 'governance_roles.view') as governance_view,
      public.has_module_permission(target_organization_id, 'SK-PE', 'governance_roles.manage') as governance_manage,
      public.has_module_permission(target_organization_id, 'SK-PE', 'strategic_monitoring.view') as monitoring_view,
      public.has_module_permission(target_organization_id, 'SK-PE', 'strategic_governance.manage') as strategic_governance_manage,
      public.has_module_permission(target_organization_id, 'SK-PE', 'users.manage') as users_manage,
      public.has_module_permission(target_organization_id, 'SK-PE', 'settings.manage') as settings_manage
  )
  select
    super_admin or organization_admin or module_view or content_view,
    super_admin or organization_admin or journey_view or journey_manage,
    super_admin or organization_admin or initiatives_view or initiatives_manage,
    super_admin or organization_admin or reports_view or evidence_view or content_view,
    super_admin or organization_admin or reports_export or reports_view or evidence_view,
    super_admin or organization_admin or governance_view or governance_manage or monitoring_view or strategic_governance_manage,
    super_admin or organization_admin or journey_manage,
    super_admin or organization_admin or content_edit or evidence_manage or module_manage,
    super_admin or organization_admin or module_manage,
    super_admin or organization_admin or users_manage,
    super_admin or organization_admin,
    super_admin or organization_admin or settings_manage
  from access;
$$;

create or replace function public.get_organization_user_access(target_organization_id uuid)
returns table (
  membership_id uuid,
  user_id uuid,
  user_email text,
  user_display_name text,
  user_active boolean,
  membership_status text,
  is_organization_admin boolean,
  job_title text,
  membership_valid_from timestamptz,
  membership_valid_until timestamptz,
  organization_module_id uuid,
  module_id uuid,
  module_code text,
  module_name text,
  module_short_name text,
  user_module_role_id uuid,
  module_role_id uuid,
  role_code text,
  role_name text,
  module_role_status text,
  module_role_valid_from timestamptz,
  module_role_valid_until timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.can_manage_module_users(target_organization_id, 'SK-PE') then
    raise exception 'Acesso negado: o usuário não pode administrar os acessos do SK-PE nesta organização.' using errcode='42501';
  end if;

  return query
  select
    membership.id,
    profile.id,
    profile.email,
    coalesce(profile.display_name, profile.full_name, profile.email),
    profile.active,
    membership.status::text,
    membership.is_organization_admin,
    membership.job_title,
    membership.valid_from,
    membership.valid_until,
    organization_module.id,
    platform_module.id,
    platform_module.code,
    platform_module.name,
    platform_module.short_name,
    user_module_role.id,
    module_role.id,
    module_role.code,
    module_role.name,
    user_module_role.status::text,
    user_module_role.valid_from,
    user_module_role.valid_until
  from public.organization_memberships membership
  join public.profiles profile on profile.id = membership.user_id
  left join public.organization_modules organization_module
    on organization_module.organization_id = membership.organization_id
  left join public.user_module_roles user_module_role
    on user_module_role.organization_module_id = organization_module.id
   and user_module_role.user_id = membership.user_id
  left join public.modules platform_module
    on platform_module.id = organization_module.module_id
  left join public.module_roles module_role
    on module_role.id = user_module_role.module_role_id
   and module_role.module_id = platform_module.id
  where membership.organization_id = target_organization_id
  order by membership.is_organization_admin desc,
           coalesce(profile.display_name, profile.full_name, profile.email),
           platform_module.name,
           module_role.name;
end;
$$;

comment on function public.get_organization_user_access(uuid) is
  'Retorna usuários, vínculos e perfis modulares para administradores organizacionais ou usuários com users.manage no SK-PE.';

create or replace function public.can_view_skpe_journey(
  target_organization_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    public.is_platform_super_admin()
    or public.is_organization_admin(target_organization_id)
    or public.has_module_permission(target_organization_id, 'SK-PE', 'journey.view')
    or public.has_module_permission(target_organization_id, 'SK-PE', 'journey.manage');
$$;

alter table public.sparks_domain_value_translations enable row level security;
alter table public.sparks_message_catalog enable row level security;

drop policy if exists sparks_domain_value_translations_select_active on public.sparks_domain_value_translations;
create policy sparks_domain_value_translations_select_active
on public.sparks_domain_value_translations
for select to authenticated
using (active = true);

drop policy if exists sparks_message_catalog_select_active on public.sparks_message_catalog;
create policy sparks_message_catalog_select_active
on public.sparks_message_catalog
for select to authenticated
using (active = true);

revoke all on table public.sparks_domain_value_translations from anon, authenticated;
revoke all on table public.sparks_message_catalog from anon, authenticated;
grant select on table public.sparks_domain_value_translations to authenticated, service_role;
grant select on table public.sparks_message_catalog to authenticated, service_role;

revoke all on function public.get_organization_user_access(uuid) from public, anon;
grant execute on function public.get_organization_user_access(uuid) to authenticated, service_role;

revoke all on function public.get_sparks_ui_catalog(text) from public, anon;
revoke all on function public.get_skpe_effective_capabilities(uuid) from public, anon;
revoke all on function public.can_view_skpe_journey(uuid) from public, anon;
grant execute on function public.get_sparks_ui_catalog(text) to authenticated, service_role;
grant execute on function public.get_skpe_effective_capabilities(uuid) to authenticated, service_role;
grant execute on function public.can_view_skpe_journey(uuid) to authenticated, service_role;

commit;
