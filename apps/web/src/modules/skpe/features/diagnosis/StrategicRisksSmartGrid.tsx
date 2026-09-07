import { useMemo, useState } from 'react'
import { Filter, X } from 'lucide-react'
import { Grid, Willow, type IColumnConfig } from '@svar-ui/react-grid'

import '@svar-ui/react-grid/all.css'
import { SparksGridNavigator } from '../../../../components/design-system/SparksGridNavigator'
import '../../components/OrganizationUsersSmartGrid.css'

import type { ImportedDiagnosisRecord } from './strategicDiagnosisImportLoader.ts'

type StrategicRisksSmartGridProps = {
  records: ImportedDiagnosisRecord[]
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

const headerLabels: Record<string, string> = {
  code: 'Código',
  event: 'Evento de risco',
  category: 'Categoria',
  cause: 'Causa',
  consequence: 'Consequência',
  probability: 'Probabilidade',
  impact: 'Impacto',
  inherent: 'Nível inerente',
  controls: 'Controles existentes',
  response: 'Resposta',
  treatment: 'Plano de tratamento',
  owner: 'Responsável',
  due: 'Prazo',
  residual: 'Risco residual',
  status: 'Status',
}

const centeredIds = new Set(['code', 'probability', 'impact', 'inherent', 'residual', 'status'])

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
}: StrategicRisksSmartGridProps) {
  const [columnFilters, setColumnFilters] = useState<Record<string, string>>({})
  const [openColumnFilter, setOpenColumnFilter] = useState<string | null>(null)
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

  const data = useMemo(() => {
    const activeFilters = Object.entries(columnFilters).filter(([, value]) =>
      value.trim(),
    )
    if (activeFilters.length === 0) return rows

    return rows.filter((row) =>
      activeFilters.every(([id, value]) => {
        const record = row as unknown as Record<string, unknown>
        return normalize(record[id]).includes(normalize(value))
      }),
    )
  }, [rows, columnFilters])

  function RiskHeaderCell({ column }: { column: any }) {
    const id = String(column?.id ?? '')
    const label = headerLabels[id] ?? String(column?.header?.text ?? '')
    const value = columnFilters[id] ?? ''
    const open = openColumnFilter === id

    return (
      <div
        className={[
          'sparks-data-explorer-header-cell',
          centeredIds.has(id) ? 'sparks-data-explorer-header-cell--centered' : '',
        ]
          .filter(Boolean)
          .join(' ')}
      >
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
              onKeyDown={(event) => {
                if (event.key === 'Escape') setOpenColumnFilter(null)
              }}
            />
            <button
              type="button"
              className="sparks-data-explorer-header-filter-close"
              aria-label={`Fechar filtro de ${label}`}
              onClick={(event) => {
                event.stopPropagation()
                setOpenColumnFilter(null)
              }}
            >
              <X aria-hidden="true" size={14} />
            </button>
          </div>
        ) : (
          <>
            <span className="sparks-data-explorer-header-label">{label}</span>
            <button
              type="button"
              className={[
                'sparks-data-explorer-header-filter-trigger',
                value ? 'sparks-data-explorer-header-filter-trigger--active' : '',
              ]
                .filter(Boolean)
                .join(' ')}
              aria-label={`Filtrar ${label}`}
              title={`Filtrar ${label}`}
              onClick={(event) => {
                event.stopPropagation()
                setOpenColumnFilter(id)
              }}
            >
              <Filter aria-hidden="true" size={14} />
            </button>
          </>
        )}
      </div>
    )
  }

  function smartHeader(text: string) {
    return {
      text,
      cell: RiskHeaderCell,
      css: 'sparks-data-explorer-header-main',
    }
  }

  const columns: IColumnConfig[] = [
    { id: 'code', header: smartHeader('Código'), width: 110, sort: true, resize: true, tooltip: true },
    { id: 'event', header: smartHeader('Evento de risco'), width: 340, sort: true, resize: true, tooltip: true },
    { id: 'category', header: smartHeader('Categoria'), width: 160, sort: true, resize: true },
    { id: 'cause', header: smartHeader('Causa'), width: 270, sort: true, resize: true, tooltip: true },
    { id: 'consequence', header: smartHeader('Consequência'), width: 290, sort: true, resize: true, tooltip: true },
    { id: 'probability', header: smartHeader('Probabilidade'), width: 145, sort: true, resize: true },
    { id: 'impact', header: smartHeader('Impacto'), width: 125, sort: true, resize: true },
    { id: 'inherent', header: smartHeader('Nível inerente'), width: 145, sort: true, resize: true },
    { id: 'controls', header: smartHeader('Controles existentes'), width: 290, sort: true, resize: true, tooltip: true },
    { id: 'response', header: smartHeader('Resposta'), width: 140, sort: true, resize: true },
    { id: 'treatment', header: smartHeader('Plano de tratamento'), width: 350, sort: true, resize: true, tooltip: true },
    { id: 'owner', header: smartHeader('Responsável'), width: 190, sort: true, resize: true },
    { id: 'due', header: smartHeader('Prazo'), width: 130, sort: true, resize: true },
    { id: 'residual', header: smartHeader('Risco residual'), width: 145, sort: true, resize: true },
    { id: 'status', header: smartHeader('Status'), width: 180, sort: true, resize: true },
  ]

  function init(api: {
    on: (
      action: string,
      handler: (event: { id?: string | number }) => void,
    ) => void
  }) {
    api.on('select-row', (event) => {
      if (event.id === undefined || event.id === null) return
      setSelectedRiskId(String(event.id))
    })
  }

  function riskCellStyle(
    row: RiskGridRow,
    column: { id?: string },
  ): string {
    const id = String(column?.id ?? '')
    const classes: string[] = []

    if (centeredIds.has(id)) {
      classes.push('sparks-risk-cell', 'sparks-risk-cell--center')
    }

    if (id === 'probability') {
      const value = ordinalRiskValue(row.probability)
      if (value) classes.push(`sparks-risk-cell-${value}`)
    }

    if (id === 'impact') {
      const value = ordinalRiskValue(row.impact)
      if (value) classes.push(`sparks-risk-cell-${value}`)
    }

    if (id === 'inherent') {
      const score = numericRiskScore(row.inherent)
      const band = riskScoreBand(score)
      if (band) classes.push(`sparks-risk-cell-${band}`)
    }

    return classes.join(' ')
  }

  return (
    <div
      className="sparks-user-grid sparks-risk-grid"
      data-sparks-grid-shell
      role="region"
      aria-label="Riscos estratégicos detalhados"
    >
      <Willow>
        <Grid
          data={data}
          columns={columns}
          init={init}
          select
          selectedRows={selectedRiskId ? [selectedRiskId] : []}
          autoRowHeight
          cellStyle={riskCellStyle as any}
        />
      </Willow>
      <SparksGridNavigator />
    </div>
  )
}
