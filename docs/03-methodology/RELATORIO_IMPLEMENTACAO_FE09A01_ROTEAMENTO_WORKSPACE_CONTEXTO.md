# Relatório de Implementação — FE-09.A.01

## 1. Identificação

- **Etapa:** FE-09.A.01 — Roteamento, Workspace e Contexto Explícito
- **Branch:** $ExpectedBranch
- **Commit-base:** $ExpectedBaseCommit
- **Dependência adicionada:**
eact-router-dom@7.18.1
- **Banco de dados:** sem migration

## 2. Objetivo

Introduzir uma fundação de navegação por URL e um contexto transversal do workspace SK-PE sem substituir o cockpit existente e sem alterar os contratos de banco.

## 3. Entregas

- BrowserRouter no ponto de entrada;
- catálogo tipado de rotas;
- interpretação de rotas de plataforma, organização, módulo e SK-PE;
- sincronização entre URL e estados existentes de App.tsx;
- suporte a voltar, avançar e atualizar o navegador;
- SkpeWorkspaceProvider;
- adaptador SkpeWorkspace preservando SkpeCockpit;
- rotas canônicas preparadas para Projeto e Formulação;
- validação automatizada, lista branca e manifesto SHA-256.

## 4. Delimitação

Esta entrega não cria ainda os seletores visuais de Projeto e Formulação. As rotas canônicas já aceitam esses identificadores, mas as telas legadas continuam operando em modo de compatibilidade até a próxima evolução controlada.

## 5. Segurança e integridade

- nenhuma escrita direta no banco;
- nenhuma migration;
- nenhuma mudança de RLS;
- nenhuma remoção de contratos legados;
- nenhum merge automático;
- commit e push apenas mediante parâmetros explícitos.

## 6. Critérios de aceite

-
pm run lint aprovado;
-
pm run build aprovado;
- git diff --check aprovado;
- login e recuperação de senha preservados;
- seleção de organização preservada;
- administração global preservada;
- administração organizacional preservada;
- abertura do SK-PE preservada;
- URL atualizada ao navegar;
- retorno pelo navegador restaura o estado correspondente;
- refresh de rota conhecida restaura organização e módulo;
- rota inválida retorna à entrada de forma controlada.
