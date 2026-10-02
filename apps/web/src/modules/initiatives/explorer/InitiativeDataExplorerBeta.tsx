import { useMemo, useState } from 'react'
import { SparksSmartGrid, type SparksSmartGridColumn } from '../../../components/design-system/SparksSmartGrid'

import type { InitiativePortfolioRow } from '../contracts/initiativePortfolio'

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

export function InitiativeDataExplorerBeta({
  initiatives,
  onOpenInitiative,
}: InitiativeDataExplorerBetaProps) {
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [groupMode, setGroupMode] =
    useState<GroupMode>('strategic_theme_objective')
  const data = useMemo(
    () => buildRows(initiatives, groupMode),
    [groupMode, initiatives],
  )

  const columns = useMemo<SparksSmartGridColumn[]>(() => [
    { id: 'classLabel', label: 'Tipo', minWidth: 175, maxWidth: 220 },
    { id: 'name', label: 'Iniciativa / agrupamento', minWidth: 390, maxWidth: 620, grow: 2, treeToggle: true, tooltip: true },
    { id: 'strategicTheme', label: 'Tema Estratégico', minWidth: 250, maxWidth: 420, tooltip: true },
    { id: 'strategicObjective', label: 'Objetivo Estratégico', minWidth: 285, maxWidth: 460, tooltip: true },
    { id: 'progressLabel', label: 'Progresso', minWidth: 120, maxWidth: 150, align: 'center' },
    { id: 'statusLabel', label: 'Situação', minWidth: 150, maxWidth: 190, align: 'center' },
    { id: 'area', label: 'Área', minWidth: 180, maxWidth: 300, tooltip: true },
    { id: 'responsible', label: 'Responsável', minWidth: 190, maxWidth: 300, tooltip: true },
    { id: 'strategic', label: 'Estratégia', minWidth: 135, maxWidth: 170, align: 'center' },
    { id: 'priority', label: 'Prioridade', minWidth: 115, maxWidth: 150, align: 'center' },
    { id: 'criticality', label: 'Criticidade', minWidth: 115, maxWidth: 150, align: 'center' },
    { id: 'startDate', label: 'Início', minWidth: 110, maxWidth: 140, align: 'center' },
    { id: 'targetEndDate', label: 'Término', minWidth: 110, maxWidth: 140, align: 'center' },
    { id: 'health', label: 'Saúde', minWidth: 120, maxWidth: 160, align: 'center' },
    { id: 'risk', label: 'Risco', minWidth: 110, maxWidth: 150, align: 'center' },
  ], [])

  const selectedInitiative =
    initiatives.find(
      (initiative) => initiative.initiative_id === selectedId,
    ) ?? null


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
            <option value="area">Área → Iniciativa</option>
            <option value="area_objective">Área → Objetivo Estratégico → Iniciativa</option>
            <option value="area_theme">Área → Tema Estratégico → Iniciativa</option>
            <option value="area_theme_objective">Área → Tema Estratégico → Objetivo Estratégico → Iniciativa</option>
            <option value="strategic_theme_objective">Tema Estratégico → Objetivo Estratégico → Iniciativa</option>
            <option value="strategic_objective">Objetivo Estratégico → Iniciativa</option>
            <option value="objective_area">Objetivo Estratégico → Área → Iniciativa</option>
            <option value="strategic_theme">Tema Estratégico → Iniciativa</option>
            <option value="responsible_objective">Responsável → Objetivo Estratégico → Iniciativa</option>
            <option value="status_area">Situação → Área → Iniciativa</option>
            <option value="priority_area">Prioridade → Área → Iniciativa</option>
            <option value="area_strategic">Área → Estratégico/Não estratégico → Iniciativa</option>
            <option value="area_responsible_strategic">Área → Responsável → Estratégico/Não estratégico → Iniciativa</option>
            <option value="responsible_strategic">Responsável → Estratégico/Não estratégico → Iniciativa</option>
            <option value="initiative_hierarchy">Hierarquia própria das iniciativas</option>
          </select>
        </label>
      </div>

      <div className="sparks-data-explorer-beta__grid">
        <SparksSmartGrid
          rows={data}
          columns={columns}
          ariaLabel="Exploração Estratégica do Plano de Ação"
          selectedId={selectedId}
          tree
          treeContextActions
          viewportMode="standard"
          primaryActionLabel="Abrir ficha da iniciativa"
          onSelect={(id) => setSelectedId(id)}
          onDoubleClick={(id) => {
            if (id.startsWith('group:')) return
            const initiative = initiatives.find((candidate) => candidate.initiative_id === id)
            if (initiative) onOpenInitiative(initiative)
          }}
        />
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
