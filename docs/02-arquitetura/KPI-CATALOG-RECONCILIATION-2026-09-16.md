---
id: kpi-catalog-reconciliation-2026-09-16
title: Reconciliação do Catálogo KPI — Runtime x Base v1.0
status: in_review
owner: product-platform
language: pt-BR
---

# Reconciliação do Catálogo KPI — 2026-09-16

Base runtime: 60 linhas, 46 códigos vigentes e 14 versões históricas.

Base candidata: 78 KPIs do pacote `SPARKs_PE_Base_KPIs_BMK_Ramos_v1_0`.

Regra: preservar identidade/ID vigente quando houver `SAME` ou alias homologado. Não importar nem migrar neste estágio.

A classificação abaixo é uma primeira passagem semântica conservadora. `NO_EQUIVALENT_FOUND_YET` não equivale a aprovação como KPI novo; exige homologação metodológica.

| KPI v1.0 | Nome | Relação preliminar | Relacionado |
| --- | --- | --- | --- |
| KPI-BAS-01 | Margem de contribuição por solução | SPECIALIZATION | FIN-MC-01 |
| KPI-BAS-02 | Margem operacional / sobras sobre ingressos | CONTEXTUAL_VARIANT | FIN-MO-01 |
| KPI-BAS-03 | Fluxo de caixa operacional sobre receita | ALIAS | KPI-TRV-002 |
| KPI-BAS-04 | Concentração de receita Top 1 / Top 5 | NEEDS_HUMAN_DECISION | FIN-CONC-CLI-01 / FIN-CONC-PROJ-01 |
| KPI-BAS-05 | Taxa de ativação de novos cooperados | NO_EQUIVALENT_FOUND_YET | — |
| KPI-BAS-06 | Churn de cooperados | NEEDS_HUMAN_DECISION | KPI-TRV-005 |
| KPI-BAS-07 | Adoção de benefícios | SPECIALIZATION | KPI-TRV-007 |
| KPI-BAS-08 | Reclamações por 1.000 cooperados | SPECIALIZATION | KPI-TRV-008 |
| KPI-BAS-09 | Resolução no primeiro contato (FCR) | NO_EQUIVALENT_FOUND_YET | — |
| KPI-BAS-10 | Adoção digital ativa | NO_EQUIVALENT_FOUND_YET | — |
| KPI-BAS-11 | Disponibilidade dos canais críticos | SPECIALIZATION | KPI-TRV-011 |
| KPI-BAS-12 | Qualidade dos dados estratégicos | NO_EQUIVALENT_FOUND_YET | — |
| KPI-BAS-13 | Receita/margem por parceiro ativo | NO_EQUIVALENT_FOUND_YET | — |
| KPI-BAS-14 | Conversão de leads de intercooperação | NO_EQUIVALENT_FOUND_YET | — |
| KPI-BAS-15 | Vitalidade da inovação | NO_EQUIVALENT_FOUND_YET | — |
| KPI-BAS-16 | Cobertura de competências críticas | NO_EQUIVALENT_FOUND_YET | — |
| KPI-BAS-17 | Cobertura de sucessão | NO_EQUIVALENT_FOUND_YET | — |
| KPI-BAS-18 | Eficácia do treinamento | NO_EQUIVALENT_FOUND_YET | — |
| KPI-BAS-19 | Eficácia de controles críticos | NO_EQUIVALENT_FOUND_YET | — |
| KPI-BAS-20 | Tempo de remediação de não conformidades | ALIAS | KPI-TRV-015 |
| KPI-BAS-21 | Execução de decisões estratégicas | NO_EQUIVALENT_FOUND_YET | — |
| KPI-BAS-22 | Atingimento de KRs/FCS | ALIAS | KPI-TRV-016 |
| KPI-TRV-001 | Crescimento de receita/ingressos | SPECIALIZATION_PAIR | KPI-CONSUMO-001 |
| KPI-TRV-002 | Fluxo de caixa operacional / receita | ALIAS | KPI-BAS-03 |
| KPI-TRV-003 | Inadimplência / perdas esperadas | NEEDS_HUMAN_DECISION | FIN-DEL-01 |
| KPI-TRV-004 | Crescimento da base de cooperados | NO_EQUIVALENT_FOUND_YET | — |
| KPI-TRV-005 | Churn / retenção de cooperados | NEEDS_HUMAN_DECISION | KPI-BAS-06 |
| KPI-TRV-006 | NPS/CSAT/satisfação | NEEDS_HUMAN_DECISION | CLI-NPS-01 / CLI-SAT-01 |
| KPI-TRV-007 | Adoção/uso de produtos e benefícios | SPECIALIZATION_PAIR | KPI-BAS-07 |
| KPI-TRV-008 | Reclamações normalizadas | SPECIALIZATION_PAIR | KPI-BAS-08 |
| KPI-TRV-009 | Produtividade por empregado/cooperado | NO_EQUIVALENT_FOUND_YET | — |
| KPI-TRV-010 | Custo operacional unitário | NO_EQUIVALENT_FOUND_YET | — |
| KPI-TRV-011 | Disponibilidade/SLA | SPECIALIZATION_PAIR | KPI-BAS-11 / ramo-specific |
| KPI-TRV-012 | Turnover voluntário | SPECIALIZATION | PES-TURN-01 |
| KPI-TRV-013 | Engajamento/clima | NO_EQUIVALENT_FOUND_YET | — |
| KPI-TRV-014 | Absenteísmo | NO_EQUIVALENT_FOUND_YET | — |
| KPI-TRV-015 | Tempo de remediação | ALIAS | KPI-BAS-20 |
| KPI-TRV-016 | Atingimento de KR/FCS | ALIAS | KPI-BAS-22 |
| KPI-AGRO-001 | Produtividade física por hectare/animal/unidade | NO_EQUIVALENT_FOUND_YET | — |
| KPI-AGRO-002 | Perdas pós-colheita / armazenagem | NO_EQUIVALENT_FOUND_YET | — |
| KPI-AGRO-003 | Capacidade de armazenagem utilizada | NO_EQUIVALENT_FOUND_YET | — |
| KPI-AGRO-004 | Preço recebido vs referência de mercado | NO_EQUIVALENT_FOUND_YET | — |
| KPI-AGRO-005 | Participação da produção comercializada via cooperativa | NO_EQUIVALENT_FOUND_YET | — |
| KPI-CONSUMO-001 | Crescimento de vendas mesmas lojas/canais | SPECIALIZATION | KPI-TRV-001 |
| KPI-CONSUMO-002 | Margem bruta | SAME | FIN-MB-01 |
| KPI-CONSUMO-003 | Giro de estoque | DERIVED | FIN-PME-01 |
| KPI-CONSUMO-004 | Ruptura | NO_EQUIVALENT_FOUND_YET | — |
| KPI-CONSUMO-005 | Ticket e frequência | NEEDS_HUMAN_DECISION | KPI composto |
| KPI-CREDITO-001 | Inadimplência 90+ dias | SPECIALIZATION | FIN-DEL-01 |
| KPI-CREDITO-002 | Índice de Basileia | NO_EQUIVALENT_FOUND_YET | — |
| KPI-CREDITO-003 | ROA/ROE | NEEDS_HUMAN_DECISION | FIN-ROA-01 / FIN-ROE-01 |
| KPI-CREDITO-004 | Índice de eficiência | NO_EQUIVALENT_FOUND_YET | — |
| KPI-CREDITO-005 | Crescimento e qualidade da carteira | NEEDS_HUMAN_DECISION | KPI composto |
| KPI-INFRA-001 | DEC | NO_EQUIVALENT_FOUND_YET | — |
| KPI-INFRA-002 | FEC | NO_EQUIVALENT_FOUND_YET | — |
| KPI-INFRA-003 | DGC continuidade | NO_EQUIVALENT_FOUND_YET | — |
| KPI-INFRA-004 | Perdas técnicas/comerciais | NO_EQUIVALENT_FOUND_YET | — |
| KPI-INFRA-005 | Disponibilidade de infraestrutura/serviço | SPECIALIZATION | KPI-TRV-011 |
| KPI-SAUDE-001 | IDSS | NO_EQUIVALENT_FOUND_YET | — |
| KPI-SAUDE-002 | Sinistralidade | NO_EQUIVALENT_FOUND_YET | — |
| KPI-SAUDE-003 | Índice de reclamações | SPECIALIZATION | KPI-TRV-008 |
| KPI-SAUDE-004 | Garantia de acesso | NEEDS_HUMAN_DECISION | índice/composto de rede e acesso |
| KPI-SAUDE-005 | Sustentabilidade econômico-financeira | NEEDS_HUMAN_DECISION | dimensão composta IDSM |
| KPI-SEGUROS-001 | Índice de sinistralidade | NO_EQUIVALENT_FOUND_YET | — |
| KPI-SEGUROS-002 | Índice combinado | NO_EQUIVALENT_FOUND_YET | — |
| KPI-SEGUROS-003 | Prêmio emitido / crescimento | NEEDS_HUMAN_DECISION | candidato ambíguo/composto |
| KPI-SEGUROS-004 | Cobertura de provisões/solvência | NEEDS_HUMAN_DECISION | candidato composto |
| KPI-SEGUROS-005 | Retenção e renovação | NO_EQUIVALENT_FOUND_YET | — |
| KPI-TPBS-001 | Receita por cooperado ativo | NO_EQUIVALENT_FOUND_YET | — |
| KPI-TPBS-002 | Margem por contrato/serviço | CONTEXTUAL_VARIANT | FIN-MARG-PROJ-01 |
| KPI-TPBS-003 | Ocupação/capacidade produtiva | NO_EQUIVALENT_FOUND_YET | — |
| KPI-TPBS-004 | SLA entregue | SPECIALIZATION | KPI-TRV-011 |
| KPI-TPBS-005 | Produtividade por hora | NO_EQUIVALENT_FOUND_YET | — |
| KPI-TRANSPORTE-001 | TKU / PKM por capacidade | NEEDS_HUMAN_DECISION | alternativas de medida no mesmo candidato |
| KPI-TRANSPORTE-002 | Quilometragem vazia | NO_EQUIVALENT_FOUND_YET | — |
| KPI-TRANSPORTE-003 | Custo por km | NO_EQUIVALENT_FOUND_YET | — |
| KPI-TRANSPORTE-004 | Disponibilidade da frota | SPECIALIZATION | KPI-TRV-011 |
| KPI-TRANSPORTE-005 | Pontualidade e segurança | NEEDS_HUMAN_DECISION | KPI composto |

## Contagem da primeira passagem

- `SAME`: 1 candidato.
- `ALIAS`: 6 linhas envolvidas em pares de alias.
- `SPECIALIZATION/SPECIALIZATION_PAIR`: 15 relações.
- `CONTEXTUAL_VARIANT`: 2 candidatos.
- `DERIVED`: 1 candidato.
- `NEEDS_HUMAN_DECISION`: 14 candidatos.
- `NO_EQUIVALENT_FOUND_YET`: 39 candidatos.

A contagem é por linha candidata e não representa o futuro número de identidades canônicas, pois pares e relações aparecem nos dois lados do pacote.

## Decisões já seguras

`KPI-CONSUMO-002` não deve gerar nova identidade: a definição deve convergir para `FIN-MB-01`, preservando o ID vigente e registrando a origem/alias da base v1.0.

Os pares `BAS-03/TRV-002`, `BAS-20/TRV-015` e `BAS-22/TRV-016` devem ser consolidados conceitualmente antes da carga, preferindo neste estágio as linhas BAS por possuírem definição metodológica mais completa.

Os candidatos compostos não devem ser publicados como um KPI único até serem decompostos ou terem metodologia composta explicitamente aprovada.

## Curadoria recomendada para `NEEDS_HUMAN_DECISION`

A recomendação técnica é evitar KPIs compostos ou rótulos guarda-chuva quando já existem medidas distintas e auditáveis.

| Grupo | Recomendação |
| --- | --- |
| BAS-04 — Concentração Top 1/Top 5 | Preservar FIN-CONC-CLI-01 e FIN-CONC-PROJ-01; tratar Top 5 como definição própria ou família parametrizada somente após decisão metodológica. |
| BAS-06 / TRV-005 — Churn/retenção | Adotar churn com fórmula explícita; retenção somente como métrica derivada quando população e período tornarem `1 - churn` válido. |
| TRV-003 — Inadimplência/perdas esperadas | Não publicar composto; manter inadimplência separada e criar perda esperada apenas com fórmula própria. |
| TRV-006 — NPS/CSAT/satisfação | Não publicar composto; mapear NPS para CLI-NPS-01 e satisfação/CSAT para CLI-SAT-01. |
| CONSUMO-005 — Ticket e frequência | Decompor em ticket médio e frequência de compra. |
| CREDITO-003 — ROA/ROE | Não criar nova identidade; mapear para FIN-ROA-01 e FIN-ROE-01. |
| CREDITO-005 — Crescimento e qualidade da carteira | Decompor crescimento da carteira e qualidade/risco/provisão. |
| SAUDE-004/005 | Manter em curadoria até fórmula oficial/composta verificável do IDSS/IDSM; não inventar fórmula. |
| SEGUROS-003/004 | Decompor nível/crescimento de prêmio e provisões/solvência, salvo definição regulatória composta comprovada. |
| TRANSPORTE-001/005 | Separar TKU de PKM conforme operação e separar pontualidade de segurança/acidentalidade. |

Essas recomendações preservam granularidade de medição, comparabilidade e explicabilidade de desempenho.
