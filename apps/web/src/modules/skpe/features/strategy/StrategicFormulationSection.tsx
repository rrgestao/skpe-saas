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
          `NÃ£o foi possÃ­vel consolidar a FormulaÃ§Ã£o EstratÃ©gica: ${firstError.message}`,
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
    if (loading) return 'Consolidando dados canÃ´nicos da FormulaÃ§Ã£o EstratÃ©gica.'

    return [
      approvedIdentity
        ? 'O PMVV encontra-se aprovado e deve ser tratado como baseline da FormulaÃ§Ã£o.'
        : 'O PMVV ainda nÃ£o estÃ¡ integralmente aprovado.',
      `${counts.themes} Tema(s) EstratÃ©gico(s) e ${counts.objectives} Objetivo(s) EstratÃ©gico(s) estÃ£o materializados.`,
      `${counts.okrs} OKR(s), ${counts.keyResults} Resultado(s)-Chave e ${counts.indicators} Indicador(es) jÃ¡ possuem registros canÃ´nicos.`,
      `${counts.initiatives} iniciativa(s) estÃ£o disponÃ­veis no Plano de AÃ§Ã£o da organizaÃ§Ã£o.`,
    ].join(' ')
  }, [approvedIdentity, counts, loading])

  return (
    <section className="skpe-strategic-formulation">
      <header className="skpe-strategic-formulation-header">
        <div>
          <p className="skpe-eyebrow">{'Pensamento Estrat\u00e9gico'}</p>
          <h2>Da identidade Ã s escolhas e ao desdobramento</h2>
          <p>
            A FormulaÃ§Ã£o reÃºne PMVV, arquitetura estratÃ©gica, objetivos,
            desdobramentos de desempenho e o Plano EstratÃ©gico em uma Ãºnica
            superfÃ­cie de trabalho.
          </p>
        </div>
      </header>

      <WorkspaceTabs
        ariaLabel="Perspectivas da FormulaÃ§Ã£o EstratÃ©gica"
        activeId={activeTab}
        onChange={(id) => setActiveTab(id as FormulationTab)}
        tabs={[
          { id: 'overview', label: 'VisÃ£o Geral' },
          { id: 'pmvv', label: 'PMVV' },
          { id: 'architecture', label: 'Temas e Mapa EstratÃ©gico' },
          { id: 'performance', label: 'OKRs, Indicadores e Metas' },
          { id: 'plan', label: 'Plano EstratÃ©gico' },
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
              <strong>{approvedIdentity ? 'Aprovado' : 'Em evoluÃ§Ã£o'}</strong>
              <span>{counts.values} valores materializados</span>
            </article>
            <article>
              <small>Arquitetura estratÃ©gica</small>
              <strong>{counts.themes} temas</strong>
              <span>{counts.objectives} objetivos estratÃ©gicos</span>
            </article>
            <article>
              <small>Desdobramento</small>
              <strong>{counts.okrs} OKRs</strong>
              <span>
                {counts.keyResults} KRs Â· {counts.indicators} indicadores
              </span>
            </article>
            <article>
              <small>Plano EstratÃ©gico</small>
              <strong>{counts.initiatives} iniciativas</strong>
              <span>execuÃ§Ã£o materializada no Plano de AÃ§Ã£o</span>
            </article>
          </div>

          <article className="skpe-formulation-synthesis">
            <h3>SÃ­ntese executiva</h3>
            <p>{executiveSynthesis}</p>
            {coherenceStatement ? (
              <>
                <h4>ConsideraÃ§Ã£o de coerÃªncia</h4>
                <p>{coherenceStatement}</p>
              </>
            ) : null}
          </article>

          <article className="skpe-formulation-report">
            <div>
              <small>RelatÃ³rio Executivo da Etapa</small>
              <strong>Ainda nÃ£o emitido no repositÃ³rio de artefatos.</strong>
              <p>
                O download serÃ¡ habilitado quando existir uma versÃ£o emitida e
                armazenada no registro canÃ´nico de artefatos da FormulaÃ§Ã£o.
              </p>
            </div>
            <button type="button" disabled>
              Download indisponÃ­vel
            </button>
          </article>
        </section>
      ) : null}

      {activeTab === 'pmvv' ? (
        <section className="skpe-formulation-tab-panel">
          <StrategicIdentitySection organizationId={organizationId} />
          <article className="skpe-formulation-synthesis">
            <h3>SÃ­ntese e consideraÃ§Ãµes</h3>
            <p>
              O PMVV deve orientar escolhas, objetivos e iniciativas. A
              aprovaÃ§Ã£o da identidade nÃ£o substitui a validaÃ§Ã£o posterior dos
              Objetivos EstratÃ©gicos e demais desdobramentos.
            </p>
          </article>
        </section>
      ) : null}

      {activeTab === 'architecture' ? (
        <section className="skpe-formulation-tab-panel">
          <StrategicPositioningSection organizationId={organizationId} />
          <StrategicMapReadOnly formulationId={formulationId} />
          <article className="skpe-formulation-synthesis">
            <h3>SÃ­ntese e consideraÃ§Ãµes</h3>
            <p>
              Temas, perspectivas e Objetivos EstratÃ©gicos formam uma
              arquitetura Ãºnica. A leitura deve preservar relaÃ§Ãµes de causa,
              contribuiÃ§Ã£o e prioridade antes do desdobramento em OKRs,
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
                        Atual: {kr.current_value ?? 'â€”'} {kr.unit ?? ''} Â· Meta:{' '}
                        {kr.target_value ?? 'â€”'} {kr.unit ?? ''}
                      </p>
                    </div>
                    <span>{percent(kr.progress)}</span>
                  </div>
                ))
              )}
            </article>

            <article>
              <h3>Indicadores e referÃªncias de meta</h3>
              {indicators.length === 0 ? (
                <p>Nenhum indicador materializado.</p>
              ) : (
                indicators.map((indicator) => (
                  <div key={indicator.id} className="skpe-formulation-data-row">
                    <div>
                      <small>{indicator.code}</small>
                      <strong>{indicator.name}</strong>
                      <p>
                        Linha de base: {indicator.baseline_value ?? 'â€”'}{' '}
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
            <h3>SÃ­ntese e consideraÃ§Ãµes</h3>
            <p>
              OKRs, KRs e indicadores jÃ¡ existentes sÃ£o exibidos sem inferir
              metas ausentes. Lacunas de meta permanecem explÃ­citas atÃ© que
              sejam materializadas e validadas no modelo canÃ´nico.
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
            <h3>SÃ­ntese e consideraÃ§Ãµes</h3>
            <p>
              O Plano EstratÃ©gico consolida as iniciativas que materializam a
              execuÃ§Ã£o da estratÃ©gia. A ediÃ§Ã£o operacional continua no Plano
              de AÃ§Ã£o, preservando uma Ãºnica fonte de verdade.
            </p>
          </article>
        </section>
      ) : null}
    </section>
  )
}
