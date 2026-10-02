import { useMemo, useState } from 'react'
import { SparksSmartGrid, type SparksSmartGridColumn } from '../../../../components/design-system/SparksSmartGrid'
import '../../components/OrganizationUsersSmartGrid.css'

import type { ImportedDiagnosisRecord } from './strategicDiagnosisImportLoader.ts'

type StrategicRisksSmartGridProps = {
  records: ImportedDiagnosisRecord[]
  onOpenAssociatedInitiative?: (riskCode: string) => void
}

type RiskGridRow = {
  id: string
  code: string
  event: string
  category: string
  cause: string
  consequence: string
  probability: string
  impact: string
  inherent: string
  controls: string
  response: string
  treatment: string
  owner: string
  due: string
  residual: string
  status: string
}



function normalize(value: unknown): string {
  return String(value ?? '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .trim()
    .toLowerCase()
}

function display(value: unknown): string {
  if (value === null || value === undefined || value === '') return '—'
  if (Array.isArray(value)) return value.map((item) => String(item)).join(' / ')
  return String(value)
}

function ordinalRiskValue(value: unknown): number | null {
  const token = normalize(value)

  const map: Record<string, number> = {
    'muito baixa': 1,
    baixa: 2,
    media: 3,
    alta: 4,
    'muito alta': 5,
    'muito baixo': 1,
    baixo: 2,
    medio: 3,
    alto: 4,
    'muito alto': 5,
  }

  return map[token] ?? null
}

function numericRiskScore(value: unknown): number | null {
  const parsed = Number(String(value ?? '').replace(',', '.'))
  return Number.isFinite(parsed) ? parsed : null
}

function riskScoreBand(score: number | null): string {
  if (score === null) return ''
  if (score <= 4) return 'risk-scale-1'
  if (score <= 9) return 'risk-scale-2'
  if (score <= 14) return 'risk-scale-3'
  if (score <= 19) return 'risk-scale-4'
  return 'risk-scale-5'
}

export function StrategicRisksSmartGrid({
  records,
  onOpenAssociatedInitiative,
}: StrategicRisksSmartGridProps) {
  const [selectedRiskId, setSelectedRiskId] = useState<string | null>(null)

  const rows = useMemo<RiskGridRow[]>(
    () =>
      records.map((record) => ({
        id: record.id,
        code: display(record.values.codigo ?? record.id),
        event: display(record.values.evento_de_risco),
        category: display(record.values.categoria),
        cause: display(record.values.causa),
        consequence: display(record.values.consequencia),
        probability: display(record.values.probabilidade),
        impact: display(record.values.impacto),
        inherent: display(record.values.nivel_inerente),
        controls: display(record.values.controles_existentes),
        response: display(record.values.resposta),
        treatment: display(record.values.plano_de_tratamento),
        owner: display(record.values.responsavel),
        due: display(record.values.prazo),
        residual: display(record.values.risco_residual),
        status: display(record.values.status),
      })),
    [records],
  )

  const columns = useMemo<SparksSmartGridColumn[]>(() => [
    { id: 'code', label: 'Código', minWidth: 110, maxWidth: 160, tooltip: true, align: 'center' },
    { id: 'event', label: 'Evento de risco', minWidth: 340, maxWidth: 560, tooltip: true, grow: 2 },
    { id: 'category', label: 'Categoria', minWidth: 160, maxWidth: 240 },
    { id: 'cause', label: 'Causa', minWidth: 270, maxWidth: 480, tooltip: true, grow: 2 },
    { id: 'consequence', label: 'Consequência', minWidth: 290, maxWidth: 500, tooltip: true, grow: 2 },
    { id: 'probability', label: 'Probabilidade', minWidth: 145, maxWidth: 180, align: 'center', cellStyle: (row) => { const value = ordinalRiskValue(row.probability); return value ? `sparks-risk-cell sparks-risk-cell--center sparks-risk-cell-${value}` : 'sparks-risk-cell sparks-risk-cell--center' } },
    { id: 'impact', label: 'Impacto', minWidth: 125, maxWidth: 160, align: 'center', cellStyle: (row) => { const value = ordinalRiskValue(row.impact); return value ? `sparks-risk-cell sparks-risk-cell--center sparks-risk-cell-${value}` : 'sparks-risk-cell sparks-risk-cell--center' } },
    { id: 'inherent', label: 'Nível inerente', minWidth: 145, maxWidth: 180, align: 'center', cellStyle: (row) => { const band = riskScoreBand(numericRiskScore(row.inherent)); return band ? `sparks-risk-cell sparks-risk-cell--center sparks-risk-cell-${band}` : 'sparks-risk-cell sparks-risk-cell--center' } },
    { id: 'controls', label: 'Controles existentes', minWidth: 290, maxWidth: 500, tooltip: true, grow: 2 },
    { id: 'response', label: 'Resposta', minWidth: 140, maxWidth: 190 },
    { id: 'treatment', label: 'Plano de tratamento', minWidth: 350, maxWidth: 620, tooltip: true, grow: 2 },
    { id: 'owner', label: 'Responsável', minWidth: 190, maxWidth: 300, tooltip: true },
    { id: 'due', label: 'Prazo', minWidth: 130, maxWidth: 170, align: 'center' },
    { id: 'residual', label: 'Risco residual', minWidth: 145, maxWidth: 180, align: 'center' },
    { id: 'status', label: 'Status', minWidth: 180, maxWidth: 240, align: 'center' },
  ], [])

  return (
    <SparksSmartGrid
      rows={rows}
      columns={columns}
      ariaLabel="Riscos estratégicos detalhados"
      selectedId={selectedRiskId}
      onSelect={setSelectedRiskId}
      onDoubleClick={(id) => {
        const risk = rows.find((row) => row.id === id)
        if (risk) onOpenAssociatedInitiative?.(risk.code)
      }}
      viewportMode="standard"
      className="sparks-risk-grid"
    />
  )
}
