---
id: SPARKS-MANIFESTO-UX-001
version: 1.0.0
status: approved
domain: SPARKs PaaS
owner: SPARKOOP
canonical_context: SK-PE-CONT-01
created_at: 2026-08-30
updated_at: 2026-08-30
applies_to:
  - all-user-facing-surfaces
  - all-modules
  - all-future-gates
---

# Manifesto UX SPARKs — Poderoso por dentro. Simples por fora. Inteligente em todo lugar.

## 1. Propósito

O SPARKs pode ser tecnicamente robusto sem parecer complexo.

A robustez pertence à arquitetura, aos contratos, à governança, à auditoria, à rastreabilidade e à inteligência da Plataforma. A superfície pertence ao usuário.

A partir deste documento, nenhuma capacidade voltada ao usuário será considerada pronta apenas porque funciona tecnicamente.

Ela precisa ser:

- fácil de compreender;
- rápida para executar;
- simples para navegar;
- coerente com o restante da Plataforma;
- visualmente clara e agradável;
- segura sem exigir que o usuário compreenda a segurança;
- inteligente sem obrigar o usuário a conversar com um sistema separado do trabalho.

## 2. Lei de Experiência SPARKs

> Nenhuma capacidade é considerada pronta apenas porque funciona. Ela precisa ser compreensível, simples, rápida e visualmente coerente para uma pessoa que não conhece nossa arquitetura.

Regra complementar:

> Se for necessário explicar verbalmente onde clicar ou o que um termo técnico significa, a experiência ainda pode melhorar.

## 3. Modelo mental principal

O SPARKs deve apresentar ao usuário, nesta ordem:

1. **onde estou**;
2. **o que precisa da minha atenção**;
3. **o que posso fazer agora**;
4. **qual será o efeito da ação**;
5. **o que vem depois**.

Detalhes técnicos, contratos, IDs, auditoria, fontes de verdade e mecanismos transversais permanecem disponíveis quando úteis, mas não devem dominar a superfície principal.

## 4. Princípios não negociáveis

### 4.1 Um objeto, um lugar natural para trabalhar

Uma Iniciativa, Projeto, Objetivo, Resultado-Chave, Ação, Pessoa ou outro objeto relevante deve possuir um ponto natural de entrada.

Ao abrir o objeto, o usuário encontra suas visões e operações relacionadas por abas, seções ou progressive disclosure.

Evitar espalhar pelo card uma coleção de botões concorrentes como se cada visão fosse um produto diferente.

### 4.2 Uma informação, múltiplas visões

A mesma autoridade pode ser projetada em Kanban, Gantt, Agenda, lista, painel, cronograma ou outras visões sem duplicação da fonte de verdade.

A experiência muda; o objeto não.

### 4.3 Linguagem do usuário antes da linguagem técnica

Rótulos devem expressar a intenção do usuário.

Preferir:

- `Adicionar à agenda` em vez de `Novo evento` quando o contexto for reunião, compromisso, prazo ou marco;
- nome da etapa antes de seu código técnico;
- `Responsável` antes do nome interno do contrato de atribuição;
- `Custos e esforço` antes de terminologia de projection/read model.

Códigos e IDs continuam disponíveis como informação secundária de rastreabilidade.

### 4.4 Complexidade progressiva

A superfície inicial mostra o necessário para compreender e agir.

Detalhes avançados surgem quando o usuário pede, navega ou precisa deles.

Abas, drawers, expansão hierárquica e progressive disclosure são preferidos ao empilhamento indiscriminado de informação.

### 4.5 Ação primária inequívoca

Uma tela deve deixar evidente qual é a ação mais importante naquele contexto.

Ações secundárias não devem competir visualmente com a ação principal.

### 4.6 Orientação permanente em jornadas complexas

Fluxos metodológicos ou multipasso devem responder permanentemente:

- onde estou;
- o que já foi concluído;
- o que falta;
- qual é o próximo passo.

### 4.7 Beleza é propriedade funcional

Beleza no SPARKs significa coerência, legibilidade e confiança operacional.

São obrigatórios quando aplicáveis:

- espaçamento consistente;
- hierarquia tipográfica evidente;
- alinhamento consistente;
- indicadores e cartões de síntese centralizados quando sua natureza for métrica/resumo;
- tipografia responsiva ao conteúdo;
- cores com significado;
- ícones semanticamente distintos;
- estados vazios instrutivos;
- microinterações discretas;
- densidade compatível com a tarefa.

### 4.8 Performance percebida é parte da UX

Não carregar ou renderizar superfícies pesadas sem necessidade.

Evitar múltiplas rolagens concorrentes, recálculos desnecessários e grandes componentes ativos fora da visão atual.

### 4.9 IA dentro do trabalho

A inteligência do SPARKs deve aparecer no contexto em que o usuário está trabalhando.

O padrão desejado não é um chatbot isolado, mas assistência contextual capaz de:

- explicar;
- sugerir;
- comparar;
- resumir;
- detectar inconsistências;
- preparar conteúdo;
- propor próximos passos;
- produzir objetos governados somente após confirmação apropriada.

### 4.10 Governança invisível, consequência visível

O usuário executa uma ação simples; a Plataforma aplica silenciosamente autorização, lifecycle, auditoria, integridade e atualização de projeções.

O usuário não deve precisar compreender a infraestrutura para trabalhar corretamente.

## 5. Padrão de entrada do usuário

A entrada no SPARKs deve privilegiar o contexto pessoal e operacional.

O Painel Principal deve evoluir como home pessoal, podendo reunir progressivamente:

- indicadores principais;
- pendências;
- alertas;
- Agenda transversal;
- itens que requerem decisão;
- informações relevantes de diferentes módulos;
- comunicação contextual quando o contrato correspondente existir.

Essa home não substitui os módulos; ela orienta o usuário para onde sua atenção deve ir.

## 6. Padrão Objeto → Espaço de Trabalho

Sempre que um objeto possuir várias visões relevantes, adotar preferencialmente:

`lista/portfólio -> abrir objeto -> espaço de trabalho -> abas/visões`

Exemplo para Iniciativa:

`Portfólio -> Iniciativa -> Kanban | Custos e esforço | demais visões justificadas`

A Agenda deve aparecer como ação contextual compreensível, não como entidade técnica concorrente.

## 7. O que não fazer

Evitar:

- telas que expõem estrutura do banco ou arquitetura como modelo mental do usuário;
- múltiplos botões equivalentes disputando atenção;
- cards de síntese desalinhados ou com tipografia que quebra a leitura;
- códigos técnicos como informação principal;
- criar uma nova tela quando uma aba resolve o problema;
- criar uma nova entidade quando uma projeção resolve o problema;
- adicionar funcionalidade sem definir seu estado vazio, carregamento, erro e permissão;
- adiar legibilidade para uma fase genérica de “polimento”.

## 8. Definition of Done UX

Uma entrega com superfície de usuário só pode receber `PASS/CLOSED` quando, além dos critérios técnicos:

1. a ação principal é evidente;
2. os termos são compreensíveis sem explicação externa;
3. o usuário sabe onde está e como voltar;
4. o layout permanece legível com conteúdo real;
5. estados vazio, carregando, erro e sem permissão são tratados;
6. o fluxo funciona por mouse e teclado quando aplicável;
7. não existe fonte de verdade concorrente criada apenas para a interface;
8. a tela respeita o Design System/guardrails existentes;
9. a experiência foi inspecionada visualmente, e não apenas testada por unit/build;
10. a capacidade reduz trabalho ou incerteza para o usuário.

## 9. Frase-guia

> **Poderoso por dentro. Simples por fora. Inteligente em todo lugar.**

Este princípio deve orientar arquitetura de experiência, implementação frontend, revisão de gates e decisões de produto do SPARKs.