-- ============================================================
-- SPARKs PE - Correção de textos visíveis para Português do Brasil
-- Migration: 20260727021500
-- Objetivo:
--   1. Corrigir nomes, descrições e critérios da PEM-00 no modelo oficial.
--   2. Refletir as mesmas correções nas jornadas de projetos já criadas.
--   3. Preservar códigos, chaves técnicas e identificadores sem acentuação.
-- ============================================================

begin;

-- ------------------------------------------------------------
-- 1. Versão metodológica oficial
-- ------------------------------------------------------------
update public.skpe_methodology_template_versions version
set
  name = 'Metodologia Oficial SPARKs PE — Governança, Estratégia e Execução',
  description = 'Versão oficial da metodologia SPARKs PE com Governança, Gestão de Evidências, Diagnóstico, Formulação, Desdobramento, Implementação, Monitoramento e Aprendizado.'
from public.skpe_methodology_templates template
where template.id = version.template_id
  and template.code = 'SKPE-OFICIAL'
  and version.version_code = 'SK-PE-2026.2';

-- ------------------------------------------------------------
-- 2. Itens da metodologia oficial — PEM-00
-- ------------------------------------------------------------
with corrected_values(code, name, description, completion_criteria) as (
  values
    (
      'PEM-00',
      'Governança, Abertura e Gestão de Evidências',
      'Estabelecer mandato, governança, caracterização, checklist dinâmico, base de evidências e prontidão para o diagnóstico.',
      '["Mandato e escopo validados", "Governança e ritos definidos", "Checklist dinâmico emitido", "Evidências críticas recebidas e classificadas", "Autoavaliações e diagnósticos analisados", "Planos de ação anteriores avaliados", "Gate de prontidão aprovado"]'::jsonb
    ),
    (
      'PEM-00.01',
      'Abertura, Mandato e Escopo',
      'Formalizar contratação, objetivos, limites, premissas, patrocínio e critérios de sucesso.',
      '["Termo de abertura validado", "Mandato e escopo confirmados"]'::jsonb
    ),
    (
      'PEM-00.02',
      'Governança, Papéis e Ritos',
      'Definir patrocinadores, comitês, papéis, responsabilidades, cadências, fóruns e regras de decisão.',
      '["Matriz de governança aprovada", "Ritos e fóruns definidos"]'::jsonb
    ),
    (
      'PEM-00.03',
      'Caracterização da Organização',
      'Registrar natureza, tipo, ramo, porte, estrutura, território, maturidade e demais atributos que orientam o método.',
      '["Perfil organizacional consolidado"]'::jsonb
    ),
    (
      'PEM-00.04',
      'Checklist Dinâmico de Informações',
      'Gerar e validar o checklist conforme contexto, porte, ramo, maturidade, escopo e modelos de referência aplicáveis.',
      '["Checklist dinâmico emitido", "Responsáveis e prazos definidos"]'::jsonb
    ),
    (
      'PEM-00.05',
      'Gestão de Evidências e Integração com o SK-DOC',
      'Solicitar, receber, classificar, validar, proteger e vincular evidências às análises e decisões do projeto.',
      '["Repositório de evidências estruturado", "Evidências críticas validadas"]'::jsonb
    ),
    (
      'PEM-00.06',
      'Autoavaliações e Diagnósticos Assistidos',
      'Importar e estruturar eixos, critérios, resultados, lacunas, recomendações e histórico de instrumentos anteriores.',
      '["Instrumentos anteriores inventariados", "Achados estruturados"]'::jsonb
    ),
    (
      'PEM-00.07',
      'Planos de Ação e Follow-up',
      'Analisar planos existentes, atualização, execução, evidências, atrasos, paralisações, reincidências e efetividade.',
      '["Planos anteriores classificados", "Ações paradas identificadas", "Follow-up definido"]'::jsonb
    ),
    (
      'PEM-00.08',
      'Lacunas, Pendências e Prontidão',
      'Consolidar lacunas de informação, riscos de qualidade, pendências críticas e nível de prontidão para o diagnóstico.',
      '["Lacunas e pendências registradas", "Nível de prontidão calculado"]'::jsonb
    ),
    (
      'PEM-00.GATE',
      'Gate 00 — Prontidão para o Diagnóstico',
      'Autorizar o início da PEM-01 mediante mandato, governança, evidências mínimas, lacunas conhecidas e plano de complementação.',
      '["Mandato validado", "Governança definida", "Checklist emitido", "Evidências mínimas recebidas", "Lacunas registradas", "Plano de complementação aprovado"]'::jsonb
    ),
    (
      'PEM-00.04.01',
      'Gerar Checklist Contextualizado',
      'Combinar regras por tipo, natureza, ramo, porte, maturidade, escopo e modelo de referência.',
      '["Checklist gerado"]'::jsonb
    ),
    (
      'PEM-00.04.ED01',
      'Checklist de Informações e Evidências',
      'Lista controlada de informações, responsáveis, prazos, criticidade e situação de atendimento.',
      '["Checklist aprovado"]'::jsonb
    ),
    (
      'PEM-00.05.01',
      'Solicitar e Receber Evidências',
      'Controlar solicitações, recebimentos, pendências e responsáveis.',
      '["Solicitações controladas"]'::jsonb
    ),
    (
      'PEM-00.05.02',
      'Classificar e Validar Evidências',
      'Avaliar origem, atualidade, completude, confiabilidade, confidencialidade e aderência.',
      '["Evidências classificadas e validadas"]'::jsonb
    ),
    (
      'PEM-00.05.ED01',
      'Base de Evidências do Projeto',
      'Repositório rastreável das evidências aceitas, rejeitadas, ausentes e desatualizadas.',
      '["Base de evidências disponível"]'::jsonb
    ),
    (
      'PEM-00.06.01',
      'Inventariar Instrumentos Anteriores',
      'Identificar autoavaliações, diagnósticos assistidos, ciclos, eixos, critérios e relatórios disponíveis.',
      '["Inventário concluído"]'::jsonb
    ),
    (
      'PEM-00.06.02',
      'Estruturar Achados e Reincidências',
      'Extrair lacunas, riscos, recomendações, fortalezas, criticidade e repetição entre ciclos.',
      '["Achados estruturados", "Reincidências calculadas"]'::jsonb
    ),
    (
      'PEM-00.06.ED01',
      'Matriz de Achados de Avaliações e Diagnósticos',
      'Visão consolidada por instrumento, eixo, critério, criticidade, recorrência e situação.',
      '["Matriz validada"]'::jsonb
    ),
    (
      'PEM-00.07.01',
      'Inventariar Planos de Ação Existentes',
      'Registrar planos, ações, responsáveis, prazos, situação, evidências e última atualização.',
      '["Planos inventariados"]'::jsonb
    ),
    (
      'PEM-00.07.02',
      'Avaliar Execução e Efetividade',
      'Distinguir execução declarada, execução comprovada, atraso, paralisação e resultado efetivo.',
      '["Execução e efetividade avaliadas"]'::jsonb
    ),
    (
      'PEM-00.07.03',
      'Configurar Cadência de Follow-up',
      'Definir alertas, responsáveis, reuniões, evidências obrigatórias e escalonamento de pendências.',
      '["Cadência de follow-up definida"]'::jsonb
    ),
    (
      'PEM-00.07.ED01',
      'Painel de Planos Anteriores e Follow-up',
      'Painel de ações vencidas, paradas, sem evidências, reincidentes e sem efetividade.',
      '["Painel validado"]'::jsonb
    ),
    (
      'PEM-00.08.01',
      'Calcular Prontidão Diagnóstica',
      'Avaliar atendimento do checklist, cobertura das evidências e riscos de informação.',
      '["Prontidão calculada"]'::jsonb
    ),
    (
      'PEM-00.08.ED01',
      'Relatório de Prontidão, Lacunas e Pendências',
      'Consolidar lacunas, impactos, responsáveis, prazos e plano de complementação.',
      '["Relatório aprovado"]'::jsonb
    ),
    (
      'PEM-01.01',
      'Consolidação da Base Diagnóstica',
      'Consolidar e qualificar as evidências validadas na PEM-00 para uso nas análises diagnósticas.',
      '["Base diagnóstica consolidada", "Evidências críticas rastreáveis"]'::jsonb
    ),
    (
      'PEM-01.02',
      'Análise de Avaliações, Diagnósticos e Planos Anteriores',
      'Interpretar autoavaliações, diagnósticos assistidos, lacunas recorrentes, planos anteriores e sua efetividade.',
      '["Lacunas históricas analisadas", "Planos anteriores classificados", "Reincidências identificadas"]'::jsonb
    )
)
update public.skpe_methodology_template_items item
set
  name = corrected_values.name,
  description = corrected_values.description,
  completion_criteria = corrected_values.completion_criteria
from corrected_values
join public.skpe_methodology_template_versions version
  on version.version_code = 'SK-PE-2026.2'
join public.skpe_methodology_templates template
  on template.id = version.template_id
 and template.code = 'SKPE-OFICIAL'
where item.template_version_id = version.id
  and item.code = corrected_values.code;

-- ------------------------------------------------------------
-- 3. Jornadas já criadas a partir da metodologia
-- ------------------------------------------------------------
with corrected_values(code, name, description) as (
  values
    ('PEM-00', 'Governança, Abertura e Gestão de Evidências', 'Estabelecer mandato, governança, caracterização, checklist dinâmico, base de evidências e prontidão para o diagnóstico.'),
    ('PEM-00.01', 'Abertura, Mandato e Escopo', 'Formalizar contratação, objetivos, limites, premissas, patrocínio e critérios de sucesso.'),
    ('PEM-00.02', 'Governança, Papéis e Ritos', 'Definir patrocinadores, comitês, papéis, responsabilidades, cadências, fóruns e regras de decisão.'),
    ('PEM-00.03', 'Caracterização da Organização', 'Registrar natureza, tipo, ramo, porte, estrutura, território, maturidade e demais atributos que orientam o método.'),
    ('PEM-00.04', 'Checklist Dinâmico de Informações', 'Gerar e validar o checklist conforme contexto, porte, ramo, maturidade, escopo e modelos de referência aplicáveis.'),
    ('PEM-00.05', 'Gestão de Evidências e Integração com o SK-DOC', 'Solicitar, receber, classificar, validar, proteger e vincular evidências às análises e decisões do projeto.'),
    ('PEM-00.06', 'Autoavaliações e Diagnósticos Assistidos', 'Importar e estruturar eixos, critérios, resultados, lacunas, recomendações e histórico de instrumentos anteriores.'),
    ('PEM-00.07', 'Planos de Ação e Follow-up', 'Analisar planos existentes, atualização, execução, evidências, atrasos, paralisações, reincidências e efetividade.'),
    ('PEM-00.08', 'Lacunas, Pendências e Prontidão', 'Consolidar lacunas de informação, riscos de qualidade, pendências críticas e nível de prontidão para o diagnóstico.'),
    ('PEM-00.GATE', 'Gate 00 — Prontidão para o Diagnóstico', 'Autorizar o início da PEM-01 mediante mandato, governança, evidências mínimas, lacunas conhecidas e plano de complementação.'),
    ('PEM-00.04.01', 'Gerar Checklist Contextualizado', 'Combinar regras por tipo, natureza, ramo, porte, maturidade, escopo e modelo de referência.'),
    ('PEM-00.04.ED01', 'Checklist de Informações e Evidências', 'Lista controlada de informações, responsáveis, prazos, criticidade e situação de atendimento.'),
    ('PEM-00.05.01', 'Solicitar e Receber Evidências', 'Controlar solicitações, recebimentos, pendências e responsáveis.'),
    ('PEM-00.05.02', 'Classificar e Validar Evidências', 'Avaliar origem, atualidade, completude, confiabilidade, confidencialidade e aderência.'),
    ('PEM-00.05.ED01', 'Base de Evidências do Projeto', 'Repositório rastreável das evidências aceitas, rejeitadas, ausentes e desatualizadas.'),
    ('PEM-00.06.01', 'Inventariar Instrumentos Anteriores', 'Identificar autoavaliações, diagnósticos assistidos, ciclos, eixos, critérios e relatórios disponíveis.'),
    ('PEM-00.06.02', 'Estruturar Achados e Reincidências', 'Extrair lacunas, riscos, recomendações, fortalezas, criticidade e repetição entre ciclos.'),
    ('PEM-00.06.ED01', 'Matriz de Achados de Avaliações e Diagnósticos', 'Visão consolidada por instrumento, eixo, critério, criticidade, recorrência e situação.'),
    ('PEM-00.07.01', 'Inventariar Planos de Ação Existentes', 'Registrar planos, ações, responsáveis, prazos, situação, evidências e última atualização.'),
    ('PEM-00.07.02', 'Avaliar Execução e Efetividade', 'Distinguir execução declarada, execução comprovada, atraso, paralisação e resultado efetivo.'),
    ('PEM-00.07.03', 'Configurar Cadência de Follow-up', 'Definir alertas, responsáveis, reuniões, evidências obrigatórias e escalonamento de pendências.'),
    ('PEM-00.07.ED01', 'Painel de Planos Anteriores e Follow-up', 'Painel de ações vencidas, paradas, sem evidências, reincidentes e sem efetividade.'),
    ('PEM-00.08.01', 'Calcular Prontidão Diagnóstica', 'Avaliar atendimento do checklist, cobertura das evidências e riscos de informação.'),
    ('PEM-00.08.ED01', 'Relatório de Prontidão, Lacunas e Pendências', 'Consolidar lacunas, impactos, responsáveis, prazos e plano de complementação.'),
    ('PEM-01.01', 'Consolidação da Base Diagnóstica', 'Consolidar e qualificar as evidências validadas na PEM-00 para uso nas análises diagnósticas.'),
    ('PEM-01.02', 'Análise de Avaliações, Diagnósticos e Planos Anteriores', 'Interpretar autoavaliações, diagnósticos assistidos, lacunas recorrentes, planos anteriores e sua efetividade.')
)
update public.skpe_journey_items item
set
  name = corrected_values.name,
  description = corrected_values.description
from corrected_values
where item.code = corrected_values.code;

commit;
