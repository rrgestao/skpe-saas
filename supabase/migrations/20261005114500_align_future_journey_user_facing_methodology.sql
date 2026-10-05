-- Align the future Journey wording with the current SK-PE methodology.
-- This migration changes presentation/description only; it does not change Journey status,
-- institutional decisions, validation results or sequencing.

update public.skpe_journey_items
set
  description = case code
    when 'PEM-03' then 'Desdobrar os Objetivos Estratégicos em OKRs, Resultados-Chave, indicadores, metas, iniciativas e responsabilidades de execução.'
    when 'PEM-03.01' then 'Estruturar OKRs e Resultados-Chave mensuráveis, vinculados aos Objetivos Estratégicos e sujeitos à validação institucional.'
    when 'PEM-03.02' then 'Definir indicadores, fórmulas, fontes, linhas de base e metas anualizadas para medir os resultados estratégicos.'
    when 'PEM-03.03' then 'Identificar, avaliar e priorizar iniciativas e projetos que contribuam diretamente para os Resultados-Chave e Objetivos Estratégicos.'
    when 'PEM-03.04' then 'Definir patrocinadores, responsáveis, fóruns, alçadas e ritos para governar a execução da estratégia.'
    when 'PEM-03.GATE' then 'Ratificar o Desdobramento Estratégico antes de iniciar a Implementação e Mobilização.'
    when 'PEM-04' then 'Preparar a execução da estratégia por meio da ativação do plano, comunicação, mobilização, desenvolvimento de capacidades e tratamento de riscos.'
    when 'PEM-04.01' then 'Organizar ondas, marcos, cronograma, recursos, dependências e condições para ativar a execução das iniciativas aprovadas.'
    when 'PEM-04.02' then 'Planejar a comunicação, o engajamento e o alinhamento das partes interessadas para sustentar a execução estratégica.'
    when 'PEM-04.03' then 'Desenvolver as competências, processos, tecnologias e mudanças organizacionais necessárias à implementação.'
    when 'PEM-04.04' then 'Identificar, acompanhar e tratar riscos, impedimentos e respostas associados à implementação da estratégia.'
    when 'PEM-04.GATE' then 'Ratificar a preparação da Implementação e Mobilização antes de iniciar o acompanhamento sistemático da estratégia.'
    when 'PEM-05' then 'Operar o monitoramento, analisar desempenho, registrar aprendizados e promover atualização estratégica governada.'
    when 'PEM-05.01' then 'Operar a rotina de monitoramento com dados, evidências, indicadores, metas e cadências previamente validados.'
    when 'PEM-05.02' then 'Realizar análise crítica dos resultados, desvios, causas, riscos e oportunidades com decisões rastreáveis.'
    when 'PEM-05.03' then 'Transformar a análise crítica em aprendizados, melhorias e ações de aperfeiçoamento da execução.'
    when 'PEM-05.04' then 'Avaliar a necessidade de atualização da estratégia e formalizar qualquer revisão por mecanismo governado e versionado.'
    when 'PEM-05.GATE' then 'Formalizar o fechamento do Ciclo de Revisão Estratégica e as decisões de continuidade.'
    else description
  end,
  updated_at = timezone('utc', now())
where code in (
  'PEM-03','PEM-03.01','PEM-03.02','PEM-03.03','PEM-03.04','PEM-03.GATE',
  'PEM-04','PEM-04.01','PEM-04.02','PEM-04.03','PEM-04.04','PEM-04.GATE',
  'PEM-05','PEM-05.01','PEM-05.02','PEM-05.03','PEM-05.04','PEM-05.GATE'
);

update public.skpe_methodology_template_items
set
  description = case code
    when 'PEM-03' then 'Desdobrar os Objetivos Estratégicos em OKRs, Resultados-Chave, indicadores, metas, iniciativas e responsabilidades de execução.'
    when 'PEM-03.01' then 'Estruturar OKRs e Resultados-Chave mensuráveis, vinculados aos Objetivos Estratégicos e sujeitos à validação institucional.'
    when 'PEM-03.02' then 'Definir indicadores, fórmulas, fontes, linhas de base e metas anualizadas para medir os resultados estratégicos.'
    when 'PEM-03.03' then 'Identificar, avaliar e priorizar iniciativas e projetos que contribuam diretamente para os Resultados-Chave e Objetivos Estratégicos.'
    when 'PEM-03.04' then 'Definir patrocinadores, responsáveis, fóruns, alçadas e ritos para governar a execução da estratégia.'
    when 'PEM-03.GATE' then 'Ratificar o Desdobramento Estratégico antes de iniciar a Implementação e Mobilização.'
    when 'PEM-04' then 'Preparar a execução da estratégia por meio da ativação do plano, comunicação, mobilização, desenvolvimento de capacidades e tratamento de riscos.'
    when 'PEM-04.01' then 'Organizar ondas, marcos, cronograma, recursos, dependências e condições para ativar a execução das iniciativas aprovadas.'
    when 'PEM-04.02' then 'Planejar a comunicação, o engajamento e o alinhamento das partes interessadas para sustentar a execução estratégica.'
    when 'PEM-04.03' then 'Desenvolver as competências, processos, tecnologias e mudanças organizacionais necessárias à implementação.'
    when 'PEM-04.04' then 'Identificar, acompanhar e tratar riscos, impedimentos e respostas associados à implementação da estratégia.'
    when 'PEM-04.GATE' then 'Ratificar a preparação da Implementação e Mobilização antes de iniciar o acompanhamento sistemático da estratégia.'
    when 'PEM-05' then 'Operar o monitoramento, analisar desempenho, registrar aprendizados e promover atualização estratégica governada.'
    when 'PEM-05.01' then 'Operar a rotina de monitoramento com dados, evidências, indicadores, metas e cadências previamente validados.'
    when 'PEM-05.02' then 'Realizar análise crítica dos resultados, desvios, causas, riscos e oportunidades com decisões rastreáveis.'
    when 'PEM-05.03' then 'Transformar a análise crítica em aprendizados, melhorias e ações de aperfeiçoamento da execução.'
    when 'PEM-05.04' then 'Avaliar a necessidade de atualização da estratégia e formalizar qualquer revisão por mecanismo governado e versionado.'
    when 'PEM-05.GATE' then 'Formalizar o fechamento do Ciclo de Revisão Estratégica e as decisões de continuidade.'
    else description
  end,
  updated_at = timezone('utc', now())
where code in (
  'PEM-03','PEM-03.01','PEM-03.02','PEM-03.03','PEM-03.04','PEM-03.GATE',
  'PEM-04','PEM-04.01','PEM-04.02','PEM-04.03','PEM-04.04','PEM-04.GATE',
  'PEM-05','PEM-05.01','PEM-05.02','PEM-05.03','PEM-05.04','PEM-05.GATE'
);
