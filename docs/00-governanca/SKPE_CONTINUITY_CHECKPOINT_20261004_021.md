# SK-PE — Checkpoint de Continuidade — 2026-10-04 — 021

Status: ATIVO
Gate: COOTAQUARA — Revisão Governada Pré-Carga / Fila decisória classificada

## Continuidade

Anterior: `SKPE_CONTINUITY_CHECKPOINT_20261004_020.md`

Branch:

`recovery/2026-09-13-recent-ux-preservation`

Batch v26:

`0ad2aea6-fa95-457a-af2c-5bff0354bdfa`

## Estado preservado

- 120 registros acionáveis;
- 120/120 requests preparados;
- 0 decisões de incorporação;
- 0 requests aplicados;
- nenhuma materialização definitiva;
- `DEFINITIVE_LOAD = NO`.

## Problema de UX/governança identificado

A UI apresentava a fila completa de 120 requests sob o rótulo:

`Dados históricos do Diagnóstico — homologação da migração`

Isso era conceitualmente incorreto porque a fila inclui também:

- contexto deliberativo;
- decisões;
- evidências;
- gestão de evidências;
- iniciativas e portfólio históricos;
- Jornada;
- governança viva;
- valores;
- artefatos metodológicos;
- pendências;
- institucionalização do PMVV;
- validações PMVV;
- contexto do projeto;
- identidade estratégica;
- rastreabilidade;
- controle de versões.

O backend de homologação em lote já estava corretamente limitado a:

- PESTEL;
- SWOT;
- TOWS;
- Riscos.

Portanto, o problema estava na apresentação, não no escopo do backend.

## Classificação decisória da fila

A fila acionável foi classificada por natureza de incorporação:

### Preservação histórica / proveniência — 78

Não cria entidade de negócio nem reabre decisão.

Famílias:

- client_validation;
- deliberative_gate;
- initiative;
- journey;
- living_governance;
- pending_item;
- pmvv_institutionalization;
- project;
- project_portfolio;
- traceability;
- version_control.

### Reconciliação com registro existente — 24

Confirma correspondência com objeto canônico existente, sem reabrir conteúdo aprovado.

Famílias:

- evidence;
- living_value;
- pmvv_validation;
- risk;
- strategic_identity.

### Criação canônica controlada — 16

Propõe criação canônica após decisão humana explícita.

Famílias:

- evidence_management: 13;
- methodology_artifact: 3.

### Decisão formal histórica — 2

Permanece em trilha própria de decisão formal.

Família:

- decision: 2.

Total:

`78 + 24 + 16 + 2 = 120`

## Evolução da UI

A seção passou a se chamar:

`Fila governada de revisão pré-carga`

A tela agora apresenta quatro KPIs:

- Preservação histórica;
- Reconciliação existente;
- Criação controlada;
- Decisão formal histórica.

A tabela recebeu coluna `Natureza`.

O botão de homologação em lote passou a deixar explícito:

`Homologar somente Diagnóstico já aprovado (N)`

e somente aparece quando houver candidato de:

- pestel;
- swot;
- tows;
- risk.

Nenhuma nova ação de materialização foi adicionada.

## Validação

Testes focados:

- incorporationReviewPreparationContract.test.ts;
- strategicRiskAcceptanceReviewContract.test.ts.

Resultado:

**8/8 PASS**

Build de bundle:

`npx vite build`

Resultado:

**PASS**

Observação:

O comando composto `npm run build` permaneceu bloqueado durante o passo `tsc -b` sem emitir erro; a sessão foi encerrada e o build Vite foi executado separadamente com sucesso. Não foi mascarado erro de TypeScript.

## Próximo gate

**DECISÃO HUMANA SOBRE OS REQUESTS DE INCORPORAÇÃO**

A UI agora diferencia claramente:

- o que apenas preserva história;
- o que reconcilia canônico existente;
- o que cria novo objeto canônico;
- o que representa decisão formal histórica.

A próxima passagem deve revisar e decidir requests elegíveis, preservando:

- riscos RIC-01..RIC-10 como já reconhecidos/aceitos;
- P-011 como pendência em andamento;
- PMVV-A08 como ação ainda a desenvolver;
- TR-004/TR-006 como snapshots sem links fabricados;
- iniciativas e portfólio históricos como insumos direcionais, não execução automática;
- evidências formais ainda ausentes como ausentes.

Até autorização humana explícita:

`DEFINITIVE_LOAD = NO`
