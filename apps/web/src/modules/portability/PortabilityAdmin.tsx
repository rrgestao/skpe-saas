import { useEffect, useMemo, useState } from 'react'
import type { FormEvent, KeyboardEvent } from 'react'

import { supabase } from '../../lib/supabase'
import { createCanonicalWorkbook } from './generateCanonicalWorkbook'
import { createPortablePortal } from './generatePortablePortal'
import { createPortablePackage } from './generatePortablePackage'
import { CanonicalWorkbookImportPreview } from './CanonicalWorkbookImportPreview'
import { CanonicalImportStaging } from './CanonicalImportStaging'

import './PortabilityAdmin.css'

type OrganizationOption = { id: string; code: string; name: string }
type Props = { organizations: OrganizationOption[] }
type ViewMode = 'cards' | 'grid'
type DirectionFilter = '' | 'import' | 'export'
type PackageStatus = '' | 'draft' | 'preparing' | 'validating' | 'ready' | 'processing' | 'completed' | 'completed_with_warnings' | 'failed' | 'cancelled' | 'archived'

type Layout = {
  layout_id: string
  module_code: string
  layout_code: string
  layout_name: string
  layout_version: string
  file_type: string
  direction: string
  description: string | null
  active: boolean
}

type PackageRow = {
  package_id: string
  organization_id: string
  organization_name: string
  project_id: string | null
  module_code: string
  package_code: string
  package_type: string
  direction: 'import' | 'export'
  status: string
  layout_name: string | null
  layout_version: string | null
  file_name: string | null
  requested_at: string
  requested_by: string | null
  completed_at: string | null
  error_message: string | null
  record_counts: Record<string, number>
}

type FormState = {
  organizationId: string
  direction: 'import' | 'export'
  packageType: string
  layoutCode: string
  reason: string
}

const EMPTY_FORM: FormState = {
  organizationId: '',
  direction: 'export',
  packageType: 'complete_project',
  layoutCode: 'SPARKS_PE_PACKAGE',
  reason: '',
}

const STATUS_LABELS: Record<string, string> = {
  draft: 'Rascunho',
  preparing: 'Em preparação',
  validating: 'Em validação',
  ready: 'Pronto',
  processing: 'Processando',
  completed: 'Concluído',
  completed_with_warnings: 'Concluído com alertas',
  failed: 'Falhou',
  cancelled: 'Cancelado',
  archived: 'Arquivado',
}

const PACKAGE_LABELS: Record<string, string> = {
  empty_template: 'Modelo vazio',
  complete_project: 'Projeto completo',
  current_phase: 'Fase atual',
  phase_closure: 'Pacote de encerramento da fase',
  execution_monitoring: 'Execução e monitoramento',
  portable_portal: 'Portal HTML portátil',
  portable_backup: 'Backup portátil',
  network_consolidated: 'Rede consolidada',
  anonymized: 'Pacote anonimizado',
  import_package: 'Pacote para importação',
}

function formatDateTime(value: string | null | undefined) {
  if (!value) return '—'
  return new Intl.DateTimeFormat('pt-BR', { dateStyle: 'short', timeStyle: 'short' }).format(new Date(value))
}

export function PortabilityAdmin({ organizations }: Props) {
  const [packages, setPackages] = useState<PackageRow[]>([])
  const [layouts, setLayouts] = useState<Layout[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [generatingPackageId, setGeneratingPackageId] = useState<string | null>(null)
  const [generatingWorkbookId, setGeneratingWorkbookId] = useState<string | null>(null)
  const [generatingHtmlId, setGeneratingHtmlId] = useState<string | null>(null)
  const [generatingZipId, setGeneratingZipId] = useState<string | null>(null)
  const [message, setMessage] = useState('')
  const [messageType, setMessageType] = useState<'success' | 'error'>('success')
  const [viewMode, setViewMode] = useState<ViewMode>('cards')
  const [search, setSearch] = useState('')
  const [organizationFilter, setOrganizationFilter] = useState('')
  const [directionFilter, setDirectionFilter] = useState<DirectionFilter>('')
  const [statusFilter, setStatusFilter] = useState<PackageStatus>('')
  const [form, setForm] = useState<FormState>(EMPTY_FORM)

  const showMessage = (text: string, type: 'success' | 'error' = 'success') => {
    setMessage(text)
    setMessageType(type)
  }

  const loadData = async () => {
    setLoading(true)
    const [layoutResponse, packageResponse] = await Promise.all([
      supabase.rpc('get_portability_layouts', { target_module_code: 'SK-PE', target_direction: null }),
      supabase.rpc('get_portability_packages', {
        target_organization_id: organizationFilter || null,
        target_direction: directionFilter || null,
        target_status: statusFilter || null,
      }),
    ])

    if (layoutResponse.error) showMessage(`Não foi possível carregar os leiautes: ${layoutResponse.error.message}`, 'error')
    else setLayouts((layoutResponse.data ?? []) as Layout[])

    if (packageResponse.error) showMessage(`Não foi possível carregar os pacotes: ${packageResponse.error.message}`, 'error')
    else setPackages((packageResponse.data ?? []) as PackageRow[])

    setLoading(false)
  }

  useEffect(() => {
    void loadData()
  }, [organizationFilter, directionFilter, statusFilter])

  const availableLayouts = useMemo(
    () => layouts.filter((layout) => layout.active && (layout.direction === form.direction || layout.direction === 'both')),
    [layouts, form.direction],
  )

  useEffect(() => {
    if (availableLayouts.length === 0) return
    const selectedStillAvailable = availableLayouts.some((layout) => layout.layout_code === form.layoutCode)
    if (!selectedStillAvailable) {
      setForm((current) => ({ ...current, layoutCode: availableLayouts[0].layout_code }))
    }
  }, [availableLayouts, form.layoutCode])

  const filteredPackages = useMemo(() => {
    const term = search.trim().toLocaleLowerCase('pt-BR')
    return packages
      .filter((item) => !term || [item.package_code, item.organization_name, item.layout_name ?? '', PACKAGE_LABELS[item.package_type] ?? item.package_type]
        .some((value) => value.toLocaleLowerCase('pt-BR').includes(term)))
      .sort((a, b) => a.organization_name.localeCompare(b.organization_name, 'pt-BR'))
  }, [packages, search])

  const changeDirection = (direction: 'import' | 'export') => {
    const defaultLayout = layouts.find((layout) => layout.active && (layout.direction === direction || layout.direction === 'both'))
    setForm((current) => ({
      ...current,
      direction,
      packageType: direction === 'import' ? 'import_package' : 'complete_project',
      layoutCode: defaultLayout?.layout_code ?? '',
    }))
    setMessage('')
  }

  const submitPackage = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    if (!form.organizationId || !form.layoutCode || !form.reason.trim()) {
      showMessage('Informe organização, leiaute e justificativa.', 'error')
      return
    }

    setSaving(true)
    const { error } = await supabase.rpc('create_portability_package', {
      target_organization_id: form.organizationId,
      target_project_id: null,
      target_module_code: 'SK-PE',
      target_package_type: form.packageType,
      target_direction: form.direction,
      target_layout_code: form.layoutCode,
      target_reason: form.reason.trim(),
    })

    if (error) {
      showMessage(`Não foi possível registrar o pacote: ${error.message}`, 'error')
    } else {
      showMessage('Solicitação de portabilidade registrada com sucesso.')
      setForm((current) => ({ ...current, reason: '' }))
      await loadData()
    }
    setSaving(false)
  }


  const generateJsonExport = async (item: PackageRow) => {
    if (item.direction !== 'export') {
      showMessage('Somente pacotes de exportação podem gerar arquivos JSON.', 'error')
      return
    }

    setGeneratingPackageId(item.package_id)
    showMessage(`Gerando dados estruturados de ${item.organization_name}...`)

    const { data, error } = await supabase.rpc('generate_portability_json_export', {
      target_package_id: item.package_id,
    })

    if (error) {
      showMessage(`Não foi possível gerar o JSON: ${error.message}`, 'error')
      setGeneratingPackageId(null)
      await loadData()
      return
    }

    const documentData = data as Record<string, unknown>
    const manifest = (documentData.manifesto ?? {}) as Record<string, unknown>
    const fileName = typeof manifest.file_name === 'string'
      ? manifest.file_name
      : `${item.package_code}.json`
    const content = JSON.stringify(documentData, null, 2)
    const blob = new Blob([content], { type: 'application/json;charset=utf-8' })
    const url = URL.createObjectURL(blob)
    const anchor = document.createElement('a')
    anchor.href = url
    anchor.download = fileName
    document.body.appendChild(anchor)
    anchor.click()
    anchor.remove()
    URL.revokeObjectURL(url)

    showMessage(`Arquivo ${fileName} gerado com manifesto e hash de integridade.`)
    setGeneratingPackageId(null)
    await loadData()
  }

  const generateWorkbookExport = async (item: PackageRow) => {
    if (item.direction !== 'export') {
      showMessage('Somente pacotes de exportação podem gerar a Planilha Canônica.', 'error')
      return
    }

    setGeneratingWorkbookId(item.package_id)
    showMessage(`Preparando a Planilha Canônica de ${item.organization_name}...`)

    const { data, error } = await supabase.rpc('generate_portability_json_export', {
      target_package_id: item.package_id,
    })

    if (error) {
      showMessage(`Não foi possível coletar os dados da planilha: ${error.message}`, 'error')
      setGeneratingWorkbookId(null)
      await loadData()
      return
    }

    try {
      const { blob, fileName } = await createCanonicalWorkbook(data as Record<string, unknown>)
      const url = URL.createObjectURL(blob)
      const anchor = document.createElement('a')
      anchor.href = url
      anchor.download = fileName
      document.body.appendChild(anchor)
      anchor.click()
      anchor.remove()
      URL.revokeObjectURL(url)

      await supabase.rpc('register_portability_generated_file', {
        target_package_id: item.package_id,
        target_format: 'xlsx',
        target_file_name: fileName,
        target_metadata: { generated_locally_by_browser: true, canonical_workbook: true },
      })

      showMessage(`Planilha Canônica ${fileName} gerada com sucesso.`)
    } catch (workbookError) {
      const detail = workbookError instanceof Error ? workbookError.message : 'Erro desconhecido.'
      showMessage(`Não foi possível gerar a Planilha Canônica: ${detail}`, 'error')
    } finally {
      setGeneratingWorkbookId(null)
      await loadData()
    }
  }

  const generateHtmlExport = async (item: PackageRow) => {
    if (item.direction !== 'export') {
      showMessage('Somente pacotes de exportação podem gerar o Portal HTML.', 'error')
      return
    }

    setGeneratingHtmlId(item.package_id)
    showMessage(`Preparando o Portal HTML Portátil de ${item.organization_name}...`)

    const { data, error } = await supabase.rpc('generate_portability_json_export', {
      target_package_id: item.package_id,
    })

    if (error) {
      showMessage(`Não foi possível coletar os dados do portal: ${error.message}`, 'error')
      setGeneratingHtmlId(null)
      await loadData()
      return
    }

    try {
      const { blob, fileName } = createPortablePortal(data as Record<string, unknown>)
      const url = URL.createObjectURL(blob)
      const anchor = document.createElement('a')
      anchor.href = url
      anchor.download = fileName
      document.body.appendChild(anchor)
      anchor.click()
      anchor.remove()
      URL.revokeObjectURL(url)

      const registerResponse = await supabase.rpc('register_portability_generated_file', {
        target_package_id: item.package_id,
        target_format: 'html',
        target_file_name: fileName,
        target_metadata: {
          generated_locally_by_browser: true,
          portable_portal: true,
          read_only: true,
          embedded_structured_data: true,
        },
      })

      if (registerResponse.error) {
        showMessage(`O HTML foi baixado, mas o registro da geração falhou: ${registerResponse.error.message}`, 'error')
      } else {
        showMessage(`Portal HTML Portátil ${fileName} gerado com sucesso.`)
      }
    } catch (portalError) {
      const detail = portalError instanceof Error ? portalError.message : 'Erro desconhecido.'
      showMessage(`Não foi possível gerar o Portal HTML Portátil: ${detail}`, 'error')
    } finally {
      setGeneratingHtmlId(null)
      await loadData()
    }
  }

  const generateZipExport = async (item: PackageRow) => {
    if (item.direction !== 'export') {
      showMessage('Somente pacotes de exportação podem gerar o Pacote Estratégico Portátil.', 'error')
      return
    }

    setGeneratingZipId(item.package_id)
    showMessage(`Preparando o Pacote Estratégico Portátil de ${item.organization_name}...`)

    const { data, error } = await supabase.rpc('generate_portability_json_export', {
      target_package_id: item.package_id,
    })

    if (error) {
      showMessage(`Não foi possível coletar os dados do pacote: ${error.message}`, 'error')
      setGeneratingZipId(null)
      await loadData()
      return
    }

    try {
      const { blob, fileName, metadata } = await createPortablePackage(data as Record<string, unknown>)
      const url = URL.createObjectURL(blob)
      const anchor = document.createElement('a')
      anchor.href = url
      anchor.download = fileName
      document.body.appendChild(anchor)
      anchor.click()
      anchor.remove()
      URL.revokeObjectURL(url)

      const registerResponse = await supabase.rpc('register_portability_generated_file', {
        target_package_id: item.package_id,
        target_format: 'zip',
        target_file_name: fileName,
        target_metadata: metadata,
      })

      if (registerResponse.error) {
        showMessage(`O ZIP foi baixado, mas o registro da geração falhou: ${registerResponse.error.message}`, 'error')
      } else {
        showMessage(`Pacote Estratégico Portátil ${fileName} gerado com sucesso.`)
      }
    } catch (packageError) {
      const detail = packageError instanceof Error ? packageError.message : 'Erro desconhecido.'
      showMessage(`Não foi possível gerar o Pacote Estratégico Portátil: ${detail}`, 'error')
    } finally {
      setGeneratingZipId(null)
      await loadData()
    }
  }

  const archivePackage = async (packageId: string) => {
    const reason = window.prompt('Informe a justificativa para arquivar este pacote:')?.trim()
    if (!reason) return

    const { error } = await supabase.rpc('set_portability_package_status', {
      target_package_id: packageId,
      target_status: 'archived',
      target_reason: reason,
    })

    if (error) showMessage(`Não foi possível arquivar: ${error.message}`, 'error')
    else {
      showMessage('Pacote arquivado.')
      await loadData()
    }
  }

  const handleCardKey = (event: KeyboardEvent<HTMLElement>, packageCode: string) => {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault()
      showMessage(`Pacote selecionado: ${packageCode}`)
    }
  }

  return (
    <section className="portability-admin">
      <div className="portability-heading">
        <div>
          <p className="portability-eyebrow">Gestão Estratégica Portátil</p>
          <h2>Importação, Exportação e Portabilidade</h2>
          <p>Administre a convivência controlada entre a Plataforma SaaS, a Planilha Canônica, o Portal HTML e os pacotes estruturados.</p>
        </div>
      </div>

      {message && <p className={`portability-message ${messageType}`}>{message}</p>}

      <section className="portability-guidance">
        <strong>Governança da portabilidade</strong>
        <span>Nenhuma importação grava dados diretamente. Todo pacote passa por preparação, validação, prévia, resolução de conflitos e confirmação auditável.</span>
      </section>

      <section className="portability-request-section" aria-labelledby="portability-request-title">
        <div className="portability-request-header">
          <div>
            <p className="portability-eyebrow">Nova solicitação</p>
            <h3 id="portability-request-title">Registrar operação de portabilidade</h3>
            <p>Os campos permanecem visíveis para que a operação seja clara e não dependa de painel oculto.</p>
          </div>
          <div className="portability-direction-switch" role="group" aria-label="Tipo de operação">
            <button type="button" className={form.direction === 'import' ? 'active' : ''} onClick={() => changeDirection('import')}>Importar</button>
            <button type="button" className={form.direction === 'export' ? 'active' : ''} onClick={() => changeDirection('export')}>Exportar</button>
          </div>
        </div>

        <form className="portability-request-form" onSubmit={submitPackage}>
          <label>
            Organização
            <select value={form.organizationId} onChange={(event) => setForm((current) => ({ ...current, organizationId: event.target.value }))} required>
              <option value="">Selecione</option>
              {organizations.map((organization) => <option key={organization.id} value={organization.id}>{organization.name}</option>)}
            </select>
          </label>

          <label>
            Tipo de pacote
            <select value={form.packageType} onChange={(event) => setForm((current) => ({ ...current, packageType: event.target.value }))}>
              {Object.entries(PACKAGE_LABELS)
                .filter(([value]) => form.direction === 'import' ? value === 'import_package' : value !== 'import_package')
                .map(([value, label]) => <option key={value} value={value}>{label}</option>)}
            </select>
          </label>

          <label>
            Leiaute
            <select value={form.layoutCode} onChange={(event) => setForm((current) => ({ ...current, layoutCode: event.target.value }))} required>
              <option value="">Selecione</option>
              {availableLayouts.map((layout) => (
                <option key={layout.layout_id} value={layout.layout_code}>
                  {layout.layout_name} — {layout.file_type.toUpperCase()} v{layout.layout_version}
                </option>
              ))}
            </select>
          </label>

          <label className="portability-reason-field">
            Justificativa
            <textarea
              value={form.reason}
              onChange={(event) => setForm((current) => ({ ...current, reason: event.target.value }))}
              placeholder="Ex.: Validação funcional da fundação de portabilidade"
              required
            />
          </label>

          <aside className="portability-request-note">
            <strong>Importante</strong>
            <span>Esta etapa registra a solicitação e sua trilha de auditoria. A geração física dos arquivos e a aplicação de importações serão implementadas nos blocos seguintes.</span>
          </aside>

          <div className="portability-request-actions">
            <button type="button" onClick={() => setForm((current) => ({ ...EMPTY_FORM, direction: current.direction }))}>Limpar</button>
            <button type="submit" className="primary" disabled={saving}>{saving ? 'Registrando...' : 'Registrar solicitação'}</button>
          </div>
        </form>
      </section>

      <CanonicalWorkbookImportPreview organizations={organizations} />
      <CanonicalImportStaging organizations={organizations} />

      <section className="portability-history-section" aria-labelledby="portability-history-title">
        <div className="portability-history-heading">
          <div>
            <p className="portability-eyebrow">Histórico</p>
            <h3 id="portability-history-title">Solicitações registradas</h3>
          </div>
        </div>

        <div className="portability-toolbar">
          <input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Pesquisar pacote, organização ou leiaute" />
          <select value={organizationFilter} onChange={(event) => setOrganizationFilter(event.target.value)}>
            <option value="">Todas as organizações</option>
            {organizations.map((organization) => <option key={organization.id} value={organization.id}>{organization.name}</option>)}
          </select>
          <select value={directionFilter} onChange={(event) => setDirectionFilter(event.target.value as DirectionFilter)}>
            <option value="">Importações e exportações</option>
            <option value="import">Importações</option>
            <option value="export">Exportações</option>
          </select>
          <select value={statusFilter} onChange={(event) => setStatusFilter(event.target.value as PackageStatus)}>
            <option value="">Todas as situações</option>
            {Object.entries(STATUS_LABELS).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
          </select>
          <div className="portability-view-toggle">
            <button type="button" className={viewMode === 'cards' ? 'active' : ''} onClick={() => setViewMode('cards')}>▦ Cards</button>
            <button type="button" className={viewMode === 'grid' ? 'active' : ''} onClick={() => setViewMode('grid')}>☷ Linhas</button>
          </div>
        </div>

        {loading ? (
          <div className="portability-empty">Carregando pacotes...</div>
        ) : filteredPackages.length === 0 ? (
          <div className="portability-empty">
            <strong>Nenhum pacote registrado</strong>
            <span>Preencha o formulário acima para criar a primeira solicitação.</span>
          </div>
        ) : viewMode === 'cards' ? (
          <div className="portability-card-grid">
            {filteredPackages.map((item) => (
              <article
                key={item.package_id}
                className="portability-card"
                tabIndex={0}
                role="button"
                onClick={() => showMessage(`Pacote selecionado: ${item.package_code}`)}
                onKeyDown={(event) => handleCardKey(event, item.package_code)}
              >
                <div className="portability-card-header">
                  <div><small>{item.package_code}</small><h3>{item.organization_name}</h3></div>
                  <span className={`status ${item.status}`}>{STATUS_LABELS[item.status] ?? item.status}</span>
                </div>
                <dl>
                  <div><dt>Operação</dt><dd>{item.direction === 'export' ? 'Exportação' : 'Importação'}</dd></div>
                  <div><dt>Pacote</dt><dd>{PACKAGE_LABELS[item.package_type] ?? item.package_type}</dd></div>
                  <div><dt>Leiaute</dt><dd>{item.layout_name ?? '—'} {item.layout_version ? `v${item.layout_version}` : ''}</dd></div>
                  <div><dt>Solicitado em</dt><dd>{formatDateTime(item.requested_at)}</dd></div>
                </dl>
                {item.error_message && <p className="portability-error">{item.error_message}</p>}
                <div className="portability-card-actions" onClick={(event) => event.stopPropagation()}>
                  {item.direction === 'export' && !['archived', 'cancelled', 'processing'].includes(item.status) && (
                    <button
                      type="button"
                      className="generate-zip"
                      onClick={() => void generateZipExport(item)}
                      disabled={generatingZipId === item.package_id}
                      title="Gerar Pacote Estratégico Portátil completo"
                    >
                      {generatingZipId === item.package_id ? 'Gerando...' : 'Gerar ZIP'}
                    </button>
                  )}
                  {item.direction === 'export' && !['archived', 'cancelled', 'processing'].includes(item.status) && (
                    <button
                      type="button"
                      className="generate-html"
                      onClick={() => void generateHtmlExport(item)}
                      disabled={generatingHtmlId === item.package_id}
                      title="Gerar Portal HTML Portátil"
                    >
                      {generatingHtmlId === item.package_id ? 'Gerando...' : 'Gerar HTML'}
                    </button>
                  )}
                  {item.direction === 'export' && !['archived', 'cancelled', 'processing'].includes(item.status) && (
                    <button
                      type="button"
                      className="generate-workbook"
                      onClick={() => void generateWorkbookExport(item)}
                      disabled={generatingWorkbookId === item.package_id}
                      title="Gerar Planilha Canônica de Gestão Estratégica"
                    >
                      {generatingWorkbookId === item.package_id ? 'Gerando...' : 'Gerar Excel'}
                    </button>
                  )}
                  {item.direction === 'export' && !['archived', 'cancelled', 'processing'].includes(item.status) && (
                    <button
                      type="button"
                      className="generate-json"
                      onClick={() => void generateJsonExport(item)}
                      disabled={generatingPackageId === item.package_id}
                      title="Gerar dados estruturados e manifesto"
                    >
                      {generatingPackageId === item.package_id ? 'Gerando...' : 'Gerar JSON'}
                    </button>
                  )}
                  <button type="button" onClick={() => window.print()} title="Imprimir">⎙</button>
                  {!['archived', 'processing'].includes(item.status) && <button type="button" onClick={() => void archivePackage(item.package_id)} title="Arquivar">⌂</button>}
                </div>
              </article>
            ))}
          </div>
        ) : (
          <div className="portability-table-wrap">
            <table>
              <thead><tr><th>Organização</th><th>Código</th><th>Operação</th><th>Pacote</th><th>Leiaute</th><th>Situação</th><th>Solicitado em</th><th>Ações</th></tr></thead>
              <tbody>
                {filteredPackages.map((item) => (
                  <tr key={item.package_id} tabIndex={0} onClick={() => showMessage(`Pacote selecionado: ${item.package_code}`)}>
                    <td><strong>{item.organization_name}</strong></td>
                    <td>{item.package_code}</td>
                    <td>{item.direction === 'export' ? 'Exportação' : 'Importação'}</td>
                    <td>{PACKAGE_LABELS[item.package_type] ?? item.package_type}</td>
                    <td>{item.layout_name ?? '—'}</td>
                    <td>{STATUS_LABELS[item.status] ?? item.status}</td>
                    <td>{formatDateTime(item.requested_at)}</td>
                    <td>
                      <div className="portability-row-actions" onClick={(event) => event.stopPropagation()}>
                        {item.direction === 'export' && !['archived', 'cancelled', 'processing'].includes(item.status) && (
                          <button
                            type="button"
                            className="generate-zip"
                            onClick={() => void generateZipExport(item)}
                            disabled={generatingZipId === item.package_id}
                            title="Gerar Pacote Estratégico Portátil completo"
                          >
                            {generatingZipId === item.package_id ? 'Gerando...' : 'ZIP'}
                          </button>
                        )}
                        {item.direction === 'export' && !['archived', 'cancelled', 'processing'].includes(item.status) && (
                          <button
                            type="button"
                            className="generate-html"
                            onClick={() => void generateHtmlExport(item)}
                            disabled={generatingHtmlId === item.package_id}
                            title="Gerar Portal HTML Portátil"
                          >
                            {generatingHtmlId === item.package_id ? 'Gerando...' : 'HTML'}
                          </button>
                        )}
                        {item.direction === 'export' && !['archived', 'cancelled', 'processing'].includes(item.status) && (
                          <button
                            type="button"
                            className="generate-workbook"
                            onClick={() => void generateWorkbookExport(item)}
                            disabled={generatingWorkbookId === item.package_id}
                            title="Gerar Planilha Canônica de Gestão Estratégica"
                          >
                            {generatingWorkbookId === item.package_id ? 'Gerando...' : 'Excel'}
                          </button>
                        )}
                        {item.direction === 'export' && !['archived', 'cancelled', 'processing'].includes(item.status) && (
                          <button
                            type="button"
                            className="generate-json"
                            onClick={() => void generateJsonExport(item)}
                            disabled={generatingPackageId === item.package_id}
                            title="Gerar dados estruturados e manifesto"
                          >
                            {generatingPackageId === item.package_id ? 'Gerando...' : 'JSON'}
                          </button>
                        )}
                        <button type="button" onClick={() => window.print()} title="Imprimir">⎙</button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>
    </section>
  )
}
