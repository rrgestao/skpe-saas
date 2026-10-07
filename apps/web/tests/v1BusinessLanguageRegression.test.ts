import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const files = {
  monitoring: readFileSync(new URL('../src/modules/skpe/features/monitoring/MonitoringPackageConfigurationPanel.tsx', import.meta.url), 'utf8'),
  map: readFileSync(new URL('../src/modules/skpe/features/strategy/StrategicMapLifecyclePanel.tsx', import.meta.url), 'utf8'),
  positioningReadiness: readFileSync(new URL('../src/modules/skpe/features/strategy/StrategicPositioningReadinessPanel.tsx', import.meta.url), 'utf8'),
  positioning: readFileSync(new URL('../src/modules/skpe/features/strategy/StrategicPositioningSection.tsx', import.meta.url), 'utf8'),
  initiatives: readFileSync(new URL('../src/modules/skpe/features/strategy/StrategicInitiativePlanSection.tsx', import.meta.url), 'utf8'),
  preview: readFileSync(new URL('../src/modules/portability/CanonicalWorkbookImportPreview.tsx', import.meta.url), 'utf8'),
  staging: readFileSync(new URL('../src/modules/portability/CanonicalImportStaging.tsx', import.meta.url), 'utf8'),
  portability: readFileSync(new URL('../src/modules/portability/PortabilityAdmin.tsx', import.meta.url), 'utf8'),
}

test('primary strategic headings use business language instead of internal methodology codes', () => {
  assert.ok(files.monitoring.includes('Configuração do monitoramento estratégico'))
  assert.ok(!files.monitoring.includes('<h3>Configuração metodológica FE-08</h3>'))

  assert.ok(files.map.includes('Governança do Mapa Estratégico'))
  assert.ok(files.map.includes('Prontidão para validação'))
  assert.ok(!files.map.includes('<small>Readiness</small>'))

  assert.ok(files.positioningReadiness.includes('Prontidão das escolhas e do posicionamento'))
  assert.ok(!files.positioningReadiness.includes('Prontidão de PEM-02.03'))

  assert.ok(files.positioning.includes('<span>Escolhas e Posicionamento Estratégico</span>'))
  assert.ok(files.positioning.includes('Próxima etapa · Objetivos Estratégicos'))
  assert.ok(!files.positioning.includes('<span>PEM-02.03 · Escolhas e Posicionamento Estratégico</span>'))

  assert.ok(files.initiatives.includes('Prontidão do portfólio estratégico'))
  assert.ok(!files.initiatives.includes('PEM-03.03 · Prontidão do portfólio'))
})

test('portability presents import governance in business language', () => {
  assert.ok(files.preview.includes('Preparar pacote de importação com controle de qualidade'))
  assert.ok(files.preview.includes('Qualidade da importação'))
  assert.ok(!files.preview.includes('Gerar payload completo com controle de qualidade'))
  assert.ok(!files.preview.includes('Qualidade do payload'))

  assert.ok(files.portability.includes('área de conferência, simulação, revisão humana e materialização governada'))
  assert.ok(files.staging.includes('enviado à área de conferência'))
  assert.ok(files.staging.includes('passou pela conferência inicial'))
  assert.ok(files.staging.includes('registro em conferência'))
})
