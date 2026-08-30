---
id: SKPE-GUARDRAIL-UX-BASILAR-6G-6H-JORNADA
version: 1.1.0
status: approved
domain: SPARKs PaaS
owner: SPARKs PE
canonical_context: SK-PE-CONT-01
created_at: 2026-08-29
updated_at: 2026-08-30
applies_to:
  - 17-B.5F.3C.6G
  - 17-B.5F.3C.6H
  - FE-09.A
  - all-future-user-facing-surfaces
---

# Guardrail Basilar de UX — Kanban, Gantt, Painéis e Jornada Estratégica

## 1. Propósito

Registrar critérios basilares de padrão, simplicidade, compreensão e performance para a continuidade do roadmap já aprovado do SK-PE SaaS.

Este guardrail **não cria novo gate funcional, não aumenta a contagem do roadmap e não altera a fonte de verdade dos domínios existentes**. Ele explicita critérios de qualidade que devem ser satisfeitos dentro dos gates e contratos já aprovados antes de seu fechamento.

Referências canônicas:

- `MANIFESTO_UX_SPARKS.md`;
- `CHECKLIST_PRONTIDAO_UX_SPARKS.md`;
- `BENCHMARK_UX_SMARTKANVAS_PARA_SPARKS.md`;
- `ROADMAP_17_B_5F_3C_6D_6J.md`;
- `ROADMAP_POS_6J_WORKSPACE_JOURNEY_PROJECT.md`;
- `CONTRATO_MEU_ESPACO_TRABALHO_FE09A05.md`;
- `CONTRATO_PAINEL_PRINCIPAL_FE09A06.md`;
- `MATRIZ_PREFERENCIAS_USUARIO_FE09A06.md`;
- `REQ-SKPE-FE-010_EXPERIENCIA_APLICACIONAL_E_OPERACIONALIZACAO_FORMULACAO.md`;
- `ADR-PLAT-INIT-001_GESTAO_TRANSVERSAL_INICIATIVAS_E_JORNADA.md`.

## 2. Princípio geral

A experiência deve obedecer ao princípio já aprovado de **simplicidade na superfície e rigor na estrutura**.

A evolução funcional não poderá considerar uma capacidade encerrada apenas porque seus contratos ou componentes técnicos existem. O fechamento de uma projeção visual exige que o usuário consiga compreender seu propósito, alternar entre visões equivalentes sem confusão e operar com densidade compatível com o contexto.

A partir da versão 1.1.0, toda superfície voltada ao usuário também fica subordinada ao `MANIFESTO_UX_SPARKS.md` e ao `CHECKLIST_PRONTIDAO_UX_SPARKS.md`.

## 3. Painel Principal

O modelo mental principal permanece singular:

- na ausência de preferência persistida, o sistema usa o fallback canônico, priorizando `my-work` quando elegível;
- quando o usuário define um painel elegível como **Painel Principal**, essa preferência substitui a anterior para o mesmo usuário, organização e módulo;
- somente um painel pode ocupar o papel de Painel Principal em cada contexto;
- a interface deve apresentar claramente qual painel é o Principal;
- painéis alternativos continuam disponíveis como outras formas de visualizar o mesmo contexto quando elegíveis, mas não devem competir visualmente como se vários fossem simultaneamente o painel principal.

A funcionalidade de `workspace.favorites` permanece distinta e não deve ser confundida com `workspace.primary_dashboard`. Favoritos não substituem nem concorrem semanticamente com o Painel Principal.

## 4. Abas e densidade de informação

Quando diferentes visões ou agrupamentos apresentarem o mesmo contexto de negócio, a preferência é por **progressive disclosure**, abas ou controles equivalentes, evitando empilhar simultaneamente grandes superfícies na mesma tela.

Critérios:

- mostrar primeiro o conteúdo necessário para a decisão atual;
- evitar repetição da mesma informação em cartões, tabelas e painéis simultâneos sem finalidade clara;
- preservar contexto ao trocar de aba ou visão;
- não montar ou carregar visualizações pesadas que não estejam ativas quando isso não for necessário;
- manter ações primárias visíveis e reduzir botões concorrentes;
- utilizar rótulos orientados à tarefa do usuário.

## 5. Kanban — guardrail do gate 17-B.5F.3C.6G

O Kanban é uma **projeção operacional das ações existentes**, não uma segunda fonte de verdade.

O gate 6G somente poderá ser considerado UX-validado quando:

1. ficar evidente ao usuário que o Kanban organiza ações da iniciativa por estado de execução;
2. a troca entre Kanban e outras visões da mesma iniciativa ocorrer sem duplicar registros;
3. movimentações chamarem exclusivamente os contratos governados de lifecycle;
4. filtros essenciais forem compreensíveis e não sobrecarregarem a superfície;
5. abertura e edição da ação ocorrerem sem perder o contexto da iniciativa;
6. estados vazios expliquem o que o quadro representa e qual ação o usuário pode tomar;
7. a densidade dos cartões permita leitura e gestão prática, inclusive em iniciativas com muitas ações;
8. a visualização seja percebida como ferramenta de gestão, e não apenas como representação gráfica adicional.

A existência do componente técnico de Kanban, isoladamente, não encerra o gate 6G.

## 6. Gantt — guardrail do gate 17-B.5F.3C.6H

O Gantt deve nascer **hierárquico, colapsável e condensável**.

São requisitos basilares:

- permitir expandir e recolher níveis hierárquicos;
- oferecer ação de `Recolher tudo` e `Expandir tudo` quando houver profundidade relevante;
- iniciar em nível condensado adequado ao volume da Jornada ou projeto;
- permitir que macrofases/fases sejam usadas como síntese antes de expor atividades e entregáveis;
- preservar alinhamento entre hierarquia e escala temporal;
- evitar uma linha contínua excessivamente longa e uma lista vertical integralmente expandida como experiência padrão;
- não renderizar detalhamento profundo desnecessário quando os níveis estiverem recolhidos;
- manter legíveis baseline, planejamento vigente, forecast e realizado conforme o nível de detalhe exibido.

Um Gantt tecnicamente correto, mas impraticável por excesso de extensão ou densidade, não satisfaz o critério de saída do 6H.

## 7. Projeto Estratégico e Jornada Estratégica

Permanece válida a decisão da `ADR-PLAT-INIT-001`:

- a Implantação do Planejamento Estratégico é representada no Portfólio como **Projeto** de natureza estratégica;
- a Jornada Estratégica do SK-PE é a especialização operacional desse mesmo objeto;
- não devem existir dois projetos concorrentes representando a mesma implantação.

A experiência deve tornar essa relação perceptível ao usuário.

Ao preparar/iniciar um Planejamento Estratégico, o fluxo governado existente deve produzir ou reutilizar o Projeto Estratégico correspondente e sua Jornada, utilizando o modelo metodológico recomendado.

A Jornada inicial deve ser apresentada como **rascunho operacional orientador**, com estrutura metodológica sugerida de macrofases, fases, atividades, entregáveis e gates, passível de evolução governada sem perder a referência do template.

O usuário não deve precisar descobrir manualmente que a Jornada também representa a execução de um Projeto Estratégico.

## 8. Performance percebida

As próximas adequações devem evitar aumentar a complexidade técnica sem benefício operacional.

Princípios mínimos:

- carregamento sob demanda para superfícies pesadas quando aplicável;
- evitar renderização simultânea de Kanban, Gantt e demais projeções se apenas uma estiver visível;
- preservar uma única rolagem vertical principal sempre que possível;
- limitar recalculações no frontend e reutilizar read models/contratos canônicos;
- manter projeções derivadas, sem persistência gráfica paralela;
- priorizar alterações incrementais e testáveis.

## 9. Sequenciamento no roadmap

Sem criar novo gate funcional, a continuidade passa a observar:

1. gates já fechados permanecem fechados e seus aprendizados viram padrão transversal;
2. **FE-09.A / Painéis:** reconciliar a interface com o contrato singular de Painel Principal e manter Favoritos semanticamente separados;
3. **Jornada Estratégica:** garantir que o Projeto Estratégico transversal e a Jornada gerada pelo template sejam claramente expostos como uma única experiência operacional;
4. qualquer nova superfície deverá aplicar o padrão `Objeto → Espaço de Trabalho` quando houver múltiplas visões do mesmo objeto;
5. toda entrega voltada ao usuário deverá alcançar classificação `UX-READY` no checklist canônico antes de `PASS/CLOSED`.

## 10. Regra de fechamento

Nenhum dos itens acima deverá ser adiado genericamente para uma etapa final de “polimento”. Quando o gate funcional correspondente tocar a superfície afetada, simplicidade, legibilidade, navegabilidade e performance percebida passam a integrar seu critério de saída.

Teste automatizado e build aprovados são necessários, mas não suficientes para fechamento de superfície de usuário.

## 11. Extensão transversal — Design System e benchmark competitivo

O benchmark externo registrado em `BENCHMARK_UX_SMARTKANVAS_PARA_SPARKS.md` passa a ser referência comparativa de experiência, não de arquitetura ou identidade visual.

A régua SPARKs é superior quando combina:

- simplicidade equivalente ou melhor na superfície;
- governança mais forte por baixo;
- contexto transversal entre módulos;
- inteligência contextual;
- explicabilidade;
- uma única autoridade projetada em múltiplas visões.

O padrão visual deverá ser progressivamente consolidado em componentes reutilizáveis. Correções recorrentes de alinhamento, tipografia, cards, abas, botões, estados vazios ou menus devem ser tratadas como sinal de ausência de Design System suficientemente aplicado, e não como exceções isoladas por tela.

**Regra final:** toda superfície nova ou alterada deve ser avaliada com o `CHECKLIST_PRONTIDAO_UX_SPARKS.md`; somente `UX-READY` sustenta fechamento funcional.