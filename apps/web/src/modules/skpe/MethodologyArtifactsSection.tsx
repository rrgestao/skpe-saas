import { type ChangeEvent, type KeyboardEvent, useEffect, useMemo, useState } from 'react'
import { supabase } from '../../lib/supabase'

import { artifactTypeLabelPtBr, eventLabelPtBr, statusLabelPtBr, translateBackendMessage } from '../../shared/i18n/ptBR'
import { DeliveryKitDialog } from './DeliveryKitDialog'
import './MethodologyArtifactsSection.css'

type Props = {
  organizationId: string
  projectId: string
  canManage: boolean
  canGenerateDeliveryKit: boolean
}

type CatalogItem = {
  artifact_type_id: string
  artifact_type_code: string
  artifact_type_name: string
  category: string
  description: string | null
  default_file_extensions: string[]
  requires_validation: boolean
  export_folder: string
  sort_order: number
}

type Requirement = {
  requirement_id: string
  requirement_code: string
  requirement_name: string
  requirement_description: string | null
  artifact_type_code: string
  artifact_type_name: string
  mandatory: boolean
  minimum_quantity: number
  validation_required: boolean
  blocks_closure: boolean
  sort_order: number
}

type Artifact = {
  artifact_id: string
  artifact_code: string
  artifact_type_code: string
  artifact_type_name: string
  category: string
  title: string
  purpose: string | null
  metafase_code: string | null
  macrophase_code: string | null
  phase_code: string | null
  stage_code: string | null
  gate_code: string | null
  status: string
  current_version_number: number
  responsible_user_id: string | null
  approver_user_id: string | null
  planned_due_date: string | null
  submitted_at: string | null
  validated_at: string | null
  created_at: string
  updated_at: string
}

type GateRow = {
  requirement_id: string
  requirement_code: string
  requirement_name: string
  artifact_type_code: string
  mandatory: boolean
  minimum_quantity: number
  produced_quantity: number
  validated_quantity: number
  requirement_status: string
  blocks_closure: boolean
}

type ArtifactDetail = {
  artifact: Record<string, unknown>
  versions: Array<Record<string, unknown>>
  validations: Array<Record<string, unknown>>
  evidence_links: Array<Record<string, unknown>>
  audit: Array<Record<string, unknown>>
}

type ViewMode = 'cards' | 'grid' | 'journey'
type MainTab = 'artifacts' | 'readiness' | 'audit'

const statusLabel: Record<string, string> = {
  planned: 'Previsto',
  in_preparation: 'Em elaboração',
  in_review: 'Em revisão',
  submitted: 'Submetido à validação',
  validated: 'Validado',
  validated_with_reservations: 'Validado com ressalvas',
  rejected: 'Rejeitado',
  superseded: 'Substituído',
  archived: 'Arquivado',
  waived: 'Dispensado',
  pending: 'Pendente',
  partial: 'Parcial',
  awaiting_validation: 'Aguardando validação',
  satisfied: 'Atendido',
}

const activate = (event: KeyboardEvent<HTMLElement>, action: () => void) => {
  if (event.key === 'Enter' || event.key === ' ') {
    event.preventDefault()
    action()
  }
}

const formatDate = (value: string | null | undefined) => {
  if (!value) return '—'
  return new Intl.DateTimeFormat('pt-BR').format(new Date(value))
}

const safeName = (value: string) => value.normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-zA-Z0-9._-]+/g, '_')

export function MethodologyArtifactsSection({ organizationId, projectId, canManage, canGenerateDeliveryKit }: Props) {
  const [catalog, setCatalog] = useState<CatalogItem[]>([])
  const [requirements, setRequirements] = useState<Requirement[]>([])
  const [artifacts, setArtifacts] = useState<Artifact[]>([])
  const [readiness, setReadiness] = useState<GateRow[]>([])
  const [audit, setAudit] = useState<Array<Record<string, unknown>>>([])
  const [selected, setSelected] = useState<Artifact | null>(null)
  const [detail, setDetail] = useState<ArtifactDetail | null>(null)
  const [tab, setTab] = useState<MainTab>('artifacts')
  const [viewMode, setViewMode] = useState<ViewMode>('cards')
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('')
  const [phaseFilter, setPhaseFilter] = useState('')
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [message, setMessage] = useState('')
  const [showCreate, setShowCreate] = useState(false)
  const [showVersion, setShowVersion] = useState(false)
  const [showValidation, setShowValidation] = useState(false)

  const [showDeliveryKit, setShowDeliveryKit] = useState(false)
  const [form, setForm] = useState({
    typeCode: '', title: '', purpose: '', metafase: '', macrophase: '', phase: '', stage: '', gate: '', requirementCode: '', dueDate: '',
  })
  const [versionForm, setVersionForm] = useState({ content: '', summary: '', generatedByAi: false, prompt: '', model: '' })
  const [validationForm, setValidationForm] = useState({ status: 'submitted', type: 'executive', decision: '', reservations: '', conditions: '', meeting: '' })
  const [file, setFile] = useState<File | null>(null)

  const loadAll = async () => {
    if (!projectId) return
    setLoading(true)
    setMessage('')
    const [catalogResult, requirementResult, artifactResult, readinessResult, auditResult] = await Promise.all([
      supabase.rpc('get_methodology_artifact_catalog'),
      supabase.rpc('get_methodology_delivery_requirements', {
        target_methodology_version: '1.0.0', target_metafase_code: null, target_macrophase_code: null, target_phase_code: null, target_gate_code: null,
      }),
      supabase.rpc('get_project_methodology_artifacts', {
        target_organization_id: organizationId, target_project_id: projectId, target_status: null, target_phase_code: null,
      }),
      supabase.rpc('get_methodology_gate_readiness', {
        target_organization_id: organizationId, target_project_id: projectId, target_methodology_version: '1.0.0', target_metafase_code: null, target_macrophase_code: null, target_phase_code: null, target_gate_code: null,
      }),
      supabase.rpc('get_methodology_artifact_audit', { target_organization_id: organizationId, target_project_id: projectId }),
    ])
    const error = catalogResult.error ?? requirementResult.error ?? artifactResult.error ?? readinessResult.error ?? auditResult.error
    if (error) setMessage(translateBackendMessage(error.message))
    setCatalog((catalogResult.data ?? []) as CatalogItem[])
    setRequirements((requirementResult.data ?? []) as Requirement[])
    setArtifacts((artifactResult.data ?? []) as Artifact[])
    setReadiness((readinessResult.data ?? []) as GateRow[])
    setAudit((auditResult.data ?? []) as Array<Record<string, unknown>>)
    setLoading(false)
  }

  useEffect(() => { void loadAll() }, [organizationId, projectId])

  const loadDetail = async (artifact: Artifact) => {
    setSelected(artifact)
    const { data, error } = await supabase.rpc('get_methodology_artifact_detail', { target_artifact_id: artifact.artifact_id })
    if (error) { setMessage(translateBackendMessage(error.message)); return }
    setDetail(data as ArtifactDetail)
  }

  const visibleArtifacts = useMemo(() => {
    const term = search.trim().toLocaleLowerCase('pt-BR')
    return artifacts.filter((item) => {
      const matchesSearch = !term || [item.artifact_code, item.title, item.artifact_type_name, item.phase_code, item.macrophase_code, item.metafase_code]
        .filter(Boolean).join(' ').toLocaleLowerCase('pt-BR').includes(term)
      const matchesStatus = !statusFilter || item.status === statusFilter
      const matchesPhase = !phaseFilter || [item.metafase_code, item.macrophase_code, item.phase_code, item.stage_code, item.gate_code].includes(phaseFilter)
      return matchesSearch && matchesStatus && matchesPhase
    }).sort((a, b) => a.title.localeCompare(b.title, 'pt-BR'))
  }, [artifacts, search, statusFilter, phaseFilter])

  const phaseOptions = useMemo(() => Array.from(new Set(artifacts.flatMap((item) => [item.metafase_code, item.macrophase_code, item.phase_code, item.stage_code, item.gate_code]).filter(Boolean) as string[])).sort(), [artifacts])
  const progress = readiness.length === 0 ? 0 : Math.round((readiness.filter((item) => item.requirement_status === 'satisfied').length / readiness.length) * 100)
  const blockers = readiness.filter((item) => item.blocks_closure && item.requirement_status !== 'satisfied').length

  const selectedIsProtected = selected ? ['validated', 'validated_with_reservations', 'superseded', 'archived'].includes(selected.status) : false

  const createArtifact = async () => {
    if (!form.typeCode || !form.title.trim()) { setMessage('Informe o tipo e o título do artefato.'); return }
    setSaving(true)
    const { data, error } = await supabase.rpc('create_methodology_artifact', {
      target_organization_id: organizationId,
      target_project_id: projectId,
      target_artifact_type_code: form.typeCode,
      target_title: form.title.trim(),
      target_purpose: form.purpose.trim() || null,
      target_metafase_code: form.metafase.trim() || null,
      target_macrophase_code: form.macrophase.trim() || null,
      target_phase_code: form.phase.trim() || null,
      target_stage_code: form.stage.trim() || null,
      target_gate_code: form.gate.trim() || null,
      target_requirement_code: form.requirementCode || null,
      target_responsible_user_id: null,
      target_approver_user_id: null,
      target_planned_due_date: form.dueDate || null,
    })
    if (error) setMessage(translateBackendMessage(error.message))
    else {
      setMessage('Artefato criado com sucesso.')
      setShowCreate(false)
      setForm({ typeCode: '', title: '', purpose: '', metafase: '', macrophase: '', phase: '', stage: '', gate: '', requirementCode: '', dueDate: '' })
      await loadAll()
      const created = artifacts.find((item) => item.artifact_id === data)
      if (created) await loadDetail(created)
    }
    setSaving(false)
  }

  const addVersion = async () => {
    if (!selected) return
    if (!versionForm.content.trim() && !file) { setMessage('Informe conteúdo ou selecione um arquivo.'); return }
    if (!versionForm.summary.trim()) { setMessage('Informe o resumo das alterações.'); return }
    setSaving(true)
    let storagePath: string | null = null
    let fileName: string | null = null
    let extension: string | null = null
    if (file) {
      extension = file.name.includes('.') ? file.name.split('.').pop()?.toLowerCase() ?? null : null
      fileName = file.name
      storagePath = `${organizationId}/${projectId}/${selected.artifact_id}/${Date.now()}_${safeName(file.name)}`
      const upload = await supabase.storage.from('methodology-artifacts').upload(storagePath, file, { upsert: false })
      if (upload.error) { setMessage(upload.error.message); setSaving(false); return }
    }
    const { error } = await supabase.rpc('add_methodology_artifact_version', {
      target_artifact_id: selected.artifact_id,
      target_content_markdown: versionForm.content.trim() || null,
      target_content_json: {},
      target_file_name: fileName,
      target_file_extension: extension,
      target_storage_bucket: storagePath ? 'methodology-artifacts' : null,
      target_storage_path: storagePath,
      target_integrity_hash: null,
      target_change_summary: versionForm.summary.trim(),
      target_generated_by_ai: versionForm.generatedByAi,
      target_generated_prompt: versionForm.prompt.trim() || null,
      target_generated_model: versionForm.model.trim() || null,
    })
    if (error) setMessage(translateBackendMessage(error.message))
    else {
      setMessage('Nova versão registrada.')
      setShowVersion(false)
      setVersionForm({ content: '', summary: '', generatedByAi: false, prompt: '', model: '' })
      setFile(null)
      await loadAll()
      await loadDetail(selected)
    }
    setSaving(false)
  }

  const validateArtifact = async () => {
    if (!selected) return
    const currentVersion = detail?.versions?.[0]?.id as string | undefined
    if (!currentVersion) { setMessage('Crie ao menos uma versão antes da validação.'); return }
    setSaving(true)
    const { error } = await supabase.rpc('validate_methodology_artifact', {
      target_artifact_id: selected.artifact_id,
      target_artifact_version_id: currentVersion,
      target_validation_status: validationForm.status,
      target_validation_type: validationForm.type,
      target_decision_text: validationForm.decision.trim() || null,
      target_reservations: validationForm.reservations.trim() || null,
      target_conditions: validationForm.conditions.trim() || null,
      target_meeting_reference: validationForm.meeting.trim() || null,
    })
    if (error) setMessage(translateBackendMessage(error.message))
    else {
      setMessage('Validação registrada.')
      setShowValidation(false)
      await loadAll()
      await loadDetail(selected)
    }
    setSaving(false)
  }

  const changeStatus = async (status: string) => {
    if (!selected) return
    const reason = window.prompt(`Justificativa para alterar a situação para “${statusLabel[status] ?? status}”:`)
    if (!reason?.trim()) return
    const { error } = await supabase.rpc('update_methodology_artifact_status', { target_artifact_id: selected.artifact_id, target_status: status, target_reason: reason.trim() })
    if (error) setMessage(translateBackendMessage(error.message))
    else { setMessage('Situação atualizada.'); await loadAll(); await loadDetail(selected) }
  }

  const downloadVersion = async (version: Record<string, unknown>) => {
    const bucket = version.storage_bucket as string | null
    const path = version.storage_path as string | null
    if (!bucket || !path) return
    const { data, error } = await supabase.storage.from(bucket).createSignedUrl(path, 300, { download: (version.file_name as string | null) ?? true })
    if (error) { setMessage(translateBackendMessage(error.message)); return }
    window.open(data.signedUrl, '_blank', 'noopener,noreferrer')
  }

  const onFile = (event: ChangeEvent<HTMLInputElement>) => setFile(event.target.files?.[0] ?? null)

  if (!projectId) return <section className="skpe-artifacts-empty"><h2>Artefatos e evidências</h2><p>Inicie a jornada estratégica para gerenciar as entregas metodológicas.</p></section>

  return <section className="skpe-artifacts-page">
    <header className="skpe-artifacts-header">
      <div><span>Gestão metodológica</span><h1>Artefatos e evidências</h1><p>Controle entregas, versões, validações e prontidão dos gates.</p></div>
      <div className="skpe-artifacts-header-actions">{canGenerateDeliveryKit && <button type="button" className="skpe-artifacts-secondary" onClick={() => setShowDeliveryKit(true)}>Kit de Entregas</button>}{canManage && <button type="button" className="skpe-artifacts-primary" onClick={() => setShowCreate(true)}>+ Novo artefato</button>}</div>
    </header>
    {showDeliveryKit && canGenerateDeliveryKit && <DeliveryKitDialog organizationId={organizationId} projectId={projectId} onClose={() => setShowDeliveryKit(false)} />}

    <section className="skpe-artifacts-summary">
      <article role="button" tabIndex={0} onClick={() => { setTab('artifacts'); setStatusFilter('') }} onKeyDown={(e) => activate(e, () => { setTab('artifacts'); setStatusFilter('') })}><span>Artefatos</span><strong>{artifacts.length}</strong><small>Clique para consultar</small></article>
      <article role="button" tabIndex={0} onClick={() => { setTab('readiness') }} onKeyDown={(e) => activate(e, () => setTab('readiness'))}><span>Prontidão</span><strong>{progress}%</strong><small>{readiness.filter((item) => item.requirement_status === 'satisfied').length} de {readiness.length} requisitos</small></article>
      <article role="button" tabIndex={0} onClick={() => { setTab('readiness') }} onKeyDown={(e) => activate(e, () => setTab('readiness'))}><span>Bloqueios</span><strong>{blockers}</strong><small>Requisitos que impedem encerramento</small></article>
      <article role="button" tabIndex={0} onClick={() => { setTab('artifacts'); setStatusFilter('submitted') }} onKeyDown={(e) => activate(e, () => { setTab('artifacts'); setStatusFilter('submitted') })}><span>Aguardando validação</span><strong>{artifacts.filter((item) => item.status === 'submitted').length}</strong><small>Entregas submetidas</small></article>
    </section>

    <nav className="skpe-artifacts-tabs">
      <button className={tab === 'artifacts' ? 'active' : ''} onClick={() => setTab('artifacts')}>Artefatos</button>
      <button className={tab === 'readiness' ? 'active' : ''} onClick={() => setTab('readiness')}>Prontidão dos gates</button>
      <button className={tab === 'audit' ? 'active' : ''} onClick={() => setTab('audit')}>Auditoria</button>
    </nav>

    {message && <div className="skpe-artifacts-message" role="status">{message}<button onClick={() => setMessage('')}>×</button></div>}

    {tab === 'artifacts' && <>
      <section className="skpe-artifacts-toolbar">
        <input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Pesquisar artefato, código, fase..." />
        <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}><option value="">Todas as situações</option>{Object.entries(statusLabel).filter(([key]) => !['pending','partial','awaiting_validation','satisfied'].includes(key)).map(([key, value]) => <option key={key} value={key}>{value}</option>)}</select>
        <select value={phaseFilter} onChange={(e) => setPhaseFilter(e.target.value)}><option value="">Toda a jornada</option>{phaseOptions.map((value) => <option key={value}>{value}</option>)}</select>
        <div><button className={viewMode === 'cards' ? 'active' : ''} onClick={() => setViewMode('cards')} title="Cards">▦</button><button className={viewMode === 'grid' ? 'active' : ''} onClick={() => setViewMode('grid')} title="Grid">☷</button><button className={viewMode === 'journey' ? 'active' : ''} onClick={() => setViewMode('journey')} title="Jornada">⌘</button></div>
      </section>
      {loading ? <div className="skpe-artifacts-state">Carregando artefatos...</div> : visibleArtifacts.length === 0 ? <div className="skpe-artifacts-state"><h2>Nenhum artefato encontrado</h2><p>Cadastre a primeira entrega ou ajuste os filtros.</p></div> : viewMode === 'grid' ? <div className="skpe-artifacts-table-wrap"><table><thead><tr><th>Título</th><th>Tipo</th><th>Fase</th><th>Situação</th><th>Versão</th><th>Prazo</th></tr></thead><tbody>{visibleArtifacts.map((item) => <tr key={item.artifact_id} role="button" tabIndex={0} onClick={() => void loadDetail(item)} onKeyDown={(e) => activate(e, () => void loadDetail(item))}><td><strong>{item.title}</strong><small>{item.artifact_code}</small></td><td>{item.artifact_type_name}</td><td>{item.phase_code ?? item.macrophase_code ?? item.metafase_code ?? '—'}</td><td><span className={`skpe-artifact-status status-${item.status}`}>{statusLabelPtBr(item.status, statusLabel[item.status])}</span></td><td>v{item.current_version_number}</td><td>{formatDate(item.planned_due_date)}</td></tr>)}</tbody></table></div> : <div className={viewMode === 'journey' ? 'skpe-artifacts-journey' : 'skpe-artifacts-grid'}>{visibleArtifacts.map((item) => <article key={item.artifact_id} role="button" tabIndex={0} onClick={() => void loadDetail(item)} onKeyDown={(e) => activate(e, () => void loadDetail(item))}>
        <header><span>{item.artifact_type_name}</span><b className={`skpe-artifact-status status-${item.status}`}>{statusLabelPtBr(item.status, statusLabel[item.status])}</b></header><h3>{item.title}</h3><p>{item.purpose ?? 'Sem finalidade complementar registrada.'}</p><div className="skpe-artifact-context"><span>{item.metafase_code ?? '—'}</span><span>{item.macrophase_code ?? '—'}</span><span>{item.phase_code ?? '—'}</span></div><footer><small>{item.artifact_code}</small><strong>v{item.current_version_number}</strong></footer>
      </article>)}</div>}
    </>}

    {tab === 'readiness' && <section className="skpe-readiness-section"><header><div><h2>Prontidão metodológica</h2><p>Requisitos canônicos e bloqueios para encerramento.</p></div><strong>{progress}%</strong></header><div className="skpe-readiness-progress"><i style={{ width: `${progress}%` }} /></div><div className="skpe-readiness-list">{readiness.map((item) => <article key={item.requirement_id}><div><span>{artifactTypeLabelPtBr(item.artifact_type_code)}</span><h3>{item.requirement_name}</h3><p>{item.produced_quantity} produzido(s) · {item.validated_quantity} validado(s) · mínimo {item.minimum_quantity}</p></div><div><b className={`readiness-${item.requirement_status}`}>{statusLabelPtBr(item.requirement_status, statusLabel[item.requirement_status])}</b>{item.blocks_closure && <small>Bloqueia encerramento</small>}</div></article>)}</div></section>}

    {tab === 'audit' && <section className="skpe-artifacts-audit"><header><h2>Trilha de auditoria</h2><p>Histórico cronológico das operações realizadas.</p></header>{audit.length === 0 ? <div className="skpe-artifacts-state">Nenhum registro de auditoria.</div> : audit.map((item) => <article key={String(item.audit_id)}><time>{formatDate(String(item.occurred_at))}</time><div><strong>{String(item.action_description ?? item.action_code)}</strong><span>{String(item.artifact_title ?? item.artifact_code ?? 'Registro metodológico')}</span></div><code>{eventLabelPtBr(String(item.action_code))}</code></article>)}</section>}

    {selected && <aside className="skpe-artifact-drawer" aria-label="Detalhes do artefato"><div className="skpe-artifact-drawer-backdrop" onClick={() => { setSelected(null); setDetail(null) }} /><div className="skpe-artifact-drawer-panel"><header><div><span>{selected.artifact_type_name}</span><h2>{selected.title}</h2><small>{selected.artifact_code}</small></div><button onClick={() => { setSelected(null); setDetail(null) }} aria-label="Fechar">×</button></header><section className="skpe-artifact-drawer-actions">{canManage && !selectedIsProtected && <><button onClick={() => setShowVersion(true)}>Nova versão</button><button onClick={() => setShowValidation(true)}>Validar</button><select value={selected.status} onChange={(e) => void changeStatus(e.target.value)}>{Object.entries(statusLabel).filter(([key]) => !['pending','partial','awaiting_validation','satisfied'].includes(key)).map(([key, value]) => <option key={key} value={key}>{value}</option>)}</select></>}</section>{selectedIsProtected && <div className="skpe-artifact-protected-notice"><strong>Artefato validado e protegido.</strong><span>Visualização, impressão e download permanecem disponíveis. Para criar nova versão, a fase deverá ser reaberta formalmente.</span></div>}<section className="skpe-artifact-meta"><div><span>Situação</span><strong>{statusLabelPtBr(selected.status, statusLabel[selected.status])}</strong></div><div><span>Versão atual</span><strong>v{selected.current_version_number}</strong></div><div><span>Prazo</span><strong>{formatDate(selected.planned_due_date)}</strong></div><div><span>Fase</span><strong>{selected.phase_code ?? selected.macrophase_code ?? selected.metafase_code ?? '—'}</strong></div></section><section><h3>Finalidade</h3><p>{selected.purpose ?? 'Não informada.'}</p></section><section><h3>Versões</h3>{detail?.versions?.length ? detail.versions.map((version) => <article className="skpe-version-card" key={String(version.id)}><div><strong>{String(version.version_label)}</strong><span>{String(version.change_summary ?? 'Sem resumo')}</span><small>{formatDate(String(version.created_at))}</small></div>{version.storage_path ? <button onClick={() => void downloadVersion(version)}>Baixar arquivo</button> : <span>Conteúdo registrado</span>}</article>) : <p>Nenhuma versão registrada.</p>}</section><section><h3>Validações</h3>{detail?.validations?.length ? detail.validations.map((validation) => <article className="skpe-validation-card" key={String(validation.id)}><strong>{statusLabelPtBr(String(validation.validation_status), statusLabel[String(validation.validation_status)])}</strong><span>{String(validation.decision_text ?? validation.reservations ?? 'Sem observação')}</span><small>{formatDate(String(validation.validated_at))}</small></article>) : <p>Nenhuma validação registrada.</p>}</section></div></aside>}

    {showCreate && <div className="skpe-artifact-modal"><div className="skpe-artifact-modal-backdrop" onClick={() => setShowCreate(false)} /><form onSubmit={(e) => { e.preventDefault(); void createArtifact() }}><header><h2>Novo artefato metodológico</h2><button type="button" onClick={() => setShowCreate(false)}>×</button></header><label><span>Tipo *</span><select value={form.typeCode} onChange={(e) => setForm({ ...form, typeCode: e.target.value })}><option value="">Selecione</option>{catalog.map((item) => <option key={item.artifact_type_id} value={item.artifact_type_code}>{item.artifact_type_name}</option>)}</select></label><label><span>Requisito associado</span><select value={form.requirementCode} onChange={(e) => { const req = requirements.find((item) => item.requirement_code === e.target.value); setForm({ ...form, requirementCode: e.target.value, typeCode: req?.artifact_type_code ?? form.typeCode }) }}><option value="">Sem requisito específico</option>{requirements.map((item) => <option key={item.requirement_id} value={item.requirement_code}>{item.requirement_name}</option>)}</select></label><label className="wide"><span>Título *</span><input value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} /></label><label className="wide"><span>Finalidade</span><textarea value={form.purpose} onChange={(e) => setForm({ ...form, purpose: e.target.value })} /></label><label><span>Metafase</span><input value={form.metafase} onChange={(e) => setForm({ ...form, metafase: e.target.value })} placeholder="PEM-00" /></label><label><span>Macrofase</span><input value={form.macrophase} onChange={(e) => setForm({ ...form, macrophase: e.target.value })} placeholder="PEM-01" /></label><label><span>Fase</span><input value={form.phase} onChange={(e) => setForm({ ...form, phase: e.target.value })} /></label><label><span>Etapa</span><input value={form.stage} onChange={(e) => setForm({ ...form, stage: e.target.value })} /></label><label><span>Gate</span><input value={form.gate} onChange={(e) => setForm({ ...form, gate: e.target.value })} /></label><label><span>Prazo planejado</span><input type="date" value={form.dueDate} onChange={(e) => setForm({ ...form, dueDate: e.target.value })} /></label><footer><button type="button" onClick={() => setShowCreate(false)}>Cancelar</button><button className="primary" disabled={saving}>{saving ? 'Salvando...' : 'Criar artefato'}</button></footer></form></div>}

    {showVersion && selected && <div className="skpe-artifact-modal"><div className="skpe-artifact-modal-backdrop" onClick={() => setShowVersion(false)} /><form onSubmit={(e) => { e.preventDefault(); void addVersion() }}><header><h2>Nova versão</h2><button type="button" onClick={() => setShowVersion(false)}>×</button></header><label className="wide"><span>Conteúdo em Markdown</span><textarea rows={10} value={versionForm.content} onChange={(e) => setVersionForm({ ...versionForm, content: e.target.value })} /></label><label className="wide"><span>Arquivo</span><input type="file" onChange={onFile} /></label><label className="wide"><span>Resumo das alterações *</span><textarea value={versionForm.summary} onChange={(e) => setVersionForm({ ...versionForm, summary: e.target.value })} /></label><label className="check wide"><input type="checkbox" checked={versionForm.generatedByAi} onChange={(e) => setVersionForm({ ...versionForm, generatedByAi: e.target.checked })} /><span>Conteúdo gerado com apoio de IA</span></label>{versionForm.generatedByAi && <><label className="wide"><span>Prompt utilizado</span><textarea value={versionForm.prompt} onChange={(e) => setVersionForm({ ...versionForm, prompt: e.target.value })} /></label><label><span>Modelo utilizado</span><input value={versionForm.model} onChange={(e) => setVersionForm({ ...versionForm, model: e.target.value })} /></label></>}<footer><button type="button" onClick={() => setShowVersion(false)}>Cancelar</button><button className="primary" disabled={saving}>{saving ? 'Salvando...' : 'Registrar versão'}</button></footer></form></div>}

    {showValidation && selected && <div className="skpe-artifact-modal"><div className="skpe-artifact-modal-backdrop" onClick={() => setShowValidation(false)} /><form onSubmit={(e) => { e.preventDefault(); void validateArtifact() }}><header><h2>Registrar validação</h2><button type="button" onClick={() => setShowValidation(false)}>×</button></header><label><span>Resultado</span><select value={validationForm.status} onChange={(e) => setValidationForm({ ...validationForm, status: e.target.value })}><option value="submitted">Submetido</option><option value="validated">Validado</option><option value="validated_with_reservations">Validado com ressalvas</option><option value="rejected">Rejeitado</option></select></label><label><span>Tipo</span><select value={validationForm.type} onChange={(e) => setValidationForm({ ...validationForm, type: e.target.value })}><option value="technical">Técnica</option><option value="methodological">Metodológica</option><option value="executive">Executiva</option><option value="client">Cliente</option><option value="gate">Gate</option></select></label><label className="wide"><span>Decisão</span><textarea value={validationForm.decision} onChange={(e) => setValidationForm({ ...validationForm, decision: e.target.value })} /></label><label className="wide"><span>Ressalvas</span><textarea value={validationForm.reservations} onChange={(e) => setValidationForm({ ...validationForm, reservations: e.target.value })} /></label><label className="wide"><span>Condições</span><textarea value={validationForm.conditions} onChange={(e) => setValidationForm({ ...validationForm, conditions: e.target.value })} /></label><label className="wide"><span>Referência da reunião/ata</span><input value={validationForm.meeting} onChange={(e) => setValidationForm({ ...validationForm, meeting: e.target.value })} /></label><footer><button type="button" onClick={() => setShowValidation(false)}>Cancelar</button><button className="primary" disabled={saving}>{saving ? 'Salvando...' : 'Registrar validação'}</button></footer></form></div>}
  </section>
}
