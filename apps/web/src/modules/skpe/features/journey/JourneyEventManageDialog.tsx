import { useEffect, useMemo, useState } from 'react'

import { supabase } from '../../../../lib/supabase'
import { translateBackendMessage } from '../../../../shared/i18n/ptBR'
import {
  isoToZonedLocalDateTime,
  isValidTimeZone,
  zonedLocalDateTimeToIso,
} from './journeyEventDateTime'

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
  onParticipantChanged: () => void
}

type EventParticipant = {
  participant_id: string
  person_id: string | null
  user_id: string | null
  participant_origin: 'internal' | 'external'
  user_email: string | null
  user_display_name: string
  external_organization: string | null
  relationship_type: string | null
  job_title: string | null
  participant_role: ParticipantRole
  participant_function: string | null
  response_status: string
  attendance_status: AttendanceStatus
  required: boolean
}

type EligibleEventUser = {
  user_id: string
  user_email: string
  user_display_name: string
  is_current_participant: boolean
}

type EligibleExternalPerson = {
  person_id: string
  display_name: string
  primary_email: string | null
  external_organization: string | null
  relationship_type: string | null
  job_title: string | null
  is_current_participant: boolean
}

type ParticipantManagementProjection = {
  event_id: string
  event_status: string
  organization_id: string
  source_module_code: string | null
  participants: EventParticipant[]
  eligible_users: EligibleEventUser[]
  eligible_external_people: EligibleExternalPerson[]
}

type ParticipantRole =
  | 'owner'
  | 'chair'
  | 'secretary'
  | 'responsible'
  | 'participant'
  | 'observer'

type AttendanceStatus = 'not_recorded' | 'attended' | 'absent'

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


export function JourneyEventManageDialog({
  event,
  onClose,
  onChanged,
  onParticipantChanged,
}: JourneyEventManageDialogProps) {
  const status = event.event_status as EventLifecycle
  const canEditContent = !['completed', 'cancelled', 'archived'].includes(status)

  const [eventType, setEventType] = useState<EventType>(
    event.event_type as EventType,
  )
  const [title, setTitle] = useState(event.event_title)
  const [description, setDescription] = useState(event.event_description ?? '')
  const [startsAt, setStartsAt] = useState(
    isoToZonedLocalDateTime(event.starts_at, event.timezone_name),
  )
  const [endsAt, setEndsAt] = useState(
    isoToZonedLocalDateTime(event.ends_at, event.timezone_name),
  )
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
  const [participantBusy, setParticipantBusy] = useState(false)
  const [participantLoading, setParticipantLoading] = useState(false)
  const [participantProjection, setParticipantProjection] =
    useState<ParticipantManagementProjection | null>(null)
  const [participantOrigin, setParticipantOrigin] =
    useState<'internal' | 'external'>('internal')
  const [participantUserId, setParticipantUserId] = useState('')
  const [externalPersonId, setExternalPersonId] = useState('')
  const [externalCreateNew, setExternalCreateNew] = useState(false)
  const [externalFullName, setExternalFullName] = useState('')
  const [externalPreferredName, setExternalPreferredName] = useState('')
  const [externalEmail, setExternalEmail] = useState('')
  const [externalOrganization, setExternalOrganization] = useState('')
  const [externalRelationshipType, setExternalRelationshipType] =
    useState('service_provider')
  const [externalJobTitle, setExternalJobTitle] = useState('')
  const [participantFunction, setParticipantFunction] = useState('')
  const [participantRole, setParticipantRole] =
    useState<ParticipantRole>('participant')
  const [participantRequired, setParticipantRequired] = useState(true)
  const [participantReason, setParticipantReason] = useState('')
  const [attendanceReasons, setAttendanceReasons] =
    useState<Record<string, string>>({})
  const [removeReasons, setRemoveReasons] =
    useState<Record<string, string>>({})
  const [errorMessage, setErrorMessage] = useState<string | null>(null)

  const normalizedStart = useMemo(
    () => zonedLocalDateTimeToIso(startsAt, event.timezone_name),
    [event.timezone_name, startsAt],
  )
  const normalizedEnd = useMemo(
    () => zonedLocalDateTimeToIso(endsAt, event.timezone_name),
    [endsAt, event.timezone_name],
  )
  const allowedTargets = lifecycleTargets[status] ?? []
  const eligibleUsers = participantProjection?.eligible_users ?? []
  const eligibleExternalPeople =
    participantProjection?.eligible_external_people ?? []
  const participants = participantProjection?.participants ?? []

  useEffect(() => {
    function handleKeyDown(keyboardEvent: KeyboardEvent) {
      if (
        keyboardEvent.key === 'Escape' &&
        !saving &&
        !transitioning &&
        !participantBusy
      ) {
        onClose()
      }
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [onClose, participantBusy, saving, transitioning])

  async function loadParticipantManagement() {
    setParticipantLoading(true)

    const { data, error } = await supabase.rpc(
      'get_sparks_event_participant_management',
      { target_event_id: event.event_id },
    )

    if (error) {
      setParticipantProjection(null)
      setErrorMessage(translateBackendMessage(error.message))
      setParticipantLoading(false)
      return
    }

    setParticipantProjection(
      (data ?? null) as ParticipantManagementProjection | null,
    )
    setParticipantLoading(false)
  }

  useEffect(() => {
    void loadParticipantManagement()
  }, [event.event_id])

  async function setParticipant() {
    const reason = participantReason.trim()

    if (!participantUserId) {
      setErrorMessage('Selecione um participante.')
      return
    }

    if (reason.length < 10) {
      setErrorMessage(
        'Informe uma justificativa de participante com pelo menos 10 caracteres.',
      )
      return
    }

    setParticipantBusy(true)
    setErrorMessage(null)

    const { error } = await supabase.rpc('set_sparks_event_participant', {
      target_event_id: event.event_id,
      target_user_id: participantUserId,
      target_participant_role: participantRole,
      target_required: participantRequired,
      change_reason: reason,
    })

    if (error) {
      setErrorMessage(translateBackendMessage(error.message))
      setParticipantBusy(false)
      return
    }

    setParticipantUserId('')
    resetParticipantContext()
    await loadParticipantManagement()
    onParticipantChanged()
    setParticipantBusy(false)
  }

  async function setExternalParticipant() {
    const reason = participantReason.trim()
    const selectedPersonId = externalCreateNew ? null : externalPersonId || null

    if (!externalCreateNew && !selectedPersonId) {
      setErrorMessage('Selecione uma pessoa externa existente ou cadastre uma nova.')
      return
    }

    if (externalCreateNew && !externalFullName.trim()) {
      setErrorMessage('Informe o nome completo da pessoa externa.')
      return
    }

    if (reason.length < 10) {
      setErrorMessage(
        'Informe uma justificativa de participante com pelo menos 10 caracteres.',
      )
      return
    }

    setParticipantBusy(true)
    setErrorMessage(null)

    const { error } = await supabase.rpc(
      'set_sparks_external_event_participant',
      {
        target_event_id: event.event_id,
        target_person_id: selectedPersonId,
        target_full_name: externalFullName.trim(),
        target_preferred_name: externalPreferredName.trim() || null,
        target_primary_email: externalEmail.trim() || null,
        target_external_organization: externalOrganization.trim() || null,
        target_relationship_type: externalRelationshipType,
        target_job_title: externalJobTitle.trim() || null,
        target_participant_role: participantRole,
        target_participant_function: participantFunction.trim() || null,
        target_required: participantRequired,
        change_reason: reason,
      },
    )

    if (error) {
      setErrorMessage(translateBackendMessage(error.message))
      setParticipantBusy(false)
      return
    }

    setExternalPersonId('')
    setExternalCreateNew(false)
    setExternalFullName('')
    setExternalPreferredName('')
    setExternalEmail('')
    setExternalOrganization('')
    setExternalRelationshipType('service_provider')
    setExternalJobTitle('')
    resetParticipantContext()
    await loadParticipantManagement()
    onParticipantChanged()
    setParticipantBusy(false)
  }

  function resetParticipantContext() {
    setParticipantRole('participant')
    setParticipantFunction('')
    setParticipantRequired(true)
    setParticipantReason('')
  }

  async function removeParticipant(participantId: string) {
    const reason = (removeReasons[participantId] ?? '').trim()

    if (reason.length < 10) {
      setErrorMessage(
        'Informe uma justificativa de remo\u00e7\u00e3o com pelo menos 10 caracteres.',
      )
      return
    }

    setParticipantBusy(true)
    setErrorMessage(null)

    const { error } = await supabase.rpc(
      'remove_sparks_event_participant_by_id',
      {
        target_event_id: event.event_id,
        target_participant_id: participantId,
        change_reason: reason,
      },
    )

    if (error) {
      setErrorMessage(translateBackendMessage(error.message))
      setParticipantBusy(false)
      return
    }

    setRemoveReasons((current) => ({ ...current, [participantId]: '' }))
    await loadParticipantManagement()
    onParticipantChanged()
    setParticipantBusy(false)
  }

  async function recordAttendance(
    participantId: string,
    attendanceStatus: AttendanceStatus,
  ) {
    const reason = (attendanceReasons[participantId] ?? '').trim()

    if (reason.length < 10) {
      setErrorMessage(
        'Informe uma justificativa de presen\u00e7a com pelo menos 10 caracteres.',
      )
      return
    }

    setParticipantBusy(true)
    setErrorMessage(null)

    const { error } = await supabase.rpc(
      'record_sparks_event_attendance_by_id',
      {
        target_event_id: event.event_id,
        target_participant_id: participantId,
        target_attendance_status: attendanceStatus,
        change_reason: reason,
      },
    )

    if (error) {
      setErrorMessage(translateBackendMessage(error.message))
      setParticipantBusy(false)
      return
    }

    setAttendanceReasons((current) => ({ ...current, [participantId]: '' }))
    await loadParticipantManagement()
    onParticipantChanged()
    setParticipantBusy(false)
  }
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

    if (!isValidTimeZone(event.timezone_name)) {
      setErrorMessage('O fuso hor\u00e1rio configurado para o evento \u00e9 inv\u00e1lido.')
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
          !transitioning &&
          !participantBusy
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
            disabled={saving || transitioning || participantBusy}
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
            <strong>
              {participantProjection
                ? participants.length
                : event.participant_count}
            </strong>
            <small>
              {event.accepted_count} aceito(s) - {
                participantProjection
                  ? participants.filter(
                      (participant) =>
                        participant.attendance_status === 'attended',
                    ).length
                  : event.attended_count
              } presente(s)
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

        <section className="skpe-journey-event-participants">
          <header>
            <div>
              <span>Participa\u00e7\u00e3o governada</span>
              <strong>Participantes e presen\u00e7a</strong>
            </div>
            <small>
              Pessoas internas e externas usam a mesma Agenda, sem exigir login
              para convidados externos.
            </small>
          </header>

          {participantLoading ? (
            <p className="skpe-journey-event-manage-note">
              Carregando participantes...
            </p>
          ) : (
            <>
              <div
                className="skpe-journey-event-participant-origin"
                role="group"
                aria-label="Tipo de participante"
              >
                <button
                  type="button"
                  className={participantOrigin === 'internal' ? 'is-active' : ''}
                  onClick={() => setParticipantOrigin('internal')}
                  disabled={participantBusy}
                >
                  Pessoa da organiza\u00e7\u00e3o
                </button>
                <button
                  type="button"
                  className={participantOrigin === 'external' ? 'is-active' : ''}
                  onClick={() => setParticipantOrigin('external')}
                  disabled={participantBusy}
                >
                  Pessoa externa
                </button>
              </div>

              <div className="skpe-journey-event-participant-add">
                {participantOrigin === 'internal' ? (
                  <label className="is-wide">
                    <span>Usu\u00e1rio da organiza\u00e7\u00e3o *</span>
                    <select
                      value={participantUserId}
                      onChange={(changeEvent) =>
                        setParticipantUserId(changeEvent.target.value)
                      }
                      disabled={participantBusy}
                    >
                      <option value="">Selecione</option>
                      {eligibleUsers.map((candidate) => (
                        <option key={candidate.user_id} value={candidate.user_id}>
                          {candidate.user_display_name} - {candidate.user_email}
                          {candidate.is_current_participant
                            ? ' - j\u00e1 participante'
                            : ''}
                        </option>
                      ))}
                    </select>
                  </label>
                ) : (
                  <>
                    <label className="is-wide">
                      <span>Pessoa externa conhecida</span>
                      <select
                        value={externalCreateNew ? '__new__' : externalPersonId}
                        onChange={(changeEvent) => {
                          const value = changeEvent.target.value
                          if (value === '__new__') {
                            setExternalCreateNew(true)
                            setExternalPersonId('')
                          } else {
                            setExternalCreateNew(false)
                            setExternalPersonId(value)
                          }
                        }}
                        disabled={participantBusy}
                      >
                        <option value="">Selecione</option>
                        {eligibleExternalPeople.map((candidate) => (
                          <option
                            key={candidate.person_id}
                            value={candidate.person_id}
                          >
                            {candidate.display_name}
                            {candidate.external_organization
                              ? ` - ${candidate.external_organization}`
                              : ''}
                            {candidate.is_current_participant
                              ? ' - j\u00e1 participante'
                              : ''}
                          </option>
                        ))}
                        <option value="__new__">
                          + Cadastrar nova pessoa externa
                        </option>
                      </select>
                    </label>

                    {externalCreateNew && (
                      <div className="skpe-journey-event-external-grid is-wide">
                        <label>
                          <span>Nome completo *</span>
                          <input
                            value={externalFullName}
                            onChange={(changeEvent) =>
                              setExternalFullName(changeEvent.target.value)
                            }
                            disabled={participantBusy}
                          />
                        </label>

                        <label>
                          <span>Nome preferido</span>
                          <input
                            value={externalPreferredName}
                            onChange={(changeEvent) =>
                              setExternalPreferredName(changeEvent.target.value)
                            }
                            disabled={participantBusy}
                          />
                        </label>

                        <label>
                          <span>E-mail</span>
                          <input
                            type="email"
                            value={externalEmail}
                            onChange={(changeEvent) =>
                              setExternalEmail(changeEvent.target.value)
                            }
                            disabled={participantBusy}
                          />
                        </label>

                        <label>
                          <span>Organiza\u00e7\u00e3o externa</span>
                          <input
                            value={externalOrganization}
                            onChange={(changeEvent) =>
                              setExternalOrganization(changeEvent.target.value)
                            }
                            disabled={participantBusy}
                          />
                        </label>

                        <label>
                          <span>Natureza da rela\u00e7\u00e3o</span>
                          <select
                            value={externalRelationshipType}
                            onChange={(changeEvent) =>
                              setExternalRelationshipType(
                                changeEvent.target.value,
                              )
                            }
                            disabled={participantBusy}
                          >
                            <option value="service_provider">
                              Prestador de servi\u00e7o
                            </option>
                            <option value="representative">Representante</option>
                            <option value="partner">Parceiro</option>
                            <option value="other">Outro</option>
                          </select>
                        </label>

                        <label>
                          <span>Cargo / atividade externa</span>
                          <input
                            value={externalJobTitle}
                            onChange={(changeEvent) =>
                              setExternalJobTitle(changeEvent.target.value)
                            }
                            disabled={participantBusy}
                          />
                        </label>
                      </div>
                    )}

                    <label className="is-wide">
                      <span>Fun\u00e7\u00e3o neste evento</span>
                      <input
                        value={participantFunction}
                        onChange={(changeEvent) =>
                          setParticipantFunction(changeEvent.target.value)
                        }
                        disabled={participantBusy}
                        placeholder="Ex.: Palestrante, facilitador, auditor"
                      />
                    </label>
                  </>
                )}

                <label>
                  <span>Papel de governan\u00e7a *</span>
                  <select
                    value={participantRole}
                    onChange={(changeEvent) =>
                      setParticipantRole(
                        changeEvent.target.value as ParticipantRole,
                      )
                    }
                    disabled={participantBusy}
                  >
                    <option value="owner">Respons\u00e1vel principal</option>
                    <option value="chair">Coordena\u00e7\u00e3o</option>
                    <option value="secretary">Secretaria</option>
                    <option value="responsible">Respons\u00e1vel</option>
                    <option value="participant">Participante</option>
                    <option value="observer">Observador</option>
                  </select>
                </label>

                <label className="is-checkbox">
                  <input
                    type="checkbox"
                    checked={participantRequired}
                    onChange={(changeEvent) =>
                      setParticipantRequired(changeEvent.target.checked)
                    }
                    disabled={participantBusy}
                  />
                  <span>Participa\u00e7\u00e3o obrigat\u00f3ria</span>
                </label>

                <label className="is-wide">
                  <span>Justificativa do v\u00ednculo/ajuste *</span>
                  <textarea
                    rows={2}
                    value={participantReason}
                    onChange={(changeEvent) =>
                      setParticipantReason(changeEvent.target.value)
                    }
                    disabled={participantBusy}
                  />
                </label>

                <button
                  type="button"
                  className="is-primary"
                  onClick={() =>
                    void (
                      participantOrigin === 'internal'
                        ? setParticipant()
                        : setExternalParticipant()
                    )
                  }
                  disabled={participantBusy}
                >
                  {participantBusy
                    ? 'Atualizando...'
                    : 'Adicionar / atualizar participante'}
                </button>
              </div>

              <div className="skpe-journey-event-participant-list">
                {participants.length === 0 ? (
                  <p className="skpe-journey-event-manage-note">
                    Nenhum participante registrado para este evento.
                  </p>
                ) : (
                  participants.map((participant) => (
                    <article
                      key={participant.participant_id}
                      className="skpe-journey-event-participant-card"
                    >
                      <header>
                        <div>
                          <strong>{participant.user_display_name}</strong>
                          {participant.user_email && (
                            <small>{participant.user_email}</small>
                          )}
                          {participant.participant_origin === 'external' && (
                            <small>
                              {[
                                participant.external_organization,
                                participant.job_title,
                                participant.participant_function,
                              ]
                                .filter(Boolean)
                                .join(' - ')}
                            </small>
                          )}
                        </div>
                        <div className="skpe-journey-event-participant-tags">
                          <span>
                            {participant.participant_origin === 'external'
                              ? 'Externo'
                              : 'Interno'}
                          </span>
                          <span>{participant.participant_role}</span>
                          {participant.participant_function && (
                            <span>{participant.participant_function}</span>
                          )}
                          <span>
                            {participant.required ? 'Obrigat\u00f3rio' : 'Opcional'}
                          </span>
                          <span>{participant.response_status}</span>
                        </div>
                      </header>

                      <div className="skpe-journey-event-participant-attendance">
                        <label>
                          <span>Presen\u00e7a</span>
                          <select
                            value={participant.attendance_status}
                            onChange={(changeEvent) =>
                              void recordAttendance(
                                participant.participant_id,
                                changeEvent.target.value as AttendanceStatus,
                              )
                            }
                            disabled={participantBusy}
                          >
                            <option value="not_recorded">N\u00e3o registrada</option>
                            <option value="attended">Presente</option>
                            <option value="absent">Ausente</option>
                          </select>
                        </label>

                        <label className="is-wide">
                          <span>Justificativa da presen\u00e7a *</span>
                          <input
                            value={
                              attendanceReasons[participant.participant_id] ?? ''
                            }
                            onChange={(changeEvent) =>
                              setAttendanceReasons((current) => ({
                                ...current,
                                [participant.participant_id]:
                                  changeEvent.target.value,
                              }))
                            }
                            disabled={participantBusy}
                            placeholder="M\u00ednimo de 10 caracteres"
                          />
                        </label>
                      </div>

                      <div className="skpe-journey-event-participant-remove">
                        <input
                          value={
                            removeReasons[participant.participant_id] ?? ''
                          }
                          onChange={(changeEvent) =>
                            setRemoveReasons((current) => ({
                              ...current,
                              [participant.participant_id]:
                                changeEvent.target.value,
                            }))
                          }
                          disabled={participantBusy}
                          placeholder="Justificativa para remo\u00e7\u00e3o"
                        />
                        <button
                          type="button"
                          onClick={() =>
                            void removeParticipant(participant.participant_id)
                          }
                          disabled={participantBusy}
                        >
                          Remover
                        </button>
                      </div>
                    </article>
                  ))
                )}
              </div>
            </>
          )}
        </section>
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