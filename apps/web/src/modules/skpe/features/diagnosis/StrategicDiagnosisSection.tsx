import { useEffect, useMemo, useState } from 'react'

import { WorkspaceTabs } from '../../../../components/design-system'
import { supabase } from '../../../../lib/supabase'
import { translateBackendMessage } from '../../../../shared/i18n/ptBR'
import type { JourneyTemporalReadRow } from '../../contracts/journey'

import './StrategicDiagnosisSection.css'

type DiagnosisTab = 'overview' | 'pestel' | 'swot' | 'tows' | 'risks'

type Props = {
  organizationId: string
  projectId: string
}

const phaseByTab: Record<Exclude<DiagnosisTab, 'overview'>, string> = {
  pestel: 'PEM-01.03',
  swot: 'PEM-01.05',
  tows: 'PEM-01.05',
  risks: 'PEM-01.06',
}

const copyByTab: Record<
  Exclude<DiagnosisTab, 'overview'>,
  { title: string; purpose: string; interpretation: string }
> = {
  pestel: {
    title: 'PESTEL',
    purpose:
      'Leitura estruturada do ambiente político, econômico, social, tecnológico, ambiental e legal.',
    interpretation:
      'A interpretação detalhada será apresentada a partir do artefato canônico correspondente. Esta tela não inventa fatores, evidências ou conclusões enquanto o conteúdo estruturado não estiver materializado.',
  },
  swot: {
    title: 'SWOT',
    purpose:
      'Síntese das forças, fraquezas, oportunidades e ameaças relevantes para a organização.',
    interpretation:
      'A visão deve distinguir evidência, interpretação e lacuna. O conteúdo específico será conectado à fonte canônica do diagnóstico sem duplicação.',
  },
  tows: {
    title: 'TOWS',
    purpose:
      'Cruzamento orientado à decisão entre fatores internos e externos para derivar alternativas estratégicas.',
    interpretation:
      'Estratégias TOWS somente serão exibidas quando derivadas de fatores SWOT rastreáveis. A interface não sintetiza estratégias sem essa base.',
  },
  risks: {
    title: 'Riscos',
    purpose:
      'Consolidação dos riscos estratégicos, lacunas e temas críticos identificados no diagnóstico.',
    interpretation:
      'Riscos estratégicos devem preservar origem, avaliação e vínculo com evidências. Riscos de iniciativas não substituem o registro de risco estratégico.',
  },
}

function statusLabel(value: string) {
  const labels: Record<string, string> = {
    not_started: 'Não iniciado',
    in_progress: 'Em execução',
    blocked: 'Bloqueado',
    pending_validation: 'Pendente de validação',
    completed: 'Concluído',
    cancelled: 'Cancelado',
  }
  return labels[value] ?? value
}

function validationLabel(value: string) {
  const labels: Record<string, string> = {
    approved: 'Aprovado',
    validated: 'Validado',
    not_required: 'Não exigida nesta fase',
    pending: 'Pendente',
    rejected: 'Rejeitado',
  }
  return labels[value] ?? value
}

export function StrategicDiagnosisSection({
  organizationId,
  projectId,
}: Props) {
  const [activeTab, setActiveTab] = useState<DiagnosisTab>('overview')
  const [rows, setRows] = useState<JourneyTemporalReadRow[]>([])
  const [loading, setLoading] = useState(true)
  const [errorMessage, setErrorMessage] = useState('')

  useEffect(() => {
    let active = true

    async function loadDiagnosis() {
      setLoading(true)
      setErrorMessage('')

      const { data, error } = await supabase.rpc(
        'get_skpe_journey_temporal_read_model',
        {
          target_organization_id: organizationId,
          target_project_id: projectId,
          target_as_of_date: null,
        },
      )

      if (!active) return

      if (error) {
        setRows([])
        setErrorMessage(
          `Não foi possível carregar o Diagnóstico Estratégico: ${translateBackendMessage(error.message)}`,
        )
      } else {
        setRows((data ?? []) as JourneyTemporalReadRow[])
      }

      setLoading(false)
    }

    void loadDiagnosis()

    return () => {
      active = false
    }
  }, [organizationId, projectId])

  const diagnosisMacrophase = useMemo(
    () => rows.find((row) => row.item_code === 'PEM-01') ?? null,
    [rows],
  )

  const selectedPhase =
    activeTab === 'overview'
      ? null
      : rows.find((row) => row.item_code === phaseByTab[activeTab]) ?? null

  return (
    <section className="skpe-strategic-diagnosis">
      <header className="skpe-strategic-diagnosis-header">
        <div>
          <p className="skpe-eyebrow">Diagnóstico Estratégico</p>
          <h2>Leitura integrada do contexto estratégico</h2>
          <p>
            PESTEL, SWOT, TOWS e Riscos são perspectivas internas do mesmo
            diagnóstico e não novos níveis do menu lateral.
          </p>
        </div>

        {diagnosisMacrophase ? (
          <span className="skpe-status-chip">
            {validationLabel(diagnosisMacrophase.validation_status)}
          </span>
        ) : null}
      </header>

      <WorkspaceTabs
        ariaLabel="Perspectivas do Diagnóstico Estratégico"
        activeId={activeTab}
        onChange={(id) => setActiveTab(id as DiagnosisTab)}
        tabs={[
          { id: 'overview', label: 'Visão Geral' },
          { id: 'pestel', label: 'PESTEL' },
          { id: 'swot', label: 'SWOT' },
          { id: 'tows', label: 'TOWS' },
          { id: 'risks', label: 'Riscos' },
        ]}
      />

      {errorMessage ? (
        <div className="skpe-admin-message skpe-admin-message-error">
          {errorMessage}
        </div>
      ) : loading ? (
        <section className="skpe-admin-state-card">
          <p>Carregando diagnóstico...</p>
        </section>
      ) : activeTab === 'overview' ? (
        <section className="skpe-strategic-diagnosis-overview">
          <article>
            <small>Megafase</small>
            <strong>
              {diagnosisMacrophase?.item_name ??
                'Diagnóstico e Entendimento Estratégico'}
            </strong>
          </article>
          <article>
            <small>Situação</small>
            <strong>
              {diagnosisMacrophase
                ? statusLabel(diagnosisMacrophase.item_status)
                : 'Não localizada'}
            </strong>
          </article>
          <article>
            <small>Progresso</small>
            <strong>{diagnosisMacrophase?.item_progress ?? 0}%</strong>
          </article>
          <article>
            <small>Validação</small>
            <strong>
              {diagnosisMacrophase
                ? validationLabel(diagnosisMacrophase.validation_status)
                : 'Não localizada'}
            </strong>
          </article>

          <div className="skpe-strategic-diagnosis-interpretation">
            <h3>Interpretação e considerações</h3>
            <p>
              A aprovação da PEM-01 é a fronteira de governança que libera este
              contexto no menu. Cada aba preserva a rastreabilidade da Jornada
              e não promove automaticamente conteúdo inexistente a evidência.
            </p>
          </div>
        </section>
      ) : (
        <section className="skpe-strategic-diagnosis-artifact">
          <header>
            <div>
              <p className="skpe-card-code">{selectedPhase?.item_code}</p>
              <h3>{copyByTab[activeTab].title}</h3>
              <p>{copyByTab[activeTab].purpose}</p>
            </div>
            {selectedPhase ? (
              <span className="skpe-status-chip">
                {statusLabel(selectedPhase.item_status)}
              </span>
            ) : null}
          </header>

          <div className="skpe-strategic-diagnosis-meta">
            <article>
              <small>Fase canônica</small>
              <strong>{selectedPhase?.item_name ?? 'Não materializada'}</strong>
            </article>
            <article>
              <small>Progresso</small>
              <strong>{selectedPhase?.item_progress ?? 0}%</strong>
            </article>
            <article>
              <small>Validação da fase</small>
              <strong>
                {selectedPhase
                  ? validationLabel(selectedPhase.validation_status)
                  : 'Não localizada'}
              </strong>
            </article>
          </div>

          <div className="skpe-strategic-diagnosis-interpretation">
            <h3>Interpretação e considerações</h3>
            <p>{copyByTab[activeTab].interpretation}</p>
          </div>
        </section>
      )}
    </section>
  )
}
