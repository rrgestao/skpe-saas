---
id: SKPE-AUDIT-17-B-5F-3C-6J
status: closed
result: PASS
canonical_context: SK-PE-CONT-01
gate: 17-B.5F.3C.6J
closed_at: 2026-08-29
---

# Relatório de Fechamento — 17-B.5F.3C.6J

## Gate

`17-B.5F.3C.6J — Custos, Esforço e Controle Econômico de Execução`

## Resultado

`SKPE_17_B_5F_3C_6J = PASS/CLOSED`

## Objetivo validado

Consolidar o controle econômico mínimo para comparar planejado x realizado em iniciativas e ações, sem criar domínio financeiro concorrente nem substituir contabilidade, orçamento corporativo ou ERP.

## Fundação canônica reutilizada

- `sparks_initiatives` mantém os valores econômicos diretos da iniciativa;
- `sparks_initiative_actions` mantém os valores econômicos das ações;
- `set_sparks_initiative_economic_execution` governa a mutação econômica da iniciativa;
- `update_sparks_initiative_action` governa a mutação econômica da ação;
- `get_sparks_initiative_economic_projection` produz a leitura gerencial consolidada.

## Contratos verificados no DEV

### Iniciativa

`set_sparks_initiative_economic_execution`:

- exige usuário autenticado;
- exige permissão de gestão da iniciativa;
- bloqueia edição econômica em lifecycle terminal;
- valida custos não negativos;
- valida moeda em código de três letras;
- valida esforço não negativo;
- exige unidade quando houver esforço;
- exige justificativa auditável;
- rejeita operação sem alteração efetiva;
- registra before/after em `sparks_initiative_audit` com `action_code = initiative_economic_execution_updated`.

### Ação

`update_sparks_initiative_action` já aceita e governa:

- `plannedCost`;
- `actualCost`;
- `currencyCode`;
- `estimatedEffort`;
- `actualEffort`;
- `effortUnit`;
- justificativa de mudança;
- proteção de lifecycle/arquivamento;
- auditoria em `sparks_initiative_action_audit`.

A UX operacional da ação já estava disponível no drawer do Kanban antes do fechamento deste gate.

## Consolidação determinística

`get_sparks_initiative_economic_projection` foi validada como fonte gerencial derivada.

### Custos

As ações são consolidadas por `currency_code`, retornando:

- custo planejado vigente;
- custo realizado;
- variação `realizado - planejado`;
- planejado cancelado;
- planejado arquivado.

Não existe soma entre moedas diferentes nem conversão cambial implícita.

### Esforço

As ações são consolidadas por `effort_unit`, retornando:

- esforço estimado vigente;
- esforço realizado;
- variação `realizado - estimado`;
- esforço estimado cancelado;
- esforço estimado arquivado.

Não existe conversão implícita entre horas, dias, semanas, meses, pontos ou unidade customizada.

### Lifecycle e histórico

- ações canceladas/arquivadas não contribuem para o planejado vigente;
- realizado permanece preservado para rastreabilidade;
- a soma das ações não sobrescreve automaticamente os valores diretos da iniciativa;
- valores diretos da iniciativa e roll-up das ações permanecem distinguíveis.

## Frontend final

Commit técnico:

`2fb371365891f1436f682a134f9f698e89fa54bf — feat(skpe): expose governed initiative economic control`

Foi adicionada ao Portfólio a ação `Custos e esforço`, que abre uma visão governada contendo:

- planejado x realizado da iniciativa;
- variação de custo;
- esforço estimado x realizado;
- variação de esforço;
- edição governada dos valores diretos da iniciativa;
- justificativa obrigatória;
- consolidação das ações por moeda;
- consolidação das ações por unidade de esforço;
- fronteira explícita com o futuro domínio financeiro especializado.

A superfície não cria tabela econômica nova, não cria ledger, não cria orçamento paralelo e não introduz conversão cambial.

## Validação local

Execução final reportada pelo gate frontend:

- testes: `112/112 PASS`;
- build: `PASS`;
- Vite: `177 modules transformed`;
- warning de chunk > 500 kB permanece não bloqueante;
- commit: `2fb371365891f1436f682a134f9f698e89fa54bf`;
- push: `PASS`;
- worktree final: limpa;
- marcador: `SKPE_6J_INITIATIVE_ECONOMIC_FRONTEND=PASS`.

## Critérios de saída

- totalizações determinísticas: **PASS**;
- variações rastreáveis: **PASS**;
- integração semântica com iniciativa e ação: **PASS**;
- fronteira explícita com domínio financeiro especializado: **PASS**;
- ausência de fonte econômica paralela: **PASS**;
- ausência de conversão cambial implícita: **PASS**;
- ausência de mistura automática de unidades de esforço: **PASS**.

## Conclusão

`SKPE_17_B_5F_3C_6J = PASS/CLOSED`

A trilha funcional `17-B.5F.3C.6D–6J` está integralmente encerrada, com `0 gates` restantes.