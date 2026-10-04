import { useCallback, useEffect, useState } from 'react'

import { supabase } from '../../../../lib/supabase'

import './StrategicMapLifecyclePanel.css'

type MapReadiness = {
  readyForValidation?: boolean
  validated?: boolean
  readyForFormulation?: boolean
  blockingIssueCount?: number
  contentBlockingIssueCount?: number
  issues?: Array<{
    code?: string
    severity?: string
    message?: string
    affectedCount?: number
  }>
}

type MapPackage = {
  id: string
  status: string
  validation_notes: string | null
  submitted_for_validation_at: string | null
  validated_at: string | null
}

type MapVersion = {
  id: string
  version_number: number
  status: string
  source_validated_at: string | null
  validation_notes: string | null
  created_at: string
}

type Props = {
  organizationId: string
  formulationId: string | null
  stageUnlocked: boolean
}

function packageStatusLabel(status: string | null | undefined) {
  const labels: Record<string, string> = {
    in_elaboration: 'Em elaboração',
    pending_validation: 'Aguardando validação',
    validated: 'Validado',
  }
  return labels[status ?? ''] ?? status ?? 'Não criado'
}

export function StrategicMapLifecyclePanel({
  organizationId,
  formulationId,
  stageUnlocked,
}: Props) {
  const [mapPackage, setMapPackage] = useState<MapPackage | null>(null)
  const [latestVersion, setLatestVersion] = useState<MapVersion | null>(null)
  const [readiness, setReadiness] = useState<MapReadiness | null>(null)
  const [canManage, setCanManage] = useState(false)
  const [canValidate, setCanValidate] = useState(false)
  const [decisionNotes, setDecisionNotes] = useState('')
  const [busy, setBusy] = useState(false)
  const [message, setMessage] = useState('')

  const refresh = useCallback(async () => {
    if (!formulationId) {
      setMapPackage(null)
      setLatestVersion(null)
      setReadiness(null)
      return
    }

    const [
      packageResponse,
      versionResponse,
      readinessResponse,
      manageResponse,
      validateResponse,
    ] = await Promise.all([
      supabase
        .from('skpe_strategic_map_packages')
        .select('id,status,validation_notes,submitted_for_validation_at,validated_at')
        .eq('formulation_id', formulationId)
        .maybeSingle(),
      supabase
        .from('skpe_strategic_map_versions')
        .select('id,version_number,status,source_validated_at,validation_notes,created_at')
        .eq('formulation_id', formulationId)
        .order('version_number', { ascending: false })
        .limit(1)
        .maybeSingle(),
      supabase.rpc('get_skpe_strategic_map_readiness', {
        target_formulation_id: formulationId,
      }),
      supabase.rpc('can_manage_skpe_formulation', {
        target_organization_id: organizationId,
      }),
      supabase.rpc('can_validate_skpe_formulation', {
        target_organization_id: organizationId,
      }),
    ])

    setMapPackage((packageResponse.data ?? null) as MapPackage | null)
    setLatestVersion((versionResponse.data ?? null) as MapVersion | null)
    setReadiness((readinessResponse.data ?? null) as MapReadiness | null)
    setCanManage(Boolean(manageResponse.data))
    setCanValidate(Boolean(validateResponse.data))

    const firstError =
      packageResponse.error ??
      versionResponse.error ??
      readinessResponse.error ??
      manageResponse.error ??
      validateResponse.error

    if (firstError) setMessage(firstError.message)
  }, [formulationId, organizationId])

  useEffect(() => {
    void refresh()
  }, [refresh])

  async function transition(
    action:
      | 'submit_validation'
      | 'validate'
      | 'return_for_adjustments'
      | 'begin_revision',
  ) {
    if (!formulationId) return

    const needsNotes =
      action === 'validate' ||
      action === 'return_for_adjustments' ||
      action === 'begin_revision'

    if (needsNotes && decisionNotes.trim().length < 10) {
      setMessage('Registre uma justificativa com pelo menos 10 caracteres.')
      return
    }

    if (
      action === 'submit_validation' &&
      !readiness?.readyForValidation
    ) {
      setMessage('O Mapa ainda possui pendências bloqueantes de readiness.')
      return
    }

    if (!stageUnlocked && action !== 'begin_revision') {
      setMessage('O workflow inicial do Mapa só pode avançar durante PEM-02.05.')
      return
    }

    setBusy(true)
    setMessage('')

    const actionReason =
      action === 'submit_validation'
        ? 'Submissão governada do Mapa Estratégico para validação humana em PEM-02.05.'
        : decisionNotes.trim()

    const { data, error } = await supabase.rpc(
      'transition_skpe_strategic_map',
      {
        target_formulation_id: formulationId,
        transition_action: action,
        decision_notes: decisionNotes.trim() || null,
        change_reason: actionReason,
      },
    )

    if (error) {
      setBusy(false)
      setMessage(error.message)
      return
    }

    const result = (data ?? {}) as {
      officialMapVersionId?: string
      officialMapVersionNumber?: number
      currentStatus?: string
    }

    if (action === 'validate' && result.officialMapVersionNumber) {
      setMessage(
        `Mapa validado. Versão oficial v${result.officialMapVersionNumber} capturada (${result.officialMapVersionId}).`,
      )
    } else {
      setMessage('Transição registrada com sucesso.')
    }

    setDecisionNotes('')
    setBusy(false)
    await refresh()
  }

  if (!formulationId) return null

  const status = mapPackage?.status ?? 'not_created'
  const blockingCount = readiness?.blockingIssueCount ?? 0

  return (
    <section className="skpe-map-lifecycle">
      <header>
        <div>
          <small>PEM-02.05 · Governança do Mapa</small>
          <h3>Validação e versão oficial</h3>
        </div>
        <span>{packageStatusLabel(status)}</span>
      </header>

      <div className="skpe-map-lifecycle-summary">
        <article>
          <small>Readiness</small>
          <strong>{readiness?.readyForValidation ? 'Pronto' : 'Bloqueado'}</strong>
        </article>
        <article>
          <small>Pendências</small>
          <strong>{blockingCount}</strong>
        </article>
        <article>
          <small>Versão oficial</small>
          <strong>
            {latestVersion ? `v${latestVersion.version_number}` : 'Ainda não existe'}
          </strong>
        </article>
      </div>

      {!stageUnlocked && status !== 'validated' ? (
        <p className="skpe-map-lifecycle-lock">
          Workflow bloqueado: PEM-02.05 ainda não foi liberado pela Jornada.
        </p>
      ) : null}

      {latestVersion ? (
        <div className="skpe-map-official-version">
          <strong>Versão oficial preservada</strong>
          <span>v{latestVersion.version_number} · {latestVersion.id}</span>
          {latestVersion.validation_notes ? <p>{latestVersion.validation_notes}</p> : null}
        </div>
      ) : null}

      {(status === 'pending_validation' || status === 'validated') ? (
        <label>
          <span>Justificativa da decisão</span>
          <textarea
            rows={4}
            value={decisionNotes}
            onChange={(event) => setDecisionNotes(event.target.value)}
            placeholder="Registre a decisão humana, orientações de ajuste ou motivo da revisão."
          />
        </label>
      ) : null}

      <div className="skpe-map-lifecycle-actions">
        {status === 'in_elaboration' && canManage ? (
          <button
            type="button"
            onClick={() => void transition('submit_validation')}
            disabled={busy || !stageUnlocked || !readiness?.readyForValidation}
          >
            Enviar para validação
          </button>
        ) : null}

        {status === 'pending_validation' && canValidate ? (
          <>
            <button
              type="button"
              onClick={() => void transition('validate')}
              disabled={busy || !stageUnlocked || !readiness?.readyForValidation}
            >
              Validar e gerar versão oficial
            </button>
            <button
              type="button"
              onClick={() => void transition('return_for_adjustments')}
              disabled={busy || !stageUnlocked}
            >
              Devolver para ajustes
            </button>
          </>
        ) : null}

        {status === 'validated' && canManage ? (
          <button
            type="button"
            onClick={() => void transition('begin_revision')}
            disabled={busy}
          >
            Iniciar revisão preservando versão oficial
          </button>
        ) : null}
      </div>

      {message ? <p className="skpe-map-lifecycle-message">{message}</p> : null}
    </section>
  )
}
