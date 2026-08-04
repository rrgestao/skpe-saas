# FE-09.A.02.2 - Contrato da Fundacao Responsiva e Tipografica

## Decisao

A responsividade e a legibilidade passam a ser requisitos transversais da Plataforma SPARKs, aplicados por `apps/web/src/responsive.css`, sem alterar regras de negocio.

## Regras

1. O conteudo principal utiliza toda a largura disponivel.
2. Containers flexiveis usam `min-width: 0`.
3. Conteudo essencial nao fica abaixo de 0.875rem.
4. Cabecalhos usam escala responsiva com `clamp()`.
5. Controles possuem altura minima de 44px.
6. Tabelas largas usam rolagem horizontal sem reduzir excessivamente a fonte.
7. Abaixo de 900px, o shell opera em uma coluna.
8. Abaixo de 680px, cabecalhos e barras de ferramentas empilham controles.
9. Icones SVG de busca e acoes permanecem limitados a aproximadamente 18px, evitando ampliacao indevida por regras globais.
