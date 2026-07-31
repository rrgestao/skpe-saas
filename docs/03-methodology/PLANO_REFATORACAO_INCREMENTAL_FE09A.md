# Plano de Refatoração Incremental — FE-09.A

## Onda A0 — Preparação

- versionar requisitos;
- confirmar branch e commit;
- confirmar working tree limpo;
- inventariar contratos;
- definir dependências frontend;
- definir estratégia de testes.

## Onda A1 — Roteamento e shell

- introduzir roteamento;
- preservar login;
- preservar seleção organizacional;
- criar layout do workspace;
- criar rotas de transição para telas existentes;
- validar back/forward e refresh.

## Onda A2 — Contexto explícito

- seletor de projeto;
- seletor de Formulação;
- contexto de versão;
- contexto de ciclo;
- validação de coerência;
- persistência segura da última seleção.

## Onda A3 — Capacidades

- consulta de permissões efetivas;
- contexto de capacidades;
- guards de rota;
- guards de ação;
- modo somente leitura;
- testes por perfil.

## Onda A4 — Componentes transversais

- cabeçalho;
- prontidão;
- transição;
- motivo;
- auditoria;
- estados;
- proteção contra perda;
- notificações básicas.

## Onda A5 — Meu Espaço de Trabalho

- Painel Principal;
- Painéis Disponíveis;
- pendências;
- favoritos;
- atalhos;
- notificações;
- indicadores visuais iniciais.

## Onda A6 — Extração inicial do cockpit

- mover Jornada para feature;
- mover Artefatos;
- manter contratos;
- reduzir responsabilidades do `SkpeCockpit`;
- não alterar comportamento funcional.

## Onda A7 — Hardening

- build;
- lint;
- testes;
- acessibilidade;
- responsividade;
- performance;
- documentação;
- lista branca;
- SHA-256;
- commit e push controlados.

## Regra de commits

Cada commit deve:

- ser pequeno e reversível;
- não misturar banco e frontend sem necessidade;
- manter aplicação compilando;
- preservar telas existentes;
- usar staging seletivo;
- não realizar merge.
