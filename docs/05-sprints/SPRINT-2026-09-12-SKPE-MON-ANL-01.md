---
id: sprint-2026-09-12-skpe-mon-anl-01
title: Sprint 2026-09-12 — SKPE-MON-ANL-01
status: active
owner: dev
language: pt-BR
---

# Sprint 2026-09-12 — SKPE-MON-ANL-01

## Base

- Capability: `SKPE-MON-ANL-01 — Painel / Monitoramento de Desempenho`.
- Branch: `sprint/2026-09-12-monitoramento-desempenho`.
- Base SHA: `429aa03b2a96aac59b487329c60349ebf4ec0f26`.
- Dependência: primeira fatia governada de `SKPE-MED-DES-01` concluída.
- Padrão inicial: `READ_ONLY_REUSE`.

## Achados de runtime

- `get_skpe_strategic_performance` existe e agrega Medição → Indicador → Objetivo → Tema → Visão;
- o `MonitoringSection` atual cobre execução operacional, não desempenho estratégico;
- `skpe_monitoring_packages`: 0 registros;
- `skpe_monitoring_cycles`: 0 registros;
- portanto desempenho estratégico real não pode ser sintetizado nem presumido.

## G1 — Read-only readiness e desempenho governado

Status: PASS

Implementação:
- `MonitoringSection` consulta `get_skpe_monitoring_package_readiness` pela Formulação do workspace;
- somente consulta `get_skpe_strategic_performance` quando existe `cycleId` real;
- ausência de pacote exibe `FE08_PACKAGE_MISSING` como bloqueio governado;
- ausência de ciclo não gera desempenho sintético;
- quando houver ciclo, o painel reutiliza progresso da Visão, Objetivos, Temas e política de agregação calculados no runtime.

Validação:
- teste de contrato: 2/2 PASS;
- suíte completa: 135/135 PASS;
- build: PASS;
- Supabase alterado: NÃO;
- migration/DDL: NÃO.

Próximo gate: decidir e materializar, sob autorização própria, o pacote/ciclo FE-08 necessário para produzir desempenho real no runtime.

## Gate transversal — Governança das sugestões da Fase 2

Status: PASS

Antes de avançar o monitoramento, foi formalizado o contrato transversal da Fase 2:
- aplicação analisa e sugere; ser humano delibera;
- ações canônicas: KEEP, ADJUST, REPLACE, ADD e REMOVE;
- KEEP é conclusão técnica válida, não ausência de análise;
- sugestão exige evidência, fontes, motivação e justificativa;
- benchmark exige comparabilidade e aplicabilidade explícitas;
- maturidade, alinhamento com a Visão e contribuição de valor são obrigatórios;
- decisão final exige rastreabilidade humana.

Contrato: `docs/03-methodology/CONTRATO_SUGESTOES_GOVERNADAS_FASE2.md`.
Supabase alterado: NÃO.

## G2A — Proposta governada de configuração FE-08

Status: PASS

Achados:
- `configure_skpe_monitoring_package` cria/atualiza o pacote, mas exige justificativa e Formulação editável;
- `transition_skpe_monitoring_package` preserva submissão e validação humana;
- `open_skpe_monitoring_cycle` exige Formulação aprovada e pacote FE-08 validado;
- runtime atual possui uma Formulação `draft` e nenhum KPI estratégico ativo;
- responsáveis do pacote exigem `owner_user_id`/`governance_owner_user_id`, sem default automático seguro.

Implementação:
- defaults reais do runtime são exibidos como proposta técnica, não como decisão;
- cada default apresenta motivação/justificativa operacional;
- responsáveis permanecem decisão humana obrigatória;
- materialização automática fica explicitamente bloqueada;
- nenhuma RPC de escrita é chamada por este gate.

Validação: 6/6 testes específicos PASS; suíte 146/146 PASS; typecheck PASS; build PASS; Supabase alterado: NÃO.

## G2B — Responsáveis elegíveis e configuração governada do pacote

Status: PASS

Implementação:
- pessoas elegíveis são resolvidas por `get_skpe_governance_people` + `sparks_people.profile_user_id`;
- apenas pessoas com identidade autenticável são oferecidas como responsáveis do FE-08;
- o formulário permite revisar os defaults técnicos e escolher Responsável pelo Monitoramento e Responsável pela Governança/RAE;
- justificativa auditável é obrigatória;
- a persistência usa exclusivamente `configure_skpe_monitoring_package`;
- após salvar, o pacote permanece `in_elaboration`;
- não há submissão, validação ou abertura automática de ciclo.

Validação:
- testes específicos G2B: 7/7 PASS;
- suíte completa: 147/147 PASS;
- typecheck: PASS;
- build: PASS;
- Supabase alterado pela execução do agente: NÃO.

Próximo gate: expor submissão e validação humana explícitas do pacote FE-08, preservando segregação de autoridade e mantendo abertura de ciclo bloqueada até Formulação aprovada + pacote validado.
