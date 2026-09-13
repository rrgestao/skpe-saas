---
id: sk-pe-current-state
title: Estado atual e baseline conceitual do SKPE-PAAS
domain: products
product: sk-pe
type: current-state
status: canonical
owner: product
canonicality: canonical
canonical: true
criticality: high
parent:
- sk-pe-product-hub
related:
- sk-pe-master-roadmap
- sk-pe-capability-execution-and-traceability
- skpe-med-des-01
- skpe-mon-anl-01-cockpit-resultados-desempenho
- specification-driven-architecture-hub
tags:
- sk-pe
- current-state
- conceptual-baseline
- specification-driven
- brownfield
language: pt-BR
encoding: UTF-8
semantic_layer: canonical-product-current-state
created: '2026-09-12'
updated: '2026-09-12'
lineage:
- repository: sparkooptech/skpe-saas
  branch: feature/formulacao-estrategica-operacional
  sha: d27373cc16740dfc86eb940abf639e322b072cc8
- repository: br-robson/projetos
  source_branch: origin/main
  source_sha: 2915073884fefa1a7bd98a7775df5f37a5f85ec9
- ./README.md
- ./roadmap.md
- ../../ecosystem/architecture/specification-driven/README.md
---

# Estado atual e baseline conceitual do SKPE-PAAS

## Identidade e autoridade da baseline

```text
PRODUCT=SKPE-PAAS
SOURCE_REPOSITORY=sparkooptech/skpe-saas
SOURCE_BRANCH=feature/formulacao-estrategica-operacional
SOURCE_SHA=d27373cc16740dfc86eb940abf639e322b072cc8
BASELINE_DATE=2026-09-12
BASELINE_METHOD=SPECIFICATION_DRIVEN_RECONCILIATION
BASELINE_STATUS=BASELINED_WITH_EXPLICIT_CONFLICTS_AND_UNKNOWNS
CODE_BASELINE=d27373cc16740dfc86eb940abf639e322b072cc8
DOCUMENTATION_BASELINE_SOURCE=2915073884fefa1a7bd98a7775df5f37a5f85ec9
DOCUMENTATION_BASELINE_TARGET_BRANCH=docs/skpe-specification-driven-baseline-20260912
RUNTIME_BASELINE=PARTIAL_PUBLIC_HTTP_ONLY
```

Este é o owner canônico de estado atual e rastreabilidade do produto; não substitui [Roadmap](roadmap.md), [Medidas](capabilities/SKPE-MED-DES-01-medidas-desempenho.md), [Cockpit](capabilities/SKPE-MON-ANL-01-cockpit-resultados-desempenho.md) ou [Governança](governance/capability-execution-and-traceability.md). A busca no product space encontrou esses cinco documentos e nenhum current-state/architecture/specification próprio que cobrisse esta responsabilidade. Por isso foi criado **um** owner, seguindo a convenção current-state já usada no Vault, sem criar diretórios architecture/ ou specifications/.

Autoridade desta baseline: fatos investigados no SHA, reconciliação e limites. Intenções conflitantes continuam pendentes de decisão Product; canonicalidade não aprova regra inferida nem certifica produto especificado. A revisão documental resultante é identificada pelo commit Git que contém este documento; SOURCE_SHA sempre identifica o produto, não o Corporate.

## Método e escopo

Aplicação explícita da [fundamentação specification-driven](../../ecosystem/architecture/specification-driven/README.md): **Memory → Investigation → Reconciliation → Conceptual Baseline → Specification**. Memory foram os owners e requisitos históricos; Investigation foi código, contratos, migrations, testes, Git e HTTP anônimo; Reconciliation confronta AS-* abaixo; esta entrega materializa a Conceptual Baseline. Specification completa não é resultado automático.

AS-INTENDED vem de decisões registradas no Corporate ou intenção documentada explicitamente qualificada; requisitos DEV históricos não recebem autoridade Corporate nova. AS-DOCUMENTED preserva a revisão original. AS-IMPLEMENTED é código/SQL, não prova de implantação. AS-OBSERVED limita-se aos testes locais executados e ao HTTP público descrito.

Preflight: produto limpo, origin canônico, upstream origin/feature/formulacao-estrategica-operacional e remoto no mesmo SHA. Corporate original em docs/sk-viva-specification-001/016c55933ee71a1f4149817308f42146e25e3638, dirty preexistente e preservado. Após fetch origin --prune autorizado, worktree novo criado de origin/main/2915073884fefa1a7bd98a7775df5f37a5f85ec9; branch nova inexistente local/remotamente antes da criação, worktree inicialmente limpo. Nenhum stash/reset/clean ou alteração de arquivo no checkout original.

Escopo: todos os módulos funcionais inventariados, chamadas literais em 59 arquivos frontend, triagem de 213 migrations, aprofundamento HIGH_VALUE, 18 arquivos de testes TS, SQL seletivo, owners SK-PE e história dirigida. Não inclui leitura integral de todos os arquivos, todas as migrations, outras estações/branches, login autenticado, banco remoto ou teste visual.

## Inventário de capabilities

As chaves Bxx são linhas estáveis **desta baseline**, não novos IDs corporativos de capabilities. IDs existentes SKPE-MED-DES-01 e SKPE-MON-ANL-01 foram preservados. IMPLEMENTED significa implementação do recorte descrito, sem aceite funcional implícito; PARTIAL indica que o recorte amplo ainda possui lacunas; CONFLICT prevalece quando há divergência material. Zero em DOCUMENTED_ONLY significa nenhum caso classificado assim neste recorte, não inexistência de documentação sem código no produto inteiro.

Contagem: **31 recortes** — IMPLEMENTED=12, PARTIAL=12, DOCUMENTED_ONLY=0, INTENDED=2, UNKNOWN=1, CONFLICT=4.

| ID / CAPABILITY | STATUS | IMPLEMENTATION_EVIDENCE | DATABASE_EVIDENCE | TEST_EVIDENCE | DOCUMENTATION_EVIDENCE |
| --- | --- | --- | --- | --- | --- |
| B01 — Autenticação e sessão | IMPLEMENTED | [APP]; login por senha, sessão, recuperação e logout | [M20260725040414]; profiles/auth.users, memberships e helpers | Sem teste autenticado identificado | [Reconciliação IAM](../../ecosystem/architecture/identity-access-tenancy-reconciliation.md) |
| B02 — Organizações, hierarquia e contexto | IMPLEMENTED | [ORG]; portal distingue acesso direto/hierárquico | [M20260725031733] + [M20260727215000] + [M20260801003000] | [T-organizationHierarchy] | [Reconciliação IAM](../../ecosystem/architecture/identity-access-tenancy-reconciliation.md) |
| B03 — Administração, usuários, papéis e auditoria | PARTIAL | [ADMIN]; RPCs de perfis/memberships/roles e Edge Functions | [M20260829135123]; papéis organizacionais separados de acesso | [T-platformAdminOrganizationalRoles] | [Reconciliação IAM](../../ecosystem/architecture/identity-access-tenancy-reconciliation.md); [Governança](governance/capability-execution-and-traceability.md) |
| B04 — Jornada e cronograma metodológico | IMPLEMENTED | [JOURNEY]; leitura temporal e transição com justificativa | [M20260727003000] + [M20260816131440] + [M20260818225044] | [T-journeyItemStatusChange]; [T-journeyEventDateTime] | [Roadmap](roadmap.md); [Governança](governance/capability-execution-and-traceability.md) |
| B05 — Evidências, checklists e proveniência | PARTIAL | [EVID]; leitura de projeção e versões de checklist | [M20260905133824] + [M20260905131345]; assets, links e avaliações contextuais | Sem teste dedicado identificado | [Governança](governance/capability-execution-and-traceability.md); [Medidas](capabilities/SKPE-MED-DES-01-medidas-desempenho.md) |
| B06 — Leitura de PESTEL | IMPLEMENTED | [DIAG]; [DIAG-LOAD]; tabela canônica e fallback staging | [M20260906144500]; skpe_pestel_items, scope e origem da importação | [T-strategic-diagnosis-import-loader] | [Roadmap](roadmap.md); [Medidas](capabilities/SKPE-MED-DES-01-medidas-desempenho.md) |
| B07 — Leitura de SWOT | IMPLEMENTED | [DIAG]; [DIAG-LOAD]; tabela canônica e fallback staging | [M20260906144500]; skpe_swot_items, scope e origem da importação | [T-strategic-diagnosis-import-loader] | [Roadmap](roadmap.md); [Medidas](capabilities/SKPE-MED-DES-01-medidas-desempenho.md) |
| B08 — Leitura de TOWS | IMPLEMENTED | [DIAG]; [DIAG-LOAD]; tabela canônica e fallback staging | [M20260906144500]; skpe_tows_items, scope e origem da importação | [T-strategic-diagnosis-import-loader] | [Roadmap](roadmap.md); [Medidas](capabilities/SKPE-MED-DES-01-medidas-desempenho.md) |
| B09 — Riscos estratégicos e mitigação | PARTIAL | [RISK]; diagnóstico e projeções de sugestões | [M20260906190500]; vínculo risco/iniciativa/ação, 5W2H e evidência residual | Sem teste dedicado de mitigação identificado | [Roadmap](roadmap.md); [Cockpit](capabilities/SKPE-MON-ANL-01-cockpit-resultados-desempenho.md) |
| B10 — Formulação e versionamento | CONFLICT | [FORM]; busca draft/under_review/approved | [M20260730033000] + [M20260730040000]; lifecycle não contém under_review | [T-skpeRoutes] não cobre lifecycle | [FE02] |
| B11 — Identidade estratégica | PARTIAL | [IDENTITY]; leitura PMVV, itens e valores | [M20260730043000]; operações/validação do pacote de identidade | Sem teste dedicado identificado | [FE03] |
| B12 — Fundamentação do negócio, canvas e cadeia de valor | PARTIAL | [CANVAS]; canvas, criação e itens | [M20260730050000]; platform_business_artifacts e snapshots de insumos | Sem teste dedicado identificado | [FE04] |
| B13 — Temas, perspectivas, objetivos, BSC e relações causais | PARTIAL | [BSC]; leitura RPC, relações canônicas e sugestões contextuais | [M20260730060000]; pacote, relações e política de ciclos warn/block | [T-strategic-map-adapter]; [T-strategic-bsc-layout]; [T-strategic-cause-effect-suggestions] | [FE05]; [Cockpit](capabilities/SKPE-MON-ANL-01-cockpit-resultados-desempenho.md) |
| B14 — Indicadores e catálogo organizacional de medidas | CONFLICT | [MEAS]; adoção em 372; [DUAL] | [M20260908015851] + [M20260909214455] + [M20260909234252] | Sem teste dedicado de adoção identificado | [Medidas](capabilities/SKPE-MED-DES-01-medidas-desempenho.md) |
| B15 — Metas e tolerâncias | PARTIAL | [MEAS]; leitura da meta contextual | [M20260730070000] + [M20260904234019]; targets distintos de benchmarks | Sem teste dedicado identificado | [Medidas](capabilities/SKPE-MED-DES-01-medidas-desempenho.md); [FE06] |
| B16 — Benchmarks de referência e organizacionais | PARTIAL | [BENCH]; editar/transicionar benchmark; catálogo em PlatformMeasureCatalog | [M20260908170508] + [M20260908220330]; catálogo, versões, remoção de draft | Sem teste dedicado identificado | [Medidas](capabilities/SKPE-MED-DES-01-medidas-desempenho.md); [FE06] |
| B17 — Medições, desempenho e snapshots | CONFLICT | [MEAS]; última apuração e performance | [M20260730100000] + [M20260908015851]; leitura da última measurement sem filtro de validação | Sem teste dedicado de seleção de measurement identificado | [FE09]; [Medidas](capabilities/SKPE-MED-DES-01-medidas-desempenho.md) |
| B18 — Cockpit de Resultados e Desempenho | CONFLICT | [ANALYTICS]; cards, distribuições, atenção e drill-down | [M20260906201500]; dashboard exclui proposed/under_analysis da média | Sem teste analítico dedicado identificado | [Cockpit](capabilities/SKPE-MON-ANL-01-cockpit-resultados-desempenho.md) |
| B19 — OKRs e resultados-chave | PARTIAL | [OKR]; leitura e composição local OE/KPI/KR/iniciativa | [M20260730080000] + [M20260904164552]; pacotes, aplicabilidade e qualidade semântica | Sem teste dedicado do ciclo OKR identificado | [FE07] |
| B20 — Portfólio e lifecycle de iniciativas | IMPLEMENTED | [PORT]; criação/transição e vínculos estratégicos | [M20260820145252] + [M20260906201500]; convergência sparks/skpe e rascunhos | Contratos auxiliares de ações; sem teste de integração do portfólio | [FE08]; [Cockpit](capabilities/SKPE-MON-ANL-01-cockpit-resultados-desempenho.md) |
| B21 — Ações, 5W2H e kanban | IMPLEMENTED | [ACTIONS]; board, criação, execução e responsabilidade | [M20260821094420] + [M20260727032500]; lifecycle e 5W2H legado | [T-initiativeActionDraftGovernance]; [T-initiativeActionEconomics] | [FE08] |
| B22 — Economia e capacidade de pessoas | IMPLEMENTED | [CAPACITY]; períodos, alocações e trilha de auditoria | [M20260826225500] + [M20260827195359]; unidades/lifecycle | [T-personCapacity]; [T-personCapacityAudit]; [T-initiativeActionCapacityAllocationEditing]; [T-initiativeActionCapacityAudit] | [Roadmap](roadmap.md); [FE08] |
| B23 — Monitoramento integrado e timeline | IMPLEMENTED | [MONITOR]; matriz/timeline da projeção operacional | [M20260828163046]; projeção operacional integrada | [T-monitoringExecutionMatrix]; [T-monitoringTimeline] | [FE09]; [Cockpit](capabilities/SKPE-MON-ANL-01-cockpit-resultados-desempenho.md) |
| B24 — RAE, reuniões, análise e decisões | PARTIAL | [RAE]; análise, síntese, decisões e ratificação no HEAD | [M20260730100000]; ratify_skpe_strategy_review em 3530 | Sem teste dedicado RAE identificado | [FE09]; [Governança](governance/capability-execution-and-traceability.md) |
| B25 — Agenda, eventos e participantes | IMPLEMENTED | [AGENDA]; agenda pessoal e diálogos de eventos/participantes | [M20260825003000] + [M20260829232922]; projeção com prazos | [T-journeyEventDateTime] | [FE10] |
| B26 — Horizontes e ciclos de evolução | PARTIAL | [EVOLUTION]; leitura e alinhamento de objetivos | [M20260818120356] + [M20260818141323]; cenário/plano/ciclo e vigência | [T-skpeRoutes] cobre rota, não aprovação | [Roadmap](roadmap.md) |
| B27 — Importação e exportação portátil | PARTIAL | [IMPORT]; simular/revisar staging; [EXPORT] | Staging: [M20260728183000]; materialização KR: [M20260814142445] | [T-parseCanonicalWorkbook] | [FE10] |
| B28 — Artefatos metodológicos e kit de entrega | UNKNOWN | [ARTIFACT]; [KIT] | [M20260728133000]; detalhe/status/storage; 7 RPCs sem definição localizada | Sem teste dedicado identificado | [Governança](governance/capability-execution-and-traceability.md) |
| B29 — Meu Espaço de Trabalho e notificações | IMPLEMENTED | [WORKSPACE]; painéis pessoais, favoritos e estado de leitura | [M20260805200500] + [M20260808130000] + [M20260830225217] | Rotas testadas; sem teste integrado dos painéis | [DOC-WORKSPACE] |
| B30 — Reuso de Medidas por outros produtos | INTENDED | Fachadas nomeadas transversalmente; adapter implementado restrito a SK-PE | [M20260904234019]; falha fechada para módulo/contexto/sujeito não suportado | Sem teste cross-product identificado | [Medidas](capabilities/SKPE-MED-DES-01-medidas-desempenho.md) |
| B31 — Escala produtiva e confiabilidade | INTENDED | Descritor de HOMOL existe; operação PRD não demonstrada | Banco efetivo, backup e restauração não auditados | Sem teste de recuperação executado | [Roadmap](roadmap.md) |

## Arquitetura funcional atual

`FATO / AS-IMPLEMENTED`. Aplicação browser React 19/TypeScript, construída com Vite 8; versões declaradas no [package web][PKG]. Entrada [main.tsx][ENTRY] → BrowserRouter → [App][APP] → [SkpeWorkspace][ROUTE-ADAPTER] → [SkpeCockpit][CANVAS]. O root package só declara CLI Supabase de desenvolvimento. Não foi identificado backend HTTP próprio separado das Edge Functions no inventário do repositório.

| Dimensão | Modelo encontrado e limite |
| --- | --- |
| APPLICATION_ENTRYPOINTS | apps/web/index.html e main.tsx; três Edge Functions Deno: criação de usuário, criação chamada convite e consulta de CEP. |
| FRONTEND_STACK | React/TypeScript, react-router-dom 7, SVAR Grid/Gantt, React Flow, ExcelJS, JSZip e componentes próprios. |
| BACKEND_MODEL | Supabase SDK no browser → tabelas/views/RPCs PostgreSQL; Auth/Storage e Edge Functions para operações específicas. |
| DATABASE_MODEL | PostgreSQL, schema public com escopo organizacional/projeto/formulação; FKs, RLS, funções, triggers e registros de auditoria. Modelo versionado, não introspecção do banco atual. |
| AUTH_MODEL | Supabase Auth; sessão cliente; memberships, habilitação de módulo, roles/permissões e helpers no banco. Super-admin e acesso hierárquico possuem regras específicas. Contexto UI não concede autorização. |
| ROUTING_MODEL | Parser/gerador próprio sobre BrowserRouter; /organizations/:org/skpe/projects/:project/formulations/:formulation/:section; compatibilidade com query section. C05 registra limites da propagação. |
| STATE_MODEL | useState/useEffect/useMemo e SkpeWorkspaceContext; localStorage para preferências, layout BSC e lote de importação. Estado de negócio é consultado por SDK. |
| DEPLOYMENT_MODEL | Docker multi-stage Node 24 → Nginx 1.28/8080, Compose e labels Traefik; healthz estático. Workflow GitHub Actions em push main/manual. C06 registra drift de hostname/branch. |
| TEST_MODEL | Node test runner com strip-types: 18 arquivos TS; testes puros e uma área de inspeção estática de source. SQL de teste/verificação separado. Sem pipeline de testes identificado no único workflow inventariado, que é de deploy. |
| MIGRATION_MODEL | 213 arquivos SQL nomeados temporalmente (25/07 a 09/09); substituições de funções e hardening sucessivos. Inventário não prova replay completo nem migrations aplicadas. |
| DOMAIN_MODULES | platform-admin, skpe, measures, initiatives, portability. SKPE contém jornada, diagnóstico, estratégia, evolução, monitoramento, agenda e artefatos. |
| SHARED_COMPONENTS | ApplicationShell, TransversalWorkspace, design-system/SparksSmartGrid, cards, branding, perfil e catálogo PT-BR; não são novos produtos. |
| CROSS_PRODUCT_COMPONENTS | sparks_initiatives, sparks_people/capacity, sparks_event*, sparks_evidence_* e fachadas sparks_measure_*; reuso técnico por outro produto não demonstrado. |
| EXTERNAL_DEPENDENCIES | Supabase (Auth/PostgreSQL/Storage/Edge), ViaCEP, registries npm/esm.sh, GitHub Actions e infraestrutura Docker/Traefik. Contas, planos, SLA e configurações remotas não investigados. |

As escolhas atuais são [implementação específica do produto](../../ecosystem/architecture/existing-product-implementation-vs-corporate-standard.md), não padrão corporativo de backend/IdP. Nenhum replatforming é proposto.

### Superfícies, leituras e escritas

| Superfície / intenção do usuário | Fonte e fronteira |
| --- | --- |
| Portal e administração: escolher organização, acessar módulo, gerir perfis | [App][APP] consulta get_my_organizations_v2/get_my_modules e tabelas organizations/memberships; [Admin][ADMIN] invoca RPCs e Edge Functions. Storage de logos/avatars usa SDK. |
| Jornada: acompanhar gates, datas e execução | [Jornada][JOURNEY] usa get_skpe_journey_temporal_read_model; planner lê schedule tables e escreve por RPCs de versão/item/transição; status exige razão. |
| Diagnóstico: interpretar contexto e origem dos instrumentos | [Loader][DIAG-LOAD] consulta dinamicamente skpe_pestel_items/swot/tows/strategic_risk_items. Só se a consulta canônica retorna vazia usa registros válidos de staging; erro canônico é erro, não fallback silencioso. |
| Formulação: consultar identidade, mapa, desdobramento e plano | [Formulação][FORM] e [OKR][OKR] leem tabelas diretamente. [BSC][BSC] usa get_skpe_strategic_map e vínculos de iniciativas. Agregações/seleções locais não substituem regra de banco. |
| Medidas: consultar por contexto e administrar adoções | [Workspace][MEAS] chama get_sparks_measure_performance_context; catálogos e adoções usam RPCs. [Dual selector][DUAL] escreve adoção/arquivamento organizacional. [Benchmarks][BENCH] possui escrita/transição. |
| Portfólio, kanban, cronograma e exploração | [Data layer][PORT] reutiliza get_sparks_initiatives_portfolio/dashboard; [ações][ACTIONS] usam RPCs de lifecycle/responsabilidade/capacidade. Sugestões SKPE convivem com iniciativas SPARKS. |
| Cockpit analítico: identificar atenção e navegar ao operacional | [Analytics][ANALYTICS] recebe portfólio/dashboard, deriva distribuições e filtros locais, resolve formulação única e delega mapa/drill-down. Não equivale a todo o SkpeCockpit, que também é shell funcional. |
| Monitoramento e RAE: analisar execução e formalizar decisões | [Monitoramento][MONITOR] lê projeção operacional; [RAE][RAE] lê reviews/decisões/performance e escreve por RPCs, com síntese e ratificação. |
| Agenda e Meu Espaço: organizar trabalho pessoal | [Agenda][AGENDA] usa get_my_sparks_agenda; [Meu Espaço][WORKSPACE] usa preferências e painéis pessoais. Eventos reais e prazos projetados permanecem distinguíveis no modelo. |
| Portabilidade e entregáveis | [Importação][IMPORT] escreve staging e simula; [exportação][EXPORT] gera pacotes JSON/XLSX/HTML/ZIP. [Artefatos][ARTIFACT] dependem de contratos incompletamente rastreados (U02). |

Esta é arquitetura funcional extraída, sem auditoria pixel/layout. Chamadas construídas dinamicamente foram inspecionadas no diagnóstico; o índice local de chamadas literais é auxiliar, não cobertura completa de todas as chamadas possíveis.

## Dados, contratos e mineração brownfield

`FATO`. Os 213 nomes e declarações estruturais foram inventariados antes da seleção HIGH_VALUE. Aprofundamento foi dirigido por consumidor, objeto, substituição de função, status, autorização e proveniência; não se declara leitura integral das 213 migrations. O registro de evidências ao final aponta os arquivos selecionados, enquanto o pacote local mantém inventário completo.

| Grupo HIGH_VALUE | Conhecimento extraído / evolução |
| --- | --- |
| Fundação organizacional e IAM | organizations/profiles/memberships → módulos/roles → hierarquia v3 e leitura descendente → capacidades integradas (28/08) → mutações de papéis organizacionais (29/08). A política inicial não representa automaticamente a final. |
| Jornada | Projeto e itens hierárquicos → templates/gates → rollup hierárquico → versões de cronograma → read-model temporal → execução real/eventos. Rollup considera filhos obrigatórios elegíveis e separa gates, cancelados e arquivados. |
| Formulação FE-00–FE-08 | Formulação versionada; identidade/valores; insumos de negócio compartilhados; temas/perspectivas/objetivos/relações; indicadores/metas/benchmarks; OKRs/KRs; iniciativas; monitoramento/reviews/snapshots. Guards e readiness não comprovam aprovação real no banco. |
| Diagnóstico e risco | PESTEL/SWOT/TOWS/riscos em tabelas próprias com source_import_record_id, origem externa, planilha/linha/payload. Mitigação relaciona risco, iniciativa e ação; risco residual avaliado exige probabilidade, impacto, produto coerente e referência de evidência. |
| Iniciativas transversais | sparks_initiatives/actions e bindings SKPE → lifecycle/responsabilidades/rollup → portfólio → inclusão de rascunhos SKPE ainda não promovidos. Convergência é parcial, não substituição total das tabelas skpe_initiatives. |
| Medidas | Base SKPE → catálogo → views security_invoker sparks_measure_* → fachadas de escrita → leitura pessoal/contextual → adoção organizacional. A última migration amplia origem para referência ou legacy_indicator_id e contém reconciliação pontual de um registro; não é regra de backfill universal. |
| Monitoramento/RAE | Medições, check-ins e snapshots separados de definição estratégica; ratify_skpe_strategy_review exige ciclo em análise/ratificação, permissão, estado válido, data, síntese, conclusões e razão auditável. Frontend RAE do HEAD consome essas funções preexistentes. |
| Evidências | Assets, usos/links e avaliações contextuais separados; a view calcula disponibilidade, validade, qualidade e suficiência sem equiparar existência do ativo a adequação ao uso. |
| Importação/artefatos | Staging, conflitos, eventos e materializadores específicos não equivalem a importação definitiva universal. Artefatos metodológicos têm dependências SQL sem definição localizada nesta revisão. |

### Semântica que pode ser afirmada nesta revisão

- **Indicador → KR existe fisicamente:** skpe_indicators.key_result_id e scope key_result_indicator; a view transversal prioriza esse sujeito quando presente. Isso reduz o unknown físico anterior, mas não prova que o adapter de escrita o suporte: sparks_upsert_measure_indicator rejeita sujeito diferente de strategic_objective.
- **Meta contextual:** get_sparks_measure_performance_context escolhe uma meta não superseded, priorizando período corrente, depois futuro; lê a última medição e o benchmark mais recente por verificação/atualização. São escolhas de implementação, não critérios de produto ratificados nesta wave.
- **Ausência de apuração:** o read-model retorna not_assessed quando não há measurement; não cria valor zero nesse caso. A seleção de measurement não filtra validated e é divergência C04.
- **Snapshot não é valor corrente:** FE-08 preserva histórico/supersessão e restringe mutação de snapshots. A função de performance delega ao cálculo de progresso de KR; thresholds de pacote produzem not_assessed/critical/attention/achieved/on_track.
- **Proveniência:** tabelas de diagnóstico mantêm referência de importação; RAE e operações governadas gravam razões/atores. Efetividade e completude desses registros em runtime permanecem UNKNOWN.
- **Reprodução do banco:** existência de migrations não comprova bootstrap íntegro. Sete RPCs literais consumidas não possuem definição encontrada nas 213 migrations; não se executou replay para tentar corrigir isso.

## Runtime e deployment conhecido

`RUNTIME_BASELINE=PARTIAL_PUBLIC_HTTP_ONLY`

URL canônica: [HOMOL](https://sparks-homol.sparkoop.com), conforme [owner de deployment](../../ecosystem/infrastructure/deployment-map.md) e [DNS/entrada pública](../../ecosystem/infrastructure/dns-and-public-entry.md).

| Fonte | Revisão / estado |
| --- | --- |
| Código auditado | d27373cc16740dfc86eb940abf639e322b072cc8, local e remoto da branch de produto coincidentes no preflight. |
| Último deployment documentado no Corporate-base | 3f2f25cf02d887b878ac1ee8e9b04724c0fef4f3; imagem skpe-saas-homol:3f2f25c; deploy/cutover técnicos PASS em 11/09; aceite interativo pendente. É registro histórico, não consulta runtime desta wave. |
| Deployment declarado na abertura pelo usuário | d27373cc16740dfc86eb940abf639e322b072cc8. DEPLOYED_SHA_STATUS=DECLARED_NOT_RUNTIME_VERIFIED. |
| Observação desta wave, 12/09 às 16:52:09 UTC | GET /healthz = 200 e corpo ok; GET / = 200 e elemento root da SPA. Sem login, consulta ao banco ou inspeção de container. |
| DEPLOYED_SHA efetivo | UNKNOWN. Shell/health não expõem prova de revisão; não assumir SOURCE_SHA = DEPLOYED_SHA. |

Build contratual [Dockerfile][DOCKER], [Nginx][NGINX], [Compose][DEPLOY] e [workflow][WF] são AS-IMPLEMENTED. Não provam configuração de Traefik/DNS atual. Divergências C06/C07 permanecem abertas. Não houve deploy, alteração de ambiente, escrita Supabase ou operação PRD.

## Testes e contratos protegidos

Execução local em 12/09/2026, no SHA da baseline: `node --experimental-strip-types --test tests/*.test.ts`, a partir de apps/web. **124 testes, 124 PASS, 0 FAIL, 0 SKIP**. Nenhum build foi executado nesta wave; nenhum teste SQL foi executado. Os testes locais são evidência de AS-OBSERVED somente para as funções/checagens testadas, nunca de aceite do runtime HOMOL.

| TEST_AREA | CONTRACT_PROTECTED | COVERAGE_SIGNAL / RELEVANCE |
| --- | --- | --- |
| Rotas e hierarquia | encode/decode, seções conhecidas, pai antes de filhos | Testes puros PASS; não cobrem propagação do contexto ao banco. |
| Importação | workbook v26, alias legado, corrupção/abas; prioridade de registros reconciliados | PASS; não executa carga definitiva nem valida migrations remotas. |
| BSC | posições válidas, objetivos/relações canônicas, agrupamento, sugestões por assinatura exata | PASS; sem aceite de causalidade ou saúde de objetivos. |
| Jornada/tempo | justificativa e timezone IANA/DST | PASS; não realiza evento nem transição no banco. |
| Capacidade/economia | unidades, negativos, intervalos, lifecycle, justificativa, rascunhos e auditoria | PASS; sem conversão indevida de grandezas, mas sem teste de RLS. |
| Monitoramento | janela por datas disponíveis, rollup local e matriz sem score composto | PASS; sinal de contrato de projeção. |
| Papéis organizacionais | presença de categorias/RPCs e ações no source da UI | PASS estático; não equivale a teste interativo de criação/revogação. |
| SQL de rollup e verification FE-00–FE-09 | assertions/transações e consultas de schema/permissão versionadas | Inspecionados seletivamente, NÃO EXECUTADOS; teste de rollup insere fixtures e faz rollback, por isso não foi executado contra o banco. |

Não foram encontrados testes dedicados de RAE, da adoção de catálogo e das divergências analíticas C02–C04 nos 18 arquivos TS. O nome strategic-diagnosis-import-loader.test.ts cobre o reconciliador, não a integração do loader ao Supabase. Binding exaustivo REQUIREMENT ↔ teste ↔ CI permanece parcial; não declarar SPEC-AS-AUTHORITY.

## Reconciliação AS-* por capability

Nesta matriz, AS-DOCUMENTED é o documento indicado na última coluna do inventário; AS-IMPLEMENTED é o recorte e os contratos das colunas de evidência. AS-OBSERVED é **UNKNOWN para o fluxo autenticado de cada linha**; os testes específicos do inventário, quando presentes, passaram localmente e têm os limites descritos na seção de testes. As colunas de intenção, status, gap, decisão e autoridade completam a reconciliação sem confundir evidência local com runtime.

| ID | AS-INTENDED / proveniência | RECONCILIATION_STATUS | AUTHORITY | GAP / DECISION_NEEDED | MATURITY |
| --- | --- | --- | --- | --- | --- |
| B01 | Autenticação separada de contexto e autorização; decisão Corporate registrada | PARTIALLY_ALIGNED | Architecture/Security; Product para adoção | Revogação, MFA, isolamento efetivo e configuração do IdP remoto UNKNOWN | BASELINED |
| B02 | Vínculo e leitura contextual; organização não prova tenant corporativo | PARTIALLY_ALIGNED | Product; DEV valida implementação | Árvore e ordenação testadas; leitura descendente real não exercitada | BASELINED |
| B03 | Administração contextual e auditável | PARTIALLY_ALIGNED | Product; DEV valida implementação | Teste estático de source; invite-platform-user cria usuário diretamente, não comprova convite aceito; auditar lifecycle real | BASELINED |
| B04 | Jornada integrada à execução; regras detalhadas derivadas permanecem AS-IMPLEMENTED | PARTIALLY_ALIGNED | Product; DEV valida implementação | Rollup SQL inspecionado, não executado; execução de gates metodológicos no banco UNKNOWN | BASELINED |
| B05 | Preservar evidência e proveniência; disponível não equivale a suficiente | PARTIALLY_ALIGNED | Product; DEV valida implementação | População, completude dos links e auditoria da migração legada UNKNOWN | BASELINED |
| B06 | Instrumento na cadeia metodológica; intenção detalhada da manutenção UNKNOWN | PARTIALLY_ALIGNED | Product; DEV valida implementação | Escopo IMPLEMENTED é leitura/reconciliação; CRUD e aceite metodológico completo não demonstrados | BASELINED |
| B07 | Instrumento na cadeia metodológica; intenção detalhada da manutenção UNKNOWN | PARTIALLY_ALIGNED | Product; DEV valida implementação | Escopo IMPLEMENTED é leitura/reconciliação; CRUD e aceite metodológico completo não demonstrados | BASELINED |
| B08 | Instrumento na cadeia metodológica; intenção detalhada da manutenção UNKNOWN | PARTIALLY_ALIGNED | Product; DEV valida implementação | Escopo IMPLEMENTED é leitura/reconciliação; CRUD e aceite metodológico completo não demonstrados | BASELINED |
| B09 | Rastrear riscos e mitigação sem presumir efetividade | PARTIALLY_ALIGNED | Product; DEV valida implementação | Risco residual exige evidência no SQL; execução e cobertura da UI de mitigação UNKNOWN | BASELINED |
| B10 | Versões, revisão derivada e transições governadas | CONFLICT | Product; DEV valida implementação | C02: reconciliação obrigatória do filtro UI com estados SQL; não decidir versão corrente pelo nome do estado | INVESTIGATED |
| B11 | Missão/visão, valores e comportamentos com validação | PARTIALLY_ALIGNED | Product; DEV valida implementação | UI consultada demonstra leitura; edição e ciclo completo não comprovados | BASELINED |
| B12 | SK-PE autossuficiente; artefatos compartilhados sem duplicar por módulo | PARTIALLY_ALIGNED | Product; DEV valida implementação | Canvas legado não prova cobertura das operações FE-03 nem integração SK-PN | BASELINED |
| B13 | Mapa estratégico configurável e causalidade governada | PARTIALLY_ALIGNED | Product; DEV valida implementação | Layout/rotas visuais salvos localmente; sugestões não são relações aprovadas; farol sem leitura permanece cinza | BASELINED |
| B14 | Primeiro gate READ_ONLY_REUSE; autoridade semântica da medida permanece Product | CONFLICT | Product; DEV valida implementação | C01: escrita/adoção implementadas além do primeiro contrato documentado; decisão de evolução não localizada nos owners | INVESTIGATED |
| B15 | Meta é decisão organizacional com horizonte e tolerâncias | PARTIALLY_ALIGNED | Product; DEV valida implementação | Critério de escolha da meta foi encontrado no SQL; aceite da UI e população UNKNOWN | BASELINED |
| B16 | Referência contextual distinta da meta | PARTIALLY_ALIGNED | Product; DEV valida implementação | Escrita demonstrada; conformidade da adoção e vínculo organizacional exige gate C01 | BASELINED |
| B17 | Registro validado deve preceder projeção oficial | CONFLICT | Product; DEV valida implementação | C04: read-model contextual seleciona última apuração independentemente de status; decisão sobre exibição não validada pendente | INVESTIGATED |
| B18 | Sem ausência convertida em zero; criticidade governada; G1 como último estado documental | CONFLICT | Product; DEV valida implementação | C03: SQL devolve zero sem universo; card crítico usa regra menor que RPC. Frontend existe; G2/aceite não demonstrados | INVESTIGATED |
| B19 | Desdobramento por ciclo sem substituir BSC; OKR configurável | PARTIALLY_ALIGNED | Product; DEV valida implementação | Vínculo físico indicador/KR existe; adapter de escrita de indicador só suporta strategic_objective | BASELINED |
| B20 | Iniciativa operacional persistente separada da decisão estratégica versionada | PARTIALLY_ALIGNED | Product; DEV valida implementação | Schemas legados e transversais coexistem; não inferir migração concluída | BASELINED |
| B21 | Plano de ação e execução com responsabilidade, justificativa e auditoria | PARTIALLY_ALIGNED | Product; DEV valida implementação | IMPLEMENTED para fluxos identificados; equivalência entre ações SK-PE e SPARKS precisa de evidência | BASELINED |
| B22 | Exploração de pessoas/capacidade por lacunas reais; sem integração financeira completa | PARTIALLY_ALIGNED | Product; DEV valida implementação | Validações locais não provam auditoria e permissões de escrita no runtime | BASELINED |
| B23 | Síntese operacional com grandezas e tempo canônicos | PARTIALLY_ALIGNED | Product; DEV valida implementação | Testes protegem projeções locais; monitoramento completo FE-08 não declarado aceito | BASELINED |
| B24 | Reunião com síntese, conclusões e ratificação auditada | DOCUMENTATION_BEHIND | Product; DEV valida implementação | HEAD acrescenta frontend sobre RPC existente; teste autenticado e aceite RAE pendentes | BASELINED |
| B25 | Agenda contextual integrada à operação | PARTIALLY_ALIGNED | Product; DEV valida implementação | Timezone/DST testados; presença, convites externos e segregação no runtime UNKNOWN | BASELINED |
| B26 | Evolução integrada; intenção detalhada de todas as regras não reconciliada | UNKNOWN | Product; DEV valida implementação | Distinguir tempo estratégico de vigência institucional; ciclo completo de aprovação não exercitado | INVESTIGATED |
| B27 | Importação assistida e intercâmbio com rastreabilidade | PARTIALLY_ALIGNED | Product; DEV valida implementação | Preview/staging não é carga definitiva; ZIP/HTML/XLSX são artefatos de intercâmbio, não autoridade de produto | BASELINED |
| B28 | Rastrear entregáveis e evidência; completude contratual UNKNOWN | UNKNOWN | Product; DEV valida implementação | U02: criação, versão, catálogo, requisitos, readiness, listagem e validação sem definição nas migrations do SHA | INVESTIGATED |
| B29 | Superfície contextual do SK-PE; não transformar /workspace global em painel sem contexto | PARTIALLY_ALIGNED | Product; DEV valida implementação | C05: parser aceita mais seções que adaptador; projeto/formulação explícitos precisam validação ponta a ponta | BASELINED |
| B30 | TRANSVERSAL_REUSE=INTENDED | INTENT_NOT_IMPLEMENTED | Product; DEV valida implementação | Integrações SK-PN/SK-DA/SK-DOC não comprovadas; não criar produto/microserviço por inferência | MEMORY |
| B31 | H4 FUTURE, condicionado a HOMOL e decisão Product/Corporate | INTENT_NOT_IMPLEMENTED | Product/Infrastructure | PRD, SLA, restore e observabilidade efetiva UNKNOWN | MEMORY |

Contagem por recorte: ALIGNED=0, PARTIALLY_ALIGNED=22, DOCUMENTATION_BEHIND=1, IMPLEMENTATION_BEHIND=0, INTENT_NOT_IMPLEMENTED=2, IMPLEMENTATION_NOT_DOCUMENTED=0, CONFLICT=4, UNKNOWN=2. Contagem de conflitos transversais C01–C07 é separada e não deve ser somada à classificação exclusiva dos recortes.

## Divergências, gaps e decisões pendentes

Nenhum conflito abaixo foi resolvido escolhendo silenciosamente documentação ou código. `CONFLICT` não significa, por si só, bug confirmado em runtime.

| ID | Evidência / diferença | Impacto e decisão necessária |
| --- | --- | --- |
| C01 | Medidas documenta primeiro gate sem escrita; MEAS/DUAL/BENCH e migrations 08–09/09 implementam adoção, arquivamento e escrita. | Product deve localizar/registrar a autorização de evolução e os critérios de aceite. Preservar primeiro gate como histórico; não proibir retroativamente nem ratificar a escrita por inferência. |
| C02 | FORM/MEAS/ANALYTICS filtram formulações draft, under_review, approved. Constraint da fundação e FE02 descrevem draft, in_elaboration, pending_validation, validated, pending_approval, approved, superseded, archived; não localizada redefinição dessa constraint. | Seleção pode omitir versões válidas e não resolve ambiguidades entre aberta/aprovada. DEV/Product devem reconciliar contrato de seleção e testar estados reais. |
| C03 | ANALYTICS conta críticas por criticality; dashboard SQL também considera priority, risk_level e health_status. SQL retorna coalesce(avg(...),0), mesmo sem universo elegível; frontend só mostra ausência se receber null. attentionTotal soma sinais sobrepostos. | Contrato Cockpit exige semântica governada e ausência distinta de zero. Validar universo, regra única de criticidade e se total representa ocorrências ou iniciativas únicas; não chamar a primeira wave aceita. |
| C04 | FE09 exige registro validado antes de projeção oficial; get_sparks_measure_performance_context escolhe última measurement por data/criação, sem filtro de status. | Uma apuração submitted/rejected/superseded pode ser selecionada conforme dados. Product deve decidir leitura informativa versus oficial; DEV deve verificar com fixtures antes de qualquer mudança. |
| C05 | ROUTES reconhece 16 seções, mas ROUTE-ADAPTER encaminha 10 como seções explícitas; guarda project/formulation no contexto. CANVAS resolve get_skpe_project_context por organização e usa o primeiro resultado. | Deep-link sintaticamente válido não prova que todo contexto da URL governe todas as consultas. Testes de parser não cobrem o fluxo completo; validar projeto/formulação/seção com múltiplas versões. |
| C06 | Workflow versionado dispara em main e contém sparks-homol.sparkoop.com.br/sparks.sparkoop.com. Owner Corporate registra hostname sparks-homol.sparkoop.com e branch de produto feature/formulacao-estrategica-operacional. | Drift de delivery documentado; Infrastructure/DEV devem reconciliar workflow com contrato publicado em gate próprio. HTTP 200 não demonstra que esse workflow publicou o HEAD. |
| C07 | Hub/deployment-map registram source 3f2f25c em 11/09; usuário declara deployment d27373c; apenas shell/health foram observados nesta auditoria. | Tratar como snapshots e declaração de origens distintas. DEPLOYED_SHA efetivo UNKNOWN; não sobrescrever prova histórica com declaração recente. |

### Known unknowns e dívida rastreável

| ID | Unknown / dívida | Evidência disponível e próxima verificação |
| --- | --- | --- |
| U01 | SHA do runtime, migrations aplicadas, configuração Auth/Storage e isolamento real | HTTP anônimo parcial; verificar revisão da release/CI e schema por leitura autorizada em gate próprio. |
| U02 | Sete RPCs de artefatos sem definição nas migrations | add_methodology_artifact_version, create_methodology_artifact, get_methodology_artifact_catalog, get_methodology_delivery_requirements, get_methodology_gate_readiness, get_project_methodology_artifacts, validate_methodology_artifact. Consumidores ARTIFACT/KIT; busca complementar SQL no produto não encontrou CREATE correspondente. Verificar histórico remoto/banco sem inventar implementação. |
| U03 | Cobertura de RLS/autorizações, fallback cliente por perfil | CANVAS registra fallback quando get_skpe_effective_capabilities falha. Não demonstra bypass de banco; testar negativas por perfil e organização antes de certificar. |
| U04 | Aceite funcional/visual de medidas, cockpit e RAE | Testes locais não exercitam browser autenticado nem interação humana; reconstruir checklist e evidência por capability. |
| U05 | Maturidade de séries históricas e de faróis | Mapa mantém ausência de leitura; validar população, período, thresholds e aprovação Product. |
| U06 | Convergência integral entre skpe_* e sparks_* | Bindings/views existem; consumidores ainda usam ambos. Inventariar objeto por objeto antes de qualquer retirement. |
| U07 | Trabalho em outras branches/estações | Esta baseline cobre somente SHA indicado; não cobre trabalho local de Ricardo fora dele. |
| U08 | RPCs sem consumidor frontend identificado | create_skpe_formulation_revision e sparks_record_measurement não aparecem no índice literal consultado; podem ter outros chamadores. Ausência no índice não equivale a código morto. |
| U09 | Intenção detalhada de instrumentos, ciclos e exceções legadas | Roadmap e comentários SQL não bastam para autoridade sobre cada regra. Product arbitra; status INVESTIGATED onde reconciliação é insuficiente. |
| U10 | Convite e identidade privilegiada | EDGE-INVITE usa admin.createUser; investigar experiência de convite/aceitação e revogação sem inferir comportamento pelo nome. |

Dívidas relevantes: shell funcional concentrado em SkpeCockpit, casts any/never em integrações, leituras diretas e fachadas coexistentes, preferências BSC locais e sugestões condicionadas a títulos/códigos específicos. São fatos/limites de manutenção, não autorização para refatorar. O teste de sugestões protege contra vazamento para conjuntos de objetivos diferentes.


## Investigação dirigida de Medidas C01 C02 C04 — 12/09/2026

`BASELINE FIRST; DELTA SECOND`. Corporate de partida: `fd7febbb01deffe8c1c698de40c17d93a86494e4`. Baseline e produto atual: `d27373cc16740dfc86eb940abf639e322b072cc8`, branch `feature/formulacao-estrategica-operacional`, HEAD remoto igual, worktree limpo. `PRODUCT_DELTA_FROM_BASELINE=NONE`. Os achados abaixo aprofundam **BASELINE_EVIDENCE** já presente no mesmo SHA; não existe CURRENT_DELTA_EVIDENCE nesta wave.

Método: leitura dos registros C01/C02/C04 acima antes do código; owners de Medidas, roadmap e governança; FE02/FE06/FE09 do produto; shortlist textual das migrations e aprofundamento dos contratos listados. Migration é AS-IMPLEMENTED, não aprovação Product. Busca negativa de decisão limitada a esses owners, documentação versionada do produto e histórico pertinente; não prova inexistência de decisão externa ou trabalho não publicado.

`AS-OBSERVED=STATIC_SOURCE_AND_LOCAL_SYNTHETIC_SCENARIOS_ONLY`. Não houve consulta ao banco, fluxo autenticado, escrita, execução de migration ou verificação de deployment. Os cenários locais ilustram consequências dos predicados lidos; não equivalem a teste PostgreSQL, RPC, RLS ou aceite funcional. C01/C02/C04 permanecem **CONFLICT**, agora qualificados; nenhum está RESOLVED.

### C01 — disponibilidade técnica e autorização de adoção

`C01_DECISION_FOUND=NO` para uma decisão canônica de ampliação do primeiro gate. `C01_DECISION_SOURCE=NOT_LOCATED_IN_SCOPED_AUTHORITIES`. FE06 documenta operações governadas de indicadores/metas/benchmark e FE09 documenta registro/validação de medição; são contratos técnicos existentes, não um aceite Corporate da nova experiência transversal. O histórico Corporate mantém READ_ONLY_REUSE; o commit produto `99d91a5841ee94e45a1ad45a500052a470dd478d` registra consolidação técnica, sem decisão de aprovação no texto consultado.

| Operação | TECHNICALLY_AVAILABLE | ACTUALLY_CONSUMED no fonte atual | Evidência |
| --- | --- | --- | --- |
| sparks_upsert_measure_indicator | YES; adapter só SK-PE / strategic_formulation / strategic_objective | Indireto: adopt_sparks_measure_reference_indicator chama a fachada; workspace chama adoção. Sem chamada direta frontend localizada. | [Fachadas][MI20260904234019], [adoção][MI20260908135440], [workspace][MI-MEAS] |
| sparks_upsert_measure_target | YES; delega upsert_skpe_indicator_target | Nenhuma chamada direta localizada no frontend versionado | [Fachadas][MI20260904234019] |
| sparks_supersede_measure_target | YES; delega supersede_skpe_indicator_target | Nenhuma chamada direta localizada no frontend versionado | [Fachadas][MI20260904234019] |
| sparks_upsert_measure_benchmark | YES | YES; OrganizationIndicatorsSmartGrid.saveBenchmark | [Grid][MI-GRID], [fachadas][MI20260904234019] |
| sparks_transition_measure_benchmark | YES | YES; grid, ações verify/activate/return_to_draft/archive | [Grid][MI-GRID], [operações][MI20260730070000] |
| sparks_record_measurement | YES; delega record_skpe_indicator_measurement | Nenhuma chamada direta localizada no frontend versionado | [Fachadas][MI20260904234019], [monitoramento SQL][MI20260730100000] |
| Adoção/arquivamento organizacional | YES; RPCs próprios, distintos das seis fachadas | YES; SparksMeasureDualSelector | [Selector][MI-DUAL], [adoção organizacional][MI20260909214455] |
| Manutenção do catálogo geral | YES; RPCs de plataforma | YES; PlatformMeasureCatalog | [Plataforma][MI-PLATFORM], [catálogo][MI20260908170508] |

`AUTHORIZED_FOR_ADOPTION=NOT_ESTABLISHED_FOR_EXPANDED_GATE`; `CANONICALLY_APPROVED=NOT_EVIDENCED`; `C01_CANONICAL_AUTHORIZATION=NOT_LOCATED`; `C01_WRITE_FACADE_EXISTS=YES`; `C01_FRONTEND_WRITE_CONSUMER_EXISTS=YES`. Consumo no fonte não comprova uso bem-sucedido em runtime.

As fachadas delegam aos contratos existentes. Adoção exige administração organizacional/plataforma; o adapter exige formulação editável e valida o objetivo. Verificar/ativar benchmark exige permissão de validação, enquanto retorno/arquivo usa manage/validate; a formulação deve estar draft/in_elaboration. Registro de medição exige gestão de monitoramento, indicador strategic_kpi ativo e ciclo gravável. Isso é autorização **técnica** implementada, distinta da aprovação **de produto**; não foi demonstrada vulnerabilidade nem auditada a efetividade dos controles.

Reconciliação: AS-INTENDED = evolução governada por Product, preservando o primeiro gate como histórico; AS-DOCUMENTED = READ_ONLY_REUSE no Corporate e contratos técnicos de escrita em [FE06][MI-FE06]/[FE09][MI-FE09]; AS-IMPLEMENTED = adapters e consumidores acima; AS-OBSERVED = fonte estático, uso autenticado UNKNOWN. `STATUS=CONFLICT`. Causa: ampliação implementada sem decisão de adoção rastreada nos owners consultados. Risco: confundir contrato/grant/commit com aceite. Correção mínima: Product localizar ou deliberar a decisão, escopo, perfis e critérios de aceite; verificar controles em gate separado. `NEEDS_HUMAN_DECISION=YES`. Ação principal `HUMAN_DECISION_REQUIRED`; AUTHORIZATION_HARDENING é avaliação posterior, não correção comprovadamente necessária.

### C02 — matriz de estados e seleção

`C02_UI_FILTERS_FOUND=YES`; `C02_SQL_STATES_FOUND=YES`; `C02_FORMULATION_RULES_FOUND=YES`. Valores SQL: formulação = draft/in_elaboration/pending_validation/validated/pending_approval/approved/superseded/archived; indicador = draft/active/inactive/archived; meta = draft/active/achieved/not_achieved/superseded; benchmark = draft/verified/active/archived; medição = submitted/validated/rejected/superseded. Catálogo tem status e is_current independentes; vínculo organizacional tem active/archived. [Constraints][MI20260730033000], [medições][MI20260730100000], [catálogo][MI20260908170508], [vínculo][MI20260909214455]. Não foi localizada redefinição posterior das constraints de lifecycle pesquisadas.

| UI_STATE / UI_FILTER / UI_VALUE | SQL_STATE / SQL_FIELD / SQL_VALUE | FORMULATION_RULE / DOCUMENTED_RULE / SELECTION_RULE | RESULT |
| --- | --- | --- | --- |
| F01: formulação draft incluída | skpe_strategic_formulations.status=draft | Estado existente e editável; [FE02][MI-FE02]. Alinhamento só desse valor, não do seletor completo. | ALIGNED |
| F02: under_review incluído por MEAS/FORM/ANALYTICS | Não pertence à constraint de formulação | Não é alias de pending_validation; under_review de ciclo de monitoramento não redefine formulação. | CONFLICT |
| F03: in_elaboration omitido | Estado válido e editável | FE02 permite alteração em draft/in_elaboration. Adoção deixa de oferecer versão editável. | CONFLICT |
| F04: pending_validation/validated/pending_approval omitidos | Estados válidos da versão aberta | Não são editáveis, mas pertencem ao lifecycle de leitura; o filtro não representa a versão aberta completa. | CONFLICT |
| F05: approved oferecido no formulário de adoção | Versão aprovada existe, conteúdo congelado | FE02 e guard do adapter impedem edição. Disponível no seletor não significa elegível para escrita. | CONFLICT |
| F06: draft e approved coexistentes | Índices permitem uma aberta e uma aprovada | FORM/ANALYTICS exigem exatamente uma linha (limit 2), logo resolvem null; MEAS usa primeiro por version_number, em toda organização. É necessário separar contexto de leitura e edição. | CONFLICT |
| F07: superseded/archived excluídos do seletor; OKR recebe formulationId | Estados históricos válidos | Exclusão pode servir à visão corrente, mas contrato explícito de leitura histórica e precedência não localizado. | PARTIAL |
| F08: MyIndicatorsPanel all/active/draft/inactive | get_my_skpe_indicators exclui archived, exige owner e objetivo active | Filtros locais usam o mesmo status do indicador; não filtram validação de medição. | ALIGNED |
| F09: workspace lista indicadores não arquivados | RPC aceita draft/active/inactive; OKR lê indicadores sem filtro de status | Leitura informativa pode incluir inativos; registrar medição exige indicador active. Não equiparar disponível a elegível. | PARTIAL |
| F10: withTarget = target_id presente; OKR conta todas as metas do indicador | RPC exclui superseded, prioriza período atual/futuro/passado, period_end DESC e updated_at DESC | Pode escolher draft ou período futuro/passado. OKR inclui superseded na contagem. Vigente no tempo, active e não superseded são critérios distintos; FE06 distingue meta e histórico. | PARTIAL |
| F11: withBenchmark = benchmark_id presente | RPC ordena verified_at DESC NULLS LAST, updated_at DESC, sem filtro de status | Pode mostrar archived ou draft; FE06 descreve verificação/ativação e recomenda referência verified/active. Presença não prova referência elegível. | PARTIAL |
| F12: assessed = measurement_state diferente de not_assessed; grid mostra performance | RPC não filtra status; OKR pega primeira medição por data sem filtro | submitted/rejected/superseded contam como apurado. FE09 distingue registro de leitura oficial validada; UI não torna essa diferença explícita. | CONFLICT |
| F13: ausência de medição versus valor zero | Sem linha: not_assessed e null; zero medido permanece zero | Workspace/grid não convertem ausência em zero; número zero não é falta de apuração. | ALIGNED |
| F14: catálogo disponível para adoção | is_current=true AND status=active | Consulta e RPC de adoção verificam ambos; vigente não é sinônimo de ativo. | ALIGNED |
| F15: selector organizacional exibe vínculo active e retira catálogo já adotado por ID | Última consulta filtra oi.status=active; não exige current/active da referência associada | Adoção ativa não comprova vigência da versão do catálogo nem validação da medida. Regra de atualização de adoção entre versões requer decisão. | PARTIAL |
| F16: estados/dados realmente publicados e permissões efetivas | Banco/runtime não consultado | Fonte e fixtures locais não comprovam populações reais, RLS ou aplicação das migrations. | UNKNOWN |

Evidências dos consumidores: [workspace][MI-MEAS], [Formulação][MI-FORM], [Analytics][MI-ANALYTICS], [OKR][MI-OKR], [painel pessoal][MI-MY], [grid][MI-GRID], [selector][MI-DUAL]. Regras de leitura: [RPC contextual][MI20260908015851], [pessoal][MI20260807013000], [adoção][MI20260908135440], [consulta organizacional final][MI20260909234252].

`C02_ALIGNED=4`; `C02_PARTIAL=5`; `C02_CONFLICTS=6`; `C02_UNKNOWN=1` — contagem exclusiva das 16 linhas desta matriz, não dos recortes B01–B31. AS-INTENDED/AS-DOCUMENTED = lifecycle FE02, medidas FE06 e validação FE09; AS-IMPLEMENTED = predicados acima; AS-OBSERVED = fonte e cenários sintéticos, sem ambiente autenticado. `STATUS=CONFLICT`. Causa: seletores locais misturam lifecycle de formulação, edição e presença de dados. Risco: omitir versão utilizável, oferecer edição impossível e apresentar dado sem qualificação. Correção mínima proposta: `FRONTEND_CORRECTION` para reconciliar estados e contexto, após Product definir precedência aberta/aprovada e semântica por consumidor; tratar regras de medição no C04. `NEEDS_HUMAN_DECISION=YES`. Nenhuma alteração de UI executada.

### C04 — última apuração não equivale a desempenho oficial

`LATEST_MEASUREMENT_BY_WHAT=measurement_date DESC NULLS LAST, created_at DESC`, por organização/módulo/indicador, limit 1. O RPC contextual não fixa ciclo, não filtra status e não usa validated_at nem supersedes_measurement_id. A view [sparks_measure_measurements][MI20260904233009] repassa todas as linhas; não existe filtro de validação escondido nessa view. Empate nas duas datas não tem desempate por ID definido. [Seleção completa][MI20260908015851].

| Campo | Papel real nesta seleção |
| --- | --- |
| measured_at | Não é coluna desse contrato; o nome real é measurement_date (date). |
| measurement_date | Primeira chave da última medição; registro exige data dentro do ciclo. |
| created_at | Desempata a data; não equivale à data de validação. |
| period_start / period_end | Período da medição exposto; não filtra nem ordena a seleção contextual. |
| reference_period | Texto do benchmark, não período ou data ordenável de medição. |
| validated_at / status | Validação tem timestamp e autor na tabela/view; RPC contextual não usa esses critérios para escolher a linha. |
| supersedes_measurement_id | Liga histórico; a seleção contextual não percorre nem exclui a cadeia. |

`SUPERSEDED_MEASUREMENT_INCLUDED=YES`; `UNVALIDATED_MEASUREMENT_INCLUDED=YES`: significam elegibilidade pelo SQL, não constatação de dados publicados. Um registro antigo superseded pode vencer se sua measurement_date for maior que a da correção retroativa; submitted/rejected podem vencer o validado anterior.

`LATEST_VALID_MEASUREMENT_BY_WHAT`: o contrato [FE09][MI-FE09] mantém **um validated corrente por ciclo/indicador**, não define “último oficial global” entre ciclos para esse RPC. A operação de registro cria submitted, supersede o submitted anterior e preserva o validated. A transição de validação exige submitted, permissão de governança e ciclo gravável; então supersede o validated anterior do mesmo ciclo/indicador e grava validated_at/by. Índices únicos separados asseguram um submitted e um validated por ciclo/indicador. Rejeitar a nova submissão não supersede o validado anterior. [Registro, transição e índices][MI20260730100000]. Não inventar ordenação oficial por validated_at ou ciclo mais recente sem decisão Product.

`OFFICIAL_PERFORMANCE_RULE_EXISTS=YES` no contrato FE09 de validação/projeção e leitura por ciclo; `C04_OFFICIAL_PERFORMANCE=NOT_ESTABLISHED_FOR_CONTEXT_RPC`. FE09 §2.3 fala explicitamente da projeção de KR, Iniciativa ou resultado; §2.4–2.5 inclui o histórico de Indicador. Isso não prova que esse novo RPC seja uma projeção oficial nem que toda projeção operacional esteja incorreta.

Performance é calculada no registro, ainda submitted: usa polaridade, baseline e meta, delegando ao cálculo de progresso; override depende da configuração do pacote, e effective_performance usa manual ou automático, limitado a 0–100. Ter effective_performance numérico não comprova validação. A meta escolhida para exibição no RPC pode ser diferente de indicator_target_id usado no cálculo histórico: a seleção contextual usa current_date, enquanto o registro automático usa measurement_date e meta elegível no período (ou meta explícita do payload). O RPC não recalcula a performance com a meta exibida. [Cálculo e registro][MI20260730100000], [leitura][MI20260908015851].

`C04_INFORMATIONAL_READING=IMPLEMENTED_WITHOUT_EXPLICIT_VALIDATION_QUALIFICATION`. O workspace chama RPC com source_context_id=null; recebe latest independente de ciclo/status. A grid exibe valor e effective_performance sem coluna de validação da medição (a coluna Situação usa indicator_status). OKR consulta a tabela diretamente, ordena só measurement_date DESC e usa find por indicador; não desempata por created_at e não filtra status. MyIndicatorsPanel não lê medição; MonitoringSection usa outra projeção operacional, não esse RPC. Não extrapolar o achado para todos os consumidores de desempenho.

AS-INTENDED/AS-DOCUMENTED = FE09 preserva histórico validado e distingue leitura oficial por ciclo; AS-IMPLEMENTED = última apuração irrestrita no RPC/OKR, cálculo disponível antes de validar; AS-OBSERVED = análise estática e cenários sintéticos, sem confirmação no banco. `STATUS=CONFLICT`. Causa: consulta informativa sem contrato explícito de oficialidade/recorte e apresentação sem status da apuração. Risco: ler correção pendente/rejeitada/substituída como oficial, ou associar desempenho histórico à meta exibida de outro período. Correção mínima proposta: Product decidir qual leitura cada consumidor oferece, ciclo/data de corte e desempate; `FRONTEND_CORRECTION` para tornar validação/proveniência explícitas; `READ_MODEL_CORRECTION` se o contrato escolhido for oficial. `NEEDS_HUMAN_DECISION=YES`. Não basta acrescentar status=validated e escolher uma linha global sem governar ciclo e período.

### Consumidores delimitados no SHA

Todas as linhas são BASELINE_EVIDENCE; delta inexistente. WRITE_SOURCE descreve chamadas de Medidas identificadas, não uma auditoria global do componente.

| COMPONENT | READ_SOURCE | WRITE_SOURCE | FILTER_LOGIC / MEASUREMENT_SELECTION_LOGIC / STATUS_SEMANTICS |
| --- | --- | --- | --- |
| MeasuresPerformanceWorkspace | get_sparks_measure_performance_context; catálogo; formulações | adopt_sparks_measure_reference_indicator | Formulações draft/under_review/approved; leitura sem formulationId; cards por presença; última medição delegada ao SQL. |
| OrganizationIndicatorsSmartGrid | Linhas recebidas do workspace | sparks_upsert_measure_benchmark; sparks_transition_measure_benchmark | Exibe indicator_status e performance, sem status da medição; benchmark é gerenciável. |
| SparksMeasureDualSelector | Catálogo e get_sparks_measure_organization_indicators | adopt_sparks_measure_references_for_organization; archive_sparks_measure_reference_adoptions_for_organization | Retira referências já adotadas por ID; vínculo ativo não equivale a versão atual de catálogo; sem medição. |
| MyIndicatorsPanel | get_my_skpe_indicators (fachada pessoal transversal existe, mas não é a chamada deste componente) | Nenhuma de Medidas localizada | all/active/draft/inactive; owner pessoal e objetivo ativo no SQL; meta não superseded por período; sem medição. |
| StrategicFormulationSection | skpe_strategic_formulations | Nenhuma das seis fachadas localizada | Três estados e exatamente uma linha; propaga contexto para desdobramento. |
| StrategicOkrDecompositionSection | Tabelas indicador/meta/medição por organização/projeto/formulação | Nenhuma das seis fachadas localizada | Sem filtro de status de medida; conta metas, inclusive superseded; primeira medição por data, sem desempate. |
| InitiativePerformanceCockpit | Formulações + dashboard/portfólio | Nenhuma das seis fachadas localizada | Mesmo filtro de formulação e resolução única; não demonstrado consumo direto de latest measurement. C03 fora desta wave. |
| MonitoringSection | get_skpe_project_operational_projection | Nenhuma das seis fachadas localizada | Projeção distinta; não equiparar progresso operacional a latest measurement contextual. |
| PlatformMeasureCatalog | RPCs de catálogo de plataforma | upsert/transition de catálogo e manutenção de benchmark de referência | Governança técnica de status/versões; não constitui aceite Product da adoção ampliada. |

Fontes: [workspace][MI-MEAS], [grid][MI-GRID], [selector][MI-DUAL], [pessoal][MI-MY], [Formulação][MI-FORM], [OKR][MI-OKR], [Analytics][MI-ANALYTICS], [monitoramento][MI-MON], [plataforma][MI-PLATFORM].

### Migrations usadas como evidência

Shortlist por measure/indicator/target/benchmark/measurement/performance/validate/supersede/status; aprofundamento dirigido, sem leitura global de todas as migrations. As definições posteriores dos objetos centrais foram pesquisadas antes da conclusão.

| MIGRATION | WHY_HIGH_VALUE | CONCEPT_SUPPORTED |
| --- | --- | --- |
| [20260730033000_create_strategic_formulation_and_shared_business_architecture_foundation.sql][MI20260730033000] | Constraints dos estados e separação de versões abertas/aprovadas | C02: formulação, indicador, meta e benchmark |
| [20260730040000_create_strategic_formulation_governance_and_versioning.sql][MI20260730040000] | Operações governadas de versionamento e editabilidade | C02: conteúdo editável versus versão aprovada |
| [20260730070000_create_strategic_indicators_targets_and_benchmarking_operations.sql][MI20260730070000] | Implementação dos adapters e transições de benchmarking | C01/C02: escrita com guards, meta e referência distintas |
| [20260730100000_create_strategic_monitoring_governance_and_learning.sql][MI20260730100000] | Série histórica, registro, transição e supersessão de medições | C04: submitted/validated e cálculo de performance |
| [20260807013000_create_my_skpe_indicators.sql][MI20260807013000] | Consulta realmente chamada pelo painel pessoal | C02/C04: indicador não arquivado e meta contextual, sem medição |
| [20260904233009_establish_transversal_measures_performance_facade.sql][MI20260904233009] | Views transversais sobre autoridades físicas | C04: measurement view não filtra status |
| [20260904234019_establish_transversal_measures_performance_write_facade.sql][MI20260904234019] | Seis fachadas de escrita e adapter SK-PE | C01: disponibilidade técnica não equivale a aceite |
| [20260908015851_govern_transversal_measure_performance_context_read.sql][MI20260908015851] | RPC contextual com três seleções laterais | C02/C04: meta, última medição e benchmark |
| [20260908135440_govern_measure_reference_catalog_adoption.sql][MI20260908135440] | Elegibilidade do catálogo e adoção para objetivo estratégico | C01/C02: current + active, guard administrativo e adapter |
| [20260908170508_govern_platform_measure_reference_catalog.sql][MI20260908170508] | Governança de versões do catálogo geral | C01/C02: is_current é separado de status |
| [20260909214455_govern_organization_measure_reference_adoption.sql][MI20260909214455] | Adoção e arquivamento organizacional | C01/C02: vínculo organizacional active/archived |
| [20260909234252_reconcile_organization_specific_measure_indicators.sql][MI20260909234252] | Última definição da consulta organizacional e origem legacy | C02: adoção ativa não comprova validação ou vigência do catálogo |

### Decision gate e próximo passo

#### Estado de fechamento da demanda documental

```text
C01_STATUS=OPEN_PRODUCT_DECISION
C02_STATUS=OPEN_PRODUCT_DECISION
C04_STATUS=OPEN_PRODUCT_DECISION
CURRENT_BASELINE_PRODUCT_SHA=d27373cc16740dfc86eb940abf639e322b072cc8
NEXT_RESUMPTION=Resolver C01/C02/C04 somente quando a frente de Medidas e Desempenho for retomada.
```

Este registro encerra o escopo de investigação e documentação, sem decidir os conflitos ou autorizar implementação. OPEN_PRODUCT_DECISION expressa a pendência de decisão Product; a classificação técnica CONFLICT permanece preservada. Esses itens não bloqueiam a baseline inteira. O ponto de retomada é este decision gate, seguindo BASELINE FIRST, DELTA SECOND.

| Item | RECONCILIATION_STATUS | Ação principal | Condições para próximo gate |
| --- | --- | --- | --- |
| C01 | CONFLICT, autorização não localizada | HUMAN_DECISION_REQUIRED | Product registra/localiza decisão de ampliação, perfis, limites e aceite; depois avaliação de authorization. |
| C02 | CONFLICT, contrato divergente confirmado no fonte | FRONTEND_CORRECTION + HUMAN_DECISION_REQUIRED | Definir leitura versus edição, precedência aberta/aprovada e seleção explícita de contexto; fixtures de lifecycle. |
| C04 | CONFLICT, leitura irrestrita confirmada no fonte | HUMAN_DECISION_REQUIRED; FRONTEND_CORRECTION; READ_MODEL_CORRECTION condicional | Definir informativo/oficial por consumidor, ciclo/período, validação/supersessão e desempate; fixtures antes de corrigir. |

`NO_CHANGE_REQUIRED=NO`; `DOCUMENTATION_ONLY=NO` para encerramento dos conflitos (esta wave altera somente documentação); `BACKEND_CONTRACT_CORRECTION=NOT_DETERMINED`; `AUTHORIZATION_HARDENING=ASSESSMENT_PENDING`; `MIGRATION_REQUIRED=NOT_DETERMINED` — eventual alteração de RPC deverá seguir o gate de versionamento, sem migration nesta wave; `HUMAN_DECISION_REQUIRED=C01,C02,C04`; `UNKNOWN=runtime/RLS, aceite externo e regra oficial global entre ciclos`.

Próximo gate seguro: decisão Product sobre autorização de adoção e contratos de seleção/apresentação, seguida de plano técnico limitado às decisões aprovadas. Preservar o primeiro READ_ONLY_REUSE como histórico; não ratificar escrita retroativamente por inferência. Não promover nenhum achado a RESOLVED até decisão e validação correspondentes. Cockpit continua depois de Medidas; não iniciar implementação, banco, migrations, runtime ou merge automático nesta wave.


## Maturidade de especificação

BASELINED nas linhas delimitadas significa fatos reconciliados e versionados, com gaps explícitos; não significa coverage completa. Linhas CONFLICT/UNKNOWN permanecem INVESTIGATED. Reuso externo e escala futura permanecem MEMORY/intenções documentadas. A reconciliação desta wave é suficiente para registrar conhecimento, não para aceitar requisitos pendentes.

Nenhuma área recebe SPECIFIED ou AUTHORITATIVE nesta auditoria: os requisitos históricos possuem conteúdo útil, mas binding completo, freshness e aceite da revisão não foram demonstrados. SPEC-FIRST é direção operacional já adotada documentalmente; SPEC-AS-AUTHORITY não comprovado; SPEC-AS-SOURCE não declarado. A [governança](governance/capability-execution-and-traceability.md) continua regulando a promoção futura.

## Git, lineage e ponto de retomada

Mineração dirigida às áreas que mudaram desde o ponto documental anterior:

| Commit | Fato relevante |
| --- | --- |
| [4baea804e9f42fb3a1ae76cab60928a84886a4bb](https://github.com/sparkooptech/skpe-saas/commit/4baea804e9f42fb3a1ae76cab60928a84886a4bb) | Evolução do cockpit executivo em 07/09; explica frontend posterior ao G1 documental. |
| [99d91a5841ee94e45a1ad45a500052a470dd478d](https://github.com/sparkooptech/skpe-saas/commit/99d91a5841ee94e45a1ad45a500052a470dd478d) | Consolidação de medidas transversais e experiência em 10/09; comparar com contrato READ_ONLY_REUSE. |
| [3f2f25cf02d887b878ac1ee8e9b04724c0fef4f3](https://github.com/sparkooptech/skpe-saas/commit/3f2f25cf02d887b878ac1ee8e9b04724c0fef4f3) | Merge canônico e source do deployment registrado no Corporate. |
| [9787af7835b502c81ce85e22028103cc1ada7149](https://github.com/sparkooptech/skpe-saas/commit/9787af7835b502c81ce85e22028103cc1ada7149) | Restauração do contrato de build HOMOL em 11/09; não comprova novo deployment. |
| [d27373cc16740dfc86eb940abf639e322b072cc8](https://github.com/sparkooptech/skpe-saas/commit/d27373cc16740dfc86eb940abf639e322b072cc8) | Último ponto investigado: frontend RAE; altera MyMeetingsPanel.tsx e CSS, sem migration no commit. |

### Relação com roadmap e próximo ponto seguro

O [roadmap](roadmap.md) permanece autoridade de sequência: **Medidas e Desempenho → Cockpit → gaps de Formulação**. A existência de código não altera essa prioridade nem fecha aceite. Os números GOV-20.1 são históricos e não se somam ao inventário B01–B31, cuja granularidade é diferente.

Na retomada, ler Hub → este documento → capability de Medidas → roadmap. Repetir preflight do produto e comparar o novo SHA com d27373cc16740dfc86eb940abf639e322b072cc8; registrar somente delta material. Próximo bloco seguro: obter as decisões Product registradas no [gate de Medidas](#decision-gate-e-próximo-passo) e então planejar as correções delimitadas de C02/C04, preservando suas decisões de autoridade; depois avaliar critérios já existentes do Cockpit, incluindo C03 e G2, e o fluxo RAE. Produto arbitra intenção; DEV fornece testes; Infrastructure comprova deployment em gate próprio.

Nenhum unknown autoriza redesign, migrations, limpeza de histórico ou replatforming. Esta wave entrega conhecimento e rastreabilidade; próximas mudanças funcionais exigem seu próprio escopo.

## Evidências versionadas

Todos os links de implementação abaixo fixam o SOURCE_SHA. Links locais apontam owners federados do Corporate; evidência em Downloads é auxiliar e não canônica.

- [APP](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/App.tsx#L963) — `apps/web/src/App.tsx`
- [M20260725040414](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260725040414_create_organizational_authorization_and_rls.sql) — `supabase/migrations/20260725040414_create_organizational_authorization_and_rls.sql`
- [ORG](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/lib/organizationHierarchy.ts) — `apps/web/src/lib/organizationHierarchy.ts`
- [M20260725031733](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260725031733_create_organizational_foundation.sql) — `supabase/migrations/20260725031733_create_organizational_foundation.sql`
- [M20260727215000](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260727215000_create_organization_hierarchy_and_descendant_access_v3.sql) — `supabase/migrations/20260727215000_create_organization_hierarchy_and_descendant_access_v3.sql`
- [M20260801003000](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260801003000_create_my_organization_hierarchy_v1.sql) — `supabase/migrations/20260801003000_create_my_organization_hierarchy_v1.sql`
- [T-organizationHierarchy](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/organizationHierarchy.test.ts) — `apps/web/tests/organizationHierarchy.test.ts`
- [ADMIN](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/platform-admin/PlatformAdmin.tsx) — `apps/web/src/modules/platform-admin/PlatformAdmin.tsx`
- [M20260829135123](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260829135123_govern_platform_admin_organizational_role_mutations.sql) — `supabase/migrations/20260829135123_govern_platform_admin_organizational_role_mutations.sql`
- [T-platformAdminOrganizationalRoles](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/platformAdminOrganizationalRoles.test.ts) — `apps/web/tests/platformAdminOrganizationalRoles.test.ts`
- [JOURNEY](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/journey/JourneySection.tsx) — `apps/web/src/modules/skpe/features/journey/JourneySection.tsx`
- [M20260727003000](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260727003000_create_skpe_journey_foundation.sql) — `supabase/migrations/20260727003000_create_skpe_journey_foundation.sql`
- [M20260816131440](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260816131440_fix_skpe_journey_hierarchical_rollup.sql) — `supabase/migrations/20260816131440_fix_skpe_journey_hierarchical_rollup.sql`
- [M20260818225044](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260818225044_harden_skpe_journey_schedule_governance.sql) — `supabase/migrations/20260818225044_harden_skpe_journey_schedule_governance.sql`
- [T-journeyItemStatusChange](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/journeyItemStatusChange.test.ts) — `apps/web/tests/journeyItemStatusChange.test.ts`
- [T-journeyEventDateTime](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/journeyEventDateTime.test.ts) — `apps/web/tests/journeyEventDateTime.test.ts`
- [EVID](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/diagnosis/StrategicEvidenceSection.tsx) — `apps/web/src/modules/skpe/features/diagnosis/StrategicEvidenceSection.tsx`
- [M20260905133824](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260905133824_create_transversal_evidence_operational_projection.sql) — `supabase/migrations/20260905133824_create_transversal_evidence_operational_projection.sql`
- [M20260905131345](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260905131345_converge_legacy_skpe_evidence_to_transversal_assets.sql) — `supabase/migrations/20260905131345_converge_legacy_skpe_evidence_to_transversal_assets.sql`
- [DIAG](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/diagnosis/StrategicDiagnosisSection.tsx) — `apps/web/src/modules/skpe/features/diagnosis/StrategicDiagnosisSection.tsx`
- [DIAG-LOAD](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/diagnosis/strategicDiagnosisImportLoader.ts#L150) — `apps/web/src/modules/skpe/features/diagnosis/strategicDiagnosisImportLoader.ts`
- [M20260906144500](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260906144500_materialize_skpe_strategic_diagnosis_artifacts.sql) — `supabase/migrations/20260906144500_materialize_skpe_strategic_diagnosis_artifacts.sql`
- [T-strategic-diagnosis-import-loader](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/strategic-diagnosis-import-loader.test.ts) — `apps/web/tests/strategic-diagnosis-import-loader.test.ts`
- [RISK](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/diagnosis/StrategicRisksSmartGrid.tsx) — `apps/web/src/modules/skpe/features/diagnosis/StrategicRisksSmartGrid.tsx`
- [M20260906190500](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260906190500_govern_strategic_risk_mitigation_to_initiative_5w2h.sql) — `supabase/migrations/20260906190500_govern_strategic_risk_mitigation_to_initiative_5w2h.sql`
- [FORM](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/strategy/StrategicFormulationSection.tsx#L136) — `apps/web/src/modules/skpe/features/strategy/StrategicFormulationSection.tsx`
- [M20260730033000](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730033000_create_strategic_formulation_and_shared_business_architecture_foundation.sql) — `supabase/migrations/20260730033000_create_strategic_formulation_and_shared_business_architecture_foundation.sql`
- [M20260730040000](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730040000_create_strategic_formulation_governance_and_versioning.sql) — `supabase/migrations/20260730040000_create_strategic_formulation_governance_and_versioning.sql`
- [T-skpeRoutes](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/skpeRoutes.test.ts) — `apps/web/tests/skpeRoutes.test.ts`
- [FE02](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-002_GOVERNANCA_VERSIONAMENTO_FORMULACAO.md) — `docs/03-methodology/REQ-SKPE-FE-002_GOVERNANCA_VERSIONAMENTO_FORMULACAO.md`
- [IDENTITY](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/strategy/StrategicIdentitySection.tsx) — `apps/web/src/modules/skpe/features/strategy/StrategicIdentitySection.tsx`
- [M20260730043000](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730043000_create_strategic_identity_operations.sql) — `supabase/migrations/20260730043000_create_strategic_identity_operations.sql`
- [FE03](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-003_IDENTIDADE_ESTRATEGICA_OPERACIONAL.md) — `docs/03-methodology/REQ-SKPE-FE-003_IDENTIDADE_ESTRATEGICA_OPERACIONAL.md`
- [CANVAS](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/SkpeCockpit.tsx#L1063) — `apps/web/src/modules/skpe/SkpeCockpit.tsx`
- [M20260730050000](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730050000_create_business_foundation_and_value_chain_operations.sql) — `supabase/migrations/20260730050000_create_business_foundation_and_value_chain_operations.sql`
- [FE04](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-004_FUNDAMENTACAO_NEGOCIO_E_CADEIA_VALOR.md) — `docs/03-methodology/REQ-SKPE-FE-004_FUNDAMENTACAO_NEGOCIO_E_CADEIA_VALOR.md`
- [BSC](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/strategy/StrategicBscMap.tsx#L450) — `apps/web/src/modules/skpe/features/strategy/StrategicBscMap.tsx`
- [M20260730060000](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730060000_create_strategic_themes_perspectives_and_objectives_operations.sql) — `supabase/migrations/20260730060000_create_strategic_themes_perspectives_and_objectives_operations.sql`
- [T-strategic-map-adapter](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/strategic-map-adapter.test.ts) — `apps/web/tests/strategic-map-adapter.test.ts`
- [T-strategic-bsc-layout](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/strategic-bsc-layout.test.ts) — `apps/web/tests/strategic-bsc-layout.test.ts`
- [T-strategic-cause-effect-suggestions](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/strategic-cause-effect-suggestions.test.ts) — `apps/web/tests/strategic-cause-effect-suggestions.test.ts`
- [FE05](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-005_TEMAS_PERSPECTIVAS_E_OBJETIVOS_ESTRATEGICOS.md) — `docs/03-methodology/REQ-SKPE-FE-005_TEMAS_PERSPECTIVAS_E_OBJETIVOS_ESTRATEGICOS.md`
- [MEAS](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/measures/MeasuresPerformanceWorkspace.tsx#L149) — `apps/web/src/modules/measures/MeasuresPerformanceWorkspace.tsx`
- [DUAL](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/measures/SparksMeasureDualSelector.tsx#L255) — `apps/web/src/modules/measures/SparksMeasureDualSelector.tsx`
- [M20260908015851](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260908015851_govern_transversal_measure_performance_context_read.sql) — `supabase/migrations/20260908015851_govern_transversal_measure_performance_context_read.sql`
- [M20260909214455](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260909214455_govern_organization_measure_reference_adoption.sql) — `supabase/migrations/20260909214455_govern_organization_measure_reference_adoption.sql`
- [M20260909234252](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260909234252_reconcile_organization_specific_measure_indicators.sql) — `supabase/migrations/20260909234252_reconcile_organization_specific_measure_indicators.sql`
- [M20260730070000](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730070000_create_strategic_indicators_targets_and_benchmarking_operations.sql) — `supabase/migrations/20260730070000_create_strategic_indicators_targets_and_benchmarking_operations.sql`
- [M20260904234019](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260904234019_establish_transversal_measures_performance_write_facade.sql) — `supabase/migrations/20260904234019_establish_transversal_measures_performance_write_facade.sql`
- [FE06](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-006_INDICADORES_METAS_LONGO_PRAZO_BENCHMARKING.md) — `docs/03-methodology/REQ-SKPE-FE-006_INDICADORES_METAS_LONGO_PRAZO_BENCHMARKING.md`
- [BENCH](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/measures/OrganizationIndicatorsSmartGrid.tsx#L213) — `apps/web/src/modules/measures/OrganizationIndicatorsSmartGrid.tsx`
- [M20260908170508](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260908170508_govern_platform_measure_reference_catalog.sql) — `supabase/migrations/20260908170508_govern_platform_measure_reference_catalog.sql`
- [M20260908220330](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260908220330_govern_platform_measure_reference_deletion.sql) — `supabase/migrations/20260908220330_govern_platform_measure_reference_deletion.sql`
- [M20260730100000](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730100000_create_strategic_monitoring_governance_and_learning.sql) — `supabase/migrations/20260730100000_create_strategic_monitoring_governance_and_learning.sql`
- [FE09](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-009_MONITORAMENTO_GOVERNANCA_APRENDIZADO_ESTRATEGICO.md) — `docs/03-methodology/REQ-SKPE-FE-009_MONITORAMENTO_GOVERNANCA_APRENDIZADO_ESTRATEGICO.md`
- [ANALYTICS](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/initiatives/analytics/InitiativePerformanceCockpit.tsx#L282) — `apps/web/src/modules/initiatives/analytics/InitiativePerformanceCockpit.tsx`
- [M20260906201500](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260906201500_converge_sparks_portfolio_with_skpe_suggested_drafts.sql) — `supabase/migrations/20260906201500_converge_sparks_portfolio_with_skpe_suggested_drafts.sql`
- [OKR](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/strategy/StrategicOkrDecompositionSection.tsx#L250) — `apps/web/src/modules/skpe/features/strategy/StrategicOkrDecompositionSection.tsx`
- [M20260730080000](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730080000_create_okrs_key_results_and_strategic_deployment_operations.sql) — `supabase/migrations/20260730080000_create_okrs_key_results_and_strategic_deployment_operations.sql`
- [M20260904164552](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260904164552_govern_okr_semantic_quality_before_validation.sql) — `supabase/migrations/20260904164552_govern_okr_semantic_quality_before_validation.sql`
- [FE07](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-007_OKRS_RESULTADOS_CHAVE_DESDOBRAMENTO_ESTRATEGICO.md) — `docs/03-methodology/REQ-SKPE-FE-007_OKRS_RESULTADOS_CHAVE_DESDOBRAMENTO_ESTRATEGICO.md`
- [PORT](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/initiatives/data/initiativePortfolioData.ts#L77) — `apps/web/src/modules/initiatives/data/initiativePortfolioData.ts`
- [M20260820145252](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260820145252_harden_sparks_initiative_lifecycle_contract.sql) — `supabase/migrations/20260820145252_harden_sparks_initiative_lifecycle_contract.sql`
- [FE08](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-008_INICIATIVAS_PROGRAMAS_PROJETOS_PLANOS_ACAO.md) — `docs/03-methodology/REQ-SKPE-FE-008_INICIATIVAS_PROGRAMAS_PROJETOS_PLANOS_ACAO.md`
- [ACTIONS](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/initiatives/data/initiativeActionsData.ts#L737) — `apps/web/src/modules/initiatives/data/initiativeActionsData.ts`
- [M20260821094420](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260821094420_govern_sparks_initiative_action_operations.sql) — `supabase/migrations/20260821094420_govern_sparks_initiative_action_operations.sql`
- [M20260727032500](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260727032500_add_initiative_validation_5w2h_and_key_results.sql) — `supabase/migrations/20260727032500_add_initiative_validation_5w2h_and_key_results.sql`
- [T-initiativeActionDraftGovernance](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/initiativeActionDraftGovernance.test.ts) — `apps/web/tests/initiativeActionDraftGovernance.test.ts`
- [T-initiativeActionEconomics](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/initiativeActionEconomics.test.ts) — `apps/web/tests/initiativeActionEconomics.test.ts`
- [CAPACITY](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/monitoring/personCapacity.ts) — `apps/web/src/modules/skpe/features/monitoring/personCapacity.ts`
- [M20260826225500](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260826225500_govern_sparks_person_capacity_allocation_foundation.sql) — `supabase/migrations/20260826225500_govern_sparks_person_capacity_allocation_foundation.sql`
- [M20260827195359](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260827195359_harden_sparks_person_capacity_period_lifecycle.sql) — `supabase/migrations/20260827195359_harden_sparks_person_capacity_period_lifecycle.sql`
- [T-personCapacity](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/personCapacity.test.ts) — `apps/web/tests/personCapacity.test.ts`
- [T-personCapacityAudit](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/personCapacityAudit.test.ts) — `apps/web/tests/personCapacityAudit.test.ts`
- [T-initiativeActionCapacityAllocationEditing](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/initiativeActionCapacityAllocationEditing.test.ts) — `apps/web/tests/initiativeActionCapacityAllocationEditing.test.ts`
- [T-initiativeActionCapacityAudit](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/initiativeActionCapacityAudit.test.ts) — `apps/web/tests/initiativeActionCapacityAudit.test.ts`
- [MONITOR](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/monitoring/MonitoringSection.tsx#L308) — `apps/web/src/modules/skpe/features/monitoring/MonitoringSection.tsx`
- [M20260828163046](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260828163046_harden_skpe_integrated_authorization_contract.sql) — `supabase/migrations/20260828163046_harden_skpe_integrated_authorization_contract.sql`
- [T-monitoringExecutionMatrix](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/monitoringExecutionMatrix.test.ts) — `apps/web/tests/monitoringExecutionMatrix.test.ts`
- [T-monitoringTimeline](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/monitoringTimeline.test.ts) — `apps/web/tests/monitoringTimeline.test.ts`
- [RAE](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/workspace/MyMeetingsPanel.tsx#L1005) — `apps/web/src/modules/skpe/workspace/MyMeetingsPanel.tsx`
- [AGENDA](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/agenda/AgendaSection.tsx#L143) — `apps/web/src/modules/skpe/features/agenda/AgendaSection.tsx`
- [M20260825003000](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260825003000_govern_sparks_transversal_agenda_foundation.sql) — `supabase/migrations/20260825003000_govern_sparks_transversal_agenda_foundation.sql`
- [M20260829232922](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260829232922_extend_skpe_agenda_projection_with_initiative_deadlines.sql) — `supabase/migrations/20260829232922_extend_skpe_agenda_projection_with_initiative_deadlines.sql`
- [FE10](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-010_EXPERIENCIA_APLICACIONAL_E_OPERACIONALIZACAO_FORMULACAO.md) — `docs/03-methodology/REQ-SKPE-FE-010_EXPERIENCIA_APLICACIONAL_E_OPERACIONALIZACAO_FORMULACAO.md`
- [EVOLUTION](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/evolution/evolutionData.ts) — `apps/web/src/modules/skpe/features/evolution/evolutionData.ts`
- [M20260818120356](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260818120356_skpe_evolution_cycles_canonical_foundation.sql) — `supabase/migrations/20260818120356_skpe_evolution_cycles_canonical_foundation.sql`
- [M20260818141323](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260818141323_skpe_objective_evolution_alignment_governed_operations.sql) — `supabase/migrations/20260818141323_skpe_objective_evolution_alignment_governed_operations.sql`
- [IMPORT](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/portability/CanonicalImportStaging.tsx#L439) — `apps/web/src/modules/portability/CanonicalImportStaging.tsx`
- [EXPORT](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/portability/PortabilityAdmin.tsx) — `apps/web/src/modules/portability/PortabilityAdmin.tsx`
- [M20260728183000](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260728183000_create_skpe_canonical_import_staging.sql) — `supabase/migrations/20260728183000_create_skpe_canonical_import_staging.sql`
- [M20260814142445](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260814142445_co_import_04_c9_e_key_result_materializer.sql) — `supabase/migrations/20260814142445_co_import_04_c9_e_key_result_materializer.sql`
- [T-parseCanonicalWorkbook](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/parseCanonicalWorkbook.test.ts) — `apps/web/tests/parseCanonicalWorkbook.test.ts`
- [ARTIFACT](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/artifacts/MethodologyArtifactsSection.tsx) — `apps/web/src/modules/skpe/features/artifacts/MethodologyArtifactsSection.tsx`
- [KIT](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/DeliveryKitDialog.tsx) — `apps/web/src/modules/skpe/DeliveryKitDialog.tsx`
- [M20260728133000](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260728133000_create_methodology_artifacts_operational_api.sql) — `supabase/migrations/20260728133000_create_methodology_artifacts_operational_api.sql`
- [WORKSPACE](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/workspace/MyWorkspacePage.tsx) — `apps/web/src/modules/skpe/workspace/MyWorkspacePage.tsx`
- [M20260805200500](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260805200500_create_user_module_preferences.sql) — `supabase/migrations/20260805200500_create_user_module_preferences.sql`
- [M20260808130000](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260808130000_create_my_skpe_notifications.sql) — `supabase/migrations/20260808130000_create_my_skpe_notifications.sql`
- [M20260830225217](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260830225217_govern_skpe_personal_work_scope.sql) — `supabase/migrations/20260830225217_govern_skpe_personal_work_scope.sql`
- [DOC-WORKSPACE](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/CONTRATO_MEU_ESPACO_TRABALHO_FE09A05.md) — `docs/03-methodology/CONTRATO_MEU_ESPACO_TRABALHO_FE09A05.md`
- [PKG](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/package.json) — `apps/web/package.json`
- [ENTRY](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/main.tsx) — `apps/web/src/main.tsx`
- [ROUTE-ADAPTER](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/app/SkpeWorkspace.tsx) — `apps/web/src/modules/skpe/app/SkpeWorkspace.tsx`
- [ROUTES](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/app/skpeRoutes.ts) — `apps/web/src/modules/skpe/app/skpeRoutes.ts`
- [WF](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/.github/workflows/deploy-skpe-saas-homol.yml) — `.github/workflows/deploy-skpe-saas-homol.yml`
- [DOCKER](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/deploy/hostinger/skpe-saas-homol/Dockerfile) — `deploy/hostinger/skpe-saas-homol/Dockerfile`
- [NGINX](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/deploy/hostinger/skpe-saas-homol/runtime/nginx.conf) — `deploy/hostinger/skpe-saas-homol/runtime/nginx.conf`
- [DEPLOY](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/deploy/hostinger/skpe-saas-homol/docker-compose.yml) — `deploy/hostinger/skpe-saas-homol/docker-compose.yml`
- [EDGE-INVITE](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/functions/invite-platform-user/index.ts) — `supabase/functions/invite-platform-user/index.ts`
- [SQL-ROLLUP](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/tests/skpe_journey_hierarchical_rollup_test.sql) — `supabase/tests/skpe_journey_hierarchical_rollup_test.sql`

[APP]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/App.tsx#L963
[M20260725040414]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260725040414_create_organizational_authorization_and_rls.sql
[ORG]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/lib/organizationHierarchy.ts
[M20260725031733]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260725031733_create_organizational_foundation.sql
[M20260727215000]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260727215000_create_organization_hierarchy_and_descendant_access_v3.sql
[M20260801003000]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260801003000_create_my_organization_hierarchy_v1.sql
[T-organizationHierarchy]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/organizationHierarchy.test.ts
[ADMIN]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/platform-admin/PlatformAdmin.tsx
[M20260829135123]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260829135123_govern_platform_admin_organizational_role_mutations.sql
[T-platformAdminOrganizationalRoles]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/platformAdminOrganizationalRoles.test.ts
[JOURNEY]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/journey/JourneySection.tsx
[M20260727003000]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260727003000_create_skpe_journey_foundation.sql
[M20260816131440]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260816131440_fix_skpe_journey_hierarchical_rollup.sql
[M20260818225044]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260818225044_harden_skpe_journey_schedule_governance.sql
[T-journeyItemStatusChange]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/journeyItemStatusChange.test.ts
[T-journeyEventDateTime]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/journeyEventDateTime.test.ts
[EVID]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/diagnosis/StrategicEvidenceSection.tsx
[M20260905133824]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260905133824_create_transversal_evidence_operational_projection.sql
[M20260905131345]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260905131345_converge_legacy_skpe_evidence_to_transversal_assets.sql
[DIAG]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/diagnosis/StrategicDiagnosisSection.tsx
[DIAG-LOAD]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/diagnosis/strategicDiagnosisImportLoader.ts#L150
[M20260906144500]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260906144500_materialize_skpe_strategic_diagnosis_artifacts.sql
[T-strategic-diagnosis-import-loader]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/strategic-diagnosis-import-loader.test.ts
[RISK]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/diagnosis/StrategicRisksSmartGrid.tsx
[M20260906190500]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260906190500_govern_strategic_risk_mitigation_to_initiative_5w2h.sql
[FORM]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/strategy/StrategicFormulationSection.tsx#L136
[M20260730033000]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730033000_create_strategic_formulation_and_shared_business_architecture_foundation.sql
[M20260730040000]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730040000_create_strategic_formulation_governance_and_versioning.sql
[T-skpeRoutes]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/skpeRoutes.test.ts
[FE02]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-002_GOVERNANCA_VERSIONAMENTO_FORMULACAO.md
[IDENTITY]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/strategy/StrategicIdentitySection.tsx
[M20260730043000]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730043000_create_strategic_identity_operations.sql
[FE03]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-003_IDENTIDADE_ESTRATEGICA_OPERACIONAL.md
[CANVAS]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/SkpeCockpit.tsx#L1063
[M20260730050000]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730050000_create_business_foundation_and_value_chain_operations.sql
[FE04]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-004_FUNDAMENTACAO_NEGOCIO_E_CADEIA_VALOR.md
[BSC]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/strategy/StrategicBscMap.tsx#L450
[M20260730060000]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730060000_create_strategic_themes_perspectives_and_objectives_operations.sql
[T-strategic-map-adapter]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/strategic-map-adapter.test.ts
[T-strategic-bsc-layout]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/strategic-bsc-layout.test.ts
[T-strategic-cause-effect-suggestions]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/strategic-cause-effect-suggestions.test.ts
[FE05]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-005_TEMAS_PERSPECTIVAS_E_OBJETIVOS_ESTRATEGICOS.md
[MEAS]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/measures/MeasuresPerformanceWorkspace.tsx#L149
[DUAL]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/measures/SparksMeasureDualSelector.tsx#L255
[M20260908015851]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260908015851_govern_transversal_measure_performance_context_read.sql
[M20260909214455]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260909214455_govern_organization_measure_reference_adoption.sql
[M20260909234252]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260909234252_reconcile_organization_specific_measure_indicators.sql
[M20260730070000]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730070000_create_strategic_indicators_targets_and_benchmarking_operations.sql
[M20260904234019]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260904234019_establish_transversal_measures_performance_write_facade.sql
[FE06]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-006_INDICADORES_METAS_LONGO_PRAZO_BENCHMARKING.md
[BENCH]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/measures/OrganizationIndicatorsSmartGrid.tsx#L213
[M20260908170508]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260908170508_govern_platform_measure_reference_catalog.sql
[M20260908220330]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260908220330_govern_platform_measure_reference_deletion.sql
[M20260730100000]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730100000_create_strategic_monitoring_governance_and_learning.sql
[FE09]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-009_MONITORAMENTO_GOVERNANCA_APRENDIZADO_ESTRATEGICO.md
[ANALYTICS]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/initiatives/analytics/InitiativePerformanceCockpit.tsx#L282
[M20260906201500]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260906201500_converge_sparks_portfolio_with_skpe_suggested_drafts.sql
[OKR]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/strategy/StrategicOkrDecompositionSection.tsx#L250
[M20260730080000]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730080000_create_okrs_key_results_and_strategic_deployment_operations.sql
[M20260904164552]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260904164552_govern_okr_semantic_quality_before_validation.sql
[FE07]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-007_OKRS_RESULTADOS_CHAVE_DESDOBRAMENTO_ESTRATEGICO.md
[PORT]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/initiatives/data/initiativePortfolioData.ts#L77
[M20260820145252]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260820145252_harden_sparks_initiative_lifecycle_contract.sql
[FE08]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-008_INICIATIVAS_PROGRAMAS_PROJETOS_PLANOS_ACAO.md
[ACTIONS]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/initiatives/data/initiativeActionsData.ts#L737
[M20260821094420]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260821094420_govern_sparks_initiative_action_operations.sql
[M20260727032500]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260727032500_add_initiative_validation_5w2h_and_key_results.sql
[T-initiativeActionDraftGovernance]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/initiativeActionDraftGovernance.test.ts
[T-initiativeActionEconomics]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/initiativeActionEconomics.test.ts
[CAPACITY]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/monitoring/personCapacity.ts
[M20260826225500]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260826225500_govern_sparks_person_capacity_allocation_foundation.sql
[M20260827195359]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260827195359_harden_sparks_person_capacity_period_lifecycle.sql
[T-personCapacity]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/personCapacity.test.ts
[T-personCapacityAudit]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/personCapacityAudit.test.ts
[T-initiativeActionCapacityAllocationEditing]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/initiativeActionCapacityAllocationEditing.test.ts
[T-initiativeActionCapacityAudit]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/initiativeActionCapacityAudit.test.ts
[MONITOR]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/monitoring/MonitoringSection.tsx#L308
[M20260828163046]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260828163046_harden_skpe_integrated_authorization_contract.sql
[T-monitoringExecutionMatrix]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/monitoringExecutionMatrix.test.ts
[T-monitoringTimeline]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/monitoringTimeline.test.ts
[RAE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/workspace/MyMeetingsPanel.tsx#L1005
[AGENDA]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/agenda/AgendaSection.tsx#L143
[M20260825003000]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260825003000_govern_sparks_transversal_agenda_foundation.sql
[M20260829232922]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260829232922_extend_skpe_agenda_projection_with_initiative_deadlines.sql
[FE10]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-010_EXPERIENCIA_APLICACIONAL_E_OPERACIONALIZACAO_FORMULACAO.md
[EVOLUTION]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/evolution/evolutionData.ts
[M20260818120356]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260818120356_skpe_evolution_cycles_canonical_foundation.sql
[M20260818141323]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260818141323_skpe_objective_evolution_alignment_governed_operations.sql
[IMPORT]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/portability/CanonicalImportStaging.tsx#L439
[EXPORT]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/portability/PortabilityAdmin.tsx
[M20260728183000]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260728183000_create_skpe_canonical_import_staging.sql
[M20260814142445]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260814142445_co_import_04_c9_e_key_result_materializer.sql
[T-parseCanonicalWorkbook]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/parseCanonicalWorkbook.test.ts
[ARTIFACT]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/artifacts/MethodologyArtifactsSection.tsx
[KIT]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/DeliveryKitDialog.tsx
[M20260728133000]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260728133000_create_methodology_artifacts_operational_api.sql
[WORKSPACE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/workspace/MyWorkspacePage.tsx
[M20260805200500]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260805200500_create_user_module_preferences.sql
[M20260808130000]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260808130000_create_my_skpe_notifications.sql
[M20260830225217]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260830225217_govern_skpe_personal_work_scope.sql
[DOC-WORKSPACE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/CONTRATO_MEU_ESPACO_TRABALHO_FE09A05.md
[PKG]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/package.json
[ENTRY]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/main.tsx
[ROUTE-ADAPTER]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/app/SkpeWorkspace.tsx
[ROUTES]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/app/skpeRoutes.ts
[WF]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/.github/workflows/deploy-skpe-saas-homol.yml
[DOCKER]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/deploy/hostinger/skpe-saas-homol/Dockerfile
[NGINX]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/deploy/hostinger/skpe-saas-homol/runtime/nginx.conf
[DEPLOY]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/deploy/hostinger/skpe-saas-homol/docker-compose.yml
[EDGE-INVITE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/functions/invite-platform-user/index.ts
[SQL-ROLLUP]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/tests/skpe_journey_hierarchical_rollup_test.sql

[MI20260730033000]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730033000_create_strategic_formulation_and_shared_business_architecture_foundation.sql
[MI20260730040000]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730040000_create_strategic_formulation_governance_and_versioning.sql
[MI20260730070000]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730070000_create_strategic_indicators_targets_and_benchmarking_operations.sql
[MI20260730100000]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730100000_create_strategic_monitoring_governance_and_learning.sql
[MI20260807013000]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260807013000_create_my_skpe_indicators.sql
[MI20260904233009]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260904233009_establish_transversal_measures_performance_facade.sql
[MI20260904234019]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260904234019_establish_transversal_measures_performance_write_facade.sql
[MI20260908015851]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260908015851_govern_transversal_measure_performance_context_read.sql
[MI20260908135440]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260908135440_govern_measure_reference_catalog_adoption.sql
[MI20260908170508]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260908170508_govern_platform_measure_reference_catalog.sql
[MI20260909214455]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260909214455_govern_organization_measure_reference_adoption.sql
[MI20260909234252]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260909234252_reconcile_organization_specific_measure_indicators.sql
[MI-MEAS]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/measures/MeasuresPerformanceWorkspace.tsx#L149
[MI-GRID]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/measures/OrganizationIndicatorsSmartGrid.tsx#L120
[MI-DUAL]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/measures/SparksMeasureDualSelector.tsx#L115
[MI-MY]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/workspace/MyIndicatorsPanel.tsx#L134
[MI-OKR]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/strategy/StrategicOkrDecompositionSection.tsx#L270
[MI-FORM]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/strategy/StrategicFormulationSection.tsx#L135
[MI-ANALYTICS]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/initiatives/analytics/InitiativePerformanceCockpit.tsx#L249
[MI-MON]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/monitoring/MonitoringSection.tsx#L308
[MI-PLATFORM]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/platform-admin/PlatformMeasureCatalog.tsx
[MI-FE02]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-002_GOVERNANCA_VERSIONAMENTO_FORMULACAO.md#L29
[MI-FE06]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-006_INDICADORES_METAS_LONGO_PRAZO_BENCHMARKING.md#L373
[MI-FE09]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-009_MONITORAMENTO_GOVERNANCA_APRENDIZADO_ESTRATEGICO.md#L61

## Piloto funcional de Medidas e regras de negócio

O [piloto no owner de Medidas](capabilities/SKPE-MED-DES-01-medidas-desempenho.md#piloto-funcional-e-regras-de-negócio--12092026), indexado em [business rules](business-rules/README.md), detalha 24 funcionalidades e 44 regras no mesmo SOURCE_SHA d27373cc16740dfc86eb940abf639e322b072cc8, sem delta do produto. As classes de autoridade distinguem decisão explícita, documentação, implementação, inferência, conflito e pendência Product.

Qualificação das evidências históricas acima: MeasuresPerformanceWorkspace retorna SparksMeasureDualSelector quando mode=administration, antes do JSX antigo de adoção contextual. Assim, a presença do handler adopt_sparks_measure_reference_indicator não comprova UI alcançável para adoção em objetivo; o contrato SQL continua disponível. Ver F-MED-006 e BR-SKPE-MED-042 no owner, com fonte fixada. Adoção organizacional e edição/transição de benchmark continuam com consumidores identificados. C01/C02 permanecem OPEN_PRODUCT_DECISION.

O piloto também distingue a agregação preparatória por ciclo (que pode preferir submitted) do gate de fechamento/snapshot; C04 continua OPEN_PRODUCT_DECISION. Nenhuma regra implementada foi promovida automaticamente a intenção. Testes diretos das regras não foram localizados no escopo pesquisado; runtime e aceite continuam UNKNOWN. Esta documentação não reabre a baseline inteira nem autoriza implementação. Retomada funcional de C01/C02/C04 permanece condicionada à retomada de Medidas.
