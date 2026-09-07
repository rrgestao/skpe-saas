import { useCallback, useEffect, useMemo, useState } from 'react'
import { Filter, X } from 'lucide-react'
import { Grid, Willow, type IColumnConfig } from '@svar-ui/react-grid'
import '@svar-ui/react-grid/all.css'

import { supabase } from '../../../lib/supabase'
import { SparksGridNavigator } from '../../../components/design-system/SparksGridNavigator'
import '../../skpe/components/OrganizationUsersSmartGrid.css'

import './SuggestedInitiativesDraftPanel.css'

type SuggestedInitiativeRow = {
  initiative_id: string
  organization_id: string
  project_id: string
  initiative_code: string
  initiative_name: string
  status: string
  validation_status: string
  proposal_origin: string
  proposal_source_reference: string | null
  suggested_by_module: string | null
  suggestion_generated_at: string | null
  suggestion_decision: string
  suggestion_decided_at: string | null
  suggestion_decided_by: string | null
  suggestion_curation_notes: string | null
  ui_status: string
  pending_5w2h_fields: string[] | null
  five_w_two_h_complete: boolean
  source_risk_codes: string[] | null
  source_label: string | null
}

type SuggestionDecision =
  | 'accepted'
  | 'accepted_with_adjustments'
  | 'rejected'

type SuggestedInitiativesDraftPanelProps = {
  organizationId: string
  canManageInitiatives: boolean
  refreshRequestKey: number
  onRefresh: () => void
  onReview: (initiativeId: string) => void
}

type SuggestedInitiativeGridRow = {
  id: string
  code: string
  initiative: string
  origin: string
  risks: string
  status: string
  fiveWTwoH: string
  pending: string
  decision: string
}

const decisionLabel: Record<string, string> = {
  pending: 'Rascunho',
  accepted: 'Aceita',
  accepted_with_adjustments: 'Aceita com ajustes',
  rejected: 'Rejeitada',
}

const fieldLabel: Record<string, string> = {
  what_text: 'O quê',
  why_text: 'Por quê',
  where_text: 'Onde',
  when_text: 'Quando',
  who_text: 'Quem',
  how_text: 'Como',
  how_much_text: 'Quanto',
}

function displayDecision(row: SuggestedInitiativeRow) {
  return (
    decisionLabel[row.suggestion_decision] ??
    row.ui_status ??
    row.suggestion_decision
  )
}

const columns: IColumnConfig[] = [
  {
    id: 'code',
    header: 'Código',
    width: 110,
    sort: true,
    resize: true,
    tooltip: true,
  },
  {
    id: 'initiative',
    header: 'Iniciativa',
    width: 340,
    sort: true,
    resize: true,
    tooltip: true,
  },
  {
    id: 'origin',
    header: 'Origem',
    width: 220,
    sort: true,
    resize: true,
    tooltip: true,
  },
  {
    id: 'risks',
    header: 'Riscos cobertos',
    width: 180,
    sort: true,
    resize: true,
    tooltip: true,
  },
  {
    id: 'status',
    header: 'Status',
    width: 120,
    sort: true,
    resize: true,
    tooltip: true,
  },
  {
    id: 'fiveWTwoH',
    header: '5W2H',
    width: 130,
    sort: true,
    resize: true,
    tooltip: true,
  },
  {
    id: 'pending',
    header: 'Pendências',
    width: 220,
    sort: true,
    resize: true,
    tooltip: true,
  },
  {
    id: 'decision',
    header: 'Decisão',
    width: 160,
    sort: true,
    resize: true,
    tooltip: true,
  },
]

export function SuggestedInitiativesDraftPanel({
  organizationId,
  canManageInitiatives,
  refreshRequestKey,
  onRefresh,
  onReview,
}: SuggestedInitiativesDraftPanelProps) {
  const [rows, setRows] = useState<SuggestedInitiativeRow[]>([])
  const [loading, setLoading] = useState(true)
  const [errorMessage, setErrorMessage] = useState('')
  const [busyId, setBusyId] = useState<string | null>(null)
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [reviewOpen, setReviewOpen] = useState(false)
  const [notes, setNotes] = useState<Record<string, string>>({})
  const [searchTerm, setSearchTerm] = useState('')
  const [decisionFilter, setDecisionFilter] = useState('all')

  const load = useCallback(async () => {
    setLoading(true)
    setErrorMessage('')

    const { data, error } = await supabase
      .from('skpe_sparks_suggested_initiative_readiness')
      .select(
        [
          'initiative_id',
          'organization_id',
          'project_id',
          'initiative_code',
          'initiative_name',
          'status',
          'validation_status',
          'proposal_origin',
          'proposal_source_reference',
          'suggested_by_module',
          'suggestion_generated_at',
          'suggestion_decision',
          'suggestion_decided_at',
          'suggestion_decided_by',
          'suggestion_curation_notes',
          'ui_status',
          'pending_5w2h_fields',
          'five_w_two_h_complete',
          'source_risk_codes',
          'source_label',
        ].join(','),
      )
      .eq('organization_id', organizationId)
      .eq('proposal_origin', 'sparks_suggestion')
      .order('initiative_code', { ascending: true })

    if (error) {
      setRows([])
      setErrorMessage(error.message)
      setLoading(false)
      return
    }

    const nextRows = (data ?? []) as unknown as SuggestedInitiativeRow[]
    setRows(nextRows)
    setNotes((current) => {
      const next = { ...current }
      for (const row of nextRows) {
        if (next[row.initiative_id] === undefined) {
          next[row.initiative_id] = row.suggestion_curation_notes ?? ''
        }
      }
      return next
    })

    setSelectedId((current) => {
      if (
        current &&
        nextRows.some((row) => row.initiative_id === current)
      ) {
        return current
      }
      return nextRows[0]?.initiative_id ?? null
    })

    setLoading(false)
  }, [organizationId])

  useEffect(() => {
    void load()
  }, [load, refreshRequestKey])

  const metrics = useMemo(() => {
    const riskCodes = new Set<string>()
    for (const row of rows) {
      for (const code of row.source_risk_codes ?? []) {
        riskCodes.add(code)
      }
    }

    return {
      total: rows.length,
      pending: rows.filter(
        (row) => row.suggestion_decision === 'pending',
      ).length,
      coveredRisks: riskCodes.size,
      complete5w2h: rows.filter(
        (row) => row.five_w_two_h_complete,
      ).length,
    }
  }, [rows])

  const filteredRows = useMemo(() => {
    const query = searchTerm.trim().toLocaleLowerCase('pt-BR')

    return rows.filter((row) => {
      const matchesDecision =
        decisionFilter === 'all' ||
        row.suggestion_decision === decisionFilter

      if (!matchesDecision) return false
      if (!query) return true

      return [
        row.initiative_code,
        row.initiative_name,
        row.source_label ?? '',
        ...(row.source_risk_codes ?? []),
        displayDecision(row),
      ]
        .join(' ')
        .toLocaleLowerCase('pt-BR')
        .includes(query)
    })
  }, [decisionFilter, rows, searchTerm])

  const gridRows = useMemo<SuggestedInitiativeGridRow[]>(
    () =>
      filteredRows.map((row) => {
        const pendingFields = row.pending_5w2h_fields ?? []

        return {
          id: row.initiative_id,
          code: row.initiative_code,
          initiative: row.initiative_name,
          origin:
            row.source_label ??
            row.proposal_source_reference ??
            'Mitigação de Risco',
          risks: (row.source_risk_codes ?? []).join(' · ') || '—',
          status: displayDecision(row),
          fiveWTwoH: row.five_w_two_h_complete
            ? 'Completo'
            : 'A completar',
          pending:
            pendingFields.length > 0
              ? pendingFields
                  .map((field) => fieldLabel[field] ?? field)
                  .join(' · ')
              : 'Nenhuma',
          decision: displayDecision(row),
        }
      }),
    [filteredRows],
  )

  const selectedRow =
    rows.find((row) => row.initiative_id === selectedId) ?? null

  async function decide(
    row: SuggestedInitiativeRow,
    decision: SuggestionDecision,
  ) {
    if (!canManageInitiatives || busyId) return

    const note = (notes[row.initiative_id] ?? '').trim()

    if (decision !== 'accepted' && !note) {
      setErrorMessage(
        decision === 'rejected'
          ? 'Informe o motivo da rejeição antes de concluir a curadoria.'
          : 'Registre os ajustes esperados antes de aceitar com ajustes.',
      )
      setReviewOpen(true)
      return
    }

    setBusyId(row.initiative_id)
    setErrorMessage('')

    const { data: authData, error: authError } =
      await supabase.auth.getUser()

    if (authError || !authData.user?.id) {
      setErrorMessage(
        authError?.message ??
          'Não foi possível identificar o usuário da decisão.',
      )
      setBusyId(null)
      return
    }

    const { error } = await supabase
      .from('skpe_initiatives')
      .update({
        suggestion_decision: decision,
        suggestion_decided_at: new Date().toISOString(),
        suggestion_decided_by: authData.user.id,
        suggestion_curation_notes: note || null,
      })
      .eq('id', row.initiative_id)

    if (error) {
      setErrorMessage(error.message)
      setBusyId(null)
      return
    }

    await load()
    onRefresh()
    setBusyId(null)
  }

  if (!loading && rows.length === 0 && !errorMessage) return null

  return (
    <section
      id="skpe-suggested-initiatives-drafts"
      className="skpe-suggested-initiatives"
      aria-label="Iniciativas sugeridas pelo SPARKs"
    >
      <div className="skpe-suggested-initiatives__header">
        <div>
          <span className="skpe-suggested-initiatives__eyebrow">
            SPARKs · Curadoria assistida
          </span>
          <h3>Iniciativas sugeridas em Rascunho</h3>
          <p>
            Propostas originadas dos riscos estratégicos. Use o Grid
            governado para localizar, ordenar e revisar as sugestões antes
            de incorporá-las à governança normal do Plano de Ação.
          </p>
        </div>
      </div>

      <div className="skpe-suggested-initiatives__metrics">
        <article>
          <span>Sugestões</span>
          <strong>{metrics.total}</strong>
        </article>
        <article>
          <span>Pendentes de curadoria</span>
          <strong>{metrics.pending}</strong>
        </article>
        <article>
          <span>Riscos cobertos</span>
          <strong>{metrics.coveredRisks}</strong>
        </article>
        <article>
          <span>5W2H completo</span>
          <strong>{metrics.complete5w2h}</strong>
        </article>
      </div>

      <div className="skpe-suggested-initiatives__toolbar">
        <label className="skpe-suggested-initiatives__search">
          <Filter size={16} aria-hidden="true" />
          <input
            value={searchTerm}
            onChange={(event) => setSearchTerm(event.target.value)}
            placeholder="Filtrar por iniciativa, código ou risco..."
          />
          {searchTerm ? (
            <button
              type="button"
              onClick={() => setSearchTerm('')}
              aria-label="Limpar busca"
              title="Limpar busca"
            >
              <X size={15} aria-hidden="true" />
            </button>
          ) : null}
        </label>

        <select
          value={decisionFilter}
          onChange={(event) =>
            setDecisionFilter(event.target.value)
          }
          aria-label="Filtrar situação da curadoria"
        >
          <option value="all">Todas as situações</option>
          <option value="pending">Rascunhos</option>
          <option value="accepted">Aceitas</option>
          <option value="accepted_with_adjustments">
            Aceitas com ajustes
          </option>
          <option value="rejected">Rejeitadas</option>
        </select>
      </div>

      {errorMessage ? (
        <div
          className="skpe-suggested-initiatives__error"
          role="alert"
        >
          {errorMessage}
        </div>
      ) : null}

      {loading ? (
        <div className="skpe-suggested-initiatives__loading">
          Carregando sugestões…
        </div>
      ) : (
        <>
          <div
            className="sparks-user-grid sparks-suggestion-grid"
            data-sparks-grid-shell
          >
            <Willow>
              <Grid
                data={gridRows}
                columns={columns}
                select={true}
                onSelectRow={(event) => {
                  setSelectedId(String(event.id))
                  setReviewOpen(false)
                }}
              />
            </Willow>
            <SparksGridNavigator />
          </div>

          {selectedRow ? (
            <section className="skpe-suggested-initiatives__selection">
              <div className="skpe-suggested-initiatives__selection-main">
                <div>
                  <small>Selecionada</small>
                  <strong>
                    {selectedRow.initiative_code} ·{' '}
                    {selectedRow.initiative_name}
                  </strong>
                </div>

                <div className="skpe-suggested-initiatives__selection-tags">
                  <span>{displayDecision(selectedRow)}</span>
                  {(selectedRow.source_risk_codes ?? []).map(
                    (code) => (
                      <span key={code}>{code}</span>
                    ),
                  )}
                </div>
              </div>

              <div className="skpe-suggested-initiatives__selection-actions">
                <button
                  type="button"
                  onClick={() => setReviewOpen((current) => !current)}
                >
                  {reviewOpen ? 'Fechar revisão' : 'Revisar'}
                </button>
                <button
                  type="button"
                  onClick={() => onReview(selectedRow.initiative_id)}
                >
                  Abrir ficha
                </button>
              </div>

              {reviewOpen ? (
                <div className="skpe-suggested-initiatives__review">
                  <div className="skpe-suggested-initiatives__review-grid">
                    <div>
                      <span>Origem</span>
                      <strong>
                        {selectedRow.source_label ??
                          selectedRow.proposal_source_reference ??
                          'SPARKs'}
                      </strong>
                    </div>
                    <div>
                      <span>Módulo sugeridor</span>
                      <strong>
                        {selectedRow.suggested_by_module ?? 'SK-PE'}
                      </strong>
                    </div>
                    <div>
                      <span>5W2H</span>
                      <strong>
                        {selectedRow.five_w_two_h_complete
                          ? 'Completo'
                          : 'A completar'}
                      </strong>
                    </div>
                  </div>

                  <label className="skpe-suggested-initiatives__notes">
                    <span>Notas de curadoria</span>
                    <textarea
                      value={notes[selectedRow.initiative_id] ?? ''}
                      onChange={(event) =>
                        setNotes((current) => ({
                          ...current,
                          [selectedRow.initiative_id]:
                            event.target.value,
                        }))
                      }
                      disabled={
                        !canManageInitiatives ||
                        selectedRow.suggestion_decision !== 'pending'
                      }
                      rows={3}
                      placeholder="Registre complementações, ajustes esperados ou o motivo de rejeição."
                    />
                  </label>

                  {selectedRow.suggestion_decision === 'pending' ? (
                    <div className="skpe-suggested-initiatives__decision-actions">
                      <button
                        type="button"
                        className="is-accept"
                        disabled={
                          !canManageInitiatives ||
                          busyId === selectedRow.initiative_id
                        }
                        onClick={() =>
                          void decide(selectedRow, 'accepted')
                        }
                      >
                        Aceitar
                      </button>
                      <button
                        type="button"
                        className="is-adjust"
                        disabled={
                          !canManageInitiatives ||
                          busyId === selectedRow.initiative_id
                        }
                        onClick={() =>
                          void decide(
                            selectedRow,
                            'accepted_with_adjustments',
                          )
                        }
                      >
                        Aceitar com ajustes
                      </button>
                      <button
                        type="button"
                        className="is-reject"
                        disabled={
                          !canManageInitiatives ||
                          busyId === selectedRow.initiative_id
                        }
                        onClick={() =>
                          void decide(selectedRow, 'rejected')
                        }
                      >
                        Rejeitar
                      </button>
                    </div>
                  ) : (
                    <div className="skpe-suggested-initiatives__decision-readonly">
                      Decisão registrada:{' '}
                      <strong>{displayDecision(selectedRow)}</strong>
                    </div>
                  )}
                </div>
              ) : null}
            </section>
          ) : null}
        </>
      )}
    </section>
  )
}
