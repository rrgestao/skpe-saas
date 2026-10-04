# SK-PE — Checkpoint de Continuidade — 2026-10-04 — 046

Status: ATIVO
Gate: PEM-04.03 — Capacidades e Gestão da Mudança governada

## Continuidade

Anterior:

`SKPE_CONTINUITY_CHECKPOINT_20261004_045.md`

Branch:

`recovery/2026-09-13-recent-ux-preservation`

## Princípio arquitetural

A auditoria confirmou que capacidade quantitativa de pessoas já possui authority transversal:

- `sparks_person_capacity_periods`;
- `sparks_person_capacity_allocations`;
- `get_sparks_person_capacity_projection`;
- funções governadas de configuração/alocação.

Portanto:

**PEM-04.03 não duplica capacidade quantitativa no SK-PE.**

O SK-PE registra:

- lacunas estratégicas;
- impactos de mudança;
- tratamento necessário;
- responsáveis;
- prazo;
- risco de adoção;
- evidência.

## Autoridades criadas

### Pacote

`skpe_implementation_change_packages`

Representa a avaliação consolidada de Capacidades e Gestão da Mudança.

Aplicabilidade:

- undetermined;
- applicable;
- no_material_gap.

Estados:

- in_elaboration;
- pending_validation;
- validated;
- returned_for_adjustment.

### Itens

`skpe_implementation_change_items`

Tipos de lacuna:

- people_capacity;
- competency;
- process;
- technology;
- behavior;
- governance;
- other.

Cada item registra:

- público impactado;
- estado atual;
- estado requerido;
- descrição da lacuna;
- tratamento;
- owner;
- prazo;
- risco de adoção;
- indicação se exige referência quantitativa de capacidade;
- evidência;
- validação.

## Cenário sem lacuna material

O modelo não obriga a organização a inventar problemas.

Pode ser declarado:

`applicability = no_material_gap`

desde que exista justificativa explícita e validação humana.

## Integração com capacidade SPARKs

Quando uma lacuna:

- gap_type = people_capacity;
- capacity_reference_required = true;

o readiness exige existência de períodos de capacidade ativos na authority transversal.

Assim, o SK-PE referencia capacidade real sem criar segunda fonte da verdade.

## Evidências

`evidence_asset_id → sparks_evidence_assets`

Não foi criada authority paralela de evidências.

## Readiness

Função:

`get_skpe_pem0403_change_readiness(formulation_id, include_package_state)`

Pré-requisito:

`get_skpe_pem0402_communication_readiness(...).readyForCompletion = true`

Bloqueadores:

- PEM-04.02 não validada;
- pacote ausente;
- owner ausente;
- aplicabilidade não definida;
- no_material_gap sem justificativa;
- applicable sem itens;
- item incompleto;
- item sem owner;
- item sem prazo;
- item sem validação final;
- lacuna quantitativa de pessoas sem capacity authority disponível;
- pacote não validado.

## Funções de gestão

### Criar/obter pacote

`ensure_skpe_pem0403_change_package`

### Configurar aplicabilidade

`configure_skpe_pem0403_change_package`

### Criar/editar lacuna

`upsert_skpe_pem0403_change_item`

### Fluxo de validação

`transition_skpe_pem0403_change_package`

Ações:

- submit_validation;
- validate;
- return_for_adjustments.

Validação exige:

- conteúdo metodologicamente completo;
- permissionamento;
- justificativa humana.

## Guard de conclusão

Função:

`skpe_guard_pem0403_completion()`

Trigger:

`skpe_pem0403_completion_guard`

PEM-04.03 só pode assumir `completed` quando:

`readyForCompletion = true`

Ao concluir legitimamente, grava:

- changePackageId;
- applicability;
- readinessVerifiedAt;
- readinessSnapshot.

## UI

Novo componente:

`StrategicCapabilitiesChangeReadinessSection`

Exibe:

- aplicabilidade;
- status do pacote;
- lacunas/impactos registrados;
- períodos de capacidade ativos;
- alocações de capacidade ativas;
- bloqueadores;
- authorities utilizadas.

Quando:

`current_stage_code = PEM-04.03`

a Formulação abre a aba:

`plan`

## Migration

Aplicada no DEV:

`20261004174500_govern_pem0403_capabilities_change.sql`

## Testes

Executados:

- pem0403CapabilitiesChange.test.ts;
- pem0402CommunicationMobilization.test.ts;
- pem0401ActivationReadiness.test.ts.

Resultado:

**12/12 PASS**

## Build

`vite build`

Resultado:

**PASS**

- 2215 módulos transformados;
- warning não bloqueante de chunk > 500 kB.

## Verificação de não fabricação — COOTAQUARA

Após aplicação:

- change packages = 0;
- change items = 0;
- PEM-04.02 = not_started;
- PEM-04.03 = not_started;
- PEM-04.04 = not_started.

Portanto:

**nenhuma lacuna, impacto de mudança, capacidade, alocação, tratamento ou decisão foi fabricada.**

## Próximo gate

**PEM-04.04 — GESTÃO DE RISCOS DA IMPLEMENTAÇÃO**

Preparar, sem iniciar:

1. consumir riscos das iniciativas e riscos estratégicos já validados;
2. não duplicar risco;
3. identificar riscos específicos da implementação;
4. exigir owner;
5. exigir resposta/tratamento;
6. distinguir risco aceito de risco sem tratamento;
7. exigir evidência quando aplicável;
8. integrar com ações de mitigação;
9. validação humana;
10. conclusão fail-closed.
