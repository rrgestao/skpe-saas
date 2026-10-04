# SK-PE — Checkpoint de Continuidade — 2026-10-04 — 030

Status: ATIVO
Gate: COOTAQUARA — PEM-02.03 preparado para validação humana auditável

## Continuidade

Anterior:

`SKPE_CONTINUITY_CHECKPOINT_20261004_029.md`

Branch:

`recovery/2026-09-13-recent-ux-preservation`

Batch v26:

`0ad2aea6-fa95-457a-af2c-5bff0354bdfa`

## Fronteira metodológica preservada

Princípio aplicado:

- antecipar implicações é permitido;
- consolidar decisões sem evidência suficiente não é permitido.

Portanto, o avanço desta passagem prepara a validação humana de PEM-02.03, mas não valida Tema/Perspectiva e não altera conteúdo canônico.

## Estado factual de PEM-02.03

### Temas Estratégicos

4 registros:

- TE-01;
- TE-02;
- TE-03;
- TE-04.

Todos:

- status = draft;
- source_status = Hipótese técnica — não submetida;
- validation_status = pending_validation.

### Perspectivas Estratégicas

5 registros:

- PE-01;
- PE-02;
- PE-03;
- PE-04;
- PE-05.

Todos possuem:

- metadata.validation_status = pending_validation.

O status técnico `active` das perspectivas não representa aprovação institucional.

### Objetivos Estratégicos

10 registros:

- OE-01 a OE-10.

Todos:

- status = draft;
- source_status = Hipótese técnica — não submetida;
- validation_gate = PEM-02.04.

PEM-02.04 permanece bloqueado.

## Contexto da etapa corrente

O projeto canônico registra:

`current_phase_code = PEM-02`

O read model da Jornada registra a subetapa ativa:

`PEM-02.03 = in_progress`

O contexto frontend foi evoluído para derivar:

- current_stage_code;
- current_stage_name.

A Formulação usa `current_stage_code` para selecionar a etapa visual corrente.

Quando:

`current_stage_code = PEM-02.03`

a Formulação recebe:

`initialTab = positioning`

Nenhuma progressão da Jornada é alterada por esse comportamento.

## Ledger append-only de validação humana

Migration criada e aplicada no DEV:

`20261004035500_create_positioning_validation_events.sql`

Tabela:

`skpe_positioning_validation_events`

Finalidade:

Registrar decisões humanas de PEM-02.03 sem alterar imediatamente Tema/Perspectiva.

### Entidades suportadas

- strategic_theme;
- bsc_perspective.

### Ações suportadas

- keep;
- adjust;
- replace;
- remove.

### Propriedades de governança

Cada evento preserva:

- organização;
- projeto;
- formulação;
- entidade;
- código da entidade;
- sequência;
- ação;
- nome proposto;
- descrição proposta;
- justificativa;
- referências de evidência;
- usuário decisor;
- timestamp;
- decisão substituída;
- metadata.

A tabela é append-only para usuários autenticados:

- SELECT permitido conforme can_view_skpe_journey;
- INSERT/UPDATE/DELETE diretos revogados;
- registro somente por RPC governada.

## RPC de decisão

Criada e aplicada:

`record_skpe_positioning_validation_decision(...)`

A RPC:

1. exige Formulação e entidade válidas;
2. aceita apenas Tema/Perspectiva;
3. aceita apenas manter/ajustar/substituir/remover;
4. exige justificativa com pelo menos 10 caracteres;
5. exige proposta para ajustar/substituir;
6. exige `can_validate_skpe_formulation`;
7. exige Formulação editável;
8. bloqueia entidade já validada/aprovada;
9. cria nova sequência append-only;
10. preserva evento anterior por `supersedes_event_id`;
11. registra auditoria operacional;
12. define:
   - canonical_mutation_applied = false;
   - next_gate = PEM-02.03_CONSOLIDATION.

A RPC NÃO executa:

- UPDATE em skpe_strategic_themes;
- UPDATE em skpe_bsc_perspectives;
- mudança de status da Jornada;
- liberação de PEM-02.04.

## UI de validação

`StrategicPositioningSection` foi ligada ao ledger.

Cada Tema e Perspectiva oferece, apenas para quem possui permissão canônica de validação:

- Manter;
- Ajustar;
- Substituir;
- Remover.

A UI permite registrar:

- decisão;
- nome proposto quando aplicável;
- descrição proposta quando aplicável;
- justificativa;
- referência de evidência opcional.

Mensagem pós-registro:

`Decisão registrada. O conteúdo canônico ainda não foi alterado.`

Usuários sem permissão permanecem em modo de consulta.

## Leitura de decisões

A tela lê:

`skpe_positioning_validation_events`

e apresenta a decisão mais recente por entidade.

Decisões posteriores não apagam as anteriores.

A sequência histórica permanece auditável.

## Estado inicial do ledger

Após aplicação da migration:

- RPC existente: YES;
- eventos de decisão para a Formulação COOTAQUARA: 0.

Portanto:

**nenhuma decisão humana foi fabricada nesta passagem.**

## Testes

### positioningValidationLedger.test.ts

Valida:

- ledger append-only;
- ausência de mutação canônica;
- ações permitidas;
- permissão canônica;
- auth.uid();
- auditoria operacional;
- exigência de justificativa;
- exigência de proposta para ajustar/substituir.

Resultado:

**3/3 PASS**

### Suite integrada PEM-02.03

Executados:

- positioningValidationLedger.test.ts;
- strategicPositioningValidationState.test.ts;
- strategicPositioningNavigation.test.ts.

Resultado:

**10/10 PASS**

## Build

`vite build`

Resultado:

**PASS**

- 2199 módulos transformados;
- warning não bloqueante de bundle/chunk permanece.

## DEV

A rota autenticada da Formulação foi aberta novamente na RMKB-NTB para a validação humana.

A captura gráfica do Windows estava temporariamente indisponível por erro de `CopyFromScreen`, porém:

- RMKB-NTB permanece online;
- aplicação DEV permanece acessível;
- contrato funcional e build passaram.

## Próximo gate — HUMANO

**VALIDAR OS 4 TEMAS E AS 5 PERSPECTIVAS**

Para cada item, registrar uma das decisões:

- Manter;
- Ajustar;
- Substituir;
- Remover.

Obrigatório:

- justificativa;
- proposta quando Ajustar/Substituir.

Opcional:

- referência de evidência.

Após as 9 decisões:

1. auditar completude;
2. apresentar consolidação das escolhas;
3. somente mediante confirmação humana explícita aplicar alterações no canônico;
4. avaliar conclusão de PEM-02.03;
5. somente depois considerar liberação de PEM-02.04.

## Estado preservado

Batch v26:

`145/145 applied`

`DEFINITIVE_LOAD = YES`

Jornada:

`MF1 aprovada; MF2 em andamento; PEM-02.03 em validação; PEM-02.04 bloqueado.`
