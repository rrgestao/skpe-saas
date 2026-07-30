---
id: adr-plat-biz-001-dominio-compartilhado-arquitetura-negocios-pe-pn
title: Domínio Compartilhado de Arquitetura de Negócios entre SK-PE e SK-PN
domain: platform-architecture
type: architecture-decision-record
status: approved
canonicality: canonical
canonical: true
criticality: high
parent: plataforma-sparks
related:
  - req-skpe-fe-001-arquitetura-canonica-formulacao-estrategica
  - sk-pe
  - sk-pn
tags:
  - arquitetura-de-negocios
  - planejamento-estrategico
  - plano-de-negocios
  - vpc
  - bmc
  - cadeia-de-valor
idioma: pt-BR
codificacao: UTF-8
language: pt-BR
encoding: UTF-8
semantic_layer: architecture-decision
created: 2026-07-30
updated: 2026-07-30
---

# ADR-PLAT-BIZ-001 — Domínio Compartilhado de Arquitetura de Negócios

## Decisão

VPC, BMC, Cadeia de Valor e demais artefatos de negócio serão objetos canônicos e compartilhados da Plataforma SPARKs. Não serão duplicados em tabelas concorrentes do SK-PE e do SK-PN.

O SK-PE será autossuficiente para criar esses artefatos no nível essencial necessário à Formulação Estratégica, mesmo quando a organização não possuir licença, contrato ou serviço do SK-PN.

O SK-PN, quando ativado, utilizará os mesmos objetos e versões, aprofundando-os conforme as melhores práticas de Plano de Negócios, Business Model Canvas, Value Proposition Canvas e demais métodos Canvas aplicáveis.

## Regras arquiteturais

1. A ausência do SK-PN nunca bloqueia o desenvolvimento ou a aprovação do SK-PE.
2. O SK-PE pode criar a Fundamentação do Negócio, VPC, BMC e Cadeia de Valor em nível essencial.
3. O SK-PN não reinicia nem copia esses conteúdos: ele evolui novas versões do mesmo artefato compartilhado.
4. Cada artefato registra organização, origem, módulo, serviço, metodologia, versão, maturidade, completude, validação e publicação.
5. Formulações Estratégicas aprovadas preservam a versão exata e um snapshot dos insumos utilizados.
6. Versões posteriores produzidas no SK-PN não alteram retroativamente uma Formulação Estratégica aprovada.
7. O sistema sinaliza oportunidades de aprofundamento no SK-PN como recomendação, não como bloqueio de licença.
8. O fluxo é bidirecional: o SK-PE alimenta o SK-PN e novos conhecimentos do SK-PN podem subsidiar revisões futuras do SK-PE.

## Níveis de maturidade

- `essential`: suficiente para sustentar a Formulação Estratégica;
- `structured`: relações e conteúdos intermediários estabelecidos;
- `complete`: atende integralmente ao método do artefato;
- `validated`: analisado e validado pela organização;
- `published`: integrado formalmente a uma versão aprovada de PE ou PN.

## Consequências

A Plataforma passa a possuir um domínio compartilhado de Arquitetura de Negócios. As interfaces e operações especializadas continuam pertencendo aos módulos contratados, mas o dado canônico permanece interoperável e versionado.
