---
id: SKPE-AUD-17-B-5F-3C-6E-FECHAMENTO
version: 1.0.0
status: approved
domain: SPARKs PaaS
owner: SPARKs PE
roadmap_step: 17-B.5F.3C.6E
canonical_context: SK-PE-CONT-01
created_at: 2026-08-21
updated_at: 2026-08-21
origin: implementacao_governada_supabase_github
technical_commit: c38ac2e513aff98463d33dfe77edc1ab56e103ff
depends_on:
  - supabase/migrations/20260821022449_sparks_initiative_actions_governance_foundation.sql
  - supabase/migrations/20260821024153_harden_sparks_initiative_actions_foundation.sql
  - supabase/migrations/20260821094420_govern_sparks_initiative_action_operations.sql
  - supabase/migrations/20260821095209_harden_sparks_initiative_action_structural_update.sql
  - supabase/migrations/20260821110805_harden_sparks_initiative_action_parent_lifecycle.sql
  - supabase/migrations/20260821121758_govern_sparks_initiative_action_responsibilities.sql
---

# Fechamento Tecnico 17-B.5F.3C.6E — Responsabilidades Governadas em Acoes

## 1. Contexto

Este documento integra a missao **SK-PE-CONT-01 — Continuidade Segura e Fechamento Controlado do SPARKs PE** e formaliza o encerramento do gate `17-B.5F.3C.6E — Responsabilidades Governadas em Acoes`.

O gate sucede `17-B.5F.3C.6D — Operacao Governada de Lifecycle e Execucao de Acoes` e estabelece responsabilidades pessoais sobre `sparks_initiative_actions` sem criar campo concorrente de responsavel pessoal na acao e sem duplicar a autoridade transversal `public.sparks_responsibility_assignments`.

Projeto Supabase:

- projeto: `skpe-saas-dev`;
- project ref: `vumbfpbcozjebomcthdw`.

Repositorio canonico:

- repositorio: `rrgestao/skpe-saas`;
- branch: `feature/formulacao-estrategica-operacional`.

## 2. Objetivo do gate

O objetivo do `6E` foi tornar governada a atribuicao, leitura e encerramento de responsabilidades pessoais associadas a acoes transversais de iniciativas.

A autoridade permaneceu:

`public.sparks_responsibility_assignments`.

A vinculacao canonica aprovada para acoes e:

- `object_type = 'initiative_action'`;
- `object_id = sparks_initiative_actions.id`;
- `module_code` herdado de `sparks_initiative_actions.source_module_code`.

O campo `sparks_initiative_actions.responsible_area_id` continua representando area organizacional e nao foi convertido em responsabilidade pessoal.

## 3. Migration executada

Migration:

`20260821121758_govern_sparks_initiative_action_responsibilities.sql`

SHA256:

`F46300B4A3E0295D2B09E21C0350255BE1B68DBAAF157884D61A05770AC3DCD4`

A migration:

- removeu `INSERT`, `UPDATE` e `DELETE` diretos de `authenticated` sobre `sparks_responsibility_assignments`;
- preservou `SELECT` sujeito a RLS;
- removeu a policy de mutacao direta;
- endureceu a superficie de RPCs legadas;
- reservou `initiative_action` ao contrato governado do `6E`;
- impediu bypass por RPCs genericas ou legadas;
- criou contratos especificos de atribuicao, encerramento e leitura.

## 4. Contratos aprovados

Foram estabelecidas as RPCs:

- `assign_sparks_initiative_action_responsibility(...)`;
- `end_sparks_initiative_action_responsibility(...)`;
- `get_sparks_initiative_action_responsibilities(...)`.

A autorizacao de mutacao deriva da autoridade da iniciativa/acao:

`can_manage_sparks_initiatives(organization_id, source_module_code)`.

A atribuicao valida:

- usuario autenticado;
- existencia da acao;
- lifecycle nao terminal;
- organizacao;
- pessoa com vinculo organizacional ativo;
- tipo de responsabilidade;
- percentual de alocacao;
- nivel de autoridade quando informado;
- vigencia;
- justificativa;
- duplicidade ativa.

O encerramento valida:

- existencia da atribuicao;
- vinculacao a uma `initiative_action`;
- escopo organizacional e modular;
- autorizacao;
- coerencia da data final;
- justificativa.

## 5. Hardening da autoridade transversal

O preflight identificou que `authenticated` possuia DML direto sobre `sparks_responsibility_assignments`.

Estado inicial:

- SELECT = true;
- INSERT = true;
- UPDATE = true;
- DELETE = true;
- mutation policy count = 1.

Apos o `6E`:

- SELECT = true;
- INSERT = false;
- UPDATE = false;
- DELETE = false;
- mutation policy count = 0.

Assim, a mutacao da autoridade transversal passou a ocorrer exclusivamente por contratos governados.

## 6. Hardening de bypass legado

Foi identificado que as RPCs:

- `assign_sparks_responsibility(...)`;
- `assign_skpe_responsibility(...)`;
- `end_skpe_responsibility(...)`;

poderiam operar sobre `object_type = 'initiative_action'` sem respeitar o contrato especifico do `6E`.

O hardening preservou essas RPCs para objetos legados compativeis, mas passou a rejeitar:

- `initiative_action`;
- `sparks_initiative_action`.

Responsabilidades de acoes transversais passaram a ser operadas exclusivamente pelas RPCs especificas do `6E`.

## 7. Superficie de privilegios

A validacao live confirmou:

- `authenticated` possui apenas `SELECT` na tabela transversal;
- `authenticated` nao possui DML direto;
- nao existe policy de mutacao;
- as tres RPCs novas existem;
- `anon` nao possui `EXECUTE` nas RPCs legadas endurecidas.

Resultado:

**STRUCTURAL / HARDENING = PASS.**

## 8. Teste comportamental

Como `sparks_initiative_actions` estava inicialmente sem registros no ambiente dev, o primeiro harness foi corretamente bloqueado por ausencia de fixture.

Foi entao utilizada a iniciativa real:

- codigo: `PE-COOTAQUARA-2026`;
- modulo: `SK-PE`;
- status: `in_progress`.

O harness V2 criou uma acao temporaria exclusivamente pela RPC governada do `6D`:

`create_sparks_initiative_action(...)`.

Sobre essa acao temporaria, o teste validou:

- criacao governada da acao;
- atribuicao positiva de responsabilidade pelo `6E`;
- heranca de organizacao e modulo;
- leitura governada;
- rejeicao de duplicidade ativa;
- bloqueio de bypass via `assign_sparks_responsibility`;
- bloqueio de bypass via `assign_skpe_responsibility`;
- rejeicao de pessoa fora da organizacao;
- rejeicao de usuario nao autorizado;
- bloqueio de encerramento via `end_skpe_responsibility`;
- encerramento positivo pela RPC especifica do `6E`;
- separacao entre leitura ativa e historica;
- ausencia de alteracao automatica de status da iniciativa;
- ausencia de alteracao automatica de progresso da iniciativa;
- auditoria de atribuicao;
- auditoria de encerramento.

O teste foi executado integralmente dentro de transacao e finalizado com `ROLLBACK`.

Resultado pos-rollback:

- `rollback_cleanup = PASS`;
- `action_residuals = 0`;
- `responsibility_residuals = 0`;
- `audit_residuals = 0`.

Resultado:

**BEHAVIORAL = PASS / ROLLBACK CLEANUP = PASS / ZERO RESIDUOS.**

## 9. Migration history

Antes da aplicacao:

`20260821121758 | [remote vazio]`

O `db push --dry-run --linked` confirmou que somente a migration `20260821121758` seria aplicada.

Apos a aplicacao:

`20260821121758 | 20260821121758`

Resultado:

**MIGRATION HISTORY = PASS.**

## 10. Advisor

O advisor pos-DDL foi executado.

Os avisos exibidos no retorno analisado foram de categoria `PERFORMANCE`, principalmente `multiple_permissive_policies` em tabelas preexistentes.

Nao foi identificado no retorno analisado finding novo associado a:

- `sparks_responsibility_assignments`;
- `sparks_initiative_actions`;
- RPCs especificas do `6E`.

Esses avisos de performance permanecem fora do escopo deste gate e nao devem ser silenciosamente incorporados ao `6E`.

## 11. Versionamento Git

Commit tecnico:

`c38ac2e513aff98463d33dfe77edc1ab56e103ff`

Mensagem:

`feat(platform): govern initiative action responsibilities`

O commit contem exclusivamente:

`supabase/migrations/20260821121758_govern_sparks_initiative_action_responsibilities.sql`

Apos o push:

- LOCAL = `c38ac2e513aff98463d33dfe77edc1ab56e103ff`;
- ORIGIN = `c38ac2e513aff98463d33dfe77edc1ab56e103ff`;
- REMOTE = `c38ac2e513aff98463d33dfe77edc1ab56e103ff`.

O commit foi confirmado independentemente pelo conector GitHub no repositorio canonico `rrgestao/skpe-saas`.

## 12. Invariantes preservadas

Permanecem preservadas:

- `sparks_responsibility_assignments` como autoridade transversal de responsabilidades;
- nenhuma coluna de responsavel pessoal adicionada a `sparks_initiative_actions`;
- `responsible_area_id` permanece responsabilidade de area organizacional;
- `source_module_code` permanece proveniencia/contexto;
- nenhuma responsabilidade altera automaticamente lifecycle da iniciativa;
- nenhuma responsabilidade altera automaticamente progresso da iniciativa;
- nenhum roll-up foi implementado;
- nenhuma sincronizacao automatica `skpe_* <-> sparks_*` foi criada;
- Kanban permanece no `6G`;
- Gantt permanece no `6H`;
- agenda/calendario permanecem no `6I`;
- custos/esforco permanecem no `6J`.

## 13. Itens fora do escopo

O `6E` nao implementa:

- roll-up de progresso ou saude;
- calculo de progresso por responsavel;
- workflow generico de RH;
- engine generico de aprovacao;
- Kanban;
- Gantt;
- agenda;
- calendario;
- custos;
- esforco;
- sincronizacao automatica com objetos `skpe_*`.

## 14. Criterios de saida

Foram atendidos:

- autoridade unica transversal;
- atribuicao governada;
- encerramento governado;
- leitura governada;
- integridade organizacional;
- validacao de pessoa ativa;
- vigencia;
- tipos de responsabilidade canonicos;
- ausencia de DML direto;
- ausencia de policy de mutacao;
- hardening de RPCs legadas;
- bloqueio de bypass;
- autorizacao positiva e negativa;
- auditoria;
- migration aplicada;
- history local/remoto convergente;
- teste comportamental integral;
- rollback;
- zero residuos;
- advisor pos-DDL revisado;
- commit tecnico atomico;
- Local, Origin e Remote convergentes;
- verificacao independente pelo GitHub canonico.

## 15. Estado do gate

O estado estrutural e **PASS**.

O hardening e **PASS**.

O estado comportamental e **PASS**.

O rollback/cleanup e **PASS**.

A reconciliacao Supabase x Git e **PASS**.

O fechamento tecnico esta **APROVADO**.

**GATE: 17-B.5F.3C.6E — PASS / CLOSED.**

A proxima etapa canonica e:

**17-B.5F.3C.6F — Roll-up Governado de Progresso e Saude.**

A continuidade permanece subordinada a **SK-PE-CONT-01 — Continuidade Segura e Fechamento Controlado do SPARKs PE**.