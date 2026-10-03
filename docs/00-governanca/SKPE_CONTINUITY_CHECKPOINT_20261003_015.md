# SK-PE — Checkpoint de Continuidade — 2026-10-03 — 015

Status: ATIVO
Gate: COOTAQUARA — Reconciliação do Diagnóstico Existente e UX de Validação Humana

## Continuidade

Anterior: `SKPE_CONTINUITY_CHECKPOINT_20261003_014.md`

Lote autoritativo para revisão humana:

`0ad2aea6-fa95-457a-af2c-5bff0354bdfa`

Fonte:

`SPARKs_PE_Sistema_Gestao_Estrategica_COOTAQUARA_v26_PRE_VALIDACAO_PEM-02.04.xlsx`

## Correção de continuidade

O lote v26 foi confirmado como mais recente e contém:

- 299 registros totais;
- 35 registros do primeiro pacote de Diagnóstico.

Comparação v17 x v26:

- PESTEL: idêntico;
- SWOT: idêntico;
- TOWS: idêntico;
- RISK: 10/10 registros alterados no v26.

Portanto, o v17 não deve ser usado para a validação humana corrente.

## Perfil de ingestão do v26

O v26 não possuía `ingestion_profile_version_id`.

Foi confirmada correspondência exata:

- schema_code: `SPARKS_PE_CANONICAL_IMPORT_PREVIEW`;
- schema_version: `2.0.1`;
- perfil governado: `canonical_workbook 2.0.1`.

O perfil foi atribuído via:

`skpe_assign_ingestion_profile_to_batch`

Modo:

`historical_explicit`

Autoria:

`ricardo.rodrigues@sparkoop.com`

## Preparação do v26

Resultado:

- PESTEL: 6 requests / 78 itens;
- SWOT: 12 requests / 108 itens;
- TOWS: 7 requests / 70 itens;
- RISK: 10 requests / 170 itens;
- total: 35 requests / 426 itens;
- falhas: 0;
- decisões humanas: 0.

## Descoberta de legado canônico

As 35 entidades correspondentes já existiam no banco desde 06/09/2026.

Estado de validação:

`validation_status = pending`

Portanto, o fluxo atual é de reconciliação/validação do existente, e não de criação de 35 novas entidades.

## Correção do resolvedor

Problema anterior:

os mappings PESTEL/SWOT/TOWS/RISK utilizavam:

`create_new_entity_by_source_key`

e:

`allows_existing_entity = false`

Isso poderia propor duplicação mesmo quando a entidade já existia.

Migration aplicada em DEV:

`20261003213000_reconcile_existing_diagnostic_targets.sql`

A migration:

- amplia `canonical_entity_by_code` para:
  - pestel_item;
  - swot_item;
  - tows_item;
  - strategic_risk_item;
- cria mapping version 2 para os quatro mappings;
- supersede version 1;
- ativa `allows_existing_entity=true`;
- mantém `allows_create_new=true`;
- usa estratégia `hybrid`;
- resolve entidade existente por código exato no mesmo projeto;
- somente propõe criação quando nenhum alvo exato existe;
- mantém revisão humana obrigatória;
- não permite inferência semântica.

## Resultado da resolução v2

Para os 35 registros do v26:

`resolution_mode = existing_entity`

Todos possuem:

`target_entity_id != null`

Distribuição dos 426 itens reconciliados:

- PESTEL: 78/78 existing_entity;
- SWOT: 108/108 existing_entity;
- TOWS: 70/70 existing_entity;
- RISK: 170/170 existing_entity.

Nenhuma decisão de incorporação foi registrada.

## UX de revisão humana

Edge Function:

`skpe-import-incorporation`

Status DEV:

- ACTIVE;
- version: 4;
- verify_jwt: true.

Melhorias:

1. ação por registro:
   `Validar todos os campos deste registro`;
2. exige confirmação humana;
3. exige justificativa;
4. grava evento individual para cada campo;
5. bloqueia revisão em lote se houver campo não fornecido;
6. não executa materialização;
7. pacote passa a ordenar resolução por `resolved_at`, evitando apresentar evento antigo por empate de sequence;
8. pacote passa a retornar `targetSnapshot`;
9. tabela de revisão passa a exibir:
   - Valor recebido;
   - Valor atual no SPARKs.

## Validação técnica

Contratos focados:

- `diagnosticExistingTargetResolutionContract.test.ts`;
- `incorporationReviewPreparationContract.test.ts`.

Resultado:

**8/8 PASS**

## Commits funcionais

- `89eb1b92296d54ebd040fb017c9a18fc29c87dd9` — revisão humana por registro;
- `bd1d3fd8da750e8a0a4db048c0339ecae49ed32a` — reconciliação de alvo existente;
- `14d340b9d3a7a7bf454a6b04bad608053e179872` — estratégia canônica hybrid;
- `f1ae22e8e2f7548470d2bad98dc0f4f28fa9cb6f` — comparação origem x SPARKs.

## Próximo gate

Validação humana visual do lote v26.

O usuário deve:

1. Administração da Organização;
2. Importação e Exportação;
3. retomar o lote:
   `SPARKs_PE_Sistema_Gestao_Estrategica_COOTAQUARA_v26_PRE_VALIDACAO_PEM-02.04.xlsx`;
4. abrir `Dados históricos do Diagnóstico — revisão humana`;
5. abrir um registro PESTEL, SWOT, TOWS ou Risco;
6. confirmar que o pacote exibe:
   - resolução como entidade existente;
   - Valor recebido;
   - Valor atual no SPARKs;
7. conferir o conteúdo;
8. se o registro estiver correto, usar:
   `Validar todos os campos deste registro`;
9. informar justificativa humana;
10. não registrar decisão de incorporação ainda, até validar a experiência em pelo menos um registro de cada tipo.

Após essa validação de UX e conteúdo, o próximo gate é a revisão/decisão dos 35 requests.
