# ADR-001 — Uso do Supabase Web no Desenvolvimento

## Status

Aprovado.

## Contexto

O ambiente local do Supabase exigiu recursos superiores aos disponíveis na estação de desenvolvimento.

## Decisão

Utilizar o projeto Supabase Web denominado skpe-saas-dev como ambiente de desenvolvimento do banco, autenticação e Storage.

## Regras

- As alterações do banco serão criadas por migrations SQL.
- As migrations serão mantidas no GitHub.
- O banco de produção não será utilizado para testes.
- Segredos não serão incluídos no repositório.
- O projeto local permanecerá vinculado ao Supabase Web pela CLI.

## Consequências

- Menor uso de memória local.
- Dependência de conexão com a internet.
- Necessidade de maior cuidado antes de executar migrations remotas.
