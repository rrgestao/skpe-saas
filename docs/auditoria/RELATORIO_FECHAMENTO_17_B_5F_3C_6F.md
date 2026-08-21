---
id: SKPE-AUD-17-B-5F-3C-6F-FECHAMENTO
version: 1.0.0
status: approved
domain: SPARKs PaaS
owner: SPARKs PE
roadmap_step: 17-B.5F.3C.6F
canonical_context: SK-PE-CONT-01
created_at: 2026-08-21
updated_at: 2026-08-21
origin: implementacao_governada_supabase_github
technical_commit: d1ffe7225bd80d31785b66a8d1a9d3c942ab6e72
depends_on:
  - supabase/migrations/20260821094420_govern_sparks_initiative_action_operations.sql
  - supabase/migrations/20260821121758_govern_sparks_initiative_action_responsibilities.sql
  - supabase/migrations/20260821132910_govern_sparks_initiative_action_rollup.sql
---

# Fechamento Tecnico 17-B.5F.3C.6F — Roll-up Governado de Progresso e Saude

## 1. Contexto

Este documento integra a missao **SK-PE-CONT-01 — Continuidade Segura e Fechamento Controlado do SPARKs PE** e formaliza o encerramento do gate `17-B.5F.3C.6F — Roll-up Governado de Progresso e Saude`.

O gate estabelece uma projecao derivada, explicavel e somente leitura do progresso e da saude de iniciativas a partir de `sparks_initiative_actions`, sem substituir a autoridade organizacional de `sparks_initiatives.progress` e `sparks_initiatives.health_status`.

Projeto Supabase:

- projeto: `skpe-saas-dev`;
- project ref: `vumbfpbcozjebomcthdw`.

Repositorio canonico:

- repositorio: `rrgestao/skpe-saas`;
- branch: `feature/formulacao-estrategica-operacional`.

## 2. Decisoes arquiteturais congeladas

O `6F` preserva:

- `sparks_initiatives.progress` como progresso organizacional oficial;
- `sparks_initiatives.health_status` como saude organizacional oficial;
- roll-up derivado e somente leitura;
- nenhuma mutacao automatica action -> initiative;
- politica V1 `equal_weight`;
- hierarquia bottom-up;
- somente roots contribuindo ao agregado da iniciativa;
- exclusao de `cancelled` e `archived`;
- milestones usando o mesmo contrato de progresso das actions;
- responsabilidades, custo, esforco e prioridade fora da ponderacao;
- ausencia de logica temporal propria do `6H`.

## 3. Migration

Migration:

`20260821132910_govern_sparks_initiative_action_rollup.sql`
SHA256 congelado:

`E38AB0A8110D632822A4AE1515F2C2219C15F03DB1F6414EE88AD4649EFD31E4F`

O historico remoto do Supabase confirma:

- version: `20260821132910`;
- name: `govern_sparks_initiative_action_rollup`.

**MIGRATION HISTORY = PASS.**

### Evidencia de integridade da migration

O arquivo canonico da migration foi validado localmente por SHA256.

Migration:

`supabase/migrations/20260821132910_govern_sparks_initiative_action_rollup.sql`

SHA256:

`E38AB0A8110D632822A4E1515F2C2219C15F03DB1F6414EE88AD4649EFD31E4F`

Resultado:

**MIGRATION FILE INTEGRITY = PASS.**

## 4. Contratos aprovados

Foram materializadas:

- `sparks_calculate_initiative_action_rollup_internal(uuid, uuid[])`;
- `get_sparks_initiative_action_rollup(uuid)`;
- `get_sparks_initiative_rollup(uuid)`.

As funcoes sao `STABLE`, `SECURITY DEFINER` e usam `search_path` endurecido.

Superficie live validada:

- helper interno: `authenticated = false`, `anon = false`, `service_role = true`;
- projecao por action: `authenticated = true`, `anon = false`, `service_role = true`;
- projecao consolidada: `authenticated = true`, `anon = false`, `service_role = true`.

**CONTRACT / PRIVILEGES = PASS.**

## 5. Politica de roll-up

A politica deterministica e:

1. folha elegivel usa seu `progress` oficial;
2. pai com filhos elegiveis usa media simples dos filhos;
3. calculo recursivo bottom-up;
4. `cancelled` e `archived` nao contribuem;
5. somente roots elegiveis entram no agregado da iniciativa;
6. ausencia de roots elegiveis gera `calculatedProgress = null`;
7. progresso calculado permanece separado do progresso oficial;
8. `progressVariance = calculatedProgress - officialProgress` quando aplicavel.

Existe guarda recursiva contra ciclo inesperado de hierarquia.

## 6. Saude derivada V1

A saude derivada permanece separada da saude oficial:

- iniciativa `completed` -> `completed`;
- nenhuma action elegivel -> `not_assessed`;
- qualquer action elegivel `blocked` -> `critical`;
- senao, qualquer action elegivel `on_hold` -> `attention`;
- demais casos -> `on_track`.

Nao utiliza atraso, baseline, forecast ou caminho critico.

## 7. Validacao comportamental

O harness controlado validou:

- hierarquia bottom-up;
- roots-only no agregado;
- exclusao de `cancelled` e `archived`;
- milestones pelo mesmo contrato;
- `critical` com action elegivel bloqueada;
- `null / not_assessed` sem actions elegiveis;
- separacao progresso oficial x calculado;
- nenhuma mutacao automatica de progresso, lifecycle ou saude oficiais.

A execucao foi transacional, finalizada com rollback e zero residuos.

**BEHAVIORAL = PASS.**

**ROLLBACK CLEANUP = PASS.**

**ZERO RESIDUOS = PASS.**

## 8. Lint pos-DDL

Foi executado:

`npx --no-install supabase db lint --linked --schema public --level warning`

O lint global do schema `public` apresentou findings em funcoes preexistentes, incluindo erros de relacao temporaria inexistente, referencias ambiguas, dependencia de funcao ausente, coluna inexistente e outros warnings legados.

Nenhum finding retornado referencia as funcoes introduzidas pelo `6F`:

- `sparks_calculate_initiative_action_rollup_internal`;
- `get_sparks_initiative_action_rollup`;
- `get_sparks_initiative_rollup`.

Portanto, nao se declara o schema global como limpo.

O registro correto e:

**LINT 6F = SEM FINDINGS PROPRIOS IDENTIFICADOS.**

Os findings globais permanecem passivo tecnico separado, fora do escopo deste gate.

## 9. Versionamento Git

Commit tecnico:

`d1ffe7225bd80d31785b66a8d1a9d3c942ab6e72`

Mensagem:

`feat(platform): govern initiative action rollup`

O commit tecnico contem exclusivamente:

`supabase/migrations/20260821132910_govern_sparks_initiative_action_rollup.sql`

A branch remota foi confirmada exatamente nesse checkpoint antes do fechamento documental.

**GIT RECONCILIATION = PASS.**

## 10. Invariantes preservadas

Permanecem preservadas:

- autoridade oficial de progresso da iniciativa;
- autoridade oficial de saude da iniciativa;
- nenhuma escrita automatica action -> initiative;
- nenhuma fonte de verdade concorrente;
- nenhuma ponderacao por responsabilidade, custo, esforco ou prioridade;
- nenhuma sincronizacao automatica `skpe_* <-> sparks_*`;
- nenhum objeto Kanban persistente;
- nenhuma logica Gantt/baseline/desvio;
- nenhuma agenda/evento transversal;
- nenhum roll-up economico.

## 11. Fronteiras dos gates seguintes

Permanecem fora do `6F`:

- `6G` — Projecao Kanban Transversal;
- `6H` — Gantt, Baseline e Desvio Temporal;
- `6I` — Agenda, Calendario e Eventos Operacionais;
- `6J` — Custos, Esforco e Controle Economico.

Nenhum desses gates foi antecipado pelo `6F`.

## 12. Estado final

- estrutural: **PASS**;
- contratos/privilegios: **PASS**;
- migration history: **PASS**;
- comportamental: **PASS**;
- rollback/cleanup: **PASS**;
- zero residuos: **PASS**;
- lint do escopo `6F`: **PASS**, sem findings proprios identificados;
- reconciliacao Supabase x Git: **PASS**.

**GATE: 17-B.5F.3C.6F — PASS / CLOSED.**

Proximo gate canonico:

**17-B.5F.3C.6G — Projecao Kanban Transversal — OPEN.**

`6H`, `6I` e `6J` permanecem **NOT OPEN**.

A continuidade permanece subordinada a **SK-PE-CONT-01 — Continuidade Segura e Fechamento Controlado do SPARKs PE**.