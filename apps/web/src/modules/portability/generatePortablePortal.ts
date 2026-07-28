type JsonObject = Record<string, unknown>

type ExportDocument = {
  manifesto?: JsonObject
  dados?: JsonObject
}

const SECTION_LABELS: Record<string, string> = {
  organizacao: 'Organização',
  projeto: 'Projeto estratégico',
  skpe_journey_items: 'Jornada estratégica',
  skpe_evidence_sources: 'Evidências',
  skpe_assessment_findings: 'Riscos e lacunas',
  skpe_pestel_items: 'PESTEL',
  skpe_swot_items: 'SWOT',
  skpe_tows_items: 'TOWS',
  skpe_strategic_identity: 'Identidade estratégica',
  skpe_strategic_themes: 'Temas estratégicos',
  skpe_strategic_objectives: 'Objetivos estratégicos',
  skpe_okrs: 'OKRs',
  skpe_key_results: 'Resultados-chave',
  skpe_indicators: 'Indicadores',
  skpe_targets: 'Metas',
  skpe_initiatives: 'Iniciativas',
  skpe_5w2h_actions: 'Planos 5W2H',
  skpe_business_artifacts: 'Artefatos metodológicos',
  skpe_evidence_checklists: 'Validações',
  skpe_decisions: 'Decisões',
  skpe_learnings: 'Aprendizados',
}

function asObject(value: unknown): JsonObject {
  return value && typeof value === 'object' && !Array.isArray(value) ? value as JsonObject : {}
}

function asRows(value: unknown): JsonObject[] {
  return Array.isArray(value)
    ? value.filter((item) => item && typeof item === 'object').map((item) => item as JsonObject)
    : []
}

function escapeHtml(value: unknown): string {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;')
}

function humanize(key: string): string {
  return key
    .replace(/^skpe_/, '')
    .replaceAll('_', ' ')
    .replace(/\b\w/g, (char) => char.toUpperCase())
}

function displayValue(value: unknown): string {
  if (value === null || value === undefined || value === '') return '—'
  if (typeof value === 'boolean') return value ? 'Sim' : 'Não'
  if (typeof value === 'object') return JSON.stringify(value)
  return String(value)
}

function safeId(value: string): string {
  return value.toLocaleLowerCase('pt-BR').normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')
}

function renderKeyValueCards(data: JsonObject): string {
  const entries = Object.entries(data)
  if (!entries.length) return '<p class="empty-state">Nenhuma informação disponível.</p>'
  return `<div class="kv-grid">${entries.map(([key, value]) => `
    <article class="kv-card" tabindex="0">
      <span>${escapeHtml(humanize(key))}</span>
      <strong>${escapeHtml(displayValue(value))}</strong>
    </article>`).join('')}</div>`
}

function renderTable(sectionKey: string, rows: JsonObject[]): string {
  if (!rows.length) return '<p class="empty-state">Nenhum registro exportado.</p>'
  const keys = Array.from(new Set(rows.flatMap((row) => Object.keys(row))))
  const preferred = ['code', 'name', 'title', 'description', 'status', 'progress', 'responsible_user_id', 'due_date']
  const orderedKeys = [...preferred.filter((key) => keys.includes(key)), ...keys.filter((key) => !preferred.includes(key))]
  return `
    <div class="table-tools">
      <label>Pesquisar nesta seção
        <input type="search" class="section-search" data-target="table-${safeId(sectionKey)}" placeholder="Digite para filtrar registros">
      </label>
      <span>${rows.length} registro(s)</span>
    </div>
    <div class="table-wrap">
      <table id="table-${safeId(sectionKey)}">
        <thead><tr>${orderedKeys.map((key) => `<th>${escapeHtml(humanize(key))}</th>`).join('')}</tr></thead>
        <tbody>${rows.map((row) => `<tr tabindex="0">${orderedKeys.map((key) => `<td>${escapeHtml(displayValue(row[key]))}</td>`).join('')}</tr>`).join('')}</tbody>
      </table>
    </div>`
}

function renderSection(key: string, value: unknown): string {
  const label = SECTION_LABELS[key] ?? humanize(key)
  const id = safeId(key)
  const rows = asRows(value)
  const content = Array.isArray(value) ? renderTable(key, rows) : renderKeyValueCards(asObject(value))
  return `<section id="${id}" class="portal-section" data-searchable-section>
    <header class="section-heading">
      <div><span class="eyebrow">Gestão Estratégica</span><h2>${escapeHtml(label)}</h2></div>
      <button type="button" class="print-section" data-section="${id}" aria-label="Imprimir ${escapeHtml(label)}">Imprimir seção</button>
    </header>
    ${content}
  </section>`
}

export function createPortablePortal(documentData: ExportDocument): { blob: Blob; fileName: string } {
  const manifesto = asObject(documentData.manifesto)
  const dados = asObject(documentData.dados)
  const organization = asObject(dados.organizacao)
  const project = asObject(dados.projeto)
  const organizationName = displayValue(organization.trade_name ?? organization.name ?? 'Organização')
  const projectName = displayValue(project.name ?? project.title ?? 'Planejamento Estratégico')
  const logoValue = typeof organization.logo_url === 'string' ? organization.logo_url : ''
  const sections = Object.entries(dados).filter(([, value]) => value !== null && value !== undefined)
  const nav = sections.map(([key]) => `<a href="#${safeId(key)}">${escapeHtml(SECTION_LABELS[key] ?? humanize(key))}</a>`).join('')
  const sectionMarkup = sections.map(([key, value]) => renderSection(key, value)).join('')
  const embeddedJson = JSON.stringify(documentData).replaceAll('<', '\\u003c')

  const html = `<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="color-scheme" content="light">
<title>SPARKs PE | ${escapeHtml(organizationName)}</title>
<style>
:root{--green:#0f5a47;--green2:#2e7d66;--dark:#183029;--soft:#eaf3f0;--soft2:#f5f8f7;--line:#d7e2de;--text:#273a34;--muted:#66736f;--white:#fff;--shadow:0 14px 34px rgba(15,90,71,.12)}
*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;font-family:Inter,Segoe UI,Arial,sans-serif;color:var(--text);background:#f4f7f6;line-height:1.45}button,input{font:inherit}
a{color:inherit}.shell{display:grid;grid-template-columns:280px minmax(0,1fr);min-height:100vh}.sidebar{position:sticky;top:0;height:100vh;overflow:auto;background:var(--dark);color:var(--white);padding:24px}.brand{display:flex;align-items:center;gap:12px;margin-bottom:22px}.brand img{width:46px;height:46px;object-fit:contain;background:#fff;border-radius:12px;padding:5px}.brand-mark{width:46px;height:46px;border-radius:12px;background:var(--green2);display:grid;place-items:center;font-weight:800}.brand strong{display:block;font-size:18px}.brand small{opacity:.72}.sidebar nav{display:grid;gap:5px}.sidebar nav a{text-decoration:none;padding:10px 12px;border-radius:10px;color:#d9e7e2}.sidebar nav a:hover,.sidebar nav a:focus{background:rgba(255,255,255,.1);color:#fff;outline:none}.sidebar-actions{display:grid;gap:8px;margin-top:22px}.sidebar-actions button{border:1px solid rgba(255,255,255,.25);background:transparent;color:#fff;border-radius:10px;padding:10px;cursor:pointer}.sidebar-actions button:hover{background:rgba(255,255,255,.1)}.main{min-width:0}.hero{background:linear-gradient(135deg,var(--green),var(--green2));color:#fff;padding:42px clamp(22px,5vw,68px)}.hero .eyebrow{opacity:.75}.hero h1{margin:.2rem 0;font-size:clamp(30px,5vw,56px);line-height:1.05}.hero p{max-width:850px;font-size:17px;opacity:.88}.hero-grid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:12px;margin-top:26px}.hero-card{background:rgba(255,255,255,.12);border:1px solid rgba(255,255,255,.18);padding:16px;border-radius:14px}.hero-card span{display:block;font-size:12px;text-transform:uppercase;letter-spacing:.08em;opacity:.75}.hero-card strong{display:block;margin-top:5px;font-size:18px}.content{padding:28px clamp(18px,4vw,54px) 90px}.global-tools{position:sticky;top:0;z-index:10;display:flex;gap:12px;align-items:center;background:rgba(244,247,246,.96);backdrop-filter:blur(10px);padding:12px 0 16px}.global-tools label{flex:1}.global-tools input{width:100%;padding:12px 14px;border:1px solid var(--line);border-radius:12px;background:#fff}.global-tools button{border:0;background:var(--green);color:#fff;border-radius:12px;padding:12px 16px;cursor:pointer}.portal-section{background:#fff;border:1px solid var(--line);border-radius:18px;padding:22px;margin:0 0 22px;box-shadow:var(--shadow);scroll-margin-top:80px}.section-heading{display:flex;justify-content:space-between;align-items:start;gap:18px;border-bottom:1px solid var(--line);padding-bottom:14px;margin-bottom:18px}.section-heading h2{margin:.15rem 0;color:var(--dark)}.eyebrow{font-size:11px;text-transform:uppercase;letter-spacing:.12em;color:var(--green2);font-weight:800}.print-section{border:1px solid var(--line);background:#fff;border-radius:10px;padding:9px 12px;cursor:pointer}.print-section:hover{border-color:var(--green2);color:var(--green)}.kv-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:12px}.kv-card{border:1px solid var(--line);border-radius:14px;padding:14px;background:var(--soft2);transition:.18s transform,.18s box-shadow,.18s border-color}.kv-card:hover,.kv-card:focus{transform:translateY(-2px);box-shadow:0 10px 22px rgba(15,90,71,.11);border-color:var(--green2);outline:none}.kv-card span{display:block;color:var(--muted);font-size:12px}.kv-card strong{display:block;margin-top:6px;overflow-wrap:anywhere}.table-tools{display:flex;gap:14px;align-items:end;justify-content:space-between;margin-bottom:12px}.table-tools label{flex:1;max-width:540px;color:var(--muted);font-size:12px}.table-tools input{display:block;width:100%;margin-top:5px;padding:10px 12px;border:1px solid var(--line);border-radius:10px}.table-wrap{overflow:auto;border:1px solid var(--line);border-radius:12px}table{width:100%;border-collapse:collapse;min-width:760px}th,td{text-align:left;padding:11px 12px;border-bottom:1px solid var(--line);vertical-align:top}th{position:sticky;top:0;background:var(--soft);color:var(--dark);font-size:12px}tbody tr{transition:.15s background,.15s box-shadow}tbody tr:hover,tbody tr:focus{background:#f1f8f5;outline:2px solid rgba(46,125,102,.22);outline-offset:-2px}.empty-state{padding:20px;border:1px dashed var(--line);border-radius:12px;color:var(--muted);text-align:center}.hidden-section{display:none!important}.back-top{position:fixed;right:24px;bottom:24px;width:48px;height:48px;border:0;border-radius:50%;background:var(--green);color:#fff;font-size:22px;box-shadow:var(--shadow);cursor:pointer;opacity:0;pointer-events:none;transform:translateY(8px);transition:.2s}.back-top.visible{opacity:1;pointer-events:auto;transform:none}.footer{padding:22px;color:var(--muted);text-align:center;font-size:12px}
@media(max-width:1000px){.shell{grid-template-columns:1fr}.sidebar{position:relative;height:auto}.sidebar nav{grid-template-columns:repeat(auto-fit,minmax(180px,1fr))}.hero-grid{grid-template-columns:repeat(2,1fr)}}
@media(max-width:620px){.hero-grid{grid-template-columns:1fr}.section-heading,.table-tools,.global-tools{align-items:stretch;flex-direction:column}.global-tools{position:relative}.content{padding-inline:12px}.portal-section{padding:16px}.back-top{right:14px;bottom:14px}}
@media print{.sidebar,.global-tools,.back-top,.print-section{display:none!important}.shell{display:block}.hero{background:#fff!important;color:#000;padding:20px}.hero-card{border:1px solid #bbb;background:#fff}.content{padding:0}.portal-section{box-shadow:none;break-inside:avoid;border:1px solid #bbb}.hidden-section{display:block!important}body{background:#fff}}
</style>
</head>
<body>
<div class="shell">
  <aside class="sidebar">
    <div class="brand">${logoValue ? `<img src="${escapeHtml(logoValue)}" alt="Logo de ${escapeHtml(organizationName)}">` : '<div class="brand-mark">SP</div>'}<div><strong>SPARKs PE</strong><small>Portal Estratégico Portátil</small></div></div>
    <nav aria-label="Seções do portal">${nav}</nav>
    <div class="sidebar-actions"><button id="print-all" type="button">Imprimir portal</button><button id="download-json" type="button">Baixar JSON incorporado</button></div>
  </aside>
  <main class="main">
    <header class="hero">
      <span class="eyebrow">Portal Estratégico Portátil</span>
      <h1>${escapeHtml(organizationName)}</h1>
      <p>${escapeHtml(projectName)}. Visão executiva, rastreável e somente leitura, gerada pela Plataforma SPARKs.</p>
      <div class="hero-grid">
        <div class="hero-card"><span>Código da organização</span><strong>${escapeHtml(organization.code ?? manifesto.organization_code ?? '—')}</strong></div>
        <div class="hero-card"><span>Código do projeto</span><strong>${escapeHtml(project.code ?? manifesto.project_code ?? '—')}</strong></div>
        <div class="hero-card"><span>Versão do esquema</span><strong>${escapeHtml(manifesto.schema_version ?? '—')}</strong></div>
        <div class="hero-card"><span>Gerado em</span><strong>${escapeHtml(manifesto.generated_at ?? new Date().toISOString())}</strong></div>
      </div>
    </header>
    <div class="content">
      <div class="global-tools"><label><input id="global-search" type="search" placeholder="Pesquisar em todo o portal"></label><button id="clear-search" type="button">Limpar pesquisa</button></div>
      ${sectionMarkup}
    </div>
    <footer class="footer">Plataforma SPARKs | Gestão Estratégica Portátil | Documento somente leitura</footer>
  </main>
</div>
<button id="back-top" class="back-top" type="button" aria-label="Voltar ao topo">↑</button>
<script id="sparks-export-data" type="application/json">${embeddedJson}</script>
<script>
(function(){
  var backTop=document.getElementById('back-top');
  function goTop(){document.documentElement.scrollTo({top:0,behavior:'smooth'});document.body.scrollTo({top:0,behavior:'smooth'});window.scrollTo({top:0,behavior:'smooth'});}
  window.addEventListener('scroll',function(){backTop.classList.toggle('visible',window.scrollY>360);},{passive:true});
  backTop.addEventListener('click',goTop);
  document.getElementById('print-all').addEventListener('click',function(){window.print();});
  document.getElementById('download-json').addEventListener('click',function(){var raw=document.getElementById('sparks-export-data').textContent||'{}';var blob=new Blob([raw],{type:'application/json;charset=utf-8'});var a=document.createElement('a');a.href=URL.createObjectURL(blob);a.download='SPARKs_PE_dados_incorporados.json';a.click();setTimeout(function(){URL.revokeObjectURL(a.href);},1000);});
  document.querySelectorAll('.section-search').forEach(function(input){input.addEventListener('input',function(){var table=document.getElementById(input.dataset.target);var term=input.value.toLocaleLowerCase('pt-BR');table.querySelectorAll('tbody tr').forEach(function(row){row.style.display=!term||row.textContent.toLocaleLowerCase('pt-BR').includes(term)?'':'none';});});});
  var global=document.getElementById('global-search');
  function applyGlobal(){var term=global.value.toLocaleLowerCase('pt-BR').trim();document.querySelectorAll('[data-searchable-section]').forEach(function(section){section.classList.toggle('hidden-section',!!term&&!section.textContent.toLocaleLowerCase('pt-BR').includes(term));});}
  global.addEventListener('input',applyGlobal);document.getElementById('clear-search').addEventListener('click',function(){global.value='';applyGlobal();global.focus();});
  document.querySelectorAll('.print-section').forEach(function(button){button.addEventListener('click',function(){var section=document.getElementById(button.dataset.section);document.querySelectorAll('.portal-section').forEach(function(item){item.classList.toggle('hidden-section',item!==section);});window.print();document.querySelectorAll('.portal-section').forEach(function(item){item.classList.remove('hidden-section');});});});
})();
</script>
</body>
</html>`

  const organizationCode = String(manifesto.organization_code ?? organization.code ?? 'ORGANIZACAO').replace(/[^A-Za-z0-9_-]+/g, '_')
  const timestamp = new Date().toISOString().replace(/[-:]/g, '').replace(/\..+/, '').replace('T', '_')
  return {
    blob: new Blob([html], { type: 'text/html;charset=utf-8' }),
    fileName: `SPARKs_PE_Portal_${organizationCode}_${timestamp}.html`,
  }
}
