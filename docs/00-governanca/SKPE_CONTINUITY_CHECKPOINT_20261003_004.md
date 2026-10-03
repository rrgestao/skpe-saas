# SK-PE — Checkpoint de Continuidade — 2026-10-03 — 004

Status: ATIVO
Gate: Alinhamento do Mapping Readiness à Arquitetura Moderna de Incorporação

## Correção

O campo legado `skpe_import_records.target_table` não é a autoridade do runtime moderno de incorporação.

A autoridade canônica é:

`skpe_incorporation_mapping_catalogs`
+
`skpe_incorporation_mapping_versions` ativas e aplicáveis.

O readiness foi corrigido para considerar como não mapeado apenas o registro `insert/update` cujo `entity_code` não possui mapping governado ativo aplicável.

## Efeito esperado no lote COOTAQUARA v17

Antes da correção arquitetural:

- 281/281 apareciam como sem destino porque `target_table IS NULL`.

Após a correção:

- 23/281 possuem mapping governado ativo;
- 258/281 permanecem sem mapping ativo;
- 5/38 tipos cobertos;
- 33/38 tipos pendentes.

## Implementação

Migration:

`supabase/migrations/20261003045000_align_import_readiness_to_mapping_catalog.sql`

Versão do readiness:

`mappingReadinessVersion = 2.0.0`

Autoridade registrada:

`mappingAuthority = active_incorporation_mapping_catalog`

O gate `TARGET_MAPPING_COMPLETE` permanece, mas passa a significar:

**todos os registros destinados a incorporação possuem contrato ativo aplicável**, e não preenchimento manual de `target_table`.

## UX

Label atualizado para:

`Contratos de incorporação definidos`

## Validação

- importMappingReadinessContract: PASS
- importMappingCoverageContract: PASS
- total focado: 4/4 PASS
- `tsc -b && vite build`: PASS
- exit code: 0

## Próximo gate

Ativar o primeiro novo mapping governado de Diagnóstico:

`pestel -> skpe_pestel_items`

Sem materializar dados até que o fluxo de request, review, decision e resolution esteja satisfeito.
