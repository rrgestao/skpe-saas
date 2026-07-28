# Especificação Funcional — Portal HTML Portátil

## Objetivo

Oferecer uma visão executiva offline, somente leitura, navegável e imprimível do Planejamento Estratégico de uma organização, preservando a segregação organizacional e a rastreabilidade da exportação.

## Requisitos implementados

- HTML único e autocontido;
- dados estruturados incorporados;
- navegação lateral por seções;
- pesquisa global;
- filtros locais nas tabelas;
- cards e linhas com hover e foco por teclado;
- impressão integral ou por seção;
- botão flutuante funcional de retorno ao topo;
- download do JSON incorporado;
- identidade da organização com logo quando disponível;
- registro auditável da geração no pacote de portabilidade;
- ausência de dependências externas;
- operação somente leitura.

## Regra de segurança

O portal é gerado exclusivamente a partir do documento estruturado retornado para o pacote e organização selecionados. Não realiza consultas posteriores ao Supabase e não tenta buscar projeto alternativo.
