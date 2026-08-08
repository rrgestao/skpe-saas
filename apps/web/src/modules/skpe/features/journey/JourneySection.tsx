import { useEffect, useMemo, useState, type ReactNode } from 'react'

import { supabase } from '../../../../lib/supabase'
import { statusLabelPtBr, translateBackendMessage } from '../../../../shared/i18n/ptBR'
import type { JourneyRow, JourneyStatus } from '../../contracts/journey'

type JourneyItem = JourneyRow & {
  children: JourneyItem[]
}

function ChevronDownIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path
        d="M6 9l6 6 6-6"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}


function CheckIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path
        d="M5 12l4 4L19 6"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}


function ClockIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <circle
        cx="12"
        cy="12"
        r="8"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
      />

      <path
        d="M12 8v5l3 2"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
        strokeLinecap="round"
      />
    </svg>
  )
}


function methodologyTextPtBr(value: string | null | undefined) {
  if (!value) return ''
  const exactLabels: Record<string, string> = {
    'Diagnostico e Entendimento Estrategico': 'Diagnóstico e Entendimento Estratégico',
    'Formulacao Estrategica': 'Formulação Estratégica',
    'Abertura da Formulacao Estrategica': 'Abertura da Formulação Estratégica',
    'Direcionadores Estrategicos': 'Direcionadores Estratégicos',
  }
  const exact = exactLabels[value.trim()]
  if (exact) return exact
  const replacements: Array<[RegExp, string]> = [
    [/\bDiagnostico\b/g, 'Diagnóstico'], [/\bFormulacao\b/g, 'Formulação'],
    [/\bEstrategico\b/g, 'Estratégico'], [/\bEstrategica\b/g, 'Estratégica'],
    [/\bProposito\b/g, 'Propósito'], [/\bMissao\b/g, 'Missão'], [/\bVisao\b/g, 'Visão'],
    [/\bValidacao\b/g, 'Validação'], [/\bOrganizacao\b/g, 'Organização'],
    [/\bAdministracao\b/g, 'Administração'], [/\bConfiguracao\b/g, 'Configuração'],
    [/\bInformacao\b/g, 'Informação'], [/\bGovernanca\b/g, 'Governança'],
    [/\bExecucao\b/g, 'Execução'], [/\bAvaliacao\b/g, 'Avaliação'], [/\bConcluida\b/g, 'Concluída'],
    [/\bcriterios\b/g, 'critérios'], [/\borganizacao\b/g, 'organização'],
    [/\bformulacao\b/g, 'formulação'], [/\bproposito\b/g, 'propósito'],
    [/\bmissao\b/g, 'missão'], [/\bvisao\b/g, 'visão'], [/\bprincipios\b/g, 'princípios'],
  ]
  return replacements.reduce((current, [pattern, replacement]) => current.replace(pattern, replacement), value)
}

function getStatusLabel(
  status: JourneyStatus,
) {
  const labels: Record<JourneyStatus, string> = {
    not_started: 'Não iniciada',
    in_progress: 'Em andamento',
    blocked: 'Bloqueada',
    pending_validation: 'Aguardando validação',
    completed: 'Concluída',
    cancelled: 'Cancelada',
  }

  return labels[status]
}


function getProjectStatusLabel(
  status: string,
) {
  const labels: Record<string, string> = {
    draft: 'Rascunho',
    active: 'Ativo',
    suspended: 'Suspenso',
    completed: 'Concluído',
    cancelled: 'Cancelado',
    archived: 'Arquivado',
  }

  return labels[status] ?? status
}


function getItemTypeLabel(
  itemType: JourneyRow['item_type'],
) {
  const labels: Record<
    JourneyRow['item_type'],
    string
  > = {
    macrophase: 'Macrofase',
    phase: 'Fase',
    stage: 'Etapa',
    activity: 'Atividade',
    deliverable: 'Entregável',
    gate: 'Gate de validação',
  }

  return labels[itemType]
}


function buildJourneyTree(
  rows: JourneyRow[],
): JourneyItem[] {
  const itemMap = new Map<
    string,
    JourneyItem
  >()

  for (const row of rows) {
    itemMap.set(row.item_id, {
      ...row,
      children: [],
    })
  }

  const roots: JourneyItem[] = []

  for (const item of itemMap.values()) {
    if (
      item.parent_item_id &&
      itemMap.has(item.parent_item_id)
    ) {
      itemMap
        .get(item.parent_item_id)
        ?.children.push(item)
    } else {
      roots.push(item)
    }
  }

  const sortItems = (
    items: JourneyItem[],
  ) => {
    items.sort(
      (firstItem, secondItem) =>
        firstItem.display_order -
        secondItem.display_order,
    )

    for (const item of items) {
      sortItems(item.children)
    }
  }

  sortItems(roots)

  return roots
}


function countJourneyDescendants(
  item: JourneyItem,
): number {
  return item.children.reduce(
    (total, child) =>
      total +
      1 +
      countJourneyDescendants(child),
    0,
  )
}


function buildJourneyBreadcrumb(
  rows: JourneyRow[],
  selectedItemId: string | null,
) {
  if (!selectedItemId) {
    return [] as JourneyRow[]
  }

  const rowMap = new Map(
    rows.map((row) => [row.item_id, row]),
  )

  const breadcrumb: JourneyRow[] = []
  let current = rowMap.get(selectedItemId)

  while (current) {
    breadcrumb.unshift(current)
    current = current.parent_item_id
      ? rowMap.get(current.parent_item_id)
      : undefined
  }

  return breadcrumb
}


function getJourneyStatusIcon(
  status: JourneyStatus,
  LockIcon: () => ReactNode,
) {
  if (status === 'completed') {
    return <CheckIcon />
  }

  if (
    status === 'in_progress' ||
    status === 'pending_validation'
  ) {
    return <ClockIcon />
  }

  return <LockIcon />
}



type JourneySectionProps = {
  organizationId: string
  formatDate: (value: string | null) => string
  RefreshIcon: () => ReactNode
  JourneyIcon: () => ReactNode
  LockIcon: () => ReactNode
  canManageJourney: boolean
  canGenerateDeliverables: boolean
  onGenerateDeliverables: (item: JourneyRow) => void
}

export function JourneySection({
  organizationId,
  formatDate,
  RefreshIcon,
  JourneyIcon,
  LockIcon,
  canManageJourney,
  canGenerateDeliverables,
  onGenerateDeliverables,
}: JourneySectionProps) {
  const [rows, setRows] =
    useState<JourneyRow[]>([])

  const [loading, setLoading] =
    useState(true)

  const [savingItemId, setSavingItemId] =
    useState<string | null>(null)

  const [errorMessage, setErrorMessage] =
    useState('')

  const [expandedItems, setExpandedItems] =
    useState<Set<string>>(new Set())

  const [selectedItemId, setSelectedItemId] =
    useState<string | null>(null)

  const journeyTree = useMemo(
    () => buildJourneyTree(rows),
    [rows],
  )

  const project = rows[0] ?? null


  const selectedItem = useMemo(
    () =>
      rows.find(
        (row) =>
          row.item_id === selectedItemId,
      ) ?? null,
    [rows, selectedItemId],
  )

  const selectedBreadcrumb = useMemo(
    () =>
      buildJourneyBreadcrumb(
        rows,
        selectedItemId,
      ),
    [rows, selectedItemId],
  )

  const loadJourney = async () => {
    setLoading(true)
    setErrorMessage('')

    const { data, error } = await supabase.rpc(
      'get_skpe_journey',
      {
        target_organization_id:
          organizationId,
      },
    )

    if (error) {
      setRows([])
      setErrorMessage(translateBackendMessage(error.message))
      setLoading(false)
      return
    }

    const journeyRows =
      (data ?? []) as JourneyRow[]

    setRows(journeyRows)

    setExpandedItems(
      new Set(
        journeyRows
          .filter(
            (row) =>
              row.item_type ===
                'macrophase' &&
              (row.is_current ||
                row.item_status ===
                  'in_progress'),
          )
          .map((row) => row.item_id),
      ),
    )

    setSelectedItemId((current) =>
      journeyRows.some(
        (row) => row.item_id === current,
      )
        ? current
        : journeyRows.find(
            (row) => row.is_current,
          )?.item_id ??
          journeyRows.find(
            (row) =>
              row.item_type ===
              'macrophase',
          )?.item_id ??
          null,
    )

    setLoading(false)
  }

  useEffect(() => {
    void loadJourney()
  }, [organizationId])

  const updateJourneyItem = async (
    item: JourneyItem,
    targetStatus: JourneyStatus,
    targetProgress: number,
  ) => {
    const actionLabel =
      targetStatus === 'completed'
        ? 'concluir'
        : targetStatus === 'in_progress'
          ? 'iniciar'
          : 'atualizar'

    const reason = window.prompt(
      `Informe a justificativa para ${actionLabel} "${item.item_name}".`,
    )

    if (!reason) {
      return
    }

    if (reason.trim().length < 10) {
      window.alert(
        'A justificativa deve ter pelo menos 10 caracteres.',
      )
      return
    }

    setSavingItemId(item.item_id)

    const { error } = await supabase.rpc(
      'set_skpe_journey_item_status',
      {
        target_item_id: item.item_id,
        target_status: targetStatus,
        target_progress: targetProgress,
        change_reason: reason.trim(),
      },
    )

    if (error) {
      window.alert(translateBackendMessage(error.message))
      setSavingItemId(null)
      return
    }

    await loadJourney()
    setSavingItemId(null)
  }

  const toggleExpanded = (
    itemId: string,
  ) => {
    setExpandedItems((current) => {
      const next = new Set(current)

      if (next.has(itemId)) {
        next.delete(itemId)
      } else {
        next.add(itemId)
      }

      return next
    })
  }

  const renderJourneyItem = (
    item: JourneyItem,
    level = 0,
  ) => {
    const hasChildren =
      item.children.length > 0

    const isExpanded =
      expandedItems.has(item.item_id)

    return (
      <article
        key={item.item_id}
        className={[
          'skpe-journey-tree-item',
          `skpe-journey-level-${Math.min(
            level,
            4,
          )}`,
          item.is_current
            ? 'skpe-phase-current'
            : '',
          selectedItemId === item.item_id
            ? 'skpe-journey-item-selected'
            : '',
          hasChildren
            ? 'skpe-journey-item-drillable'
            : '',
        ]
          .filter(Boolean)
          .join(' ')}
        onClick={() => {
          setSelectedItemId(item.item_id)

          if (hasChildren) {
            toggleExpanded(item.item_id)
          }
        }}
      >
        <div className="skpe-journey-item-main">
          <div
            className={`skpe-phase-marker skpe-phase-${item.item_status}`}
          >
            {getJourneyStatusIcon(
              item.item_status,
              LockIcon,
            )}
          </div>

          <div className="skpe-journey-item-content">
            <div className="skpe-phase-heading">
              <div>
                <p>
                  {getItemTypeLabel(
                    item.item_type,
                  )}{' '}
                  · {item.item_code}
                </p>

                <h2>{methodologyTextPtBr(item.item_name)}</h2>
              </div>

              <div className="skpe-journey-heading-actions">
                <span
                  className={`skpe-pill skpe-pill-${item.item_status}`}
                >
                  {getStatusLabel(
                    item.item_status,
                  )}
                </span>

                {hasChildren && (
                  <button
                    type="button"
                    className={[
                      'skpe-tree-toggle-button',
                      isExpanded
                        ? 'skpe-tree-toggle-expanded'
                        : '',
                    ]
                      .filter(Boolean)
                      .join(' ')}
                    onClick={(event) => {
                      event.stopPropagation()
                      setSelectedItemId(
                        item.item_id,
                      )
                      toggleExpanded(
                        item.item_id,
                      )
                    }}
                    aria-expanded={isExpanded}
                    title={
                      isExpanded
                        ? 'Recolher níveis subordinados'
                        : 'Abrir fases, etapas e atividades'
                    }
                  >
                    <span>
                      {countJourneyDescendants(
                        item,
                      )}{' '}
                      itens
                    </span>
                    <ChevronDownIcon />
                  </button>
                )}
              </div>
            </div>

            {item.item_description && (
              <p>{methodologyTextPtBr(item.item_description)}</p>
            )}

            <div className="skpe-journey-meta">
              {item.responsible_name && (
                <span>
                  Responsável:{' '}
                  <strong>
                    {item.responsible_name}
                  </strong>
                </span>
              )}

              {(item.planned_start_date ||
                item.planned_end_date) && (
                <span>
                  Período:{' '}
                  <strong>
                    {formatDate(
                      item.planned_start_date,
                    )}{' '}
                    a{' '}
                    {formatDate(
                      item.planned_end_date,
                    )}
                  </strong>
                </span>
              )}

              {item.validation_required && (
                <span>
                  Validação:{' '}
                  <strong>
                    {statusLabelPtBr(item.validation_status)}
                  </strong>
                </span>
              )}
            </div>

            {item.blocked &&
              item.blocking_reason && (
                <div className="skpe-journey-blocked-message">
                  {item.blocking_reason}
                </div>
              )}

            <div className="skpe-phase-progress">
              <div className="skpe-progress-track">
                <span
                  style={{
                    width: `${item.item_progress}%`,
                  }}
                />
              </div>

              <strong>
                {item.item_progress}%
              </strong>
            </div>

            {canManageJourney && (
              <div
                className="skpe-journey-quick-actions"
                onClick={(event) =>
                  event.stopPropagation()
                }
              >
                {item.item_status ===
                  'not_started' && (
                  <button
                    type="button"
                    onClick={() =>
                      void updateJourneyItem(
                        item,
                        'in_progress',
                        Math.max(
                          item.item_progress,
                          1,
                        ),
                      )
                    }
                    disabled={
                      savingItemId ===
                      item.item_id
                    }
                  >
                    Iniciar
                  </button>
                )}

                {item.item_status !==
                  'completed' && (
                  <button
                    type="button"
                    onClick={() =>
                      void updateJourneyItem(
                        item,
                        'completed',
                        100,
                      )
                    }
                    disabled={
                      savingItemId ===
                      item.item_id
                    }
                  >
                    Concluir
                  </button>
                )}

                {item.item_status ===
                  'completed' && (
                  <button
                    type="button"
                    onClick={() =>
                      void updateJourneyItem(
                        item,
                        'in_progress',
                        Math.min(
                          item.item_progress,
                          99,
                        ),
                      )
                    }
                    disabled={
                      savingItemId ===
                      item.item_id
                    }
                  >
                    Reabrir
                  </button>
                )}

                {level === 0 &&
                  canGenerateDeliverables && (
                  <button
                    type="button"
                    className="skpe-generate-deliverables-button"
                    onClick={() =>
                      onGenerateDeliverables(item)
                    }
                  >
                    Gerar entregáveis
                  </button>
                )}
              </div>
            )}
          </div>
        </div>

        {hasChildren && isExpanded && (
          <div className="skpe-journey-children">
            {item.children.map((child) =>
              renderJourneyItem(
                child,
                level + 1,
              ),
            )}
          </div>
        )}
      </article>
    )
  }

  return (
    <>
      <section className="skpe-page-heading skpe-administration-heading">
        <div>
          <p className="skpe-eyebrow">
            Metodologia de Planejamento Estratégico
          </p>

          <h1>Jornada Estratégica</h1>

          <p>
            Estrutura real do projeto, carregada
            do banco, com macrofases, fases,
            entregáveis e gates de validação.
          </p>
        </div>

        <button
          type="button"
          className="skpe-refresh-button"
          onClick={() => void loadJourney()}
          disabled={loading}
        >
          <RefreshIcon />
          Atualizar jornada
        </button>
      </section>

      {project && (
        <section className="skpe-project-context-card">
          <div>
            <span>Projeto estratégico</span>
            <strong>
              {project.project_name}
            </strong>
            <small>
              {project.project_code}
            </small>
          </div>

          <div>
            <span>Progresso geral</span>
            <strong>
              {project.project_progress}%
            </strong>
            <small>
              Situação: {getProjectStatusLabel(
                project.project_status,
              )}
            </small>
          </div>
        </section>
      )}

      {errorMessage && (
        <div className="skpe-admin-message skpe-admin-message-error">
          {errorMessage}
        </div>
      )}

      {loading ? (
        <section className="skpe-admin-state-card">
          <p>
            Carregando a Jornada Estratégica...
          </p>
        </section>
      ) : journeyTree.length === 0 ? (
        <section className="skpe-admin-state-card">
          <h2>
            Nenhuma jornada encontrada
          </h2>
          <p>
            Verifique se o projeto estratégico
            foi criado para esta organização.
          </p>
        </section>
      ) : (
        <div className="skpe-journey-workspace">
          <section className="skpe-journey-tree">
            {journeyTree.map((item) =>
              renderJourneyItem(item),
            )}
          </section>

          <aside className="skpe-journey-detail-panel">
            {selectedItem ? (
              <>
                <div className="skpe-journey-breadcrumb">
                  {selectedBreadcrumb.map(
                    (breadcrumbItem, index) => (
                      <span
                        key={
                          breadcrumbItem.item_id
                        }
                      >
                        {index > 0 && (
                          <b>›</b>
                        )}
                        {breadcrumbItem.item_code}
                      </span>
                    ),
                  )}
                </div>

                <p className="skpe-eyebrow">
                  {getItemTypeLabel(
                    selectedItem.item_type,
                  )}
                </p>

                <h2>{methodologyTextPtBr(selectedItem.item_name)}</h2>

                <p>
                  {selectedItem.item_description ??
                    'Não há descrição complementar cadastrada.'}
                </p>

                <dl className="skpe-journey-detail-list">
                  <div>
                    <dt>Situação</dt>
                    <dd>
                      {getStatusLabel(
                        selectedItem.item_status,
                      )}
                    </dd>
                  </div>

                  <div>
                    <dt>Progresso</dt>
                    <dd>
                      {selectedItem.item_progress}%
                    </dd>
                  </div>

                  <div>
                    <dt>Responsável</dt>
                    <dd>
                      {selectedItem.responsible_name ??
                        'Não definido'}
                    </dd>
                  </div>

                  <div>
                    <dt>Validação</dt>
                    <dd>
                      {selectedItem.validation_required
                        ? statusLabelPtBr(selectedItem.validation_status)
                        : 'Validação não obrigatória'}
                    </dd>
                  </div>
                </dl>

                {selectedItem.item_type ===
                  'macrophase' && (
                  <div className="skpe-journey-detail-hint">
                    Clique novamente no cartão ou no
                    ícone de expansão para navegar pelos
                    níveis subordinados.
                  </div>
                )}
              </>
            ) : (
              <div className="skpe-user-detail-empty">
                <JourneyIcon />
                <h2>Selecione um item</h2>
                <p>
                  Consulte seus detalhes e navegue pela
                  estrutura metodológica.
                </p>
              </div>
            )}
          </aside>
        </div>
      )}
    </>
  )
}
