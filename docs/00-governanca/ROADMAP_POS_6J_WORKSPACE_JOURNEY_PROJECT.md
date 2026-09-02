---
id: SKPE-ROADMAP-POS-6J-WORKSPACE-JOURNEY-PROJECT
version: 1.3.0
status: approved
domain: SPARKs PaaS
owner: SPARKs PE
canonical_context: SK-PE-CONT-01
created_at: 2026-08-29
updated_at: 2026-09-02
starts_after: 17-B.5F.3C.6J
remaining_gates: 2
integrity_gate: POS-6J.IR-01
ux_governance:
  manifesto: MANIFESTO_UX_SPARKS.md
  checklist: CHECKLIST_PRONTIDAO_UX_SPARKS.md
  benchmark: BENCHMARK_UX_SMARTKANVAS_PARA_SPARKS.md
  required_exit_classification: UX-READY
---

# Roadmap pós-6J — Workspace Principal e Visibilidade Jornada ↔ Projeto

## 1. Contexto

A trilha `17-B.5F.3C.6D–6J` está integralmente encerrada. Este roadmap não reabre aqueles gates e não cria novos domínios transacionais.

A reconciliação pós-6J confirmou duas lacunas de experiência apoiadas por contratos existentes:

1. completar a família canônica `FE-09.A.06 — Painel Principal`, fazendo a entrada padrão do módulo aplicar a preferência `workspace.primary_dashboard` já persistida e governada;
2. tornar suficientemente visível e operacional a relação entre Projeto Estratégico e Jornada sem duplicar entidades ou fontes de verdade.

A partir da versão 1.2.0, qualquer entrega com superfície de usuário neste roadmap está subordinada a:

- `MANIFESTO_UX_SPARKS.md`;
- `CHECKLIST_PRONTIDAO_UX_SPARKS.md`;
- `BENCHMARK_UX_SMARTKANVAS_PARA_SPARKS.md`;
- `GUARDRAIL_UX_BASILAR_6G_6H_JORNADA.md`.

Teste automatizado e build aprovados permanecem obrigatórios, porém nenhuma entrega visual pode ser formalmente fechada sem classificação `UX-READY`.

A partir da versão 1.3.0, nenhuma evolução visual da Jornada, Projeto ou superfícies dependentes pode avançar enquanto o subgate `PÓS-6J.IR-01 — Integridade e Reconciliação de Projeções` estiver aberto. Esse subgate não aumenta a contagem funcional deste roadmap: ele controla integridade, semântica, segurança e não regressão antes da continuação dos gates já existentes.

## 2. Sequência canônica

### FE-09.A.06-H — Painel Principal como landing governado do usuário

Esta entrega é continuação da família documental já existente `FE-09.A.06`; não constitui uma nova frente `FE-09.A`.

Objetivo: fazer a entrada padrão no módulo SK-PE respeitar o `workspace.primary_dashboard` elegível do usuário, preservando o fallback canônico e mantendo `workspace.favorites` como preferência separada.

Inclui:

- leitura da preferência pessoal já existente;
- aplicação somente na entrada padrão do módulo, sem sequestrar rotas explícitas;
- `my-work` e `executive` permanecendo na Visão Geral enquanto forem superfícies de `overview`;
- `portfolio` abrindo Iniciativas quando elegível;
- `governance` abrindo Governança quando elegível;
- fallback seguro conforme o contrato FE-09.A.06;
- manutenção de `workspace.favorites` como lista independente;
- sincronização dos atalhos do Meu Espaço de Trabalho com o roteamento governado do `SkpeWorkspace`.

Não inclui:

- novos tipos de dashboard;
- mudança de schema das preferências;
- transformar Favoritos em múltiplos painéis principais;
- composição futura de widgets de Agenda/Mensageria.

Evidência técnica materializada:

- commit `e97a946f08e7d959b1f9e0f09cfb183168bd4772` — `feat(skpe): apply primary dashboard on module entry`;
- testes web: `112/112 PASS`;
- build de produção: `PASS`;
- DEV sem nova migration; última migration permanece `20260829232922`;
- contratos reutilizados: `get_my_module_preference`, `set_my_module_preference`, `delete_my_module_preference`;
- hardening operacional posterior em `de6da85a5c6b4679fa0289189a955f6aa70bff15` — iniciativa como espaço de trabalho, cards métricos centralizados e redução de ações concorrentes.

Critério de saída funcional: ao entrar pela rota padrão do módulo, o usuário é direcionado uma única vez para o Painel Principal elegível; rotas explícitas continuam soberanas; fallback permanece determinístico e não há loop de navegação.

Critério de saída UX adicional: a entrada, a tela destino e os fluxos tocados devem alcançar `UX-READY` no checklist canônico, incluindo inspeção visual com dados reais.

Critério de integridade adicional: o fechamento `PASS/CLOSED` fica bloqueado enquanto `PÓS-6J.IR-01` estiver aberto.

**Status: IMPLEMENTED — validação UX final e Gate de Integridade pendentes antes de PASS/CLOSED.**

### PÓS-6J.IR-01 — Integridade e Reconciliação de Projeções

Natureza: subgate transversal de hardening e reconciliação. Não constitui novo gate funcional e não reabre `6D–6J`.

Objetivo: assegurar que read models, adapters e formatação de frontend preservem e distingam corretamente informação canônica, histórica, temporal e de responsabilidade antes de qualquer novo avanço visual.

#### Autoridades e camadas semânticas obrigatórias

A implementação e a validação devem distinguir, sem sobrescrita implícita:

1. **evidência histórica de origem** — Planilha, HTML, atas, registros formais, fotos e demais evidências válidas;
2. **horizonte institucional do Projeto Estratégico** — datas e contexto próprios de `skpe_projects`;
3. **baseline governada da Jornada** — versão aprovada em `skpe_journey_schedule_versions/items`, quando formalizada;
4. **plano vigente/rebaseline** — versão aprovada corrente, quando existente;
5. **forecast ativo** — projeção vigente sem substituir baseline/plano;
6. **execução real** — datas e estados efetivamente executados nos objetos canônicos;
7. **responsabilidade pessoal operacional** — pessoa/usuário resolvido por autoridade organizacional válida;
8. **responsabilidade institucional histórica/metodológica** — papel, órgão ou grupo registrado na evidência de origem, sem conversão automática para usuário individual.

Divergência entre essas camadas não é, isoladamente, não conformidade e não autoriza substituição de uma fonte por outra.

#### Evidências já confirmadas em 2026-09-02

- Projeto canônico COOTAQUARA: `PE-COOTAQUARA-2026` (`c4a93567-8ab3-4cb9-91ce-8421c3f305f1`).
- Horizonte do projeto preservado: início `2026-07-14` e término-alvo `2026-12-11`.
- `PEM-00` e `PEM-01` permanecem concluídas/aprovadas; `PEM-02` permanece em execução.
- `responsible_user_id` das Macrofases permanece persistido e resolve para Ricardo Rodrigues.
- Não existe atualmente versão em `skpe_journey_schedule_versions` para o projeto COOTAQUARA; portanto o estado temporal `unscheduled` representa ausência de baseline/plano governado por item e não pode ser traduzido semanticamente como inexistência de planejamento institucional do projeto.
- Imports históricos v17/v26 foram preservados como prévia/revisão governada, sem escrita definitiva/materialização automática; não devem ser convertidos em cronograma canônico por inferência.
- A função `get_skpe_journey_temporal_read_model(uuid,uuid,date)` permanece `SECURITY INVOKER` por hardening arquitetural deliberado.
- O nome do responsável pode desaparecer no read model temporal porque a função faz `LEFT JOIN public.profiles` sob RLS restritiva de perfil, embora o `responsible_user_id` esteja preservado.
- Ricardo Rodrigues já está sincronizado em `sparks_people` e possui vínculo ativo com a COOTAQUARA em `sparks_organization_people`, camada cuja leitura é governada por `can_view_sparks_people(organization_id)`.
- A função frontend `formatDate` em `SkpeCockpit.tsx` usa `new Date(value)` sobre valores SQL do tipo `date`; isso permite deslocamento de um dia em fusos negativos, como `2026-07-31` ser apresentado como `30/07/2026` em `America/Sao_Paulo`.
- A Jornada recebe esse mesmo formatter e atualmente traduz `unscheduled` como `Sem programação institucional` e ausência de datas de plano como `Não programado`, o que precisa ser reconciliado semanticamente antes de UX adicional.

#### Guardrails de correção

- **Não aplicar automaticamente** a migration proposta `restore_skpe_journey_temporal_formal_responsible_visibility`.
- **Não converter o read model temporal inteiro para `SECURITY DEFINER` apenas para contornar RLS de `profiles`.** Qualquer mudança de segurança exige solução mínima, guard explícito, `search_path` seguro, grants controlados e teste positivo/negativo de autorização.
- Preferir resolução de nome pela autoridade transversal de pessoas (`sparks_people` + `sparks_organization_people`) ou por projeção mínima especializada que respeite a autorização organizacional, evitando exposição ampla de `profiles`.
- Datas PostgreSQL `date` devem ser tratadas como **LocalDate**, sem conversão implícita para instante UTC. Formatação deve ser determinística e independente de timezone.
- Read models devem distinguir `dado ausente`, `dado não autorizado para projeção`, `baseline não formalizada`, `plano não aprovado` e `planejamento institucional inexistente`; esses estados não podem compartilhar silenciosamente o mesmo rótulo.
- Nenhum import histórico pode escrever ou sobrescrever autoridade canônica sem decisão/materialização governada explícita e rastreável.
- Nenhum campo projetado pode transformar falha de join/RLS em afirmação factual de inexistência do dado canônico.

#### Critérios de saída

O subgate só pode ser fechado quando todos os itens abaixo estiverem comprovados:

1. responsável persistido e nome projetado corretamente para usuários autorizados, sem ampliar indevidamente acesso a perfis;
2. testes negativos comprovando que usuário sem autorização não obtém nomes/dados de pessoas da organização;
3. datas `date` reproduzidas exatamente em `pt-BR` para `America/Sao_Paulo` e demais fusos relevantes, sem deslocamento de dia;
4. horizonte do projeto, baseline, plano vigente, forecast e execução real permanecem semanticamente distinguíveis;
5. ausência de `schedule_versions` não é apresentada como inexistência de planejamento institucional;
6. COOTAQUARA reconciliada contra banco e evidências históricas disponíveis, preservando provenance e sem materialização inferida;
7. testes de contrato/read model cobrindo RLS, fallback e provenance;
8. nenhuma migration de segurança aplicada antes da aprovação da arquitetura mínima;
9. testes/build permanecem PASS após futuras correções técnicas;
10. relatório de fechamento registra evidências, objetos alterados, não regressões e decisão explícita sobre a migration suspensa.

**Status: IN PROGRESS — bloqueia avanço visual e fechamento UX dos gates pós-6J.**

### PÓS-6J.02 — Visibilidade e wiring Projeto Estratégico ↔ Jornada

Este é um identificador interno deste roadmap. Não deve ser interpretado como continuação de uma família `FE-09.B` sem contrato canônico próprio.

Objetivo: tornar explícita para o usuário a relação entre o Projeto Estratégico e sua Jornada, reutilizando os contratos existentes e sem criar entidade concorrente.

Fundação já existente:

- `create_skpe_project_from_template`;
- `prepare_skpe_project`;
- `start_skpe_project_pem00`;
- `backfill_skpe_project_journey_from_template`;
- template publicado da Jornada;
- read models e projeções temporais do Projeto/Jornada.

Inclui:

- visibilidade clara do Projeto que materializa a Jornada;
- navegação contextual Projeto ↔ Jornada;
- identificação de template/estado quando útil ao usuário;
- reaproveitamento da hierarquia já materializada;
- correção apenas de wiring/UX comprovadamente faltante.

Não inclui:

- sincronização paralela;
- segunda tabela de Jornada;
- novo lifecycle;
- recriação automática de hierarquia já existente.

Critério de entrada adicional: `PÓS-6J.IR-01` deve estar `PASS/CLOSED` antes de qualquer nova alteração visual deste gate.

Critério de saída funcional: o usuário compreende e navega a relação Projeto ↔ Jornada sem duplicidade de fonte de verdade.

Critério de saída UX: a jornada deve deixar permanentemente perceptível onde o usuário está, o que já avançou, o que vem depois e como retornar ao Projeto; deve alcançar `UX-READY` antes de fechamento.

**Status: PLANNED — inicia somente após FE-09.A.06-H PASS/CLOSED e PÓS-6J.IR-01 PASS/CLOSED.**

## 3. Ordem congelada

A ordem funcional permanece:

`17-B.5F.3C.6J -> FE-09.A.06-H -> PÓS-6J.02`

A trava de integridade passa a ser:

`estado atual -> PÓS-6J.IR-01 -> retomada da validação UX de FE-09.A.06-H -> PÓS-6J.02`

Enquanto `FE-09.A.06-H` não estiver formalmente fechado, restam **2 gates funcionais** neste roadmap pós-6J. `PÓS-6J.IR-01` é subgate de hardening/reconciliação e não altera essa contagem.

O guardrail UX não aumenta a contagem de gates; ele qualifica o critério de saída dos gates existentes.

## 4. Regra de governança

- 6D–6J permanecem fechados;
- a família FE-09.A.06 existente é reutilizada e não renomeada;
- preferências existentes são reutilizadas, não remodeladas sem necessidade;
- Projeto e Jornada mantêm suas autoridades canônicas atuais;
- evidência histórica, horizonte de projeto, baseline, plano vigente, forecast e execução real são camadas distintas e rastreáveis;
- projeção nula por autorização/RLS não equivale a dado canônico inexistente;
- valores PostgreSQL `date` não podem sofrer conversão dependente de timezone no frontend;
- novas necessidades fora desta sequência devem ser propostas separadamente;
- nenhuma superfície nova ou alterada poderá ser declarada encerrada apenas por `tests/build PASS`;
- recorrência do mesmo defeito visual em telas diferentes deve ser tratada preferencialmente por componente/design system transversal;
- nenhuma migration de elevação de privilégio pode ser usada como correção de conveniência para falha de projeção.

**ROADMAP PÓS-6J — FE-09.A.06-H IMPLEMENTED / UX VALIDATION BLOCKED BY PÓS-6J.IR-01 — PÓS-6J.02 PLANNED — INTEGRITY + UX-READY REQUIRED.**