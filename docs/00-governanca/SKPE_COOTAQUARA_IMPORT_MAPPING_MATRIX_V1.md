# SK-PE — COOTAQUARA — Matriz de Mapping de Importação v1

Status: EM EVOLUÇÃO CONTROLADA
Lote de referência: `c6c255e6-46d1-4072-9ebd-e0640345c98b`
Origem: workbook canônico COOTAQUARA v17 / schema 2.0.1
Total: 281 registros / 38 tipos

## Regra de leitura

Esta matriz distingue três níveis:

- **ATIVO/GOVERNADO**: existe catálogo ativo, versão ativa, destino canônico, materializador e proveniência.
- **CANDIDATO TÉCNICO**: o schema atual oferece destino compatível, mas ainda não existe mapping ativo completo. Não autoriza materialização.
- **REVISÃO/COMPOSTO**: o conteúdo precisa ser decomposto, reconciliado, agregado ou vinculado a mais de uma autoridade; não cabe mapping direto.
- **SEM DESTINO CONFIRMADO**: não foi identificada autoridade canônica suficiente para promover o registro.

Nenhuma linha CANDIDATO, REVISÃO ou SEM DESTINO autoriza escrita estratégica.

## Cobertura atual governada

| Tipo | Registros | Estado | Mapping ativo | Destino |
|---|---:|---|---|---|
| decision | 5 | ATIVO/GOVERNADO | decision_to_gate_decision | skpe_gate_decisions |
| indicator | 5 | ATIVO/GOVERNADO | indicator_to_indicator | skpe_indicators |
| key_result | 4 | ATIVO/GOVERNADO | key_result_to_key_result | skpe_key_results |
| okr | 4 | ATIVO/GOVERNADO | okr_to_okr | skpe_okrs |
| strategic_objective | 5 | ATIVO/GOVERNADO | strategic_objective_to_strategic_objective | skpe_strategic_objectives |
| pestel | 6 | ATIVO/GOVERNADO | pestel_to_pestel_item | skpe_pestel_items |
| swot | 12 | ATIVO/GOVERNADO | swot_to_swot_item | skpe_swot_items |

**Cobertura atual:** 41/281 registros (14,59%) e 7/38 tipos (18,42%).

Todos os sete mappings ativos exigem revisão humana e não permitem inferência semântica.

## Matriz completa

| entity_code | Reg. | Classificação v1 | Destino/caminho candidato | Regra principal antes da ativação |
|---|---:|---|---|---|
| action_5w2h | 6 | CANDIDATO TÉCNICO | sparks_initiative_actions | Resolver iniciativa por código; normalizar 5W2H sem inferir responsável/prazos |
| benchmark_reference | 6 | REVISÃO/COMPOSTO | skpe_benchmark_references / referências de indicador | Definir granularidade: referência global x referência de indicador |
| client_validation | 6 | REVISÃO/COMPOSTO | gate/governance decision | Resolver artefato/gate e distinguir submissão de decisão |
| decision | 5 | ATIVO/GOVERNADO | skpe_gate_decisions | Mapping ativo existente |
| deliberative_gate | 20 | REVISÃO/COMPOSTO | skpe_gate_decisions / Jornada | Separar definição do gate de decisão ocorrida |
| deviation_action | 1 | SEM DESTINO CONFIRMADO | — | Registro amostral é majoritariamente vazio; definir autoridade |
| evidence | 13 | REVISÃO/COMPOSTO | arquitetura transversal de Evidências / skpe_evidence_sources | Resolver ativo/evidência, confiabilidade e vínculos sem duplicação |
| evidence_checklist | 13 | CANDIDATO TÉCNICO | skpe_evidence_checklist_items | Resolver checklist-pai e journey item antes de materializar |
| evidence_management | 13 | REVISÃO/COMPOSTO | assessment/estado do checklist | Evitar duplicar evidence_checklist; tratar como camada operacional |
| handoff | 3 | SEM DESTINO CONFIRMADO | — | Definir autoridade de handoff/continuidade na Jornada |
| indicator | 5 | ATIVO/GOVERNADO | skpe_indicators | Mapping ativo existente |
| indicator_sheet | 12 | REVISÃO/COMPOSTO | skpe_indicators + skpe_indicator_targets + benchmarks | Enriquecer indicador existente; não criar segundo indicador |
| initiative | 6 | CANDIDATO TÉCNICO | sparks_initiatives + binding SK-PE | Usar core transversal atual; resolver OE e projeto |
| journey | 4 | REVISÃO/COMPOSTO | skpe_journey_items | Reconciliar com Jornada existente; não recriar template/metodologia |
| key_result | 4 | ATIVO/GOVERNADO | skpe_key_results | Mapping ativo existente |
| kpi_result | 5 | CANDIDATO TÉCNICO | skpe_indicator_measurements | Resolver indicador; exigir período/valor utilizável; linhas vazias não materializam medição |
| living_governance | 12 | SEM DESTINO CONFIRMADO | — | Conteúdo contém instruções/estrutura de workbook; não promover como fato |
| living_value | 6 | CANDIDATO TÉCNICO | skpe_strategic_values + behaviors | Separar valor de comportamentos e preservar status histórico |
| methodology_artifact | 9 | CANDIDATO TÉCNICO | sparks_methodology_artifacts | Resolver tipo/versão/evidência e evitar criar artefato sem arquivo/autoridade |
| okr | 4 | ATIVO/GOVERNADO | skpe_okrs | Mapping ativo existente |
| pending_item | 11 | REVISÃO/COMPOSTO | governance decision / ação / pendência | Classificar natureza de cada pendência antes de escolher autoridade |
| pestel | 6 | ATIVO/GOVERNADO | skpe_pestel_items | Mapping ativo `pestel_to_pestel_item`; revisão humana obrigatória; sem inferência semântica |
| pmvv_institutionalization | 7 | REVISÃO/COMPOSTO | identidade + ação + gate | Não confundir plano de institucionalização com identidade aprovada |
| pmvv_validation | 3 | REVISÃO/COMPOSTO | skpe_strategic_identity/items + decisão | Preservar proposta e decisão separadas |
| process_maturity | 4 | SEM DESTINO CONFIRMADO | — | Não foi identificada tabela canônica específica de maturidade do processo |
| project | 20 | REVISÃO/COMPOSTO | skpe_projects | Registros são chave/valor do mesmo projeto; agregar e reconciliar, não inserir 20 projetos |
| project_portfolio | 5 | REVISÃO/COMPOSTO | sparks_initiatives | Deduplicar contra initiative; confirmar se são projetos/iniciativas distintos |
| risk | 10 | CANDIDATO TÉCNICO FORTE | skpe_strategic_risk_items | Correspondência direta; não confundir com riscos operacionais de iniciativa |
| strategic_association | 12 | REVISÃO/COMPOSTO | links OE/KR/indicador | Materializar relações após entidades-base existirem |
| strategic_identity | 9 | CANDIDATO TÉCNICO | skpe_strategic_identity / items | Resolver elemento, versão/proposta e formulação vigente |
| strategic_meeting | 1 | SEM DESTINO CONFIRMADO | possível strategy review | Amostra é template vazio; não materializar sem conteúdo factual |
| strategic_objective | 5 | ATIVO/GOVERNADO | skpe_strategic_objectives | Mapping ativo existente |
| strategic_review | 1 | CANDIDATO CONDICIONAL | skpe_strategy_reviews | Amostra é template vazio; só promover revisão factual |
| strategy_map | 5 | REVISÃO/COMPOSTO | strategic map versions + objective relations | Conteúdo duplica OE e acrescenta causalidade/narrativa |
| swot | 12 | ATIVO/GOVERNADO | skpe_swot_items | Mapping ativo `swot_to_swot_item`; revisão humana obrigatória; sem inferência semântica |
| tows | 7 | CANDIDATO TÉCNICO FORTE | skpe_tows_items | Correspondência direta; preservar códigos dos fatores |
| traceability | 5 | REVISÃO/COMPOSTO | múltiplos links canônicos | Não existe entidade única: OE, risco, indicador, iniciativa, decisão e evidência |
| version_control | 5 | SEM DESTINO ESTRATÉGICO | auditoria/proveniência | Preservar histórico do arquivo; não converter em entidade estratégica |

## Próxima expansão recomendada pela matriz

Primeiro conjunto para novo mapping governado:

1. `tows -> skpe_tows_items` — 7 registros;
2. `risk -> skpe_strategic_risk_items` — 10 registros.

Esses dois tipos restantes somam **17 registros** e possuem:

- tabelas canônicas específicas;
- unicidade por organização/projeto/código;
- campos de origem `source_import_record_id`, `source_external_key`, `source_sheet`, `source_row`, `source_payload`;
- semântica explicitamente destinada ao Diagnóstico Estratégico;
- separação clara entre risco estratégico e risco operacional de iniciativa.

Com PESTEL e SWOT já ativos, a cobertura atual é **41/281 registros e 7/38 tipos**. Se TOWS e RISK forem ativados com materializadores e proveniência, a cobertura potencial sobe para **58 registros e 9 tipos**, sem recorrer a inferência semântica.

## Ordem de dependência sugerida

`PESTEL -> SWOT -> TOWS -> RISK`

A ordem não significa que PESTEL seja pai obrigatório de todos os itens, mas facilita validação dos códigos de origem e rastreabilidade:

- SWOT pode referenciar PESTEL;
- TOWS cruza fatores SWOT;
- riscos podem referenciar evidências e futuros objetivos;
- vínculos posteriores só devem ser criados quando as entidades-base existirem.

## Regras invariantes

- não atualizar `target_table` manualmente fora do fluxo governado;
- usar `skpe_create_import_incorporation_request` e mecanismos de resolução existentes;
- revisão humana permanece separada de validação institucional;
- status histórico da planilha não é promovido automaticamente a status canônico aprovado;
- proibir inferência semântica para resolver códigos, pais ou relacionamentos;
- materialização idempotente;
- cada objeto materializado deve manter proveniência até o `import_record`;
- nenhum mapping ativo pode ser criado sem materializador, validação e contrato de rollback/reconciliação compatíveis.
