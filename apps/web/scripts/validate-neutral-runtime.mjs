import { readFileSync, existsSync } from 'node:fs'
import { resolve } from 'node:path'
import { createClient } from '@supabase/supabase-js'

const EXPECTED_ORG_CODE = 'SKPE-V1-RUNTIME'
const EXPECTED_PROJECT_CODE = 'PE-SKPE-V1-RUNTIME-2026'

function loadEnvFile(path) {
  if (!existsSync(path)) return
  const content = readFileSync(path, 'utf8')
  for (const rawLine of content.split(/\r?\n/)) {
    const line = rawLine.trim()
    if (!line || line.startsWith('#')) continue
    const separator = line.indexOf('=')
    if (separator <= 0) continue
    const key = line.slice(0, separator).trim()
    const value = line.slice(separator + 1).trim().replace(/^['"]|['"]$/g, '')
    if (!(key in process.env)) process.env[key] = value
  }
}

function fail(message) {
  console.error('[E2E-NEUTRAL][FAIL]', message)
  process.exitCode = 1
  throw new Error(message)
}

function ok(message) {
  console.log('[E2E-NEUTRAL][OK]', message)
}

loadEnvFile(resolve(process.cwd(), '.env.local'))
loadEnvFile(resolve(process.cwd(), '.env.e2e.local'))

const supabaseUrl = process.env.VITE_SUPABASE_URL
const supabaseKey =
  process.env.VITE_SUPABASE_PUBLISHABLE_KEY ||
  process.env.VITE_SUPABASE_ANON_KEY
const email = process.env.SKPE_E2E_EMAIL
const password = process.env.SKPE_E2E_PASSWORD
const requestedOrgCode = process.env.SKPE_E2E_ORG_CODE || EXPECTED_ORG_CODE

if (!supabaseUrl || !supabaseKey) {
  fail('Configuração Supabase ausente. Defina VITE_SUPABASE_URL e VITE_SUPABASE_PUBLISHABLE_KEY.')
}

if (requestedOrgCode !== EXPECTED_ORG_CODE) {
  fail(`Execução recusada: o harness só pode operar em ${EXPECTED_ORG_CODE}.`)
}

if (!email || !password) {
  fail(
    'Credencial técnica E2E ausente. Defina SKPE_E2E_EMAIL e SKPE_E2E_PASSWORD em .env.e2e.local ou no ambiente; nunca versione esses valores.',
  )
}

const supabase = createClient(supabaseUrl, supabaseKey, {
  auth: {
    persistSession: false,
    autoRefreshToken: false,
    detectSessionInUrl: false,
  },
})

const { data: authData, error: authError } =
  await supabase.auth.signInWithPassword({ email, password })

if (authError || !authData.user) {
  fail('Falha no login técnico E2E. Verifique a credencial sem alterar o tenant de validação.')
}
ok('Login técnico autenticado.')

const { data: organizations, error: orgError } = await supabase
  .from('organizations')
  .select('id,code,status')
  .eq('code', EXPECTED_ORG_CODE)
  .limit(2)

if (orgError) fail(`Não foi possível localizar o tenant neutro: ${orgError.message}`)
if ((organizations ?? []).length !== 1) {
  fail(`Esperada exatamente uma organização ${EXPECTED_ORG_CODE}.`)
}

const organization = organizations[0]
if (organization.status !== 'active') {
  fail(`Tenant neutro não está ativo; situação atual: ${organization.status}.`)
}
ok(`Tenant neutro confirmado: ${organization.code}.`)

const { data: membership, error: membershipError } = await supabase
  .from('organization_memberships')
  .select('status,is_organization_admin')
  .eq('organization_id', organization.id)
  .eq('user_id', authData.user.id)
  .eq('status', 'active')
  .maybeSingle()

if (membershipError) {
  fail(`Não foi possível validar membership do usuário técnico: ${membershipError.message}`)
}
if (!membership) fail('Usuário técnico não possui membership ativo no tenant neutro.')
if (!membership.is_organization_admin) {
  fail('Usuário técnico deve ser administrador da organização neutra para o E2E governado.')
}
ok('Membership técnico ativo e com administração da organização.')

const { data: projects, error: projectError } = await supabase
  .from('skpe_projects')
  .select('id,code,status,current_phase_code,progress')
  .eq('organization_id', organization.id)
  .is('archived_at', null)
  .eq('code', EXPECTED_PROJECT_CODE)
  .limit(2)

if (projectError) fail(`Falha ao carregar projeto neutro: ${projectError.message}`)
if ((projects ?? []).length !== 1) {
  fail(`Esperado exatamente um projeto técnico ${EXPECTED_PROJECT_CODE}.`)
}

const project = projects[0]
ok(`Projeto neutro confirmado em ${project.current_phase_code}, progresso ${project.progress}%.`)

const { data: journey, error: journeyError } = await supabase.rpc(
  'get_skpe_journey_temporal_read_model',
  {
    target_organization_id: organization.id,
    target_project_id: project.id,
    target_as_of_date: null,
  },
)

if (journeyError) {
  fail(`Falha ao carregar Jornada governada: ${journeyError.message}`)
}

const rows = Array.isArray(journey) ? journey : []
const pem0001 = rows.find((row) => row.item_code === 'PEM-00.01')
const pem0203 = rows.find((row) => row.item_code === 'PEM-02.03')
const pem0204 = rows.find((row) => row.item_code === 'PEM-02.04')

if (!pem0001 || !pem0203 || !pem0204) {
  fail('Jornada neutra incompleta: itens de controle esperados não foram encontrados.')
}
ok('Jornada canônica carregada com itens de controle.')

if (pem0203.item_status === 'completed') {
  fail('Pré-condição do teste fail-closed não é válida: PEM-02.03 já está concluído.')
}

const { error: blockedTransitionError } = await supabase.rpc(
  'set_skpe_journey_item_status',
  {
    target_item_id: pem0204.item_id,
    target_status: 'in_progress',
    target_progress: 0,
    change_reason:
      'Validação E2E neutra: comprovar bloqueio por dependência metodológica não atendida.',
  },
)

if (!blockedTransitionError) {
  fail('Falha grave: PEM-02.04 avançou sem PEM-02.03 concluído.')
}

if (!String(blockedTransitionError.message).includes('PEM-02.03')) {
  fail(
    `A transição foi bloqueada, mas por motivo inesperado: ${blockedTransitionError.message}`,
  )
}
ok('Fail-closed comprovado: PEM-02.04 não avança antes de PEM-02.03 concluído.')

const { data: afterRows, error: afterError } = await supabase
  .from('skpe_journey_items')
  .select('code,status,progress')
  .eq('project_id', project.id)
  .in('code', ['PEM-00.01', 'PEM-02.03', 'PEM-02.04'])

if (afterError) fail(`Falha ao conferir estado pós-teste: ${afterError.message}`)

const afterPem0204 = (afterRows ?? []).find((row) => row.code === 'PEM-02.04')
if (!afterPem0204 || afterPem0204.status !== pem0204.item_status) {
  fail('O teste de bloqueio alterou indevidamente o estado de PEM-02.04.')
}

ok('Estado da Jornada permaneceu íntegro após a tentativa bloqueada.')
console.log('[E2E-NEUTRAL] PRECHECK PASS — nenhuma decisão institucional foi fabricada.')
await supabase.auth.signOut()
