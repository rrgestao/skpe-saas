import { useEffect, useMemo, useState } from 'react'

import { WorkspaceTabs } from '../../../../components/design-system'
import { supabase } from '../../../../lib/supabase'
import { StrategicIdentitySection } from './StrategicIdentitySection'
import { StrategicPositioningSection } from './StrategicPositioningSection'
import { StrategicMapReadOnly } from './StrategicMapReadOnly'

import './StrategicFormulationSection.css'

type FormulationTab =
  | 'overview'
  | 'pmvv'
  | 'architecture'
  | 'performance'
  | 'plan'

type CountState = {
  values: number
  themes: number
  objectives: number
  okrs: number
  keyResults: number
  indicators: number
  initiatives: number
}

type OkrRow = {
  id: string
  code: string
  title: string
  description: string | null
  status: string
  progress: number
  validation_status: string
}

type KeyResultRow = {
  id: string
  code: string
  name: string
  description: string | null
  target_value: number | null
  current_value: number | null
  unit: string | null
  progress: number
  validation_status: string
}

type IndicatorRow = {
  id: string
  code: string
  name: string
  description: string | null
  unit: string | null
  status: string
  baseline_value: number | null
}

type InitiativeRow = {
  id: string
  code: string
  name: string
  status: string
  progress: number
  priority: string
}

type Props = {
  organizationId: string
  projectId: string
}

function percent(value: number | null | undefined) {
  return `${Number(value ?? 0).toLocaleString('pt-BR', {
    maximumFractionDigits: 1,
  })}%`
}

export function StrategicFormulationSection({
  organizationId,
  projectId,
}: Props) {
  const [formulationId, setFormulationId] = useState<string | null>(null)
  const [activeTab, setActiveTab] = useState<FormulationTab>('overview')
  const [counts, setCounts] = useState<CountState>({
    values: 0,
    themes: 0,
    objectives: 0,
    okrs: 0,
    keyResults: 0,
    indicators: 0,
    initiatives: 0,
  })
  const [okrs, setOkrs] = useState<OkrRow[]>([])
  const [keyResults, setKeyResults] = useState<KeyResultRow[]>([])
  const [indicators, setIndicators] = useState<IndicatorRow[]>([])
  const [initiatives, setInitiatives] = useState<InitiativeRow[]>([])
  const [identityStatus, setIdentityStatus] = useState<string | null>(null)
  const [coherenceStatement, setCoherenceStatement] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [errorMessage, setErrorMessage] = useState('')

  useEffect(() => {
    let active = true

    async function load() {
      setLoading(true)
      setErrorMessage('')

      const [
        identityResponse,
        valuesResponse,
        themesResponse,
        objectivesResponse,
        okrsResponse,
        keyResultsResponse,
        indicatorsResponse,
        initiativesResponse,
      ] = await Promise.all([
        supabase
          .from('skpe_strategic_identity')
          .select('status, coherence_statement')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId)
          .maybeSingle(),
        supabase
          .from('skpe_strategic_values')
          .select('id', { count: 'exact', head: true })
          .eq('organization_id', organizationId)
          .eq('project_id', projectId),
        supabase
          .from('skpe_strategic_themes')
          .select('id', { count: 'exact', head: true })
          .eq('organization_id', organizationId)
          .eq('project_id', projectId),
        supabase
          .from('skpe_strategic_objectives')
          .select('id', { count: 'exact', head: true })
          .eq('organization_id', organizationId)
          .eq('project_id', projectId),
        supabase
          .from('skpe_okrs')
          .select('id, code, title, description, status, progress, validation_status')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId)
          .order('display_order'),
        supabase
          .from('skpe_key_results')
          .select('id, code, name, description, target_value, current_value, unit, progress, validation_status')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId)
          .order('code'),
        supabase
          .from('skpe_indicators')
          .select('id, code, name, description, unit, status, baseline_value')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId)
          .order('code'),
        supabase
          .from('sparks_initiatives')
          .select('id, code, name, status, progress, priority')
          .eq('organization_id', organizationId)
          .is('archived_at', null)
          .order('code'),
      ])

      if (!active) return

      const responses = [
        identityResponse,
        valuesResponse,
        themesResponse,
        objectivesResponse,
        okrsResponse,
        keyResultsResponse,
        indicatorsResponse,
        initiativesResponse,
      ]

      const firstError = responses.find((response) => response.error)?.error

      if (firstError) {
        setErrorMessage(
          `Não foi possível consolidar a Formulação Estratégica: ${firstError.message}`,
        )
        setLoading(false)
        return
      }

      setIdentityStatus(identityResponse.data?.status ?? null)
      setCoherenceStatement(identityResponse.data?.coherence_statement ?? null)

      const { data: formulationRows, error: formulationError } = await supabase
        .from('skpe_strategic_formulations')
        .select('id')
        .eq('organization_id', organizationId)
        .eq('project_id', projectId)
        .in('status', ['draft', 'under_review', 'approved'])
        .order('version_number', { ascending: false })
        .limit(2)

      if (!active) return

      if (formulationError) {
        setErrorMessage(
          `Não foi possível resolver a versão da Formulação Estratégica: ${formulationError.message}`,
        )
        setLoading(false)
        return
      }

      setFormulationId(
        formulationRows?.length === 1 ? formulationRows[0]?.id ?? null : null,
      )

      setOkrs((okrsResponse.data ?? []) as OkrRow[])
      setKeyResults((keyResultsResponse.data ?? []) as KeyResultRow[])
      setIndicators((indicatorsResponse.data ?? []) as IndicatorRow[])
      setInitiatives((initiativesResponse.data ?? []) as InitiativeRow[])

      setCounts({
        values: valuesResponse.count ?? 0,
        themes: themesResponse.count ?? 0,
        objectives: objectivesResponse.count ?? 0,
        okrs: okrsResponse.data?.length ?? 0,
        keyResults: keyResultsResponse.data?.length ?? 0,
        indicators: indicatorsResponse.data?.length ?? 0,
        initiatives: initiativesResponse.data?.length ?? 0,
      })

      setLoading(false)
    }

    void load()

    return () => {
      active = false
    }
  }, [organizationId, projectId])

  const approvedIdentity = identityStatus === 'approved'

  const executiveSynthesis = useMemo(() => {
    if (loading) return 'Consolidando dados canônicos da Formulação Estratégica.'

    return [
      approvedIdentity
        ? 'O PMVV encontra-se aprovado e deve ser tratado como baseline da Formulação.'
        : 'O PMVV ainda não está integralmente aprovado.',
      `${counts.themes} Tema(s) Estratégico(s) e ${counts.objectives} Objetivo(s) Estratégico(s) estão materializados.`,
      `${counts.okrs} OKR(s), ${counts.keyResults} Resultado(s)-Chave e ${counts.indicators} Indicador(es) já possuem registros canônicos.`,
      `${counts.initiatives} iniciativa(s) estão disponíveis no Plano de Ação da organização.`,
    ].join(' ')
  }, [approvedIdentity, counts, loading])

  return (
    <section className="skpe-strategic-formulation">
      <header className="skpe-strategic-formulation-header">
        <div>
          <p className="skpe-eyebrow">{'Pensamento Estrat\u00e9gico'}</p>
          <h2>Da identidade às escolhas e ao desdobramento</h2>
          <p>
            A Formulação reúne PMVV, arquitetura estratégica, objetivos,
            desdobramentos de desempenho e o Plano Estratégico em uma única
            superfície de trabalho.
          </p>
        </div>
      </header>

      <WorkspaceTabs
        ariaLabel="Perspectivas da Formulação Estratégica"
        activeId={activeTab}
        onChange={(id) => setActiveTab(id as FormulationTab)}
        tabs={[
          { id: 'overview', label: 'Visão Geral' },
          { id: 'pmvv', label: 'PMVV' },
          { id: 'architecture', label: 'Temas e Mapa Estratégico' },
          { id: 'performance', label: 'OKRs, Indicadores e Metas' },
          { id: 'plan', label: 'Plano Estratégico' },
        ]}
      />

      {errorMessage ? (
        <div className="skpe-admin-message skpe-admin-message-error">
          {errorMessage}
        </div>
      ) : null}

      {activeTab === 'overview' ? (
        <section className="skpe-formulation-overview">
          <div className="skpe-formulation-summary-grid">
            <article>
              <small>PMVV</small>
              <strong>{approvedIdentity ? 'Aprovado' : 'Em evolução'}</strong>
              <span>{counts.values} valores materializados</span>
            </article>
            <article>
              <small>Arquitetura estratégica</small>
              <strong>{counts.themes} temas</strong>
              <span>{counts.objectives} objetivos estratégicos</span>
            </article>
            <article>
              <small>Desdobramento</small>
              <strong>{counts.okrs} OKRs</strong>
              <span>
                {counts.keyResults} KRs · {counts.indicators} indicadores
              </span>
            </article>
            <article>
              <small>Plano Estratégico</small>
              <strong>{counts.initiatives} iniciativas</strong>
              <span>execução materializada no Plano de Ação</span>
            </article>
          </div>

          <article className="skpe-formulation-synthesis">
            <h3>Síntese executiva</h3>
            <p>{executiveSynthesis}</p>
            {coherenceStatement ? (
              <>
                <h4>Consideração de coerência</h4>
                <p>{coherenceStatement}</p>
              </>
            ) : null}
          </article>

          <article className="skpe-formulation-report">
            <div>
              <small>Relatório Executivo da Etapa</small>
              <strong>Ainda não emitido no repositório de artefatos.</strong>
              <p>
                O download será habilitado quando existir uma versão emitida e
                armazenada no registro canônico de artefatos da Formulação.
              </p>
            </div>
            <button type="button" disabled>
              Download indisponível
            </button>
          </article>
        </section>
      ) : null}

      {activeTab === 'pmvv' ? (
        <section className="skpe-formulation-tab-panel">
          <StrategicIdentitySection organizationId={organizationId} />
          <article className="skpe-formulation-synthesis">
            <h3>Síntese e considerações</h3>
            <p>
              O PMVV deve orientar escolhas, objetivos e iniciativas. A
              aprovação da identidade não substitui a validação posterior dos
              Objetivos Estratégicos e demais desdobramentos.
            </p>
          </article>
        </section>
      ) : null}

      {activeTab === 'architecture' ? (
        <section className="skpe-formulation-tab-panel">
          <StrategicPositioningSection organizationId={organizationId} />
          <StrategicMapReadOnly formulationId={formulationId} />
          <article className="skpe-formulation-synthesis">
            <h3>Síntese e considerações</h3>
            <p>
              Temas, perspectivas e Objetivos Estratégicos formam uma
              arquitetura única. A leitura deve preservar relações de causa,
              contribuição e prioridade antes do desdobramento em OKRs,
              indicadores, metas e iniciativas.
            </p>
          </article>
        </section>
      ) : null}

      {activeTab === 'performance' ? (
        <section className="skpe-formulation-tab-panel">
          <div className="skpe-formulation-data-grid">
            <article>
              <h3>OKRs</h3>
              {okrs.length === 0 ? (
                <p>Nenhum OKR materializado.</p>
              ) : (
                okrs.map((okr) => (
                  <div key={okr.id} className="skpe-formulation-data-row">
                    <div>
                      <small>{okr.code}</small>
                      <strong>{okr.title}</strong>
                      {okr.description ? <p>{okr.description}</p> : null}
                    </div>
                    <span>{percent(okr.progress)}</span>
                  </div>
                ))
              )}
            </article>

            <article>
              <h3>Resultados-Chave</h3>
              {keyResults.length === 0 ? (
                <p>Nenhum Resultado-Chave materializado.</p>
              ) : (
                keyResults.map((kr) => (
                  <div key={kr.id} className="skpe-formulation-data-row">
                    <div>
                      <small>{kr.code}</small>
                      <strong>{kr.name}</strong>
                      <p>
                        Atual: {kr.current_value ?? '—'} {kr.unit ?? ''} · Meta:{' '}
                        {kr.target_value ?? '—'} {kr.unit ?? ''}
                      </p>
                    </div>
                    <span>{percent(kr.progress)}</span>
                  </div>
                ))
              )}
            </article>

            <article>
              <h3>Indicadores e referências de meta</h3>
              {indicators.length === 0 ? (
                <p>Nenhum indicador materializado.</p>
              ) : (
                indicators.map((indicator) => (
                  <div key={indicator.id} className="skpe-formulation-data-row">
                    <div>
                      <small>{indicator.code}</small>
                      <strong>{indicator.name}</strong>
                      <p>
                        Linha de base: {indicator.baseline_value ?? '—'}{' '}
                        {indicator.unit ?? ''}
                      </p>
                    </div>
                    <span>{indicator.status}</span>
                  </div>
                ))
              )}
            </article>
          </div>

          <article className="skpe-formulation-synthesis">
            <h3>Síntese e considerações</h3>
            <p>
              OKRs, KRs e indicadores já existentes são exibidos sem inferir
              metas ausentes. Lacunas de meta permanecem explícitas até que
              sejam materializadas e validadas no modelo canônico.
            </p>
          </article>
        </section>
      ) : null}

      {activeTab === 'plan' ? (
        <section className="skpe-formulation-tab-panel">
          <div className="skpe-formulation-plan-list">
            {initiatives.map((initiative) => (
              <article key={initiative.id}>
                <div>
                  <small>{initiative.code}</small>
                  <strong>{initiative.name}</strong>
                </div>
                <div>
                  <span>{initiative.status}</span>
                  <strong>{percent(initiative.progress)}</strong>
                </div>
              </article>
            ))}
          </div>

          <article className="skpe-formulation-synthesis">
            <h3>Síntese e considerações</h3>
            <p>
              O Plano Estratégico consolida as iniciativas que materializam a
              execução da estratégia. A edição operacional continua no Plano
              de Ação, preservando uma única fonte de verdade.
            </p>
          </article>
        </section>
      ) : null}
    </section>
  )
}
