---
id: skpe-corporate-mirror
title: Mirror governado do Product Space Corporate do SK-PE
domain: products
type: mirror-manifest
status: active
owner: dev
canonicality: mirror
canonical: false
language: pt-BR
---

# Mirror governado — SK-PE Corporate

Esta árvore mantém uma cópia de referência do Product Space canônico do SK-PE publicado em `br-robson/projetos`.

## Autoridade

- Fonte canônica: `br-robson/projetos`.
- Branch de origem: `main`.
- Path de origem: `docs/products/sk-pe/`.
- Source SHA do mirror: `35583cc835cba6c71ed0c0f2d7cd4a1412b6fae6`.
- Repositório executável local: `sparkooptech/skpe-saas`.
- Path do mirror: `docs/corporate/sk-pe/source/`.

`CORPORATE_AUTHORITY=YES`
`LOCAL_MIRROR_AUTHORITY=NO`
`LOCAL_MIRROR_EDIT_AS_SOURCE=PROHIBITED`
`EXTERNAL_CHANGE_AUTO_ADOPTION=PROHIBITED`
`RRGESTAO_PRODUCT_AUTHORITY=NO`

## Regra de consentimento e alerta

Qualquer mudança observada em GitHub fora da linha DEV aprovada — especialmente em `rrgestao/skpe-saas` — que possa alterar direção de produto, regra de negócio, UX, arquitetura funcional, prioridade, lifecycle, semântica ou roadmap deve ser tratada como proposta externa até decisão humana explícita.

Fluxo obrigatório: `ALERTA -> COMPARACAO -> IMPACTO -> RECOMENDACAO -> DECISAO ROBSON -> INCORPORACAO OU REJEICAO`.

Nenhum agente deve promover automaticamente mudança encontrada em `rrgestao/skpe-saas`, no Corporate ou em outra branch/repositório para a linha canônica executável.

## Regra de uso

O mirror serve para leitura, comparação, testes documentais e reconciliação Product ↔ DEV.

Alterações de produto, prioridade, regra de negócio, capability ou status canônico devem ser promovidas no repositório Corporate e depois refletidas neste mirror por atualização controlada.

O mirror não autoriza:

- editar uma regra Corporate somente no `skpe-saas`;
- declarar `DONE` com base apenas em implementação;
- transformar baseline histórica em estado corrente sem nova reconciliação;
- substituir o roadmap operacional DEV pelo roadmap mestre Product.

## Conteúdo espelhado

A pasta `source/` contém os 14 arquivos existentes no Product Space Corporate no Source SHA informado, preservados sem alteração local.

A verificação de integridade executada em 13/09/2026 resultou em `SOURCE_COUNT=14`, `MIRROR_COUNT=14`, `DIFF_COUNT=0`.

Ver também:

- `SOURCE-SHA256.txt` — hashes do mirror;
- `RECONCILIATION-2026-09-13.md` — matriz Corporate × DEV e recomendações.
