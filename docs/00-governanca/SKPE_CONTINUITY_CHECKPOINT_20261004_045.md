# SK-PE — Checkpoint de Continuidade — 2026-10-04 — 045

Status: ATIVO
Gate: PEM-04.02 — Comunicação e Mobilização governada

## Continuidade

Anterior:

`SKPE_CONTINUITY_CHECKPOINT_20261004_044.md`

Branch:

`recovery/2026-09-13-recent-ux-preservation`

## PEM-04.02 — Comunicação e Mobilização

Não existia authority específica para esta etapa.

Foi criada uma estrutura canônica mínima, sem mecanismo de disparo automático.

## Autoridades criadas

### Pacote

`skpe_implementation_communication_packages`

Representa o Plano de Comunicação e Mobilização da implementação.

Campos centrais:

- organization_id;
- project_id;
- formulation_id;
- status;
- owner_user_id;
- validation_notes;
- submitted_for_validation_at/by;
- validated_at/by;
- metadata.

Estados:

- in_elaboration;
- pending_validation;
- validated;
- returned_for_adjustment.

### Itens

`skpe_implementation_communication_items`

Cada item representa uma combinação governada de:

- público;
- objetivo de comunicação;
- mensagem-chave;
- canal;
- cadência;
- responsável;
- início/fim planejados;
- ação de mobilização;
- exigência de evidência;
- evidência vinculada;
- status;
- validação.

## Integração de evidências

Quando houver evidência de comunicação/mobilização:

`evidence_asset_id → sparks_evidence_assets`

Portanto:

**PEM-04.02 não cria uma authority paralela de evidências.**

## Segurança

RLS habilitado nas duas tabelas.

Leitura:

`can_view_skpe_formulation`

Gestão:

`can_manage_skpe_formulation`

Validação:

`can_validate_skpe_formulation`

## Funções canônicas

### Criar/obter pacote

`ensure_skpe_pem0402_communication_package(formulation_id)`

Não é executada automaticamente pela migration.

### Criar/editar item

`upsert_skpe_pem0402_communication_item(...)`

Características:

- exige change_reason;
- exige permissão de gestão;
- não permite edição silenciosa de pacote validado;
- alteração devolve pacote para elaboração;
- não dispara comunicação.

### Readiness

`get_skpe_pem0402_communication_readiness(formulation_id, include_package_state)`

Reutiliza:

`get_skpe_pem0401_activation_readiness`

Bloqueadores:

- PEM-04.01 sem prontidão;
- pacote ausente;
- owner do plano ausente;
- nenhum item;
- item incompleto;
- item sem responsável;
- item sem data planejada;
- item sem validação final;
- pacote não validado.

## Conteúdo mínimo por item

Todo item precisa explicitar:

- público;
- objetivo;
- mensagem;
- canal;
- cadência;
- responsável;
- início planejado.

A validação humana é obrigatória antes da conclusão.

## Fluxo de validação

Função:

`transition_skpe_pem0402_communication_package`

Ações:

- submit_validation;
- validate;
- return_for_adjustments.

### Submit

Só ocorre quando o conteúdo está metodologicamente completo.

### Validate

Exige:

- permissionamento de validação;
- justificativa humana;
- conteúdo sem pendências.

A validação marca:

- itens = validated;
- pacote = validated;
- validated_at/by;
- validation_notes.

### Return for adjustments

- registra justificativa;
- retorna o pacote;
- itens pendentes voltam para draft quando aplicável.

## Guard de conclusão

Função:

`skpe_guard_pem0402_completion()`

Trigger:

`skpe_pem0402_completion_guard`

PEM-04.02 só pode assumir `completed` quando:

`readyForCompletion = true`

Ao concluir legitimamente, grava:

- communicationPackageId;
- readinessVerifiedAt;
- readinessSnapshot;
- automaticSendingPerformed = false.

## Regra de não automação

O contrato explicita:

`automaticSendingEnabled = false`

e a UI informa:

- nenhum e-mail;
- nenhuma mensagem;
- nenhum aviso;
- nenhuma convocação

é enviado por esta capacidade.

## UI

Novo componente:

`StrategicCommunicationMobilizationReadinessSection`

A superfície apresenta:

- status do pacote;
- quantidade de itens;
- quantidade de itens validados;
- envio automático = Não;
- bloqueadores;
- estado de prontidão.

Quando:

`current_stage_code = PEM-04.02`

a Formulação abre a aba:

`plan`

onde o painel é apresentado.

## Migration

Aplicada no DEV:

`20261004170000_govern_pem0402_communication_mobilization.sql`

## Testes

Executados:

- pem0402CommunicationMobilization.test.ts;
- pem0401ActivationReadiness.test.ts;
- pem04ImplementationSequence.test.ts.

Resultado:

**11/11 PASS**

## Build

`vite build`

Resultado:

**PASS**

- 2213 módulos transformados;
- warning não bloqueante de chunk > 500 kB.

## Verificação de não fabricação — COOTAQUARA

Após aplicação:

- communication packages = 0;
- communication items = 0;
- PEM-04.01 = not_started;
- PEM-04.02 = not_started;
- PEM-04.03 = not_started.

Portanto:

**nenhum Plano de Comunicação, público, mensagem, canal, mobilização ou decisão foi fabricado.**

## Próximo gate

**PEM-04.03 — CAPACIDADES E GESTÃO DA MUDANÇA**

Preparar, sem iniciar:

1. lacunas de capacidade para executar o portfólio;
2. capacidades organizacionais requeridas;
3. ações de desenvolvimento;
4. impactos de mudança;
5. públicos impactados;
6. responsáveis;
7. riscos de adoção;
8. evidências;
9. validação humana;
10. conclusão fail-closed.
