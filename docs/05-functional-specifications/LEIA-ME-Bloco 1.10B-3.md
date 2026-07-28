# SPARKs PE — Bloco 1.10B-3

## Finalidade

Executar uma simulação comparativa segura do lote já existente no staging.

A comparação usa registros canônicos de lotes anteriores do mesmo projeto e classifica cada registro como:

- `new`: chave ainda não existente;
- `update`: chave existente com fingerprint diferente;
- `unchanged`: chave e fingerprint iguais;
- `blocked`, `quarantined` ou `invalid`: preservados como impedimentos.

## Limite desta etapa

A simulação é **entre lotes canônicos**. Ela ainda não compara os 281 registros com todas as tabelas estratégicas definitivas, pois o inventário completo dessas tabelas não foi fornecido. Nenhuma carga definitiva é executada.

## Instalação

1. Execute a migration `20260728190000_add_skpe_import_comparative_simulation.sql` no SQL Editor do Supabase.
2. Substitua integralmente `CanonicalImportStaging.tsx` e `CanonicalImportStaging.css`.
3. Execute `npm run build` e `npm run dev`.
4. Reabra o lote e clique em **Executar simulação comparativa**.

## Resultado esperado no primeiro lote

Como não há lote canônico anterior, os registros aptos deverão ser classificados predominantemente como `new`. O registro `version_control:v17` permanece bloqueado.

## Correção UX incorporada

O botão **Atualizar resumo** agora possui cursor, hover, estado `Atualizando...`, bloqueio temporário e mensagem de sucesso.
