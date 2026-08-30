---
id: SPARKS-BENCHMARK-UX-SMARTKANVAS-001
version: 1.0.0
status: approved
domain: SPARKs PaaS
owner: SPARKOOP
canonical_context: SK-PE-CONT-01
created_at: 2026-08-30
updated_at: 2026-08-30
source: SMARTKANVAS.docx
classification: external-benchmark
---

# Benchmark UX — SmartKanvas → SPARKs

## 1. Objetivo

Registrar, sem copiar identidade visual ou arquitetura do benchmark, os padrões de experiência observados no material recebido e traduzir esses aprendizados em critérios competitivos para o SPARKs.

O benchmark é usado para elevar a régua de simplicidade, velocidade de compreensão, orientação e beleza funcional.

## 2. Padrões fortes observados

### 2.1 Entrada orientada

O produto recebe o usuário com uma mensagem de boas-vindas, explica brevemente a proposta e oferece uma ação inicial inequívoca.

Aprendizado SPARKs: reduzir o custo de descoberta inicial e priorizar uma ação primária por contexto.

### 2.2 Jornada multipasso permanentemente visível

O planejamento estratégico é organizado em sequência visível de etapas, permitindo compreender posição atual, passos anteriores e próximos passos.

Aprendizado SPARKs: a Jornada Estratégica deve ser compreensível como percurso, não apenas como hierarquia metodológica.

### 2.3 Ajuda contextual no ponto de trabalho

O benchmark apresenta orientação e sugestões junto ao objeto/tela em edição, em vez de exigir que o usuário abandone o contexto para procurar ajuda.

Aprendizado SPARKs: assistência cognitiva deve ser contextual ao objeto atual.

### 2.4 Progressive disclosure

Informações e operações avançadas aparecem conforme o usuário avança ou solicita mais detalhe.

Aprendizado SPARKs: evitar exposição simultânea de todas as capacidades da Plataforma.

### 2.5 Um mesmo trabalho em múltiplas visões

Há alternância entre lista, Kanban, cronograma/calendário e outras visões operacionais.

Aprendizado SPARKs: reforçar a arquitetura já adotada de uma autoridade única com projeções múltiplas.

### 2.6 Espaço de trabalho por objeto

Ao entrar em trabalhos/iniciativas/tarefas, o usuário passa a operar aquele contexto e suas visões relacionadas.

Aprendizado SPARKs: consolidar o padrão `Objeto → Espaço de Trabalho`.

### 2.7 Painéis e favoritos pessoais

O benchmark reserva uma área própria para painéis favoritos e personalização da experiência.

Aprendizado SPARKs: manter separação semântica entre `Painel Principal` singular e `Favoritos`, evoluindo a home pessoal de forma governada.

### 2.8 Operação direta

Ações como incluir tarefas, editar, mover, usar checklist, documentos e acompanhar tempo ficam próximas ao contexto operacional.

Aprendizado SPARKs: reduzir distância entre diagnóstico e execução.

## 3. O que não copiar

O SPARKs não deve copiar:

- identidade visual, paleta ou componentes proprietários;
- terminologia específica do benchmark;
- estrutura de dados presumida pelas telas;
- qualquer duplicação de entidades apenas para reproduzir uma visão;
- densidade ou padrões que não se alinhem ao Design System SPARKs.

Benchmark é referência de experiência, não especificação de implementação.

## 4. Onde o SPARKs deve superar o benchmark

### 4.1 Governança invisível

Toda ação simples do usuário deve preservar autorização, lifecycle, auditoria, rastreabilidade e integridade sem exigir compreensão da arquitetura.

### 4.2 Contexto transversal

O mesmo usuário deve conseguir transitar entre estratégia, iniciativas, pessoas, capacidades, agenda, evidências, custos, processos e demais módulos sem fragmentação de identidade/contexto.

### 4.3 Inteligência contextual real

A assistência deve usar o contexto autorizado do objeto, da organização, dos dados e das evidências, podendo explicar, sugerir e preparar ações governadas.

### 4.4 Explicabilidade

Indicadores e recomendações relevantes devem poder responder `por quê?` e, quando aplicável, permitir navegação até sua origem.

### 4.5 Uma autoridade, muitas experiências

Kanban, Gantt, Agenda, lista, cronograma e painéis devem ser projeções de autoridades canônicas, não cópias de dados.

### 4.6 Design System transversal

O usuário não deve perceber cada módulo como um produto diferente. Alinhamento, tipografia, cards, abas, botões, menus, estados e interações devem obedecer à mesma gramática.

## 5. Tradução prática para o SPARKs

### Painel Principal

Deve evoluir para home pessoal de atenção e decisão, contendo progressivamente indicadores, pendências, alertas, Agenda e informações relevantes entre módulos.

### Jornada Estratégica

Deve mostrar claramente a progressão metodológica, posição atual e próximos passos, preservando sua relação com o Projeto Estratégico.

### Iniciativas

A lista/portfólio deve permitir abrir a iniciativa como espaço de trabalho. O padrão inicial validado é:

`Iniciativa → Kanban | Custos e esforço | outras visões justificadas`.

Operações de agenda devem usar linguagem contextual como `Adicionar à agenda`.

### Ações

A ação deve concentrar seus detalhes operacionais em um contexto único, com progressive disclosure para responsabilidade, capacidade, checklist, anexos, comentários, custos, esforço e demais contratos disponíveis.

### IA

A evolução deve priorizar assistência dentro do contexto de trabalho, não uma conversa genérica desconectada.

## 6. Régua competitiva

Para uma capacidade nova, perguntar antes do fechamento:

1. O usuário compreende em poucos segundos o que fazer?
2. Há menos passos do que antes?
3. Existe um único lugar natural para trabalhar o objeto?
4. A tela continua bonita com dados reais?
5. A inteligência aparece no contexto correto?
6. A governança está preservada sem ficar exposta como complexidade?
7. A experiência é pelo menos tão simples quanto o benchmark e mais poderosa onde o SPARKs tem vantagem estrutural?

Se a resposta relevante for `não`, a entrega ainda não está pronta para competir.

## 7. Síntese estratégica

O objetivo não é construir um SmartKanvas melhor.

O objetivo é combinar a disciplina de experiência observada no benchmark com a profundidade do SPARKs.

> **SPARKs = profundidade empresarial + simplicidade de aplicativo de consumo + inteligência contextual.**

Este benchmark deve ser usado em revisões de UX, definição de novos fluxos e fechamento de gates com superfície de usuário.