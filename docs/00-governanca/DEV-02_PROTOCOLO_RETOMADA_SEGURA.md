---
id: DEV-02
title: Protocolo de Retomada Segura
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

# DEV-02 — Protocolo de Retomada Segura

## 1. Objetivo

Retomar qualquer frente de desenvolvimento sem presumir que instruções anteriores, documentação histórica ou lembranças de contexto correspondam integralmente ao estado atual da aplicação.

## 2. Regra central

Nenhum código deve ser alterado na inspeção inicial.

A retomada deve primeiro confrontar:

**Git → fontes canônicas → implementação atual → divergências → impacto → próxima mudança mínima.**

## 3. Validação inicial obrigatória

Antes de implementar, retornar:

`RETOMADA — CONTEXTO VALIDADO: SIM`

com:

1. branch;
2. HEAD;
3. `git status -sb`;
4. alterações locais identificadas;
5. documentos canônicos consultados;
6. estado atual da frente;
7. arquivos potencialmente envolvidos;
8. divergências encontradas;
9. riscos;
10. próximo passo mínimo recomendado.

## 4. Consulta canônica

Consultar os hubs, ADRs, requisitos, contratos e critérios de aceite aplicáveis.

No SK-PE, a frente de experiência deve considerar, quando pertinente:

`docs/03-methodology/REQ-SKPE-FE-010_EXPERIENCIA_APLICACIONAL_E_OPERACIONALIZACAO_FORMULACAO.md`

e os contratos FE-09A vigentes indicados pela documentação canônica.

## 5. Experiência, usabilidade e acessibilidade

Para retomadas que envolvam experiência aplicacional, avaliar o estado atual de:

- Application Shell;
- Cockpit;
- Workspace;
- responsividade;
- navegação;
- painéis;
- artefatos metodológicos;
- usabilidade;
- acessibilidade;
- experiência operacional;
- redução de cliques;
- progressive disclosure;
- comportamento responsivo.

Uma lista histórica de arquivos é apenas referência e nunca autorização automática para alterar todos eles.

Modificar somente arquivos efetivamente necessários à demanda atual.

## 6. Divergências

Se a implementação atual divergir da documentação:

- registrar a divergência;
- identificar a fonte vigente;
- não corrigir silenciosamente;
- propor a menor ação segura.

## 7. Encerramento da retomada

A retomada termina quando existe contexto suficiente para autorizar uma implementação mínima, rastreável e com critérios de aceite explícitos.
