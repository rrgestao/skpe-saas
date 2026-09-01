import { useMemo, useState } from 'react'
import { Grid, Willow } from '@svar-ui/react-grid'

import type { InitiativePortfolioRow } from '../contracts/initiativePortfolio'

import '@svar-ui/react-grid/all.css'
import './InitiativeDataExplorerBeta.css'

type InitiativeDataExplorerBetaProps = {
  initiatives: InitiativePortfolioRow[]
  onOpenInitiative: (initiative: InitiativePortfolioRow) => void
}

type ExplorerRow = {
  id: string
  name: string
  classLabel: string
  statusLabel: string
  area: string
  priority: string
  criticality: string
  progressLabel: string
  startDate: string
  targetEndDate: string
  health: string
  risk: string
  open?: boolean
  data?: ExplorerRow[]
}

function classLabel(value: string) {
  const labels: Record<string, string> = {
    program: 'Programa',
    project: 'Projeto',
    initiative: 'Iniciativa legada',
    structuring_action: 'Ação estruturante',
    process: 'Processo',
    sprint: 'Sprint',
    task: 'Tarefa',
    work: 'Trabalho',
  }

  return labels[value] ?? value
}

function statusLabel(value: string) {
  const labels: Record<string, string> = {
    proposed: 'Proposta',
    under_analysis: 'Em análise',
    approved: 'Aprovada',
    planned: 'Planejada',
    in_progress: 'Em execução',
    on_hold: 'Em espera',
    blocked: 'Bloqueada',
    completed: 'Concluída',
    cancelled: 'Cancelada',
    archived: 'Arquivada',
  }

  return labels[value] ?? value
}

function priorityLabel(value: string) {
  const labels: Record<string, string> = {
    low: 'Baixa',
    medium: 'Média',
    high: 'Alta',
    critical: 'Crítica',
  }

  return labels[value] ?? value
}

function criticalityLabel(value: string) {
  return priorityLabel(value)
}

function healthLabel(value: string) {
  const labels: Record<string, string> = {
    healthy: 'Saudável',
    on_track: 'Saudável',
    attention: 'Atenção',
    at_risk: 'Em risco',
    critical: 'Crítica',
    completed: 'Concluída',
    unknown: 'Não avaliada',
    not_assessed: 'Não avaliada',
  }

  return labels[value] ?? value
}

function riskLabel(value: string) {
  const labels: Record<string, string> = {
    low: 'Baixo',
    medium: 'Médio',
    high: 'Alto',
    critical: 'Crítico',
    unknown: 'Não avaliado',
    not_assessed: 'Não avaliado',
  }

  return labels[value] ?? value
}
function formatDate(value: string | null) {
  if (!value) return '—'

  const [year, month, day] = value.slice(0, 10).split('-')
  if (!year || !month || !day) return value

  return `${day}/${month}/${year}`
}

function buildTree(initiatives: InitiativePortfolioRow[]) {
  const sourceById = new Map(
    initiatives.map((initiative) => [
      initiative.initiative_id,
      initiative,
    ]),
  )

  const rowById = new Map<string, ExplorerRow>()

  for (const initiative of initiatives) {
    rowById.set(initiative.initiative_id, {
      id: initiative.initiative_id,
      name: initiative.initiative_name,
      classLabel: classLabel(initiative.initiative_class),
      statusLabel: statusLabel(initiative.initiative_status),
      area: initiative.responsible_area_name ?? 'Não definida',
      priority: priorityLabel(initiative.priority),
      criticality: criticalityLabel(initiative.criticality),
      progressLabel: `${initiative.progress}%`,
      startDate: formatDate(initiative.start_date),
      targetEndDate: formatDate(initiative.target_end_date),
      health: healthLabel(initiative.health_status),
      risk: riskLabel(initiative.risk_level),
      open: true,
      data: [],
    })
  }

  const roots: ExplorerRow[] = []

  for (const initiative of initiatives) {
    const row = rowById.get(initiative.initiative_id)
    if (!row) continue

    const parentId = initiative.parent_initiative_id
    const parentIsVisible =
      parentId !== null && sourceById.has(parentId)

    if (!parentId || !parentIsVisible) {
      roots.push(row)
      continue
    }

    const parent = rowById.get(parentId)
    if (!parent) {
      roots.push(row)
      continue
    }

    parent.data ??= []
    parent.data.push(row)
  }

  const sortRows = (rows: ExplorerRow[]) => {
    rows.sort(
      (first, second) =>
        first.name.localeCompare(second.name, 'pt-BR'),
    )

    for (const row of rows) {
      if (row.data && row.data.length > 0) {
        sortRows(row.data)
      } else {
        delete row.data
      }
    }
  }

  sortRows(roots)
  return roots
}

const columns = [
  {
    id: 'classLabel',
    header: 'Tipo',
    width: 140,
    sort: true,
  },
  {
    id: 'name',
    header: 'Iniciativa',
    width: 360,
    treetoggle: true,
    sort: true,
  },
  {
    id: 'progressLabel',
    header: 'Progresso',
    width: 105,
    sort: true,
  },
  {
    id: 'statusLabel',
    header: 'Situação',
    width: 140,
    sort: true,
  },
  {
    id: 'area',
    header: 'Área',
    width: 170,
    sort: true,
  },
  {
    id: 'priority',
    header: 'Prioridade',
    width: 115,
    sort: true,
  },
  {
    id: 'criticality',
    header: 'Criticidade',
    width: 115,
    sort: true,
  },
  {
    id: 'startDate',
    header: 'Início',
    width: 110,
    sort: true,
  },
  {
    id: 'targetEndDate',
    header: 'Término',
    width: 110,
    sort: true,
  },
  {
    id: 'health',
    header: 'Saúde',
    width: 120,
    sort: true,
  },
  {
    id: 'risk',
    header: 'Risco',
    width: 110,
    sort: true,
  },
]

export function InitiativeDataExplorerBeta({
  initiatives,
  onOpenInitiative,
}: InitiativeDataExplorerBetaProps) {
  const [selectedId, setSelectedId] = useState<string | null>(null)

  const data = useMemo(
    () => buildTree(initiatives),
    [initiatives],
  )

  const selectedInitiative =
    initiatives.find(
      (initiative) => initiative.initiative_id === selectedId,
    ) ?? null

  function init(api: {
    on: (
      action: string,
      handler: (event: { id?: string | number }) => void,
    ) => void
  }) {
    api.on('select-row', (event) => {
      setSelectedId(
        event.id === undefined || event.id === null
          ? null
          : String(event.id),
      )
    })
  }

  return (
    <section className="sparks-data-explorer-beta">
      <div
        className="sparks-data-explorer-beta__toolbar"
        title="Use a busca e os filtros do Plano de Iniciativas acima. No grid, ordene pelas colunas, navegue pela hierarquia e dê duplo clique para abrir."
      >
        <div>
          <p>SPARKs Data Explorer · Beta</p>
          <strong>Exploração hierárquica das iniciativas</strong>
        </div>
      </div>

      <div
        className="sparks-data-explorer-beta__grid"
        role="region"
        aria-label="Exploração hierárquica das iniciativas"
        tabIndex={0}
        title="Selecione uma linha e dê duplo clique para abrir a iniciativa"
        onDoubleClick={() => {
          if (selectedInitiative) {
            onOpenInitiative(selectedInitiative)
          }
        }}
        onKeyDown={(event) => {
          if (event.key === 'Enter' && selectedInitiative) {
            event.preventDefault()
            onOpenInitiative(selectedInitiative)
          }
        }}
      >
        <Willow>
          <Grid
            tree
            data={data}
            columns={columns}
            init={init}
            select
            rowStyle={() => 'sparks-data-explorer-row'}
          />
        </Willow>
      </div>

      <footer>
        <div>
          <span>
            Beta somente leitura · selecione uma linha e dê duplo clique para
            abrir. Enter também abre a linha selecionada.
          </span>
          {selectedInitiative ? (
            <strong>
              Selecionada: {selectedInitiative.initiative_name}
            </strong>
          ) : null}
        </div>
        <strong>
          {initiatives.length} registro
          {initiatives.length === 1 ? '' : 's'}
        </strong>
      </footer>
    </section>
  )
}