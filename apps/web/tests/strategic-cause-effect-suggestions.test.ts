import assert from 'node:assert/strict'
import test from 'node:test'

import type { StrategicMapObjective } from '../src/modules/skpe/contracts/strategic-map.ts'
import { resolveStrategicCauseEffectSuggestions } from '../src/modules/skpe/features/strategy/strategicCauseEffectSuggestions.ts'

const titles: Record<string, string> = {
  'OE-01': 'Fortalecer a governança e a disciplina de execução da estratégia',
  'OE-02': 'Desenvolver lideranças, pessoas e cultura cooperativista orientadas à estratégia',
  'OE-03': 'Padronizar processos críticos e fortalecer controles e dados gerenciais',
  'OE-04': 'Assegurar qualidade, segurança dos alimentos, conformidade e inovação responsável',
  'OE-05': 'Ampliar a participação dos cooperados e a oferta organizada da produção',
  'OE-06': 'Fortalecer o desenvolvimento produtivo, econômico e inclusivo dos cooperados',
  'OE-07': 'Diversificar clientes, canais e mercados com posicionamento de valor',
  'OE-08': 'Elevar margem, eficiência econômico-financeira e capacidade de investimento',
  'OE-09': 'Fortalecer o relacionamento e a geração de valor compartilhado com a comunidade',
  'OE-10': 'Gerar e demonstrar impacto cooperativista, social, ambiental e territorial',
}

function objective(code: string): StrategicMapObjective {
  return {
    id: code.toLowerCase(),
    code,
    title: titles[code]!,
    description: null,
    expectedResult: null,
    rationale: null,
    strategicThemeId: null,
    perspectiveId: null,
    priority: null,
    horizonStart: null,
    horizonEnd: null,
    ownerUserId: null,
    status: 'active',
    validationStatus: 'draft',
    progress: 0,
    displayOrder: 100,
    mapPosition: null,
    visualColor: null,
    metadata: {},
    createdAt: '2026-09-03T00:00:00Z',
    updatedAt: '2026-09-03T00:00:00Z',
  }
}

test('resolves suggestions only for the exact objective signature', () => {
  const objectives = Object.keys(titles).map(objective)
  const suggestions = resolveStrategicCauseEffectSuggestions(objectives)

  assert.equal(suggestions.length, 13)
  assert.ok(
    suggestions.some(
      (suggestion) =>
        suggestion.sourceCode === 'OE-01' && suggestion.targetCode === 'OE-03',
    ),
  )
  assert.ok(
    suggestions.some(
      (suggestion) =>
        suggestion.sourceCode === 'OE-09' && suggestion.targetCode === 'OE-10',
    ),
  )
})

test('does not leak contextual suggestions into another objective set', () => {
  const objectives = Object.keys(titles).map(objective)
  objectives[0] = { ...objectives[0]!, title: 'Outro objetivo' }

  assert.deepEqual(resolveStrategicCauseEffectSuggestions(objectives), [])
})