type WallDateTimeParts = {
  year: number
  month: number
  day: number
  hour: number
  minute: number
}

const wallDateTimePattern =
  /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})$/

function parseWallDateTime(value: string): WallDateTimeParts | null {
  const match = wallDateTimePattern.exec(value)
  if (!match) return null

  const parts: WallDateTimeParts = {
    year: Number(match[1]),
    month: Number(match[2]),
    day: Number(match[3]),
    hour: Number(match[4]),
    minute: Number(match[5]),
  }

  const validationDate = new Date(
    Date.UTC(
      parts.year,
      parts.month - 1,
      parts.day,
      parts.hour,
      parts.minute,
    ),
  )

  if (
    validationDate.getUTCFullYear() !== parts.year ||
    validationDate.getUTCMonth() !== parts.month - 1 ||
    validationDate.getUTCDate() !== parts.day ||
    validationDate.getUTCHours() !== parts.hour ||
    validationDate.getUTCMinutes() !== parts.minute
  ) {
    return null
  }

  return parts
}

function getZonedParts(date: Date, timeZone: string): WallDateTimeParts {
  const formatter = new Intl.DateTimeFormat('en-CA', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hourCycle: 'h23',
  })

  const values = Object.fromEntries(
    formatter
      .formatToParts(date)
      .filter((part) => part.type !== 'literal')
      .map((part) => [part.type, part.value]),
  )

  return {
    year: Number(values.year),
    month: Number(values.month),
    day: Number(values.day),
    hour: Number(values.hour),
    minute: Number(values.minute),
  }
}

function getOffsetMilliseconds(date: Date, timeZone: string) {
  const parts = getZonedParts(date, timeZone)
  const wallAsUtc = Date.UTC(
    parts.year,
    parts.month - 1,
    parts.day,
    parts.hour,
    parts.minute,
  )
  const instantAtMinutePrecision =
    Math.floor(date.getTime() / 60_000) * 60_000

  return wallAsUtc - instantAtMinutePrecision
}

function sameWallDateTime(
  left: WallDateTimeParts,
  right: WallDateTimeParts,
) {
  return (
    left.year === right.year &&
    left.month === right.month &&
    left.day === right.day &&
    left.hour === right.hour &&
    left.minute === right.minute
  )
}

function pad(value: number) {
  return String(value).padStart(2, '0')
}

export function isValidTimeZone(timeZone: string) {
  if (!timeZone.trim()) return false

  try {
    new Intl.DateTimeFormat('en-US', { timeZone }).format(new Date())
    return true
  } catch {
    return false
  }
}

export function zonedLocalDateTimeToIso(
  value: string,
  timeZone: string,
): string | null {
  if (!value) return null
  if (!isValidTimeZone(timeZone)) return null

  const requested = parseWallDateTime(value)
  if (!requested) return null

  const wallAsUtc = Date.UTC(
    requested.year,
    requested.month - 1,
    requested.day,
    requested.hour,
    requested.minute,
  )

  let candidateMilliseconds = wallAsUtc

  for (let attempt = 0; attempt < 4; attempt += 1) {
    const candidate = new Date(candidateMilliseconds)
    const offset = getOffsetMilliseconds(candidate, timeZone)
    const nextCandidateMilliseconds = wallAsUtc - offset

    if (nextCandidateMilliseconds === candidateMilliseconds) break
    candidateMilliseconds = nextCandidateMilliseconds
  }

  const candidate = new Date(candidateMilliseconds)

  if (!sameWallDateTime(getZonedParts(candidate, timeZone), requested)) {
    return null
  }

  return candidate.toISOString()
}

export function isoToZonedLocalDateTime(
  value: string | null,
  timeZone: string,
) {
  if (!value || !isValidTimeZone(timeZone)) return ''

  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return ''

  const parts = getZonedParts(date, timeZone)

  return [
    parts.year,
    '-',
    pad(parts.month),
    '-',
    pad(parts.day),
    'T',
    pad(parts.hour),
    ':',
    pad(parts.minute),
  ].join('')
}