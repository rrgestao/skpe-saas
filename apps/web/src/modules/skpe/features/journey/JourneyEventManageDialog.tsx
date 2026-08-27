import { useEffect, useMemo, useState } from 'react'

import { supabase } from '../../../../lib/supabase'
import { translateBackendMessage } from '../../../../shared/i18n/ptBR'

import './JourneyEventManageDialog.css'

type ManagedJourneyEvent = {
  event_id: string
  journey_item_code: string
  journey_item_title: string
  event_type: string
  event_title: string
  event_description: string | null
  starts_at: string | null
  ends_at: string | null
  all_day: boolean
  timezone_name: string
  event_status: string
  priority: string
  location_text: string | null
  meeting_reference: string | null
  participant_count: number
  accepted_count: number
  attended_count: number
}

type JourneyEventManageDialogProps = {
  event: ManagedJourneyEvent
  onClose: () => void
  onChanged: () => void
}

type EventType =
  | 'meeting'
  | 'review'
  | 'assembly'
  | 'workshop'
  | 'presentation'
  | 'validation_session'
  | 'institutional_event'
  | 'other'

type EventPriority = 'low' | 'medium' | 'high' | 'critical'

type EventLifecycle =
  | 'draft'
  | 'scheduled'
  | 'in_progress'
  | 'completed'
  | 'cancelled'
  | 'archived'

const lifecycleTargets: Record<EventLifecycle, EventLifecycle[]> = {
  draft: ['scheduled', 'cancelled'],
  scheduled: ['in_progress', 'completed', 'cancelled'],
  in_progress: ['completed', 'cancelled'],
  completed: ['archived'],
  cancelled: ['archived'],
  archived: [],
}

const lifecycleLabels: Record<EventLifecycle, string> = {
  draft: 'Rascunho',
  scheduled: 'Agendado',
  in_progress: 'Em andamento',
  completed: 'Conclu\u00eddo',
  cancelled: 'Cancelado',
  archived: 'Arquivado',
}

function toLocalDateTime(value: string | null) {
  if (!value) return ''
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return ''

  const pad = (part: number) => String(part).padStart(2, '0')
  return [
    date.getFullYear(),
    '-',
    pad(date.getMonth() + 1),
    '-',
    pad(date.getDate()),
    'T',
    pad(date.getHours()),
    ':',
    pad(date.getMinutes()),
  ].join('')
}

function toIsoOrNull(value: string) {
  if (!value) return null
  const parsed = new Date(value)
  return Number.isNaN(parsed.getTime()) ? null : parsed.toISOString()
}

export function JourneyEventManageDialog({
  event,
  onClose,
  onChanged,
}: JourneyEventManageDialogProps) {
  const status = event.event_status as EventLifecycle
  const canEditContent = !['completed', 'cancelled', 'archived'].includes(status)

  const [eventType, setEventType] = useState<EventType>(
    event.event_type as EventType,
  )
  const [title, setTitle] = useState(event.event_title)
  const [description, setDescription] = useState(event.event_description ?? '')
  const [startsAt, setStartsAt] = useState(toLocalDateTime(event.starts_at))
  const [endsAt, setEndsAt] = useState(toLocalDateTime(event.ends_at))
  const [priority, setPriority] = useState<EventPriority>(
    event.priority as EventPriority,
  )
  const [locationText, setLocationText] = useState(event.location_text ?? '')
  const [meetingReference, setMeetingReference] = useState(
    event.meeting_reference ?? '',
  )
  const [changeReason, setChangeReason] = useState('')
  const [targetStatus, setTargetStatus] = useState<EventLifecycle | ''>('')
  const [lifecycleReason, setLifecycleReason] = useState('')
  const [saving, setSaving] = useState(false)
  const [transitioning, setTransitioning] = useState(false)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)

  const normalizedStart = useMemo(() => toIsoOrNull(startsAt), [startsAt])
  const normalizedEnd = useMemo(() => toIsoOrNull(endsAt), [endsAt])
  const allowedTargets = lifecycleTargets[status] ?? []

  useEffect(() => {
    function handleKeyDown(keyboardEvent: KeyboardEvent) {
      if (keyboardEvent.key === 'Escape' && !saving && !transitioning) onClose()
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [onClose, saving, transitioning])

  async function saveChanges() {
    const normalizedTitle = title.trim()
    const reason = changeReason.trim()

    if (!canEditContent) {
      setErrorMessage('Este evento n\u00e3o permite replanejamento de conte\u00fado.')
      return
    }

    if (!normalizedTitle) {
      setErrorMessage('Informe o t\u00edtulo do evento.')
      return
    }

    if (reason.length < 10) {
      setErrorMessage(
        'Informe uma justificativa de altera\u00e7\u00e3o com pelo menos 10 caracteres.',
      )
      return
    }

    if (startsAt && !normalizedStart) {
      setErrorMessage('Data/hora de in\u00edcio inv\u00e1lida.')
      return
    }

    if (endsAt && !normalizedEnd) {
      setErrorMessage('Data/hora de t\u00e9rmino inv\u00e1lida.')
      return
    }

    if (
      normalizedStart &&
      normalizedEnd &&
      normalizedEnd < normalizedStart
    ) {
      setErrorMessage('O t\u00e9rmino n\u00e3o pode ser anterior ao in\u00edcio.')
      return
    }

    setSaving(true)
    setErrorMessage(null)

    const { error } = await supabase.rpc('update_sparks_event', {
      target_event_id: event.event_id,
      target_event_type: eventType,
      target_title: normalizedTitle,
      target_description: description.trim() || null,
      target_starts_at: normalizedStart,
      target_ends_at: normalizedEnd,
      target_all_day: false,
      target_timezone_name: event.timezone_name,
      target_priority: priority,
      target_location_text: locationText.trim() || null,
      target_meeting_reference: meetingReference.trim() || null,
      change_reason: reason,
    })

    if (error) {
      setErrorMessage(translateBackendMessage(error.message))
      setSaving(false)
      return
    }

    onChanged()
  }

  async function transitionLifecycle() {
    const reason = lifecycleReason.trim()

    if (!targetStatus) {
      setErrorMessage('Selecione a nova situa\u00e7\u00e3o do evento.')
      return
    }

    if (reason.length < 10) {
      setErrorMessage(
        'Informe uma justificativa de lifecycle com pelo menos 10 caracteres.',
      )
      return
    }

    setTransitioning(true)
    setErrorMessage(null)

    const { error } = await supabase.rpc('transition_sparks_event_lifecycle', {
      target_event_id: event.event_id,
      target_status: targetStatus,
      change_reason: reason,
    })

    if (error) {
      setErrorMessage(translateBackendMessage(error.message))
      setTransitioning(false)
      return
    }

    onChanged()
  }

  return (
    <div
      className="skpe-journey-event-manage-backdrop"
      role="presentation"
      onMouseDown={(mouseEvent) => {
        if (
          mouseEvent.target === mouseEvent.currentTarget &&
          !saving &&
          !transitioning
        ) {
          onClose()
        }
      }}
    >
      <section
        className="skpe-journey-event-manage"
        role="dialog"
        aria-modal="true"
        aria-labelledby="skpe-journey-event-manage-title"
      >
        <header>
          <div>
            <span>Agenda transversal governada</span>
            <h3 id="skpe-journey-event-manage-title">Gerir evento da Jornada</h3>
            <p>
              {event.journey_item_code} - {event.journey_item_title}
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            disabled={saving || transitioning}
          >
            Fechar
          </button>
        </header>

        <div className="skpe-journey-event-manage-status">
          <div>
            <span>Situa\u00e7\u00e3o atual</span>
            <strong>{lifecycleLabels[status] ?? status}</strong>
          </div>
          <div>
            <span>Participantes</span>
            <strong>{event.participant_count}</strong>
            <small>
              {event.accepted_count} aceito(s) - {event.attended_count} presente(s)
            </small>
          </div>
          <div>
            <span>Timezone</span>
            <strong>{event.timezone_name}</strong>
          </div>
        </div>

        <div className="skpe-journey-event-manage-grid">
          <label className="is-wide">
            <span>T\u00edtulo *</span>
            <input
              value={title}
              onChange={(changeEvent) => setTitle(changeEvent.target.value)}
              disabled={!canEditContent || saving || transitioning}
            />
          </label>

          <label>
            <span>Tipo</span>
            <select
              value={eventType}
              onChange={(changeEvent) =>
                setEventType(changeEvent.target.value as EventType)
              }
              disabled={!canEditContent || saving || transitioning}
            >
              <option value="meeting">Reuni\u00e3o</option>
              <option value="review">Revis\u00e3o</option>
              <option value="assembly">Assembleia</option>
              <option value="workshop">Workshop</option>
              <option value="presentation">Apresenta\u00e7\u00e3o</option>
              <option value="validation_session">Sess\u00e3o de valida\u00e7\u00e3o</option>
              <option value="institutional_event">Evento institucional</option>
              <option value="other">Outro</option>
            </select>
          </label>

          <label>
            <span>Prioridade</span>
            <select
              value={priority}
              onChange={(changeEvent) =>
                setPriority(changeEvent.target.value as EventPriority)
              }
              disabled={!canEditContent || saving || transitioning}
            >
              <option value="low">Baixa</option>
              <option value="medium">M\u00e9dia</option>
              <option value="high">Alta</option>
              <option value="critical">Cr\u00edtica</option>
            </select>
          </label>

          <label>
            <span>In\u00edcio</span>
            <input
              type="datetime-local"
              value={startsAt}
              onChange={(changeEvent) => setStartsAt(changeEvent.target.value)}
              disabled={!canEditContent || saving || transitioning}
            />
          </label>

          <label>
            <span>T\u00e9rmino</span>
            <input
              type="datetime-local"
              value={endsAt}
              onChange={(changeEvent) => setEndsAt(changeEvent.target.value)}
              disabled={!canEditContent || saving || transitioning}
            />
          </label>

          <label>
            <span>Local</span>
            <input
              value={locationText}
              onChange={(changeEvent) =>
                setLocationText(changeEvent.target.value)
              }
              disabled={!canEditContent || saving || transitioning}
            />
          </label>

          <label>
            <span>Refer\u00eancia da reuni\u00e3o</span>
            <input
              value={meetingReference}
              onChange={(changeEvent) =>
                setMeetingReference(changeEvent.target.value)
              }
              disabled={!canEditContent || saving || transitioning}
            />
          </label>

          <label className="is-wide">
            <span>Descri\u00e7\u00e3o</span>
            <textarea
              rows={3}
              value={description}
              onChange={(changeEvent) =>
                setDescription(changeEvent.target.value)
              }
              disabled={!canEditContent || saving || transitioning}
            />
          </label>

          {canEditContent && (
            <label className="is-wide">
              <span>Justificativa da altera\u00e7\u00e3o *</span>
              <textarea
                rows={3}
                value={changeReason}
                onChange={(changeEvent) =>
                  setChangeReason(changeEvent.target.value)
                }
                disabled={saving || transitioning}
              />
            </label>
          )}
        </div>

        {canEditContent ? (
          <div className="skpe-journey-event-manage-save">
            <button
              type="button"
              className="is-primary"
              onClick={() => void saveChanges()}
              disabled={saving || transitioning}
            >
              {saving ? 'Salvando...' : 'Salvar altera\u00e7\u00f5es'}
            </button>
          </div>
        ) : (
          <div className="skpe-journey-event-manage-note">
            O conte\u00fado deste evento est\u00e1 encerrado para replanejamento.
            As transi\u00e7\u00f5es de lifecycle ainda permitidas aparecem abaixo.
          </div>
        )}

        <section className="skpe-journey-event-lifecycle">
          <header>
            <div>
              <span>Lifecycle governado</span>
              <strong>Mudar situa\u00e7\u00e3o</strong>
            </div>
          </header>

          {allowedTargets.length > 0 ? (
            <div className="skpe-journey-event-lifecycle-grid">
              <label>
                <span>Nova situa\u00e7\u00e3o *</span>
                <select
                  value={targetStatus}
                  onChange={(changeEvent) =>
                    setTargetStatus(
                      changeEvent.target.value as EventLifecycle | '',
                    )
                  }
                  disabled={saving || transitioning}
                >
                  <option value="">Selecione</option>
                  {allowedTargets.map((candidate) => (
                    <option key={candidate} value={candidate}>
                      {lifecycleLabels[candidate]}
                    </option>
                  ))}
                </select>
              </label>

              <label className="is-wide">
                <span>Justificativa do lifecycle *</span>
                <textarea
                  rows={3}
                  value={lifecycleReason}
                  onChange={(changeEvent) =>
                    setLifecycleReason(changeEvent.target.value)
                  }
                  disabled={saving || transitioning}
                />
              </label>

              <button
                type="button"
                className="is-primary"
                onClick={() => void transitionLifecycle()}
                disabled={saving || transitioning}
              >
                {transitioning ? 'Atualizando...' : 'Aplicar nova situa\u00e7\u00e3o'}
              </button>
            </div>
          ) : (
            <p className="skpe-journey-event-manage-note">
              N\u00e3o h\u00e1 nova transi\u00e7\u00e3o permitida para este evento.
            </p>
          )}
        </section>

        {errorMessage && (
          <div className="skpe-journey-event-manage-error" role="alert">
            {errorMessage}
          </div>
        )}
      </section>
    </div>
  )
}