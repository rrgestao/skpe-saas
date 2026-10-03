# SK-PE — Checkpoint de Continuidade — 2026-10-03 — 016

Status: ATIVO
Gate: COOTAQUARA — Confirmação Assistida em Lote do Diagnóstico já Aprovado

## Continuidade

Anterior: `SKPE_CONTINUITY_CHECKPOINT_20261003_015.md`

SHA funcional:

`d4f4389437f443f531b23296f046b56c478c7828`

## Decisão de UX/Governança

Os elementos do Diagnóstico Estratégico da COOTAQUARA já foram aprovados pela Gestão.

A importação não deve repetir a aprovação de negócio.

O fluxo passa a distinguir:

1. aprovação estratégica preexistente;
2. confirmação técnica de correspondência entre histórico e SPARKs;
3. tratamento individual somente de diferenças reais;
4. incorporação/materialização como gate posterior e separado.

## Ação em lote

Nova ação Edge:

`review_batch_integral_matches`

Nova ação UI:

`Confirmar correspondências integrais em lote`

Regras:

- exige sessão autenticada;
- exige `can_manage_skpe_journey` ou Super Admin;
- exige confirmação humana;
- exige justificativa;
- considera apenas PESTEL, SWOT, TOWS e RISK do lote;
- exige request em `under_review`;
- exige todos os campos fornecidos;
- exige destino canônico único e existente;
- compara cada valor recebido com o valor atual no SPARKs;
- só confirma registros com correspondência integral;
- diferenças permanecem intocadas para análise individual;
- destinos não resolvidos permanecem intocados;
- grava evento de revisão por campo;
- reavalia elegibilidade por request;
- não registra decisão de aprovação de negócio;
- não executa materialização.

Metadata auditável:

- `human_batch_confirmation = true`;
- `validation_scope = migration_correspondence_only`;
- `historical_business_approval_preserved = true`;
- `business_decision_repeated = false`;
- `semantic_inference = false`;
- `materialization_requested = false`.

## UX por exceção

A fila passa a informar explicitamente que:

- o Diagnóstico já foi aprovado pela Gestão da COOTAQUARA;
- a etapa atual confere correspondência de migração;
- correspondências integrais podem ser homologadas em lote;
- somente diferenças reais exigem análise individual.

A revisão por registro mantém:

- Informação;
- Recebido do histórico;
- Atual no SPARKs;
- selo `Igual` ou `Diferença`.

Ações individuais aparecem somente em diferenças.

O texto de confirmação pendente por campo foi removido.

## Correção de layout

A tabela de revisão passa a usar:

- 28% para Informação;
- 36% para Recebido do histórico;
- 36% para Atual no SPARKs;
- `box-sizing: border-box` em células;
- largura máxima 100% no pacote e tabela.

Objetivo:

eliminar corte da coluna direita sem criar coluna adicional de ações.

## Validação

Contratos focados:

- `incorporationReviewPreparationContract.test.ts`;
- `diagnosticExistingTargetResolutionContract.test.ts`.

Resultado:

**8/8 PASS**

## Runtime DEV

Edge Function:

`skpe-import-incorporation`

Estado:

- ACTIVE;
- version: 5;
- verify_jwt: true.

## Próximo gate

Validação humana na UI do lote v26:

1. atualizar a página;
2. localizar `Dados históricos do Diagnóstico — revisão humana`;
3. usar `Confirmar correspondências integrais em lote`;
4. confirmar que a ação trata somente correspondências integrais;
5. registrar justificativa humana;
6. verificar resumo retornado:
   - registros confirmados;
   - campos confirmados;
   - registros com diferenças;
   - registros sem resolução;
7. não usar `Aprovar informação` neste gate;
8. tratar individualmente apenas as exceções remanescentes.
