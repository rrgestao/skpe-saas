import {
  useCallback,
  useEffect,
  useMemo,
  useState,
} from 'react'

import type {
  InitiativeKanbanCardModel,
  InitiativeKanbanStatus,
} from '../contracts/initiativeActions'
import {
  InitiativeActionDrawer,
} from './InitiativeActionDrawer'
import {
  InitiativeActionCreateDialog,
} from './InitiativeActionCreateDialog'
import {
  InitiativeClosedActionsPanel,
} from './InitiativeClosedActionsPanel'
import {
  InitiativeKanbanColumn,
} from './InitiativeKanbanColumn'
import {
  InitiativeLifecycleDialog,
} from './InitiativeLifecycleDialog'
import {
  loadInitiativeKanbanFilteredBoard,
  type InitiativeKanbanFilteredColumnModel,
} from './initiativeKanbanFilteredBoardData'

import './InitiativeKanbanBoard.css'
import './InitiativeKanbanFilters.css'

type InitiativeKanbanBoardProps = {
  initiativeId: string
  canManageInitiatives: boolean
  initialActionId?: string | null
}

type PendingTransition = {
  card: InitiativeKanbanCardModel
  targetStatus: InitiativeKanbanStatus
}

export function InitiativeKanbanBoard({
  initiativeId,
  canManageInitiatives,
  initialActionId = null,
}: InitiativeKanbanBoardProps) {
  const [columns, setColumns] = useState<
    InitiativeKanbanFilteredColumnModel[]
  >([])
  const [selectedAreaId, setSelectedAreaId] =
    useState('all')
  const [selectedPersonName, setSelectedPersonName] =
    useState('all')
  const [selectedCard, setSelectedCard] =
    useState<InitiativeKanbanCardModel | null>(
      null,
    )
  const [draggingCard, setDraggingCard] =
    useState<InitiativeKanbanCardModel | null>(
      null,
    )
  const [
    pendingTransition,
    setPendingTransition,
  ] = useState<PendingTransition | null>(null)

  const [loading, setLoading] = useState(true)
  const [showCreateDialog, setShowCreateDialog] =
    useState(false)
  const [errorMessage, setErrorMessage] =
    useState<string | null>(null)

  const allCards = useMemo(
    () => columns.flatMap((column) => column.cards),
    [columns],
  )

  const activeActionCount = allCards.length

  const areaOptions = useMemo(() => {
    const byId = new Map<string, string>()

    allCards.forEach((card) => {
      if (
        card.responsibleAreaId &&
        card.responsibleAreaName
      ) {
        byId.set(
          card.responsibleAreaId,
          card.responsibleAreaName,
        )
      }
    })

    return Array.from(byId.entries())
      .map(([id, name]) => ({ id, name }))
      .sort((first, second) =>
        first.name.localeCompare(second.name, 'pt-BR'),
      )
  }, [allCards])

  const personOptions = useMemo(
    () =>
      Array.from(
        new Set(
          allCards.flatMap(
            (card) => card.responsiblePersonNames,
          ),
        ),
      ).sort((first, second) =>
        first.localeCompare(second, 'pt-BR'),
      ),
    [allCards],
  )

  const filteredColumns = useMemo(
    () =>
      columns.map((column) => ({
        ...column,
        cards: column.cards.filter((card) => {
          const matchesArea =
            selectedAreaId === 'all' ||
            card.responsibleAreaId === selectedAreaId
          const matchesPerson =
            selectedPersonName === 'all' ||
            card.responsiblePersonNames.includes(
              selectedPersonName,
            )

          return matchesArea && matchesPerson
        }),
      })),
    [columns, selectedAreaId, selectedPersonName],
  )

  const filteredActionCount = useMemo(
    () =>
      filteredColumns.reduce(
        (total, column) => total + column.cards.length,
        0,
      ),
    [filteredColumns],
  )

  const hasActiveFilters =
    selectedAreaId !== 'all' ||
    selectedPersonName !== 'all'

  const loadBoard = useCallback(async () => {
    setLoading(true)
    setErrorMessage(null)

    try {
      const nextColumns =
        await loadInitiativeKanbanFilteredBoard(
          initiativeId,
        )

      setColumns(nextColumns)

      if (initialActionId) {
        const initialCard = nextColumns
          .flatMap((column) => column.cards)
          .find((card) => card.actionId === initialActionId)

        setSelectedCard(initialCard ?? null)
      }
    } catch (error) {
      setColumns([])
      setErrorMessage(
        error instanceof Error
          ? error.message
          : 'Não foi possível carregar o Kanban.',
      )
    } finally {
      setLoading(false)
    }
  }, [initiativeId, initialActionId])

  useEffect(() => {
    void loadBoard()
  }, [loadBoard])

  useEffect(() => {
    setSelectedCard(null)
    setDraggingCard(null)
    setPendingTransition(null)
    setShowCreateDialog(false)
    setSelectedAreaId('all')
    setSelectedPersonName('all')
  }, [initiativeId])

  async function handleActionChanged() {
    await loadBoard()
    setSelectedCard(null)
    setPendingTransition(null)
  }

  function requestTransition(
    card: InitiativeKanbanCardModel,
    targetStatus: InitiativeKanbanStatus,
  ) {
    setDraggingCard(null)
    setPendingTransition({
      card,
      targetStatus,
    })
  }

  function clearFilters() {
    setSelectedAreaId('all')
    setSelectedPersonName('all')
  }

  if (loading) {
    return (
      <div className="initiative-kanban-state">
        Carregando ações…
      </div>
    )
  }

  if (errorMessage) {
    return (
      <div
        className="initiative-kanban-state initiative-kanban-state--error"
        role="alert"
      >
        {errorMessage}
      </div>
    )
  }

  return (
    <>
      <section
        className="initiative-kanban-guide"
        aria-label="Como usar o quadro de ações"
      >
        <div className="initiative-kanban-guide__copy">
          <p className="initiative-kanban-guide__eyebrow">
            Gestão das ações
          </p>
          <h3>Do planejamento à execução, no mesmo registro</h3>
          <p>
            Cada cartão é uma ação real desta iniciativa. Abra para consultar
            ou editar detalhes e, quando permitido, mova o cartão para avançar
            seu ciclo de vida governado. O Kanban não cria uma cópia da ação.
          </p>
        </div>

        <div className="initiative-kanban-guide__actions">
          <span className="initiative-kanban-guide__count">
            <strong>{activeActionCount}</strong>
            {activeActionCount === 1
              ? ' ação no quadro'
              : ' ações no quadro'}
          </span>

          {canManageInitiatives ? (
            <button
              type="button"
              className="initiative-kanban-primary-action"
              onClick={() =>
                setShowCreateDialog(true)
              }
            >
              Criar ação
            </button>
          ) : null}
        </div>
      </section>

      {activeActionCount > 0 ? (
        <section
          className="initiative-kanban-filters"
          aria-label="Filtros do Kanban"
        >
          <label>
            <span>Área responsável</span>
            <select
              value={selectedAreaId}
              onChange={(event) =>
                setSelectedAreaId(event.target.value)
              }
            >
              <option value="all">Todas as áreas</option>
              {areaOptions.map((area) => (
                <option key={area.id} value={area.id}>
                  {area.name}
                </option>
              ))}
            </select>
          </label>

          <label>
            <span>Responsável</span>
            <select
              value={selectedPersonName}
              onChange={(event) =>
                setSelectedPersonName(event.target.value)
              }
            >
              <option value="all">Todas as pessoas</option>
              {personOptions.map((personName) => (
                <option key={personName} value={personName}>
                  {personName}
                </option>
              ))}
            </select>
          </label>

          <span className="initiative-kanban-filters__summary">
            {filteredActionCount === activeActionCount
              ? `${activeActionCount} no quadro`
              : `${filteredActionCount} de ${activeActionCount} visíveis`}
          </span>

          {hasActiveFilters ? (
            <button
              type="button"
              className="initiative-kanban-filters__clear"
              onClick={clearFilters}
            >
              Limpar filtros
            </button>
          ) : null}
        </section>
      ) : null}

      {activeActionCount === 0 ? (
        <section className="initiative-kanban-empty">
          <h3>Nenhuma ação ativa nesta iniciativa</h3>
          <p>
            O quadro ficará organizado por etapa de execução assim que a
            iniciativa possuir ações. A mesma ação poderá ser acompanhada e
            atualizada aqui sem duplicação de dados.
          </p>
          {canManageInitiatives ? (
            <button
              type="button"
              className="initiative-kanban-primary-action"
              onClick={() =>
                setShowCreateDialog(true)
              }
            >
              Criar primeira ação
            </button>
          ) : null}
        </section>
      ) : filteredActionCount === 0 ? (
        <section className="initiative-kanban-filter-empty">
          <h3>Nenhuma ação corresponde aos filtros</h3>
          <p>
            Ajuste a área ou o responsável para reencontrar as ações desta
            iniciativa.
          </p>
        </section>
      ) : (
        <div
          className="initiative-kanban-board"
          aria-label="Kanban de ações da iniciativa"
        >
          {filteredColumns.map((column) => (
            <InitiativeKanbanColumn
              key={column.status}
              column={column}
              canManageInitiatives={canManageInitiatives}
              draggingCard={draggingCard}
              onOpenCard={setSelectedCard}
              onDragStart={setDraggingCard}
              onDragEnd={() =>
                setDraggingCard(null)
              }
              onRequestTransition={requestTransition}
            />
          ))}
        </div>
      )}

      {selectedCard ? (
        <InitiativeActionDrawer
          card={selectedCard}
          canManageInitiatives={canManageInitiatives}
          onClose={() =>
            setSelectedCard(null)
          }
          onChanged={handleActionChanged}
        />
      ) : null}

      {pendingTransition ? (
        <InitiativeLifecycleDialog
          card={pendingTransition.card}
          canManageInitiatives={canManageInitiatives}
          requestedStatus={
            pendingTransition.targetStatus
          }
          onClose={() =>
            setPendingTransition(null)
          }
          onChanged={handleActionChanged}
        />
      ) : null}

      {showCreateDialog ? (
        <InitiativeActionCreateDialog
          initiativeId={initiativeId}
          onClose={() =>
            setShowCreateDialog(false)
          }
          onChanged={loadBoard}
        />
      ) : null}
      {canManageInitiatives ? (
        <InitiativeClosedActionsPanel
          initiativeId={initiativeId}
          onChanged={loadBoard}
        />
      ) : null}
    </>
  )
}
