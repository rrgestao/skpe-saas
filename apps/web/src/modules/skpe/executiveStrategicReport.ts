export type ExecutiveReportArtifact = {
  title: string
  code: string
  typeLabel: string
  phaseCode: string | null
  purpose: string | null
  statusLabel: string
  version: number
  validatedAt: string | null
  contentMarkdown: string | null
  fileName: string | null
}

type BuildExecutiveReportArgs = {
  organizationName: string
  projectName: string
  horizonLabel: string | null
  isFinalized: boolean
  generatedAt: Date
  artifacts: ExecutiveReportArtifact[]
}

const phaseLabels: Record<string, string> = {
  'PEM-00': 'Preparação e Enquadramento',
  'PEM-01': 'Diagnóstico Estratégico',
  'PEM-02': 'Formulação Estratégica',
  'PEM-03': 'Desdobramento Estratégico',
  'PEM-04': 'Implementação e Mobilização',
  'PEM-05': 'Monitoramento e Aprendizado',
}

function escapeHtml(value: unknown) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;')
}

function phaseRoot(value: string | null) {
  if (!value) return 'SEM_FASE'
  const match = value.match(/^PEM-\d{2}/)
  return match?.[0] ?? value
}

function phaseSortValue(value: string) {
  const match = value.match(/^PEM-(\d{2})/)
  return match ? Number(match[1]) : 999
}

function formatDateTime(value: string | null) {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value
  return new Intl.DateTimeFormat('pt-BR', {
    dateStyle: 'short',
    timeStyle: 'short',
  }).format(date)
}

function artifactBody(artifact: ExecutiveReportArtifact) {
  if (artifact.contentMarkdown?.trim()) {
    return `<pre class="artifact-content">${escapeHtml(artifact.contentMarkdown.trim())}</pre>`
  }

  return `<div class="artifact-file-note">
    <strong>Conteúdo em arquivo:</strong>
    ${escapeHtml(artifact.fileName ?? 'arquivo registrado')}
  </div>`
}

export function buildExecutiveStrategicReportHtml({
  organizationName,
  projectName,
  horizonLabel,
  isFinalized,
  generatedAt,
  artifacts,
}: BuildExecutiveReportArgs) {
  const reportTitle = isFinalized
    ? 'Plano Estratégico Consolidado'
    : 'Relatório Executivo de Trabalho'
  const reportStatus = isFinalized
    ? 'Jornada concluída e ratificada'
    : 'Documento de trabalho — a Jornada ainda não foi concluída'

  const sorted = [...artifacts].sort((a, b) => {
    const phaseCompare = phaseSortValue(phaseRoot(a.phaseCode)) - phaseSortValue(phaseRoot(b.phaseCode))
    if (phaseCompare !== 0) return phaseCompare
    return a.title.localeCompare(b.title, 'pt-BR')
  })

  const groups = new Map<string, ExecutiveReportArtifact[]>()
  for (const artifact of sorted) {
    const root = phaseRoot(artifact.phaseCode)
    const current = groups.get(root) ?? []
    current.push(artifact)
    groups.set(root, current)
  }

  const summaryRows = sorted.map((artifact) => `
    <tr>
      <td>${escapeHtml(artifact.phaseCode ?? '—')}</td>
      <td>${escapeHtml(artifact.title)}</td>
      <td>${escapeHtml(artifact.statusLabel)}</td>
      <td>v${artifact.version}</td>
    </tr>`).join('')

  const sections = Array.from(groups.entries()).map(([root, items]) => {
    const phaseTitle = phaseLabels[root] ?? (root === 'SEM_FASE' ? 'Conteúdos transversais' : root)
    const artifactSections = items.map((artifact) => `
      <article class="artifact">
        <header>
          <span>${escapeHtml(artifact.typeLabel)}</span>
          <h3>${escapeHtml(artifact.title)}</h3>
          <div class="meta">
            <b>${escapeHtml(artifact.phaseCode ?? root)}</b>
            <span>${escapeHtml(artifact.statusLabel)}</span>
            <span>v${artifact.version}</span>
            <span>Validação: ${escapeHtml(formatDateTime(artifact.validatedAt))}</span>
          </div>
        </header>
        ${artifact.purpose ? `<p class="purpose">${escapeHtml(artifact.purpose)}</p>` : ''}
        ${artifactBody(artifact)}
      </article>`).join('')

    return `
      <section class="phase">
        <h2>${escapeHtml(root === 'SEM_FASE' ? phaseTitle : `${root} — ${phaseTitle}`)}</h2>
        ${artifactSections}
      </section>`
  }).join('')

  return `<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${escapeHtml(reportTitle)} — SPARKs PE</title>
<style>
  :root{font-family:Inter,Arial,sans-serif;color:#17251e;background:#fff}
  body{margin:0;line-height:1.5}
  main{max-width:1080px;margin:0 auto;padding:48px 56px 96px}
  .cover{min-height:72vh;display:flex;flex-direction:column;justify-content:center;border-bottom:4px solid #17251e}
  .cover small,.eyebrow{letter-spacing:.08em;text-transform:uppercase;font-weight:700}
  h1{font-size:44px;line-height:1.08;margin:12px 0}
  h2{font-size:28px;margin:52px 0 20px}
  h3{font-size:21px;margin:6px 0}
  .lead{font-size:18px;max-width:820px}
  .notice{padding:16px 18px;background:#f2f5f3;border-left:4px solid #17251e;margin:28px 0}
  table{width:100%;border-collapse:collapse;margin:20px 0 36px}
  th,td{border:1px solid #d7ded9;padding:9px 10px;text-align:left;vertical-align:top}
  th{background:#f2f5f3}
  .artifact{break-inside:avoid-page;border-top:1px solid #d7ded9;padding:22px 0 28px}
  .artifact header>span{font-size:12px;text-transform:uppercase;font-weight:700;letter-spacing:.05em}
  .meta{display:flex;gap:10px;flex-wrap:wrap;font-size:12px;color:#4b5d54}
  .purpose{font-size:15px}
  .artifact-content{white-space:pre-wrap;overflow-wrap:anywhere;background:#fafbfa;border:1px solid #e3e8e5;padding:18px;font:14px/1.5 Inter,Arial,sans-serif}
  .artifact-file-note{padding:16px;background:#fafbfa;border:1px solid #e3e8e5}
  footer{margin-top:70px;border-top:1px solid #d7ded9;padding-top:18px;font-size:12px;color:#5d6b64}
  @media print{
    main{max-width:none;padding:20mm 16mm}
    .cover{min-height:250mm;page-break-after:always}
    .phase{page-break-before:always}
  }
</style>
</head>
<body>
<main>
  <section class="cover">
    <small>SPARKs PE</small>
    <h1>${escapeHtml(reportTitle)}</h1>
    <p class="lead">Consolidação das versões selecionadas dos artefatos metodológicos registrados na Jornada Estratégica.</p>
    <p><strong>${escapeHtml(reportStatus)}</strong></p>
    <p>Gerado em ${escapeHtml(generatedAt.toLocaleString('pt-BR'))}.</p>
  </section>

  <section>
    <p class="eyebrow">Como ler este relatório</p>
    <h2>Consolidação governada</h2>
    <p>Este relatório reúne conteúdos já registrados na solução. A geração deste arquivo não cria evidência, aprovação, decisão institucional ou nova versão dos artefatos.</p>
    <div class="notice">
      <strong>${isFinalized ? 'Plano consolidado:' : 'Documento de trabalho:'}</strong>
      ${isFinalized
        ? ' a Jornada registrada no projeto está concluída. Este relatório continua subordinado aos registros canônicos e às validações existentes na solução.'
        : ' a Jornada ainda possui etapas ou validações pendentes. Este arquivo não deve ser apresentado como versão final institucional do Planejamento Estratégico.'}
    </div>
    <div class="notice">
      <strong>Regra de autoridade:</strong> em caso de divergência, prevalecem os registros canônicos e as validações existentes na solução SPARKs PE.
    </div>
    <p><strong>Organização:</strong> ${escapeHtml(organizationName)}<br>
    <strong>Projeto:</strong> ${escapeHtml(projectName)}<br>
    ${horizonLabel ? `<strong>Horizonte Estratégico:</strong> ${escapeHtml(horizonLabel)}<br>` : ''}
    <strong>Artefatos incluídos:</strong> ${artifacts.length}</p>
  </section>

  <section>
    <p class="eyebrow">Sumário executivo</p>
    <h2>Conteúdos consolidados</h2>
    <table>
      <thead><tr><th>Etapa</th><th>Artefato</th><th>Situação</th><th>Versão</th></tr></thead>
      <tbody>${summaryRows}</tbody>
    </table>
  </section>

  <section>
    <p class="eyebrow">Metodologia</p>
    <h2>Jornada Estratégica SPARKs</h2>
    <p>A leitura segue a sequência da Jornada: Preparação e Enquadramento, Diagnóstico Estratégico, Formulação Estratégica, Desdobramento Estratégico, Implementação e Mobilização, Monitoramento e Aprendizado.</p>
  </section>

  ${sections}

  <footer>
    Relatório emitido em modo de consulta. Nenhuma situação, validação ou decisão institucional foi alterada por esta geração.
  </footer>
</main>
</body>
</html>`
}
