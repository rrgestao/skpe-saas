# SK-PE — Checkpoint de Continuidade — 2026-10-03 — 007

Status: ATIVO
Gate: COOTAQUARA — Mapping Governado TOWS

## Continuidade

Anterior: `SKPE_CONTINUITY_CHECKPOINT_20261003_006.md`

SHA funcional do mapping TOWS:

`aeec39bb70ea4a6149982e8d303b7154adfeefdd`

## Implementação

Mapping ativado:

`tows_to_tows_item`

Origem:

`entity_code = tows`

Destino:

`public.skpe_tows_items`

Materializador:

`skpe_materialize_import_request_as_tows`

Características obrigatórias:

- revisão humana;
- sem inferência semântica;
- criação apenas por resolução declarativa `create_new_entity`;
- chave revisada pelo campo histórico `codigo`;
- coerência determinística entre o código `TW-<TIPO>nn` e o campo `tipo`;
- fatores internos e externos preservados como tokens históricos, sem resolução automática;
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
- swotImportMappingContract;
- towsImportMappingContract.

Resultado: **18/18 PASS**.

## Sincronização

O SHA `aeec39bb70ea4a6149982e8d303b7154adfeefdd` foi confirmado nos dois remotos governados da branch de preservação.

## Supabase DEV

Migration aplicada:

`govern_tows_import_mapping`

Nenhum ImportRecord TOWS foi materializado.

Nenhum objeto TOWS foi criado por este gate.

Apenas o contrato de incorporação foi ativado.

## Cobertura após o gate

Lote COOTAQUARA v17:

- registros cobertos: **48/281**;
- registros sem mapping ativo: **233/281**;
- tipos cobertos: **8/38**;
- tipos pendentes: **30/38**.

## Próximo gate

Ativar mapping governado:

`risk -> skpe_strategic_risk_items`

Restrições:

- não materializar riscos antes de request/review/decision/resolution;
- distinguir risco estratégico de risco operacional de iniciativa;
- preservar códigos de evidência e objetivo como referências, sem inferência;
- não transformar status histórico em validação institucional;
- criar risco canônico como draft;
- preservar proveniência até ImportRecord;
- manter execução do materializador sob `service_role`.
