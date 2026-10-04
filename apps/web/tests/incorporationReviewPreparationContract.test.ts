import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261003143000_prepare_import_incorporation_review.sql', import.meta.url),
  'utf8',
)
const edge = readFileSync(
  new URL('../../../supabase/functions/skpe-import-incorporation/index.ts', import.meta.url),
  'utf8',
)
const staging = readFileSync(
  new URL('../src/modules/portability/CanonicalImportStaging.tsx', import.meta.url),
  'utf8',
)

test('review preparation orchestrates governed runtime without strategic materialization', () => {
  assert.match(migration, /skpe_prepare_import_incorporation_review/)
  assert.match(migration, /skpe_create_import_incorporation_request/)
  assert.match(migration, /skpe_resolve_import_target/)
  assert.match(migration, /skpe_add_import_incorporation_item/)
  assert.match(migration, /skpe_evaluate_import_incorporation_request/)
  assert.match(migration, /mapping_definition -> 'field_map'/)
  assert.match(migration, /'structured_mapping'/)
  assert.match(migration, /'semanticInference',false/)
  assert.match(migration, /'materializationExecuted',false/)
  assert.doesNotMatch(migration, /skpe_execute_governed_import_materialization\(/)
})

test('review preparation is retry-safe and service-role only', () => {
  assert.match(migration, /request_status not in \('rejected','cancelled','superseded','applied'\)/)
  assert.match(migration, /v_reused_request := true/)
  assert.match(migration, /incorporation_request_id=v_request_id/)
  assert.match(migration, /source_field_name=v_source_field/)
  assert.match(migration, /target_field_name=v_target_field/)
  assert.match(migration, /revoke all on function public\.skpe_prepare_import_incorporation_review[\s\S]*from authenticated/)
  assert.match(migration, /grant execute on function public\.skpe_prepare_import_incorporation_review[\s\S]*to service_role/)
})

test('edge function authenticates and authorizes before privileged orchestration', () => {
  assert.match(edge, /verify|Authorization/)
  assert.match(edge, /userClient\.auth\.getUser\(\)/)
  assert.match(edge, /can_manage_skpe_journey/)
  assert.match(edge, /is_platform_super_admin/)
  assert.match(edge, /Sem permissão para operar esta incorporação/)
  assert.match(edge, /SUPABASE_SERVICE_ROLE_KEY/)
  assert.match(edge, /skpe_prepare_import_incorporation_review/)
})

test('edge function exposes governed human review and decision without materialization', () => {
  assert.match(edge, /'prepare_review' \| 'get_review' \| 'get_batch_review_queue' \| 'review_item' \| 'review_request_items' \| 'review_batch_integral_matches' \| 'decide_request'/)
  assert.match(edge, /human_bulk_review: true/)
  assert.match(edge, /human_batch_confirmation: true/)
  assert.match(edge, /validation_scope: 'migration_correspondence_only'/)
  assert.match(edge, /historical_business_approval_preserved: true/)
  assert.match(edge, /business_decision_repeated: false/)
  assert.match(edge, /DEFERRED_STRUCTURED_LINKAGE/)
  assert.match(edge, /mitigation_business_approval_preserved: isRisk/)
  assert.match(edge, /approved_mitigation_input: isRisk && fieldName === 'treatment_plan'/)
  assert.match(edge, /mitigation_development_stage: isRisk \? 'strategic_initiatives' : null/)
  assert.match(edge, /A revisão deve ser feita campo a campo/)
  assert.match(edge, /materializationExecuted: false/)
  assert.match(edge, /skpe_import_incorporation_items/)
  assert.match(edge, /skpe_import_target_resolution_events/)
  assert.match(edge, /skpe_import_incorporation_decisions/)
  assert.match(edge, /order\('resolved_at', \{ ascending: false \}\)/)
  assert.match(edge, /targetSnapshot/)
  assert.match(edge, /skpe_pestel_items/)
  assert.match(edge, /skpe_swot_items/)
  assert.match(edge, /skpe_tows_items/)
  assert.match(edge, /skpe_strategic_risk_items/)
  assert.match(edge, /skpe_review_import_incorporation_item/)
  assert.match(edge, /skpe_record_import_incorporation_decision/)
  assert.match(edge, /skpe_evaluate_import_incorporation_request/)
  assert.match(edge, /skpe_confirm_import_record_from_governed_review/)
  assert.match(edge, /eligible_with_reservations/)
  assert.doesNotMatch(edge, /skpe_execute_governed_import_materialization/)
})

test('staging exposes preparation UX without approval or materialization CTA', () => {
  assert.match(staging, /Fila governada de revisão pré-carga/)
  assert.match(staging, /Preservação histórica \/ proveniência/)
  assert.match(staging, /Reconciliação com registro existente/)
  assert.match(staging, /Criação canônica controlada/)
  assert.match(staging, /Decisão formal histórica/)
  assert.match(staging, /Abrir revisão/)
  assert.match(staging, /Atualizar dados para revisão/)
  assert.match(staging, /prepareAllIncorporationReviews/)
  assert.match(staging, /for \(const candidate of incorporationCandidates\)/)
  assert.match(staging, /Nenhuma aprovação ou incorporação foi executada/)
  assert.match(staging, /supabase\.functions\.invoke\('skpe-import-incorporation'/)
  assert.match(staging, /action: 'prepare_review'/)
  assert.match(staging, /Revisão aberta/)
  assert.match(staging, /reviewIncorporationItem/)
  assert.match(staging, /validateAllIncorporationItems/)
  assert.match(staging, /Confirmar informações/)
  assert.match(staging, /Homologar somente Diagnóstico já aprovado/)
  assert.match(staging, /diagnosticReviewCount/)
  assert.match(staging, /review_batch_integral_matches/)
  assert.match(staging, /get_batch_review_queue/)
  assert.doesNotMatch(staging, /\.from\('skpe_import_incorporation_requests'\)/)
  assert.doesNotMatch(staging, /\.from\('skpe_import_incorporation_items'\)/)
  assert.match(staging, /aprovações de negócio e dos vínculos técnicos a estruturar posteriormente/)
  assert.match(staging, /Recebido do histórico/)
  assert.match(staging, /Atual no SPARKs/)
  assert.match(staging, /reviewValuesEqual/)
  assert.match(staging, /Igual/)
  assert.match(staging, /Diferença/)
  assert.match(staging, /review-match/)
  assert.match(staging, /review-difference/)
  assert.match(staging, /Detalhes da importação/)
  assert.match(staging, /scrollIntoView/)
  assert.match(staging, /action: 'review_request_items'/)
  assert.match(staging, /decideIncorporationRequest/)
  assert.match(staging, /Aprovar informação/)
  assert.match(staging, /A incorporação definitiva ao planejamento permanece bloqueada/)
  assert.doesNotMatch(staging, />Materializar</)
})
