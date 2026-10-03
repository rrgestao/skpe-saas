# SK-PE — Checkpoint de Continuidade — 2026-10-03 — 002

Status: ATIVO
Gate: COOTAQUARA — Mapping Readiness para Promoção Definitiva

## Origem

Continuação do checkpoint `SKPE_CONTINUITY_CHECKPOINT_20261002_001.md`.

Lote canônico investigado:

`c6c255e6-46d1-4072-9ebd-e0640345c98b`

Projeto Supabase DEV: `skpe-saas-dev`.

## Constatação

A avaliação histórica do lote indicava:

- status do lote: `ready`;
- `readyForDefinitiveLoad=true`;
- 281 registros válidos;
- 0 bloqueados;
- 0 inválidos;
- 0 pendentes de mapping pelo campo `simulation_status`;
- 6 conflitos formalmente tratados;
- carga definitiva ainda não executada.

A investigação do contrato de destino revelou, porém, uma lacuna estrutural:

- 281/281 registros com `proposed_action in ('insert','update')` possuem `target_table IS NULL`;
- 38 tipos distintos de entidade não possuem destino canônico explicitamente definido;
- o readiness anterior avaliava `simulation_status='pending_mapping'`, mas não exigia `target_table`;
- portanto, `readyForDefinitiveLoad=true` era um falso positivo para promoção ao modelo estratégico atual.

## Decisão de governança

Não executar carga definitiva enquanto houver registro de escrita sem destino canônico.

Novo gate obrigatório:

`TARGET_MAPPING_COMPLETE`

Critério:

- todo registro com ação `insert` ou `update` deve possuir `target_table` canônica;
- enquanto `target_table IS NULL`, o lote permanece bloqueado para promoção definitiva;
- o relatório de readiness deve expor quantidade e tipos de entidades sem destino;
- nenhuma regra de transformação será inferida silenciosamente;
- a Jornada canônica permanece protegida.

## Implementação local

Migration criada:

`supabase/migrations/20261003021500_govern_import_mapping_readiness.sql`

Alterações principais:

- corrige `skpe_assess_import_batch_readiness`;
- adiciona gate `TARGET_MAPPING_COMPLETE`;
- adiciona contagem `unmapped`;
- adiciona `unmappedEntities`;
- registra `IMPORT_MAPPING_READINESS_ASSESSED`;
- mantém `definitiveLoadExecuted=false`;
- rebaixa lote para `reviewed` quando o mapping não estiver completo.

Interface atualizada:

`apps/web/src/modules/portability/CanonicalImportStaging.tsx`

A interface passa a explicar a lacuna de mapeamento e listar os tipos de informação sem destino.

Teste contratual:

`apps/web/tests/importMappingReadinessContract.test.ts`

Resultado: 2/2 PASS.

O build foi iniciado, mas o processo local permaneceu retido em `tsc -b && vite build` sem erro emitido. Não considerar build concluído até haver exit code 0.

## Estado do banco

Nenhuma migration foi aplicada neste gate.

Nenhum dado foi alterado no Supabase durante a investigação.

A migration somente deverá ser aplicada depois de:

1. código e teste versionados;
2. sincronização do mesmo SHA nos remotos governados;
3. confirmação do checkpoint;
4. aplicação controlada em DEV;
5. reavaliação do lote;
6. comprovação esperada: `unmapped=281`, `readyForDefinitiveLoad=false`, `readinessState=blocked`.

## Próximo gate

Construir a matriz canônica:

`entity_code -> target_table -> transformation rule -> idempotency key -> validation contract`

para os 38 tipos de entidade do lote COOTAQUARA.

Somente entidades com mapeamento determinístico e validado poderão ser promovidas.

Não criar RPC genérica de despejo de `values_json` nas tabelas estratégicas.
