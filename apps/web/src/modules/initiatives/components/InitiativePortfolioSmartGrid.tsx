import { useMemo, useState } from 'react'
import { Filter, X } from 'lucide-react'
import { Grid, Willow, type IColumnConfig } from '@svar-ui/react-grid'

import '@svar-ui/react-grid/all.css'
import '../../../components/design-system/SparksGridSemantics.css'
import { SparksGridNavigator } from '../../../components/design-system/SparksGridNavigator'
import { gridSemanticCellClass, gridSemanticHeaderClass } from '../../../components/design-system/SparksGridSemantics'
import type { InitiativePortfolioRow } from '../contracts/initiativePortfolio'

import '../../skpe/components/OrganizationUsersSmartGrid.css'
import './InitiativePortfolioSmartGrid.css'

type InitiativePortfolioSmartGridProps = {
  initiatives: InitiativePortfolioRow[]
  selectedInitiativeId: string | null
  onSelectInitiative: (initiative: InitiativePortfolioRow) => void
  onOpenInitiative: (initiative: InitiativePortfolioRow) => void
}

type InitiativeGridRow = {
  id: string
  code: string
  initiative: string
  status: string
  initiativeClass: string
  responsibleArea: string
  priority: string
  responsible: string
  startDate: string
  dueDate: string
  progress: string
  origin: string
  strategicTheme: string
}

const headerLabels: Record<keyof Omit<InitiativeGridRow, 'id'>, string> = {
  code: 'Código',
  initiative: 'Iniciativa',
  status: 'Situação',
  initiativeClass: 'Classe',
  responsibleArea: 'Área responsável',
  priority: 'Prioridade',
  responsible: 'Responsável',
  startDate: 'Início',
  dueDate: 'Término-alvo',
  progress: 'Progresso',
  origin: 'Origem',
  strategicTheme: 'Tema estratégico',
}

const statusLabels: Record<string, string> = {
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

const classLabels: Record<string, string> = {
  program: 'Programa',
  project: 'Projeto',
  initiative: 'Iniciativa',
  structuring_action: 'Ação estruturante',
  process: 'Processo',
  sprint: 'Sprint',
  task: 'Tarefa',
  work: 'Trabalho',
}

const priorityLabels: Record<string, string> = {
  low: 'Baixa',
  medium: 'Média',
  high: 'Alta',
  critical: 'Crítica',
}

const originLabels: Record<string, string> = {
  sparks_suggestion: 'Sugestão SPARKs',
  organization: 'Organização',
  joint_construction: 'Construção conjunta',
  previous_plan: 'Plano anterior',
  assessment: 'Diagnóstico',
  action_plan: 'Plano de ação',
  bmc_vpc: 'BMC/VPC',
  benchmark: 'Benchmark',
}

function normalize(value: unknown) {
  return String(value ?? '')
    .normalize('NFD')
    .replace(/\p{Diacritic}/gu, '')
    .toLocaleLowerCase('pt-BR')
    .trim()
}

function dateLabel(value: string | null) {
  if (!value) return 'Não definido'
  const raw = value.slice(0, 10)
  const [year, month, day] = raw.split('-')
  return year && month && day ? `${day}/${month}/${year}` : raw
}

function fittedColumnWidth(
  header: string,
  values: Array<string | number | null | undefined>,
  minimum: number,
  maximum: number,
) {
  const longest = values.reduce<number>(
    (current, value) =>
      Math.max(current, String(value ?? '').trim().length),
    header.length,
  )

  const estimated = Math.ceil(longest * 7.4 + 56)
  return Math.max(minimum, Math.min(maximum, estimated))
}
function isSparksDraft(initiative: InitiativePortfolioRow) {
  return (
    initiative.initiative_status === 'proposed' &&
    initiative.proposal_origin === 'sparks_suggestion'
  )
}

function initiativeStatusLabel(initiative: InitiativePortfolioRow) {
  if (isSparksDraft(initiative)) return 'Rascunho'
  return statusLabels[initiative.initiative_status] ?? 'Situação não classificada'
}

export function InitiativePortfolioSmartGrid({
  initiatives,
  selectedInitiativeId,
  onSelectInitiative,
  onOpenInitiative,
}: InitiativePortfolioSmartGridProps) {
  const [columnFilters, setColumnFilters] = useState<Record<string, string>>({})
  const [openColumnFilter, setOpenColumnFilter] = useState<string | null>(null)

  const initiativeById = useMemo(
    () =>
      new Map(
        initiatives.map((initiative) => [
          initiative.initiative_id,
          initiative,
        ]),
      ),
    [initiatives],
  )

  const rows = useMemo<InitiativeGridRow[]>(
    () =>
      initiatives.map((initiative) => ({
        id: initiative.initiative_id,
        code: initiative.initiative_code,
        initiative: initiative.initiative_name,
        status: initiativeStatusLabel(initiative),
        initiativeClass:
          classLabels[initiative.initiative_class] ?? 'Classe não classificada',
        responsibleArea:
          initiative.responsible_area_name ?? 'Não definida',
        priority:
          priorityLabels[initiative.priority] ?? 'Não definida',
        responsible:
          initiative.responsible_name ?? 'Não definido',
        startDate: dateLabel(initiative.start_date),
        dueDate: dateLabel(initiative.target_end_date),
        progress: isSparksDraft(initiative)
          ? 'Não iniciado'
          : `${Math.round(initiative.progress)}%`,
        origin:
          originLabels[initiative.proposal_origin] ?? 'Outra origem',
        strategicTheme:
          initiative.strategic_theme_names.length > 0
            ? initiative.strategic_theme_names.join(' · ')
            : initiative.strategic_theme ?? 'Não definido',
      })),
    [initiatives],
  )

  const fittedWidths = useMemo(
    () => ({
      code: fittedColumnWidth(
        'Código',
        rows.map((row) => row.code),
        105,
        190,
      ),
      initiative: fittedColumnWidth(
        'Iniciativa',
        rows.map((row) => row.initiative),
        260,
        520,
      ),
      status: fittedColumnWidth(
        'Situação',
        rows.map((row) => row.status),
        125,
        190,
      ),
      initiativeClass: fittedColumnWidth(
        'Classe',
        rows.map((row) => row.initiativeClass),
        120,
        190,
      ),
      responsibleArea: fittedColumnWidth(
        'Área responsável',
        rows.map((row) => row.responsibleArea),
        160,
        320,
      ),
      priority: fittedColumnWidth(
        'Prioridade',
        rows.map((row) => row.priority),
        115,
        160,
      ),
      responsible: fittedColumnWidth(
        'Responsável',
        rows.map((row) => row.responsible),
        150,
        300,
      ),
      startDate: fittedColumnWidth(
        'Início',
        rows.map((row) => row.startDate),
        120,
        150,
      ),
      dueDate: fittedColumnWidth(
        'Término-alvo',
        rows.map((row) => row.dueDate),
        130,
        170,
      ),
      progress: fittedColumnWidth(
        'Progresso',
        rows.map((row) => row.progress),
        120,
        165,
      ),
      origin: fittedColumnWidth(
        'Origem',
        rows.map((row) => row.origin),
        150,
        280,
      ),
      strategicTheme: fittedColumnWidth(
        'Tema estratégico',
        rows.map((row) => row.strategicTheme),
        180,
        420,
      ),
    }),
    [rows],
  )
  const data = useMemo(() => {
    const activeFilters = Object.entries(columnFilters).filter(
      ([, value]) => value.trim(),
    )

    if (activeFilters.length === 0) return rows

    return rows.filter((row) =>
      activeFilters.every(([id, value]) => {
        const record = row as unknown as Record<string, unknown>
        return normalize(record[id]).includes(normalize(value))
      }),
    )
  }, [columnFilters, rows])

  function InitiativeHeaderCell({ column }: { column: any }) {
    const id = String(column?.id ?? '')
    const label =
      headerLabels[id as keyof typeof headerLabels] ??
      String(column?.header?.text ?? '')
    const value = columnFilters[id] ?? ''
    const open = openColumnFilter === id

    return (
      <div className="sparks-data-explorer-header-cell">
        {open ? (
          <div
            className="sparks-data-explorer-header-filter-input-wrap"
            onClick={(event) => event.stopPropagation()}
          >
            <input
              autoFocus
              className="sparks-data-explorer-header-filter-input"
              value={value}
              placeholder={`Filtrar ${label.toLocaleLowerCase('pt-BR')}`}
              aria-label={`Filtrar ${label}`}
              onChange={(event) =>
                setColumnFilters((current) => ({
                  ...current,
                  [id]: event.target.value,
                }))
              }
            />
            <button
              type="button"
              title="Fechar filtro"
              aria-label={`Fechar filtro de ${label}`}
              onClick={() => setOpenColumnFilter(null)}
            >
              <X size={14} aria-hidden="true" />
            </button>
          </div>
        ) : (
          <>
            <span>{label}</span>
            <button
              type="button"
              title={`Filtrar ${label}`}
              aria-label={`Filtrar ${label}`}
              className={
                value.trim()
                  ? 'sparks-data-explorer-header-filter is-active'
                  : 'sparks-data-explorer-header-filter'
              }
              onClick={(event) => {
                event.stopPropagation()
                setOpenColumnFilter(id)
              }}
            >
              <Filter size={14} aria-hidden="true" />
            </button>
          </>
        )}
      </div>
    )
  }

  function smartHeader(text: string, semanticId?: string) {
    const semanticClass = semanticId
      ? gridSemanticHeaderClass(semanticId)
      : ''

    return {
      text,
      cell: InitiativeHeaderCell,
      css: semanticClass
        ? `sparks-data-explorer-header-main ${semanticClass}`
        : 'sparks-data-explorer-header-main',
    }
  }
  const columns: IColumnConfig[] = [
    {
      id: 'code',
      header: smartHeader('Código'),
      width: fittedWidths.code,
      sort: true,
      resize: true,
    },
    {
      id: 'initiative',
      header: smartHeader('Iniciativa'),
      width: fittedWidths.initiative,
      sort: true,
      resize: true,
      tooltip: true,
    },
    {
      id: 'status',
      header: smartHeader('Situação', 'status'),
      width: fittedWidths.status,
      sort: true,
      resize: true,
      css: gridSemanticCellClass('status'),
    },
    {
      id: 'initiativeClass',
      header: smartHeader('Classe', 'initiativeClass'),
      width: fittedWidths.initiativeClass,
      sort: true,
      resize: true,
      css: gridSemanticCellClass('initiativeClass'),
    },
    {
      id: 'responsibleArea',
      header: smartHeader('Área responsável', 'responsibleArea'),
      width: fittedWidths.responsibleArea,
      sort: true,
      resize: true,
      tooltip: true,
      css: gridSemanticCellClass('responsibleArea'),
    },
    {
      id: 'priority',
      header: smartHeader('Prioridade', 'priority'),
      width: fittedWidths.priority,
      sort: true,
      resize: true,
      css: gridSemanticCellClass('priority'),
    },
    {
      id: 'responsible',
      header: smartHeader('Responsável', 'responsible'),
      width: fittedWidths.responsible,
      sort: true,
      resize: true,
      tooltip: true,
      css: gridSemanticCellClass('responsible'),
    },
    {
      id: 'startDate',
      header: smartHeader('Início', 'startDate'),
      width: fittedWidths.startDate,
      sort: true,
      resize: true,
      css: gridSemanticCellClass('startDate'),
    },
    {
      id: 'dueDate',
      header: smartHeader('Término-alvo', 'dueDate'),
      width: fittedWidths.dueDate,
      sort: true,
      resize: true,
      css: gridSemanticCellClass('dueDate'),
    },
    {
      id: 'progress',
      header: smartHeader('Progresso', 'progress'),
      width: fittedWidths.progress,
      sort: true,
      resize: true,
      css: gridSemanticCellClass('progress'),
    },
    {
      id: 'origin',
      header: smartHeader('Origem'),
      width: fittedWidths.origin,
      sort: true,
      resize: true,
      tooltip: true,
    },
    {
      id: 'strategicTheme',
      header: smartHeader('Tema estratégico'),
      width: fittedWidths.strategicTheme,
      sort: true,
      resize: true,
      tooltip: true,
    },
  ]
  function resolveEventInitiativeId(event: any) {
    const raw =
      event?.id ??
      event?.row?.id ??
      event?.data?.id ??
      event?.item?.id ??
      null
    return raw === null || raw === undefined ? null : String(raw)
  }

  function init(api: {
    on: (
      action: string,
      handler: (event: any) => void,
    ) => void
  }) {
    api.on('select-row', (event) => {
      const id = resolveEventInitiativeId(event)
      if (!id) return
      const initiative = initiativeById.get(id)
      if (initiative) onSelectInitiative(initiative)
    })

    const openSelected = (event: any) => {
      const id =
        resolveEventInitiativeId(event) ??
        selectedInitiativeId
      if (!id) return
      const initiative = initiativeById.get(id)
      if (initiative) onOpenInitiative(initiative)
    }

    api.on('dblclick-row', openSelected)
    api.on('double-click-row', openSelected)
  }

  const activeFilterCount = Object.values(columnFilters).filter((value) =>
    value.trim(),
  ).length

  return (
    <div className="skpe-initiative-smart-grid-shell">
      {activeFilterCount > 0 ? (
        <div className="skpe-initiative-smart-grid-filter-summary">
          <span>
            {activeFilterCount}{' '}
            {activeFilterCount === 1 ? 'filtro ativo' : 'filtros ativos'}
          </span>
          <button
            type="button"
            onClick={() => {
              setColumnFilters({})
              setOpenColumnFilter(null)
            }}
          >
            Limpar filtros
          </button>
        </div>
      ) : null}

      <div
        className="sparks-user-grid sparks-initiative-portfolio-grid"
        data-sparks-grid-shell
        role="region"
        aria-label="Portfólio de iniciativas"
        onDoubleClickCapture={() => {
          if (!selectedInitiativeId) return
          const initiative = initiativeById.get(selectedInitiativeId)
          if (initiative) onOpenInitiative(initiative)
        }}
      >
        <Willow>
          <Grid
            data={data}
            columns={columns}
            init={init}
            select
            selectedRows={
              selectedInitiativeId ? [selectedInitiativeId] : []
            }
            autoRowHeight
          />
        </Willow>
        <SparksGridNavigator />
      </div>

      <p className="skpe-initiative-smart-grid-hint">
        Clique uma vez para selecionar a linha. Dê duplo clique para abrir a
        ficha da iniciativa. Rascunhos não recebem progresso operacional antes
        de avançarem no fluxo de gestão.
      </p>
    </div>
  )
}
