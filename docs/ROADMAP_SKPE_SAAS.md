---
id: skpe-operational-roadmap
title: Roadmap operacional do SKPE-SAAS
domain: products
type: roadmap
status: active
owner: dev
canonicality: supporting
canonical: false
criticality: high
parent:
  - sk-pe-master-roadmap
related:
  - sk-pe-product-hub
  - sk-pe-capability-execution-and-traceability
tags:
  - sk-pe
  - skpe-saas
  - roadmap
  - dev
  - execution
language: pt-BR
encoding: UTF-8
semantic_layer: product-operational-execution
created: 2026-09-07
updated: 2026-09-14
---

# Roadmap operacional — SKPE-SAAS

## Autoridade

Owner: DEV / Ricardo.

Repositório: `sparkooptech/skpe-saas`.

Branch canônica de desenvolvimento: `feature/formulacao-estrategica-operacional`.

Este documento é o roadmap operacional do repositório executável. Ele orienta execução técnica, gates, validações, branches, releases, blockers e dependências de implementação.

## Roadmap mestre

Roadmap mestre Corporate: `br-robson/projetos`.

Path: `docs/products/sk-pe/roadmap.md`.

Mirror governado local de referência: `docs/corporate/sk-pe/README.md`.

Matriz de reconciliação vigente: `docs/corporate/sk-pe/RECONCILIATION-2026-09-13.md`.

O mirror local não substitui a autoridade Corporate e não deve ser editado como fonte de verdade.

O roadmap Corporate define:

- prioridade;
- épicos;
- outcomes;
- escopo de produto;
- capabilities;
- status de produto;
- dependências de alto nível.

Este roadmap DEV define:

- como executar;
- em que ordem;
- com quais gates;
- dependências técnicas;
- blockers;
- migrations;
- validações;
- releases.

Este documento não redefine prioridade de produto, nova capability, mudança de escopo ou repriorização estrutural. Quando uma dessas necessidades aparecer, registrar `ROADMAP_CHANGE_CANDIDATE`.

## Estado técnico atual

Conforme GOV-20.1:

| Frente | Status | Implicação operacional |
| --- | --- | --- |
| P1 — Sincronização Robson/Ricardo | DONE | Repositório e branch canônica estão definidos. |
| P2 — DNS / entrada pública | DONE | `sparks.sparkoop.com` possui evidência Corporate de entrada pública. |
| P3 — Configuração Traefik do SKPE-PAAS | DONE | Traefik é componente existente; configuração SKPE-PAAS está versionada e alinhada ao runtime observado. |
| P4 — Deployment / hostname / HTTPS | DONE | HTTPS e rotas principais possuem evidência Corporate suficiente. |
| P5 — Remoção de acesso temporário | STILL_VALID | Remoção depende de evidência de que o mecanismo temporário ainda existe e pode ser encerrado com segurança. |
| P6 — Auditoria de trabalho local | DONE | Trabalho local/preserve foi classificado nos gates de reconciliação. |
| P7 — Higienização da estação | PARTIAL | Classificação foi concluída; limpeza física não deve ser presumida como concluída. |

O roadmap histórico/local anterior não deve ser restaurado literalmente. Esta versão substitui as premissas antigas de `origin/main` como fonte canônica pela branch `feature/formulacao-estrategica-operacional`.

## Próximos gates

### CURRENT

- Manter este roadmap operacional linkado ao roadmap mestre Corporate.
- Usar a branch canônica `feature/formulacao-estrategica-operacional` como base de novas frentes de desenvolvimento.
- Consultar os documentos da capability antes de abrir gates substantivos.

### NEXT

- Tratar P5: validar se o acesso temporário ainda existe e, se existir, propor remoção controlada sem alterar runtime neste documento.
- Tratar P7: planejar higienização física de branches, worktrees e diretórios temporários com preservação explícita de trabalho legítimo.
- Reconciliar qualquer diferença entre execução técnica e roadmap mestre por `ROADMAP_CHANGE_CANDIDATE`.
- Consolidar a Jornada Estratégica com semântica coerente entre agregadores, itens executáveis, gates, eventos, prazo e progresso, preservando contexto após atualizações.

### LATER

- Definir gates operacionais para releases, validações e eventuais migrations somente quando uma capability ou decisão Product/Corporate exigir.
- Separar trilhas de infraestrutura, HOMOL/PRD, backups, storage e observabilidade quando houver decisão de produto e evidência operacional suficiente.
- Realizar um banho de loja no Orçamento das Iniciativas, cobrindo UX, estrutura de lançamentos, leitura gerencial, orçamento × realizado, esforço, navegação, responsividade e coerência visual com o restante da Plataforma SPARKs.

### DIRETRIZ VISUAL TRANSVERSAL APROVADA — 2026-09-14

- Usar tons de verde-água derivados do menu principal como base visual transversal para grids, botões, tabs, seleção, hover e controles.
- Reservar o laranja já adotado para destaque, ação principal, alerta ou ênfase contextual.
- Evitar novas variações cromáticas locais sem justificativa funcional.
- O refinamento estético completo permanece para a fase final de acabamento, mas novas correções devem respeitar esta direção desde já.

### ROADMAP_CHANGE_CANDIDATE — ORÇAMENTO DAS INICIATIVAS

- Contexto: a capability econômica da iniciativa já existe tecnicamente, porém a experiência atual ainda não alcança o padrão desejado de gestão e usabilidade.
- Motivo: consolidar uma experiência executiva clara para planejamento, lançamentos, orçamento × realizado, esforço e leitura gerencial sem confundir a funcionalidade com contabilidade corporativa.
- Impacto no produto: evolução de UX e capacidade gerencial da iniciativa; não altera, por si só, a fronteira conceitual de que o módulo não substitui sistemas contábeis/financeiros.
- Impacto técnico: revisão do workspace econômico, componentes, fluxos de lançamento, visualizações e integração com os dados já existentes.
- Recomendação DEV: manter esta frente em LATER e retomá-la após estabilização conceitual da Jornada Estratégica.
- Decisão solicitada ao Corporate: incorporar esta evolução ao roadmap mestre do SK-PE.

### BLOCKED

- Qualquer nova capability, mudança de prioridade, mudança estrutural de escopo ou decisão de produto não aprovada pelo roadmap mestre.
- Qualquer migration, alteração Supabase, hosting, DNS ou runtime sem gate específico e autorização explícita.

## ROADMAP_CHANGE_CANDIDATE

DEV não transforma mudança relevante em verdade de produto silenciosamente.

Quando necessário:

`ROADMAP_CHANGE_CANDIDATE -> Product/Corporate decide -> roadmap mestre e roadmap operacional são reconciliados`.

Um `ROADMAP_CHANGE_CANDIDATE` deve registrar:

- contexto;
- motivo;
- impacto no produto;
- impacto técnico;
- recomendação DEV;
- decisão solicitada.

Enquanto não houver decisão Product/Corporate, o candidate não altera prioridade, escopo, capability ou outcome do produto.

## Regra para ChatGPT / PS1

Antes de gerar novo gate substantivo:

1. validar branch e HEAD;
2. consultar este roadmap operacional;
3. consultar documentos da capability;
4. respeitar o roadmap mestre Corporate;
5. sinalizar divergência;
6. registrar `ROADMAP_CHANGE_CANDIDATE` quando aplicável;
7. preservar worktree dirty;
8. não reexecutar migrations aplicadas;
9. não fazer commit/push automático sem autorização;
10. qualquer mudança relevante encontrada em `rrgestao/skpe-saas` ou outro repositório/branch fora da linha DEV aprovada deve gerar alerta explícito antes de ser considerada para incorporação;
11. mudanças externas com impacto de produto seguem `ALERTA -> COMPARACAO -> IMPACTO -> RECOMENDACAO -> DECISAO ROBSON -> INCORPORACAO OU REJEICAO`.

## Links de autoridade

- Roadmap mestre Corporate: `br-robson/projetos:docs/products/sk-pe/roadmap.md`.
- Roadmap operacional DEV: `sparkooptech/skpe-saas:docs/ROADMAP_SKPE_SAAS.md`.
- Branch canônica DEV: `feature/formulacao-estrategica-operacional`.
