import { useMemo } from 'react'

import {
  SparksSmartGrid,
  type SparksSmartGridColumn,
  type SparksSmartGridRow,
} from '../../../components/design-system/SparksSmartGrid'
import type { InitiativePortfolioRow } from '../contracts/initiativePortfolio'

import '../../../components/design-system/SparksGridSemantics.css'
import './InitiativePortfolioSmartGrid.css'

type InitiativePortfolioSmartGridProps = {
  initiatives: InitiativePortfolioRow[]
  selectedInitiativeId: string | null
  onSelectInitiative: (initiative: InitiativePortfolioRow) => void
  onOpenInitiative: (initiative: InitiativePortfolioRow) => void
}

type InitiativeGridRow = SparksSmartGridRow & {
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

function dateLabel(value: string | null) {
  if (!value) return 'Não definido'
  const raw = value.slice(0, 10)
  const [year, month, day] = raw.split('-')
  return year && month && day ? `${day}/${month}/${year}` : raw
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
  const initiativeById = useMemo(
    () => new Map(initiatives.map((initiative) => [initiative.initiative_id, initiative])),
    [initiatives],
  )

  const rows = useMemo<InitiativeGridRow[]>(
    () => initiatives.map((initiative) => ({
      id: initiative.initiative_id,
      code: initiative.initiative_code,
      initiative: initiative.initiative_name,
      status: initiativeStatusLabel(initiative),
      initiativeClass: classLabels[initiative.initiative_class] ?? 'Classe não classificada',
      responsibleArea: initiative.responsible_area_name ?? 'Não definida',
      priority: priorityLabels[initiative.priority] ?? 'Não definida',
      responsible: initiative.responsible_name ?? 'Não definido',
      startDate: dateLabel(initiative.start_date),
      dueDate: dateLabel(initiative.target_end_date),
      progress: isSparksDraft(initiative) ? 'Não iniciado' : `${Math.round(initiative.progress)}%`,
      origin: originLabels[initiative.proposal_origin] ?? 'Outra origem',
      strategicTheme: initiative.strategic_theme_names.length > 0
        ? initiative.strategic_theme_names.join(' · ')
        : initiative.strategic_theme ?? 'Não definido',
    })),
    [initiatives],
  )
  const columns = useMemo<SparksSmartGridColumn[]>(() => [
    { id: 'code', label: 'Código', minWidth: 105, maxWidth: 190 },
    { id: 'initiative', label: 'Iniciativa', minWidth: 260, maxWidth: 520, tooltip: true, grow: 2 },
    { id: 'status', label: 'Situação', minWidth: 125, maxWidth: 190, align: 'center', semanticClass: 'sparks-grid-semantic-status' },
    { id: 'initiativeClass', label: 'Classe', minWidth: 120, maxWidth: 190, align: 'center', semanticClass: 'sparks-grid-semantic-initiative-class' },
    { id: 'responsibleArea', label: 'Área responsável', minWidth: 160, maxWidth: 320, tooltip: true, grow: 2 },
    { id: 'priority', label: 'Prioridade', minWidth: 115, maxWidth: 160, align: 'center' },
    { id: 'responsible', label: 'Responsável', minWidth: 150, maxWidth: 300, tooltip: true },
    { id: 'startDate', label: 'Início', minWidth: 120, maxWidth: 150, align: 'center' },
    { id: 'dueDate', label: 'Término-alvo', minWidth: 130, maxWidth: 170, align: 'center' },
    { id: 'progress', label: 'Progresso', minWidth: 120, maxWidth: 165, align: 'center' },
    { id: 'origin', label: 'Origem', minWidth: 150, maxWidth: 280, tooltip: true },
    { id: 'strategicTheme', label: 'Tema estratégico', minWidth: 180, maxWidth: 420, tooltip: true, grow: 2 },
  ], [])

  const selectInitiative = (id: string) => {
    const initiative = initiativeById.get(id)
    if (initiative) onSelectInitiative(initiative)
  }

  const openInitiative = (id: string) => {
    const initiative = initiativeById.get(id)
    if (initiative) onOpenInitiative(initiative)
  }

  return (
    <div className="skpe-initiative-smart-grid-shell">
      <SparksSmartGrid
        rows={rows}
        columns={columns}
        ariaLabel="Portfólio de iniciativas"
        selectedId={selectedInitiativeId}
        onSelect={selectInitiative}
        onDoubleClick={openInitiative}
        primaryActionLabel="Abrir ficha da iniciativa"
        viewportMode="standard"
      />
      <p className="skpe-initiative-smart-grid-hint">
        Clique uma vez para selecionar a linha. Dê duplo clique para abrir a ficha da iniciativa.
        Rascunhos não recebem progresso operacional antes de avançarem no fluxo de gestão.
      </p>
    </div>
  )
}
