---
id: ADR-PLAT-MEAS-001
title: Fundação Transversal de Medidas e Desempenho
status: accepted
owner: product-platform
language: pt-BR
effective_date: 2026-09-16
---

# ADR-PLAT-MEAS-001 — Fundação Transversal de Medidas e Desempenho

## Contexto

A capability `SKPE-MED-DES-01` nasceu e amadureceu no product space SK-PE, com contratos físicos e funcionais já implementados para indicadores, metas, benchmarks, medições, desempenho, evidências, histórico e monitoramento.

Entre 11 e 13/09/2026 houve evolução relevante do acompanhamento e controle das Iniciativas, incluindo leitura de desempenho, coleta governada, check-ins de KR e Iniciativa, RAE, decisões, aprendizado, ratificação, snapshots e reabertura controlada.

A Plataforma SPARKs também recebeu o pacote `SPARKs_PE_Base_KPIs_BMK_Ramos_v1_0`, com catálogo candidato de KPIs, ramos, benchmarks e fontes. Esse pacote é insumo de curadoria e não substitui o domínio/runtime já existente.

## Decisão

Medidas e Desempenho passa a ser formalmente uma capability transversal da Plataforma SPARKs.

`SKPE-MED-DES-01` permanece como origem histórica e especialização metodológica do SK-PE, mas não será o owner técnico definitivo da capability transversal.

A evolução seguirá a estratégia `Facade -> Convergence -> eventual Storage Evolution`.

Não haverá big-bang rename. As tabelas `skpe_*` existentes serão preservadas nesta etapa e continuarão válidas até que uma convergência futura seja especificada, migrada e validada por gate próprio.

A definição canônica de métrica/KPI deve ser separada de sua adoção e binding organizacional/contextual. Uma organização poderá adotar e contextualizar um KPI sem clonar ou alterar silenciosamente a definição global.

`Benchmark Comparability Assessment` é autorizado como conceito canônico. A existência de um benchmark não implica comparabilidade e benchmark comparável não se transforma automaticamente em meta.

A avaliação de desempenho deverá evoluir para regras e assessments versionáveis, preservando os contratos atuais de `automatic_performance`, `manual_performance_override` e `effective_performance` durante a transição.

## Invariantes

- `Medição != Meta != Benchmark != Desempenho`.
- Ausência de medição não é zero.
- Histórico validado não deve ser sobrescrito silenciosamente.
- Meta é contextual e temporal; não pertence ao catálogo global.
- Benchmark exige fonte, período, contexto e avaliação de comparabilidade.
- Check-in gerencial de KR/Iniciativa não é automaticamente uma medição formal de KPI.
- Agregações de desempenho precisam de regra explícita e explicável; não usar médias ingênuas.
- IDs e versões existentes devem ser preservados.
- Outros produtos SPARKs devem reutilizar a capability transversal, evitando motores locais paralelos.

## Catálogo KPI/BMK v1.0

A importação da base v1.0 fica bloqueada até a reconciliação semântica com o catálogo existente.

O runtime contém 60 linhas em `skpe_indicator_reference_catalog`, correspondentes a 46 códigos/identidades atuais e 14 versões históricas. A reconciliação será, portanto, `46 identidades vigentes + histórico preservado` versus `78 candidatos v1.0`.

Quando houver equivalência ou alias, a identidade canônica existente tem precedência. O ID do pacote deve ser preservado como referência de origem/alias quando tecnicamente aplicável. Alterações metodológicas relevantes deverão produzir versão, não mutação destrutiva do histórico.

Classificações admitidas: `SAME`, `ALIAS`, `SPECIALIZATION`, `DERIVED`, `DIFFERENT_FORMULA`, `CONTEXTUAL_VARIANT`, `TRUE_DUPLICATE`, `NEEDS_HUMAN_DECISION`.

## Baseline de não regressão

Os contratos amadurecidos entre 11 e 13/09/2026 para Medidas, Monitoramento e Iniciativas constituem baseline obrigatório de não regressão, especialmente ciclo real, validação de medição, check-ins, readiness, RAE, decisões, aprendizado, snapshot e reabertura/supersessão.

## Restrições deste gate

`STRUCTURAL_MIGRATION_AUTHORIZED=NO`

`CATALOG_IMPORT_AUTHORIZED=NO`

`SKPE_TABLE_RENAME_AUTHORIZED=NO`

A próxima etapa autorizada é a formalização canônica e a reconciliação do catálogo antes de qualquer migration estrutural ou carga de dados.
