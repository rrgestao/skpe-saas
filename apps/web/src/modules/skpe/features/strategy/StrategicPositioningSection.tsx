import { useEffect, useState } from 'react'
import { supabase } from '../../../../lib/supabase'
import { useSkpeWorkspace } from '../../context/SkpeWorkspaceContext'
import { StrategicPositioningReadinessPanel } from './StrategicPositioningReadinessPanel'
import './StrategicContentSection.css'

type ValidationMetadata = {
  source_status?: string | null
  validation_status?: string | null
  validation_gate?: string | null
}

type Theme = {
  id: string
  code: string
  name: string
  description: string | null
  display_order: number
  status: string
  metadata: ValidationMetadata | null
}

type Perspective = {
  id: string
  code: string
  name: string
  description: string | null
  display_order: number
  status: string
  metadata: ValidationMetadata | null
}

type Objective = {
  id: string
  code: string
  name: string
  description: string | null
  perspective_id: string | null
  perspective_code: string | null
  status: string
  metadata: ValidationMetadata | null
}

function validationLabel(metadata: ValidationMetadata | null, status: string) {
  const sourceStatus = metadata?.source_status?.trim()
  if (sourceStatus) return sourceStatus

  const validationStatus = metadata?.validation_status?.trim()
  if (validationStatus === 'pending_validation') return 'Pendente de validação'
  if (validationStatus === 'draft') return 'Hipótese técnica — não submetida'

  return status === 'draft' ? 'Hipótese técnica — não submetida' : status
}

type PositioningDecisionAction = 'keep' | 'adjust' | 'replace' | 'remove'

type PositioningValidationDecision = {
  id: string
  entity_type: 'strategic_theme' | 'bsc_perspective'
  entity_id: string
  entity_code: string
  decision_sequence: number
  decision_action: PositioningDecisionAction
  proposed_name: string | null
  proposed_description: string | null
  rationale: string
  decided_at: string
}

type PositioningEvidenceAttestation = {
  id: string
  title: string
  description: string | null
  status: string
  reliability_level: string
  received_at: string | null
  metadata: {
    attestation_key?: string
    reporter?: {
      name?: string
      email?: string
      role?: string
      organization?: string
    }
    reported_facts?: {
      validation_meeting_completed?: boolean
      meeting_outcome?: string
      perspectives_approved_without_changes?: boolean
      themes_approved_without_changes?: boolean
      strategic_objectives_approved_without_changes?: boolean
    }
    documentary_counterproof?: {
      status?: string
      expected_artifacts?: string[]
      generated_after_validation?: boolean
    }
    canonical_effect?: {
      approval_state_changed?: boolean
      journey_status_changed?: boolean
      pem02_04_unlocked?: boolean
    }
  } | null
}

type Props = {
  organizationId: string
  projectId?: string | null
}

const decisionActionLabel: Record<PositioningDecisionAction, string> = {
  keep: 'Manter',
  adjust: 'Ajustar',
  replace: 'Substituir',
  remove: 'Remover',
}

type PositioningDecisionEditorProps = {
  formulationId: string
  entityType: 'strategic_theme' | 'bsc_perspective'
  entityId: string
  entityCode: string
  currentName: string
  currentDescription: string | null
  canValidate: boolean
  latestDecision: PositioningValidationDecision | null
  onRecorded: () => Promise<void>
}

function PositioningDecisionEditor({
  formulationId,
  entityType,
  entityId,
  entityCode,
  currentName,
  currentDescription,
  canValidate,
  latestDecision,
  onRecorded,
}: PositioningDecisionEditorProps) {
  const [action, setAction] = useState<PositioningDecisionAction>(
    latestDecision?.decision_action ?? 'keep',
  )
  const [proposedName, setProposedName] = useState(
    latestDecision?.proposed_name ?? currentName,
  )
  const [proposedDescription, setProposedDescription] = useState(
    latestDecision?.proposed_description ?? currentDescription ?? '',
  )
  const [rationale, setRationale] = useState(latestDecision?.rationale ?? '')
  const [evidenceReference, setEvidenceReference] = useState('')
  const [saving, setSaving] = useState(false)
  const [message, setMessage] = useState('')

  useEffect(() => {
    setAction(latestDecision?.decision_action ?? 'keep')
    setProposedName(latestDecision?.proposed_name ?? currentName)
    setProposedDescription(
      latestDecision?.proposed_description ?? currentDescription ?? '',
    )
    setRationale(latestDecision?.rationale ?? '')
  }, [currentDescription, currentName, latestDecision])

  const requiresProposal = action === 'adjust' || action === 'replace'

  async function recordDecision() {
    setMessage('')

    if (rationale.trim().length < 10) {
      setMessage('Informe uma justificativa com pelo menos 10 caracteres.')
      return
    }

    if (
      requiresProposal &&
      !proposedName.trim() &&
      !proposedDescription.trim()
    ) {
      setMessage('Informe o nome ou a descrição proposta.')
      return
    }

    setSaving(true)

    const { error } = await supabase.rpc(
      'record_skpe_positioning_validation_decision',
      {
        target_formulation_id: formulationId,
        target_entity_type: entityType,
        target_entity_id: entityId,
        decision_action: action,
        proposed_name: requiresProposal ? proposedName.trim() || null : null,
        proposed_description: requiresProposal
          ? proposedDescription.trim() || null
          : null,
        decision_rationale: rationale.trim(),
        evidence_refs: evidenceReference.trim()
          ? [evidenceReference.trim()]
          : [],
        decision_metadata: {
          source: 'pem02_03_human_validation_ui',
          entity_code: entityCode,
          canonical_mutation_requested: false,
        },
      },
    )

    if (error) {
      setMessage(error.message)
      setSaving(false)
      return
    }

    setMessage('Decisão registrada. O conteúdo canônico ainda não foi alterado.')
    setSaving(false)
    await onRecorded()
  }

  return (
    <div className="skpe-positioning-decision">
      {latestDecision ? (
        <div className="skpe-positioning-decision-current">
          <small>Última decisão registrada</small>
          <strong>{decisionActionLabel[latestDecision.decision_action]}</strong>
          <span>{latestDecision.rationale}</span>
        </div>
      ) : null}

      {canValidate ? (
        <details>
          <summary>Registrar decisão humana</summary>
          <div className="skpe-positioning-decision-form">
            <label>
              Decisão
              <select
                value={action}
                onChange={(event) =>
                  setAction(event.target.value as PositioningDecisionAction)
                }
              >
                <option value="keep">Manter</option>
                <option value="adjust">Ajustar</option>
                <option value="replace">Substituir</option>
                <option value="remove">Remover</option>
              </select>
            </label>

            {requiresProposal ? (
              <>
                <label>
                  Nome proposto
                  <input
                    value={proposedName}
                    onChange={(event) => setProposedName(event.target.value)}
                  />
                </label>
                <label>
                  Descrição proposta
                  <textarea
                    value={proposedDescription}
                    onChange={(event) =>
                      setProposedDescription(event.target.value)
                    }
                  />
                </label>
              </>
            ) : null}

            <label>
              Justificativa
              <textarea
                value={rationale}
                onChange={(event) => setRationale(event.target.value)}
                placeholder="Explique a decisão e o motivo."
              />
            </label>

            <label>
              Evidência ou referência
              <input
                value={evidenceReference}
                onChange={(event) =>
                  setEvidenceReference(event.target.value)
                }
                placeholder="Opcional: ata, documento, reunião ou referência."
              />
            </label>

            <button type="button" onClick={() => void recordDecision()} disabled={saving}>
              {saving ? 'Registrando...' : 'Registrar decisão'}
            </button>

            {message ? <p className="skpe-positioning-decision-message">{message}</p> : null}
          </div>
        </details>
      ) : (
        <p className="skpe-positioning-decision-readonly">
          Você pode consultar esta proposta, mas não possui permissão de validação.
        </p>
      )}
    </div>
  )
}

export function StrategicPositioningSection({
  organizationId,
  projectId,
}: Props) {
  const workspace = useSkpeWorkspace()
  const formulationId = workspace.route.formulationId
  const effectiveProjectId = workspace.route.projectId ?? projectId

  const [themes, setThemes] = useState<Theme[]>([])
  const [perspectives, setPerspectives] = useState<Perspective[]>([])
  const [objectives, setObjectives] = useState<Objective[]>([])
  const [canValidate, setCanValidate] = useState(false)
  const [latestDecisions, setLatestDecisions] = useState<
    Record<string, PositioningValidationDecision>
  >({})
  const [evidenceAttestation, setEvidenceAttestation] = useState<
    PositioningEvidenceAttestation | null
  >(null)
  const [error, setError] = useState('')

  async function refreshValidationState() {
    if (!formulationId) {
      setCanValidate(false)
      setLatestDecisions({})
      return
    }

    const [permissionResponse, decisionResponse] = await Promise.all([
      supabase.rpc('can_validate_skpe_formulation', {
        target_organization_id: organizationId,
      }),
      supabase
        .from('skpe_positioning_validation_events')
        .select(
          'id,entity_type,entity_id,entity_code,decision_sequence,decision_action,proposed_name,proposed_description,rationale,decided_at',
        )
        .eq('formulation_id', formulationId)
        .order('decision_sequence', { ascending: false }),
    ])

    setCanValidate(Boolean(permissionResponse.data))

    if (decisionResponse.error) {
      setError('Não foi possível carregar as decisões de validação de PEM-02.03.')
      return
    }

    const latest: Record<string, PositioningValidationDecision> = {}
    for (const decision of (decisionResponse.data ?? []) as PositioningValidationDecision[]) {
      const key = `${decision.entity_type}:${decision.entity_id}`
      if (!latest[key]) latest[key] = decision
    }
    setLatestDecisions(latest)
  }

  useEffect(() => {
    let active = true

    if (!formulationId) {
      setThemes([])
      setPerspectives([])
      setObjectives([])
      setError('')
      return () => {
        active = false
      }
    }

    setError('')

    const themesQuery = supabase
      .from('skpe_strategic_themes')
      .select('id,code,name,description,display_order,status,metadata')
      .eq('organization_id', organizationId)
      .eq('formulation_id', formulationId)
      .order('display_order')

    const perspectivesQuery = supabase
      .from('skpe_bsc_perspectives')
      .select('id,code,name,description,display_order,status,metadata')
      .eq('organization_id', organizationId)
      .eq('formulation_id', formulationId)
      .order('display_order')

    const objectivesQuery = supabase
      .from('skpe_strategic_objectives')
      .select(
        'id,code,name,description,perspective_id,perspective_code,status,metadata',
      )
      .eq('organization_id', organizationId)
      .eq('formulation_id', formulationId)
      .order('code')

    const scopedThemesQuery = effectiveProjectId
      ? themesQuery.eq('project_id', effectiveProjectId)
      : themesQuery
    const scopedPerspectivesQuery = effectiveProjectId
      ? perspectivesQuery.eq('project_id', effectiveProjectId)
      : perspectivesQuery
    const scopedObjectivesQuery = effectiveProjectId
      ? objectivesQuery.eq('project_id', effectiveProjectId)
      : objectivesQuery

    void Promise.all([
      scopedThemesQuery,
      scopedPerspectivesQuery,
      scopedObjectivesQuery,
    ]).then(([themeResponse, perspectiveResponse, objectiveResponse]) => {
      if (!active) return

      if (
        themeResponse.error ||
        perspectiveResponse.error ||
        objectiveResponse.error
      ) {
        setError('Não foi possível carregar o Posicionamento Estratégico.')
        return
      }

      setThemes((themeResponse.data ?? []) as Theme[])
      setPerspectives((perspectiveResponse.data ?? []) as Perspective[])
      setObjectives((objectiveResponse.data ?? []) as Objective[])
    })

    return () => {
      active = false
    }
  }, [organizationId, effectiveProjectId, formulationId])

  useEffect(() => {
    void refreshValidationState()
  }, [organizationId, formulationId])

  useEffect(() => {
    let active = true

    if (!effectiveProjectId) {
      setEvidenceAttestation(null)
      return () => {
        active = false
      }
    }

    void supabase
      .from('skpe_evidence_sources')
      .select('id,title,description,status,reliability_level,received_at,metadata')
      .eq('organization_id', organizationId)
      .eq('project_id', effectiveProjectId)
      .eq('cycle_code', 'PEM-02.03')
      .order('received_at', { ascending: false })
      .then((response) => {
        if (!active) return
        if (response.error) {
          setEvidenceAttestation(null)
          return
        }

        const attestation = ((response.data ?? []) as PositioningEvidenceAttestation[])
          .find(
            (item) =>
              item.metadata?.attestation_key ===
              'COOTAQUARA-PEM-02.03-VALIDATION-REPORT-20261004',
          )

        setEvidenceAttestation(attestation ?? null)
      })

    return () => {
      active = false
    }
  }, [organizationId, effectiveProjectId])

  if (!formulationId) {
    return (
      <section className="skpe-strategy-state">
        Selecione uma Formulação Estratégica para consultar o Mapa Estratégico.
      </section>
    )
  }

  if (error) {
    return <section className="skpe-strategy-state is-error">{error}</section>
  }

  return (
    <section className="skpe-strategy-content">
      <header>
        <span>Escolhas e Posicionamento Estratégico</span>
        <h1>Posicionamento Estratégico</h1>
        <p className="skpe-strategy-validation-guidance">
          Esta etapa organiza hipóteses de Temas e Perspectivas para validação
          humana. Conteúdo materializado não equivale a aprovação institucional.
        </p>
      </header>

      <StrategicPositioningReadinessPanel formulationId={formulationId} />

      {evidenceAttestation ? (
        <section className="skpe-positioning-attestation">
          <strong>Relato humano recebido — aguardando contraprova estruturada v26</strong>
          <p>
            Ricardo Rodrigues · Líder da SPARKOOP neste projeto ·
            {' '}{evidenceAttestation.metadata?.reporter?.email ?? 'e-mail não informado'}
          </p>
          <p>
            Foi informado que a reunião de validação com a COOTAQUARA foi concluída
            com sucesso e que Perspectivas, Temas e Objetivos Estratégicos foram
            aprovados integralmente, sem adequações.
          </p>
          <small>
            Estado da fonte: {evidenceAttestation.status} · confiabilidade:
            {' '}{evidenceAttestation.reliability_level}. A planilha + HTML v26 ainda
            não foram submetidos; nenhum estado canônico foi promovido por este relato.
          </small>
        </section>
      ) : null}

      <section>
        <h2>{themes.length} Temas Estratégicos em validação</h2>
        <div className="skpe-strategy-theme-grid">
          {themes.map((theme) => (
            <article key={theme.id}>
              <small>{theme.code}</small>
              <span className="skpe-strategy-validation-badge">
                {validationLabel(theme.metadata, theme.status)}
              </span>
              <strong>{theme.name}</strong>
              {theme.description ? <p>{theme.description}</p> : null}
              <PositioningDecisionEditor
                formulationId={formulationId}
                entityType="strategic_theme"
                entityId={theme.id}
                entityCode={theme.code}
                currentName={theme.name}
                currentDescription={theme.description}
                canValidate={canValidate}
                latestDecision={
                  latestDecisions[`strategic_theme:${theme.id}`] ?? null
                }
                onRecorded={refreshValidationState}
              />
            </article>
          ))}
        </div>
      </section>

      <section>
        <h2>{perspectives.length} Perspectivas Estratégicas em validação</h2>
        <div className="skpe-strategy-perspective-grid">
          {perspectives.map((perspective) => (
            <article key={perspective.id}>
              <small>{perspective.code}</small>
              <span className="skpe-strategy-validation-badge">
                {validationLabel(perspective.metadata, perspective.status)}
              </span>
              <strong>{perspective.name}</strong>
              {perspective.description ? (
                <p>{perspective.description}</p>
              ) : null}
              <PositioningDecisionEditor
                formulationId={formulationId}
                entityType="bsc_perspective"
                entityId={perspective.id}
                entityCode={perspective.code}
                currentName={perspective.name}
                currentDescription={perspective.description}
                canValidate={canValidate}
                latestDecision={
                  latestDecisions[`bsc_perspective:${perspective.id}`] ?? null
                }
                onRecorded={refreshValidationState}
              />
            </article>
          ))}
        </div>
      </section>

      <section className="skpe-strategy-next-stage-preview">
        <header>
          <span>Próxima etapa · Objetivos Estratégicos</span>
          <h2>Objetivos Estratégicos — prévia bloqueada</h2>
          <p>
            Os {objectives.length} Objetivos já materializados permanecem em
            draft e não fazem parte da validação desta etapa. Eles só devem ser
            trabalhados após a conclusão governada do Posicionamento Estratégico.
          </p>
        </header>
        <div className="skpe-strategy-objective-grid">
          {objectives.map((objective) => (
            <article key={objective.id} className="skpe-strategy-objective-card">
              <small>{objective.code}</small>
              <span className="skpe-strategy-validation-badge">
                {validationLabel(objective.metadata, objective.status)}
              </span>
              <strong>{objective.name}</strong>
            </article>
          ))}
        </div>
      </section>
    </section>
  )
}