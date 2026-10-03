# SK-PE — Checkpoint de Continuidade — 2026-10-03 — 006

Status: ATIVO
Gate: COOTAQUARA — Mapping Governado SWOT

## Continuidade

Anterior: `SKPE_CONTINUITY_CHECKPOINT_20261003_005.md`

SHA funcional do mapping SWOT:

`a8645ea77a63666aa7b667a8994d5439d4cdadb7`

## Implementação

Mapping ativado:

`swot_to_swot_item`

Origem:

`entity_code = swot`

Destino:

`public.skpe_swot_items`

Materializador:

`skpe_materialize_import_request_as_swot`

Características obrigatórias:

- revisão humana;
- sem inferência semântica;
- criação apenas por resolução declarativa `create_new_entity`;
- chave revisada pelo campo histórico `codigo`;
- fatores PESTEL relacionados preservados como códigos, sem resolução automática;
- evidências relacionadas preservadas como referências;
- status histórico preservado em metadata e não promovido automaticamente;
- item canônico criado como `draft/draft`;
- idempotência por `source_import_record_id`;
- colisão de código com fluxo distinto bloqueada;
- proveniência preservada nas colunas de origem;
- materializador e dispatcher restritos a `service_role`.

## Validação

Contratos focados executados:

- importMappingCoverageContract;
- importMappingReadinessContract;
- pestelImportMappingContract;
- swotImportMappingContract.

Resultado: **13/13 PASS**.

## Sincronização

O SHA `a8645ea77a63666aa7b667a8994d5439d4cdadb7` foi confirmado nos dois remotos governados da branch de preservação.

## Supabase DEV

Migration aplicada:

`govern_swot_import_mapping`

Nenhum ImportRecord SWOT foi materializado.

Nenhum objeto SWOT foi criado por este gate.

Apenas o contrato de incorporação foi ativado.

## Cobertura após o gate

Lote COOTAQUARA v17:

- registros cobertos: **41/281**;
- registros sem mapping ativo: **240/281**;
- tipos cobertos: **7/38**;
- tipos pendentes: **31/38**.

## Próximo gate

Ativar mapping governado:

`tows -> skpe_tows_items`

Restrições:

- não materializar TOWS antes de request/review/decision/resolution;
- preservar códigos dos fatores SWOT internos/externos sem inferência;
- não transformar status histórico em validação institucional;
- criar item canônico como draft;
- preservar proveniência até ImportRecord;
- manter execução do materializador sob `service_role`.
