# Bloco 1.10B-3.1 — Listagem, retomada e simulação autenticada

Este pacote corrige a lacuna que impedia reabrir um lote de staging depois de recarregar a página.

## Instalação

1. Execute no Supabase Web / SQL Editor:
   `supabase/migrations/20260728203000_add_skpe_import_batch_recovery.sql`
2. Substitua integralmente, no projeto local:
   - `apps/web/src/modules/portability/CanonicalImportStaging.tsx`
   - `apps/web/src/modules/portability/CanonicalImportStaging.css`
3. No terminal:
   - `cd C:\DADOS\SPARKs\skpe-saas\apps\web`
   - `npm run build`
   - `npm run dev`
4. Atualize o navegador com `Ctrl + F5`.

## Uso esperado

Após selecionar COOTAQUARA e o projeto, será exibida a seção **Lotes de importação existentes**. Localize o lote:

`c6c255e6-46d1-4072-9ebd-e0640345c98b`

Clique em **Retomar lote** e, no resumo carregado, clique em **Executar simulação comparativa**.

A execução ocorre pela sessão autenticada da aplicação, preservando `can_manage_skpe_journey(...)`.

## Proteções preservadas

- nenhuma carga nas tabelas estratégicas definitivas;
- autorização por organização;
- lote existente reutilizado, sem duplicação;
- cancelamento auditável;
- persistência do lote selecionado no navegador;
- recuperação automática do último lote aberto para o projeto.
