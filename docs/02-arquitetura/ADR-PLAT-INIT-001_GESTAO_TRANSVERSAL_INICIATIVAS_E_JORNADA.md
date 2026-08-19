---
id: ADR-PLAT-INIT-001
version: 1.0.0
status: accepted
domain: SPARKs Platform
owner_module: PLATFORM
created_at: 2026-08-19
updated_at: 2026-08-19
origin: SK-PE-CONT-01
related_gates:
  - 17-B.5F.1
related_domains:
  - SK-PE
  - SK-PN
  - SK-BPM
  - SK-PCM
  - SPARK Impacto Coop
  - Gestão de Iniciativas
---

# ADR-PLAT-INIT-001 — Gestão Transversal de Iniciativas e Especialização da Jornada Estratégica

## 1. Contexto

A Plataforma SPARKs evoluiu o domínio de Iniciativas originalmente dentro do SK-PE, incluindo tipologias, classes metodológicas, portfólio, 5W2H, responsáveis, patrocinadores, custos, benefícios, riscos, marcos, ações, resultados e vínculos estratégicos.

Em paralelo, a Jornada Estratégica passou a concentrar inteligência de execução do processo de construção e implantação do Planejamento Estratégico, com hierarquia metodológica, cronograma governado, baseline, rebaseline, forecast, execução real, entregáveis, gates, responsabilidades e futura projeção em Gantt, agenda, custos e acompanhamento gerencial.

A evolução dessas duas capacidades revelou um risco de duplicação conceitual: tratar a implantação do Planejamento Estratégico simultaneamente como um `skpe_project` técnico do módulo e como uma Iniciativa Estratégica do tipo Projeto da organização.

Também ficou evidente que Iniciativas, Projetos e Programas possuem valor organizacional independente do Planejamento Estratégico e deverão ser utilizados por outros módulos e contextos da Plataforma SPARKs.

## 2. Decisão

A Plataforma SPARKs adotará **Gestão de Iniciativas como capacidade transversal da plataforma**, com vida própria no contexto da organização.

O Planejamento Estratégico será um dos contextos capazes de propor, gerar, selecionar, priorizar, validar, vincular e acompanhar Iniciativas, mas não será o proprietário existencial delas.

A **Implantação do Planejamento Estratégico** deverá ser representada no Portfólio de Iniciativas da organização como:

- Classe: `Projeto`;
- Categoria/Natureza: `Estratégica`;
- Origem: Planejamento Estratégico / metodologia SPARKs, quando aplicável;
- Governança: organizacional;
- Execução especializada: Jornada Estratégica do SK-PE.

A Jornada Estratégica será, portanto, uma **especialização operacional do Projeto Estratégico “Implantação do Planejamento Estratégico”**, e não um projeto concorrente ou independente representando o mesmo objeto de negócio.

## 3. Princípio de propriedade do domínio

A entidade canônica de Iniciativa deverá ser de propriedade da Organização e não de uma versão específica do Planejamento Estratégico.

O vínculo entre uma Iniciativa e:

- Planejamento Estratégico;
- Formulação Estratégica;
- Objetivo Estratégico — OKR;
- Resultado-Chave;
- Ciclo de Evolução;
- Programa;
- módulo especialista;

será tratado como **relação governada, rastreável e versionável**, sem condicionar a existência da Iniciativa à permanência desse vínculo.

Uma Iniciativa poderá sobreviver à mudança de versão do PE, à mudança de ciclo estratégico, à revisão de Objetivos Estratégicos — OKRs ou à transferência para outro contexto de gestão.

## 4. Modelo conceitual alvo

```text
ORGANIZAÇÃO
│
├── PORTFÓLIO DE INICIATIVAS
│   ├── Programa
│   ├── Projeto
│   ├── Iniciativa
│   └── Ação Estruturante
│
└── PROJETO ESTRATÉGICO
    "Implantação do Planejamento Estratégico"
        │
        └── Especialização SK-PE
            └── Jornada Estratégica
                ├── Macrofases
                ├── Fases
                ├── Etapas
                ├── Atividades
                ├── Entregáveis
                ├── Gates
                ├── Cronograma governado
                ├── Baseline / Rebaseline
                ├── Forecast
                ├── Execução real
                ├── Agenda / Eventos
                ├── Marcos
                ├── Evidências
                ├── Custos
                ├── Riscos
                └── Aprendizados
```

## 5. Gestão de Iniciativas como capacidade transversal

A Gestão de Iniciativas deverá poder evoluir para módulo ou submódulo transversal com experiência própria, incluindo, progressivamente:

- painel gerencial de portfólio;
- Programas, Projetos, Iniciativas e Ações Estruturantes;
- Canvas/TAP conforme classe e contexto;
- 5W2H;
- cronograma e Gantt;
- Kanban;
- agenda, reuniões e eventos;
- marcos e entregáveis;
- custos e orçamento;
- benefícios e resultados;
- riscos e dependências;
- responsáveis, patrocinadores e equipes;
- evidências e documentos;
- indicadores de saúde, prazo, custo, benefício e execução;
- decisões, validações e aprendizados;
- integração com módulos especialistas.

## 6. Relação com módulos especialistas

Os módulos especialistas poderão gerar, especializar ou consumir Iniciativas sem duplicar o núcleo transversal.

Exemplos:

- SK-PE → projetos e iniciativas estratégicas, incluindo Implantação do PE;
- SK-PN → iniciativas derivadas do modelo de negócio e viabilidade;
- SK-BPM → iniciativas de processos e melhoria;
- SPARK Impacto Coop → programas, projetos e iniciativas ESG/impacto;
- SK-PCM → iniciativas de comunicação, marketing e engajamento;
- demais módulos → especializações futuras sobre o mesmo núcleo.

Cada módulo poderá possuir artefatos e jornadas especializadas, mas não deverá reconstruir sua própria entidade concorrente de Projeto/Iniciativa quando o conceito de negócio for o mesmo.

## 7. Fonte única de verdade

A evolução deverá preservar uma única fonte de verdade para o objeto organizacional Iniciativa/Projeto.

Não será aceita uma arquitetura em que:

- o SK-PE mantenha um Projeto;
- a Gestão de Iniciativas mantenha outro Projeto;
- ambos representem a mesma Implantação do Planejamento Estratégico;
- cronogramas, custos, responsáveis, progresso ou riscos sejam atualizados independentemente.

Projeções, read models e especializações são permitidos; duplicação de autoridade não é.

## 8. Consequências para o modelo atual

O modelo atual contém acoplamento histórico de `skpe_initiatives.project_id` com `skpe_projects`.

Esse acoplamento deverá ser auditado antes de qualquer DDL de convergência. A solução de implementação poderá envolver:

1. evolução da entidade existente para núcleo transversal;
2. criação de núcleo transversal com migração governada;
3. camada canônica transversal com compatibilidade temporária;
4. composição entre entidade organizacional e especializações por módulo.

A decisão física somente será tomada após auditoria de dependências, cardinalidades, contratos RPC, frontend, RLS, migrations e dados existentes.

## 9. Regras arquiteturais obrigatórias

1. A Organização é o contexto proprietário da Iniciativa.
2. Planejamentos, formulações e ciclos vinculam Iniciativas; não determinam sua existência.
3. Programa é distinto de Projeto.
4. Projeto é uma classe de Iniciativa, sem impedir especializações próprias.
5. A Jornada Estratégica não é uma segunda fonte de verdade do Projeto de Implantação do PE.
6. Cronograma, Gantt, Kanban, agenda e dashboards são projeções/capacidades de gestão, não entidades concorrentes do Projeto.
7. Módulos especialistas podem especializar execução, artefatos e metodologia.
8. Relações estratégicas devem ser versionadas e auditáveis.
9. Mudanças relevantes exigem autoria, origem, status de validação e histórico.
10. Nenhuma migração poderá introduzir dívida consciente, drift semântico ou duplicação de autoridade.

## 10. Impacto no SK-PE

O SK-PE deverá continuar sendo responsável por:

- metodologia do Planejamento Estratégico;
- Jornada Estratégica especializada;
- geração e validação de propostas estratégicas;
- vínculos com Objetivos Estratégicos — OKRs e Resultados-Chave;
- governança da implantação do PE;
- artefatos metodológicos especializados.

O SK-PE não deverá ser o proprietário exclusivo do domínio transversal de Iniciativas.

## 11. Gate de implementação

A implementação desta ADR inicia pela auditoria **17-B.5F.1 — Convergência Canônica Jornada ↔ Gestão de Iniciativas**.

Antes de DDL deverão ser verificados:

- dependências de `skpe_initiatives`;
- dependências de `skpe_projects`;
- cardinalidades existentes;
- vínculos com Jornada;
- vínculos com Formulações e Portfólio;
- contratos RPC e frontend;
- RLS e permissões;
- registros existentes que possam representar a Implantação do PE;
- impacto sobre histórico e rastreabilidade.

## 12. Critério de sucesso

A decisão estará plenamente implementada quando a organização puder visualizar e administrar o Projeto Estratégico de Implantação do Planejamento Estratégico em seu Portfólio de Iniciativas e, a partir desse mesmo objeto, acessar sua Jornada Estratégica especializada, sem duplicação de cadastro, autoridade, cronograma, responsáveis, custos ou progresso.
