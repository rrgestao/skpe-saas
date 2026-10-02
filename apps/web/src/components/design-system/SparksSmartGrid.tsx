import { useEffect, useMemo, useRef, useState } from 'react'
import { ArrowUpDown, Filter, X } from 'lucide-react'
import {
  ContextMenu,
  Grid,
  Willow,
  type IColumnConfig,
} from '@svar-ui/react-grid'

import '@svar-ui/react-grid/all.css'
import './SparksSmartGrid.css'

export type SparksSmartGridRow = {
  id: string
  data?: SparksSmartGridRow[]
  open?: boolean
  [key: string]: unknown
}

export type SparksSmartGridColumn = {
  id: string
  label: string
  minWidth?: number
  maxWidth?: number
  width?: number
  align?: 'left' | 'center' | 'right'
  tooltip?: boolean
  sortable?: boolean
  resizable?: boolean
  filterable?: boolean
  cell?: any
  cellStyle?: (row: SparksSmartGridRow) => string
  semanticClass?: string
  filterValue?: (row: SparksSmartGridRow) => unknown
  widthValue?: (row: SparksSmartGridRow) => unknown
  grow?: number
  treeToggle?: boolean
}

export type SparksSmartGridContextAction = {
  id?: string
  text?: string
  icon?: string
  comp?: string
}

type Props = {
  rows: SparksSmartGridRow[]
  columns: SparksSmartGridColumn[]
  ariaLabel: string
  selectedId?: string | null
  selectedIds?: string[]
  multiselect?: boolean
  onSelectionChange?: (ids: string[]) => void
  onSelect?: (id: string) => void
  onDoubleClick?: (id: string) => void
  onActivate?: (id: string) => void
  primaryActionLabel?: string
  contextMenu?: SparksSmartGridContextAction[]
  onContextAction?: (actionId: string, rowId: string) => void
  tree?: boolean
  treeContextActions?: boolean
  fillViewport?: boolean
  autoRowHeight?: boolean
  className?: string
  emptyMessage?: string
  viewportMode?: 'standard' | 'balanced' | 'compact'
}

function normalize(value: unknown) {
  return String(value ?? '')
    .normalize('NFD')
    .replace(/\p{Diacritic}/gu, '')
    .toLocaleLowerCase('pt-BR')
    .trim()
}

function fittedColumnWidth(
  header: string,
  values: unknown[],
  minimum = 110,
  maximum = 460,
) {
  const longest = values.reduce<number>(
    (current, value) =>
      Math.max(current, String(value ?? '').trim().length),
    header.length,
  )

  const estimated = Math.ceil(longest * 7.4 + 56)
  return Math.max(minimum, Math.min(maximum, estimated))
}

function flattenGridRows(rows: SparksSmartGridRow[]) {
  const flattened: SparksSmartGridRow[] = []

  const visit = (items: SparksSmartGridRow[]) => {
    items.forEach((row) => {
      flattened.push(row)
      if (Array.isArray(row.data) && row.data.length > 0) {
        visit(row.data)
      }
    })
  }

  visit(rows)
  return flattened
}

function filterTreeRows(
  rows: SparksSmartGridRow[],
  matches: (row: SparksSmartGridRow) => boolean,
): SparksSmartGridRow[] {
  return rows.flatMap((row) => {
    const children = Array.isArray(row.data)
      ? filterTreeRows(row.data, matches)
      : []

    if (!matches(row) && children.length === 0) return []

    return [
      {
        ...row,
        ...(Array.isArray(row.data)
          ? {
              data: children,
              open: children.length > 0 ? true : row.open,
            }
          : {}),
      },
    ]
  })
}

function resolveGridRowId(event: any) {
  const raw =
    event?.id ??
    event?.row?.id ??
    event?.data?.id ??
    event?.item?.id ??
    null

  return raw === null || raw === undefined ? null : String(raw)
}

export function SparksSmartGrid({
  rows,
  columns,
  ariaLabel,
  selectedId = null,
  selectedIds = [],
  multiselect = false,
  onSelectionChange,
  onSelect,
  onDoubleClick,
  onActivate,
  primaryActionLabel = 'Abrir manutenção',
  contextMenu,
  onContextAction,
  tree = false,
  treeContextActions = false,
  fillViewport = true,
  autoRowHeight = false,
  className = '',
  emptyMessage = 'Nenhum registro disponível.',
  viewportMode = 'standard',
}: Props) {
  const [columnFilters, setColumnFilters] = useState<Record<string, string>>({})
  const [openColumnFilter, setOpenColumnFilter] = useState<string | null>(null)
  const [gridApi, setGridApi] = useState<any>(null)
  const contextRowIdRef = useRef<string | null>(null)
  const lastActivationRef = useRef<{ id: string; at: number } | null>(null)
  const lastSelectClickRef = useRef<{ id: string; at: number } | null>(null)
  const selectedRowRef = useRef<string | null>(selectedId ?? null)
  const gridShellRef = useRef<HTMLDivElement | null>(null)

  useEffect(() => {
    if (rows.length === 0) return
    const shell = gridShellRef.current
    if (!shell) return
    const handleDocumentDoubleClick = (event: MouseEvent) => {
      const target = event.target as HTMLElement | null
      if (!target || !shell.contains(target)) return
      if (target.closest('input, textarea, select, button, a, [contenteditable="true"], .wx-grip, [role="columnheader"]')) return
      const selected = selectedRowRef.current
      if (!selected) return
      event.preventDefault()
      event.stopPropagation()
      activateRow(String(selected))
    }
    document.addEventListener('dblclick', handleDocumentDoubleClick, true)
    return () => document.removeEventListener('dblclick', handleDocumentDoubleClick, true)
  }, [onActivate, onDoubleClick, rows.length])
  const [gridViewportWidth, setGridViewportWidth] = useState(0)
  const [sortState, setSortState] = useState<{
    columnId: string
    direction: 'asc' | 'desc'
  } | null>(null)
  const effectiveSelectedIds =
    selectedIds.length > 0
      ? selectedIds
      : selectedId
        ? [selectedId]
        : []
  useEffect(() => {
    selectedRowRef.current = selectedId ?? selectedIds[0] ?? null
  }, [selectedId, selectedIds])
  useEffect(() => {
    if (!fillViewport) return
    const shell = gridShellRef.current
    if (!shell) return
    const updateWidth = () => {
      const nextWidth = Math.floor(shell.clientWidth)
      setGridViewportWidth((current) =>
        current === nextWidth ? current : nextWidth,
      )
    }
    updateWidth()
    const observer = new ResizeObserver(updateWidth)
    observer.observe(shell)
    return () => observer.disconnect()
  }, [fillViewport])

  const allRows = useMemo(() => flattenGridRows(rows), [rows])

  const filteredRows = useMemo(() => {
    const activeFilters = Object.entries(columnFilters).filter(
      ([, value]) => value.trim(),
    )

    if (activeFilters.length === 0) return rows

    const matches = (row: SparksSmartGridRow) =>
      activeFilters.every(([id, value]) => {
        const definition = columns.find((column) => column.id === id)
        const candidate = definition?.filterValue
          ? definition.filterValue(row)
          : row[id]

        return normalize(candidate).includes(normalize(value))
      })

    return tree ? filterTreeRows(rows, matches) : rows.filter(matches)
  }, [columnFilters, columns, rows, tree])

  const activeFilterCount = useMemo(
    () => Object.values(columnFilters).filter((value) => value.trim()).length,
    [columnFilters],
  )

  const compareValues = (left: unknown, right: unknown) => {
    const leftText = String(left ?? '').trim()
    const rightText = String(right ?? '').trim()

    const leftNumber = Number(leftText.replace(',', '.'))
    const rightNumber = Number(rightText.replace(',', '.'))

    if (
      leftText !== '' &&
      rightText !== '' &&
      Number.isFinite(leftNumber) &&
      Number.isFinite(rightNumber)
    ) {
      return leftNumber - rightNumber
    }

    return leftText.localeCompare(rightText, 'pt-BR', {
      sensitivity: 'base',
      numeric: true,
    })
  }

  const sortRows = (
    items: SparksSmartGridRow[],
    columnId: string,
    direction: 'asc' | 'desc',
  ): SparksSmartGridRow[] => {
    const definition = columns.find((column) => column.id === columnId)
    const factor = direction === 'asc' ? 1 : -1

    return [...items]
      .sort((left, right) => {
        const leftValue = definition?.filterValue
          ? definition.filterValue(left)
          : left[columnId]
        const rightValue = definition?.filterValue
          ? definition.filterValue(right)
          : right[columnId]

        return compareValues(leftValue, rightValue) * factor
      })
      .map((row) =>
        tree && Array.isArray(row.data)
          ? {
              ...row,
              data: sortRows(row.data, columnId, direction),
            }
          : row,
      )
  }

  const sortedRows = useMemo(
    () =>
      sortState
        ? sortRows(
            filteredRows,
            sortState.columnId,
            sortState.direction,
          )
        : filteredRows,
    [filteredRows, sortState, columns, tree],
  )

  const toggleSort = (columnId: string) => {
    const definition = columns.find((column) => column.id === columnId)
    if (definition?.sortable === false) return

    setSortState((current) => {
      if (!current || current.columnId !== columnId) {
        return { columnId, direction: 'asc' }
      }

      if (current.direction === 'asc') {
        return { columnId, direction: 'desc' }
      }

      return null
    })
  }

  function SmartHeaderCell({ column }: { column: any }) {
    const id = String(column?.id ?? '')
    const definition = columns.find((candidate) => candidate.id === id)
    const label = definition?.label ?? String(column?.header?.text ?? '')
    const filterable = definition?.filterable !== false
    const sortable = definition?.sortable !== false
    const value = columnFilters[id] ?? ''
    const open = openColumnFilter === id

    return (
      <div className="sparks-data-explorer-header-cell">
        {open && filterable ? (
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
              className="sparks-data-explorer-header-filter-clear"
              title={`Fechar filtro de ${label}`}
              aria-label={`Fechar filtro de ${label}`}
              onClickCapture={(event) => {
                event.stopPropagation()
                setOpenColumnFilter(null)
              }}
            >
              <X size={14} aria-hidden="true" />
            </button>
          </div>
        ) : (
          <>
            <button
              type="button"
              className="sparks-data-explorer-header-label"
              title={sortable ? `Classificar por ${label}` : undefined}
              aria-label={
                sortable
                  ? `Classificar por ${label}${
                      sortState?.columnId === id
                        ? sortState.direction === 'asc'
                          ? ', ordem crescente'
                          : ', ordem decrescente'
                        : ''
                    }`
                  : undefined
              }
              onClick={(event) => {
                event.stopPropagation()
                if (sortable) toggleSort(id)
              }}
            >
              <span>{label}</span>
              {sortable ? (
                <ArrowUpDown
                  size={13}
                  aria-hidden="true"
                  className={
                    sortState?.columnId === id
                      ? `sparks-data-explorer-header-sort-icon is-${sortState.direction}`
                      : 'sparks-data-explorer-header-sort-icon'
                  }
                />
              ) : null}
            </button>
            {filterable ? (
              <button
                type="button"
                title={`Filtrar ${label}`}
                aria-label={`Filtrar ${label}`}
                className={
                  value.trim()
                    ? 'sparks-data-explorer-header-filter-button sparks-data-explorer-header-filter-button--active'
                    : 'sparks-data-explorer-header-filter-button'
                }
                onClick={(event) => {
                  event.stopPropagation()
                  setOpenColumnFilter(id)
                }}
              >
                <Filter size={14} aria-hidden="true" />
              </button>
            ) : null}
          </>
        )}
      </div>
    )
  }

  const gridColumns = useMemo<IColumnConfig[]>(() => {
    const measured = columns.map((column) => {
      const semanticClass = [
        'sparks-data-explorer-header-main',
        column.align === 'center' ? 'sparks-smart-grid__header-center' : '',
        column.align === 'right' ? 'sparks-smart-grid__header-right' : '',
        column.semanticClass ?? '',
      ].filter(Boolean).join(' ')
      const cellClass = [
        column.align === 'center' ? 'sparks-smart-grid__cell-center' : '',
        column.align === 'right' ? 'sparks-smart-grid__cell-right' : '',
        column.semanticClass ?? '',
      ].filter(Boolean).join(' ')
      const minimum = column.minWidth ?? 110
      const maximum = column.maxWidth ?? 460
      const measuredWidth =
        column.width ??
        fittedColumnWidth(
          column.label,
          allRows.map((row) =>
            column.widthValue ? column.widthValue(row) : row[column.id],
          ),
          minimum,
          maximum,
        )
      return {
        column,
        semanticClass,
        cellClass,
        maximum,
        measuredWidth,
        grow: Math.max(0, column.grow ?? 1),
      }
    })

    const measuredTotal = measured.reduce(
      (total, item) => total + item.measuredWidth,
      0,
    )
    const availableWidth = Math.max(0, gridViewportWidth - 2)
    const extra =
      fillViewport && availableWidth > measuredTotal
        ? availableWidth - measuredTotal
        : 0
    const growTotal = measured.reduce(
      (total, item) =>
        total +
        (item.grow > 0 && item.measuredWidth < item.maximum
          ? item.grow
          : 0),
      0,
    )

    return measured.map(
      ({ column, semanticClass, cellClass, maximum, measuredWidth, grow }) => {
        const share =
          extra > 0 && growTotal > 0 && grow > 0
            ? (extra * grow) / growTotal
            : 0
        const width = Math.min(
          maximum,
          Math.round(measuredWidth + share),
        )
        return {
          id: column.id,
          header: {
            text: column.label,
            cell: SmartHeaderCell,
            css: semanticClass,
          },
          width,
          sort: column.sortable !== false,
          resize: column.resizable !== false,
          tooltip: column.tooltip ?? false,
          treetoggle: column.treeToggle ?? false,
          css: cellClass || undefined,
          cell: column.cell,
        } as IColumnConfig
      },
    )
  }, [
    allRows,
    columns,
    columnFilters,
    fillViewport,
    gridViewportWidth,
    openColumnFilter,
  ])

  function init(api: any) {
    setGridApi(api)

    api.on?.('select-row', (event: any) => {
      const id = resolveGridRowId(event)
      if (id) {
        selectedRowRef.current = id
        onSelect?.(id)
        const now = Date.now()
        const previous = lastSelectClickRef.current
        if (previous?.id === id && now - previous.at >= 80 && now - previous.at <= 500) {
          lastSelectClickRef.current = null
          activateRow(id)
        } else {
          lastSelectClickRef.current = { id, at: now }
        }
      }

      const nextSelection = Array.from(
        api.getState?.()?.selectedRows ?? [],
        (value) => String(value),
      )
      onSelectionChange?.(nextSelection)
    })

    api.on?.('open-editor', (event: any) => {
      const id = resolveGridRowId(event) ?? selectedRowRef.current
      if (id) activateRow(String(id))
    })
  }

  function activateRow(id: string) {
    const now = Date.now()
    const last = lastActivationRef.current
    if (last?.id === id && now - last.at < 250) return
    lastActivationRef.current = { id, at: now }
    ;(onActivate ?? onDoubleClick)?.(id)
  }

  function resolveContextMenuRow(id: unknown) {
    const rowId =
      id === null || id === undefined
        ? null
        : String(id)

    contextRowIdRef.current = rowId

    if (rowId && gridApi?.exec) {
      gridApi.exec('select-row', {
        id: rowId,
        mode: true,
      })
    }

    return id
  }

  function resolveContextRowId() {
    const contextual = contextRowIdRef.current
    if (contextual) return contextual

    const selected =
      gridApi?.getState?.()?.selectedRows?.[0] ??
      selectedId ??
      null

    return selected === null || selected === undefined
      ? null
      : String(selected)
  }

  const effectiveContextMenu = useMemo<
    SparksSmartGridContextAction[] | undefined
  >(() => {
    const primary = (onActivate ?? onDoubleClick)
      ? [{ id: '__primary__', text: primaryActionLabel }]
      : []
    const screenActions = contextMenu?.length ? [...contextMenu] : []
    const treeActions = tree && treeContextActions
      ? [
          { id: 'tree-open', text: 'Expandir este nó' },
          { id: 'tree-close', text: 'Recolher este nó' },
          { id: 'tree-open-nested', text: 'Expandir descendentes' },
          { id: 'tree-close-nested', text: 'Recolher descendentes' },
        ]
      : []
    const options = [
      ...primary,
      ...(primary.length && (treeActions.length || screenActions.length) ? [{ comp: 'separator' }] : []),
      ...treeActions,
      ...(treeActions.length && screenActions.length ? [{ comp: 'separator' }] : []),
      ...screenActions,
    ]
    return options.length ? options : undefined
  }, [contextMenu, onActivate, onDoubleClick, primaryActionLabel, tree, treeContextActions])

  function handleContextMenuAction(event: any) {
    const actionId = String(
      event?.action?.id ??
        event?.item?.id ??
        event?.id ??
        '',
    )
    const rowId = resolveContextRowId()
    if (!actionId || !rowId) return

    contextRowIdRef.current = rowId

    if (actionId === '__primary__') {
      activateRow(rowId)
      return
    }

    if (tree && gridApi?.exec) {
      if (actionId === 'tree-open') {
        gridApi.exec('open-row', { id: rowId })
        return
      }

      if (actionId === 'tree-close') {
        gridApi.exec('close-row', { id: rowId })
        return
      }

      if (actionId === 'tree-open-nested') {
        gridApi.exec('open-row', { id: rowId, nested: true })
        return
      }

      if (actionId === 'tree-close-nested') {
        gridApi.exec('close-row', { id: rowId, nested: true })
        return
      }
    }

    onContextAction?.(actionId, rowId)
  }

  const visibleRows = useMemo(() => flattenGridRows(sortedRows), [sortedRows])

  function selectAndRevealRow(id: string) {
    selectedRowRef.current = id
    onSelect?.(id)
    if (gridApi?.exec) gridApi.exec('select-row', { id, mode: true })
    window.requestAnimationFrame(() => {
      const shell = gridShellRef.current
      if (!shell) return
      const row = Array.from(shell.querySelectorAll<HTMLElement>('[data-id]')).find(
        (candidate) => candidate.getAttribute('data-id') === id,
      )
      row?.scrollIntoView({ block: 'nearest', inline: 'nearest' })
    })
  }

  function moveSelection(step: number) {
    if (visibleRows.length === 0) return
    const current = selectedRowRef.current ?? selectedId ?? null
    const currentIndex = current
      ? visibleRows.findIndex((row) => String(row.id) === String(current))
      : -1
    const start = currentIndex < 0 ? (step > 0 ? -1 : 0) : currentIndex
    const nextIndex = Math.max(0, Math.min(visibleRows.length - 1, start + step))
    selectAndRevealRow(String(visibleRows[nextIndex].id))
  }

  useEffect(() => {
    if (!selectedId || !gridApi) return
    window.requestAnimationFrame(() => {
      const shell = gridShellRef.current
      if (!shell) return
      const row = Array.from(shell.querySelectorAll<HTMLElement>('[data-id]')).find(
        (candidate) => candidate.getAttribute('data-id') === selectedId,
      )
      row?.scrollIntoView({ block: 'nearest', inline: 'nearest' })
    })
  }, [gridApi, selectedId, sortedRows])

  function scrollHorizontally(direction: -1 | 1) {
    const shell = gridShellRef.current
    if (!shell) return
    const candidates = [shell, ...Array.from(shell.querySelectorAll<HTMLElement>('*'))]
    const target = candidates
      .filter((candidate) => candidate.scrollWidth > candidate.clientWidth + 3)
      .sort((a, b) => (b.scrollWidth - b.clientWidth) - (a.scrollWidth - a.clientWidth))[0]
    if (!target) return
    target.scrollBy({
      left: direction * Math.max(180, Math.round(target.clientWidth * 0.65)),
      behavior: 'smooth',
    })
  }

  const grid = (
    <Grid
      data={sortedRows}
      columns={gridColumns}
      init={init}
      tree={tree}
      select
      selectedRows={effectiveSelectedIds}
      multiselect={multiselect}
      autoRowHeight={autoRowHeight}
      rowStyle={(row) =>
        effectiveSelectedIds.includes(String((row as SparksSmartGridRow).id))
          ? 'sparks-smart-grid__row-selected'
          : ''
      }
      cellStyle={(row, column) => {
        const definition = columns.find((candidate) => candidate.id === String(column?.id ?? ''))
        return [String(column?.css ?? ''), definition?.cellStyle?.(row as SparksSmartGridRow) ?? '']
          .filter(Boolean)
          .join(' ')
      }}
    />
  )

  return (
    <div className={`sparks-smart-grid-block ${className}`.trim()} data-sparks-grid-shell>
      {activeFilterCount > 0 ? (
        <div className="sparks-smart-grid__filter-summary">
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

      {rows.length === 0 ? (
        <div className="sparks-smart-grid__empty">{emptyMessage}</div>
      ) : (
        <div
          ref={gridShellRef}
          className={`sparks-smart-grid sparks-smart-grid--${viewportMode}`}
          role="region"
          aria-label={ariaLabel}
          tabIndex={0}
          onClickCapture={(event) => {
            if (!gridApi?.exec) return
            const target = event.target as HTMLElement
            if (target.closest('input, textarea, select, button, a, [contenteditable="true"], .wx-grip')) return

            const rowElement = target.closest('[data-id]')
            const rowId = rowElement?.getAttribute('data-id')
            if (rowId) selectAndRevealRow(rowId)
          }}
          onContextMenuCapture={(event) => {
            if (!gridApi?.exec) return
            const target = event.target as HTMLElement
            const rowElement = target.closest('[data-id]')
            const rowId = rowElement?.getAttribute('data-id')
            if (!rowId) return
            selectAndRevealRow(rowId)
          }}
          onMouseDownCapture={(event) => {
            const target = event.target as HTMLElement
            if (
              target.closest(
                'input, textarea, select, button, a, [contenteditable="true"]',
              )
            ) {
              return
            }

            event.currentTarget.focus({ preventScroll: true })
          }}
          onKeyDown={(event) => {
            const target = event.target as HTMLElement
            if (
              target.closest(
                'input, textarea, select, button, a, [contenteditable="true"]',
              )
            ) {
              return
            }

            if (event.key === 'Enter') {
              const selected = selectedRowRef.current ?? selectedId ?? null
              if (selected) {
                event.preventDefault()
                event.stopPropagation()
                activateRow(String(selected))
              }
              return
            }
            if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
              event.preventDefault()
              event.stopPropagation()
              moveSelection(event.key === 'ArrowDown' ? 1 : -1)
              return
            }
            if (event.key === 'ArrowLeft' || event.key === 'ArrowRight') {
              event.preventDefault()
              event.stopPropagation()
              scrollHorizontally(event.key === 'ArrowRight' ? 1 : -1)
              return
            }
            if (event.key === 'PageDown' || event.key === 'PageUp') {
              event.preventDefault()
              event.stopPropagation()
              const rowsPerPage = Math.max(1, Math.floor(event.currentTarget.clientHeight / 34) - 2)
              moveSelection(event.key === 'PageDown' ? rowsPerPage : -rowsPerPage)
              return
            }
          }}
        >
          <Willow>
            {effectiveContextMenu?.length ? (
              <ContextMenu
                api={gridApi}
                at="point"
                resolver={resolveContextMenuRow}
                options={effectiveContextMenu}
                onClick={handleContextMenuAction}
              >
                {grid}
              </ContextMenu>
            ) : (
              grid
            )}
          </Willow>
        </div>
      )}
    </div>
  )
}
