import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const workspace = readFileSync(
  new URL('../src/modules/initiatives/economics/InitiativeEconomicExecutionDialog.tsx', import.meta.url),
  'utf8',
)

test('initiative economics integrates physical progress, economic execution and schedule from canonical sources', () => {
  assert.match(workspace, /from\('sparks_initiatives'\)/)
  assert.match(workspace, /progress,start_date,target_end_date/)
  assert.match(workspace, /forecast_start_date,forecast_end_date/)
  assert.match(workspace, /Execução física × econômica × prazo/)
  assert.match(workspace, /Progresso físico/)
  assert.match(workspace, /Consumo do orçamento direto/)
  assert.match(workspace, /Consumo do esforço direto/)
  assert.match(workspace, /Término-alvo/)
  assert.match(workspace, /Forecast de término/)
})

test('action-level physical financial view uses governed action facts without mixed-unit conversion', () => {
  assert.match(workspace, /from\('sparks_initiative_actions'\)/)
  assert.match(workspace, /planned_cost,actual_cost,currency_code/)
  assert.match(workspace, /estimated_effort,actual_effort,effort_unit/)
  assert.match(workspace, /Leitura físico-financeira por ação/)
  assert.match(workspace, /Desvio de custo/)
  assert.match(workspace, /Moedas diferentes e unidades de esforço diferentes permanecem separadas/)
})

test('management interpretation stays factual and does not create a synthetic evaluation', () => {
  assert.match(workspace, /Leitura factual para a gestão/)
  assert.match(workspace, /não classifica automaticamente a iniciativa como boa ou ruim/)
  assert.match(workspace, /comparação indisponível por ausência de valor planejado ou realizado/)
  assert.match(workspace, /Ausência de dado permanece como ausência/)
})
