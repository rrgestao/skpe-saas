# SK-PE — Checkpoint de Continuidade — 2026-10-04 — 026

Status: ATIVO
Gate: COOTAQUARA — Validação funcional pós-carga / fila pós-carga reconciliada

## Continuidade

Anterior:

`SKPE_CONTINUITY_CHECKPOINT_20261004_025.md`

Branch:

`recovery/2026-09-13-recent-ux-preservation`

Batch v26:

`0ad2aea6-fa95-457a-af2c-5bff0354bdfa`

## Preflight

RMKB-NTB:

- status: ONLINE;
- ping: PASS.

Git:

- HEAD local inicial: `3283bbcd4ae53c305e6a22d98cf03bc30f813324`;
- origin: mesmo HEAD;
- sparkooptech: mesmo HEAD.

Itens locais protegidos preservados e fora do commit:

- `.sparkoop-safety/`;
- `apps/web/src/modules/skpe/SkpeCockpit.tsx.tmp`;
- `supabase/migrations/20261004013000_govern_methodology_artifact_references.sql`.

## Estado do batch

Consulta canônica confirmou:

- total requests: 145;
- applied: 145;
- não applied: 0.

## Validação de pendências históricas

### P-011

Origem:

- código: P-011;
- status: Em andamento;
- ação: Vincular cada risco aceito a iniciativa ou ação do Ciclo 1;
- dependência: Portfólio Ciclo 1.

Materialização:

- evidence_only: true;
- business_entity_created: false;
- business_entity_updated: false;
- institutional_validation: false;
- semantic_inference: false;
- target type: pending_context_provenance.

Conclusão:

P-011 continua como contexto histórico em andamento.
Não foi promovido a concluído nem convertido em iniciativa executada.

### PMVV-A08

Origem:

- status: Planejado;
- objetivo: Escutar comunidades e medir impacto territorial;
- linha de base prevista: Ciclo 1.

Materialização:

- evidence_only: true;
- business_entity_created: false;
- business_entity_updated: false;
- institutional_validation: false;
- target type: pmvv_institutionalization_input_provenance.

Conclusão:

PMVV-A08 continua planejado.
Não foi promovido a ação executada ou concluída.

### TR-004 / TR-006

Materialização:

- evidence_only: true;
- composite_historical_context: true;
- business_entity_created: false;
- business_entity_updated: false;
- semantic_inference: false;
- target type: traceability_snapshot_provenance.

Conclusão:

TR-004/TR-006 permanecem snapshots históricos.
Nenhum vínculo futuro foi fabricado.

## Evidence — E14

E14 canônico:

- title: E14 — Identidade Estratégica;
- validation_status: validated;
- reliability_level: high;
- current_version_id: null;
- skdoc_document_id: null;
- quality/completeness/currentness/overall score: null.

Metadata preservada:

- gap: Ata/e-mail/registro formal do CA ainda deve ser anexado ao repositório;
- validation_action: anexar evidência formal da deliberação;
- classification: Deliberação comunicada.

Materialização do batch:

- reconciliation_only: true;
- business_content_updated: false;
- validation_status_updated: false;
- reliability_updated: false;
- formal_document_created: false;
- semantic_inference: false.

Conclusão:

A decisão comunicada permanece reconhecida.
A evidência documental formal continua ausente e explicitamente pendente.

## Evidence Management

Os 13 itens materializados foram consultados diretamente em
`skpe_evidence_checklist_items`.

Resultado:

- collection_status = not_requested: 13/13;
- assessment_status = not_assessed: 13/13;
- last_assessed_at preenchido: 0;
- itens com compliance/overall score: 0.

Conclusão:

O histórico foi preservado sem promover avaliação passada para estado atual.

## Riscos no Diagnóstico

O loader canônico do Diagnóstico consulta e mapeia explicitamente:

- management_recognition -> reconhecimento_pela_direcao;
- risk_acceptance -> aceite_do_risco;
- acceptance_evidence -> evidencia_do_aceite;
- implementation_cycle -> ciclo_de_implementacao;
- portfolio_destination -> destino_no_portfolio.

Portanto, os RIC-01..RIC-10 continuam sendo carregados com os fatos de aceite e reconhecimento já preservados no canônico.

## Defeito pós-carga identificado

A ação Edge:

`get_batch_review_queue`

ainda consultava apenas:

- pestel;
- swot;
- tows;
- risk.

Além disso, buscava somente requests `under_review`.

Com o batch 145/145 applied, os registros diagnósticos não tinham request `under_review`; a implementação antiga interpretaria isso como ausência de request e os devolveria artificialmente como pendentes.

Consequência potencial:

A UI poderia reabrir a fila de revisão mesmo após a carga governada concluída.

## Correção da fila pós-carga

A Edge Function foi alterada para:

1. consultar todos os ImportRecords do batch com:
   - proposed_action in insert/update;
   - quality_status = valid;
2. buscar todos os requests relacionados;
3. escolher o request mais recente por ImportRecord;
4. classificar request_status = applied como confirmado/aplicado;
5. retornar como pendente apenas:
   - ImportRecord sem request;
   - request mais recente ainda não applied.

Novos campos de resposta:

- totalReviewableRecords;
- pendingCount;
- confirmedCount;
- appliedCount;
- pendingImportRecordIds;
- confirmedImportRecordIds;
- appliedImportRecordIds.

Com o estado atual 145/145 applied, a fila governada pós-carga deve retornar:

- pendingCount = 0;
- appliedCount = 145.

## Edge Function

`skpe-import-incorporation`

Deploy:

- status: ACTIVE;
- version: 10;
- verify_jwt: true.

Observação:

O primeiro deploy retornou erro interno do serviço.
Uma segunda tentativa única foi bem-sucedida.

## Testes

Novo contrato:

`apps/web/tests/postLoadFunctionalConsistency.test.ts`

Valida:

1. carregamento dos fatos de aceite/reconhecimento dos riscos;
2. consumo da fila governada pela UI;
3. não reabertura de todos os registros cobertos após applied.

Também foi reforçado:

`incorporationReviewPreparationContract.test.ts`

para verificar:

- filtro insert/update + valid;
- latestRequestByRecord;
- semântica de request applied;
- appliedImportRecordIds;
- totalReviewableRecords.

Execução focada:

- postLoadFunctionalConsistency.test.ts;
- incorporationReviewPreparationContract.test.ts;
- historicalGateDecisionMaterialization.test.ts.

Resultado:

**9/9 PASS**

## Build

`npx vite build`

Resultado:

**PASS**

Observação não bloqueante:

Vite reportou warning de bundle/chunk acima de 500 kB.
Não é regressão funcional deste gate.

## Estado funcional consolidado

- batch v26: 145/145 applied;
- fila pós-carga: contrato corrigido para não reabrir itens applied;
- riscos: aceite/reconhecimento preservados na leitura canônica;
- P-011: Em andamento;
- PMVV-A08: Planejado;
- TR-004/TR-006: snapshots históricos;
- E14: documento formal ainda ausente;
- Evidence Management: not_requested / not_assessed;
- gate decisions históricos: preservados e idempotentes.

## Próximo gate

**VALIDAÇÃO VISUAL DA JORNADA E TRANSIÇÃO PARA O PRÓXIMO BLOCO FUNCIONAL**

Objetivos:

1. abrir a UI no DEV;
2. confirmar visualmente que a fila de revisão está vazia;
3. validar a tela de Diagnóstico/Riscos;
4. validar que a Jornada não reabre MF2 indevidamente;
5. confirmar a apresentação de pendências futuras;
6. identificar o próximo passo funcional do PE após MF2.

O batch v26 permanece tecnicamente concluído:

`DEFINITIVE_LOAD = YES`

Isso não altera o estado semântico das pendências históricas descritas acima.
