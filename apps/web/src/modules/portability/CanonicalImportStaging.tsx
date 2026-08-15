import { useEffect, useMemo, useRef, useState } from 'react'
import { supabase } from '../../lib/supabase'
import './CanonicalImportStaging.css'

type OrganizationOption = { id: string; code: string; name: string }
type Props = { organizations: OrganizationOption[]; onBackToPortal?: () => void }
type ProjectOption = { id: string; code: string; name: string; status: string }

type PayloadRecord = {
  sourceSheet?: string
  sourceRow?: number
  entityCode?: string
  externalKey?: string
  fingerprint?: string
  qualityStatus?: string
  values?: Record<string, unknown>
}

type CanonicalPayload = {
  schema?: string
  schemaVersion?: string
  sourceFile?: string
  sourceFileFingerprint?: string
  organization?: string
  horizon?: string
  sheetCount?: number
  mappedSheetCount?: number
  totalPayloadRecords?: number
  validPayloadRecords?: number
  quarantinedRecords?: number
  entities?: Array<{ entityCode?: string; entityName?: string; records?: PayloadRecord[] }>
  conflicts?: unknown[]
  journey?: Record<string, unknown>
  databaseWrites?: boolean
  generatedAt?: string
}

type ImportBatchListItem = {
  id: string
  schema_version?: string
  source_file?: string
  source_file_fingerprint?: string
  declared_record_count?: number
  staged_record_count?: number
  valid_record_count?: number
  quarantined_record_count?: number
  blocked_record_count?: number
  conflict_count?: number
  status?: string
  created_at?: string
  staged_at?: string
}

type ReadinessGate = { code: string; label: string; passed: boolean; actual?: unknown; required?: unknown; total?: number }
type ReadinessBlockedRecord = { id?: string; entityCode?: string; externalKey?: string; simulationStatus?: string; proposedAction?: string; sourceSheet?: string; sourceRow?: string; validationMessages?: unknown[] }
type ReadinessAssessment = {
  batchId?: string
  assessedAt?: string
  readinessState?: 'ready' | 'blocked'
  readyForDefinitiveLoad?: boolean
  gates?: ReadinessGate[]
  counts?: Record<string, number>
  blockedRecords?: ReadinessBlockedRecord[]
  conflicts?: Array<Record<string, unknown>>
  protections?: Record<string, unknown>
}


type BlockedReview = {
  batchId?: string
  recordId?: string
  entityCode?: string
  externalKey?: string
  sourceSheet?: string
  sourceRow?: number
  currentValues?: Record<string, unknown>
  suggestedValues?: Record<string, unknown>
  validationMessages?: unknown[]
  requiresHumanConfirmation?: boolean
  inferenceNotice?: string
}

type BatchSummary = {
  batch?: ImportBatchListItem
  bySimulationStatus?: Record<string, number>
  byEntity?: Array<{ entity_code: string; total: number; blocked: number; quarantined: number }>
  conflicts?: Array<{ conflict_code: string; severity: string; topic: string; status: string }>
}

function readJsonFile(file: File) {
  return file.text().then((text) => JSON.parse(text) as CanonicalPayload)
}

function countEntityRecords(payload: CanonicalPayload) {
  return (payload.entities ?? []).reduce((total, entity) => total + (entity.records?.length ?? 0), 0)
}

function formatDate(value?: string) {
  if (!value) return '—'
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? value : date.toLocaleString('pt-BR')
}

export function CanonicalImportStaging({ organizations, onBackToPortal }: Props) {
  const [organizationId, setOrganizationId] = useState('')
  const [projectId, setProjectId] = useState('')
  const [projects, setProjects] = useState<ProjectOption[]>([])
  const [payload, setPayload] = useState<CanonicalPayload | null>(null)
  const [fileName, setFileName] = useState('')
  const [batchId, setBatchId] = useState('')
  const [summary, setSummary] = useState<BatchSummary | null>(null)
  const [existingBatches, setExistingBatches] = useState<ImportBatchListItem[]>([])
  const [loadingProjects, setLoadingProjects] = useState(false)
  const [loadingBatches, setLoadingBatches] = useState(false)
  const [openingBatchId, setOpeningBatchId] = useState('')
  const [staging, setStaging] = useState(false)
  const [cancelling, setCancelling] = useState(false)
  const [refreshing, setRefreshing] = useState(false)
  const [simulating, setSimulating] = useState(false)
  const [assessingReadiness, setAssessingReadiness] = useState(false)
  const [readiness, setReadiness] = useState<ReadinessAssessment | null>(null)
  const [blockedReview, setBlockedReview] = useState<BlockedReview | null>(null)
  const [correctedValuesText, setCorrectedValuesText] = useState('')
  const [reviewNotes, setReviewNotes] = useState('')
  const [loadingBlockedReview, setLoadingBlockedReview] = useState(false)
  const [approvingCorrection, setApprovingCorrection] = useState(false)
  const [conflictNotes, setConflictNotes] = useState('')
  const [resolvingConflicts, setResolvingConflicts] = useState(false)
  const [message, setMessage] = useState('')
  const [messageType, setMessageType] = useState<'success' | 'error' | 'info'>('info')
  const blockedReviewRef = useRef<HTMLDivElement | null>(null)

  const selectedOrganization = useMemo(
    () => organizations.find((item) => item.id === organizationId),
    [organizations, organizationId],
  )

  useEffect(() => {
    setProjectId('')
    setProjects([])
    setPayload(null)
    setFileName('')
    setBatchId('')
    setSummary(null)
    setReadiness(null)
    setExistingBatches([])
    if (!organizationId) return

    const loadProjects = async () => {
      setLoadingProjects(true)
      const { data, error } = await supabase
        .from('skpe_projects')
        .select('id, code, name, status')
        .eq('organization_id', organizationId)
        .is('archived_at', null)
        .order('name', { ascending: true })

      if (error) {
        setMessage(`Não foi possível carregar os projetos: ${error.message}`)
        setMessageType('error')
      } else {
        const rows = (data ?? []) as ProjectOption[]
        setProjects(rows)
        if (rows.length === 1) setProjectId(rows[0].id)
      }
      setLoadingProjects(false)
    }

    void loadProjects()
  }, [organizationId])

  const loadExistingBatches = async (showFeedback = false) => {
    if (!organizationId || !projectId) return
    setLoadingBatches(true)
    const { data, error } = await supabase.rpc('skpe_list_import_batches', {
      p_organization_id: organizationId,
      p_project_id: projectId,
      p_limit: 20,
    })

    if (error) {
      setExistingBatches([])
      setMessage(`Não foi possível listar os lotes existentes: ${error.message}`)
      setMessageType('error')
    } else {
      setExistingBatches(Array.isArray(data) ? (data as ImportBatchListItem[]) : [])
      if (showFeedback) {
        setMessage('Lista de lotes atualizada.')
        setMessageType('success')
      }
    }
    setLoadingBatches(false)
  }

  useEffect(() => {
    setPayload(null)
    setFileName('')
    setBatchId('')
    setSummary(null)
    setReadiness(null)
    setExistingBatches([])
    if (organizationId && projectId) void loadExistingBatches()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [organizationId, projectId])

  const openBlockedReview = async (externalKey: string) => {
    if (!batchId) return
    setLoadingBlockedReview(true)
    try {
      const { data, error } = await supabase.rpc('skpe_get_blocked_import_record_review', {
        p_batch_id: batchId,
        p_external_key: externalKey,
      })
      if (error) throw error
      const review = (data ?? null) as BlockedReview | null
      setBlockedReview(review)
      setCorrectedValuesText(JSON.stringify(review?.suggestedValues ?? {}, null, 2))
      window.setTimeout(() => blockedReviewRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' }), 80)
      setReviewNotes('Correção assistida dos campos deslocados na linha de controle de versões, validada com base no padrão das versões anteriores e no arquivo-fonte v17.')
      setMessage('Proposta de correção carregada. Revise todos os campos antes de confirmar.')
      setMessageType('info')
    } catch (error) {
      setMessage(error instanceof Error ? `Não foi possível abrir a revisão: ${error.message}` : 'Não foi possível abrir a revisão.')
      setMessageType('error')
    } finally {
      setLoadingBlockedReview(false)
    }
  }

  const approveBlockedCorrection = async () => {
    if (!batchId || !blockedReview?.externalKey) return
    let correctedValues: Record<string, unknown>
    try {
      correctedValues = JSON.parse(correctedValuesText) as Record<string, unknown>
    } catch {
      setMessage('Os valores corrigidos não formam um JSON válido.')
      setMessageType('error')
      return
    }
    if (!window.confirm('Confirma que revisou os campos e aprova esta correção manual? A carga definitiva ainda não será executada.')) return
    setApprovingCorrection(true)
    try {
      const { error } = await supabase.rpc('skpe_approve_blocked_import_record_correction', {
        p_batch_id: batchId,
        p_external_key: blockedReview.externalKey,
        p_corrected_values: correctedValues,
        p_review_notes: reviewNotes,
        p_confirm: true,
      })
      if (error) throw error
      setBlockedReview(null)
      setCorrectedValuesText('')
      setReviewNotes('')
      await loadSummary(batchId)
      const { data: readinessData, error: readinessError } = await supabase.rpc('skpe_assess_import_batch_readiness', { p_batch_id: batchId })
      if (readinessError) throw readinessError
      setReadiness((readinessData ?? null) as ReadinessAssessment | null)
      setMessage('Correção aprovada. O lote foi reavaliado sem executar carga definitiva.')
      setMessageType('success')
    } catch (error) {
      setMessage(error instanceof Error ? `Não foi possível aprovar a correção: ${error.message}` : 'Não foi possível aprovar a correção.')
      setMessageType('error')
    } finally {
      setApprovingCorrection(false)
    }
  }

  const validatePayload = (candidate: CanonicalPayload) => {
    const errors: string[] = []
    if (candidate.schema !== 'SPARKS_PE_CANONICAL_IMPORT_PREVIEW') errors.push('Schema incompatível.')
    if (candidate.schemaVersion !== '2.0.1') errors.push('A versão aceita nesta etapa é 2.0.1.')
    if (!candidate.sourceFileFingerprint) errors.push('Fingerprint do arquivo não informado.')
    if (!Array.isArray(candidate.entities)) errors.push('Coleção de entidades ausente.')
    if (!Array.isArray(candidate.conflicts)) errors.push('Coleção de conflitos ausente.')
    if (candidate.databaseWrites === true) errors.push('O payload informa gravações anteriores e foi bloqueado.')
    if (selectedOrganization && candidate.organization?.toLocaleUpperCase('pt-BR') !== selectedOrganization.code.toLocaleUpperCase('pt-BR')) {
      errors.push(`O payload pertence a ${candidate.organization ?? 'organização não informada'}, não a ${selectedOrganization.code}.`)
    }
    const counted = countEntityRecords(candidate)
    if (candidate.validPayloadRecords != null && counted !== candidate.validPayloadRecords) {
      errors.push(`A coleção principal contém ${counted} registros, mas o payload declara ${candidate.validPayloadRecords} válidos.`)
    }
    return errors
  }

  const selectPayload = async (file: File | undefined) => {
    if (!file) return
    if (!selectedOrganization || !projectId) {
      setMessage('Selecione a organização e o projeto antes do JSON.')
      setMessageType('error')
      return
    }

    try {
      const candidate = await readJsonFile(file)
      const errors = validatePayload(candidate)
      if (errors.length > 0) {
        setPayload(null)
        setFileName(file.name)
        setMessage(errors.join(' '))
        setMessageType('error')
        return
      }
      setPayload(candidate)
      setFileName(file.name)
      setBatchId('')
      setSummary(null)
      setMessage('Payload validado localmente. Nenhuma gravação foi realizada.')
      setMessageType('success')
    } catch (error) {
      setPayload(null)
      setMessage(error instanceof Error ? `JSON inválido: ${error.message}` : 'Não foi possível ler o JSON.')
      setMessageType('error')
    }
  }

  const loadSummary = async (id: string, showFeedback = false) => {
    if (showFeedback) setRefreshing(true)
    try {
      const { data, error } = await supabase.rpc('skpe_get_import_batch_summary', { p_batch_id: id })
      if (error) throw error
      setSummary((data ?? null) as BatchSummary | null)
      if (showFeedback) {
        setMessage('Resumo atualizado com sucesso.')
        setMessageType('success')
      }
    } catch (error) {
      setMessage(error instanceof Error ? `Não foi possível carregar o resumo: ${error.message}` : 'Não foi possível carregar o resumo.')
      setMessageType('error')
      throw error
    } finally {
      if (showFeedback) setRefreshing(false)
    }
  }

  const openExistingBatch = async (id: string) => {
    setOpeningBatchId(id)
    setPayload(null)
    setFileName('')
    try {
      await loadSummary(id)
      const { data: readinessData, error: readinessError } = await supabase.rpc(
        'skpe_assess_import_batch_readiness',
        { p_batch_id: id },
      )
      if (readinessError) throw readinessError
      const assessment = (readinessData ?? null) as ReadinessAssessment | null
      setBatchId(id)
      setReadiness(assessment)
      window.localStorage.setItem(`skpe.import.batch.${organizationId}.${projectId}`, id)
      setMessage(assessment?.readyForDefinitiveLoad
        ? 'Lote retomado e avaliado. Nenhuma carga definitiva foi executada.'
        : 'Lote retomado. Consulte abaixo os impedimentos e conflitos identificados.')
      setMessageType(assessment?.readyForDefinitiveLoad ? 'success' : 'info')
    } catch (error) {
      setBatchId('')
      setReadiness(null)
      setMessage(error instanceof Error
        ? `Não foi possível retomar e avaliar o lote: ${error.message}`
        : 'Não foi possível retomar e avaliar o lote.')
      setMessageType('error')
    } finally {
      setOpeningBatchId('')
    }
  }

  useEffect(() => {
    if (!organizationId || !projectId || batchId || existingBatches.length === 0) return
    const saved = window.localStorage.getItem(`skpe.import.batch.${organizationId}.${projectId}`)
    if (saved && existingBatches.some((item) => item.id === saved)) void openExistingBatch(saved)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [existingBatches])

  const simulateBatch = async () => {
    if (!batchId) return
    setSimulating(true)
    setMessage('Executando a simulação comparativa do lote...')
    setMessageType('info')
    const { data, error } = await supabase.rpc('skpe_simulate_import_batch', { p_batch_id: batchId })
    if (error) {
      setMessage(`Não foi possível simular o lote: ${error.message}`)
      setMessageType('error')
    } else {
      setSummary((data ?? null) as BatchSummary | null)
      setReadiness(null)
      await loadExistingBatches()
      setMessage('Simulação concluída. Nenhuma tabela estratégica definitiva foi alterada.')
      setMessageType('success')
    }
    setSimulating(false)
  }


  const assessBatchReadiness = async () => {
    if (!batchId) return
    setAssessingReadiness(true)
    setMessage('Avaliando bloqueios, conflitos e critérios de prontidão...')
    setMessageType('info')
    const { data, error } = await supabase.rpc('skpe_assess_import_batch_readiness', { p_batch_id: batchId })
    if (error) {
      setMessage(`Não foi possível avaliar a prontidão: ${error.message}`)
      setMessageType('error')
    } else {
      const assessment = (data ?? null) as ReadinessAssessment | null
      setReadiness(assessment)
      setMessage(assessment?.readyForDefinitiveLoad
        ? 'Avaliação concluída: lote tecnicamente apto para a próxima decisão de governança.'
        : 'Avaliação concluída: a carga definitiva permanece bloqueada até o tratamento dos impedimentos.')
      setMessageType(assessment?.readyForDefinitiveLoad ? 'success' : 'info')
    }
    setAssessingReadiness(false)
  }

  const stagePayload = async () => {
    if (!payload || !organizationId || !projectId) return
    setStaging(true)
    setMessage('Enviando o payload para a área segura de staging...')
    setMessageType('info')

    const { data, error } = await supabase.rpc('skpe_stage_canonical_import', {
      p_organization_id: organizationId,
      p_project_id: projectId,
      p_payload: payload,
    })

    if (error) {
      setMessage(`Não foi possível criar o lote: ${error.message}`)
      setMessageType('error')
      setStaging(false)
      return
    }

    const id = String(data)
    setBatchId(id)
    window.localStorage.setItem(`skpe.import.batch.${organizationId}.${projectId}`, id)
    try {
      await loadSummary(id)
      await loadExistingBatches()
      setMessage('Lote criado em staging. Nenhuma tabela estratégica definitiva foi alterada.')
      setMessageType('success')
    } catch {
      // loadSummary já exibiu a mensagem correspondente.
    }
    setStaging(false)
  }

  const cancelBatch = async () => {
    if (!batchId) return
    const reason = window.prompt('Informe a justificativa do cancelamento do lote:')?.trim()
    if (!reason) return
    setCancelling(true)
    const { error } = await supabase.rpc('skpe_cancel_import_batch', { p_batch_id: batchId, p_reason: reason })
    if (error) {
      setMessage(`Não foi possível cancelar o lote: ${error.message}`)
      setMessageType('error')
    } else {
      await loadSummary(batchId)
      await loadExistingBatches()
      setMessage('Lote cancelado. Os registros de staging foram preservados para auditoria.')
      setMessageType('success')
    }
    setCancelling(false)
  }

  const closeBatch = () => {
    setBatchId('')
    setSummary(null)
    setReadiness(null)
    setPayload(null)
    setFileName('')
    window.localStorage.removeItem(`skpe.import.batch.${organizationId}.${projectId}`)
    setMessage('Lote fechado na tela. Ele permanece preservado no Supabase.')
    setMessageType('info')
  }

  const batch = summary?.batch
  const canStage = Boolean(payload && organizationId && projectId && !batchId)

  const resolveCanonicalConflicts = async () => {
    if (!batchId || !conflictNotes.trim()) return
    setResolvingConflicts(true)
    const { error } = await supabase.rpc('skpe_resolve_import_conflicts_accept_canonical', {
      p_batch_id: batchId,
      p_notes: conflictNotes.trim(),
    })

    if (error) {
      setMessage(`Não foi possível tratar os conflitos: ${error.message}`)
      setMessageType('error')
      setResolvingConflicts(false)
      return
    }

    setMessage('Os conflitos foram tratados com preservação do valor canônico. Reavaliando a prontidão...')
    setMessageType('success')
    setConflictNotes('')
    await loadSummary(batchId)
    await assessBatchReadiness()
    setResolvingConflicts(false)
  }

  const handleBackToPortal = () => {
    if (onBackToPortal) {
      onBackToPortal()
      return
    }
    window.history.back()
  }

  return (
    <section className="canonical-staging" aria-labelledby="canonical-staging-title">
      <div className="canonical-staging-navigation">
        <button type="button" className="back-to-portal" onClick={handleBackToPortal} aria-label="Voltar ao Portal da Plataforma" title="Voltar ao Portal da Plataforma">
          <span aria-hidden="true">‹</span>
        </button>
      </div>
      <div className="canonical-staging-heading">
        <div>
          <p>Bloco 1.10B-6</p>
          <h3 id="canonical-staging-title">Tratamento assistido de conflitos e prontidão</h3>
          <span>O lote é avaliado antes de qualquer carga definitiva. A jornada estratégica permanece protegida.</span>
        </div>
        <span className="staging-badge">Sem carga definitiva</span>
      </div>

      <div className="canonical-staging-controls">
        <label>
          Organização
          <select value={organizationId} onChange={(event) => setOrganizationId(event.target.value)} disabled={Boolean(batchId)}>
            <option value="">Selecione</option>
            {organizations.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}
          </select>
        </label>
        <label>
          Projeto de Planejamento Estratégico
          <select value={projectId} onChange={(event) => setProjectId(event.target.value)} disabled={!organizationId || loadingProjects || Boolean(batchId)}>
            <option value="">{loadingProjects ? 'Carregando...' : 'Selecione'}</option>
            {projects.map((item) => <option key={item.id} value={item.id}>{item.code} — {item.name}</option>)}
          </select>
        </label>
        <label className="canonical-staging-file">
          Payload JSON 2.0.1
          <input type="file" accept=".json,application/json" disabled={!projectId || Boolean(batchId)} onChange={(event) => void selectPayload(event.target.files?.[0])} />
        </label>
      </div>

      {message && <div className={`canonical-staging-message ${messageType}`}>{message}</div>}

      {organizationId && projectId && !batchId && (
        <div className="canonical-existing-batches">
          <div className="canonical-existing-batches-title">
            <div>
              <small>Recuperação</small>
              <h4>Lotes de importação existentes</h4>
            </div>
            <button type="button" className="refresh-list" onClick={() => void loadExistingBatches(true)} disabled={loadingBatches}>
              {loadingBatches ? 'Atualizando...' : 'Atualizar lista'}
            </button>
          </div>

          {loadingBatches && existingBatches.length === 0 ? (
            <p className="canonical-empty-state">Carregando lotes...</p>
          ) : existingBatches.length === 0 ? (
            <p className="canonical-empty-state">Nenhum lote de importação foi localizado para este projeto.</p>
          ) : (
            <div className="canonical-batch-table-wrap">
              <table className="canonical-existing-batches-table">
                <thead>
                  <tr><th>Arquivo</th><th>Versão</th><th>Status</th><th>Válidos</th><th>Bloqueados</th><th>Conflitos</th><th>Criado em</th><th>Ação</th></tr>
                </thead>
                <tbody>
                  {existingBatches.map((item) => (
                    <tr key={item.id}>
                      <td><strong>{item.source_file ?? '—'}</strong><small>{item.id}</small></td>
                      <td>{item.schema_version ?? '—'}</td>
                      <td><span className={`batch-status ${item.status ?? ''}`}>{item.status ?? '—'}</span></td>
                      <td>{item.valid_record_count ?? 0}</td>
                      <td>{item.blocked_record_count ?? 0}</td>
                      <td>{item.conflict_count ?? 0}</td>
                      <td>{formatDate(item.created_at)}</td>
                      <td>
                        <button type="button" className="open-batch" onClick={() => void openExistingBatch(item.id)} disabled={Boolean(openingBatchId)}>
                          {openingBatchId === item.id ? 'Abrindo...' : 'Retomar lote'}
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {payload && !batchId && (
        <div className="canonical-staging-review">
          <div className="canonical-staging-kpis">
            <article><small>Arquivo</small><strong>{fileName}</strong></article>
            <article><small>Registros válidos</small><strong>{payload.validPayloadRecords ?? countEntityRecords(payload)}</strong></article>
            <article><small>Quarentena</small><strong>{payload.quarantinedRecords ?? 0}</strong></article>
            <article><small>Conflitos</small><strong>{payload.conflicts?.length ?? 0}</strong></article>
          </div>
          <div className="canonical-staging-actions">
            <button type="button" onClick={() => void stagePayload()} disabled={!canStage || staging}>
              {staging ? 'Preparando lote...' : 'Criar lote em staging'}
            </button>
          </div>
        </div>
      )}

      {batch && (
        <div className="canonical-batch-summary">
          <div className="canonical-batch-title">
            <div><small>Lote retomado</small><h4>{batch.id}</h4><span>{batch.source_file ?? 'Arquivo não informado'}</span></div>
            <span className={`batch-status ${batch.status ?? ''}`}>{batch.status ?? '—'}</span>
          </div>
          <div className="canonical-staging-kpis compact">
            <article><small>Recebidos</small><strong>{batch.staged_record_count ?? 0}</strong></article>
            <article><small>Válidos</small><strong>{batch.valid_record_count ?? 0}</strong></article>
            <article><small>Quarentena</small><strong>{batch.quarantined_record_count ?? 0}</strong></article>
            <article><small>Bloqueados</small><strong>{batch.blocked_record_count ?? 0}</strong></article>
            <article><small>Conflitos</small><strong>{batch.conflict_count ?? 0}</strong></article>
          </div>

          <details open>
            <summary>Resumo por entidade</summary>
            <div className="canonical-batch-table-wrap">
              <table>
                <thead><tr><th>Entidade</th><th>Total</th><th>Bloqueados</th><th>Quarentena</th></tr></thead>
                <tbody>{(summary?.byEntity ?? []).map((item) => (
                  <tr key={item.entity_code}><td>{item.entity_code}</td><td>{item.total}</td><td>{item.blocked}</td><td>{item.quarantined}</td></tr>
                ))}</tbody>
              </table>
            </div>
          </details>

          {summary?.bySimulationStatus && (
            <div className="canonical-simulation-kpis">
              <article><small>Novos</small><strong>{summary.bySimulationStatus.new ?? 0}</strong></article>
              <article><small>Atualizações</small><strong>{summary.bySimulationStatus.update ?? 0}</strong></article>
              <article><small>Sem alteração</small><strong>{summary.bySimulationStatus.unchanged ?? 0}</strong></article>
              <article><small>Pendentes</small><strong>{summary.bySimulationStatus.pending_mapping ?? 0}</strong></article>
            </div>
          )}

          {readiness && (
            <div className={`canonical-readiness ${readiness.readyForDefinitiveLoad ? 'ready' : 'blocked'}`}>
              <div className="canonical-readiness-heading">
                <div>
                  <small>Avaliação formal</small>
                  <h4>{readiness.readyForDefinitiveLoad ? 'Lote tecnicamente apto' : 'Carga definitiva bloqueada'}</h4>
                </div>
                <span>{readiness.readinessState ?? '—'}</span>
              </div>
              <div className="canonical-readiness-gates">
                {(readiness.gates ?? []).map((gate) => (
                  <article key={gate.code} className={gate.passed ? 'passed' : 'failed'}>
                    <strong>{gate.passed ? '✓' : '!'}</strong>
                    <div><small>{gate.code}</small><span>{gate.label}</span><em>Atual: {String(gate.actual ?? '—')} · Exigido: {String(gate.required ?? '—')}</em></div>
                  </article>
                ))}
              </div>
              {(readiness.blockedRecords ?? []).length > 0 && (
                <details open>
                  <summary>Registros que impedem a prontidão</summary>
                  <div className="canonical-batch-table-wrap">
                    <table>
                      <thead><tr><th>Entidade</th><th>Chave externa</th><th>Situação</th><th>Origem</th><th>Mensagens</th><th>Ação</th></tr></thead>
                      <tbody>{(readiness.blockedRecords ?? []).map((item, index) => (
                        <tr key={item.id ?? `${item.externalKey}-${index}`}>
                          <td>{item.entityCode ?? '—'}</td>
                          <td><strong>{item.externalKey ?? '—'}</strong></td>
                          <td>{item.simulationStatus ?? '—'}</td>
                          <td>{item.sourceSheet ?? '—'}{item.sourceRow ? ` · linha ${item.sourceRow}` : ''}</td>
                          <td><code>{JSON.stringify(item.validationMessages ?? [])}</code></td>
                          <td><button type="button" className="review-blocked" onClick={() => void openBlockedReview(item.externalKey ?? '')} disabled={loadingBlockedReview}>{loadingBlockedReview ? 'Abrindo...' : 'Revisar e corrigir'}</button></td>
                        </tr>
                      ))}</tbody>
                    </table>
                  </div>
                </details>
              )}

              {(readiness.conflicts ?? []).length > 0 && (
                <details className="canonical-conflict-review" open>
                  <summary>Tratamento assistido dos conflitos ({readiness.conflicts?.length ?? 0})</summary>
                  <p>Todos os conflitos deste lote vieram com a decisão proposta <strong>accept_canonical</strong>. A confirmação abaixo preserva o estado canônico já validado e registra usuário, data e justificativa.</p>
                  <div className="canonical-conflict-grid">
                    {(readiness.conflicts ?? []).map((conflict, index) => (
                      <article key={String(conflict.id ?? conflict.conflict_code ?? index)}>
                        <div>
                          <small>{String(conflict.conflict_code ?? `CONFLITO-${index + 1}`)}</small>
                          <strong>{String(conflict.topic ?? 'Conflito de reconciliação')}</strong>
                        </div>
                        <dl>
                          <div><dt>Origem A</dt><dd>{String(conflict.source_a ?? '—')}</dd></div>
                          <div><dt>Valor A</dt><dd>{String(conflict.value_a ?? '—')}</dd></div>
                          <div><dt>Origem B</dt><dd>{String(conflict.source_b ?? '—')}</dd></div>
                          <div><dt>Valor B</dt><dd>{String(conflict.value_b ?? '—')}</dd></div>
                          <div><dt>Valor canônico</dt><dd>{String(conflict.canonical_value ?? '—')}</dd></div>
                          <div><dt>Decisão proposta</dt><dd>{String(conflict.proposed_decision ?? '—')}</dd></div>
                          <div><dt>Situação</dt><dd>{String(conflict.status ?? '—')}</dd></div>
                        </dl>
                      </article>
                    ))}
                  </div>
                  {(readiness.counts?.unresolvedConflicts ?? 0) > 0 && (
                    <div className="canonical-conflict-confirmation">
                      <label>
                        <span>Justificativa da decisão</span>
                        <textarea
                          value={conflictNotes}
                          onChange={(event) => setConflictNotes(event.target.value)}
                          placeholder="Ex.: Confirmo a preservação dos valores canônicos já validados e a decisão accept_canonical para os seis conflitos de reconciliação."
                        />
                      </label>
                      <button
                        type="button"
                        className="canonical-confirm-conflicts-button"
                        onClick={() => void resolveCanonicalConflicts()}
                        disabled={resolvingConflicts || !conflictNotes.trim()}
                      >
                        {resolvingConflicts ? 'Registrando decisão...' : 'Confirmar tratamento dos conflitos'}
                      </button>
                    </div>
                  )}
                  {(readiness.counts?.unresolvedConflicts ?? 0) === 0 && (
                    <p className="canonical-conflicts-resolved">✓ Conflitos formalmente tratados.</p>
                  )}
                </details>
              )}

              {blockedReview && (
                <div className="canonical-blocked-review" ref={blockedReviewRef}>
                  <div className="canonical-blocked-review-heading">
                    <div><small>Revisão humana obrigatória</small><h4>{blockedReview.externalKey}</h4></div>
                    <button type="button" className="neutral" onClick={() => setBlockedReview(null)}>Fechar revisão</button>
                  </div>
                  <p>{blockedReview.inferenceNotice}</p>
                  <div className="canonical-review-origin"><strong>Origem:</strong> {blockedReview.sourceSheet} · linha {blockedReview.sourceRow ?? '—'}</div>
                  <div className="canonical-review-columns">
                    <label><span>Valores recebidos</span><textarea readOnly value={JSON.stringify(blockedReview.currentValues ?? {}, null, 2)} /></label>
                    <label><span>Valores corrigidos propostos</span><textarea value={correctedValuesText} onChange={(event) => setCorrectedValuesText(event.target.value)} /></label>
                  </div>
                  <label className="canonical-review-notes"><span>Justificativa da validação</span><textarea value={reviewNotes} onChange={(event) => setReviewNotes(event.target.value)} /></label>
                  <div className="canonical-staging-actions secondary">
                    <button type="button" className="readiness" onClick={() => void approveBlockedCorrection()} disabled={approvingCorrection || !reviewNotes.trim()}>{approvingCorrection ? 'Confirmando...' : 'Confirmar correção revisada'}</button>
                  </div>
                  <p className="canonical-readiness-note">A confirmação altera somente o registro no staging, registra auditoria e reavalia a prontidão. Nenhuma tabela estratégica definitiva é atualizada.</p>
                </div>
              )}
              <p className="canonical-readiness-note">Esta avaliação não executa carga definitiva, não reabre a Macrofase 1 e não libera o PEM-02.04.</p>
            </div>
          )}

          <div className="canonical-staging-actions secondary">
            {batch.status === 'reviewed' && (
              <button type="button" className="readiness" onClick={() => void assessBatchReadiness()} disabled={assessingReadiness || simulating || refreshing}>
                {assessingReadiness ? 'Avaliando prontidão...' : 'Avaliar prontidão para carga'}
              </button>
            )}
            {['staged', 'reviewed'].includes(batch.status ?? '') && (
              <button type="button" className="simulate" onClick={() => void simulateBatch()} disabled={simulating || refreshing}>
                {simulating ? 'Simulando...' : batch.status === 'reviewed' ? 'Executar simulação novamente' : 'Executar simulação comparativa'}
              </button>
            )}
            <button type="button" className="refresh" onClick={() => void loadSummary(batchId, true)} disabled={refreshing || simulating}>
              {refreshing ? 'Atualizando...' : 'Atualizar resumo'}
            </button>
            <button type="button" className="neutral" onClick={closeBatch} disabled={simulating || refreshing || cancelling}>Fechar lote na tela</button>
            {!['cancelled', 'applied', 'rolled_back'].includes(batch.status ?? '') && (
              <button type="button" className="danger" onClick={() => void cancelBatch()} disabled={cancelling || simulating}>
                {cancelling ? 'Cancelando...' : 'Cancelar lote'}
              </button>
            )}
          </div>
        </div>
      )}
    </section>
  )
}
