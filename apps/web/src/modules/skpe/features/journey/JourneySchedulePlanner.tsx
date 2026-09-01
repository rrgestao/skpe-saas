import { useEffect, useMemo, useState } from 'react'

import { supabase } from '../../../../lib/supabase'
import { translateBackendMessage } from '../../../../shared/i18n/ptBR'
import type { JourneyTemporalRow } from '../../contracts/journey'

import './JourneySchedulePlanner.css'

type ScheduleVersion = {
  id: string
  version_number: number
  schedule_kind: 'baseline' | 'rebaseline' | 'forecast'
  governance_status:
    | 'draft'
    | 'pending_approval'
    | 'approved'
    | 'active'
    | 'superseded'
    | 'cancelled'
  title: string
  notes: string | null
  supersedes_version_id: string | null
  is_current_plan: boolean
  is_current_forecast: boolean
  submitted_at: string | null
  approved_at: string | null
  created_at: string
}

type ScheduleItem = {
  id: string
  schedule_version_id: string
  journey_item_id: string
  planned_start_date: string | null
  planned_end_date: string | null
  source_mode: string
  planning_note: string | null
}

type Readiness = {
  scheduleVersionId: string
  projectId: string
  scheduleKind: string
  governanceStatus: string
  mandatoryLeafCount: number
  readyMandatoryLeafCount: number
  missingMandatoryLeafCount: number
  missingItems: Array<{
    itemId: string
    code: string
    name: string
    itemType: string
    plannedStartDate: string | null
    plannedEndDate: string | null
  }>
  readyToSubmit: boolean
}

type DraftDates = {
  start: string
  end: string
  note: string
}

type JourneySchedulePlannerProps = {
  organizationId: string
  projectId: string
  rows: JourneyTemporalRow[]
  canManageJourney: boolean
  formatDate: (value: string | null) => string
  onPlanMaterialized: () => void
}

function governanceLabel(value: ScheduleVersion['governance_status']) {
  const labels: Record<ScheduleVersion['governance_status'], string> = {
    draft: 'Em elaboração',
    pending_approval: 'Aguardando aprovação',
    approved: 'Linha de Base aprovada',
    active: 'Ativo',
    superseded: 'Substituído',
    cancelled: 'Cancelado',
  }

  return labels[value]
}

function kindLabel(value: ScheduleVersion['schedule_kind']) {
  if (value === 'baseline') return 'Linha de Base inicial'
  if (value === 'rebaseline') return 'Revisão da Linha de Base'
  return 'Previsão operacional'
}

function itemTypeLabel(value: JourneyTemporalRow['item_type']) {
  const labels: Record<JourneyTemporalRow['item_type'], string> = {
    macrophase: 'MEGAFASE',
    phase: 'Fase',
    stage: 'Etapa',
    meta_stage: 'Metaetapa',
    activity: 'Atividade',
    deliverable: 'Entregável',
    gate: 'Gate',
  }

  return labels[value]
}

export function JourneySchedulePlanner({
  organizationId,
  projectId,
  rows,
  canManageJourney,
  formatDate,
  onPlanMaterialized,
}: JourneySchedulePlannerProps) {
  const [versions, setVersions] = useState<ScheduleVersion[]>([])
  const [selectedVersionId, setSelectedVersionId] = useState<string | null>(null)
  const [items, setItems] = useState<ScheduleItem[]>([])
  const [readiness, setReadiness] = useState<Readiness | null>(null)
  const [canApprove, setCanApprove] = useState(false)
  const [draftDates, setDraftDates] = useState<Record<string, DraftDates>>({})
  const [title, setTitle] = useState('Linha de Base da Jornada Estratégica')
  const [notes, setNotes] = useState(
    'Planejamento temporal institucional da Jornada Estratégica.',
  )
  const [changeReason, setChangeReason] = useState(
    'Planejamento temporal inicial da Jornada Estratégica.',
  )
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [message, setMessage] = useState('')
  const [errorMessage, setErrorMessage] = useState('')

  const childIds = useMemo(() => {
    const parents = new Set<string>()
    for (const row of rows) {
      if (row.parent_item_id && row.item_status !== 'cancelled') {
        parents.add(row.parent_item_id)
      }
    }
    return parents
  }, [rows])

  const leaves = useMemo(
    () =>
      rows
        .filter(
          (row) =>
            row.item_status !== 'cancelled' && !childIds.has(row.item_id),
        )
        .sort(
          (first, second) =>
            first.display_order - second.display_order ||
            first.item_code.localeCompare(second.item_code, 'pt-BR'),
        ),
    [rows, childIds],
  )

  const currentPlan = useMemo(
    () =>
      versions.find(
        (version) =>
          version.is_current_plan &&
          version.governance_status === 'approved' &&
          (version.schedule_kind === 'baseline' ||
            version.schedule_kind === 'rebaseline'),
      ) ?? null,
    [versions],
  )

  const editableVersion = useMemo(
    () =>
      versions.find(
        (version) =>
          version.id === selectedVersionId &&
          version.governance_status === 'draft' &&
          (version.schedule_kind === 'baseline' ||
            version.schedule_kind === 'rebaseline'),
      ) ?? null,
    [versions, selectedVersionId],
  )

  const selectedVersion = useMemo(
    () => versions.find((version) => version.id === selectedVersionId) ?? null,
    [versions, selectedVersionId],
  )

  const itemByJourneyId = useMemo(
    () => new Map(items.map((item) => [item.journey_item_id, item])),
    [items],
  )

  async function loadVersions(preferredVersionId?: string | null) {
    setErrorMessage('')

    const { data, error } = await supabase
      .from('skpe_journey_schedule_versions')
      .select(
        'id, version_number, schedule_kind, governance_status, title, notes, supersedes_version_id, is_current_plan, is_current_forecast, submitted_at, approved_at, created_at',
      )
      .eq('project_id', projectId)
      .order('version_number', { ascending: false })

    if (error) {
      setVersions([])
      setErrorMessage(translateBackendMessage(error.message))
      return null
    }

    const loaded = (data ?? []) as ScheduleVersion[]
    setVersions(loaded)

    const preferred =
      loaded.find((version) => version.id === preferredVersionId) ??
      loaded.find(
        (version) =>
          version.governance_status === 'draft' &&
          (version.schedule_kind === 'baseline' ||
            version.schedule_kind === 'rebaseline'),
      ) ??
      loaded.find((version) => version.is_current_plan) ??
      loaded[0] ??
      null

    setSelectedVersionId(preferred?.id ?? null)
    return preferred?.id ?? null
  }

  async function loadVersionItems(versionId: string | null) {
    if (!versionId) {
      setItems([])
      setDraftDates({})
      setReadiness(null)
      return
    }

    const [{ data, error }, readinessResult] = await Promise.all([
      supabase
        .from('skpe_journey_schedule_items')
        .select(
          'id, schedule_version_id, journey_item_id, planned_start_date, planned_end_date, source_mode, planning_note',
        )
        .eq('schedule_version_id', versionId),
      supabase.rpc('get_skpe_journey_schedule_readiness', {
        p_schedule_version_id: versionId,
      }),
    ])

    if (error) {
      setErrorMessage(translateBackendMessage(error.message))
      return
    }

    const loadedItems = (data ?? []) as ScheduleItem[]
    setItems(loadedItems)

    const nextDrafts: Record<string, DraftDates> = {}
    for (const row of leaves) {
      const existing = loadedItems.find(
        (item) => item.journey_item_id === row.item_id,
      )
      nextDrafts[row.item_id] = {
        start: existing?.planned_start_date ?? '',
        end: existing?.planned_end_date ?? '',
        note: existing?.planning_note ?? '',
      }
    }
    setDraftDates(nextDrafts)

    if (!readinessResult.error) {
      setReadiness((readinessResult.data ?? null) as Readiness | null)
    } else {
      setReadiness(null)
    }
  }

  async function loadCapabilities() {
    const { data } = await supabase.rpc('can_approve_skpe_journey_schedule', {
      target_organization_id: organizationId,
    })
    setCanApprove(Boolean(data))
  }

  async function reload(preferredVersionId?: string | null) {
    setLoading(true)
    setMessage('')
    const versionId = await loadVersions(preferredVersionId)
    await Promise.all([loadVersionItems(versionId), loadCapabilities()])
    setLoading(false)
  }

  useEffect(() => {
    void reload()
  }, [organizationId, projectId])

  useEffect(() => {
    if (!loading) {
      void loadVersionItems(selectedVersionId)
    }
  }, [selectedVersionId])

  async function createPlanningVersion(kind: 'baseline' | 'rebaseline') {
    if (!canManageJourney || saving) return

    setSaving(true)
    setErrorMessage('')
    setMessage('')

    const supersedes =
      kind === 'rebaseline' ? currentPlan?.id ?? null : null

    const { data, error } = await supabase.rpc(
      'create_skpe_journey_schedule_version',
      {
        p_project_id: projectId,
        p_schedule_kind: kind,
        p_title: title.trim(),
        p_notes: notes.trim() || null,
        p_supersedes_version_id: supersedes,
        p_change_reason: changeReason.trim(),
      },
    )

    if (error) {
      setErrorMessage(translateBackendMessage(error.message))
      setSaving(false)
      return
    }

    const versionId = data as string
    await reload(versionId)
    setMessage(
      kind === 'baseline'
        ? 'Proposta de Linha de Base criada. Informe as datas planejadas.'
        : 'Revisão da Linha de Base criada a partir do plano vigente.',
    )
    setSaving(false)
  }

  async function saveDates() {
    if (!editableVersion || !canManageJourney || saving) return

    if (changeReason.trim().length < 10) {
      setErrorMessage('Informe uma justificativa com pelo menos 10 caracteres.')
      return
    }

    setSaving(true)
    setErrorMessage('')
    setMessage('')

    for (const row of leaves) {
      const draft = draftDates[row.item_id]
      if (!draft) continue

      const existing = itemByJourneyId.get(row.item_id)
      const start = draft.start || null
      const end = draft.end || null
      const note = draft.note.trim() || null

      const unchanged =
        (existing?.planned_start_date ?? null) === start &&
        (existing?.planned_end_date ?? null) === end &&
        (existing?.planning_note ?? null) === note

      if (unchanged) continue

      if (!start && !end) {
        if (existing) {
          const deleteResult = await supabase.rpc(
            'delete_skpe_journey_schedule_item',
            {
              p_schedule_version_id: editableVersion.id,
              p_journey_item_id: row.item_id,
              p_change_reason: changeReason.trim(),
            },
          )

          if (deleteResult.error) {
            setErrorMessage(translateBackendMessage(deleteResult.error.message))
            setSaving(false)
            return
          }
        }
        continue
      }

      const { error } = await supabase.rpc('set_skpe_journey_schedule_item', {
        p_schedule_version_id: editableVersion.id,
        p_journey_item_id: row.item_id,
        p_planned_start_date: start,
        p_planned_end_date: end,
        p_source_mode: 'explicit',
        p_planning_note: note,
        p_change_reason: changeReason.trim(),
      })

      if (error) {
        setErrorMessage(
          `${row.item_code}: ${translateBackendMessage(error.message)}`,
        )
        setSaving(false)
        return
      }
    }

    await loadVersionItems(editableVersion.id)
    setMessage('Datas planejadas salvas e prontidão recalculada.')
    setSaving(false)
  }

  async function transition(
    action: 'submit' | 'approve' | 'return_for_adjustment' | 'cancel',
  ) {
    if (!selectedVersion || saving) return

    if (changeReason.trim().length < 10) {
      setErrorMessage('Informe uma justificativa com pelo menos 10 caracteres.')
      return
    }

    setSaving(true)
    setErrorMessage('')
    setMessage('')

    if (action === 'submit') {
      const readinessResult = await supabase.rpc(
        'get_skpe_journey_schedule_readiness',
        {
          p_schedule_version_id: selectedVersion.id,
        },
      )

      if (readinessResult.error) {
        setErrorMessage(
          translateBackendMessage(readinessResult.error.message),
        )
        setSaving(false)
        return
      }

      const currentReadiness = readinessResult.data as Readiness
      setReadiness(currentReadiness)

      if (!currentReadiness.readyToSubmit) {
        setErrorMessage(
          `Ainda existem ${currentReadiness.missingMandatoryLeafCount} item(ns) obrigatório(s) sem planejamento completo.`,
        )
        setSaving(false)
        return
      }
    }

    const { error } = await supabase.rpc(
      'transition_skpe_journey_schedule_version',
      {
        p_schedule_version_id: selectedVersion.id,
        p_action: action,
        p_change_reason: changeReason.trim(),
      },
    )

    if (error) {
      setErrorMessage(translateBackendMessage(error.message))
      setSaving(false)
      return
    }

    const actionMessages = {
      submit: 'Planejamento submetido para aprovação.',
      approve:
        'Linha de Base aprovada e materializada como Plano Institucional vigente.',
      return_for_adjustment: 'Planejamento devolvido para ajustes.',
      cancel: 'Versão de planejamento cancelada.',
    }

    await reload(selectedVersion.id)
    if (action === 'approve') {
      await onPlanMaterialized()
    }
    setMessage(actionMessages[action])
    setSaving(false)
  }

  if (loading) {
    return (
      <section className="skpe-schedule-planner-card">
        <p>Carregando planejamento temporal...</p>
      </section>
    )
  }

  return (
    <section
      className="skpe-schedule-planner"
      aria-label="Planejamento temporal da Jornada Estratégica"
    >
      <header className="skpe-schedule-planner-header">
        <div>
          <p className="skpe-eyebrow">Planejamento temporal governado</p>
          <h2>Linha de Base da Jornada</h2>
          <p>
            Informe as datas nas folhas da Jornada. Fases, etapas e MEGAFASES
            serão consolidadas pelo backend a partir dos filhos ativos.
          </p>
        </div>

        <div className="skpe-schedule-planner-rules">
          <span><strong>90 dias</strong> implantação padrão</span>
          <span><strong>45 dias</strong> meta acelerada</span>
          <span><strong>+90 dias</strong> acompanhamento pós-entrega</span>
        </div>
      </header>

      {errorMessage && (
        <div className="skpe-admin-message skpe-admin-message-error">
          {errorMessage}
        </div>
      )}

      {message && (
        <div className="skpe-admin-message skpe-admin-message-success">
          {message}
        </div>
      )}

      {versions.length === 0 ? (
        <div className="skpe-schedule-planner-empty">
          <h3>O planejamento temporal ainda não foi iniciado</h3>
          <p>
            Crie a proposta inicial, informe as datas planejadas e submeta para
            aprovação. A aprovação fecha a Linha de Base e a transforma no Plano
            Institucional vigente.
          </p>

          <div className="skpe-schedule-create-form">
            <label>
              Título
              <input
                value={title}
                onChange={(event) => setTitle(event.target.value)}
              />
            </label>
            <label>
              Observações
              <textarea
                value={notes}
                onChange={(event) => setNotes(event.target.value)}
                rows={2}
              />
            </label>
            <label>
              Justificativa auditável
              <textarea
                value={changeReason}
                onChange={(event) => setChangeReason(event.target.value)}
                rows={2}
              />
            </label>
            <button
              type="button"
              onClick={() => void createPlanningVersion('baseline')}
              disabled={
                !canManageJourney ||
                saving ||
                title.trim().length === 0 ||
                changeReason.trim().length < 10
              }
            >
              Iniciar planejamento da Linha de Base
            </button>
          </div>
        </div>
      ) : (
        <>
          <div className="skpe-schedule-version-bar">
            <label>
              Versão
              <select
                value={selectedVersionId ?? ''}
                onChange={(event) =>
                  setSelectedVersionId(event.target.value || null)
                }
              >
                {versions.map((version) => (
                  <option key={version.id} value={version.id}>
                    v{version.version_number} · {kindLabel(version.schedule_kind)}
                    {' · '}
                    {governanceLabel(version.governance_status)}
                  </option>
                ))}
              </select>
            </label>

            {selectedVersion && (
              <div className="skpe-schedule-version-status">
                <strong>v{selectedVersion.version_number}</strong>
                <span>{kindLabel(selectedVersion.schedule_kind)}</span>
                <span>{governanceLabel(selectedVersion.governance_status)}</span>
              </div>
            )}
          </div>

          {selectedVersion?.governance_status === 'approved' &&
            selectedVersion.is_current_plan &&
            canManageJourney && (
              <div className="skpe-schedule-approved-banner">
                <div>
                  <strong>Linha de Base fechada</strong>
                  <span>
                    A versão aprovada não pode ser editada. Mudanças posteriores
                    devem ocorrer por Revisão da Linha de Base.
                  </span>
                </div>
                <button
                  type="button"
                  onClick={() => void createPlanningVersion('rebaseline')}
                  disabled={saving}
                >
                  Criar revisão da Linha de Base
                </button>
              </div>
            )}

          {readiness && (
            <div className="skpe-schedule-readiness">
              <div>
                <span>Obrigatórios planejados</span>
                <strong>
                  {readiness.readyMandatoryLeafCount}/
                  {readiness.mandatoryLeafCount}
                </strong>
              </div>
              <div>
                <span>Pendências</span>
                <strong>{readiness.missingMandatoryLeafCount}</strong>
              </div>
              <div>
                <span>Pronto para submeter</span>
                <strong>{readiness.readyToSubmit ? 'Sim' : 'Não'}</strong>
              </div>
            </div>
          )}

          {selectedVersion?.governance_status === 'draft' && (
            <>
              <div className="skpe-schedule-reason-row">
                <label>
                  Justificativa das alterações
                  <input
                    value={changeReason}
                    onChange={(event) => setChangeReason(event.target.value)}
                  />
                </label>
              </div>

              <div className="skpe-schedule-table-wrap">
                <table className="skpe-schedule-table">
                  <thead>
                    <tr>
                      <th>Item</th>
                      <th>Obrigatório</th>
                      <th>Início planejado</th>
                      <th>Fim / marco planejado</th>
                      <th>Observação</th>
                    </tr>
                  </thead>
                  <tbody>
                    {leaves.map((row) => {
                      const draft =
                        draftDates[row.item_id] ?? {
                          start: '',
                          end: '',
                          note: '',
                        }
                      const endOnly =
                        row.item_type === 'gate' ||
                        row.item_type === 'deliverable'

                      return (
                        <tr key={row.item_id}>
                          <td>
                            <strong>{row.item_code}</strong>
                            <span>{row.item_name}</span>
                            <small>{itemTypeLabel(row.item_type)}</small>
                          </td>
                          <td>{row.is_mandatory ? 'Sim' : 'Não'}</td>
                          <td>
                            <input
                              type="date"
                              value={draft.start}
                              disabled={endOnly || !canManageJourney || saving}
                              onChange={(event) =>
                                setDraftDates((current) => ({
                                  ...current,
                                  [row.item_id]: {
                                    ...draft,
                                    start: event.target.value,
                                  },
                                }))
                              }
                            />
                          </td>
                          <td>
                            <input
                              type="date"
                              value={draft.end}
                              disabled={!canManageJourney || saving}
                              onChange={(event) =>
                                setDraftDates((current) => ({
                                  ...current,
                                  [row.item_id]: {
                                    ...draft,
                                    end: event.target.value,
                                  },
                                }))
                              }
                            />
                          </td>
                          <td>
                            <input
                              value={draft.note}
                              disabled={!canManageJourney || saving}
                              placeholder="Opcional"
                              onChange={(event) =>
                                setDraftDates((current) => ({
                                  ...current,
                                  [row.item_id]: {
                                    ...draft,
                                    note: event.target.value,
                                  },
                                }))
                              }
                            />
                          </td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>

              <div className="skpe-schedule-actions">
                <button
                  type="button"
                  onClick={() => void saveDates()}
                  disabled={
                    !canManageJourney ||
                    saving ||
                    changeReason.trim().length < 10
                  }
                >
                  Salvar datas planejadas
                </button>
                <button
                  type="button"
                  className="is-primary"
                  onClick={() => void transition('submit')}
                  disabled={
                    !canManageJourney ||
                    saving ||
                    !readiness?.readyToSubmit ||
                    changeReason.trim().length < 10
                  }
                >
                  Submeter Linha de Base
                </button>
              </div>
            </>
          )}

          {selectedVersion?.governance_status === 'pending_approval' && (
            <div className="skpe-schedule-approval-panel">
              <div>
                <strong>Planejamento aguardando decisão</strong>
                <span>
                  A aprovação fecha a Linha de Base e materializa as datas como
                  Plano Institucional vigente.
                </span>
              </div>
              <div className="skpe-schedule-actions">
                {canApprove && (
                  <>
                    <button
                      type="button"
                      onClick={() => void transition('return_for_adjustment')}
                      disabled={saving}
                    >
                      Devolver para ajustes
                    </button>
                    <button
                      type="button"
                      className="is-primary"
                      onClick={() => void transition('approve')}
                      disabled={saving}
                    >
                      Aprovar e fechar Linha de Base
                    </button>
                  </>
                )}
              </div>
            </div>
          )}

          {selectedVersion?.governance_status === 'approved' && (
            <div className="skpe-schedule-readonly-items">
              <h3>Planejamento aprovado</h3>
              <p>
                Linha de Base aprovada em{' '}
                {formatDate(selectedVersion.approved_at?.slice(0, 10) ?? null)}.
                As datas consolidadas já alimentam a Jornada e os Gantts.
              </p>
            </div>
          )}

          {readiness && readiness.missingItems.length > 0 && (
            <details className="skpe-schedule-missing">
              <summary>
                Ver {readiness.missingItems.length} pendência(s) obrigatória(s)
              </summary>
              <ul>
                {readiness.missingItems.map((item) => (
                  <li key={item.itemId}>
                    <strong>{item.code}</strong> · {item.name}
                  </li>
                ))}
              </ul>
            </details>
          )}
        </>
      )}
    </section>
  )
}