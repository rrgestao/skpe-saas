import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const panel = readFileSync(
  new URL('../src/modules/skpe/features/monitoring/MonitoringStrategyReviewPanel.tsx', import.meta.url),
  'utf8',
)
const migration = readFileSync(
  new URL('../../../supabase/migrations/20261007224000_harden_strategic_learning_lifecycle.sql', import.meta.url),
  'utf8',
)

test('RAE UI hydrates existing review and freezes analysis/decision after ratification', () => {
  assert.match(panel, /scheduled_at,held_at,executive_summary,conclusions,minutes_reference/)
  assert.match(panel, /setScheduledAt\(dateTimeLocalValue\(selectedReview\.scheduled_at\)\)/)
  assert.match(panel, /reviewMutable/)
  assert.match(panel, /disabled=\{!canGovern \|\| !reviewMutable\}/)
  assert.match(panel, /reviewCanRatify/)
})

test('review item requiring decision can be linked to the governance decision', () => {
  assert.match(panel, /skpe_strategy_review_items/)
  assert.match(panel, /selectedReviewItemId/)
  assert.match(panel, /strategyReviewItemId: selectedReviewItemId \|\| null/)
  assert.match(panel, /decisão obrigatória/)
})

test('learning lifecycle is executable in UI only after ratified critical review', () => {
  assert.match(panel, /learningEntryAllowed/)
  assert.match(panel, /transition_skpe_strategic_learning/)
  assert.match(panel, /Enviar para análise/)
  assert.match(panel, /Aceitar/)
  assert.match(panel, /Rejeitar/)
  assert.match(panel, /Incorporar aprendizado/)
  assert.match(panel, /Reabrir/)
  assert.match(panel, /interpretação, lição e recomendação substantivas/)
})

test('database enforces ordered learning transitions and explicit governance', () => {
  assert.match(migration, /Somente aprendizado identificado pode ser encaminhado para análise/)
  assert.match(migration, /Aceite ou rejeição exige aprendizado em análise/)
  assert.match(migration, /Somente aprendizado aceito pode ser incorporado/)
  assert.match(migration, /Somente aprendizado rejeitado ou arquivado pode ser reaberto/)
  assert.match(migration, /Aprendizado de alto impacto exige decisão de governança explícita para aceite/)
  assert.match(migration, /A incorporação exige decisão de governança explícita/)
})
