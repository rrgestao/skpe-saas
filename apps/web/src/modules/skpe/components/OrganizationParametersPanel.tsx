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
  organizationId?: string | null
  canManage: boolean
  scopeType?: 'module' | 'organization_module'
}

const PARAMETER_KEYS = [
  'SKPE.JOURNEY.DURATION_MODE',
  'SKPE.JOURNEY.STANDARD_DURATION',
  'SKPE.JOURNEY.EXTENDED_DURATION',
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
  'SKPE.JOURNEY.DURATION_MODE':'business_days','SKPE.JOURNEY.STANDARD_DURATION':'45','SKPE.JOURNEY.EXTENDED_DURATION':'90','SKPE.JOURNEY.ACCELERATED_DURATION':'45','SKPE.JOURNEY.POST_DELIVERY_FOLLOWUP':'90',
  'SKPE.JOURNEY.PEM02.01_DURATION':'1','SKPE.JOURNEY.PEM02.02_DURATION':'2','SKPE.JOURNEY.PEM02.03_DURATION':'2','SKPE.JOURNEY.PEM02.04_DURATION':'2','SKPE.JOURNEY.PEM02.05_DURATION':'3',
  'SKPE.JOURNEY.PEM03.01_DURATION':'2','SKPE.JOURNEY.PEM03.02_DURATION':'3','SKPE.JOURNEY.PEM03.03_DURATION':'2','SKPE.JOURNEY.PEM03.04_DURATION':'2',
  'SKPE.JOURNEY.PEM04.01_DURATION':'3','SKPE.JOURNEY.PEM04.02_DURATION':'2','SKPE.JOURNEY.PEM04.03_DURATION':'2','SKPE.JOURNEY.PEM04.04_DURATION':'2',
  'SKPE.JOURNEY.PEM00.01_DURATION':'1','SKPE.JOURNEY.PEM00.02_DURATION':'1','SKPE.JOURNEY.PEM00.03_DURATION':'1','SKPE.JOURNEY.PEM00.04_DURATION':'1',
  'SKPE.JOURNEY.PEM00.05_DURATION':'1','SKPE.JOURNEY.PEM00.06_DURATION':'1','SKPE.JOURNEY.PEM00.07_DURATION':'1','SKPE.JOURNEY.PEM00.08_DURATION':'1',
  'SKPE.JOURNEY.PEM01.01_DURATION':'1','SKPE.JOURNEY.PEM01.02_DURATION':'1','SKPE.JOURNEY.PEM01.03_DURATION':'2','SKPE.JOURNEY.PEM01.04_DURATION':'1','SKPE.JOURNEY.PEM01.05_DURATION':'2','SKPE.JOURNEY.PEM01.06_DURATION':'2',
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

export function OrganizationParametersPanel({ organizationId = null, canManage, scopeType = 'organization_module' }: Props) {
  const isModuleDefault = scopeType === 'module'
  const panelTitle = isModuleDefault ? 'Padrão SPARKs · SK-PE' : 'Parâmetros da Organização · SK-PE'
  const panelDescription = isModuleDefault
    ? 'Defina o padrão do SK-PE disponibilizado pelo SPARKs. Organizações podem herdar este padrão ou registrar suas próprias adaptações.'
    : 'O SPARKs fornece o padrão do SK-PE; a Organização pode adaptá-lo sem perder rastreabilidade nem a possibilidade de retornar ao padrão herdado.'
  const successLabel = isModuleDefault
    ? 'Padrão do SK-PE salvo com rastreabilidade.'
    : 'Parâmetro da Organização salvo com rastreabilidade.'
  const restoreLabel = isModuleDefault ? 'Restaurar padrão SPARKs' : 'Restaurar padrão do SK-PE'
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
      p_organization_id: isModuleDefault ? null : organizationId,
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
  }, [organizationId, scopeType])

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
      p_scope_type: scopeType,
      p_parameter_value: parameterValue,
      p_organization_id: isModuleDefault ? null : organizationId,
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
    setMessage({ type: 'success', text: successLabel })
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
      p_scope_type: scopeType,
      p_organization_id: isModuleDefault ? null : organizationId,
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
    setMessage({ type: 'success', text: isModuleDefault ? 'Padrão do módulo restaurado para o default SPARKs.' : 'Herança restaurada para o padrão do SK-PE disponível.' })
    setSaving(false)
  }

  function renderParameter(key: ParameterKey, label: string, help: string) {
    const parameter = parameterByKey.get(key)
    const isCurrentScopeOverride = parameter?.source_scope === scopeType
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
            disabled={!canManage || saving || !isCurrentScopeOverride}
          >
            {restoreLabel}
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
          <h2>{panelTitle}</h2>
          <p>{panelDescription}</p>
        </div>
      </div>

      {message ? <div className={`skpe-admin-message skpe-admin-message-${message.type}`}>{message.text}</div> : null}
      {loading ? <p>Carregando parâmetros efetivos...</p> : (
        <div className="skpe-organization-parameter-list">
          {renderParameter('SKPE.JOURNEY.DURATION_MODE', 'Contagem da Jornada', 'Escolha entre dias úteis e dias corridos para o planejamento temporal.')}
          {renderParameter('SKPE.JOURNEY.STANDARD_DURATION', 'Prazo usual para entrega', 'Referência SPARKs quando a Ordem de Serviço ou contrato não trouxer prazo específico.')}
          {renderParameter('SKPE.JOURNEY.EXTENDED_DURATION', 'Prazo ampliado para entrega', 'Referência de ampliação quando a complexidade ou o escopo exigirem.')}
          {renderParameter('SKPE.JOURNEY.POST_DELIVERY_FOLLOWUP', 'Acompanhamento após a entrega', 'Período de acompanhamento da implantação do Planejamento Estratégico após a entrega.')}
          <div className="skpe-organization-parameter-copy"><strong>Regra de precedência</strong><span>Quando a Ordem de Serviço ou o contrato estabelecerem prazos, eles prevalecem sobre as referências SPARKs de 45/90/90 dias.</span></div>
          <div className="skpe-organization-parameter-copy"><strong>Cadência da implantação</strong><span>Total efetivo atual: {implementationCadenceTotal} dias. Preparação: {pem00PhaseTotal} · Diagnóstico: {pem01PhaseTotal} · Formulação: {pem02PhaseTotal} · Desdobramento: {pem03PhaseTotal} · Implementação: {pem04PhaseTotal}.</span></div>
          <div className="skpe-organization-parameter-copy"><strong>Preparação e Enquadramento · Etapas</strong><span>O total da Macrofase é derivado das etapas abaixo; o ponto de validação não consome duração própria.</span></div>
          {renderParameter('SKPE.JOURNEY.PEM00.01_DURATION','Abertura, Mandato e Escopo','Cadência de referência desta etapa.')}
          {renderParameter('SKPE.JOURNEY.PEM00.02_DURATION','Governança, Papéis e Ritos','Cadência de referência desta etapa.')}
          {renderParameter('SKPE.JOURNEY.PEM00.03_DURATION','Caracterização da Organização','Cadência de referência desta etapa.')}
          {renderParameter('SKPE.JOURNEY.PEM00.04_DURATION','Checklist Dinâmico','Cadência de referência desta etapa.')}
          {renderParameter('SKPE.JOURNEY.PEM00.05_DURATION','Gestão de Evidências','Cadência de referência desta etapa.')}
          {renderParameter('SKPE.JOURNEY.PEM00.06_DURATION','Autoavaliações e Diagnósticos','Cadência de referência desta etapa.')}
          {renderParameter('SKPE.JOURNEY.PEM00.07_DURATION','Planos de Ação e Acompanhamento','Cadência de referência desta etapa.')}
          {renderParameter('SKPE.JOURNEY.PEM00.08_DURATION','Lacunas, Pendências e Prontidão','Cadência de referência desta etapa.')}
          <div className="skpe-organization-parameter-copy"><strong>Diagnóstico Estratégico · Etapas</strong><span>O total da Macrofase é derivado das etapas abaixo; o ponto de validação não consome duração própria.</span></div>
          {renderParameter('SKPE.JOURNEY.PEM01.01_DURATION','Consolidação da Base Diagnóstica','Cadência de referência desta etapa.')}
          {renderParameter('SKPE.JOURNEY.PEM01.02_DURATION','Avaliações, Diagnósticos e Planos Anteriores','Cadência de referência desta etapa.')}
          {renderParameter('SKPE.JOURNEY.PEM01.03_DURATION','Contexto e PESTEL','Cadência de referência desta etapa.')}
          {renderParameter('SKPE.JOURNEY.PEM01.04_DURATION','Partes Interessadas, Mercado e Posicionamento','Cadência de referência desta etapa.')}
          {renderParameter('SKPE.JOURNEY.PEM01.05_DURATION','SWOT e TOWS','Cadência de referência desta etapa.')}
          {renderParameter('SKPE.JOURNEY.PEM01.06_DURATION','Riscos, Lacunas e Temas Críticos','Cadência de referência desta etapa.')}
          <div className="skpe-organization-parameter-copy"><strong>Formulação Estratégica · Etapas</strong><span>O total da Macrofase é derivado das etapas abaixo; o ponto de validação não consome duração própria.</span></div>
          {renderParameter('SKPE.JOURNEY.PEM02.01_DURATION','Abertura da Formulação Estratégica','Cadência de referência desta etapa.')}
          {renderParameter('SKPE.JOURNEY.PEM02.02_DURATION','Direcionadores Estratégicos','Cadência de referência desta etapa.')}
          {renderParameter('SKPE.JOURNEY.PEM02.03_DURATION','Escolhas e Posicionamento Estratégico','Cadência de referência desta etapa.')}
          {renderParameter('SKPE.JOURNEY.PEM02.04_DURATION','Objetivos Estratégicos','Cadência de referência desta etapa.')}
          {renderParameter('SKPE.JOURNEY.PEM02.05_DURATION','Modelo Estratégico Futuro','Cadência de referência desta etapa.')}
          <div className="skpe-organization-parameter-copy"><strong>Desdobramento Estratégico · Etapas</strong><span>O total da Macrofase é derivado das etapas abaixo; o ponto de validação não consome duração própria.</span></div>
          {renderParameter('SKPE.JOURNEY.PEM03.01_DURATION','Desdobramento em OKRs','Cadência de referência desta etapa.')}
          {renderParameter('SKPE.JOURNEY.PEM03.02_DURATION','Indicadores e Metas','Cadência de referência desta etapa.')}
          {renderParameter('SKPE.JOURNEY.PEM03.03_DURATION','Iniciativas e Projetos Estratégicos','Cadência de referência desta etapa.')}
          {renderParameter('SKPE.JOURNEY.PEM03.04_DURATION','Responsabilidades e Governança da Execução','Cadência de referência desta etapa.')}
          <div className="skpe-organization-parameter-copy"><strong>Implementação e Mobilização · Etapas</strong><span>O total da Macrofase é derivado das etapas abaixo; o ponto de validação não consome duração própria.</span></div>
          {renderParameter('SKPE.JOURNEY.PEM04.01_DURATION','Ativação do Plano de Implementação','Cadência de referência desta etapa.')}
          {renderParameter('SKPE.JOURNEY.PEM04.02_DURATION','Comunicação e Mobilização','Cadência de referência desta etapa.')}
          {renderParameter('SKPE.JOURNEY.PEM04.03_DURATION','Capacidades e Gestão da Mudança','Cadência de referência desta etapa.')}
          {renderParameter('SKPE.JOURNEY.PEM04.04_DURATION','Gestão de Riscos da Implementação','Cadência de referência desta etapa.')}
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
          placeholder={isModuleDefault ? 'Explique por que o padrão SPARKs do SK-PE está sendo alterado ou restaurado.' : 'Explique por que a Organização está alterando ou restaurando este parâmetro.'}
          disabled={!canManage || saving}
        />
      </label>
    </section>
  )
}
