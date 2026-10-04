# SK-PE — Checkpoint de Continuidade — 2026-10-04 — 032

Status: ATIVO
Gate: COOTAQUARA — Preflight da nova v26 preparado / submissão ainda não executada

## Continuidade

Anterior:

`SKPE_CONTINUITY_CHECKPOINT_20261004_031.md`

Branch:

`recovery/2026-09-13-recent-ux-preservation`

## Premissa de negócio vigente

Já ocorreu validação humana com a COOTAQUARA.

Resultado informado:

- 4 Temas Estratégicos aprovados sem adequações;
- 5 Perspectivas Estratégicas aprovadas sem adequações;
- 10 Objetivos Estratégicos aprovados sem adequações.

Informante registrado:

- Ricardo Rodrigues;
- ricardo.rodrigues@sparkoop.com;
- Líder da SPARKOOP neste projeto.

A planilha + HTML v26 gerados após essa reunião permanecem **não submetidos**.

## Problema identificado no parser atual

A v26 de referência já possui:

- `50_Temas_Perspectivas`;
- `51_Validacao_PEM0204`.

Porém o parser:

- não mapeava estruturalmente a aba 50;
- não mapeava estruturalmente a aba 51;
- tratava a aba 51 apenas como conflito auxiliar;
- hardcodava:
  `PEM-02.04 — Pré-validação`
  mesmo se as decisões estivessem preenchidas.

Isso poderia fazer a solução ignorar o fato de que a nova v26 já contém resultado de validação.

## Evolução do parser

`parseCanonicalWorkbook.ts` passou a mapear:

### Aba 50

`strategic_positioning_reference`

Finalidade:

preservar Temas e Perspectivas como referência estruturada de posicionamento.

### Aba 51

`positioning_validation`

Finalidade:

preservar decisões estruturadas de validação para:

- Tema;
- Perspectiva;
- Objetivo Estratégico.

## Preflight de validação

Foi criado:

`PositioningValidationPreflight`

Campos:

- themesExpected;
- themesDecided;
- perspectivesExpected;
- perspectivesDecided;
- objectivesExpected;
- objectivesDecided;
- totalExpected;
- totalDecided;
- complete;
- approvedWithoutChanges;
- reconciliationState;
- blockers.

Estados possíveis:

- not_submitted;
- incomplete;
- reported_approved_without_changes;
- requires_manual_review.

## Regra de aprovação sem adequações

Uma decisão só é tratada como aprovação sem adequações quando:

- existe decisão explícita;
- representa aprovação/manutenção;
- não contém sinal de:
  - ajuste;
  - alteração;
  - substituição;
  - remoção;
  - reserva;
  - ressalva;
  - aprovação parcial.

O parser reconhece expressões como:

- Manter;
- Aprovado;
- Aprovado integralmente;
- Aprovado sem ajustes;
- Aprovado sem alterações.

Qualquer sinal divergente leva a revisão humana.

## Contagens esperadas

O preflight deriva:

- Temas: da aba 50;
- Perspectivas: da aba 50;
- Objetivos: da aba 09.

Para a COOTAQUARA de referência:

- Temas esperados: 4;
- Perspectivas esperadas: 5;
- Objetivos esperados: 10;
- total esperado: 19.

## Comportamento fail-closed

Mesmo quando:

- 19/19 decisões existem;
- todas representam aprovação;
- todas são aprovação sem adequações;

o parser continua retornando:

`databaseWrites = false`

e classifica apenas:

`reported_approved_without_changes`

A Jornada exibida no preview passa a ser:

`PEM-02.03 — validação informada; reconciliação canônica pendente`

Próximo passo:

`Reconciliar v26 com o atestado recebido antes de liberar PEM-02.04`

Portanto:

**v26 aprovada não promove automaticamente o canônico.**

## Conflito REC-004

O conflito PEM-02.04 deixou de ser hardcoded.

Quando a validação está incompleta:

- PEM-02.04 permanece bloqueado.

Quando a validação está completa e sem adequações:

- o preview reconhece o fato reportado;
- informa que promoção canônica depende de reconciliação governada com o atestado de Ricardo Rodrigues.

## UI de staging

`CanonicalImportStaging` ganhou:

**Preflight PEM-02.03 / v26**

Antes de criar lote em staging, a UI exibe:

- Temas decididos / esperados;
- Perspectivas decididas / esperadas;
- Objetivos decididos / esperados;
- estado de reconciliação;
- bloqueadores;
- aviso explícito de que nenhum estado canônico é promovido nesse passo.

Quando 19/19 estão aprovados sem adequações:

`Validação estruturada reportada como aprovada sem adequações`

Ainda assim:

`Reconciliação canônica continua pendente.`

## Testes

`parseCanonicalWorkbook.test.ts`

Passou a validar dois cenários:

### v26 ainda não deliberada

- 4 Temas esperados;
- 5 Perspectivas esperadas;
- 10 OEs esperados;
- 0 decisões;
- estado = incomplete;
- PEM-02.03 permanece pendente.

### v26 aprovada integralmente

- strategic_positioning_reference = 9 registros;
- positioning_validation = 19 registros;
- 19/19 decisões;
- complete = true;
- approvedWithoutChanges = true;
- reconciliationState = reported_approved_without_changes;
- 0 blockers;
- databaseWrites = false;
- reconciliação canônica permanece pendente.

Novo teste:

`v26PositioningPreflightUi.test.ts`

valida a exposição do preflight antes do staging.

Resultado:

**5/5 PASS**

## Build

`vite build`

Resultado:

**PASS**

Warning não bloqueante:

- chunks > 500 kB;
- tempo elevado em plugins CSS.

## Estado atual

A nova v26 real ainda NÃO foi submetida.

Nenhum:

- novo batch;
- novo ImportRecord;
- novo request;
- novo estado approved;
- avanço de Jornada

foi criado nesta passagem.

## Próximo gate

**SELECIONAR A v26 REAL E EXECUTAR SOMENTE O PREFLIGHT LOCAL**

Quando o usuário decidir fornecer/selecionar a nova v26:

1. ler localmente;
2. conferir 4/4 Temas;
3. conferir 5/5 Perspectivas;
4. conferir 10/10 OEs;
5. confirmar 19/19 decisões;
6. confirmar aprovação sem adequações;
7. comparar com o atestado registrado;
8. NÃO criar lote ainda se houver divergência;
9. somente depois autorizar staging governado.

Até lá:

`SUBMISSION = NO`

`CANONICAL_PROMOTION = NO`

`PEM-02.04 = BLOCKED`
