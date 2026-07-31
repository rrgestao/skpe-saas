# Guia de Implementação Controlada — FE-09.A

## 1. Pré-condições

1. repositório `rrgestao/skpe-saas`;
2. branch `feature/formulacao-estrategica-operacional`;
3. HEAD `0fd801bfe076c07fd6f06ac2aea94a8aa094115f`;
4. working tree limpo;
5. branch remota sincronizada;
6. nenhum merge;
7. Node e npm funcionais.

## 2. Instalação do pacote arquitetural

No PowerShell, a partir da raiz do repositório:

```powershell
powershell -ExecutionPolicy Bypass -File .\CAMINHO_DO_PACOTE\scripts\fe09a\instalar_fe09a_no_repositorio.ps1 -RepoPath .
```

O script:

- confirma branch;
- confirma commit;
- exige working tree limpo;
- copia somente a lista branca;
- gera manifesto;
- não faz staging;
- não faz commit;
- não faz push;
- não faz merge.

## 3. Revisão

Revisar:

```powershell
git --no-pager status --short
git --no-pager diff -- docs/03-methodology scripts/fe09a
git --no-pager diff --check
```

## 4. Validação e staging

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\fe09a\validar_fe09a_planejamento.ps1 -RepoPath .
```

## 5. Commit

Após validar o conteúdo:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\fe09a\commit_e_push_fe09a.ps1 -RepoPath . -ArquiteturaValidada
```

Para publicar:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\fe09a\commit_e_push_fe09a.ps1 -RepoPath . -ArquiteturaValidada -Push
```

## 6. Próxima etapa

Após o pacote arquitetural estar versionado:

```text
FE-09.A.01 — Roteamento, Workspace e Contexto Explícito
```

Antes de codificar:

- inspecionar o catálogo de permissões;
- definir dependências;
- confirmar estratégia de testes;
- preparar lista branca específica da implementação.

## 7. Proibições

- não criar migration sem lacuna comprovada;
- não editar `develop` ou `main`;
- não realizar merge;
- não substituir integralmente o cockpit;
- não remover contratos legados antes da transição;
- não introduzir dados específicos da COOTAQUARA no código.
