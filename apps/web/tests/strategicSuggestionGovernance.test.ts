import assert from 'node:assert/strict'
import test from 'node:test'

import {
  type GovernedStrategicSuggestion,
  validateGovernedStrategicSuggestion,
} from '../src/modules/skpe/contracts/strategic-suggestion-governance.ts'

function validSuggestion(): GovernedStrategicSuggestion {
  return {
    suggestionId: 'SUG-001', phaseCode: 'PEM-02', stageCode: 'PEM-02.04',
    elementType: 'strategic_theme', action: 'keep', currentValue: 'Prosperidade',
    proposedValue: null, evidenceReferences: ['EVD-001'],
    sources: [{ kind: 'sk_km', reference: 'DOC-001', title: 'Referência canônica', reliability: 'canonical' }],
    motivation: 'O elemento permanece aderente aos desafios identificados.',
    justification: 'As evidências atuais não sustentam alteração.',
    maturityFit: 'Compatível com o estágio de maturidade requerido.',
    visionAlignment: 'Contribui diretamente para a Visão aprovada.',
    valueContribution: 'Preserva foco e valor estratégico.',
    confidence: 'high', status: 'pending_human_validation', humanDecision: null,
  }
}
test('KEEP é recomendação válida quando fundamentada e submetida à validação humana', () => {
  const result = validateGovernedStrategicSuggestion(validSuggestion())
  assert.equal(result.ok, true)
})

test('sugestão sem evidência, fonte, motivação ou justificativa é bloqueada', () => {
  const suggestion = validSuggestion()
  suggestion.evidenceReferences = []
  suggestion.sources = []
  suggestion.motivation = ''
  suggestion.justification = ''

  const result = validateGovernedStrategicSuggestion(suggestion)
  assert.equal(result.ok, false)
  assert.ok(result.errors.includes('evidence_required'))
  assert.ok(result.errors.includes('source_required'))
  assert.ok(result.errors.includes('motivation_required'))
  assert.ok(result.errors.includes('justification_required'))
})

test('benchmark exige comparabilidade e aplicabilidade explícitas', () => {
  const suggestion = validSuggestion()
  suggestion.sources = [{ kind: 'benchmark', reference: 'BMK-01', title: 'Benchmark', reliability: 'official' }]
  const result = validateGovernedStrategicSuggestion(suggestion)
  assert.equal(result.ok, false)
  assert.ok(result.errors.includes('benchmark_comparability_required'))
  assert.ok(result.errors.includes('benchmark_applicability_required'))
})
test('decisão final nunca é aceita sem deliberação humana rastreável', () => {
  const suggestion = validSuggestion()
  suggestion.status = 'approved'
  suggestion.humanDecision = null

  const result = validateGovernedStrategicSuggestion(suggestion)
  assert.equal(result.ok, false)
  assert.ok(result.errors.includes('human_decision_required'))
})

test('ajuste aprovado exige identificação, data e motivo da decisão humana', () => {
  const suggestion = validSuggestion()
  suggestion.action = 'adjust'
  suggestion.proposedValue = 'Prosperidade Sustentável'
  suggestion.status = 'adjusted'
  suggestion.humanDecision = {
    decision: 'adjusted', decidedBy: 'USR-01', decidedAt: '2026-09-12T20:00:00-03:00',
    reason: 'Ajuste aprovado após análise crítica da Direção.', adjustedValue: 'Prosperidade Sustentável',
  }

  const result = validateGovernedStrategicSuggestion(suggestion)
  assert.equal(result.ok, true)
})

import { readFileSync } from 'node:fs'

test('Formulação Estratégica expõe o contrato transversal de sugestão e validação humana', () => {
  const source = readFileSync(
    new URL('../src/modules/skpe/features/strategy/StrategicFormulationSection.tsx', import.meta.url),
    'utf8',
  )
  assert.match(source, /phase2SuggestionGovernanceNotice/)
  assert.match(source, /Governança das sugestões da Fase 2/)
  assert.match(source, /Análise assistida e validação humana/)
})

test('contrato preserva as cinco ações canônicas de recomendação', () => {
  for (const action of ['keep', 'adjust', 'replace', 'add', 'remove'] as const) {
    const suggestion = validSuggestion()
    suggestion.action = action
    if (['adjust', 'replace', 'add'].includes(action)) suggestion.proposedValue = 'Novo valor'
    if (action === 'remove') suggestion.currentValue = 'Elemento vigente'
    const result = validateGovernedStrategicSuggestion(suggestion)
    assert.equal(result.ok, true, `ação ${action} deve ser válida`)
  }
})
