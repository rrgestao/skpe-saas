---
id: REQ-PLAT-INIT-001
version: 1.0.0
status: approved-for-progressive-implementation
domain: SPARKs Platform
owner_module: PLATFORM
created_at: 2026-08-19
updated_at: 2026-08-19
origin: SK-PE-CONT-01
depends_on:
  - ADR-PLAT-INIT-001
related_gates:
  - 17-B.5F.1
---

# REQ-PLAT-INIT-001 — Gestão Organizacional de Iniciativas, Projetos e Programas

## 1. Objetivo

Definir os requisitos canônicos para que Iniciativas, Projetos, Programas e Ações Estruturantes sejam administrados como ativos organizacionais transversais da Plataforma SPARKs, independentes da existência de um Planejamento Estratégico específico, mas capazes de se vincular a ele e a outros módulos especialistas.

## 2. Escopo funcional

A Gestão de Iniciativas deverá possuir vida própria na plataforma e permitir, progressivamente:

- Portfólio de Iniciativas da Organização;
- Programas;
- Projetos;
- Iniciativas;
- Ações Estruturantes;
- vinculação estratégica;
- priorização e scoring;
- responsáveis, patrocinadores e equipes;
- TAP e Canvas contextuais;
- 5W2H;
- cronograma governado;
- baseline, rebaseline e forecast quando aplicáveis;
- Gantt;
- Kanban;
- agenda, reuniões, oficinas e demais eventos;
- marcos e entregáveis;
- custos e orçamento;
- benefícios e resultados;
- riscos e dependências;
- documentos e evidências;
- decisões, validações e histórico;
- indicadores de saúde e desempenho;
- dashboards gerenciais;
- integração com módulos especialistas.

## 3. Propriedade organizacional

A Iniciativa deverá pertencer à Organização.

Sua existência não poderá depender obrigatoriamente de:

- um `skpe_project`;
- uma Formulação Estratégica;
- uma versão de Planejamento Estratégico;
- um Objetivo Estratégico — OKR;
- um Resultado-Chave;
- um Ciclo de Evolução;
- um módulo especialista específico.

Esses elementos poderão vinculá-la e contextualizá-la por relações governadas.

## 4. Classificação canônica

A plataforma deverá distinguir, no mínimo:

### Classe
- Programa;
- Projeto;
- Iniciativa;
- Ação Estruturante.

### Categoria/Natureza
A categoria deverá expressar o contexto gerencial/estratégico da iniciativa sem confundir-se com sua classe. Exemplos esperados:

- Estratégica;
- Operacional;
- Processo;
- Transformação;
- Sustentabilidade/ESG;
- Comunicação/Marketing;
- outras categorias governadas pelo domínio.

A taxonomia definitiva será versionada e administrável, evitando enums rígidos quando a natureza do domínio exigir evolução.

## 5. Implantação do Planejamento Estratégico

Ao iniciar formalmente um processo de Planejamento Estratégico, a plataforma deverá permitir criar ou materializar uma única Iniciativa organizacional com identidade equivalente a:

**Implantação do Planejamento Estratégico**

Configuração esperada:

- Classe: Projeto;
- Categoria/Natureza: Estratégica;
- origem registrada;
- status governado;
- patrocinador;
- responsável;
- período de execução;
- custos, benefícios, riscos e indicadores quando aplicáveis.

A Jornada Estratégica do SK-PE deverá estar vinculada a esse mesmo Projeto e atuar como especialização de sua execução.

## 6. Jornada Estratégica especializada

Quando uma Iniciativa do tipo Projeto estiver associada à implantação do PE, o SK-PE deverá fornecer sua Jornada Estratégica especializada, incluindo:

- Macrofases;
- Fases;
- Etapas;
- Atividades;
- Entregáveis;
- Gates/Pontos de Validação;
- cronograma governado;
- baseline/rebaseline;
- forecast;
- execução real;
- responsabilidades;
- evidências;
- ritos metodológicos;
- acompanhamento gerencial.

A Jornada não deverá criar um segundo Projeto organizacional.

## 7. Vinculação estratégica versionada

Uma Iniciativa poderá vincular-se a um ou mais:

- Objetivos Estratégicos — OKRs;
- Resultados-Chave;
- Temas Estratégicos;
- Ciclos de Evolução;
- Programas;
- Formulações Estratégicas;
- Planos de Negócio;
- Processos;
- compromissos ESG;
- campanhas ou planos de comunicação;
- outros objetos governados.

Esses vínculos deverão possuir, quando aplicável:

- origem;
- autoria;
- status de validação;
- vigência;
- peso/contribuição;
- justificativa;
- histórico.

## 8. Independência de ciclo de vida

A revisão ou encerramento de um Planejamento Estratégico não deverá excluir automaticamente uma Iniciativa.

A plataforma deverá suportar:

- continuidade da Iniciativa em novo ciclo estratégico;
- alteração de vínculos;
- arquivamento governado;
- cancelamento;
- transferência entre Programas;
- reclassificação;
- preservação histórica.

## 9. Experiência do usuário

A área de Gestão de Iniciativas deverá ser acessível como capacidade própria da Organização.

A entrada deverá privilegiar visão gerencial, com:

- indicadores;
- filtros;
- pesquisa;
- visão por portfólio;
- visão por responsável;
- visão por Objetivo Estratégico — OKRs;
- visão por Programa;
- visão por categoria/classe;
- Kanban;
- Gantt;
- alertas de prazo, custo, risco e saúde.

Cards e linhas deverão obedecer ao padrão transversal da Plataforma SPARKs: destaque no hover, ações rápidas e abertura do registro por clique em área útil.

## 10. Instrumentos contextuais

O instrumento de gestão deverá ser determinado pela classe e pelo contexto, sem ocupar desnecessariamente o menu principal:

- Projeto → TAP/Canvas do Projeto;
- Programa → Canvas do Programa e composição de projetos;
- Iniciativa de Processo → SIPOC Canvas quando aplicável;
- Ação Estruturante → Plano de Ação/5W2H;
- outras especializações → artefatos do módulo especialista.

## 11. Integração modular

Módulos especialistas deverão reutilizar o núcleo transversal.

O módulo especialista poderá acrescentar:

- metodologia;
- artefatos;
- campos contextuais;
- jornada;
- validações;
- read models;
- dashboards específicos.

Não poderá criar silenciosamente uma entidade concorrente representando a mesma Iniciativa/Projeto.

## 12. Requisitos de governança e auditoria

Toda alteração material deverá preservar, conforme aplicável:

- organização proprietária;
- autoria;
- origem;
- data/hora;
- responsável;
- patrocinador;
- status;
- motivo da mudança;
- validação;
- histórico;
- evidências;
- rastreabilidade dos vínculos.

## 13. Requisitos arquiteturais

A implementação deverá:

- separar domínio de apresentação;
- manter regras críticas no backend;
- impedir DML direto quando houver operação governada;
- preservar RLS e autorização;
- evitar `SECURITY DEFINER` sem justificativa explícita;
- evitar fontes de verdade duplicadas;
- usar projeções/read models para dashboards;
- suportar especializações sem herança rígida que provoque acoplamento entre módulos;
- manter nomenclatura e semântica consistentes entre banco, API, tipos, frontend e documentação.

## 14. Migração do modelo atual

Nenhuma alteração estrutural será executada antes da auditoria 17-B.5F.1.

A migração deverá preservar:

- IDs e histórico sempre que possível;
- vínculos existentes;
- Formulações;
- Portfólio;
- Jornada;
- ações;
- marcos;
- riscos;
- resultados;
- permissões;
- contratos externos já publicados.

Se for necessária compatibilidade transitória, ela deverá possuir prazo e plano explícito de retirada.

## 15. Critérios de aceite

O requisito será considerado implementado quando, no mínimo:

1. uma Iniciativa puder existir no contexto da Organização sem depender existencialmente de um PE;
2. o Projeto “Implantação do Planejamento Estratégico” aparecer no Portfólio da Organização;
3. a Jornada SK-PE estiver vinculada ao mesmo Projeto;
4. não houver duplicação de cronograma, progresso, custos ou responsáveis como fontes concorrentes;
5. o Projeto puder manter histórico através de ciclos e versões estratégicas;
6. módulos especialistas puderem referenciar a mesma Iniciativa;
7. dashboards e read models respeitarem a fonte única de verdade;
8. a segurança multi-organização permanecer validada.
