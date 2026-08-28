export type JourneyTemporalTimelineRow = {
  item_id: string
  parent_item_id: string | null
  item_type: string
  item_code: string
  item_name: string
  item_status: string
  item_progress: number
  display_order: number
  baseline_start_date: string | null
  baseline_end_date: string | null
  current_plan_start_date: string | null
  current_plan_end_date: string | null
  forecast_start_date: string | null
  forecast_end_date: string | null
  operational_expected_start_date: string | null
  operational_expected_end_date: string | null
  actual_start_date: string | null
  actual_end_date: string | null
  is_start_overdue: boolean
  days_start_overdue: number
  is_completion_overdue: boolean
  days_completion_overdue: number
  temporal_state: string
}

export type InitiativeTemporalTimelineRow = {
  entity_type: 'initiative' | 'action'
  entity_id: string
  initiative_id: string
  parent_action_id?: string | null
  code: string
  name: string
  lifecycle_status?: string
  priority?: string
  baseline_start_date: string | null
  baseline_end_date: string | null
  current_plan_start_date: string | null
  current_plan_end_date: string | null
  forecast_start_date: string | null
  forecast_end_date: string | null
  actual_start_date: string | null
  actual_end_date: string | null
  is_start_overdue: boolean
  days_start_overdue: number
  is_completion_overdue: boolean
  days_completion_overdue: number
  temporal_state?: string
  temporal_data_quality_state: string
}

export type JourneyEventTimelineRow = {
  event_id: string
  journey_item_id: string
  journey_item_code: string
  journey_item_title: string
  journey_item_type: string
  event_type: string
  event_title: string
  starts_at: string | null
  ends_at: string | null
  all_day: boolean
  timezone_name: string
  event_status: string
  priority: string
}

export type MonitoringTimelineWindow = {
  startDate: string
  endDate: string
  totalDays: number
  referencePosition: number | null
}

export type MonitoringTimelineSegment = {
  left: number
  width: number
}

function toDateOnly(value: string | null | undefined) {
  if (!value) return null

  const match = value.match(/^(\d{4})-(\d{2})-(\d{2})/)
  if (!match) return null

  const [, year, month, day] = match
  return `${year}-${month}-${day}`
}

function toUtcDay(value: string | null | undefined) {
  const dateOnly = toDateOnly(value)
  if (!dateOnly) return null

  const [year, month, day] = dateOnly
    .split('-')
    .map(Number)

  const result = Date.UTC(year, month - 1, day)

  if (!Number.isFinite(result)) return null
  return result
}

function dayDifference(
  first: string,
  second: string,
) {
  const firstDay = toUtcDay(first)
  const secondDay = toUtcDay(second)

  if (firstDay === null || secondDay === null) {
    return null
  }

  return Math.round(
    (secondDay - firstDay) / 86_400_000,
  )
}

function collectDate(
  target: string[],
  value: string | null | undefined,
) {
  const date = toDateOnly(value)
  if (date) target.push(date)
}

export function deriveMonitoringTimelineWindow(
  journeyRows: JourneyTemporalTimelineRow[],
  initiativeRows: InitiativeTemporalTimelineRow[],
  events: JourneyEventTimelineRow[],
  referenceDate?: string | null,
): MonitoringTimelineWindow | null {
  const dates: string[] = []

  for (const row of journeyRows) {
    collectDate(dates, row.baseline_start_date)
    collectDate(dates, row.baseline_end_date)
    collectDate(dates, row.current_plan_start_date)
    collectDate(dates, row.current_plan_end_date)
    collectDate(dates, row.forecast_start_date)
    collectDate(dates, row.forecast_end_date)
    collectDate(dates, row.actual_start_date)
    collectDate(dates, row.actual_end_date)
  }

  for (const row of initiativeRows) {
    collectDate(dates, row.baseline_start_date)
    collectDate(dates, row.baseline_end_date)
    collectDate(dates, row.current_plan_start_date)
    collectDate(dates, row.current_plan_end_date)
    collectDate(dates, row.forecast_start_date)
    collectDate(dates, row.forecast_end_date)
    collectDate(dates, row.actual_start_date)
    collectDate(dates, row.actual_end_date)
  }

  for (const event of events) {
    collectDate(dates, event.starts_at)
    collectDate(dates, event.ends_at)
  }

  if (dates.length === 0) {
    return null
  }

  dates.sort()

  const startDate = dates[0]
  const endDate = dates[dates.length - 1]
  const difference = dayDifference(
    startDate,
    endDate,
  )

  if (difference === null) {
    return null
  }

  const totalDays = Math.max(1, difference + 1)
  const reference = toDateOnly(referenceDate)

  let referencePosition: number | null = null

  if (reference) {
    const referenceOffset = dayDifference(
      startDate,
      reference,
    )

    if (
      referenceOffset !== null &&
      referenceOffset >= 0 &&
      referenceOffset < totalDays
    ) {
      referencePosition =
        ((referenceOffset + 0.5) / totalDays) * 100
    }
  }

  return {
    startDate,
    endDate,
    totalDays,
    referencePosition,
  }
}

export function getMonitoringTimelineSegment(
  startDate: string | null | undefined,
  endDate: string | null | undefined,
  window: MonitoringTimelineWindow,
): MonitoringTimelineSegment | null {
  const start = toDateOnly(startDate)
  const end = toDateOnly(endDate)

  if (!start || !end) return null

  const orderedStart =
    start <= end ? start : end
  const orderedEnd =
    start <= end ? end : start

  const startOffset =
    dayDifference(window.startDate, orderedStart)
  const endOffset =
    dayDifference(window.startDate, orderedEnd)

  if (
    startOffset === null ||
    endOffset === null ||
    endOffset < 0 ||
    startOffset >= window.totalDays
  ) {
    return null
  }

  const clippedStart = Math.max(0, startOffset)
  const clippedEnd = Math.min(
    window.totalDays - 1,
    endOffset,
  )

  const left =
    (clippedStart / window.totalDays) * 100
  const width =
    ((clippedEnd - clippedStart + 1) /
      window.totalDays) *
    100

  return {
    left,
    width,
  }
}

export function getMonitoringTimelinePoint(
  value: string | null | undefined,
  window: MonitoringTimelineWindow,
) {
  const date = toDateOnly(value)
  if (!date) return null

  const offset =
    dayDifference(window.startDate, date)

  if (
    offset === null ||
    offset < 0 ||
    offset >= window.totalDays
  ) {
    return null
  }

  return ((offset + 0.5) / window.totalDays) * 100
}

export function getJourneyTimelineDepth(
  rows: JourneyTemporalTimelineRow[],
  itemId: string,
) {
  const byId = new Map(
    rows.map((row) => [row.item_id, row]),
  )

  let depth = 0
  let current = byId.get(itemId)
  const visited = new Set<string>()

  while (
    current?.parent_item_id &&
    depth < 8 &&
    !visited.has(current.item_id)
  ) {
    visited.add(current.item_id)
    const parent =
      byId.get(current.parent_item_id)

    if (!parent) break

    depth += 1
    current = parent
  }

  return depth
}

export function formatMonitoringTimelineDate(
  value: string | null | undefined,
) {
  const date = toDateOnly(value)
  if (!date) return '—'

  const [year, month, day] =
    date.split('-')

  return `${day}/${month}/${year}`
}