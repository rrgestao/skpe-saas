---
id: SPARKS-UX-ATTACK-72H-001
version: 1.0.0
status: approved
domain: SPARKs PaaS
owner: SPARKOOP
canonical_context: SK-PE-CONT-01
created_at: 2026-08-30
updated_at: 2026-08-30
timebox: 72h
creates_new_functional_gates: false
---

# Plano de Ataque UX SPARKs — 72 horas

## 1. Missão

Elevar rapidamente a percepção de simplicidade, velocidade e beleza do SPARKs sem desmontar sua arquitetura e sem interromper a sequência funcional canônica.

Este plano é um **pacote transversal de hardening**, não um novo roadmap funcional.

Regra de priorização:

> corrigir primeiro padrões que aparecem em muitas telas; depois corrigir telas específicas.

## 2. Resultado esperado em 72 horas

Ao final do timebox, o usuário deve perceber:

- uma Plataforma visualmente coerente;
- menos botões concorrentes;
- cards e indicadores com padrão único;
- objetos clicáveis que abrem espaços de trabalho claros;
- Jornada Estratégica orientada por progresso e próximo passo;
- Painel Principal com sensação de home pessoal;
- estados vazios e mensagens que ensinam o usuário a avançar;
- base visual preparada para assistência contextual.

## 3. Frente P0 — Design System mínimo executável | 0–12h

Objetivo: eliminar correções repetidas de CSS tela por tela.

Criar ou consolidar componentes/padrões reutilizáveis:

- `MetricCard` — métrica/resumo, conteúdo centralizado, tipografia adaptativa;
- `ObjectCard` — objeto clicável, informação textual alinhada à leitura;
- `ObjectWorkspaceHeader` — contexto, status, ações primária/secundária;
- `WorkspaceTabs` — abas consistentes;
- `EmptyState` — título, explicação, próxima ação;
- `LoadingState`;
- `ErrorState`;
- `PrimaryAction` / `SecondaryAction`;
- `SectionHeader`;
- `ContextCode` — código técnico sempre secundário;
- tokens mínimos de spacing, radius, elevation e tamanhos tipográficos.

Primeiras superfícies obrigatórias para aplicação:

1. Visão Geral;
2. Iniciativas;
3. Administração da Organização;
4. componentes econômicos já expostos.

Critério: defeitos como “valor desalinhado” devem deixar de ser resolvidos por seletor específico de tela.

## 4. Frente P0 — Objeto → Espaço de Trabalho | 12–24h

Objetivo: reduzir dispersão operacional.

### Iniciativa

Estado já iniciado no commit `de6da85a5c6b4679fa0289189a955f6aa70bff15`.

Consolidar experiência:

- clicar na iniciativa abre o espaço da iniciativa;
- Kanban é visão operacional inicial;
- Custos e esforço é aba da mesma iniciativa;
- Agenda aparece como ação contextual `Adicionar à agenda`;
- futuras visões justificadas entram como abas, não como botões espalhados no portfólio.

### Ação

Revisar o drawer atual para aproximá-lo do mesmo modelo:

- resumo;
- responsável/capacidade;
- datas;
- custo/esforço;
- checklist/documentos quando os respectivos contratos existirem;
- histórico/auditoria sob progressive disclosure.

Critério: o usuário não deve precisar memorizar em qual tela cada propriedade da ação é editada.

## 5. Frente P0 — Jornada Estratégica guiada | 24–36h

Objetivo: transformar profundidade metodológica em percurso compreensível.

Implementar sem duplicar a hierarquia:

- indicador persistente de posição atual;
- concluído / atual / próximo;
- ação clara `Continuar Jornada`;
- nome humano da etapa em destaque;
- código metodológico como apoio;
- relação perceptível com Projeto Estratégico;
- controles `Anterior` / `Próximo` quando semanticamente válidos;
- possibilidade de recolher hierarquia sem perder a orientação global.

Referência competitiva: usar a disciplina de jornada multipasso observada no benchmark, sem copiar identidade ou estrutura proprietária.

Critério: uma pessoa que não conhece PEM deve conseguir responder `onde estou?` e `o que faço agora?` em poucos segundos.

## 6. Frente P1 — Painel Principal como home pessoal | 36–48h

Objetivo: fazer a entrada da Plataforma parecer útil imediatamente.

Compor progressivamente, usando contratos existentes:

- 3–5 indicadores realmente prioritários;
- `Minha atenção agora`;
- Agenda compacta do mês;
- próximos compromissos/prazos em ordem cronológica;
- alertas relevantes;
- atalhos contextuais para itens que exigem ação;
- continuidade do último contexto quando apropriado.

Não construir dashboard “árvore de Natal”.

Regra: cada bloco precisa responder `por que isso está na minha home?`.

## 7. Frente P1 — Estados vazios que ensinam | 48–56h

Objetivo: transformar ausência de dados em orientação.

Padronizar estados vazios para responder:

1. o que é esta área;
2. por que está vazia;
3. quem pode agir;
4. qual é o próximo passo;
5. qual ação pode ser executada agora.

Aplicar primeiro em:

- Agenda;
- Kanban;
- Iniciativas;
- Custos e esforço;
- Jornada;
- Monitoramento.

## 8. Frente P1 — Assistência contextual: fundação de experiência | 56–64h

Objetivo: preparar a IA para aparecer dentro do trabalho.

Não criar ainda um motor novo.

Definir o padrão visual e de interação:

- `Perguntar ao SPARKs sobre esta iniciativa`;
- `Explicar este indicador`;
- `Sugerir próximos passos`;
- `Preparar pauta`;
- `Revisar consistência`.

Toda sugestão deve distinguir:

- informação observada;
- inferência/sugestão;
- ação que pode gerar objeto persistido.

Nenhuma persistência automática sem confirmação governada.

## 9. Frente P0 — Auditoria UX competitiva | 64–72h

Objetivo: concluir o timebox com evidência, não sensação.

Executar inspeção sistemática usando `CHECKLIST_PRONTIDAO_UX_SPARKS.md` nas superfícies críticas:

- entrada no módulo;
- Visão Geral;
- Jornada;
- Iniciativas;
- espaço da Iniciativa;
- Kanban;
- Agenda;
- Administração da Organização.

Registrar para cada uma:

- `UX-BLOCKED`;
- `UX-NEEDS-HARDENING`;
- `UX-READY`.

Bloqueadores P0 devem ser corrigidos antes de nova expansão funcional.

## 10. O que fica fora das 72 horas

Para proteger o timebox:

- redesign total de marca;
- biblioteca visual externa pesada;
- animações sofisticadas;
- novo motor de IA;
- novo sistema financeiro;
- mensageria completa;
- reescrita arquitetural;
- features sem relação direta com percepção de valor imediata.

## 11. Regra para cada mudança durante o timebox

Antes de implementar:

1. existe componente/padrão transversal que deve resolver isto?
2. podemos reduzir uma ação em vez de adicionar outra?
3. podemos reutilizar uma autoridade existente?
4. o nome fala a língua do usuário?
5. a mudança deixa a tela mais rápida de compreender?

Depois de implementar:

1. testes PASS;
2. build PASS;
3. inspeção visual;
4. caminho real percorrido;
5. checklist `UX-READY`.

## 12. North Star do timebox

Não medir sucesso por quantidade de componentes criados.

Medir por três perguntas:

- **Tempo até compreender:** quanto tempo leva para entender a tela?
- **Tempo até agir:** quantos passos até executar a tarefa principal?
- **Confiança:** o usuário sente que sabe o que aconteceu e o que vem depois?

## 13. Compromisso

> O SPARKs não ganhará o mercado por mostrar que é complexo. Ganhará quando o usuário perceber simplicidade e a organização receber, silenciosamente, toda a profundidade que construímos.

**Ordem recomendada imediata:** Design System mínimo → espaço de trabalho dos objetos → Jornada guiada → Painel Principal pessoal → estados vazios → assistência contextual → auditoria UX.