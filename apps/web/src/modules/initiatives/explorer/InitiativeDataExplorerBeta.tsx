import { useMemo, useState } from 'react'
import { Grid, Willow } from '@svar-ui/react-grid'

import type { InitiativePortfolioRow } from '../contracts/initiativePortfolio'

import '@svar-ui/react-grid/all.css'
import './InitiativeDataExplorerBeta.css'

type InitiativeDataExplorerBetaProps = {
  initiatives: InitiativePortfolioRow[]
  onOpenInitiative: (initiative: InitiativePortfolioRow) => void
}

type GroupMode =
  | 'initiative_hierarchy'
  | 'area_strategic'
  | 'area'
  | 'area_responsible_strategic'
  | 'responsible_strategic'

type ExplorerRow = {
  id: string
  initiativeId: string | null
  name: string
  classLabel: string
  statusLabel: string
  area: string
  responsible: string
  strategic: string
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

function toInitiativeRow(initiative: InitiativePortfolioRow): ExplorerRow {
  return {
    id: initiative.initiative_id,
    initiativeId: initiative.initiative_id,
    name: initiative.initiative_name,
    classLabel: classLabel(initiative.initiative_class),
    statusLabel: statusLabel(initiative.initiative_status),
    area: initiative.responsible_area_name ?? 'Área não definida',
    responsible: initiative.responsible_name ?? 'Responsável não definido',
    strategic: initiative.is_strategic ? 'Estratégica' : 'Não estratégica',
    priority: priorityLabel(initiative.priority),
    criticality: priorityLabel(initiative.criticality),
    progressLabel: `${initiative.progress}%`,
    startDate: formatDate(initiative.start_date),
    targetEndDate: formatDate(initiative.target_end_date),
    health: healthLabel(initiative.health_status),
    risk: riskLabel(initiative.risk_level),
    open: false,
  }
}

function sortTree(rows: ExplorerRow[]) {
  rows.sort((first, second) =>
    first.name.localeCompare(second.name, 'pt-BR'),
  )

  for (const row of rows) {
    if (row.data && row.data.length > 0) {
      sortTree(row.data)
    } else {
      delete row.data
    }
  }

  return rows
}

function buildInitiativeTree(initiatives: InitiativePortfolioRow[]) {
  const sourceById = new Map(
    initiatives.map((initiative) => [
      initiative.initiative_id,
      initiative,
    ]),
  )

  const rowById = new Map(
    initiatives.map((initiative) => [
      initiative.initiative_id,
      { ...toInitiativeRow(initiative), data: [] as ExplorerRow[] },
    ]),
  )

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

  return sortTree(roots)
}

function groupRows(
  initiatives: InitiativePortfolioRow[],
  dimensions: Array<{
    key: string
    label: (initiative: InitiativePortfolioRow) => string
    classLabel: string
  }>,
): ExplorerRow[] {
  const root: ExplorerRow[] = []

  const ensureGroup = (
    rows: ExplorerRow[],
    id: string,
    name: string,
    groupClassLabel: string,
  ) => {
    let group = rows.find((row) => row.id === id)

    if (!group) {
      group = {
        id,
        initiativeId: null,
        name,
        classLabel: groupClassLabel,
        statusLabel: '',
        area: '',
        responsible: '',
        strategic: '',
        priority: '',
        criticality: '',
        progressLabel: '',
        startDate: '',
        targetEndDate: '',
        health: '',
        risk: '',
        open: true,
        data: [],
      }
      rows.push(group)
    }

    return group
  }

  for (const initiative of initiatives) {
    let currentRows = root
    const keyParts: string[] = []

    dimensions.forEach((dimension) => {
      const label = dimension.label(initiative)
      keyParts.push(`${dimension.key}:${label}`)
      const id = `group:${keyParts.join('|')}`
      const group = ensureGroup(
        currentRows,
        id,
        label,
        dimension.classLabel,
      )

      group.data ??= []
      currentRows = group.data
    })

    currentRows.push(toInitiativeRow(initiative))
  }

  return sortTree(root)
}

function buildRows(
  initiatives: InitiativePortfolioRow[],
  mode: GroupMode,
) {
  if (mode === 'initiative_hierarchy') {
    return buildInitiativeTree(initiatives)
  }

  const area = {
    key: 'area',
    label: (initiative: InitiativePortfolioRow) =>
      initiative.responsible_area_name ?? 'Área não definida',
    classLabel: 'Área',
  }

  const responsible = {
    key: 'responsible',
    label: (initiative: InitiativePortfolioRow) =>
      initiative.responsible_name ?? 'Responsável não definido',
    classLabel: 'Responsável',
  }

  const strategic = {
    key: 'strategic',
    label: (initiative: InitiativePortfolioRow) =>
      initiative.is_strategic ? 'Estratégica' : 'Não estratégica',
    classLabel: 'Vínculo estratégico',
  }

  if (mode === 'area_strategic') {
    return groupRows(initiatives, [area, strategic])
  }

  if (mode === 'area') {
    return groupRows(initiatives, [area])
  }

  if (mode === 'area_responsible_strategic') {
    return groupRows(initiatives, [area, responsible, strategic])
  }

  return groupRows(initiatives, [responsible, strategic])
}

const columns = [
  {
    id: 'classLabel',
    header: 'Tipo',
    width: 150,
    sort: true,
  },
  {
    id: 'name',
    header: 'Iniciativa / agrupamento',
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
    id: 'responsible',
    header: 'Responsável',
    width: 180,
    sort: true,
  },
  {
    id: 'strategic',
    header: 'Estratégia',
    width: 135,
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
  const [groupMode, setGroupMode] =
    useState<GroupMode>('area_strategic')

  const data = useMemo(
    () => buildRows(initiatives, groupMode),
    [groupMode, initiatives],
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
      const id =
        event.id === undefined || event.id === null
          ? null
          : String(event.id)

      setSelectedId(
        id && !id.startsWith('group:')
          ? id
          : null,
      )
    })
  }

  return (
    <section className="sparks-data-explorer-beta">
      <div
        className="sparks-data-explorer-beta__toolbar"
        title="Escolha uma hierarquia, expanda ou recolha os grupos, ordene as colunas e dê duplo clique numa iniciativa para abrir."
      >
        <div>
          <p>SPARKs Data Explorer · Beta</p>
          <strong>Exploração hierárquica do Plano de Ação</strong>
        </div>

        <label className="sparks-data-explorer-beta__grouping">
          <span>Organizar por</span>
          <select
            value={groupMode}
            onChange={(event) =>
              setGroupMode(event.target.value as GroupMode)
            }
          >
            <option value="area_strategic">
              Área → Estratégico/Não estratégico → Iniciativa
            </option>
            <option value="area">
              Área → Iniciativa
            </option>
            <option value="area_responsible_strategic">
              Área → Responsável → Estratégico/Não estratégico → Iniciativa
            </option>
            <option value="responsible_strategic">
              Responsável → Estratégico/Não estratégico → Iniciativa
            </option>
            <option value="initiative_hierarchy">
              Hierarquia própria das iniciativas
            </option>
          </select>
        </label>
      </div>

      <div
        className="sparks-data-explorer-beta__grid"
        role="region"
        aria-label="Exploração hierárquica do Plano de Ação"
        tabIndex={0}
        title="Expanda ou recolha os agrupamentos. Dê duplo clique numa iniciativa para abrir."
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
            Somente leitura · agrupamentos analíticos derivados dos mesmos
            registros canônicos.
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