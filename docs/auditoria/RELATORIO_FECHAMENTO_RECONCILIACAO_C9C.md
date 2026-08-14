---
id: SKPE-AUD-C9C-RECONCILIACAO-FECHAMENTO
version: 1.0.0
status: approved
domain: SK-PE
owner: SPARKs PE
roadmap_step: CO-IMPORT-04-C9
canonical_context: SK-PE-CONT-01
created_at: 2026-08-14
updated_at: 2026-08-14
origin: auditoria_controlada_supabase_github
depends_on:
  - docs/auditoria/RELATORIO_FORENSE_MIGRATIONS_C9C_AUSENTES.md
  - supabase/migrations/20260813220018_c9c_key_result_parent_handler.sql
  - supabase/migrations/20260813220033_c9c_register_key_result_parent_handler.sql
  - supabase/migrations/20260814033658_harden_c9c_handler_permissions.sql
---

# Fechamento da Reconciliação C9-C — Supabase × GitHub

## 1. Contexto canônico

Este documento integra a missão **SK-PE-CONT-01 — Continuidade Segura e Fechamento Controlado do SPARKs PE** e registra o encerramento formal da divergência de repositório identificada durante o roadmap `CO-IMPORT-04-C9 — Key Results`.

O relatório forense `RELATORIO_FORENSE_MIGRATIONS_C9C_AUSENTES.md` deve ser preservado como fotografia histórica do estado anterior à correção. Este termo não apaga nem reescreve aquela evidência; ele registra o estado posterior, já reconciliado.

## 2. Problema originalmente identificado

Foram identificadas no Supabase remoto duas migrations C9-C que não estavam persistidas no repositório Git:

- `20260813220018_c9c_key_result_parent_handler.sql`
- `20260813220033_c9c_register_key_result_parent_handler.sql`

A causa raiz foi classificada como **R3 — SQL executado diretamente no Supabase sem arquivo de migration persistido no repositório**.

O marcador de controle adotado foi:

`C9_BLOCKER_REPOSITORY_DRIFT`

Enquanto esse marcador estivesse aberto, o Gate `CO-IMPORT-04-C9-E — Governed Materialization de Key Results` deveria permanecer bloqueado.

## 3. Reconciliação executada

A reconciliação foi materializada no commit:

`534a4d4c765a0ae8a7eda4c77538ce4207f1ee94`

Mensagem:

`fix(skpe): reconcile C9-C migrations and harden handlers`

Branch:

`feature/formulacao-estrategica-operacional`

Repositório:

`rrgestao/skpe-saas`

O commit restaurou no GitHub os SQLs históricos recuperados da metadata do Supabase e acrescentou hardening forward-only pré-C9-E.

## 4. Arquivos reconciliados

### 4.1 Migration histórica C9-C — handler de parent resolution

`supabase/migrations/20260813220018_c9c_key_result_parent_handler.sql`

Responsabilidade:

- resolver deterministicamente o Key Result a partir do código do KR e do OKR pai informado na origem;
- exigir o OKR pai materializado no mesmo projeto e formulação;
- derivar o Objetivo Estratégico exclusivamente pela relação primária canônica do OKR;
- manter `semantic_inference = false`;
- bloquear ou encaminhar para revisão quando o pai não puder ser resolvido deterministicamente.

### 4.2 Migration histórica C9-C — registro e dispatcher

`supabase/migrations/20260813220033_c9c_register_key_result_parent_handler.sql`

Responsabilidade:

- registrar `key_result_parent_okr_candidate` no catálogo de handlers;
- declarar o contrato de entrada e saída;
- registrar `allows_semantic_inference = false`;
- conectar o handler ao dispatcher canônico de resolução.

### 4.3 Hardening forward-only pré-C9-E

`supabase/migrations/20260814033658_harden_c9c_handler_permissions.sql`

Responsabilidade:

- remover execução de handlers internos por `PUBLIC`, `anon` e `authenticated`;
- conceder execução desses handlers somente a `service_role`;
- retirar acesso anônimo indevido de `set_my_module_preference`;
- preservar acesso da preferência pessoal para `authenticated` e `service_role`.

## 5. Validação de equivalência Supabase × repositório local

Em 2026-08-14 foi executado:

`npx supabase migration list`

A listagem confirmou equivalência **Local = Remote** para todo o histórico exibido, inclusive:

- `20260813220018` = `20260813220018`
- `20260813220033` = `20260813220033`
- `20260814033658` = `20260814033658`

Também foi verificado:

- branch local: `feature/formulacao-estrategica-operacional`;
- branch alinhada a `origin/feature/formulacao-estrategica-operacional`;
- working tree limpo no momento da verificação;
- HEAD local antes deste termo: `534a4d4c765a0ae8a7eda4c77538ce4207f1ee94`.

## 6. Validação GitHub

O commit `534a4d4c765a0ae8a7eda4c77538ce4207f1ee94` foi confirmado no repositório `rrgestao/skpe-saas` contendo:

- relatório forense original;
- as duas migrations históricas restauradas;
- a migration de hardening pré-C9-E.

Os SQLs versionados correspondem ao mecanismo C9-C já validado funcionalmente no Supabase.

## 7. Estado do blocker

Classificação final:

- marcador: `C9_BLOCKER_REPOSITORY_DRIFT`
- estado técnico: **RESOLVIDO**
- estado documental: **RESOLVIDO por este termo de fechamento**
- severidade residual: **nenhuma para abertura do C9-E**
- reabertura automática: somente se nova evidência demonstrar divergência entre migrations versionadas, estado remoto ou semântica de execução.

## 8. Gates e baseline

Estado consolidado do roadmap:

- `C9-A — Contract Discovery`: concluído com reservas
- `C9-B — Source Mapping`: concluído com reservas
- `C9-C — Parent Resolution`: **PASS**
- `C9-D — Eligibility`: **PASS**
- `C9-E — Governed Materialization`: **LIBERADO PARA IMPLEMENTAÇÃO CONTROLADA**

O fechamento deste blocker **não reabre C8 nem altera os contratos aprovados** de resolução, elegibilidade, proveniência, idempotência ou separação entre incorporação técnica e validação institucional.

## 9. Invariantes preservadas para o C9-E

O C9-E deve preservar, no mínimo:

- aprovação não equivale a resolução;
- validação técnica não equivale a materialização;
- similaridade textual não cria relacionamento;
- elegibilidade não equivale a validação institucional;
- `semantic_inference` permanece `false`;
- KR sem OKR pai deterministicamente resolvido não pode ser materializado;
- o KR-01 é o controle positivo elegível;
- o KR-02 é o controle negativo e deve permanecer não materializado enquanto `requires_review/unresolved`;
- nenhuma duplicação de entidade, mecanismo ou contrato é permitida;
- qualquer alteração posterior deve permanecer reprodutível por migration versionada antes do fechamento do respectivo Gate.

## 10. Decisão de passagem

**DECISÃO: C9_BLOCKER_REPOSITORY_DRIFT ENCERRADO.**

**GATE: CO-IMPORT-04-C9-E LIBERADO.**

Próximo passo canônico:

`CO-IMPORT-04-C9-E — Governed Materialization de Key Results`

A implementação deve iniciar pela inspeção do dispatcher de materialização governada, do materializer de OKR e do workflow de decisão de incorporação, sem criar estruturas paralelas e sem usar o `upsert_skpe_key_result` operacional de forma incompatível com o contrato histórico.
