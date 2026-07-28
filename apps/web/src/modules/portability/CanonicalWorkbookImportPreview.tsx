import { useMemo, useState } from 'react'
import { parseCanonicalWorkbook } from './parseCanonicalWorkbook'
import type { CanonicalImportPreview, ReconciliationConflict } from './parseCanonicalWorkbook'
import './CanonicalWorkbookImportPreview.css'

type Props = { organizations: Array<{ id: string; code: string; name: string }> }

export function CanonicalWorkbookImportPreview({ organizations }: Props) {
  const [organizationId, setOrganizationId] = useState('')
  const [preview, setPreview] = useState<CanonicalImportPreview | null>(null)
  const [fileName, setFileName] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [decisions, setDecisions] = useState<Record<string, ReconciliationConflict['decision']>>({})

  const selectedOrganization = useMemo(() => organizations.find((item) => item.id === organizationId), [organizations, organizationId])

  const analyze = async (file: File | undefined) => {
    if (!file) return
    if (!selectedOrganization) { setError('Selecione a organização antes de analisar a planilha.'); return }
    if (selectedOrganization.code.toLocaleUpperCase('pt-BR') !== 'COOTAQUARA') { setError('A carga canônica inicial está bloqueada para organizações diferentes da COOTAQUARA.'); return }
    setLoading(true); setError(''); setPreview(null); setFileName(file.name)
    try {
      const result = await parseCanonicalWorkbook(file)
      setPreview(result)
      setDecisions(Object.fromEntries(result.conflicts.map((item) => [item.id, item.decision])))
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : 'Não foi possível analisar a planilha.')
    } finally { setLoading(false) }
  }

  const downloadPreview = () => {
    if (!preview || !preview.quality.canDownload) return
    const approvedPreview = {
      ...preview,
      conflicts: preview.conflicts.map((item) => ({ ...item, decision: decisions[item.id] ?? item.decision })),
    }
    const content = JSON.stringify(approvedPreview, null, 2)
    const url = URL.createObjectURL(new Blob([content], { type: 'application/json;charset=utf-8' }))
    const anchor = document.createElement('a')
    anchor.href = url
    anchor.download = `PAYLOAD_IMPORTACAO_${preview.organization}_v201_${Date.now()}.json`
    anchor.click()
    URL.revokeObjectURL(url)
  }

  return <section className="canonical-import-preview" aria-labelledby="canonical-import-title">
    <div className="canonical-import-heading">
      <div><p>Bloco 1.10B-0.1</p><h3 id="canonical-import-title">Gerar payload completo com controle de qualidade</h3><span>Chaves duplicadas são corrigidas automaticamente e linhas estruturalmente inválidas são colocadas em quarentena.</span></div>
      <span className="preview-only-badge">Schema 2.0.1 · sem gravação</span>
    </div>

    <div className="canonical-import-controls">
      <label>Organização<select value={organizationId} onChange={(event) => setOrganizationId(event.target.value)}><option value="">Selecione</option>{organizations.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}</select></label>
      <label className="canonical-file-field">Planilha `.xlsx`<input type="file" accept=".xlsx,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" onChange={(event) => void analyze(event.target.files?.[0])} /></label>
    </div>

    {loading && <div className="canonical-import-state">Extraindo dados, validando chaves e auditando a estrutura...</div>}
    {error && <div className="canonical-import-error">{error}</div>}

    {preview && <>
      <div className="canonical-import-kpis">
        <article><small>Organização</small><strong>{preview.organization}</strong></article>
        <article><small>Registros lidos</small><strong>{preview.totalPayloadRecords}</strong></article>
        <article><small>Registros válidos</small><strong>{preview.validPayloadRecords}</strong></article>
        <article><small>Em quarentena</small><strong>{preview.quarantinedRecords}</strong></article>
      </div>

      <div className="canonical-journey">
        <strong>Ponto canônico da jornada</strong>
        <span>MF1: {preview.journey.MF1}</span><span>MF2: {preview.journey.MF2}</span><span>{preview.journey.currentStage}</span><span>{preview.journey.nextStage}</span>
      </div>

      <div className="canonical-conflicts">
        <div className="canonical-section-title">
          <div><p>Qualidade do payload</p><h4>{preview.quality.canDownload ? 'Apto para download controlado' : 'Download bloqueado'}</h4></div>
          <button type="button" onClick={downloadPreview} disabled={!preview.quality.canDownload}>Baixar payload 2.0.1</button>
        </div>
        <article className={`canonical-conflict ${preview.quality.criticalIssues ? 'critical' : 'high'}`}>
          <div><small>Auditoria automática</small><h5>Resultado da validação estrutural</h5></div>
          <dl>
            <div><dt>Críticos</dt><dd>{preview.quality.criticalIssues}</dd></div>
            <div><dt>Altos</dt><dd>{preview.quality.highIssues}</dd></div>
            <div><dt>Correções automáticas</dt><dd>{preview.quality.autoCorrectedIssues}</dd></div>
            <div><dt>Registros em quarentena</dt><dd>{preview.quarantinedRecords}</dd></div>
          </dl>
          <p>Registros em quarentena permanecem no JSON para revisão, mas não entram na coleção de registros válidos destinada ao staging.</p>
        </article>

        {preview.quality.issues.map((issue) => <article key={issue.id} className={`canonical-conflict ${issue.severity}`}>
          <div><small>{issue.id} · {issue.action === 'auto_corrected' ? 'Corrigido automaticamente' : 'Quarentena'}</small><h5>{issue.sourceSheet} · linha {issue.sourceRow}</h5></div>
          <p>{issue.message}</p>
        </article>)}
      </div>

      <div className="canonical-conflicts">
        <div className="canonical-section-title"><div><p>Reconciliação obrigatória</p><h4>{preview.conflicts.length} conflitos identificados</h4></div></div>
        {preview.conflicts.map((item) => <article key={item.id} className={`canonical-conflict ${item.severity}`}>
          <div><small>{item.id} · {item.severity === 'critical' ? 'Crítico' : 'Alto'}</small><h5>{item.topic}</h5></div>
          <dl><div><dt>{item.sourceA}</dt><dd>{item.valueA}</dd></div><div><dt>{item.sourceB}</dt><dd>{item.valueB}</dd></div><div className="canonical-value"><dt>Valor canônico proposto</dt><dd>{item.canonicalValue}</dd></div></dl>
          <p>{item.rule}</p>
          <label>Decisão<select value={decisions[item.id] ?? item.decision} onChange={(event) => setDecisions((current) => ({ ...current, [item.id]: event.target.value as ReconciliationConflict['decision'] }))}><option value="accept_canonical">Aceitar valor canônico</option><option value="keep_source_a">Manter fonte A</option><option value="keep_source_b">Manter fonte B</option><option value="manual_review">Revisão manual</option></select></label>
        </article>)}
      </div>

      <details className="canonical-sheet-inventory"><summary>Inventário das {preview.sheetCount} abas — {fileName}</summary><div className="canonical-sheet-table"><table><thead><tr><th>Aba</th><th>Entidade</th><th>Linha de cabeçalho</th><th>Registros válidos</th></tr></thead><tbody>{preview.sheets.map((sheet) => <tr key={sheet.sheet}><td>{sheet.sheet}</td><td>{sheet.entity ?? 'Referência/estrutura'}</td><td>{sheet.headerRow}</td><td>{sheet.records}</td></tr>)}</tbody></table></div></details>
    </>}
  </section>
}
