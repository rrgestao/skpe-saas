import { useMemo, useState } from 'react'
import { SparksGridNavigator } from '../../../components/design-system/SparksGridNavigator'
import { Filter, X } from 'lucide-react'
import { Grid, Willow, type IColumnConfig } from '@svar-ui/react-grid'

import type { InitiativePortfolioRow } from '../contracts/initiativePortfolio'

import '@svar-ui/react-grid/all.css'
import './InitiativeDataExplorerBeta.css'

type InitiativeDataExplorerBetaProps = {
  initiatives: InitiativePortfolioRow[]
  onOpenInitiative: (initiative: InitiativePortfolioRow) => void
}

type GroupMode =
  | 'area'
  | 'area_objective'
  | 'area_theme'
  | 'area_theme_objective'
  | 'strategic_theme_objective'
  | 'strategic_theme'
  | 'strategic_objective'
  | 'objective_area'
  | 'responsible_objective'
  | 'status_area'
  | 'priority_area'
  | 'initiative_hierarchy'
  | 'area_strategic'
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
  strategicTheme: string
  strategicObjective: string
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

function joined(values: string[], fallback: string) {
  return values.length > 0 ? values.join(' | ') : fallback
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
    strategicTheme: joined(
      initiative.strategic_theme_names,
      'Tema não definido',
    ),
    strategicObjective: joined(
      initiative.strategic_objective_names,
      'Objetivo não definido',
    ),
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
        strategicTheme: '',
        strategicObjective: '',
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

  const theme = {
    key: 'strategic-theme',
    label: (initiative: InitiativePortfolioRow) =>
      joined(initiative.strategic_theme_names, 'Tema não definido'),
    classLabel: 'Tema Estratégico',
  }

  const objective = {
    key: 'strategic-objective',
    label: (initiative: InitiativePortfolioRow) =>
      joined(initiative.strategic_objective_names, 'Objetivo não definido'),
    classLabel: 'Objetivo Estratégico',
  }

  const status = {
    key: 'status',
    label: (initiative: InitiativePortfolioRow) =>
      statusLabel(initiative.initiative_status),
    classLabel: 'Situação',
  }

  const priority = {
    key: 'priority',
    label: (initiative: InitiativePortfolioRow) =>
      priorityLabel(initiative.priority),
    classLabel: 'Prioridade',
  }

  if (mode === 'area_objective') {
    return groupRows(initiatives, [area, objective])
  }

  if (mode === 'area_theme') {
    return groupRows(initiatives, [area, theme])
  }

  if (mode === 'area_theme_objective') {
    return groupRows(initiatives, [area, theme, objective])
  }

  if (mode === 'objective_area') {
    return groupRows(initiatives, [objective, area])
  }

  if (mode === 'responsible_objective') {
    return groupRows(initiatives, [responsible, objective])
  }

  if (mode === 'status_area') {
    return groupRows(initiatives, [status, area])
  }

  if (mode === 'priority_area') {
    return groupRows(initiatives, [priority, area])
  }

  if (mode === 'strategic_theme_objective') {
    return groupRows(initiatives, [theme, objective])
  }

  if (mode === 'strategic_theme') {
    return groupRows(initiatives, [theme])
  }

  if (mode === 'strategic_objective') {
    return groupRows(initiatives, [objective])
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

type ColumnFilterId =
  | 'classLabel'
  | 'name'
  | 'strategicTheme'
  | 'strategicObjective'
  | 'progressLabel'
  | 'statusLabel'
  | 'area'
  | 'responsible'
  | 'strategic'
  | 'priority'
  | 'criticality'
  | 'startDate'
  | 'targetEndDate'
  | 'health'
  | 'risk'

const columnFilterIds: ColumnFilterId[] = [
  'classLabel',
  'name',
  'strategicTheme',
  'strategicObjective',
  'progressLabel',
  'statusLabel',
  'area',
  'responsible',
  'strategic',
  'priority',
  'criticality',
  'startDate',
  'targetEndDate',
  'health',
  'risk',
]

function filterExplorerTree(
  rows: ExplorerRow[],
  filters: Partial<Record<ColumnFilterId, string>>,
): ExplorerRow[] {
  return rows.flatMap((row) => {
    const filteredChildren = row.data
      ? filterExplorerTree(row.data, filters)
      : undefined

    const selfMatches = columnFilterIds.every((id) => {
      const filterValue = (filters[id] ?? '').trim().toLocaleLowerCase('pt-BR')
      if (!filterValue) return true
      return String(row[id] ?? '')
        .toLocaleLowerCase('pt-BR')
        .includes(filterValue)
    })

    const hasMatchingChildren =
      filteredChildren !== undefined && filteredChildren.length > 0

    if (!selfMatches && !hasMatchingChildren) {
      return []
    }

    return [
      {
        ...row,
        ...(row.data
          ? {
              data: selfMatches ? row.data : filteredChildren,
              open: hasMatchingChildren ? true : row.open,
            }
          : {}),
      },
    ]
  })
}

export function InitiativeDataExplorerBeta({
  initiatives,
  onOpenInitiative,
}: InitiativeDataExplorerBetaProps) {
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [groupMode, setGroupMode] =
    useState<GroupMode>('strategic_theme_objective')
  const [columnFilters, setColumnFilters] = useState<Partial<Record<ColumnFilterId, string>>>({})
  const [openColumnFilter, setOpenColumnFilter] = useState<ColumnFilterId | null>(null)

  const data = useMemo(
    () =>
      filterExplorerTree(
        buildRows(initiatives, groupMode),
        columnFilters,
      ),
    [columnFilters, groupMode, initiatives],
  )

  function ExplorerHeaderCell(props: any) {
    const id = props.column.id as ColumnFilterId
    const label = props.cell.text as string
    const value = columnFilters[id] ?? ''
    const open = openColumnFilter === id

    return (
      <div className="sparks-data-explorer-header-cell">
        {open ? (
          <div
            className="sparks-data-explorer-header-inline-filter"
            onClick={(event) => event.stopPropagation()}
          >
            <input
              autoFocus
              value={value}
              placeholder={label}
              aria-label={`Filtrar ${label}`}
              onChange={(event) =>
                setColumnFilters((current) => ({
                  ...current,
                  [id]: event.target.value,
                }))
              }
              onKeyDown={(event) => {
                if (event.key === 'Escape') {
                  setOpenColumnFilter(null)
                }
              }}
            />
            {value ? (
              <button
                type="button"
                className="sparks-data-explorer-header-filter-clear"
                aria-label={`Limpar filtro de ${label}`}
                title={`Limpar filtro de ${label}`}
                onClick={(event) => {
                  event.stopPropagation()
                  setColumnFilters((current) => ({
                    ...current,
                    [id]: '',
                  }))
                }}
              >
                <X aria-hidden="true" size={14} />
              </button>
            ) : null}
          </div>
        ) : (
          <span className="sparks-data-explorer-header-label">{label}</span>
        )}

        <button
          type="button"
          className={
            value
              ? 'sparks-data-explorer-header-filter-button sparks-data-explorer-header-filter-button--active'
              : 'sparks-data-explorer-header-filter-button'
          }
          aria-label={`${open ? 'Fechar' : 'Abrir'} filtro de ${label}`}
          title={`${open ? 'Fechar' : 'Filtrar'} ${label}`}
          onClick={(event) => {
            event.stopPropagation()
            setOpenColumnFilter((current) => (current === id ? null : id))
          }}
        >
          <Filter aria-hidden="true" size={14} />
        </button>
      </div>
    )
  }

  function smartHeader(text: string) {
    return {
      text,
      cell: ExplorerHeaderCell,
      css: 'sparks-data-explorer-header-main',
    }
  }

  const columns: IColumnConfig[] = [
    { id: 'classLabel', header: smartHeader('Tipo'), width: 175, sort: true, resize: true },
    { id: 'name', header: smartHeader('Iniciativa / agrupamento'), width: 390, flexgrow: 2, treetoggle: true, sort: true, resize: true },
    { id: 'strategicTheme', header: smartHeader('Tema Estratégico'), width: 250, sort: true, resize: true },
    { id: 'strategicObjective', header: smartHeader('Objetivo Estratégico'), width: 285, sort: true, resize: true },
    { id: 'progressLabel', header: smartHeader('Progresso'), width: 120, sort: true, resize: true },
    { id: 'statusLabel', header: smartHeader('Situação'), width: 150, sort: true, resize: true },
    { id: 'area', header: smartHeader('Área'), width: 180, sort: true, resize: true },
    { id: 'responsible', header: smartHeader('Responsável'), width: 190, sort: true, resize: true },
    { id: 'strategic', header: smartHeader('Estratégia'), width: 135, sort: true, resize: true },
    { id: 'priority', header: smartHeader('Prioridade'), width: 115, sort: true, resize: true },
    { id: 'criticality', header: smartHeader('Criticidade'), width: 115, sort: true, resize: true },
    { id: 'startDate', header: smartHeader('Início'), width: 110, sort: true, resize: true },
    { id: 'targetEndDate', header: smartHeader('Término'), width: 110, sort: true, resize: true },
    { id: 'health', header: smartHeader('Saúde'), width: 120, sort: true, resize: true },
    { id: 'risk', header: smartHeader('Risco'), width: 110, sort: true, resize: true },
  ]

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
        title="Escolha uma hierarquia, expanda ou recolha os grupos, ordene as colunas e use os filtros nativos de cabeçalho."
      >
        <div>
          <p>SPARKs Exploração Hierárquica</p>
          <strong>Exploração Estratégica do Plano de Ação</strong>
        </div>

        <label className="sparks-data-explorer-beta__grouping">
          <span>Organizar por</span>
          <select
            value={groupMode}
            onChange={(event) =>
              setGroupMode(event.target.value as GroupMode)
            }
          >
            <option value="area">
              Área → Iniciativa
            </option>
            <option value="area_objective">
              Área → Objetivo Estratégico → Iniciativa
            </option>
            <option value="area_theme">
              Área → Tema Estratégico → Iniciativa
            </option>
            <option value="area_theme_objective">
              Área → Tema Estratégico → Objetivo Estratégico → Iniciativa
            </option>
            <option value="strategic_theme_objective">
              Tema Estratégico → Objetivo Estratégico → Iniciativa
            </option>
            <option value="strategic_objective">
              Objetivo Estratégico → Iniciativa
            </option>
            <option value="objective_area">
              Objetivo Estratégico → Área → Iniciativa
            </option>
            <option value="strategic_theme">
              Tema Estratégico → Iniciativa
            </option>
            <option value="responsible_objective">
              Responsável → Objetivo Estratégico → Iniciativa
            </option>
            <option value="status_area">
              Situação → Área → Iniciativa
            </option>
            <option value="priority_area">
              Prioridade → Área → Iniciativa
            </option>
            <option value="area_strategic">
              Área → Estratégico/Não estratégico → Iniciativa
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
        className="sparks-data-explorer-beta__grid" data-sparks-grid-shell
        role="region"
        aria-label="Exploração Estratégica do Plano de Ação"
        tabIndex={0}
        title="Clique nos cabeçalhos para ordenar. Use os filtros logo abaixo dos títulos. Ctrl/Cmd+clique permite ordenação por múltiplas colunas."
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
        <SparksGridNavigator />
</div>

      <footer>
        <div>
          <span>
            Somente leitura · agrupamentos analíticos derivados dos mesmos
            registros canônicos · ordenação e filtros nativos do SVAR Grid.
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