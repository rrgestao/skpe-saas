import { useMemo } from 'react'

import {
  SparksSmartGrid,
  type SparksSmartGridColumn,
  type SparksSmartGridContextAction,
} from '../../components/design-system/SparksSmartGrid'

export type CatalogReferenceGridItem = {
  reference_catalog_id: string
  catalog_code: string
  version_number: number
  name: string
  description: string | null
  purpose: string | null
  formula_text: string | null
  unit: string | null
  polarity: string | null
  measurement_frequency: string | null
  indicator_category: string | null
  status: string | null
  is_current: boolean
  benchmarks: unknown
}

type Props = {
  catalog: CatalogReferenceGridItem[]
  selectedReferenceId: string
  onSelect: (referenceId: string) => void
  onOpenAdoption: (referenceId: string) => void
}

type GridRow = {
  [key: string]: string | number
  id: string
  code: string
  name: string
  category: string
  unit: string
  frequency: string
  polarity: string
  status: string
  benchmarks: number
  version: string
}

function display(value: string | null | undefined, fallback = 'Não informado') {
  return value?.trim() ? value : fallback
}

function frequencyLabel(value: string | null) {
  const labels: Record<string, string> = {
    daily: 'Diária',
    weekly: 'Semanal',
    monthly: 'Mensal',
    bimonthly: 'Bimestral',
    quarterly: 'Trimestral',
    semiannual: 'Semestral',
    annual: 'Anual',
    on_demand: 'Sob demanda',
  }
  return value ? labels[value] ?? value : 'Não informada'
}

function categoryLabel(value: string | null) {
  const labels: Record<string, string> = {
    financial: 'Financeiro',
    customer_market: 'Clientes e mercado',
    internal_process: 'Processos internos',
    people_learning: 'Pessoas e aprendizado',
    governance: 'Governança',
    social: 'Social',
    environmental: 'Ambiental',
    sustainability: 'Sustentabilidade',
    other: 'Outro',
  }
  return value ? labels[value] ?? value : 'Não informada'
}

function polarityLabel(value: string | null) {
  const labels: Record<string, string> = {
    higher_is_better: 'Maior é melhor',
    lower_is_better: 'Menor é melhor',
    target_is_better: 'Alvo é melhor',
    range_is_better: 'Faixa é melhor',
  }
  return value ? labels[value] ?? value : 'Não informada'
}

function statusLabel(value: string | null) {
  const labels: Record<string, string> = {
    draft: 'Rascunho',
    active: 'Ativo',
    inactive: 'Inativo',
    archived: 'Arquivado',
  }
  return value ? labels[value] ?? value : 'Não informada'
}

function benchmarkCount(value: unknown) {
  return Array.isArray(value) ? value.length : 0
}

export function MeasuresCatalogSmartGrid({
  catalog,
  selectedReferenceId,
  onSelect,
  onOpenAdoption,
}: Props) {

  const currentCatalog = useMemo(() => {
    const byCode = new Map<string, CatalogReferenceGridItem>()

    for (const item of catalog) {
      if (!item.is_current) continue
      const existing = byCode.get(item.catalog_code)
      if (!existing || item.version_number > existing.version_number) {
        byCode.set(item.catalog_code, item)
      }
    }

    return Array.from(byCode.values()).sort((a, b) =>
      a.catalog_code.localeCompare(b.catalog_code, 'pt-BR'),
    )
  }, [catalog])

  const rows = useMemo<GridRow[]>(
    () =>
      currentCatalog.map((item) => ({
        id: item.reference_catalog_id,
        code: item.catalog_code,
        name: item.name,
        category: categoryLabel(item.indicator_category),
        unit: display(item.unit, 'Não informada'),
        frequency: frequencyLabel(item.measurement_frequency),
        polarity: polarityLabel(item.polarity),
        status: statusLabel(item.status),
        benchmarks: benchmarkCount(item.benchmarks),
        version: `v${item.version_number}`,
      })),
    [currentCatalog],
  )

  const columns = useMemo<SparksSmartGridColumn[]>(
    () => [
      { id: 'code', label: 'Código', minWidth: 105 },
      { id: 'name', label: 'Referência', minWidth: 240 },
      {
        id: 'category',
        label: 'Categoria',
        minWidth: 140,
        align: 'center',
      },
      { id: 'unit', label: 'Unidade', minWidth: 120, align: 'center' },
      {
        id: 'frequency',
        label: 'Periodicidade',
        minWidth: 135,
        align: 'center',
      },
      {
        id: 'polarity',
        label: 'Polaridade',
        minWidth: 140,
        align: 'center',
      },
      { id: 'status', label: 'Situação', minWidth: 115, align: 'center' },
      {
        id: 'benchmarks',
        label: 'Benchmarks',
        minWidth: 115,
        align: 'center',
      },
      { id: 'version', label: 'Versão', minWidth: 90, align: 'center' },
    ],
    [],
  )

  const menu: SparksSmartGridContextAction[] = [
    { id: 'select', text: 'Selecionar referência', icon: 'wxi-check' },
    { id: 'adopt', text: 'Abrir adoção', icon: 'wxi-plus' },
  ]

  return (
    <SparksSmartGrid
      rows={rows}
      columns={columns}
      ariaLabel="Catálogo GERAL disponível para adoção"
      viewportMode="balanced"
      selectedId={selectedReferenceId || null}
      onSelect={(id) => onSelect(id)}
      onDoubleClick={(id) => {
        onSelect(id)
        onOpenAdoption(id)
      }}
      contextMenu={menu}
      onContextAction={(action, id) => {
        if (action === 'select') {
          onSelect(id)
          return
        }

        if (action === 'adopt') {
          onSelect(id)
          onOpenAdoption(id)
        }
      }}
    />
  )

}
