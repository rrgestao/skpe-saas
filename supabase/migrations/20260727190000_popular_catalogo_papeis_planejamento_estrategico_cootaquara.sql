-- ============================================================
-- Plataforma SPARKs / Planejamento Estratégico
-- Catálogo inicial de papéis do Planejamento Estratégico
-- Organização: COOTAQUARA
-- Data: 2026-07-27
--
-- Características:
--   * idempotente: pode ser executado novamente sem duplicar papéis;
--   * não cria pessoas nem designações;
--   * não atribui cargos estatutários a usuários;
--   * registra os papéis como catálogo proposto para validação;
--   * preserva códigos técnicos sem acentos.
-- ============================================================

begin;

do $$
declare
  v_organization_id uuid;
  v_organization_count integer;
begin
  select count(*), min(id)
    into v_organization_count, v_organization_id
  from public.organizations
  where upper(coalesce(code, '')) = 'COOTAQUARA'
     or upper(coalesce(trade_name, '')) = 'COOTAQUARA'
     or upper(coalesce(legal_name, '')) like '%COOTAQUARA%';

  if v_organization_count = 0 then
    raise exception 'Organização COOTAQUARA não encontrada.';
  end if;

  if v_organization_count > 1 then
    raise exception 'Mais de uma organização correspondente à COOTAQUARA foi encontrada. Revise o cadastro antes de executar.';
  end if;

  create temporary table tmp_skpe_roles_seed (
    code text primary key,
    name text not null,
    role_type text not null,
    description text,
    organizational_area text,
    authority_level text,
    is_governance_role boolean not null,
    requires_mandate boolean not null,
    responsibilities_summary text,
    reports_to_code text,
    display_order integer not null
  ) on commit drop;

  insert into tmp_skpe_roles_seed (
    code, name, role_type, description, organizational_area,
    authority_level, is_governance_role, requires_mandate,
    responsibilities_summary, reports_to_code, display_order
  ) values
    ('PAT-EST', 'Patrocinador da Estratégia', 'governance',
      'Representa a liderança institucional que assegura legitimidade, prioridade e apoio à jornada estratégica.',
      'Governança e Direção', 'governance', true, false,
      'Patrocinar o processo; remover impedimentos; assegurar recursos; apoiar decisões críticas; cobrar resultados.',
      null, 10),

    ('COM-EST', 'Comitê de Direção Estratégica', 'committee',
      'Instância colegiada de orientação, análise e acompanhamento da estratégia.',
      'Governança e Direção', 'governance', true, false,
      'Analisar propostas; priorizar escolhas; acompanhar resultados; deliberar sobre mudanças relevantes; tratar desvios estratégicos.',
      'PAT-EST', 20),

    ('APR-EST', 'Aprovador da Estratégia', 'governance',
      'Papel autorizado a aprovar formalmente os principais produtos e decisões estratégicas.',
      'Governança e Direção', 'governance', true, false,
      'Aprovar direcionadores, objetivos, indicadores, metas, iniciativas e revisões relevantes.',
      'PAT-EST', 30),

    ('GEST-EST', 'Gestor do Planejamento Estratégico', 'function',
      'Responsável pela coordenação permanente do sistema de gestão estratégica.',
      'Planejamento Estratégico', 'executive', false, false,
      'Organizar o ciclo estratégico; coordenar reuniões; integrar responsáveis; acompanhar indicadores, metas e iniciativas; reportar resultados.',
      'PAT-EST', 40),

    ('COORD-PE', 'Coordenador do Projeto de Planejamento Estratégico', 'project',
      'Coordena a execução metodológica e operacional do projeto de formulação estratégica.',
      'Planejamento Estratégico', 'tactical', false, false,
      'Planejar atividades; controlar cronograma; coordenar oficinas; consolidar entregas; controlar pendências e validações.',
      'GEST-EST', 50),

    ('PFOC-PE', 'Ponto Focal do Planejamento Estratégico', 'project',
      'Principal interlocutor operacional entre a organização, a consultoria e os participantes.',
      'Planejamento Estratégico', 'operational', false, false,
      'Articular agendas; solicitar informações; acompanhar pendências; distribuir comunicações; apoiar validações.',
      'COORD-PE', 60),

    ('FAC-PE', 'Facilitador do Planejamento Estratégico', 'function',
      'Conduz reuniões, oficinas e dinâmicas de construção e validação estratégica.',
      'Planejamento Estratégico', 'tactical', false, false,
      'Preparar e facilitar encontros; estimular participação; organizar contribuições; apoiar consensos e decisões.',
      'COORD-PE', 70),

    ('CONS-PE', 'Consultor do Planejamento Estratégico', 'temporary',
      'Especialista externo ou interno que aplica metodologia e presta orientação técnica.',
      'Planejamento Estratégico', 'tactical', false, false,
      'Realizar análises; propor métodos; facilitar formulações; produzir artefatos; orientar decisões sem substituir a governança.',
      'GEST-EST', 80),

    ('ANAL-EST', 'Analista de Gestão Estratégica', 'function',
      'Apoia tecnicamente a consolidação, análise e monitoramento dos dados estratégicos.',
      'Planejamento Estratégico', 'operational', false, false,
      'Atualizar informações; analisar desempenho; produzir relatórios; apoiar indicadores, metas, riscos e planos de ação.',
      'GEST-EST', 90),

    ('SEC-EST', 'Secretário da Governança Estratégica', 'function',
      'Apoia formalmente as reuniões e os registros do processo decisório estratégico.',
      'Planejamento Estratégico', 'operational', false, false,
      'Preparar pautas; registrar atas; controlar deliberações; acompanhar encaminhamentos; organizar documentos.',
      'GEST-EST', 100),

    ('RESP-OE', 'Responsável por Objetivo Estratégico', 'function',
      'Responde pela evolução e pelos resultados de determinado objetivo estratégico.',
      'Planejamento Estratégico', 'tactical', false, false,
      'Coordenar indicadores, metas e iniciativas vinculadas; analisar desempenho; propor correções; reportar resultados.',
      'GEST-EST', 110),

    ('RESP-IND', 'Responsável por Indicador Estratégico', 'function',
      'Mantém a definição, a medição e a confiabilidade de determinado indicador.',
      'Planejamento Estratégico', 'operational', false, false,
      'Coletar dados; calcular indicador; validar fonte; explicar variações; manter periodicidade e evidências.',
      'RESP-OE', 120),

    ('RESP-META', 'Responsável por Meta Estratégica', 'function',
      'Responde pelo acompanhamento e alcance de uma meta vinculada a objetivo ou indicador.',
      'Planejamento Estratégico', 'operational', false, false,
      'Acompanhar resultado; analisar desvios; articular ações corretivas; atualizar projeções; prestar contas.',
      'RESP-OE', 130),

    ('PAT-INI', 'Patrocinador de Iniciativa Estratégica', 'governance',
      'Liderança que dá suporte institucional a uma iniciativa estratégica.',
      'Governança e Direção', 'executive', true, false,
      'Validar escopo; assegurar recursos; remover impedimentos; aprovar decisões críticas; acompanhar benefícios.',
      'PAT-EST', 140),

    ('GEST-INI', 'Gestor de Iniciativa Estratégica', 'project',
      'Coordena a execução integral de uma iniciativa ou projeto estratégico.',
      'Projetos Estratégicos', 'tactical', false, false,
      'Planejar escopo, prazo, custos e entregas; coordenar responsáveis; controlar riscos; reportar progresso.',
      'PAT-INI', 150),

    ('RESP-ENT', 'Responsável por Entrega Estratégica', 'project',
      'Responde pela produção e conclusão de uma entrega específica da iniciativa.',
      'Projetos Estratégicos', 'operational', false, false,
      'Organizar atividades; cumprir critérios de aceite; registrar evidências; comunicar conclusão e impedimentos.',
      'GEST-INI', 160),

    ('RESP-ACAO', 'Responsável por Ação Estratégica', 'project',
      'Executa ou coordena uma ação específica do plano estratégico.',
      'Projetos Estratégicos', 'operational', false, false,
      'Realizar a ação; atualizar progresso; registrar evidências; informar problemas e resultados.',
      'GEST-INI', 170),

    ('APROV-ENT', 'Aprovador de Entrega Estratégica', 'project',
      'Verifica e aceita formalmente uma entrega estratégica.',
      'Projetos Estratégicos', 'tactical', false, false,
      'Avaliar critérios de aceite; solicitar correções; aprovar ou rejeitar entrega; registrar decisão.',
      'PAT-INI', 180),

    ('MON-EST', 'Responsável pelo Monitoramento Estratégico', 'function',
      'Coordena a rotina de acompanhamento consolidado do desempenho estratégico.',
      'Planejamento Estratégico', 'tactical', false, false,
      'Consolidar resultados; preparar painéis; organizar reuniões de análise; registrar decisões; acompanhar ações corretivas.',
      'GEST-EST', 190),

    ('VAL-RES', 'Validador de Resultados Estratégicos', 'governance',
      'Confirma a consistência, a relevância e a aceitabilidade dos resultados reportados.',
      'Governança e Direção', 'governance', true, false,
      'Avaliar resultados; verificar evidências; validar conclusões; registrar ressalvas e aprovações.',
      'COM-EST', 200),

    ('RESP-DOC', 'Responsável pela Documentação Estratégica', 'process',
      'Organiza e controla os documentos produzidos durante a jornada estratégica.',
      'Gestão Documental', 'operational', false, false,
      'Classificar documentos; controlar versões; manter repositório; garantir rastreabilidade e acesso.',
      'GEST-EST', 210),

    ('RESP-EVID', 'Responsável pela Gestão de Evidências', 'process',
      'Mantém evidências que sustentam diagnósticos, decisões, entregas e resultados.',
      'Gestão Documental', 'operational', false, false,
      'Registrar evidências; relacioná-las aos objetos estratégicos; avaliar suficiência; controlar atualização.',
      'RESP-DOC', 220),

    ('RESP-COM', 'Responsável pela Comunicação da Estratégia', 'process',
      'Planeja e executa a comunicação do direcionamento e dos resultados estratégicos.',
      'Comunicação', 'tactical', false, false,
      'Elaborar plano de comunicação; adequar mensagens aos públicos; divulgar avanços; apoiar engajamento.',
      'GEST-EST', 230),

    ('RESP-RISC', 'Responsável por Riscos Estratégicos', 'process',
      'Coordena a identificação, avaliação e tratamento dos riscos estratégicos.',
      'Riscos e Controles', 'tactical', false, false,
      'Manter matriz de riscos; acompanhar respostas; alertar exposições críticas; reportar mudanças.',
      'COM-EST', 240),

    ('RESP-ORC', 'Responsável pelo Orçamento Estratégico', 'process',
      'Integra recursos financeiros, investimentos e custos às prioridades estratégicas.',
      'Administrativo-Financeiro', 'tactical', false, false,
      'Estimar recursos; acompanhar orçamento; avaliar desvios; apoiar priorizações e decisões financeiras.',
      'PAT-EST', 250),

    ('RESP-DAD', 'Responsável por Dados e Informações Estratégicas', 'process',
      'Assegura disponibilidade, qualidade e rastreabilidade dos dados usados na estratégia.',
      'Dados e Informações', 'operational', false, false,
      'Administrar fontes; validar dados; tratar inconsistências; apoiar integrações e relatórios.',
      'GEST-EST', 260),

    ('AUD-EST', 'Auditor ou Verificador da Gestão Estratégica', 'governance',
      'Realiza avaliação independente ou controlada sobre a execução e os registros estratégicos.',
      'Riscos e Controles', 'governance', true, false,
      'Verificar conformidade; testar evidências; identificar lacunas; emitir recomendações; acompanhar correções.',
      'COM-EST', 270);

  insert into public.sparks_organizational_roles (
    organization_id,
    code,
    name,
    role_type,
    description,
    organizational_area,
    authority_level,
    is_governance_role,
    requires_mandate,
    responsibilities_summary,
    active,
    metadata
  )
  select
    v_organization_id,
    seed.code,
    seed.name,
    seed.role_type,
    seed.description,
    seed.organizational_area,
    seed.authority_level,
    seed.is_governance_role,
    seed.requires_mandate,
    seed.responsibilities_summary,
    true,
    jsonb_build_object(
      'catalog_source', 'SK-PE',
      'catalog_version', '2026-07-27',
      'catalog_status', 'proposed_for_validation',
      'display_order', seed.display_order,
      'created_via', 'sql_seed'
    )
  from tmp_skpe_roles_seed seed
  on conflict (organization_id, code) do update
  set
    name = excluded.name,
    role_type = excluded.role_type,
    description = excluded.description,
    organizational_area = excluded.organizational_area,
    authority_level = excluded.authority_level,
    is_governance_role = excluded.is_governance_role,
    requires_mandate = excluded.requires_mandate,
    responsibilities_summary = excluded.responsibilities_summary,
    active = true,
    metadata = coalesce(public.sparks_organizational_roles.metadata, '{}'::jsonb) || excluded.metadata,
    updated_at = timezone('utc', now());

  update public.sparks_organizational_roles child
  set
    reports_to_role_id = parent.id,
    updated_at = timezone('utc', now())
  from tmp_skpe_roles_seed seed
  left join public.sparks_organizational_roles parent
    on parent.organization_id = v_organization_id
   and parent.code = seed.reports_to_code
  where child.organization_id = v_organization_id
    and child.code = seed.code
    and child.reports_to_role_id is distinct from parent.id;

  raise notice 'Catálogo inicial criado/atualizado para a organização %, com % papéis.',
    v_organization_id,
    (select count(*) from tmp_skpe_roles_seed);
end;
$$;

commit;

-- ============================================================
-- CONFERÊNCIA FINAL
-- ============================================================
select
  role.code,
  role.name,
  role.role_type,
  role.organizational_area,
  role.authority_level,
  role.is_governance_role,
  role.requires_mandate,
  parent.name as reports_to,
  role.active,
  role.metadata ->> 'catalog_status' as catalog_status
from public.sparks_organizational_roles role
join public.organizations organization
  on organization.id = role.organization_id
left join public.sparks_organizational_roles parent
  on parent.id = role.reports_to_role_id
where (
    upper(coalesce(organization.code, '')) = 'COOTAQUARA'
    or upper(coalesce(organization.trade_name, '')) = 'COOTAQUARA'
    or upper(coalesce(organization.legal_name, '')) like '%COOTAQUARA%'
  )
  and role.metadata ->> 'catalog_source' = 'SK-PE'
order by
  coalesce((role.metadata ->> 'display_order')::integer, 9999),
  role.name;
