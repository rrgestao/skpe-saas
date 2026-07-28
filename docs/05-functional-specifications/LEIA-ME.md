# SPARKs PE — Bloco 1.10B-2

## Finalidade

Conectar a interface de Portabilidade ao staging criado no Bloco 1.10B-1.

## Pré-requisito obrigatório

A migration `20260728183000_create_skpe_canonical_import_staging.sql` deve estar aplicada e as três funções RPC devem existir.

## Arquivos para copiar

Copie integralmente para `apps/web/src/modules/portability/`:

- `CanonicalImportStaging.tsx`
- `CanonicalImportStaging.css`
- `PortabilityAdmin.tsx`

O `PortabilityAdmin.tsx` incluído foi derivado do pacote 1.10B-0. Caso o arquivo local tenha recebido alterações posteriores, preserve-as e adicione apenas o import e o componente indicados em `PATCH_MANUAL.md`.

## Teste

1. Execute `npm run build`.
2. Execute `npm run dev`.
3. Abra Administração da Plataforma > Importação, Exportação e Portabilidade.
4. Selecione COOTAQUARA e o projeto.
5. Selecione o payload JSON 2.0.1.
6. Clique em `Criar lote em staging`.
7. Confira o resumo: 281 recebidos, 280 válidos, 0 em quarentena dentro de entities, 1 bloqueado semântico e 6 conflitos. O registro originalmente em quarentena fica fora da coleção principal do payload 2.0.1 e, por isso, não entra automaticamente no staging atual.

## Segurança

Este bloco não aplica registros às tabelas estratégicas definitivas.
