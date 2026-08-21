---
id: SKPE-AUD-17-B-5F-3C-6D-FECHAMENTO
version: 1.0.0
status: approved
domain: SPARKs PaaS
owner: SPARKs PE
roadmap_step: 17-B.5F.3C.6D
canonical_context: SK-PE-CONT-01
created_at: 2026-08-21
updated_at: 2026-08-21
origin: implementacao_governada_supabase_github
technical_commit: c3e2f07c01aac190da1e6e2526a7614d8034d0c0
depends_on:
  - supabase/migrations/20260821022449_sparks_initiative_actions_governance_foundation.sql
  - supabase/migrations/20260821024153_harden_sparks_initiative_actions_foundation.sql
  - supabase/migrations/20260821094420_govern_sparks_initiative_action_operations.sql
  - supabase/migrations/20260821095209_harden_sparks_initiative_action_structural_update.sql
  - supabase/migrations/20260821110805_harden_sparks_initiative_action_parent_lifecycle.sql
---

# Fechamento Tecnico 17-B.5F.3C.6D — Operacao Governada de Lifecycle e Execucao de Acoes

## 1. Contexto e identificacao do gate

Este documento integra a missao **SK-PE-CONT-01 — Continuidade Segura e Fechamento Controlado do SPARKs PE** e formaliza o encerramento do gate `17-B.5F.3C.6D — Operacao Governada de Lifecycle e Execucao de Acoes`.

O gate sucede `17-B.5F.3C.6C — Fundacao Transversal de Acoes de Iniciativas` e transforma `public.sparks_initiative_actions` de fundacao estrutural em entidade operacional governada, sem criar uma segunda fonte de verdade e sem antecipar responsabilidades pessoais, roll-up, Kanban, Gantt, calendario ou controle economico expandido.

Projeto Supabase de referencia:

- projeto: `skpe-saas-dev`;
- project ref: `vumbfpbcozjebomcthdw`.

Repositorio canonico:

- repositorio: `rrgestao/skpe-saas`;
- branch: `feature/formulacao-estrategica-operacional`.

## 2. Objetivo do gate

O objetivo do `6D` foi estabelecer contratos governados para:

- criacao de acoes;
- edicao estrutural permitida;
- transicao de lifecycle;
- atualizacao de progresso de execucao;
- justificativa obrigatoria;
- auditoria;
- autorizacao organizacional e modular;
- protecao de identidade, proveniencia e baseline;
- precedencia do lifecycle da iniciativa pai sobre a execucao da acao.

A mutacao direta da tabela por `authenticated` permaneceu proibida.

## 3. Migrations executadas

### 3.1 Migration principal

`20260821094420_govern_sparks_initiative_action_operations.sql`

Estabeleceu os quatro contratos operacionais governados:

- `create_sparks_initiative_action(...)`;
- `update_sparks_initiative_action(...)`;
- `transition_sparks_initiative_action_lifecycle(...)`;
- `update_sparks_initiative_action_execution(...)`.

Tambem estabeleceu:

- protecao de identidade e baseline;
- controles adicionais de inicio real e progresso;
- auditoria obrigatoria das operacoes;
- matriz governada de transicoes;
- privilegios de execucao por RPC;
- manutencao da proibicao de DML direto para `authenticated`.

### 3.2 Hardening de update estrutural

`20260821095209_harden_sparks_initiative_action_structural_update.sql`

Corrigiu a deteccao de update estrutural sem mudanca material.

A validacao passou a comparar os atributos de negocio antes da alteracao de `updated_at` e `updated_by`, impedindo que uma atualizacao sem mudanca efetiva produza falsa alteracao e auditoria indevida.

### 3.3 Hardening de lifecycle da iniciativa pai

`20260821110805_harden_sparks_initiative_action_parent_lifecycle.sql`

Estabeleceu a precedencia do lifecycle organizacional da iniciativa sobre a operacao de suas acoes.

A regra consolidada impede que uma acao:

- seja criada para iniciativa ainda nao aceita para planejamento/execucao;
- entre em execucao real enquanto a iniciativa pai nao estiver em lifecycle operacional compativel;
- continue sendo alterada operacionalmente apos encerramento da iniciativa, ressalvado o arquivamento historico permitido.

Esse hardening nao implementa roll-up e nao altera automaticamente o progresso da iniciativa pai.

## 4. Contrato operacional aprovado

O `6D` separa explicitamente quatro responsabilidades.

### Criacao

A criacao estabelece o nascimento da acao e seu contexto estrutural inicial.

A acao nasce:

- com status `planned`;
- progresso igual a zero;
- sem `started_at`;
- sem `completed_at`;
- vinculada obrigatoriamente a uma iniciativa e organizacao;
- herdando `source_module_code` da iniciativa.

### Edicao estrutural

A edicao permite atributos estruturais autorizados, incluindo:

- codigo;
- nome;
- descricao;
- tipo;
- hierarquia;
- referencia de origem;
- textos de contexto;
- area organizacional responsavel;
- planejamento vigente;
- prioridade;
- metadata.

Permanecem fora do contrato de edicao:

- identidade organizacional;
- iniciativa pai;
- modulo de origem;
- baseline original;
- lifecycle;
- progresso;
- custos;
- esforco.

### Lifecycle

O lifecycle aprovado e:

`planned`
- `in_progress`
- `blocked`
- `cancelled`

`in_progress`
- `on_hold`
- `blocked`
- `completed`
- `cancelled`

`on_hold`
- `in_progress`
- `blocked`
- `cancelled`

`blocked`
- `in_progress`
- `on_hold`, somente quando a acao ja tiver sido iniciada
- `cancelled`

`completed`
- `archived`

`cancelled`
- `archived`

`archived`
- terminal

A conclusao da acao ocorre exclusivamente pelo contrato de lifecycle, que estabelece progresso igual a 100 e `completed_at`.

### Execucao

A atualizacao governada de execucao:

- opera somente em `in_progress`, `on_hold` ou `blocked`;
- aceita progresso de 0 ate valor inferior a 100;
- nao permite conclusao indireta por progresso 100;
- registra `last_update_at`;
- exige justificativa;
- gera auditoria.

## 5. Invariantes preservadas

Permanecem preservadas:

- `sparks_initiatives.status` como lifecycle organizacional transversal;
- `sparks_initiatives.progress` como progresso organizacional governado;
- nenhuma acao altera automaticamente lifecycle da iniciativa pai;
- nenhuma acao altera automaticamente progresso da iniciativa pai;
- nenhum roll-up foi implementado;
- `skpe_initiative_actions` nao foi migrada ou sincronizada automaticamente;
- nao existe sincronizacao automatica `skpe_*` para `sparks_*`;
- `source_module_code` permanece proveniencia/contexto;
- responsabilidades pessoais permanecem no dominio transversal de responsabilidades;
- custos e esforco permanecem fora da operacao deste gate;
- Kanban, Gantt e calendario permanecem projecoes futuras.

## 6. Autorizacao e seguranca

Os contratos operacionais utilizam a autoridade existente:

`public.can_manage_sparks_initiatives(organization_id, source_module_code)`.

O modelo preserva:

- usuario autenticado obrigatorio;
- autorizacao por organizacao e contexto modular;
- justificativa obrigatoria;
- `SECURITY DEFINER` com `search_path` vazio;
- `EXECUTE` explicitamente controlado;
- ausencia de DML direto de `INSERT`, `UPDATE` e `DELETE` para `authenticated`;
- auditoria de operacoes governadas.

Os codigos de auditoria utilizados sao:

- `initiative_action_created`;
- `initiative_action_updated`;
- `initiative_action_lifecycle_transitioned`;
- `initiative_action_execution_updated`.

## 7. Hardening e reconciliacao de migration history

A migration principal `20260821094420` foi aplicada pelo fluxo governado do Supabase CLI e confirmou:

- dry-run positivo;
- `db push` positivo;
- history `Local = Remote`.

O primeiro hardening `20260821095209` tambem foi aplicado pelo fluxo governado e confirmou:

- dry-run isolando somente a migration alvo;
- `db push` positivo;
- history `Local = Remote`.

O segundo hardening `20260821110805` foi executado manualmente no SQL Editor do Supabase e retornou:

`Success. No rows returned`

A consulta subsequente de migration history confirmou inicialmente:

`20260821110805 | [remote vazio]`

Como o schema ja havia sido alterado, o SQL nao foi reaplicado.

A reconciliacao foi realizada exclusivamente sobre o migration history com:

`supabase migration repair 20260821110805 --status applied --linked`

A validacao posterior confirmou:

`20260821110805 | 20260821110805`

Resultado:

**SCHEMA = PASS / MIGRATION HISTORY = PASS / SEM REAPLICACAO DE DDL.**

## 8. Teste comportamental integral

Foi executado teste transacional do contrato `6D`.

O harness validou, em fluxo governado:

- superficie de privilegios;
- criacao;
- estado inicial `planned / progress 0`;
- rejeicao de update estrutural sem mudanca material;
- update estrutural real;
- precedencia do lifecycle da iniciativa pai;
- transicao `planned -> blocked`;
- transicao `blocked -> in_progress`;
- registro de `started_at`;
- progresso parcial governado;
- rejeicao de progresso 100 pela RPC de execucao;
- ausencia de roll-up automatico para a iniciativa pai;
- conclusao via lifecycle;
- bloqueio de edicao estrutural apos conclusao;
- trilha de auditoria;
- autorizacao negativa.

Durante a preparacao do harness foram corrigidos dois problemas exclusivos do teste, sem alteracao do contrato de producao:

1. nome invalido de custom GUC, alterado de `test.6d.*` para `test.gate6d.*`;
2. execucao parcial no SQL Editor, que perdia a tabela temporaria de contexto; o teste foi posteriormente executado como lote transacional unico.

O lote chegou ao `ROLLBACK` final sem erro nao tratado.

A validacao pos-rollback retornou:

- `rollback_cleanup = PASS`;
- `residual_actions = 0`.

Resultado:

**PASS COMPORTAMENTAL / ZERO RESIDUOS.**

## 9. Versionamento Git

As tres migrations foram staged exclusivamente por caminho explicito e incorporadas em commit atomico.

Commit:

`c3e2f07c01aac190da1e6e2526a7614d8034d0c0`

Mensagem:

`feat(platform): govern initiative action lifecycle execution`

Apos o push:

- `LOCAL = c3e2f07c01aac190da1e6e2526a7614d8034d0c0`;
- `ORIGIN = c3e2f07c01aac190da1e6e2526a7614d8034d0c0`;
- `REMOTE = c3e2f07c01aac190da1e6e2526a7614d8034d0c0`;
- working tree limpo.

O commit foi confirmado no repositorio GitHub canonico.

## 10. Itens deliberadamente fora do escopo

Nao pertencem ao `6D` e permanecem nos gates posteriores:

- `6E` — responsabilidades pessoais governadas em acoes;
- `6F` — roll-up governado de progresso e saude;
- `6G` — projecao Kanban transversal;
- `6H` — Gantt, baseline e desvio temporal;
- `6I` — agenda, calendario e eventos operacionais;
- `6J` — custos, esforco e controle economico de execucao.

Nenhum desses itens deve ser incorporado retroativamente ao `6D`.

## 11. Criterios de saida

Foram atendidos:

- contratos operacionais de criacao, edicao, lifecycle e execucao;
- matriz de transicoes governada;
- autorizacao positiva e negativa validada;
- ausencia de mutacao direta para `authenticated`;
- justificativa e auditoria obrigatorias;
- protecao de identidade e baseline;
- rejeicao de no-op estrutural;
- precedencia de lifecycle da iniciativa pai;
- ausencia de roll-up automatico;
- migrations aplicadas no Supabase;
- migration history `Local = Remote`;
- reconciliacao sem reaplicacao de DDL;
- teste comportamental integral;
- rollback com zero residuos;
- commit tecnico atomico;
- Local, Origin e Remote convergentes;
- working tree limpo.

## 12. Estado do gate

O estado estrutural e **PASS**.

O estado operacional e **PASS**.

O estado comportamental e **PASS**.

O hardening e **PASS**.

A reconciliacao Supabase x Git e **PASS**.

O fechamento tecnico esta **APROVADO**.

**GATE: 17-B.5F.3C.6D — PASS / CLOSED.**

A proxima etapa canonica e:

**17-B.5F.3C.6E — Responsabilidades Governadas em Acoes.**

A continuidade permanece subordinada a **SK-PE-CONT-01 — Continuidade Segura e Fechamento Controlado do SPARKs PE**.