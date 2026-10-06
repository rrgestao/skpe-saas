export type PerformanceDistributionItem = {
  label: string
  value: number
}

export type ExecutivePerformanceReportArgs = {
  organizationName: string
  projectName: string
  generatedAt: Date
  journey: {
    actualProgress: number | null
    plannedProgress: number | null
    variancePoints: number | null
    completedItems: number
    totalItems: number
    overdueItems: number
    currentMacrophaseName: string | null
    nextMilestoneName: string | null
    nextMilestoneTargetDate: string | null
  } | null
  portfolio: {
    total: number
    operationalUniverse: number
    averageOperationalProgress: number | null
    inProgress: number
    underAnalysis: number
    proposals: number
    blocked: number
    critical: number
    withoutDueDate: number
    attentionSignals: number
  }
  priorities: PerformanceDistributionItem[]
  areas: PerformanceDistributionItem[]
  classes: PerformanceDistributionItem[]
}

function escapeHtml(value: unknown) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;')
}

function percent(value: number | null) {
  return value == null ? '—' : `${value.toLocaleString('pt-BR', { maximumFractionDigits: 1 })}%`
}

function dateLabel(value: string | null) {
  if (!value) return '—'
  const date = new Date(`${value}T00:00:00`)
  if (Number.isNaN(date.getTime())) return value
  return new Intl.DateTimeFormat('pt-BR').format(date)
}

function distributionRows(items: PerformanceDistributionItem[]) {
  if (!items.length) return '<tr><td colspan="2">Sem leitura disponível.</td></tr>'
  return items
    .map((item) => `<tr><td>${escapeHtml(item.label)}</td><td>${item.value}</td></tr>`)
    .join('')
}

export function buildExecutivePerformanceReportHtml(args: ExecutivePerformanceReportArgs) {
  const { organizationName, projectName, generatedAt, journey, portfolio, priorities, areas, classes } = args
  const journeyStatus = journey
    ? `${journey.completedItems} de ${journey.totalItems} itens concluídos`
    : 'Leitura temporal indisponível'
  const variance = journey?.variancePoints == null
    ? '—'
    : `${journey.variancePoints >= 0 ? '+' : ''}${journey.variancePoints.toLocaleString('pt-BR', { maximumFractionDigits: 1 })}%`

  return `<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Relatório Executivo de Desempenho — SPARKs PE</title>
<style>
:root{font-family:Inter,Arial,sans-serif;color:#17251e;background:#fff}
body{margin:0;line-height:1.45}
main{max-width:1120px;margin:0 auto;padding:48px 56px 80px}
.cover{padding:36px 0 28px;border-bottom:4px solid #17251e}
.eyebrow{text-transform:uppercase;letter-spacing:.08em;font-size:12px;font-weight:800}
h1{font-size:38px;line-height:1.1;margin:8px 0 12px}
h2{font-size:24px;margin:34px 0 14px}
.grid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:12px}
.card{padding:16px;border:1px solid #d7ded9;border-radius:10px}
.card span{display:block;color:#5d6b64;font-size:12px}
.card strong{display:block;margin-top:6px;font-size:25px}
.note{margin:18px 0;padding:14px 16px;background:#f2f5f3;border-left:4px solid #17251e}
table{width:100%;border-collapse:collapse}
th,td{border:1px solid #d7ded9;padding:9px 10px;text-align:left}
th{background:#f2f5f3}
.cols{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:18px}
footer{margin-top:46px;padding-top:16px;border-top:1px solid #d7ded9;color:#5d6b64;font-size:12px}
@media print{main{padding:14mm}.cover{page-break-after:avoid}.cols{break-inside:avoid}}
</style>
</head>
<body>
<main>
<section class="cover">
<div class="eyebrow">SPARKs PE</div>
<h1>Relatório Executivo de Resultados e Desempenho</h1>
<p><strong>${escapeHtml(organizationName)}</strong><br>${escapeHtml(projectName)}</p>
<p>Gerado em ${escapeHtml(generatedAt.toLocaleString('pt-BR'))}.</p>
</section>

<div class="note"><strong>Leitura governada:</strong> este relatório apresenta somente dados já registrados na solução. Ausência de dado é apresentada como ausência; a geração não cria aprovação, evidência, meta, decisão institucional ou avanço da Jornada.</div>

<h2>Jornada Estratégica</h2>
<div class="grid">
<div class="card"><span>Realizado</span><strong>${percent(journey?.actualProgress ?? null)}</strong></div>
<div class="card"><span>Planejado até hoje</span><strong>${percent(journey?.plannedProgress ?? null)}</strong></div>
<div class="card"><span>Desvio</span><strong>${escapeHtml(variance)}</strong></div>
<div class="card"><span>Situação</span><strong>${escapeHtml(journeyStatus)}</strong></div>
</div>
<p><strong>Macrofase atual:</strong> ${escapeHtml(journey?.currentMacrophaseName ?? '—')}<br>
<strong>Próximo marco:</strong> ${escapeHtml(journey?.nextMilestoneName ?? '—')} — ${escapeHtml(dateLabel(journey?.nextMilestoneTargetDate ?? null))}<br>
<strong>Itens com desvio temporal:</strong> ${journey?.overdueItems ?? 0}</p>

<h2>Execução Estratégica</h2>
<div class="grid">
<div class="card"><span>Iniciativas visíveis</span><strong>${portfolio.total}</strong></div>
<div class="card"><span>Em execução</span><strong>${portfolio.inProgress}</strong></div>
<div class="card"><span>Progresso médio operacional</span><strong>${percent(portfolio.averageOperationalProgress)}</strong><span>Universo: ${portfolio.operationalUniverse} iniciativas elegíveis</span></div>
<div class="card"><span>Sinais para gestão</span><strong>${portfolio.attentionSignals}</strong></div>
</div>
<div class="grid" style="margin-top:12px">
<div class="card"><span>Propostas</span><strong>${portfolio.proposals}</strong></div>
<div class="card"><span>Em análise</span><strong>${portfolio.underAnalysis}</strong></div>
<div class="card"><span>Bloqueadas</span><strong>${portfolio.blocked}</strong></div>
<div class="card"><span>Críticas / sem término-alvo</span><strong>${portfolio.critical} / ${portfolio.withoutDueDate}</strong></div>
</div>

<h2>Composição do Portfólio</h2>
<div class="cols">
<section><h3>Por prioridade</h3><table><thead><tr><th>Prioridade</th><th>Qtd.</th></tr></thead><tbody>${distributionRows(priorities)}</tbody></table></section>
<section><h3>Por área responsável</h3><table><thead><tr><th>Área</th><th>Qtd.</th></tr></thead><tbody>${distributionRows(areas)}</tbody></table></section>
<section><h3>Por classe</h3><table><thead><tr><th>Classe</th><th>Qtd.</th></tr></thead><tbody>${distributionRows(classes)}</tbody></table></section>
</div>

<footer>Relatório emitido em modo de consulta. Os registros canônicos, validações e decisões existentes no SPARKs PE permanecem como autoridade.</footer>
</main>
</body>
</html>`
}
