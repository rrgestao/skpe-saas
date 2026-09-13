---
id: sk-pe-capability-execution-and-traceability
title: Execução por Capacidades e Rastreabilidade Incremental do SK-PE
domain: products
type: governance
status: active
owner: governance
canonicality: supporting
canonical: false
criticality: high
parent:
  - sk-pe-product-hub
related:
  - sk-pe-master-roadmap
  - sk-pe-current-state
  - specification-driven-architecture-hub
  - sparkoop-infrastructure-operations-governance
  - products-hub
tags:
  - sk-pe
  - sparks-pe
  - capability
  - traceability
  - evidence
  - brownfield
  - specification-driven
language: pt-BR
encoding: UTF-8
semantic_layer: canonical-product-governance
created: 2026-09-06
updated: 2026-09-12
lineage:
  - repository: br-robson/projetos
    source_sha: 2915073884fefa1a7bd98a7775df5f37a5f85ec9
    path: docs/products/sk-pe/governance/capability-execution-and-traceability.md
  - ./../current-state.md
---

# Execução por Capacidades e Rastreabilidade Incremental do SK-PE

## Objetivo

Formalizar a adoção, pelo `SK-PE / SPARKs PE`, de uma execução brownfield orientada por capacidades, preservando velocidade de desenvolvimento sem perder intenção, evidência, dependências, gaps, decisões e possibilidade futura de evolução para specification.

Este documento não duplica a fundamentação transversal de Specification-Driven Architecture nem a governança corporativa de infraestrutura. Ele registra somente a adoção e o contrato operacional específicos do SK-PE.

## Autoridades superiores

A fundamentação transversal permanece em:

- `docs/ecosystem/architecture/specification-driven/`

A governança transversal de infraestrutura permanece em:

- `docs/ecosystem/infrastructure/`

O SK-PE referencia essas autoridades e não cria shadow standards.

## Decisão de adoção

`DECISAO`

O SK-PE passa a executar waves relevantes segundo a cadeia:

`CAPACIDADE -> INVESTIGACAO -> IMPLEMENTACAO -> VALIDACAO -> EVIDENCIA -> FECHAMENTO -> REGISTRO MINIMO DE CONHECIMENTO -> PROXIMA CAPACIDADE`

O registro documental não deve interromper o desenvolvimento funcional nem produzir documentação por volume. Deve preservar somente o conhecimento necessário para compreender, validar, continuar, reconciliar ou futuramente especificar a capacidade.

## Brownfield incremental

`DECISAO`

O SK-PE não realizará rewrite documental big-bang.

A reconstrução documental histórica ocorrerá progressivamente quando uma área ou capacidade for tocada, usando a reconciliação:

`AS-INTENDED <-> AS-DOCUMENTED <-> AS-IMPLEMENTED <-> AS-OBSERVED`

Uma divergência não é automaticamente erro. Ela deve ser classificada como decisão, evolução, gap, unknown, dívida documental ou necessidade de reconciliação.

## Contrato mínimo de capacidade

Ao fechar uma capacidade ou gate relevante, registrar quando aplicável:

```text
CAPABILITY_ID=
CAPABILITY_NAME=
INTENT=
SCOPE=
STATUS=

BRANCH=
HEAD=

MIGRATIONS_CREATED=
MIGRATIONS_APPLIED=
TARGET_PROJECT_REF=

TABLES_CHANGED=
VIEWS_CHANGED=
RPCS_CHANGED=
FUNCTIONS_CHANGED=
EDGE_FUNCTIONS_CHANGED=
STORAGE_CHANGED=
AUTH_CHANGED=
FRONTEND_CHANGED=
DEPLOYMENT_CHANGED=

ACCEPTANCE_CRITERIA=
ACCEPTANCE_EVIDENCE=

DECISIONS=
DEPENDENCIES=
OPEN_GAPS=
KNOWN_UNKNOWNS=
RISKS=

DOCUMENTATION_UPDATED=
SPECIFICATION_STATUS=
NEXT_CAPABILITY=
```

Campos não aplicáveis devem ser explicitamente marcados como `N/A`, e desconhecidos como `UNKNOWN`, sem preenchimento por inferência.

## Evidência e fechamento

`DECISAO`

Build, teste, migration aplicada ou contrato estático são evidências técnicas, mas não bastam isoladamente para declarar aceite funcional ou visual.

O fechamento deve distinguir, quando aplicável:

- `TECHNICAL_PASS`;
- `FUNCTIONAL_PASS`;
- `VISUAL_PASS`;
- `DATA_PASS`;
- `SECURITY_PASS`;
- `GOVERNANCE_PASS`;
- `USER_ACCEPTED`.

Uma capacidade só deve ser chamada de fechada no aspecto que efetivamente foi validado.

## Promoção para specification

`DECISAO`

Uma capacidade validada torna-se candidata a specification, mas não é promovida automaticamente.

A promoção deve considerar:

- intenção estabilizada;
- contratos suficientemente claros;
- dados e dependências conhecidos;
- critérios de aceite verificáveis;
- evidências de comportamento real;
- gaps e unknowns explicitados;
- necessidade de autoridade futura para reconstrução ou implementação.

A cadeia transversal de maturidade continua sendo definida pela autoridade Specification-Driven corporativa.

## Sistema de registro crítico e collision gate

`DECISAO`

O projeto Supabase `vumbfpbcozjebomcthdw` deve ser tratado pelo SK-PE como ativo crítico enquanto a governança corporativa de ambientes, backup, recuperação e transição não definir substituição segura.

Este documento não redefine a arquitetura de infraestrutura. Para ações que possam afetar banco destrutivamente, Auth, Storage, Edge Functions, secrets, bindings, backup, restore, ambientes, hosting, Docker, deploy, CI/CD, migrations históricas ou branch governance, o SK-PE deve interromper a execução e aplicar o gate de colisão da governança vigente antes da mudança.

## Migration governance local

`DECISAO`

Toda migration aplicada deve possuir arquivo SQL versionado correspondente e rastreabilidade suficiente para relacionar propósito, branch, target, aplicação, validação e evidência.

Migration já aplicada não deve ser reexecutada por conveniência.

Mudanças destrutivas exigem gate explícito antes da execução.

## Backlog de reconstrução documental

Capacidades históricas podem ser classificadas progressivamente como:

- `CAPABILITY_DOCUMENTED`;
- `CAPABILITY_PARTIALLY_DOCUMENTED`;
- `CAPABILITY_UNDOCUMENTED`;
- `CAPABILITY_REQUIRES_RECONCILIATION`;
- `CAPABILITY_REQUIRES_EVIDENCE`;
- `CAPABILITY_REQUIRES_SPECIFICATION`.

A classificação gera backlog; não obriga interrupção da wave funcional corrente.

## Primeira capacidade sob este contrato

`DECISAO`

A próxima capacidade funcional candidata a operar integralmente sob este modelo é:

`SKPE-MON-ANL-01 — Cockpit de Resultados e Desempenho`

Antes da implementação, deve possuir baseline funcional mínimo de intenção, usuários, decisões suportadas, métricas, visualizações, alertas, drill-downs, fontes de dados, regras de cálculo e critérios de aceite.

Ao final, deve ser reconciliada como `AS-INTENDED`, `AS-IMPLEMENTED` e `AS-OBSERVED`, decidindo-se então seu estágio documental e eventual promoção futura para specification.

## Princípio de produtividade

`DIRETRIZ`

O objetivo não é maximizar documentação. É reduzir redescoberta, regressões semânticas, decisões contraditórias e conhecimento perdido.

`VELOCIDADE + EVIDENCIA + RASTREABILIDADE + APRENDIZAGEM > VELOCIDADE BRUTA SEM MEMORIA`

## Registro contínuo de achados

`DECISAO / DIRETRIZ`

A partir desta governança, todo achado relevante do SK-PE deve ser reconciliado com a autoridade documental adequada. O objetivo é memória governada, não volume documental.

Achados relevantes não devem ser perdidos quando surgirem durante:

- investigação;
- desenvolvimento;
- validação;
- operação;
- UX;
- infraestrutura;
- dados;
- segurança;
- arquitetura;
- roadmap;
- evidências de campo.

Quando aplicável, cada achado deve ser classificado como uma das categorias abaixo:

- `FATO`
- `EVIDENCIA`
- `DECISAO`
- `GAP`
- `UNKNOWN`
- `HISTORICO`
- `RECOMENDACAO`
- `ROADMAP_CHANGE_CANDIDATE`

Antes de criar novo Markdown, procurar a autoridade existente e atualizar essa autoridade quando ela for adequada. Não criar shadow documentation, não duplicar Corporate no DEV e não duplicar DEV no Corporate.

Documentos canônicos ou supporting devem possuir frontmatter coerente com:

- `id`
- `title`
- `domain`
- `type`
- `status`
- `owner`
- `canonicality`
- `parent` e `related`, quando aplicável
- `tags`
- `language`
- `encoding`
- `semantic_layer`
- `created`
- `updated`

Descoberta nova não deve sobrescrever silenciosamente verdade anterior. Quando houver divergência, registrar reconciliação entre:

- `AS-INTENDED`
- `AS-DOCUMENTED`
- `AS-IMPLEMENTED`
- `AS-OBSERVED`

Evidência operacional não vira automaticamente autoridade. Ela deve ser incorporada semanticamente ao documento correto.

## Mineração brownfield de migrations

`DECISAO / DIRETRIZ`

Em capability brownfield, migrations relevantes devem ser tratadas como fonte obrigatória de conhecimento `AS-IMPLEMENTED` antes de propor redesign de schema, novo contrato de dados, nova migration estrutural ou novo modelo físico.

O fluxo mínimo é:

`shortlist textual -> HIGH_VALUE migrations -> extração semântica -> AS-DOCUMENTED / AS-IMPLEMENTED -> reconciliação Corporate -> somente então redesign, se necessário`

A shortlist textual deve localizar candidatos por termos de domínio, objetos, constraints, funções, views, RLS, policies, comentários e vínculos próximos. O filtro `HIGH_VALUE` deve priorizar migrations que materializam tabelas, views, RPCs, triggers, constraints, contratos de lifecycle/status, autorização ou comentários substantivos relacionados à capability.

Migration não vira automaticamente verdade de produto. Ela é evidência de implementação a reconciliar com `AS-INTENDED`, `AS-DOCUMENTED` e `AS-OBSERVED`.

Quando a implementação estiver à frente da documentação, incorporar semanticamente o conhecimento na autoridade Corporate correta. Quando Corporate estiver à frente, manter como intenção ou contrato parcial, sem fingir implementação. Quando houver conflito, registrar explicitamente antes de qualquer redesign.

## Aplicação à baseline de 12/09/2026

A [baseline canônica de estado atual](../current-state.md) registra SOURCE_SHA `d27373cc16740dfc86eb940abf639e322b072cc8`, distingue código/documentação/runtime, mapeia evidências por capability e mantém conflitos/unknowns explícitos. Seu owner é Product; prioridades permanecem no [roadmap](../roadmap.md).

Esta aplicação documental não altera o contrato de governança nem promove este documento supporting para canonical. BASELINED descreve fatos delimitados; CONFLICT/UNKNOWN não recebem SPECIFIED/AUTHORITATIVE. Aceite de runtime exige sua própria evidência. A próxima investigação deve comparar o SHA novo com o SHA da baseline antes de alterar status ou tratar backlog histórico como trabalho ainda não implementado.
