---
id: DEV-03
title: Padrão de Solicitação de Implementação
version: 1.0.0
status: active
domain: platform-governance
owner: SPARKs Platform
created_at: 2026-08-17
updated_at: 2026-08-17
source: Gate 17-Q
dependencies:
  - docs/00-governanca/AGENT_EXECUTION_GUARDRAILS.md
---

# DEV-03 — Padrão de Solicitação de Implementação

## 1. Objetivo

Padronizar solicitações futuras de implementação, código, scripts ou prompts de execução para a Plataforma SPARKs.

Toda demanda deve partir das fontes canônicas e do estado real do Git.

## 2. Regra obrigatória

Toda solicitação de implementação deve conter explicitamente:

> Leia obrigatoriamente e cumpra:
>
> `docs/00-governanca/AGENT_EXECUTION_GUARDRAILS.md`

O guardrail vigente não deve ser copiado integralmente em cada solicitação.

Ele deve ser referenciado como fonte normativa.

## 3. Modelo mínimo

```text
Leia obrigatoriamente e cumpra:

docs/00-governanca/AGENT_EXECUTION_GUARDRAILS.md

Consulte também os documentos canônicos e requisitos aplicáveis à demanda.

Implemente:

[DEMANDA]

Antes de alterar código:

1. inspecione o estado atual do Git;
2. identifique alterações preexistentes;
3. identifique as fontes canônicas aplicáveis;
4. compare documentação e implementação atual;
5. determine o impacto;
6. determine a mudança mínima necessária.

Preserve integralmente alterações de outras frentes.

Não faça mudanças fora do escopo.

Quando a execução for solicitada via PowerShell:

gere um PS1 completo e pronto para execução quando isso for tecnicamente seguro e adequado.

Não solicite alterações manuais quando elas puderem ser realizadas de forma segura e determinística pelo script.

Não execute automaticamente operações destrutivas de Git.

Ao final, informe:

- arquivos alterados;
- validações executadas;
- testes;
- divergências encontradas;
- riscos;
- estado do Git;
- documentação afetada;
- próximo passo recomendado.
```

## 4. Definition of Done proporcional ao risco

Quando aplicável:

### Código

- lint;
- testes;
- build.

### Banco

- migration governada;
- integridade;
- RLS;
- policies;
- grants;
- testes positivos e negativos.

### UX

- simplicidade;
- redução de etapas desnecessárias;
- progressive disclosure;
- feedback;
- prevenção de perda de dados.

### Acessibilidade

- teclado;
- foco;
- labels;
- semântica;
- contraste;
- independência de cor;
- operação sem mouse quando pertinente.

### Responsividade

- desktop;
- tablet;
- mobile.

### Arquitetura

- domínio separado da apresentação;
- acesso a dados governado;
- ausência de duplicidade conceitual;
- ausência de drift semântico.

### Compatibilidade

- greenfield;
- brownfield;
- regressão.

### Documentação

Atualizar ADR, requisito, contrato ou outra fonte canônica quando a decisão implementada alterar o comportamento institucional da Plataforma.

## 5. Encerramento obrigatório

Nenhuma solicitação deve ser encerrada sem evidência do estado final e dos riscos remanescentes.
