import { useCallback, useEffect, useMemo, useState } from 'react'
import {
  ArrowLeft,
  ArrowRight,
  SearchCheck,
  ShieldCheck,
} from 'lucide-react'

import {
  SparksSmartGrid,
  type SparksSmartGridColumn,
  type SparksSmartGridRow,
} from '../../components/design-system/SparksSmartGrid'
import { supabase } from '../../lib/supabase'
import './SparksMeasureDualSelector.css'

type CatalogReference = {
  reference_catalog_id: string
  catalog_code: string
  version_number: number
  name: string
  description: string | null
  formula_text: string | null
  unit: string | null
  polarity: string | null
  measurement_frequency: string | null
  indicator_category: string | null
  status: string | null
}

type OrganizationIndicator = {
  organization_indicator_id: string
  organization_id: string
  reference_catalog_id: string
  catalog_code: string
  version_number: number
  name: string
  description: string | null
  formula_text: string | null
  unit: string | null
  polarity: string | null
  measurement_frequency: string | null
  indicator_category: string | null
  status: string
  reference_adaptation_notes: string | null
  usage_count: number | string
  usage_summary: Record<string, unknown> | null
  updated_at: string
}

type Props = {
  organizationId: string
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
    other: 'Outros',
  }
  return labels[value ?? ''] ?? value ?? 'Não informada'
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
  return labels[value ?? ''] ?? value ?? 'Não informada'
}

function polarityLabel(value: string | null) {
  const labels: Record<string, string> = {
    higher_is_better: 'Maior é melhor',
    lower_is_better: 'Menor é melhor',
    target_is_better: 'Alvo é melhor',
    range_is_better: 'Faixa é melhor',
  }
  return labels[value ?? ''] ?? value ?? 'Não informada'
}

function statusLabel(value: string | null) {
  const labels: Record<string, string> = {
    active: 'Ativo',
    draft: 'Rascunho',
    inactive: 'Inativo',
    archived: 'Arquivado',
  }
  return labels[value ?? ''] ?? value ?? 'Não informado'
}

export function SparksMeasureDualSelector({ organizationId }: Props) {
  const [catalog, setCatalog] = useState<CatalogReference[]>([])
  const [organizationIndicators, setOrganizationIndicators] = useState<
    OrganizationIndicator[]
  >([])
  const [catalogSelection, setCatalogSelection] = useState<string[]>([])
  const [organizationSelection, setOrganizationSelection] = useState<string[]>([])
  const [loading, setLoading] = useState(true)
  const [changing, setChanging] = useState(false)
  const [message, setMessage] = useState<string | null>(null)

  const load = useCallback(async () => {
    setLoading(true)
    setMessage(null)

    const [catalogResult, organizationResult] = await Promise.all([
      supabase.rpc('get_sparks_measure_reference_catalog' as never, {
        target_organization_id: organizationId,
        target_source_module_code: 'SK-PE',
      } as never),
      supabase.rpc('get_sparks_measure_organization_indicators' as never, {
        target_organization_id: organizationId,
      } as never),
    ])

    if (catalogResult.error) {
      setMessage(catalogResult.error.message)
      setLoading(false)
      return
    }

    if (organizationResult.error) {
      setMessage(organizationResult.error.message)
      setLoading(false)
      return
    }

    setCatalog((catalogResult.data ?? []) as CatalogReference[])
    setOrganizationIndicators(
      (organizationResult.data ?? []) as OrganizationIndicator[],
    )
    setCatalogSelection([])
    setOrganizationSelection([])
    setLoading(false)
  }, [organizationId])

  useEffect(() => {
    void load()
  }, [load])

  const adoptedReferenceIds = useMemo(
    () =>
      new Set(
        organizationIndicators.map((indicator) => indicator.reference_catalog_id),
      ),
    [organizationIndicators],
  )

  const availableCatalog = useMemo(
    () =>
      catalog.filter(
        (reference) => !adoptedReferenceIds.has(reference.reference_catalog_id),
      ),
    [adoptedReferenceIds, catalog],
  )

  const catalogRows = useMemo<SparksSmartGridRow[]>(
    () =>
      availableCatalog.map((reference) => ({
        id: reference.reference_catalog_id,
        code: reference.catalog_code,
        name: reference.name,
        category: categoryLabel(reference.indicator_category),
        unit: reference.unit ?? 'Não informada',
        frequency: frequencyLabel(reference.measurement_frequency),
        polarity: polarityLabel(reference.polarity),
        status: statusLabel(reference.status),
      })),
    [availableCatalog],
  )

  const organizationRows = useMemo<SparksSmartGridRow[]>(
    () =>
      organizationIndicators.map((indicator) => ({
        id: indicator.reference_catalog_id,
        code: indicator.catalog_code,
        name: indicator.name,
        unit: indicator.unit ?? 'Não informada',
        frequency: frequencyLabel(indicator.measurement_frequency),
        status: statusLabel(indicator.status),
        usage: Number(indicator.usage_count ?? 0),
      })),
    [organizationIndicators],
  )

  const catalogColumns = useMemo<SparksSmartGridColumn[]>(
    () => [
      { id: 'code', label: 'Código', minWidth: 118 },
      { id: 'name', label: 'Indicador', minWidth: 270 },
      {
        id: 'category',
        label: 'Categoria',
        minWidth: 135,
        align: 'center',
      },
      { id: 'unit', label: 'Unidade', minWidth: 110, align: 'center' },
      {
        id: 'frequency',
        label: 'Periodicidade',
        minWidth: 120,
        align: 'center',
      },
      {
        id: 'polarity',
        label: 'Polaridade',
        minWidth: 130,
        align: 'center',
      },
    ],
    [],
  )

  const organizationColumns = useMemo<SparksSmartGridColumn[]>(
    () => [
      { id: 'code', label: 'Código', minWidth: 118 },
      { id: 'name', label: 'Indicador', minWidth: 270 },
      { id: 'unit', label: 'Unidade', minWidth: 105, align: 'center' },
      {
        id: 'frequency',
        label: 'Periodicidade',
        minWidth: 120,
        align: 'center',
      },
      { id: 'status', label: 'Situação', minWidth: 108, align: 'center' },
      {
        id: 'usage',
        label: 'Em uso',
        minWidth: 80,
        align: 'center',
        tooltip: true,
      },
    ],
    [],
  )

  async function adoptReferences(referenceIds: string[]) {
    if (referenceIds.length === 0 || changing) return

    setChanging(true)
    setMessage(null)

    const result = await supabase.rpc(
      'adopt_sparks_measure_references_for_organization' as never,
      {
        target_organization_id: organizationId,
        target_reference_catalog_ids: referenceIds,
        target_change_reason:
          'Adoção realizada no painel de Indicadores da Organização.',
      } as never,
    )

    if (result.error) {
      setMessage(result.error.message)
      setChanging(false)
      return
    }

    await load()
    setChanging(false)
  }

  async function archiveReferences(referenceIds: string[]) {
    if (referenceIds.length === 0 || changing) return

    setChanging(true)
    setMessage(null)

    const result = await supabase.rpc(
      'archive_sparks_measure_reference_adoptions_for_organization' as never,
      {
        target_organization_id: organizationId,
        target_reference_catalog_ids: referenceIds,
        target_change_reason:
          'Retirada realizada no painel de Indicadores da Organização.',
      } as never,
    )

    if (result.error) {
      setMessage(result.error.message)
      setChanging(false)
      return
    }

    await load()
    setChanging(false)
  }
  async function adoptSelected() {
    await adoptReferences(catalogSelection)
  }

  async function archiveSelected() {
    await archiveReferences(organizationSelection)
  }

  return (
    <section
      className="sparks-measure-dual-selector"
      aria-label="Seleção de Indicadores da Organização"
    >
      <div className="sparks-measure-dual-selector__intro">
        <div>
          <span className="sparks-measure-dual-selector__eyebrow">
            Catálogo GERAL → Organização
          </span>
          <h2>Indicadores da Organização</h2>
          <p>
            Selecione no Catálogo GERAL os indicadores que a organização deseja
            administrar. Depois de adotados, eles podem ser contextualizados e
            vinculados aos Objetivos Estratégicos, OKRs, iniciativas e demais
            elementos de gestão.
          </p>
        </div>
      </div>

      {message ? (
        <div className="sparks-measure-dual-selector__message" role="status">
          {message}
        </div>
      ) : null}

      <div className="sparks-measure-dual-selector__layout">
        <article className="sparks-measure-dual-selector__pane">
          <header className="sparks-measure-dual-selector__pane-header">
            <div>
              <SearchCheck size={18} aria-hidden="true" />
              <div>
                <strong>Catálogo GERAL</strong>
                <span>{availableCatalog.length} disponíveis para adoção</span>
              </div>
            </div>
            <span className="sparks-measure-dual-selector__selection-count">
              {catalogSelection.length} selecionados
            </span>
          </header>

          <SparksSmartGrid
            rows={catalogRows}
            columns={catalogColumns}
            ariaLabel="Catálogo GERAL de indicadores disponíveis"
            selectedIds={catalogSelection}
            multiselect
            onSelectionChange={setCatalogSelection}
            onDoubleClick={(id) => {
              setCatalogSelection([id])
              void adoptReferences([id])
            }}
            viewportMode="balanced"
          />
        </article>

        <div
          className="sparks-measure-dual-selector__actions"
          aria-label="Ações de adoção"
        >
          <button
            type="button"
            className="sparks-measure-dual-selector__action sparks-measure-dual-selector__action--primary"
            disabled={catalogSelection.length === 0 || loading || changing}
            onClick={() => void adoptSelected()}
            title="Adotar selecionados"
          >
            <ArrowRight size={18} aria-hidden="true" />
            <span>Adotar</span>
          </button>

          <button
            type="button"
            className="sparks-measure-dual-selector__action"
            disabled={
              organizationSelection.length === 0 || loading || changing
            }
            onClick={() => void archiveSelected()}
            title="Retirar selecionados da organização"
          >
            <ArrowLeft size={18} aria-hidden="true" />
            <span>Retirar</span>
          </button>
        </div>

        <article className="sparks-measure-dual-selector__pane">
          <header className="sparks-measure-dual-selector__pane-header">
            <div>
              <ShieldCheck size={18} aria-hidden="true" />
              <div>
                <strong>Indicadores da Organização</strong>
                <span>{organizationIndicators.length} adotados</span>
              </div>
            </div>
            <span className="sparks-measure-dual-selector__selection-count">
              {organizationSelection.length} selecionados
            </span>
          </header>

          <SparksSmartGrid
            rows={organizationRows}
            columns={organizationColumns}
            ariaLabel="Indicadores adotados pela organização"
            selectedIds={organizationSelection}
            multiselect
            onSelectionChange={setOrganizationSelection}
            viewportMode="balanced"
          />
        </article>
      </div>

      <footer className="sparks-measure-dual-selector__footer">
        <span>
          Duplo clique no Catálogo adota o indicador. Ctrl/Cmd adiciona ou
          remove itens da seleção; Shift seleciona um intervalo.
        </span>
        <span>
          Indicadores em uso não podem ser retirados até que seus vínculos
          contextuais sejam tratados.
        </span>
      </footer>
    </section>
  )
}
