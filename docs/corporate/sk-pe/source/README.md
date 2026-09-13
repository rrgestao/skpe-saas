---
id: sk-pe-product-hub
title: SK-PE no NEXUS Knowledge Vault
domain: products
type: hub
status: canonical
owner: product
canonicality: canonical
canonical: true
criticality: high
parent:
  - products-hub
related:
  - skpe-fund-neg-01
  - skpe-ident-01
  - skpe-form-ver-01
  - sk-pe-business-rules-hub
  - skpe-med-des-01
  - sk-pe-master-roadmap
  - sk-pe-current-state
  - sk-pe-capability-execution-and-traceability
  - skpe-mon-anl-01-cockpit-resultados-desempenho
  - specification-driven-architecture-hub
  - sparkoop-infrastructure-operations-governance
tags:
  - sk-pe
  - sparks-pe
  - product
  - planning
  - strategy
  - vault
language: pt-BR
encoding: UTF-8
semantic_layer: canonical-product-space
created: 2026-09-06
updated: 2026-09-12
lineage:
  - repository: br-robson/projetos
    source_sha: 2915073884fefa1a7bd98a7775df5f37a5f85ec9
    path: docs/products/sk-pe/README.md
  - ./current-state.md
---

# SK-PE no NEXUS Knowledge Vault

## Parent Links

- [[products-hub]]

## Child Links

### Governança

- [[sk-pe-capability-execution-and-traceability]]

### Capacidades

- [[skpe-mon-anl-01-cockpit-resultados-desempenho]] — primeira capability sob o novo contrato de execução e rastreabilidade incremental

## Related Links

- [[specification-driven-architecture-hub]]
- [[sparkoop-infrastructure-operations-governance]]

## Papel do SK-PE no vault

O `SK-PE / SPARKs PE` passa a possuir product space documental governado em `docs/products/sk-pe/`.

Este espaço é a casa canônica do conhecimento específico do produto, de suas capacidades, decisões, evidências, gaps, reconciliações brownfield e futuras specifications.

Ele não duplica arquitetura transversal, infraestrutura corporativa ou padrões corporativos. Esses assuntos permanecem sob seus owners próprios e são apenas referenciados pelo produto.

## Fronteira de autoridade

A hierarquia é:

`ECOSYSTEM / CORPORATE STANDARDS -> SK-PE PRODUCT SPACE -> IMPLEMENTACAO`

A implementação executável não redefine, sozinha, a autoridade documental do produto.

A documentação do SK-PE também não redefine, sozinha, padrões corporativos de arquitetura, infraestrutura, segurança, ambientes, storage, Auth, deployment ou Specification-Driven Architecture.

## Ambiente publicado — registro histórico de 11/09/2026

O ambiente público comprovado do SK-PE é **HOMOL**.

Estado registrado em 2026-09-11 (runtime atual tratado na baseline):

- URL canônica de HOMOL: `https://sparks-homol.sparkoop.com`
- ambiente: `HOMOL`
- source SHA: `3f2f25cf02d887b878ac1ee8e9b04724c0fef4f3`
- imagem: `skpe-saas-homol:3f2f25c`
- validação técnica de deploy: `PASS`
- cutover DNS/Traefik/TLS: `PASS`
- aceitação visual/autenticação interativa: `PENDING`

O endereço `https://sparks.sparkoop.com` permanece temporariamente funcional como fallback após o cutover. Seu destino futuro não está definido e não deve ser reinterpretado automaticamente como PRD.

A autoridade sobre topologia, DNS, runtime e deployment permanece em `docs/ecosystem/infrastructure/`. Este registro de produto apenas referencia o ambiente vigente e não duplica sua especificação operacional.

## Adoção Specification-Driven

O SK-PE adota explicitamente a fundamentação transversal localizada em `docs/ecosystem/architecture/specification-driven/`.

A adoção é brownfield e incremental. Não há rewrite documental big-bang.

A cadeia local de execução e aprendizagem é governada por [[sk-pe-capability-execution-and-traceability]].


## Baseline atual do produto — 12/09/2026

- [Estado atual e baseline conceitual](current-state.md): SOURCE_SHA `d27373cc16740dfc86eb940abf639e322b072cc8`, branch `feature/formulacao-estrategica-operacional`, investigação em `2026-09-12`.
- [Roadmap mestre](roadmap.md): prioridades e próximo bloco; [Medidas e Desempenho](capabilities/SKPE-MED-DES-01-medidas-desempenho.md) e [Cockpit](capabilities/SKPE-MON-ANL-01-cockpit-resultados-desempenho.md): owners das respectivas semânticas.
- [Governança](governance/capability-execution-and-traceability.md): regras de execução, evidência e promoção.
- [Arquitetura funcional e fontes](current-state.md#arquitetura-funcional-atual): mapa do produto no SHA; [fundamentação transversal](../../ecosystem/architecture/specification-driven/README.md): autoridade arquitetural federada.

`BASELINE_STATUS=BASELINED_WITH_EXPLICIT_CONFLICTS_AND_UNKNOWNS`. Código, documentação e runtime possuem revisões distintas. HOMOL respondeu HTTP 200 em shell/health; deployment `d27373cc16740dfc86eb940abf639e322b072cc8` foi declarado pelo usuário, mas seu SHA não foi verificado em runtime. O registro de 11/09 acima é preservado como histórico documental, não como consulta atual.

Último ponto investigado: frontend RAE no HEAD indicado. Próximo bloco mantém Medidas → Cockpit → gaps de Formulação, com decisões pendentes explicitadas na baseline. Não há declaração de SPEC-AS-AUTHORITY ou SPEC-AS-SOURCE.

## Estado atual

O SK-PE está em evolução funcional acelerada e passa a reconstruir sua autoridade documental progressivamente a partir do estado real observado.

O produto deve distinguir:

- intenção;
- documentação;
- implementação;
- observação;
- evidência;
- decisão;
- gap;
- unknown;
- specification futura.

## Primeira capacidade sob o novo contrato

A primeira capacidade funcional executada integralmente sob o novo modelo é:

[[skpe-mon-anl-01-cockpit-resultados-desempenho]] — `SKPE-MON-ANL-01 — Cockpit de Resultados e Desempenho`.

## AI Navigation Readiness

IA deve tratar `docs/products/sk-pe/` como a casa documental governada do `SK-PE`, preservando a fronteira entre conhecimento de produto, standards corporativos e implementação executável.

## Catálogo funcional e regras de negócio

[Índice de regras do produto](business-rules/README.md): piloto de Medidas, com funcionalidades, regras, fontes, autoridade e decisões pendentes no owner da capability.

## Formulação e Versionamento

[Owner funcional B10](capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md) · [Regras e evidências](business-rules/formulacao-versionamento.md). Aprofundamento da mesma baseline; conflitos preservados, sem alteração da prioridade de implementação.

## Identidade Estratégica

[Owner funcional B11](capabilities/SKPE-IDENT-01-identidade-estrategica.md) · [Regras e metodologia](business-rules/identidade-estrategica.md). Mesma baseline, sem mudança de prioridades ou aceite; conflitos preservados.

## Fundamentação do Negócio, Canvas e Cadeia de Valor

[Owner funcional B12](capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md) · [Regras de Fundamentação](business-rules/fundamentacao-negocio.md). Contratos compartilhados e legados distinguidos; mesma baseline e conflitos abertos, sem promoção de aceite.
