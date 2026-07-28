# Bloco 1.10B-0.1 — Qualidade do Payload 2.0.1

## Objetivo

Corrigir chaves externas duplicadas e impedir que linhas com deslocamento estrutural sejam enviadas ao staging.

## Arquivos para substituir

- `apps/web/src/modules/portability/parseCanonicalWorkbook.ts`
- `apps/web/src/modules/portability/CanonicalWorkbookImportPreview.tsx`

## Comportamento

- `strategic_identity` usa chave composta por elemento, versão proposta e texto.
- `client_validation` usa chave composta por código, artefato/tema e data.
- colisões remanescentes recebem sufixo determinístico baseado no fingerprint.
- linhas suspeitas de deslocamento são preservadas em `quarantine`, mas excluídas de `entities[].records`.
- o payload passa a usar schema `2.0.1`.
- nenhuma gravação no Supabase é realizada.

## Teste

```powershell
cd C:\DADOS\SPARKs\skpe-saas\apps\web
npm run build
npm run dev
```

Depois, gere novamente o payload usando a planilha v17.

Resultado esperado:

- 282 registros lidos;
- 280 registros válidos;
- 2 registros em quarentena;
- 0 problemas críticos;
- 2 ou mais correções automáticas de chaves;
- botão de download habilitado.
