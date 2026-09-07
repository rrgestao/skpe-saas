import { useEffect, useMemo, useState } from 'react'

import { supabase } from '../../../lib/supabase'
import { StrategicBscMap } from '../../skpe/features/strategy/StrategicBscMap'

import './InitiativePerformanceCockpit.css'

type DrilldownFilter =
  | 'all'
  | 'in_progress'
  | 'draft'
  | 'under_analysis'
  | 'critical'
  | 'blocked'

type InitiativePerformanceCockpitProps = {
  dashboard: unknown
  initiatives: unknown[]
  onStatusDrilldown: (filter: DrilldownFilter) => void
}

type NormalizedInitiative = {
  status: string
  priority: string
  initiativeClass: string
  responsibleArea: string
  criticality: string
  proposalOrigin: string
  dueDate: string
  progress: number | null
  projectId: string
}

function asRecord(value: unknown): Record<string, unknown> {
  return value && typeof value === 'object'
    ? (value as Record<string, unknown>)
    : {}
}

function readString(record: Record<string, unknown>, ...keys: string[]): string {
  for (const key of keys) {
    const value = record[key]
    if (typeof value === 'string' && value.trim()) return value.trim()
  }
  return ''
}

function readNumber(record: Record<string, unknown>, ...keys: string[]): number | null {
  for (const key of keys) {
    const value = record[key]
    if (typeof value === 'number' && Number.isFinite(value)) return value
    if (typeof value === 'string' && value.trim()) {
      const parsed = Number(value)
      if (Number.isFinite(parsed)) return parsed
    }
  }
  return null
}

function normalizeInitiative(value: unknown): NormalizedInitiative {
  const record = asRecord(value)
  return {
    status: readString(record, 'initiative_status', 'status'),
    priority: readString(record, 'priority'),
    initiativeClass: readString(record, 'initiative_class', 'initiativeClass', 'class'),
    responsibleArea: readString(
      record,
      'responsible_area_name',
      'responsibleAreaName',
      'responsible_area_code',
    ),
    criticality: readString(record, 'criticality'),
    proposalOrigin: readString(record, 'proposal_origin', 'proposalOrigin'),
    dueDate: readString(record, 'target_end_date', 'targetEndDate', 'due_date', 'dueDate'),
    progress: readNumber(record, 'progress'),
    projectId: readString(record, 'skpe_project_id', 'project_id', 'projectId'),
  }
}

function labelStatus(initiative: NormalizedInitiative) {
  if (
    initiative.status === 'proposed' &&
    initiative.proposalOrigin === 'sparks_suggestion'
  ) {
    return 'Rascunhos'
  }

  const labels: Record<string, string> = {
    proposed: 'Propostas',
    under_analysis: 'Em análise',
    approved: 'Aprovadas',
    planned: 'Planejadas',
    in_progress: 'Em execução',
    on_hold: 'Em espera',
    blocked: 'Bloqueadas',
    completed: 'Concluídas',
    cancelled: 'Canceladas',
  }

  return labels[initiative.status] ?? (initiative.status || 'Sem classificação')
}

function labelPriority(value: string) {
  const labels: Record<string, string> = {
    low: 'Baixa',
    medium: 'Média',
    high: 'Alta',
    critical: 'Crítica',
  }
  return labels[value] ?? (value || 'Sem classificação')
}

function labelClass(value: string) {
  const labels: Record<string, string> = {
    program: 'Programa',
    project: 'Projeto',
    initiative: 'Iniciativa legada',
    structuring_action: 'Ação estruturante',
    process: 'Processo',
    sprint: 'Sprint',
    task: 'Tarefa',
    work: 'Trabalho',
    strategic: 'Estratégica',
    tactical: 'Tática',
    operational: 'Operacional',
    risk_mitigation: 'Mitigação de risco',
  }
  return labels[value] ?? (value || 'Sem classificação')
}

function groupCounts(
  initiatives: NormalizedInitiative[],
  selector: (initiative: NormalizedInitiative) => string,
) {
  const counts = new Map<string, number>()
  for (const initiative of initiatives) {
    const key = selector(initiative)
    counts.set(key, (counts.get(key) ?? 0) + 1)
  }
  return [...counts.entries()]
    .map(([label, value]) => ({ label, value }))
    .sort((a, b) => b.value - a.value || a.label.localeCompare(b.label, 'pt-BR'))
}

function DistributionBars({
  title,
  subtitle,
  items,
}: {
  title: string
  subtitle: string
  items: Array<{ label: string; value: number }>
}) {
  const max = Math.max(1, ...items.map((item) => item.value))

  return (
    <article className="skpe-performance-card">
      <header>
        <div>
          <p className="skpe-performance-eyebrow">Análise de composição</p>
          <h3>{title}</h3>
          <span>{subtitle}</span>
        </div>
      </header>

      <div className="skpe-performance-bars">
        {items.map((item) => (
          <div key={item.label} className="skpe-performance-bar-row">
            <div className="skpe-performance-bar-label">
              <span>{item.label}</span>
              <strong>{item.value}</strong>
            </div>
            <div className="skpe-performance-bar-track" aria-hidden="true">
              <span
                style={{
                  width: `${Math.max(4, Math.round((item.value / max) * 100))}%`,
                }}
              />
            </div>
          </div>
        ))}
      </div>
    </article>
  )
}

export function InitiativePerformanceCockpit({
  dashboard,
  initiatives,
  onStatusDrilldown,
}: InitiativePerformanceCockpitProps) {
  const dashboardRecord = asRecord(dashboard)
  const normalized = useMemo(
    () => initiatives.map(normalizeInitiative),
    [initiatives],
  )
  const [formulationId, setFormulationId] = useState<string | null>(null)
  const [formulationResolution, setFormulationResolution] = useState<
    'loading' | 'resolved' | 'unavailable'
  >('loading')

  const projectId = useMemo(() => {
    const ids = Array.from(
      new Set(normalized.map((item) => item.projectId).filter(Boolean)),
    )
    return ids.length === 1 ? ids[0] : null
  }, [normalized])

  useEffect(() => {
    let active = true

    async function resolveFormulation() {
      if (!projectId) {
        setFormulationId(null)
        setFormulationResolution('unavailable')
        return
      }

      setFormulationResolution('loading')

      const { data, error } = await supabase
        .from('skpe_strategic_formulations')
        .select('id')
        .eq('project_id', projectId)
        .in('status', ['draft', 'under_review', 'approved'])
        .order('version_number', { ascending: false })
        .limit(2)

      if (!active) return

      if (error || !data || data.length !== 1) {
        setFormulationId(null)
        setFormulationResolution('unavailable')
        return
      }

      setFormulationId(data[0]?.id ?? null)
      setFormulationResolution(data[0]?.id ? 'resolved' : 'unavailable')
    }

    void resolveFormulation()

    return () => {
      active = false
    }
  }, [projectId])

  const total = normalized.length
  const averageProgress = readNumber(dashboardRecord, 'average_progress')
  const averageProgressForBar = Math.max(0, Math.min(100, averageProgress ?? 0))

  const drafts = normalized.filter(
    (item) =>
      item.status === 'proposed' &&
      item.proposalOrigin === 'sparks_suggestion',
  ).length
  const inProgress = normalized.filter((item) => item.status === 'in_progress').length
  const blocked = normalized.filter((item) => item.status === 'blocked').length
  const critical = normalized.filter((item) => item.criticality === 'critical').length
  const withoutDueDate = normalized.filter((item) => !item.dueDate).length

  const statusDistribution = groupCounts(normalized, labelStatus)
  const priorityDistribution = groupCounts(normalized, (item) => labelPriority(item.priority))
  const areaDistribution = groupCounts(
    normalized,
    (item) => item.responsibleArea || 'Sem área responsável',
  )
  const classDistribution = groupCounts(
    normalized,
    (item) => labelClass(item.initiativeClass),
  )

  const attentionTotal = drafts + critical + blocked + withoutDueDate

  return (
    <section className="skpe-performance-cockpit" aria-label="Cockpit de Resultados e Desempenho">
      <div className="skpe-performance-hero">
        <div>
          <p className="skpe-performance-eyebrow">SKPE-MON-ANL-01</p>
          <h2>Cockpit de Resultados e Desempenho</h2>
          <p>
            Onde queremos chegar, como estamos performando, o que está sendo executado
            e onde a gestão precisa agir.
          </p>
        </div>
      </div>

      <section className="skpe-performance-map-section">
        <header className="skpe-performance-section-heading">
          <div>
            <p className="skpe-performance-eyebrow">Arquitetura estratégica</p>
            <h2>Mapa Estratégico</h2>
          </div>
          <p>
            O sinaleiro de cada Objetivo Estratégico permanece cinza enquanto não houver
            sensibilização governada por execução, indicadores e resultados apurados.
          </p>
        </header>

        {formulationResolution === 'loading' ? (
          <div className="skpe-performance-map-state">Carregando Mapa Estratégico...</div>
        ) : formulationId ? (
          <StrategicBscMap formulationId={formulationId} />
        ) : (
          <div className="skpe-performance-map-state">
            O Mapa Estratégico ainda não pôde ser associado de forma unívoca ao
            portfólio carregado. Nenhum status de Objetivo Estratégico foi inferido.
          </div>
        )}
      </section>

      <section className="skpe-performance-results-section">
        <header className="skpe-performance-section-heading">
          <div>
            <p className="skpe-performance-eyebrow">Resultados e desempenho</p>
            <h2>Desempenho da estratégia</h2>
          </div>
          <p>
            Execução, indicadores e resultados aparecem aqui somente quando houver
            evidência suficiente. Ausência de apuração não é convertida em zero.
          </p>
        </header>

        <div className="skpe-performance-results-grid">
          <article className="skpe-performance-result-card">
            <div className="skpe-performance-result-card__heading">
              <span>Execução média do portfólio</span>
              <strong>
                {averageProgress == null ? '—' : `${averageProgress.toFixed(0)}%`}
              </strong>
            </div>
            <div className="skpe-performance-result-track">
              <span
                style={{
                  width: averageProgress == null ? '0%' : `${averageProgressForBar}%`,
                }}
              />
            </div>
            <small>Leitura baseada apenas na regra atualmente governada.</small>
          </article>

          <article className="skpe-performance-result-card is-pending">
            <div className="skpe-performance-result-card__heading">
              <span>Indicadores e metas</span>
              <strong>—</strong>
            </div>
            <div className="skpe-performance-result-placeholder">
              Aguardando apuração governada
            </div>
            <small>
              Será ativado quando Medidas & Desempenho fornecer série, meta e resultado
              comparáveis.
            </small>
          </article>

          <article className="skpe-performance-result-card is-pending">
            <div className="skpe-performance-result-card__heading">
              <span>Resultados dos Objetivos Estratégicos</span>
              <strong>—</strong>
            </div>
            <div className="skpe-performance-result-placeholder">
              Sinaleiros ainda não sensibilizados
            </div>
            <small>
              Cinza = ainda não sensibilizado. Verde, amarelo, vermelho e azul dependem
              de regra e evidência governadas.
            </small>
          </article>
        </div>
      </section>

      <section className="skpe-performance-execution-section">
        <header className="skpe-performance-section-heading">
          <div>
            <p className="skpe-performance-eyebrow">Execução da estratégia</p>
            <h2>Portfólio em execução</h2>
          </div>
          <p>
            Navegue do resultado executivo até as iniciativas que materializam a
            estratégia.
          </p>
        </header>

        <div className="skpe-performance-summary-grid">
          <button type="button" className="skpe-performance-summary-card" onClick={() => onStatusDrilldown('all')}>
            <span>Portfólio</span><strong>{total}</strong><small>iniciativas visíveis</small>
          </button>
          <button type="button" className="skpe-performance-summary-card" onClick={() => onStatusDrilldown('in_progress')}>
            <span>Em execução</span><strong>{inProgress}</strong><small>execução corrente</small>
          </button>
          <button type="button" className="skpe-performance-summary-card is-attention" onClick={() => onStatusDrilldown('draft')}>
            <span>Rascunhos</span><strong>{drafts}</strong><small>aguardando curadoria</small>
          </button>
          <div className="skpe-performance-summary-card is-attention">
            <span>Atenção necessária</span><strong>{attentionTotal}</strong><small>sinais governados para gestão</small>
          </div>
        </div>
      </section>

      <section className="skpe-performance-attention-section">
        <article className="skpe-performance-card skpe-performance-attention">
          <header>
            <div>
              <p className="skpe-performance-eyebrow">Gestão por exceção</p>
              <h3>Atenção da Gestão</h3>
              <span>
                A liderança organizacional é distinta da custódia provisória do
                consultor SPARKOOP.
              </span>
            </div>
          </header>
          <div className="skpe-performance-attention-grid">
            <button type="button" onClick={() => onStatusDrilldown('draft')}><strong>{drafts}</strong><span>Rascunhos para curadoria</span></button>
            <button type="button" onClick={() => onStatusDrilldown('critical')}><strong>{critical}</strong><span>Iniciativas críticas</span></button>
            <button type="button" onClick={() => onStatusDrilldown('blocked')}><strong>{blocked}</strong><span>Bloqueadas</span></button>
            <div><strong>—</strong><span>Liderança organizacional pendente de designação</span></div>
            <div><strong>{withoutDueDate}</strong><span>Sem término-alvo</span></div>
          </div>
        </article>
      </section>

      <section className="skpe-performance-composition-section">
        <header className="skpe-performance-section-heading">
          <div>
            <p className="skpe-performance-eyebrow">Composição do portfólio</p>
            <h2>Leitura estrutural das iniciativas</h2>
          </div>
          <p>
            Distribuições de apoio à análise. Não substituem a leitura de resultados
            e desempenho.
          </p>
        </header>
        <div className="skpe-performance-grid">
          <DistributionBars title="Situação do portfólio" subtitle="Composição por situação governada." items={statusDistribution} />
          <DistributionBars title="Prioridade" subtitle="Composição atual por nível de prioridade." items={priorityDistribution} />
          <DistributionBars title="Área responsável" subtitle="Distribuição da responsabilidade organizacional registrada." items={areaDistribution} />
          <DistributionBars title="Classe de iniciativa" subtitle="Composição atual por classificação da iniciativa." items={classDistribution} />
        </div>
      </section>

      <div className="skpe-performance-data-note">
        <strong>Leituras ainda não simuladas:</strong>
        <span>
          evolução temporal, planejado x realizado, desempenho de indicadores e metas,
          atraso, saúde consolidada do Mapa Estratégico e liderança organizacional
          permanecem bloqueados até existir contrato de dados e evidência suficientes.
        </span>
      </div>
    </section>
  )
}
