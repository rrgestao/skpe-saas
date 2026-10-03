# SK-PE — Checkpoint de Continuidade — 2026-10-03 — 017

Status: ATIVO
Gate: COOTAQUARA — Riscos Estratégicos Aprovados e Ressalvas Técnicas de Estruturação

## Continuidade

Anterior: `SKPE_CONTINUITY_CHECKPOINT_20261003_016.md`

SHA funcional:

`deacaa2ca8765a22c5e7857970941a2aed5183e3`

## Autoridade de negócio

A Gestão da COOTAQUARA aprovou integralmente o Diagnóstico Estratégico.

Isso inclui:

- PESTEL;
- SWOT;
- TOWS;
- os 10 Riscos Estratégicos;
- as propostas de mitigação associadas aos riscos.

Nenhum dos 10 Riscos Estratégicos foi alterado pela COOTAQUARA durante a aprovação.

As propostas de mitigação também foram aprovadas.

Essas propostas permanecem como insumos aprovados e deverão ser melhor desenvolvidas, detalhadas e estruturadas quando a Jornada chegar à etapa própria de Iniciativas do Planejamento Estratégico.

## Correção da interpretação anterior

Uma comparação técnica anterior entre os lotes v17 e v26 detectou diferenças e foi interpretada, indevidamente, como possível alteração dos riscos.

Essa interpretação fica revogada.

Diferença técnica de representação, serialização, vínculo ou estrutura de dados não equivale a mudança de decisão de negócio.

## Diagnóstico técnico dos 10 riscos

Cada Risco possui 17 campos preparados para reconciliação.

Resultado:

- 15/17 campos por risco coincidem com o registro atual do SPARKs;
- 2/17 campos por risco ainda não possuem vínculo estruturado no modelo atual.

Os dois campos são os mesmos nos 10 riscos:

1. `monitoring_evidence`
   - histórico contém códigos como E01, E02, E06 etc.;
   - registro atual ainda não possui o vínculo estruturado;

2. `related_objective_codes`
   - histórico contém o valor `Futuro`;
   - associação objetiva ainda não está estruturada porque os Objetivos do PE serão consolidados na continuidade da Jornada.

Esses dois casos não são divergências substantivas.

## Mitigação

O campo canônico:

`treatment_plan`

está preservado nos Riscos e representa as propostas de mitigação aprovadas.

Regra canônica:

`Risco aprovado -> mitigação proposta aprovada -> desenvolvimento posterior na etapa de Iniciativas do PE`

A aprovação da mitigação não significa que a iniciativa executiva já esteja integralmente especificada.

Ela significa que:

- a direção de resposta/mitigação foi aprovada;
- o conteúdo deve ser preservado;
- a transformação em iniciativa completa ocorrerá no gate próprio de Iniciativas.

## Nova regra de homologação

A ação governada:

`review_batch_integral_matches`

passa a aceitar dois resultados de homologação:

### Correspondência integral

Todos os campos coincidem.

Resultado dos itens:

`validated`

### Correspondência aprovada com ressalva técnica

Aplicável atualmente aos Riscos quando as únicas diferenças forem:

- `monitoring_evidence`;
- `related_objective_codes`.

Os demais campos devem coincidir.

Resultado desses dois itens:

`validated_with_reservations`

Reservation:

`DEFERRED_STRUCTURED_LINKAGE`

Os demais campos:

`validated`

## Metadados auditáveis

Para os Riscos homologados, os eventos registram:

- `diagnostic_business_approval_preserved = true`;
- `risk_business_approval_preserved = true`;
- `mitigation_business_approval_preserved = true`;
- `approved_mitigation_input = true` no campo `treatment_plan`;
- `mitigation_development_stage = strategic_initiatives`;
- `deferred_structured_linkage = true` nos dois vínculos técnicos;
- `business_decision_repeated = false`;
- `semantic_inference = false`;
- `materialization_requested = false`.

## UX

A seção passa a ser denominada:

`Dados históricos do Diagnóstico — homologação da migração`

A mensagem deixa explícito que:

- o Diagnóstico já foi aprovado integralmente;
- os Riscos e mitigações já foram aprovados;
- esta etapa apenas homologa a migração;
- vínculos técnicos ainda não estruturados são ressalvas de implementação;
- a decisão de negócio não é reaberta.

A ação principal passa a ser:

`Homologar Diagnóstico aprovado em lote`

## Runtime DEV

Edge Function:

`skpe-import-incorporation`

Estado:

- ACTIVE;
- version: 7;
- verify_jwt: true.

## Validação

Contratos focados:

- `incorporationReviewPreparationContract.test.ts`;
- `diagnosticExistingTargetResolutionContract.test.ts`.

Resultado:

**8/8 PASS**

O build completo permaneceu bloqueado no `tsc -b` sem emitir erro, comportamento já recorrente neste ambiente; o processo foi encerrado sem alterar o runtime.

## Próximo gate

Ação humana na UI:

1. atualizar a página;
2. retomar o lote v26;
3. acessar `Dados históricos do Diagnóstico — homologação da migração`;
4. clicar `Homologar Diagnóstico aprovado em lote`;
5. confirmar a mensagem;
6. manter ou ajustar a justificativa;
7. verificar o resultado esperado:
   - 10 Riscos homologados;
   - 170 campos tratados;
   - 20 campos homologados com ressalva técnica;
   - nenhuma diferença substantiva;
   - nenhuma incorporação definitiva executada;
8. confirmar que a fila de Diagnóstico fica vazia após a homologação.
