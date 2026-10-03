# SK-PE — Checkpoint de Continuidade — 2026-10-03 — 003

Status: ATIVO
Gate: COOTAQUARA — Cobertura dos Contratos de Incorporação

## Continuidade

Anterior: `SKPE_CONTINUITY_CHECKPOINT_20261003_002.md`

SHA base do gate: `95e58a3bea462973765df67169c5b009a6fcd21e`

## Constatação canônica

O lote histórico v17 contém 281 registros em 38 tipos.

A arquitetura posterior de importação/incorporação já possui catálogo, versionamento, resolução, revisão, decisão, proveniência e materialização governada.

Mappings ativos encontrados:

1. `decision_to_gate_decision`
   - origem: `decision`
   - destino: `skpe_gate_decisions`
2. `indicator_to_indicator`
   - origem: `indicator`
   - destino: `skpe_indicators`
3. `key_result_to_key_result`
   - origem: `key_result`
   - destino: `skpe_key_results`
4. `okr_to_okr`
   - origem: `okr`
   - destino: `skpe_okrs`
5. `strategic_objective_to_strategic_objective`
   - origem: `strategic_objective`
   - destino: `skpe_strategic_objectives`

Todos possuem versão ativa e materializador configurado.

## Cobertura medida

- registros cobertos por mapping ativo: **23/281**;
- registros sem mapping ativo: **258/281**;
- tipos cobertos: **5/38**;
- tipos sem mapping ativo: **33/38**;
- cobertura por registros: **8,19%**;
- cobertura por tipos: **13,16%**.

Importante: existência de mapping não equivale a resolução de destino nem materialização.

## Nova função read-only

Migration:

`supabase/migrations/20261003040500_add_import_mapping_coverage.sql`

Função:

`skpe_get_import_mapping_coverage(batch_id)`

A função:

- usa somente mappings e versões `active`;
- calcula cobertura por registro e por tipo;
- expõe destino, versão e materializador configurado;
- não cria pedido de incorporação;
- não resolve target;
- não altera import_record;
- não materializa dado estratégico.

## UX

`CanonicalImportStaging.tsx` passa a exibir:

- registros cobertos;
- registros sem contrato;
- tipos cobertos;
- tipos pendentes;
- percentual de cobertura;
- matriz por tipo com destino canônico e exigência de revisão humana.

A UI explicita que cobertura não significa materialização.

## Matriz v1

Documento:

`docs/00-governanca/SKPE_COOTAQUARA_IMPORT_MAPPING_MATRIX_V1.md`

A matriz classifica os 38 tipos em:

- ATIVO/GOVERNADO;
- CANDIDATO TÉCNICO;
- REVISÃO/COMPOSTO;
- SEM DESTINO CONFIRMADO.

## Próxima expansão

Primeiro conjunto candidato:

- `pestel -> skpe_pestel_items` (6);
- `swot -> skpe_swot_items` (12);
- `tows -> skpe_tows_items` (7);
- `risk -> skpe_strategic_risk_items` (10).

Potencial após os quatro: 58/281 registros e 9/38 tipos.

As quatro tabelas foram criadas especificamente para o Diagnóstico Estratégico e possuem:

- chave única por organização/projeto/código;
- `source_import_record_id`;
- `source_external_key`;
- `source_sheet`;
- `source_row`;
- `source_payload`.

## Validação

Contratos focados:

- `importMappingCoverageContract.test.ts`: PASS;
- `importMappingReadinessContract.test.ts`: PASS.

Resultado consolidado: **4/4 PASS**.

Build:

`tsc -b && vite build`

Resultado: **PASS — exit code 0**.

Avisos de bundle permanecem não bloqueadores.

## Próximo gate

Implementar mappings governados de Diagnóstico na ordem:

`PESTEL -> SWOT -> TOWS -> RISK`

Cada mapping deve seguir o runtime existente:

`incorporation request -> target resolution -> item review -> governed decision -> materializer -> provenance`

Sem preenchimento manual de `target_table` e sem inferência semântica.
