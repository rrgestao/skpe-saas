import { useEffect, useMemo, useState } from 'react'

import { supabase } from '../../../../lib/supabase'
import { translateBackendMessage } from '../../../../shared/i18n/ptBR'

import './JourneyEventCreateDialog.css'

type JourneyEventCreateDialogProps = {
  organizationId: string
  itemId: string
  itemCode: string
  itemName: string
  timezoneName: string
  suggestedStartDate: string | null
  onClose: () => void
  onCreated: () => void
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

function toSuggestedLocalDateTime(dateOnly: string | null) {
  if (!dateOnly) return ''
  return `${dateOnly}T09:00`
}

function toIsoOrNull(value: string) {
  if (!value) return null
  const parsed = new Date(value)
  return Number.isNaN(parsed.getTime()) ? null : parsed.toISOString()
}

export function JourneyEventCreateDialog({
  organizationId,
  itemId,
  itemCode,
  itemName,
  timezoneName,
  suggestedStartDate,
  onClose,
  onCreated,
}: JourneyEventCreateDialogProps) {
  const [eventType, setEventType] = useState<EventType>('meeting')
  const [title, setTitle] = useState(`${itemCode} - ${itemName}`)
  const [description, setDescription] = useState('')
  const [startsAt, setStartsAt] = useState(
    toSuggestedLocalDateTime(suggestedStartDate),
  )
  const [endsAt, setEndsAt] = useState('')
  const [priority, setPriority] = useState<EventPriority>('medium')
  const [locationText, setLocationText] = useState('')
  const [meetingReference, setMeetingReference] = useState('')
  const [changeReason, setChangeReason] = useState('')
  const [saving, setSaving] = useState(false)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)

  const normalizedStart = useMemo(() => toIsoOrNull(startsAt), [startsAt])
  const normalizedEnd = useMemo(() => toIsoOrNull(endsAt), [endsAt])

  useEffect(() => {
    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === 'Escape' && !saving) onClose()
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [onClose, saving])

  async function handleSubmit() {
    const normalizedTitle = title.trim()
    const reason = changeReason.trim()

    if (!normalizedTitle) {
      setErrorMessage('Informe o t\u00edtulo do evento.')
      return
    }

    if (reason.length < 10) {
      setErrorMessage(
        'Informe uma justificativa com pelo menos 10 caracteres.',
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

    const { error } = await supabase.rpc('create_sparks_event', {
      target_organization_id: organizationId,
      target_event_type: eventType,
      target_title: normalizedTitle,
      target_description: description.trim() || null,
      target_starts_at: normalizedStart,
      target_ends_at: normalizedEnd,
      target_all_day: false,
      target_timezone_name: timezoneName,
      target_priority: priority,
      target_source_module_code: 'SK-PE',
      target_source_entity_type: 'skpe_journey_item',
      target_source_entity_id: itemId,
      target_location_text: locationText.trim() || null,
      target_meeting_reference: meetingReference.trim() || null,
      change_reason: reason,
    })

    if (error) {
      setErrorMessage(translateBackendMessage(error.message))
      setSaving(false)
      return
    }

    onCreated()
  }

  return (
    <div
      className="skpe-journey-event-dialog-backdrop"
      role="presentation"
      onMouseDown={(event) => {
        if (event.target === event.currentTarget && !saving) onClose()
      }}
    >
      <section
        className="skpe-journey-event-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="skpe-journey-event-dialog-title"
      >
        <header>
          <div>
            <span>Agenda transversal governada</span>
            <h3 id="skpe-journey-event-dialog-title">Novo evento da Jornada</h3>
            <p>
              {itemCode} - {itemName}
            </p>
          </div>
          <button type="button" onClick={onClose} disabled={saving}>
            Fechar
          </button>
        </header>

        <div className="skpe-journey-event-dialog-grid">
          <label className="is-wide">
            <span>T\u00edtulo *</span>
            <input
              value={title}
              onChange={(event) => setTitle(event.target.value)}
              disabled={saving}
            />
          </label>

          <label>
            <span>Tipo *</span>
            <select
              value={eventType}
              onChange={(event) => setEventType(event.target.value as EventType)}
              disabled={saving}
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
              onChange={(event) =>
                setPriority(event.target.value as EventPriority)
              }
              disabled={saving}
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
              onChange={(event) => setStartsAt(event.target.value)}
              disabled={saving}
            />
          </label>

          <label>
            <span>T\u00e9rmino</span>
            <input
              type="datetime-local"
              value={endsAt}
              onChange={(event) => setEndsAt(event.target.value)}
              disabled={saving}
            />
          </label>

          <label>
            <span>Local</span>
            <input
              value={locationText}
              onChange={(event) => setLocationText(event.target.value)}
              disabled={saving}
            />
          </label>

          <label>
            <span>Refer\u00eancia da reuni\u00e3o</span>
            <input
              value={meetingReference}
              onChange={(event) => setMeetingReference(event.target.value)}
              disabled={saving}
              placeholder="Link, sala, protocolo ou refer\u00eancia"
            />
          </label>

          <label className="is-wide">
            <span>Descri\u00e7\u00e3o</span>
            <textarea
              rows={3}
              value={description}
              onChange={(event) => setDescription(event.target.value)}
              disabled={saving}
            />
          </label>

          <label className="is-wide">
            <span>Justificativa para auditoria *</span>
            <textarea
              rows={3}
              value={changeReason}
              onChange={(event) => setChangeReason(event.target.value)}
              disabled={saving}
            />
          </label>
        </div>

        <div className="skpe-journey-event-dialog-note">
          O evento ser\u00e1 persistido em SPARKs Agenda e apenas vinculado a este
          item da Jornada. Timezone: {timezoneName}.
        </div>

        {errorMessage && (
          <div className="skpe-journey-event-dialog-error" role="alert">
            {errorMessage}
          </div>
        )}

        <footer>
          <button type="button" onClick={onClose} disabled={saving}>
            Cancelar
          </button>
          <button
            type="button"
            className="is-primary"
            onClick={() => void handleSubmit()}
            disabled={saving}
          >
            {saving ? 'Salvando...' : 'Criar evento'}
          </button>
        </footer>
      </section>
    </div>
  )
}