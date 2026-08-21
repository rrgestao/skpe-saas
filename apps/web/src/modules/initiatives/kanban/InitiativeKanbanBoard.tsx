import {
  useEffect,
  useState,
} from 'react'

import type {
  InitiativeKanbanColumnModel,
} from '../contracts/initiativeActions'
import {
  loadInitiativeActionBoard,
} from '../data/initiativeActionsData'
import { InitiativeKanbanColumn } from './InitiativeKanbanColumn'

import './InitiativeKanbanBoard.css'

type InitiativeKanbanBoardProps = {
  initiativeId: string
}

export function InitiativeKanbanBoard({
  initiativeId,
}: InitiativeKanbanBoardProps) {
  const [columns, setColumns] = useState<
    InitiativeKanbanColumnModel[]
  >([])
  const [loading, setLoading] = useState(true)
  const [errorMessage, setErrorMessage] =
    useState<string | null>(null)

  useEffect(() => {
    let active = true

    async function loadBoard() {
      setLoading(true)
      setErrorMessage(null)

      try {
        const nextColumns =
          await loadInitiativeActionBoard(
            initiativeId,
          )

        if (!active) return

        setColumns(nextColumns)
      } catch (error) {
        if (!active) return

        setColumns([])
        setErrorMessage(
          error instanceof Error
            ? error.message
            : 'Não foi possível carregar o Kanban.',
        )
      } finally {
        if (active) {
          setLoading(false)
        }
      }
    }

    void loadBoard()

    return () => {
      active = false
    }
  }, [initiativeId])

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
    <div
      className="initiative-kanban-board"
      aria-label="Kanban de ações da iniciativa"
    >
      {columns.map((column) => (
        <InitiativeKanbanColumn
          key={column.status}
          column={column}
        />
      ))}
    </div>
  )
}