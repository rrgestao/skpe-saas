# SK-PE — Checkpoint de Continuidade — 2026-10-04 — 035

Status: ATIVO
Gate: PEM-02.05 — validação humana de relações causais governada

## Continuidade

Anterior:

`SKPE_CONTINUITY_CHECKPOINT_20261004_034.md`

Branch:

`recovery/2026-09-13-recent-ux-preservation`

## Objetivo da passagem

Fechar a lacuna entre:

- hipótese causal sugerida;
- relação causal registrada;
- decisão humana sobre a relação;
- readiness do Mapa;
- versão oficial do Mapa Estratégico.

A solução deve ser replicável para COOTAQUARA, COOPERCOMPANY e QUERUBIM.

## Estado anterior

O backend já possuía:

- `upsert_skpe_objective_relation(...)`;
- racional causal;
- tipo e força da relação;
- prevenção de auto-relação;
- controle de ciclos;
- trilha operacional;
- invalidação do Mapa quando uma relação muda;
- `get_skpe_strategic_map_readiness(...)`;
- workflow de validação/versionamento do Mapa;
- `capture_skpe_strategic_map_version(...)`.

A UI já registrava relações com metadata:

- assistance.generated = true;
- assistance.scope;
- assistance.confidence;
- assistance.humanValidationRequired = true.

Porém não existia decisão humana específica e auditável por relação.

## Lacuna identificada

Uma relação marcada como hipótese poderia existir no Mapa sem um ledger próprio de validação.

O readiness não bloqueava explicitamente:

- relação sem decisão humana;
- relação rejeitada;
- Objetivo ativo desconectado da arquitetura causal.

## Ledger append-only

Migration:

`20261004052000_govern_causal_relation_validation.sql`

Tabela criada:

`skpe_objective_relation_validation_events`

Cada evento registra:

- organização;
- projeto;
- formulação;
- relação causal;
- sequência da decisão;
- ação;
- justificativa;
- usuário decisor;
- data/hora;
- evento anterior substituído;
- metadata.

Ações permitidas:

- `validate`;
- `reject`.

A tabela é append-only para usuários autenticados.

## RPC de validação

Criada:

`record_skpe_objective_relation_validation(...)`

Regras:

1. exige relação causal existente;
2. exige decisão `validate` ou `reject`;
3. exige justificativa com pelo menos 10 caracteres;
4. exige `can_validate_skpe_formulation`;
5. exige Formulação editável;
6. gera sequência append-only;
7. preserva `supersedes_event_id`;
8. registra `auth.uid()`;
9. registra auditoria operacional;
10. invalida readiness anterior do Mapa para reavaliação;
11. não altera a relação causal.

Metadata preserva:

`canonical_relation_mutated = false`

## Readiness causal

`get_skpe_strategic_map_readiness(...)` foi envolvido por nova camada canônica.

Novas pendências bloqueantes:

### CAUSAL_RELATION_VALIDATION_PENDING

Existe relação registrada sem decisão humana.

### CAUSAL_RELATION_REJECTED

Existe relação rejeitada que ainda precisa ser removida/reformulada.

### OBJECTIVE_WITHOUT_CAUSAL_LINK

Existe OE ativo que não participa de nenhuma relação causal, quando há mais de um OE ativo.

Novos dados:

`causalValidation.pendingRelationValidations`

`causalValidation.rejectedRelations`

`causalValidation.disconnectedObjectives`

`readyForValidation` permanece false enquanto qualquer uma dessas pendências existir.

## Estado atual COOTAQUARA

Na Formulação atual:

- relações causais registradas: 1;
- relações marcadas como humanValidationRequired: 1;
- eventos de validação causal: 0.

Portanto:

**a relação atual é hipótese registrada e ainda não está validada humanamente.**

Nenhuma decisão foi fabricada.

## Bloqueio temporal da edição causal

Foi encontrada uma brecha adicional:

o layout estava bloqueado fora de PEM-02.05, mas o gestor de relações causais ainda poderia ser aberto.

Correção:

- o gestor de relações só aparece quando `canAdjustLayout = true`;
- o sidepanel só renderiza quando PEM-02.05 está legitimamente liberado;
- `persistCausalRelation` também verifica `canAdjustLayout`;
- fora de PEM-02.05, tentativa de alteração retorna:
  `Relações causais só podem ser alteradas durante PEM-02.05.`

Assim, a proteção não depende somente da visibilidade de um botão.

## UI de validação causal

Em PEM-02.05, cada relação registrada passa a mostrar um estado:

- Pendente de validação humana;
- Validada humanamente;
- Rejeitada — requer reformulação.

Cada relação oferece:

- Validar;
- Rejeitar;
- justificativa obrigatória;
- revisão posterior da decisão.

A decisão é registrada no ledger append-only.

Mensagem pós-registro:

`Decisão humana registrada. O readiness do Mapa será recalculado sem alterar a relação causal.`

## Relação entre edição e validação

Editar uma relação:

- continua alterando o conteúdo da hipótese;
- invalida a validação anterior do Mapa;
- exige nova avaliação.

Validar/rejeitar uma relação:

- não altera origem/destino;
- não altera tipo;
- não altera força;
- não altera racional;
- registra somente decisão humana auditável.

## Versão oficial

O workflow já existente permanece autoridade:

`transition_skpe_strategic_map(..., 'validate', ...)`

Ao validar o Mapa:

- readiness é verificado;
- o pacote é validado;
- `capture_skpe_strategic_map_version(...)` cria versão oficial;
- revisão posterior exige `begin_revision`;
- versão oficial anterior é preservada.

Nenhuma versão oficial foi criada nesta passagem.

## Testes

Executados:

- causalRelationValidationGovernance.test.ts;
- causalRelationValidationUi.test.ts;
- strategicMapReadinessPanel.test.ts;
- strategicMapStageLock.test.ts.

Resultado:

**7/7 PASS**

## Build

`vite build`

Resultado:

**PASS**

- 2199 módulos transformados;
- warning não bloqueante de chunk > 500 kB.

## Efeito no DEV

Migration aplicada no DEV.

Não houve:

- validação de relação;
- rejeição de relação;
- alteração da relação existente;
- validação do Mapa;
- captura de versão oficial;
- avanço de PEM-02.05.

## Próximo gate

**VALIDAÇÃO DO PACOTE DO MAPA E VERSÃO OFICIAL**

Preparar a UI/workflow para:

1. consumir o readiness atualizado;
2. só habilitar envio para validação quando não houver bloqueadores;
3. exigir decisão humana do pacote do Mapa;
4. capturar versão oficial imutável na validação;
5. apresentar número/id da versão oficial;
6. permitir revisão apenas via `begin_revision`;
7. vincular conclusão de PEM-02.05 à existência de Mapa validado/versionado;
8. somente então liberar PEM-02.GATE.

Estado preservado:

`PEM-02.03 = reconciliação documental pendente`

`PEM-02.04 = bloqueado`

`PEM-02.05 = protegido`

`MAP_VALIDATION = NO`

`OFFICIAL_VERSION = NO`
