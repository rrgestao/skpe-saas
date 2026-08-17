---
id: DEV-01
title: Atualização Segura do Repositório
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

# DEV-01 — Atualização Segura do Repositório

## 1. Objetivo

Atualizar um ambiente local da Plataforma SPARKs antes de qualquer nova implementação, preservando alterações legítimas e garantindo alinhamento com o repositório remoto.

## 2. Princípio

Não utilizar SHA histórico fixo como verdade permanente.

O executor deve validar a referência atual do branch de trabalho no momento da execução.

No contexto atual do SK-PE, a branch canônica é:

`feature/formulacao-estrategica-operacional`

## 3. Sequência obrigatória

Antes de alterar qualquer arquivo:

1. localizar o repositório correto;
2. executar `git status -sb`;
3. identificar a branch atual;
4. executar `git fetch origin`;
5. obter HEAD local;
6. obter HEAD de `origin/<branch>`;
7. obter a referência remota, quando disponível;
8. classificar o estado como sincronizado, ahead, behind ou divergente;
9. listar alterações locais e arquivos não rastreados.

## 4. Estados permitidos

### Sincronizado

Local, `origin` e remoto apontam para o mesmo commit.

A implementação pode prosseguir, desde que o working tree seja compreendido.

### Local ahead

O local contém commits ainda não publicados.

Não sobrescrever nem atualizar automaticamente. Avaliar os commits antes de prosseguir.

### Local behind

Somente permitir atualização por fast-forward quando o working tree estiver seguro e a ancestralidade for comprovada.

### Divergente

Bloquear escrita até que a divergência seja compreendida e resolvida de forma governada.

## 5. Operações proibidas automaticamente

Não executar automaticamente:

- `git reset --hard`;
- `git clean -fd`;
- force push;
- merge não analisado;
- descarte de mudanças;
- `git add .` em repositórios com arquivos de outras frentes.

## 6. Evidência mínima

Ao final da atualização, registrar:

- repositório;
- branch;
- HEAD local;
- HEAD de `origin`;
- referência remota;
- `git status -sb`;
- ação realizada;
- divergências e riscos encontrados.

## 7. Resultado esperado

A atualização é considerada segura quando o executor consegue demonstrar que o estado final é conhecido, reproduzível e não descartou trabalho preexistente.
