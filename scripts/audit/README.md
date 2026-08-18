# Pipeline Canonico de Evidencias Tecnicas SPARKs

## Contexto

Este mecanismo integra a governanca definida em:

- SK-PE-CONT-01 - Continuidade Segura e Fechamento Controlado do SPARKs PE
- GATE-17-B.3C - Pipeline Canonico de Evidencias Tecnicas

## Objetivo

Materializar evidencias tecnicas de forma:

- reproduzivel;
- rastreavel;
- verificavel;
- vinculada a commit Git;
- vinculada ao projeto Supabase;
- independente da renderizacao de respostas do MCP ou da interface do ChatGPT.

## Fonte primaria

Para Advisors e verificacoes de banco, a fonte primaria de evidencia do
pipeline e a Supabase CLI executada contra o projeto remoto vinculado.

O MCP Supabase continua sendo uma fonte operacional e complementar.

## Regras obrigatorias

1. Ausencia de evidencia nunca equivale a PASS.
2. Arquivo vazio nunca equivale a zero findings.
3. JSON ilegivel nunca equivale a PASS.
4. Falha de comando nunca equivale a zero findings.
5. Integridade do pacote nao equivale a aprovacao do gate.
6. Findings devem ser classificados separadamente.
7. O pacote deve registrar projeto, branch, commit e versao da CLI.
8. O worktree deve estar limpo antes da coleta.
9. Local, origin e remoto devem estar sincronizados antes da coleta.
10. O project ref deve ser validado antes da coleta.

## Estrutura das evidencias

Os pacotes sao gerados em:

    _audit/supabase/<gate>/<timestamp>/

Exemplo:

    _audit/
      supabase/
        17-B.3B/
          20260818T000000Z/
            security.json
            security.stderr.txt
            performance.json
            performance.stderr.txt
            db-lint.txt
            db-lint.stderr.txt
            migrations.txt
            migrations.stderr.txt
            git-state.json
            environment.json
            summary.md
            manifest.json

## Seguranca

O diretorio `_audit/` e ignorado pelo Git por padrao porque pode conter
informacoes tecnicas ou findings que nao devem ser publicados
automaticamente no repositorio.

A promocao de qualquer evidencia para armazenamento permanente deve ocorrer
somente depois de classificacao e decisao explicita de governanca.

## Fluxo

Coleta:

    powershell.exe -NoProfile -ExecutionPolicy Bypass `
      -File .\scripts\audit\Invoke-SparksSupabaseEvidence.ps1

Validacao:

    powershell.exe -NoProfile -ExecutionPolicy Bypass `
      -File .\scripts\audit\Test-SparksSupabaseEvidence.ps1 `
      -EvidencePath "<diretorio-gerado>"

Somente depois da validacao devem ser classificados os findings de seguranca,
performance, lint e migrations e tomada a decisao formal do gate.
