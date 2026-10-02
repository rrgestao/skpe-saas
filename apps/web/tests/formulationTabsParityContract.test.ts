import assert from 'node:assert/strict'
import test from 'node:test'
import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const testDir = dirname(fileURLToPath(import.meta.url))
const appCss = readFileSync(join(testDir, '../src/App.css'), 'utf8')
const designSystemCss = readFileSync(
  join(testDir, '../src/components/design-system/design-system.css'),
  'utf8',
)

test('Formulação herda o mesmo contrato transparente de WorkspaceTabs do Diagnóstico', () => {
  assert.match(
    designSystemCss,
    /\.sparks-workspace-tabs \{[\s\S]*?background: transparent;/,
  )
  assert.match(
    appCss,
    /\.skpe-strategic-formulation > \.sparks-workspace-tabs \{[\s\S]*?background: transparent !important;/,
  )
  assert.doesNotMatch(
    appCss,
    /\.skpe-strategic-formulation > \.sparks-workspace-tabs \{[\s\S]*?background: var\(--skpe-surface, #ffffff\) !important;/,
  )
})
