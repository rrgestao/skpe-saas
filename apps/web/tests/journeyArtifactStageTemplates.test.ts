import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261005215500_enrich_journey_artifact_stage_templates.sql', import.meta.url),
  'utf8',
)

test('future Journey artifact templates are stage-specific through PEM-05', () => {
  for (const code of [
    'PEM-03.01','PEM-03.02','PEM-03.03','PEM-03.04',
    'PEM-04.01','PEM-04.02','PEM-04.03','PEM-04.04',
    'PEM-05.01','PEM-05.02','PEM-05.03','PEM-05.04',
  ]) {
    assert.ok(migration.includes(`when '${code}' then`), `missing stage template for ${code}`)
  }
})

test('validation artifacts demand explicit human decisions without fabricating approval', () => {
  assert.match(migration, /aprovar/)
  assert.match(migration, /aprovar com ajustes/)
  assert.match(migration, /devolver para revisão/)
  assert.match(migration, /não representa decisão institucional, aprovação, evidência ou aceite/)
})

test('stage templates preserve core methodology distinctions', () => {
  assert.match(migration, /2026–2030/)
  assert.match(migration, /Ciclo de Evolução/)
  assert.match(migration, /Benchmark é referência comparativa, não evidência própria/)
  assert.match(migration, /Iniciativas podem ser substituídas/)
  assert.match(migration, /Aceitação exige justificativa explícita/)
  assert.match(migration, /Diferenciar causa comprovada de hipótese/)
})
