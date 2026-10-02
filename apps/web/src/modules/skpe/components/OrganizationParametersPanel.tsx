import { useEffect, useMemo, useState } from 'react'

import { supabase } from '../../../lib/supabase'
import { translateBackendMessage } from '../../../shared/i18n/ptBR'

type EffectiveParameter = {
  parameter_key: string
  name: string
  value_type: 'number' | 'text' | 'boolean' | 'json'
  unit: string | null
  value: number | string | boolean | Record<string, unknown>
  default_value: number | string | boolean | Record<string, unknown>
  source_scope: string
}

type Props = {
  organizationId: string
  canManage: boolean
}

const PARAMETER_KEYS = [
  'SKPE.JOURNEY.DURATION_MODE',
  'SKPE.JOURNEY.ACCELERATED_DURATION',
  'SKPE.JOURNEY.POST_DELIVERY_FOLLOWUP',
  'SKPE.JOURNEY.PEM02.01_DURATION','SKPE.JOURNEY.PEM02.02_DURATION','SKPE.JOURNEY.PEM02.03_DURATION','SKPE.JOURNEY.PEM02.04_DURATION','SKPE.JOURNEY.PEM02.05_DURATION',
  'SKPE.JOURNEY.PEM03.01_DURATION','SKPE.JOURNEY.PEM03.02_DURATION','SKPE.JOURNEY.PEM03.03_DURATION','SKPE.JOURNEY.PEM03.04_DURATION',
  'SKPE.JOURNEY.PEM04.01_DURATION','SKPE.JOURNEY.PEM04.02_DURATION','SKPE.JOURNEY.PEM04.03_DURATION','SKPE.JOURNEY.PEM04.04_DURATION',
  'SKPE.JOURNEY.PEM00.01_DURATION','SKPE.JOURNEY.PEM00.02_DURATION','SKPE.JOURNEY.PEM00.03_DURATION','SKPE.JOURNEY.PEM00.04_DURATION',
  'SKPE.JOURNEY.PEM00.05_DURATION','SKPE.JOURNEY.PEM00.06_DURATION','SKPE.JOURNEY.PEM00.07_DURATION','SKPE.JOURNEY.PEM00.08_DURATION',
  'SKPE.JOURNEY.PEM01.01_DURATION','SKPE.JOURNEY.PEM01.02_DURATION','SKPE.JOURNEY.PEM01.03_DURATION','SKPE.JOURNEY.PEM01.04_DURATION','SKPE.JOURNEY.PEM01.05_DURATION','SKPE.JOURNEY.PEM01.06_DURATION',
  'SKPE.PERFORMANCE.DEVIATION.ADEQUATE_MAX_PERCENT','SKPE.PERFORMANCE.DEVIATION.ATTENTION_MAX_PERCENT',
] as const

type ParameterKey = (typeof PARAMETER_KEYS)[number]
type DraftState = Record<ParameterKey, string>

const INITIAL_DRAFT: DraftState = {
  'SKPE.JOURNEY.DURATION_MODE':'business_days','SKPE.JOURNEY.ACCELERATED_DURATION':'45','SKPE.JOURNEY.POST_DELIVERY_FOLLOWUP':'90',
  'SKPE.JOURNEY.PEM02.01_DURATION':'2','SKPE.JOURNEY.PEM02.02_DURATION':'5','SKPE.JOURNEY.PEM02.03_DURATION':'5','SKPE.JOURNEY.PEM02.04_DURATION':'7','SKPE.JOURNEY.PEM02.05_DURATION':'6',
  'SKPE.JOURNEY.PEM03.01_DURATION':'4','SKPE.JOURNEY.PEM03.02_DURATION':'6','SKPE.JOURNEY.PEM03.03_DURATION':'6','SKPE.JOURNEY.PEM03.04_DURATION':'4',
  'SKPE.JOURNEY.PEM04.01_DURATION':'5','SKPE.JOURNEY.PEM04.02_DURATION':'3','SKPE.JOURNEY.PEM04.03_DURATION':'4','SKPE.JOURNEY.PEM04.04_DURATION':'3',
  'SKPE.JOURNEY.PEM00.01_DURATION':'1','SKPE.JOURNEY.PEM00.02_DURATION':'1','SKPE.JOURNEY.PEM00.03_DURATION':'1','SKPE.JOURNEY.PEM00.04_DURATION':'1',
  'SKPE.JOURNEY.PEM00.05_DURATION':'2','SKPE.JOURNEY.PEM00.06_DURATION':'1','SKPE.JOURNEY.PEM00.07_DURATION':'2','SKPE.JOURNEY.PEM00.08_DURATION':'1',
  'SKPE.JOURNEY.PEM01.01_DURATION':'3','SKPE.JOURNEY.PEM01.02_DURATION':'3','SKPE.JOURNEY.PEM01.03_DURATION':'4','SKPE.JOURNEY.PEM01.04_DURATION':'3','SKPE.JOURNEY.PEM01.05_DURATION':'4','SKPE.JOURNEY.PEM01.06_DURATION':'3',
  'SKPE.PERFORMANCE.DEVIATION.ADEQUATE_MAX_PERCENT':'15','SKPE.PERFORMANCE.DEVIATION.ATTENTION_MAX_PERCENT':'30',
}

function sourceLabel(scope: string) {
  const labels: Record<string, string> = {
    sparks_default: 'Padrão SPARKs',
    platform: 'Plataforma',
    module: 'Padrão do módulo',
    organization: 'Organização',
    organization_module: 'Organização · SK-PE',
    project: 'Projeto',
  }
  return labels[scope] ?? scope
}

function parameterValueToDraft(value: EffectiveParameter['value']) {
  if (typeof value === 'string' || typeof value === 'number') return String(value)
  if (typeof value === 'boolean') return value ? 'true' : 'false'
  return JSON.stringify(value)
}

export function OrganizationParametersPanel({ organizationId, canManage }: Props) {
  const [parameters, setParameters] = useState<EffectiveParameter[]>([])
  const [draft, setDraft] = useState<DraftState>(INITIAL_DRAFT)
  const [reason, setReason] = useState('')
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null)

  const parameterByKey = useMemo(
    () => new Map(parameters.map((parameter) => [parameter.parameter_key, parameter])),
    [parameters],
  )

  async function loadParameters() {
    setLoading(true)
    setMessage(null)
    const { data, error } = await supabase.rpc('list_sparks_effective_parameters', {
      p_organization_id: organizationId,
      p_module_code: 'SK-PE',
      p_project_id: null,
    })

    if (error) {
      setParameters([])
      setMessage({ type: 'error', text: translateBackendMessage(error.message) })
      setLoading(false)
      return
    }

    const loaded = ((data ?? []) as EffectiveParameter[]).filter((item) =>
      PARAMETER_KEYS.includes(item.parameter_key as ParameterKey),
    )
    setParameters(loaded)
    setDraft((current) => {
      const next = { ...current }
      for (const item of loaded) {
        if (PARAMETER_KEYS.includes(item.parameter_key as ParameterKey)) {
          next[item.parameter_key as ParameterKey] = parameterValueToDraft(item.value)
        }
      }
      return next
    })
    setLoading(false)
  }

  useEffect(() => {
    void loadParameters()
  }, [organizationId])

  async function saveParameter(key: ParameterKey) {
    if (!canManage || saving) return
    if (reason.trim().length < 10) {
      setMessage({ type: 'error', text: 'Informe uma justificativa com pelo menos 10 caracteres.' })
      return
    }

    const definition = parameterByKey.get(key)
    if (!definition) return

    const raw = draft[key]
    const parameterValue = definition.value_type === 'number'
      ? Number(raw)
      : raw

    if (definition.value_type === 'number' && !Number.isFinite(parameterValue)) {
      setMessage({ type: 'error', text: 'Informe um valor numérico válido.' })
      return
    }

    if (key.startsWith('SKPE.PERFORMANCE.DEVIATION.')) {
      const adequateMax = Number(draft['SKPE.PERFORMANCE.DEVIATION.ADEQUATE_MAX_PERCENT'])
      const attentionMax = Number(draft['SKPE.PERFORMANCE.DEVIATION.ATTENTION_MAX_PERCENT'])
      if (!Number.isFinite(adequateMax) || !Number.isFinite(attentionMax) || adequateMax > attentionMax) {
        setMessage({ type: 'error', text: 'A faixa adequada deve ser menor ou igual à faixa de atenção.' })
        return
      }
    }

    setSaving(true)
    setMessage(null)
    const { error } = await supabase.rpc('set_sparks_parameter_value', {
      p_parameter_key: key,
      p_scope_type: 'organization_module',
      p_parameter_value: parameterValue,
      p_organization_id: organizationId,
      p_module_code: 'SK-PE',
      p_project_id: null,
      p_effective_from: null,
      p_effective_until: null,
      p_change_reason: reason.trim(),
    } as never)

    if (error) {
      setMessage({ type: 'error', text: translateBackendMessage(error.message) })
      setSaving(false)
      return
    }

    await loadParameters()
    setMessage({ type: 'success', text: 'Parâmetro da Organização salvo com rastreabilidade.' })
    setSaving(false)
  }

  async function resetParameter(key: ParameterKey) {
    if (!canManage || saving) return
    if (reason.trim().length < 10) {
      setMessage({ type: 'error', text: 'Informe uma justificativa com pelo menos 10 caracteres.' })
      return
    }

    setSaving(true)
    setMessage(null)
    const { error } = await supabase.rpc('clear_sparks_parameter_value', {
      p_parameter_key: key,
      p_scope_type: 'organization_module',
      p_organization_id: organizationId,
      p_module_code: 'SK-PE',
      p_project_id: null,
      p_change_reason: reason.trim(),
    } as never)

    if (error) {
      setMessage({ type: 'error', text: translateBackendMessage(error.message) })
      setSaving(false)
      return
    }

    await loadParameters()
    setMessage({ type: 'success', text: 'Herança restaurada para o padrão SPARKs disponível.' })
    setSaving(false)
  }

  function renderParameter(key: ParameterKey, label: string, help: string) {
    const parameter = parameterByKey.get(key)
    const isOrganizationOverride = parameter?.source_scope === 'organization_module'
    return (
      <div className="skpe-organization-parameter-row" key={key}>
        <div className="skpe-organization-parameter-copy">
          <strong>{label}</strong>
          <span>{help}</span>
          <small>
            Origem efetiva: <b>{sourceLabel(parameter?.source_scope ?? 'sparks_default')}</b>
            {parameter ? ` · Padrão SPARKs: ${parameterValueToDraft(parameter.default_value)}` : ''}
          </small>
        </div>
        <div className="skpe-organization-parameter-control">
          {key === 'SKPE.JOURNEY.DURATION_MODE' ? (
            <select
              value={draft[key]}
              onChange={(event) => setDraft((current) => ({ ...current, [key]: event.target.value }))}
              disabled={!canManage || saving}
            >
              <option value="business_days">Dias úteis</option>
              <option value="calendar_days">Dias corridos</option>
            </select>
          ) : (
            <input
              type="number"
              min={key === 'SKPE.JOURNEY.POST_DELIVERY_FOLLOWUP' || key.startsWith('SKPE.PERFORMANCE.DEVIATION.') ? 0 : 1}
              max={key.startsWith('SKPE.PERFORMANCE.DEVIATION.') ? 100 : 730}
              value={draft[key]}
              onChange={(event) => setDraft((current) => ({ ...current, [key]: event.target.value }))}
              disabled={!canManage || saving}
            />
          )}
          <button type="button" onClick={() => void saveParameter(key)} disabled={!canManage || saving}>
            Salvar
          </button>
          <button
            type="button"
            className="skpe-secondary-button"
            onClick={() => void resetParameter(key)}
            disabled={!canManage || saving || !isOrganizationOverride}
          >
            Restaurar padrão SPARKs
          </button>
        </div>
      </div>
    )
  }

  const pem00PhaseTotal = ['SKPE.JOURNEY.PEM00.01_DURATION','SKPE.JOURNEY.PEM00.02_DURATION','SKPE.JOURNEY.PEM00.03_DURATION','SKPE.JOURNEY.PEM00.04_DURATION','SKPE.JOURNEY.PEM00.05_DURATION','SKPE.JOURNEY.PEM00.06_DURATION','SKPE.JOURNEY.PEM00.07_DURATION','SKPE.JOURNEY.PEM00.08_DURATION'].reduce((sum,key)=>sum+(Number(draft[key as ParameterKey])||0),0)
  const pem01PhaseTotal = ['SKPE.JOURNEY.PEM01.01_DURATION','SKPE.JOURNEY.PEM01.02_DURATION','SKPE.JOURNEY.PEM01.03_DURATION','SKPE.JOURNEY.PEM01.04_DURATION','SKPE.JOURNEY.PEM01.05_DURATION','SKPE.JOURNEY.PEM01.06_DURATION'].reduce((sum,key)=>sum+(Number(draft[key as ParameterKey])||0),0)
  const pem02PhaseTotal = ['SKPE.JOURNEY.PEM02.01_DURATION','SKPE.JOURNEY.PEM02.02_DURATION','SKPE.JOURNEY.PEM02.03_DURATION','SKPE.JOURNEY.PEM02.04_DURATION','SKPE.JOURNEY.PEM02.05_DURATION'].reduce((sum,key)=>sum+(Number(draft[key as ParameterKey])||0),0)
  const pem03PhaseTotal = ['SKPE.JOURNEY.PEM03.01_DURATION','SKPE.JOURNEY.PEM03.02_DURATION','SKPE.JOURNEY.PEM03.03_DURATION','SKPE.JOURNEY.PEM03.04_DURATION'].reduce((sum,key)=>sum+(Number(draft[key as ParameterKey])||0),0)
  const pem04PhaseTotal = ['SKPE.JOURNEY.PEM04.01_DURATION','SKPE.JOURNEY.PEM04.02_DURATION','SKPE.JOURNEY.PEM04.03_DURATION','SKPE.JOURNEY.PEM04.04_DURATION'].reduce((sum,key)=>sum+(Number(draft[key as ParameterKey])||0),0)
  const implementationCadenceTotal = pem00PhaseTotal + pem01PhaseTotal + pem02PhaseTotal + pem03PhaseTotal + pem04PhaseTotal

  return (
    <section className="skpe-organization-parameters-card">
      <div className="skpe-organization-parameters-heading">
        <div>
          <p className="skpe-eyebrow">Configuração herdável</p>
          <h2>Parâmetros da Organização · SK-PE</h2>
          <p>O SPARKs fornece o padrão; a Organização pode adaptar o módulo sem perder rastreabilidade nem a possibilidade de retornar ao default.</p>
        </div>
        <span className="skpe-organization-parameter-badge">SPARKs → Organização → Projeto</span>
      </div>

      {message ? <div className={`skpe-admin-message skpe-admin-message-${message.type}`}>{message.text}</div> : null}
      {loading ? <p>Carregando parâmetros efetivos...</p> : (
        <div className="skpe-organization-parameter-list">
          {renderParameter('SKPE.JOURNEY.DURATION_MODE', 'Contagem da Jornada', 'Escolha entre dias úteis e dias corridos para o planejamento temporal.')}
          {renderParameter('SKPE.JOURNEY.ACCELERATED_DURATION', 'Meta acelerada', 'Referência para cenários de implantação acelerada.')}
          {renderParameter('SKPE.JOURNEY.POST_DELIVERY_FOLLOWUP', 'Acompanhamento pós-entrega · PEM-05', 'Período inicial de Monitoramento e Aprendizado após a entrega da implantação.')}
          <div className="skpe-organization-parameter-copy"><strong>Cadência da implantação</strong><span>Total efetivo atual: {implementationCadenceTotal} dias. PEM-00: {pem00PhaseTotal} · PEM-01: {pem01PhaseTotal} · PEM-02: {pem02PhaseTotal} · PEM-03: {pem03PhaseTotal} · PEM-04: {pem04PhaseTotal}.</span></div>
          <div className="skpe-organization-parameter-copy"><strong>PEM-00 · Fases</strong><span>O total da Megafase é derivado das fases abaixo; o Gate não consome duração própria.</span></div>
          {renderParameter('SKPE.JOURNEY.PEM00.01_DURATION','PEM-00.01 · Abertura, Mandato e Escopo','Cadência default da fase.')}
          {renderParameter('SKPE.JOURNEY.PEM00.02_DURATION','PEM-00.02 · Governança, Papéis e Ritos','Cadência default da fase.')}
          {renderParameter('SKPE.JOURNEY.PEM00.03_DURATION','PEM-00.03 · Caracterização da Organização','Cadência default da fase.')}
          {renderParameter('SKPE.JOURNEY.PEM00.04_DURATION','PEM-00.04 · Checklist Dinâmico','Cadência default da fase.')}
          {renderParameter('SKPE.JOURNEY.PEM00.05_DURATION','PEM-00.05 · Gestão de Evidências','Cadência default da fase.')}
          {renderParameter('SKPE.JOURNEY.PEM00.06_DURATION','PEM-00.06 · Autoavaliações e Diagnósticos','Cadência default da fase.')}
          {renderParameter('SKPE.JOURNEY.PEM00.07_DURATION','PEM-00.07 · Planos de Ação e Follow-up','Cadência default da fase.')}
          {renderParameter('SKPE.JOURNEY.PEM00.08_DURATION','PEM-00.08 · Lacunas, Pendências e Prontidão','Cadência default da fase.')}
          <div className="skpe-organization-parameter-copy"><strong>PEM-01 · Fases</strong><span>O total da Megafase é derivado das fases abaixo; o Gate não consome duração própria.</span></div>
          {renderParameter('SKPE.JOURNEY.PEM01.01_DURATION','PEM-01.01 · Consolidação da Base Diagnóstica','Cadência default da fase.')}
          {renderParameter('SKPE.JOURNEY.PEM01.02_DURATION','PEM-01.02 · Avaliações, Diagnósticos e Planos Anteriores','Cadência default da fase.')}
          {renderParameter('SKPE.JOURNEY.PEM01.03_DURATION','PEM-01.03 · Contexto e PESTEL','Cadência default da fase.')}
          {renderParameter('SKPE.JOURNEY.PEM01.04_DURATION','PEM-01.04 · Partes Interessadas, Mercado e Posicionamento','Cadência default da fase.')}
          {renderParameter('SKPE.JOURNEY.PEM01.05_DURATION','PEM-01.05 · SWOT e TOWS','Cadência default da fase.')}
          {renderParameter('SKPE.JOURNEY.PEM01.06_DURATION','PEM-01.06 · Riscos, Lacunas e Temas Críticos','Cadência default da fase.')}
          <div className="skpe-organization-parameter-copy"><strong>PEM-02 · Fases</strong><span>O total da Megafase é derivado das fases abaixo; o Gate não consome duração própria.</span></div>
          {renderParameter('SKPE.JOURNEY.PEM02.01_DURATION','PEM-02.01 · Abertura da Formulação Estratégica','Cadência default da fase.')}
          {renderParameter('SKPE.JOURNEY.PEM02.02_DURATION','PEM-02.02 · Direcionadores Estratégicos','Cadência default da fase.')}
          {renderParameter('SKPE.JOURNEY.PEM02.03_DURATION','PEM-02.03 · Escolhas e Posicionamento Estratégico','Cadência default da fase.')}
          {renderParameter('SKPE.JOURNEY.PEM02.04_DURATION','PEM-02.04 · Objetivos Estratégicos','Cadência default da fase.')}
          {renderParameter('SKPE.JOURNEY.PEM02.05_DURATION','PEM-02.05 · Modelo Estratégico Futuro','Cadência default da fase.')}
          <div className="skpe-organization-parameter-copy"><strong>PEM-03 · Fases</strong><span>O total da Megafase é derivado das fases abaixo; o Gate não consome duração própria.</span></div>
          {renderParameter('SKPE.JOURNEY.PEM03.01_DURATION','PEM-03.01 · Mapa Estratégico','Cadência default da fase.')}
          {renderParameter('SKPE.JOURNEY.PEM03.02_DURATION','PEM-03.02 · Indicadores e Metas','Cadência default da fase.')}
          {renderParameter('SKPE.JOURNEY.PEM03.03_DURATION','PEM-03.03 · Iniciativas e Projetos Estratégicos','Cadência default da fase.')}
          {renderParameter('SKPE.JOURNEY.PEM03.04_DURATION','PEM-03.04 · Responsabilidades e Governança da Execução','Cadência default da fase.')}
          <div className="skpe-organization-parameter-copy"><strong>PEM-04 · Fases</strong><span>O total da Megafase é derivado das fases abaixo; o Gate não consome duração própria.</span></div>
          {renderParameter('SKPE.JOURNEY.PEM04.01_DURATION','PEM-04.01 · Plano de Implementação','Cadência default da fase.')}
          {renderParameter('SKPE.JOURNEY.PEM04.02_DURATION','PEM-04.02 · Comunicação e Mobilização','Cadência default da fase.')}
          {renderParameter('SKPE.JOURNEY.PEM04.03_DURATION','PEM-04.03 · Capacidades e Gestão da Mudança','Cadência default da fase.')}
          {renderParameter('SKPE.JOURNEY.PEM04.04_DURATION','PEM-04.04 · Gestão de Riscos da Implementação','Cadência default da fase.')}
          {renderParameter('SKPE.PERFORMANCE.DEVIATION.ADEQUATE_MAX_PERCENT', 'Desvio · faixa adequada', 'Desvio absoluto máximo para manter a leitura de desempenho na faixa adequada.')}
          {renderParameter('SKPE.PERFORMANCE.DEVIATION.ATTENTION_MAX_PERCENT', 'Desvio · faixa de atenção', 'Desvio absoluto máximo da faixa de atenção; acima deste valor a leitura é crítica.')}
        </div>
      )}

      <label className="skpe-organization-parameter-reason">
        Justificativa auditável
        <textarea
          rows={2}
          value={reason}
          onChange={(event) => setReason(event.target.value)}
          placeholder="Explique por que a Organização está alterando ou restaurando este parâmetro."
          disabled={!canManage || saving}
        />
      </label>
    </section>
  )
}
