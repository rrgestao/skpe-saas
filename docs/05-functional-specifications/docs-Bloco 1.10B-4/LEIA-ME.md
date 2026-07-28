# Bloco 1.10B-4 — Revisão de bloqueios, conflitos e prontidão

## Objetivo
Avaliar formalmente o lote já simulado antes de qualquer carga definitiva.

## Resultado esperado para o lote atual
- lote: `reviewed`;
- pendentes: `0`;
- bloqueados: `1`;
- conflitos: `6`, tratados como decisão canônica;
- prontidão: `blocked`;
- carga definitiva: não autorizada.

O bloqueio esperado é `version_control:v17`. A função apenas lê, classifica e registra a avaliação no metadado e no histórico de eventos. Ela não aplica registros nas tabelas estratégicas.

## Instalação
1. Execute a migration no Supabase SQL Editor.
2. Substitua integralmente `CanonicalImportStaging.tsx` e `CanonicalImportStaging.css`.
3. Execute `npm run build` e `npm run dev`.
4. Retome o lote e clique em **Avaliar prontidão para carga**.
