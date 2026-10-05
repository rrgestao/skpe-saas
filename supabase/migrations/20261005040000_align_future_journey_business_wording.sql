-- Align future SK-PE Journey wording with the governed methodology already implemented.
-- This migration changes labels/descriptions only. It does not open, complete or validate any Journey item.

with wording(code,name,description) as (
  values
    ('PEM-03','Desdobramento Estratégico','Transformar os Objetivos Estratégicos aprovados em OKRs, Resultados-Chave, indicadores, metas, iniciativas e governança da execução.'),
    ('PEM-03.01','Desdobramento em OKRs','Traduzir os Objetivos Estratégicos em Objetivos de OKR qualitativos e Resultados-Chave mensuráveis, calibrados à maturidade e submetidos à validação humana.'),
    ('PEM-03.02','Indicadores e Metas','Definir indicadores, fórmulas, fontes, linhas de base e metas anualizadas, distinguindo evidência histórica, benchmark e proposta sujeita à validação.'),
    ('PEM-03.03','Iniciativas e Projetos Estratégicos','Identificar, priorizar e temporalizar iniciativas e projetos que contribuam diretamente para os Resultados-Chave e caibam nos Ciclos de Evolução aplicáveis.'),
    ('PEM-03.04','Responsabilidades e Governança da Execução','Definir responsabilidades, alçadas, fóruns, ritos, cadências e escalonamentos da execução sem atribuir papéis não validados.'),
    ('PEM-03.GATE','Validação da Macrofase 3','Ratificar institucionalmente o Desdobramento Estratégico antes de iniciar a Implementação e Mobilização.'),

    ('PEM-04','Implementação e Mobilização','Preparar a execução da estratégia, mobilizando pessoas, comunicação, capacidades, ações, recursos, dependências e riscos necessários à implantação.'),
    ('PEM-04.01','Ativação do Plano de Implementação','Confirmar prioridades, responsáveis, ações, marcos, recursos, dependências e prontidão antes de iniciar a execução do portfólio validado.'),
    ('PEM-04.02','Comunicação e Mobilização','Planejar comunicação e mobilização por público, objetivo, mensagem, canal, cadência, responsável e evidência de alcance.'),
    ('PEM-04.03','Capacidades e Gestão da Mudança','Identificar lacunas de pessoas, processos, tecnologia e gestão e estruturar as mudanças e capacidades necessárias à execução.'),
    ('PEM-04.04','Gestão de Riscos da Implementação','Consolidar e tratar riscos capazes de comprometer a implementação, conectando causa, consequência, controles, respostas, responsáveis, indicadores e evidências.'),
    ('PEM-04.GATE','Validação da Macrofase 4','Confirmar institucionalmente a prontidão da Implementação e Mobilização antes de iniciar a operação monitorada.'),

    ('PEM-05','Monitoramento e Aprendizado','Acompanhar resultados e execução, realizar análises críticas, registrar aprendizados e promover atualização estratégica governada e melhoria contínua.'),
    ('PEM-05.01','Operação da Rotina de Monitoramento','Operar ciclos de monitoramento com dados, evidências, qualidade, confiança, check-ins e tratamento dos atrasos e desvios.'),
    ('PEM-05.02','Análise Crítica de Desempenho','Analisar resultados, metas, desvios, causas, riscos, oportunidades e decisões necessárias com base em evidências.'),
    ('PEM-05.03','Aprendizado e Melhoria','Registrar aprendizados, causas, práticas eficazes e oportunidades e convertê-los em decisões ou melhorias verificáveis.'),
    ('PEM-05.04','Atualização Estratégica Governada','Avaliar a necessidade de atualização da estratégia e formalizar qualquer revisão de forma versionada, rastreável e sem edição silenciosa do que foi aprovado.'),
    ('PEM-05.GATE','Ciclo de Revisão Estratégica','Ratificar institucionalmente a revisão do ciclo, os aprendizados e as decisões de continuidade ou atualização.')
)
update public.skpe_journey_items i
set name=w.name,
    description=w.description,
    updated_at=timezone('utc',now()),
    updated_by=coalesce(auth.uid(),i.updated_by)
from wording w
where i.code=w.code
  and i.archived_at is null;

with wording(code,name,description) as (
  values
    ('PEM-03','Desdobramento Estratégico','Transformar os Objetivos Estratégicos aprovados em OKRs, Resultados-Chave, indicadores, metas, iniciativas e governança da execução.'),
    ('PEM-03.01','Desdobramento em OKRs','Traduzir os Objetivos Estratégicos em Objetivos de OKR qualitativos e Resultados-Chave mensuráveis, calibrados à maturidade e submetidos à validação humana.'),
    ('PEM-03.02','Indicadores e Metas','Definir indicadores, fórmulas, fontes, linhas de base e metas anualizadas, distinguindo evidência histórica, benchmark e proposta sujeita à validação.'),
    ('PEM-03.03','Iniciativas e Projetos Estratégicos','Identificar, priorizar e temporalizar iniciativas e projetos que contribuam diretamente para os Resultados-Chave e caibam nos Ciclos de Evolução aplicáveis.'),
    ('PEM-03.04','Responsabilidades e Governança da Execução','Definir responsabilidades, alçadas, fóruns, ritos, cadências e escalonamentos da execução sem atribuir papéis não validados.'),
    ('PEM-03.GATE','Validação da Macrofase 3','Ratificar institucionalmente o Desdobramento Estratégico antes de iniciar a Implementação e Mobilização.'),
    ('PEM-04','Implementação e Mobilização','Preparar a execução da estratégia, mobilizando pessoas, comunicação, capacidades, ações, recursos, dependências e riscos necessários à implantação.'),
    ('PEM-04.01','Ativação do Plano de Implementação','Confirmar prioridades, responsáveis, ações, marcos, recursos, dependências e prontidão antes de iniciar a execução do portfólio validado.'),
    ('PEM-04.02','Comunicação e Mobilização','Planejar comunicação e mobilização por público, objetivo, mensagem, canal, cadência, responsável e evidência de alcance.'),
    ('PEM-04.03','Capacidades e Gestão da Mudança','Identificar lacunas de pessoas, processos, tecnologia e gestão e estruturar as mudanças e capacidades necessárias à execução.'),
    ('PEM-04.04','Gestão de Riscos da Implementação','Consolidar e tratar riscos capazes de comprometer a implementação, conectando causa, consequência, controles, respostas, responsáveis, indicadores e evidências.'),
    ('PEM-04.GATE','Validação da Macrofase 4','Confirmar institucionalmente a prontidão da Implementação e Mobilização antes de iniciar a operação monitorada.'),
    ('PEM-05','Monitoramento e Aprendizado','Acompanhar resultados e execução, realizar análises críticas, registrar aprendizados e promover atualização estratégica governada e melhoria contínua.'),
    ('PEM-05.01','Operação da Rotina de Monitoramento','Operar ciclos de monitoramento com dados, evidências, qualidade, confiança, check-ins e tratamento dos atrasos e desvios.'),
    ('PEM-05.02','Análise Crítica de Desempenho','Analisar resultados, metas, desvios, causas, riscos, oportunidades e decisões necessárias com base em evidências.'),
    ('PEM-05.03','Aprendizado e Melhoria','Registrar aprendizados, causas, práticas eficazes e oportunidades e convertê-los em decisões ou melhorias verificáveis.'),
    ('PEM-05.04','Atualização Estratégica Governada','Avaliar a necessidade de atualização da estratégia e formalizar qualquer revisão de forma versionada, rastreável e sem edição silenciosa do que foi aprovado.'),
    ('PEM-05.GATE','Ciclo de Revisão Estratégica','Ratificar institucionalmente a revisão do ciclo, os aprendizados e as decisões de continuidade ou atualização.')
)
update public.skpe_methodology_template_items i
set name=w.name,
    description=w.description,
    updated_at=timezone('utc',now()),
    updated_by=coalesce(auth.uid(),i.updated_by)
from wording w
where i.code=w.code;

comment on table public.skpe_journey_items is
'Instâncias governadas da Jornada SK-PE. A nomenclatura de PEM-03 a PEM-05 reflete o fluxo OKRs/indicadores/iniciativas/governança, implementação e monitoramento; alterações de texto não promovem status.';
