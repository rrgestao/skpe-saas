# Plataforma SPARKs — Acesso hierárquico e catálogo oficial CNAE

## Escopo desta etapa

Esta etapa implanta somente a fundação de banco e autorização:

1. leitura de organizações subordinadas por administradores de organizações superiores;
2. distinção entre acesso direto, hierárquico, somente leitura e SUPER-ADMIN;
3. catálogo mestre versionado de CNAE;
4. associação oficial organização x CNAE;
5. marcação dos CNAEs legados como pendentes de revisão;
6. auditoria das alterações de CNAE.

A interface ainda não é alterada nesta etapa.

## Ordem de execução

1. Criar e publicar a branch `feature/acesso-hierarquico-cnae-oficial`.
2. Copiar a estrutura deste pacote para a raiz do repositório.
3. Executar a migration `20260729033000_add_hierarchical_read_access_and_cnae_catalog.sql` no SQL Editor do Supabase Web.
4. Executar `supabase/verification/verificar-hierarquia-cnae.sql`.
5. Confirmar que o catálogo existe com quantidade zero antes do seed e que os CNAEs antigos aparecem como legados para revisão.
6. Baixar o Excel oficial “CNAE 2.3 Subclasses — Estrutura Detalhada” no portal IBGE/CONCLA.
7. Na pasta `apps/web`, gerar o seed:

```powershell
node .\scripts\gerar-seed-cnae-oficial.mjs "C:\CAMINHO\CNAE_Subclasses_2_3_Estrutura_Detalhada.xlsx" "C:\DADOS\SPARKs\skpe-saas\supabase\migrations\20260729040000_seed_cnae_subclasses_2_3.sql"
```

8. Conferir a quantidade informada pelo gerador antes de executar o seed no Supabase Web.
9. Executar o seed e repetir o SQL de verificação.

## Controles

- Não executar o seed antes da migration de fundação.
- Não alterar manualmente os CNAEs atuais para ocultar a origem do erro.
- Não fazer commit antes de validar a migration e o seed.
- CNAEs legados permanecem preservados, mas são marcados como `needs_review`.
