import { useMemo } from 'react'

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
  responsible: string
  criticality: string
  proposalOrigin: string
  dueDate: string
  progress: number | null
  strategicObjectiveNames: string[]
}

function asRecord(value: unknown): Record<string, unknown> {
  return value && typeof value === 'object'
    ? (value as Record<string, unknown>)
    : {}
}

function readString(
  record: Record<string, unknown>,
  ...keys: string[]
): string {
  for (const key of keys) {
    const value = record[key]
    if (typeof value === 'string' && value.trim()) return value.trim()
  }
  return ''
}

function readNumber(
  record: Record<string, unknown>,
  ...keys: string[]
): number | null {
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

function readStringArray(
  record: Record<string, unknown>,
  ...keys: string[]
): string[] {
  for (const key of keys) {
    const value = record[key]
    if (Array.isArray(value)) {
      return value.filter(
        (item): item is string => typeof item === 'string' && item.trim() !== '',
      )
    }
  }
  return []
}

function normalizeInitiative(value: unknown): NormalizedInitiative {
  const record = asRecord(value)

  return {
    status: readString(record, 'initiative_status', 'status'),
    priority: readString(record, 'priority'),
    initiativeClass: readString(
      record,
      'initiative_class',
      'initiativeClass',
      'class',
    ),
    responsibleArea: readString(
      record,
      'responsible_area_name',
      'responsibleAreaName',
      'responsible_area_code',
    ),
    responsible: readString(
      record,
      'responsible_name',
      'responsibleName',
      'owner_name',
      'ownerName',
    ),
    criticality: readString(record, 'criticality'),
    proposalOrigin: readString(
      record,
      'proposal_origin',
      'proposalOrigin',
    ),
    dueDate: readString(
      record,
      'target_end_date',
      'targetEndDate',
      'due_date',
      'dueDate',
    ),
    progress: readNumber(record, 'progress'),
    strategicObjectiveNames: readStringArray(
      record,
      'strategic_objective_names',
      'strategicObjectiveNames',
    ),
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
    strategic: 'Estratégica',
    tactical: 'Tática',
    operational: 'Operacional',
    risk_mitigation: 'Mitigação de risco',
  }
  return labels[value] ?? (value || 'Sem classificação')
}

function statusFilter(label: string): DrilldownFilter | null {
  const filters: Record<string, DrilldownFilter> = {
    'Em execução': 'in_progress',
    Rascunhos: 'draft',
    'Em análise': 'under_analysis',
    Bloqueadas: 'blocked',
  }

  return filters[label] ?? null
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
  onSelect,
}: {
  title: string
  subtitle: string
  items: Array<{ label: string; value: number }>
  onSelect?: (label: string) => void
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
        {items.map((item) => {
          const width = Math.max(4, Math.round((item.value / max) * 100))
          const interactive = Boolean(onSelect)

          return (
            <button
              key={item.label}
              type="button"
              className={`skpe-performance-bar-row ${interactive ? 'is-interactive' : ''}`}
              onClick={() => onSelect?.(item.label)}
              disabled={!interactive}
            >
              <div className="skpe-performance-bar-label">
                <span>{item.label}</span>
                <strong>{item.value}</strong>
              </div>
              <div className="skpe-performance-bar-track" aria-hidden="true">
                <span style={{ width: `${width}%` }} />
              </div>
            </button>
          )
        })}
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

  const total = normalized.length
  const averageProgress = readNumber(dashboardRecord, 'average_progress') ?? 0

  const drafts = normalized.filter(
    (initiative) =>
      initiative.status === 'proposed' &&
      initiative.proposalOrigin === 'sparks_suggestion',
  ).length

  const inProgress = normalized.filter(
    (initiative) => initiative.status === 'in_progress',
  ).length

  const blocked = normalized.filter(
    (initiative) => initiative.status === 'blocked',
  ).length

  const critical = normalized.filter(
    (initiative) => initiative.criticality === 'critical',
  ).length

  const withoutResponsible = normalized.filter(
    (initiative) => !initiative.responsible,
  ).length

  const withoutDueDate = normalized.filter(
    (initiative) => !initiative.dueDate,
  ).length

  const statusDistribution = groupCounts(normalized, labelStatus)
  const priorityDistribution = groupCounts(
    normalized,
    (initiative) => labelPriority(initiative.priority),
  )
  const areaDistribution = groupCounts(
    normalized,
    (initiative) => initiative.responsibleArea || 'Sem área responsável',
  )
  const classDistribution = groupCounts(
    normalized,
    (initiative) => labelClass(initiative.initiativeClass),
  )

  const linkedObjectives = new Set(
    normalized.flatMap((initiative) => initiative.strategicObjectiveNames),
  )

  const attentionTotal =
    drafts + critical + blocked + withoutResponsible + withoutDueDate

  return (
    <section
      className="skpe-performance-cockpit"
      aria-label="Cockpit de Resultados e Desempenho"
    >
      <div className="skpe-performance-hero">
        <div>
          <p className="skpe-performance-eyebrow">SKPE-MON-ANL-01</p>
          <h2>Cockpit de Resultados e Desempenho</h2>
          <p>
            Leitura executiva da execução estratégica, construída somente com
            dados atualmente disponíveis e regras verificáveis.
          </p>
        </div>

        <div className="skpe-performance-hero-badge">
          <span>Leitura operacional média</span>
          <strong>{averageProgress.toFixed(0)}%</strong>
        </div>
      </div>

      <div className="skpe-performance-summary-grid">
        <button
          type="button"
          className="skpe-performance-summary-card"
          onClick={() => onStatusDrilldown('all')}
        >
          <span>Portfólio</span>
          <strong>{total}</strong>
          <small>iniciativas visíveis</small>
        </button>

        <button
          type="button"
          className="skpe-performance-summary-card"
          onClick={() => onStatusDrilldown('in_progress')}
        >
          <span>Em execução</span>
          <strong>{inProgress}</strong>
          <small>execução corrente</small>
        </button>

        <button
          type="button"
          className="skpe-performance-summary-card is-attention"
          onClick={() => onStatusDrilldown('draft')}
        >
          <span>Rascunhos</span>
          <strong>{drafts}</strong>
          <small>aguardando curadoria</small>
        </button>

        <div className="skpe-performance-summary-card is-attention">
          <span>Atenção necessária</span>
          <strong>{attentionTotal}</strong>
          <small>sinais para gestão</small>
        </div>
      </div>

      <div className="skpe-performance-grid">
        <DistributionBars
          title="Situação do portfólio"
          subtitle="Clique em uma situação governada para retornar ao Monitoramento Inicial já filtrado."
          items={statusDistribution}
          onSelect={(label) => {
            const filter = statusFilter(label)
            if (filter) onStatusDrilldown(filter)
          }}
        />

        <DistributionBars
          title="Prioridade"
          subtitle="Composição atual por nível de prioridade."
          items={priorityDistribution}
        />

        <DistributionBars
          title="Área responsável"
          subtitle="Distribuição da responsabilidade organizacional registrada."
          items={areaDistribution}
        />

        <DistributionBars
          title="Classe de iniciativa"
          subtitle="Composição atual por classificação da iniciativa."
          items={classDistribution}
        />
      </div>

      <div className="skpe-performance-lower-grid">
        <article className="skpe-performance-card skpe-performance-attention">
          <header>
            <div>
              <p className="skpe-performance-eyebrow">Gestão por exceção</p>
              <h3>Atenção necessária</h3>
              <span>
                Sinais derivados de dados reais; ausência de dado não é tratada
                como desempenho ruim.
              </span>
            </div>
          </header>

          <div className="skpe-performance-attention-grid">
            <button type="button" onClick={() => onStatusDrilldown('draft')}>
              <strong>{drafts}</strong>
              <span>Rascunhos para curadoria</span>
            </button>
            <button type="button" onClick={() => onStatusDrilldown('critical')}>
              <strong>{critical}</strong>
              <span>Iniciativas críticas</span>
            </button>
            <button type="button" onClick={() => onStatusDrilldown('blocked')}>
              <strong>{blocked}</strong>
              <span>Bloqueadas</span>
            </button>
            <div>
              <strong>{withoutResponsible}</strong>
              <span>Sem responsável identificado</span>
            </div>
            <div>
              <strong>{withoutDueDate}</strong>
              <span>Sem término-alvo</span>
            </div>
          </div>
        </article>

        <article className="skpe-performance-card skpe-performance-map-readiness">
          <header>
            <div>
              <p className="skpe-performance-eyebrow">Mapa Estratégico sinalizado</p>
              <h3>Prontidão de leitura estratégica</h3>
            </div>
          </header>

          <div className="skpe-performance-readiness">
            <span
              className={`skpe-performance-readiness-dot ${
                linkedObjectives.size > 0 ? 'is-partial' : 'is-unavailable'
              }`}
              aria-hidden="true"
            />
            <div>
              <strong>
                {linkedObjectives.size > 0 ? 'LEITURA PARCIAL' : 'SEM LEITURA'}
              </strong>
              <p>
                {linkedObjectives.size > 0
                  ? `${linkedObjectives.size} objetivo(s) já aparecem vinculados às iniciativas carregadas, mas a regra de saúde ainda não foi governada.`
                  : 'As iniciativas carregadas ainda não oferecem vínculo suficiente com Objetivos Estratégicos para atribuir saúde sem inventar resultado.'}
              </p>
            </div>
          </div>
        </article>
      </div>

      <div className="skpe-performance-data-note">
        <strong>Leituras ainda não simuladas:</strong>
        <span>
          evolução temporal, planejado x realizado, desempenho de indicadores e
          metas, atraso e saúde consolidada do Mapa Estratégico permanecem
          bloqueados até existir regra e evidência suficientes.
        </span>
      </div>
    </section>
  )
}
