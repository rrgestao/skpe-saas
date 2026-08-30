---
id: SPARKS-CHECKLIST-UX-READY-001
version: 1.0.0
status: approved
domain: SPARKs PaaS
owner: SPARKOOP
canonical_context: SK-PE-CONT-01
created_at: 2026-08-30
updated_at: 2026-08-30
applies_to:
  - all-user-facing-surfaces
---

# Checklist de Prontidão UX SPARKs

## Uso

Este checklist integra o critério de fechamento de toda entrega com superfície de usuário.

Não cria novo gate funcional e não substitui testes técnicos. Ele impede que uma entrega tecnicamente correta seja encerrada com experiência inadequada.

Uma entrega pode ser classificada como `UX-READY` somente quando todos os itens obrigatórios aplicáveis estiverem atendidos.

## A. Compreensão imediata

- [ ] O título da tela deixa claro o propósito da superfície.
- [ ] O usuário sabe em que organização, módulo, projeto ou objeto está.
- [ ] A ação principal é identificável em poucos segundos.
- [ ] Rótulos utilizam linguagem de negócio, não linguagem de implementação.
- [ ] Códigos técnicos aparecem como informação secundária quando necessários.
- [ ] Não há botão cujo propósito dependa de explicação externa.

## B. Navegação e orientação

- [ ] O usuário sabe como voltar.
- [ ] Menus recolhidos preservam ícones compreensíveis e tooltips.
- [ ] Rotas explícitas não são sequestradas por preferências de landing.
- [ ] Abas/visões preservam contexto do objeto atual.
- [ ] Fluxos multipasso mostram posição atual e próximo passo.
- [ ] Não existem becos sem saída de navegação.

## C. Hierarquia visual

- [ ] Há uma única ação visualmente dominante por contexto quando aplicável.
- [ ] Ações secundárias possuem peso visual inferior.
- [ ] Cards métricos/de síntese utilizam alinhamento central e tipografia adaptativa.
- [ ] Cards textuais preservam alinhamento adequado à leitura, sem aplicar centralização indiscriminada.
- [ ] Espaçamentos, bordas, raios e hierarquia tipográfica seguem padrão consistente.
- [ ] Ícones diferentes representam funções diferentes.
- [ ] Cores têm significado consistente e não são o único portador de informação.

## D. Conteúdo real

- [ ] A tela foi inspecionada com dados reais ou representativos, não apenas lorem/estado vazio.
- [ ] Textos longos não quebram o layout.
- [ ] Valores grandes não estouram cards.
- [ ] Nomes extensos permanecem legíveis.
- [ ] Datas, moedas, percentuais e unidades são formatados para o usuário.

## E. Estados operacionais

- [ ] Estado `loading` existe e não parece erro.
- [ ] Estado vazio explica o que a superfície representa e o que pode ser feito.
- [ ] Estado de erro é compreensível e oferece recuperação quando possível.
- [ ] Estado sem permissão não expõe ação impossível.
- [ ] Estado read-only é distinguível do estado editável.
- [ ] Salvamento em andamento evita mutação concorrente quando necessário.

## F. Progressive disclosure

- [ ] A tela inicial não apresenta detalhe que só é útil depois de uma ação do usuário.
- [ ] Visões do mesmo objeto usam preferencialmente abas ou controles equivalentes.
- [ ] Componentes pesados não são montados simultaneamente sem necessidade.
- [ ] Formulários avançados não competem com tarefas operacionais básicas.

## G. Padrão Objeto → Espaço de Trabalho

Quando aplicável:

- [ ] O objeto é clicável a partir de sua lista/portfólio.
- [ ] O clique abre um espaço de trabalho do objeto, não uma coleção de modais desconectados.
- [ ] As visões do objeto ficam agrupadas de forma coerente.
- [ ] Operações transversais são apresentadas em linguagem contextual.

## H. Acessibilidade operacional mínima

- [ ] Elementos clicáveis não dependem exclusivamente de `div` sem semântica ou suporte de teclado.
- [ ] Ações principais podem ser alcançadas por teclado quando aplicável.
- [ ] Foco visível existe.
- [ ] Tooltips não são a única forma de comunicar informação essencial.
- [ ] Contraste visual é suficiente para leitura prática.

## I. Performance percebida

- [ ] A entrada na tela não dispara chamadas ou renderizações claramente desnecessárias.
- [ ] Troca de abas não recria estado sem necessidade.
- [ ] Uma única rolagem principal é preservada sempre que possível.
- [ ] Não existem listas profundamente expandidas por padrão quando podem ser condensadas.
- [ ] Componentes de grande volume oferecem filtros, busca ou condensação adequados.

## J. Governança invisível

- [ ] A interface usa contratos governados existentes.
- [ ] Nenhuma entidade foi criada apenas para sustentar uma representação visual.
- [ ] A UI não permite uma ação que o backend necessariamente rejeitará em condições previsíveis.
- [ ] Alterações auditáveis comunicam justificativa quando realmente necessária, sem expor jargão técnico.

## K. Inteligência contextual

Quando houver assistência de IA:

- [ ] A assistência conhece o objeto/contexto atual.
- [ ] A sugestão é claramente distinguida de um fato persistido.
- [ ] Nenhum objeto governado é criado silenciosamente sem confirmação apropriada.
- [ ] O usuário consegue entender o efeito antes de aceitar a ação proposta.

## L. Validação final

Obrigatórios antes de `PASS/CLOSED`:

- [ ] testes automatizados aplicáveis = PASS;
- [ ] build = PASS;
- [ ] inspeção visual realizada;
- [ ] caminho feliz testado manualmente;
- [ ] pelo menos um estado alternativo relevante testado;
- [ ] nenhum problema crítico de compreensão conhecido permanece aberto.

## Classificação

- `UX-BLOCKED`: existe falha que impede compreensão/operação adequada;
- `UX-NEEDS-HARDENING`: funciona, mas ainda viola algum critério relevante;
- `UX-READY`: atende aos critérios obrigatórios aplicáveis.

Somente `UX-READY` pode sustentar fechamento de uma entrega com superfície de usuário.