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
  code: string
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
    initiative: 'Iniciativa',
    structuring_action: 'Ação estruturante',
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
      code: initiative.initiative_code,
      name: initiative.initiative_name,
      classLabel: classLabel(initiative.initiative_class),
      statusLabel: statusLabel(initiative.initiative_status),
      area: initiative.responsible_area_name ?? 'Não definida',
      priority: initiative.priority,
      criticality: initiative.criticality,
      progressLabel: `${initiative.progress}%`,
      startDate: formatDate(initiative.start_date),
      targetEndDate: formatDate(initiative.target_end_date),
      health: initiative.health_status,
      risk: initiative.risk_level,
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
        first.code.localeCompare(second.code, 'pt-BR') ||
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
    id: 'code',
    header: ['Código', { filter: 'text' as const }],
    width: 130,
    sort: true,
  },
  {
    id: 'name',
    header: ['Iniciativa / Projeto', { filter: 'text' as const }],
    flexgrow: 2,
    minWidth: 280,
    treetoggle: true,
    sort: true,
  },
  {
    id: 'classLabel',
    header: ['Classe', { filter: 'text' as const }],
    width: 145,
    sort: true,
  },
  {
    id: 'statusLabel',
    header: ['Situação', { filter: 'text' as const }],
    width: 145,
    sort: true,
  },
  {
    id: 'area',
    header: ['Área', { filter: 'text' as const }],
    width: 180,
    sort: true,
  },
  {
    id: 'priority',
    header: ['Prioridade', { filter: 'text' as const }],
    width: 120,
    sort: true,
  },
  {
    id: 'criticality',
    header: ['Criticidade', { filter: 'text' as const }],
    width: 120,
    sort: true,
  },
  {
    id: 'progressLabel',
    header: 'Progresso',
    width: 110,
    sort: true,
  },
  {
    id: 'startDate',
    header: 'Início',
    width: 115,
    sort: true,
  },
  {
    id: 'targetEndDate',
    header: 'Término',
    width: 115,
    sort: true,
  },
  {
    id: 'health',
    header: ['Saúde', { filter: 'text' as const }],
    width: 125,
    sort: true,
  },
  {
    id: 'risk',
    header: ['Risco', { filter: 'text' as const }],
    width: 115,
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
      <div className="sparks-data-explorer-beta__toolbar">
        <div>
          <p>SPARKs Data Explorer · Beta</p>
          <strong>Portfólio hierárquico de iniciativas</strong>
          <span>
            Pesquisa e filtros por coluna, ordenação, hierarquia e seleção
            sobre o mesmo read-model canônico do Portfólio.
          </span>
        </div>

        <div className="sparks-data-explorer-beta__actions">
          <span>
            {initiatives.length} registro
            {initiatives.length === 1 ? '' : 's'}
          </span>
          <button
            type="button"
            disabled={!selectedInitiative}
            onClick={() => {
              if (selectedInitiative) {
                onOpenInitiative(selectedInitiative)
              }
            }}
          >
            Abrir selecionada
          </button>
        </div>
      </div>

      <div className="sparks-data-explorer-beta__grid">
        <Willow>
          <Grid
            tree
            data={data}
            columns={columns}
            init={init}
            select
          />
        </Willow>
      </div>

      <footer>
        <span>
          Beta somente leitura: alterações continuam passando pelos fluxos
          governados do SPARKs.
        </span>
        {selectedInitiative ? (
          <strong>
            Selecionada: {selectedInitiative.initiative_code} ·{' '}
            {selectedInitiative.initiative_name}
          </strong>
        ) : (
          <strong>Selecione uma linha para abrir a iniciativa.</strong>
        )}
      </footer>
    </section>
  )
}