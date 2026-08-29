---
id: SKPE-AUDIT-17-B-5F-3C-6I
status: closed
result: pass
canonical_context: SK-PE-CONT-01
roadmap: 17-B.5F.3C.6D-6J
gate: 17-B.5F.3C.6I
date: 2026-08-29
---

# Relatório de Fechamento — 17-B.5F.3C.6I — Agenda, Calendário e Eventos Operacionais

## 1. Resultado

`SKPE_17_B_5F_3C_6I = PASS/CLOSED`

O gate foi encerrado após reconciliação do branch canônico, inspeção direta do Supabase DEV e validação dos contratos de eventos, participantes, agenda pessoal, vínculos polimórficos e projeções derivadas.

## 2. Critério de saída do roadmap

Critério: autoridade única para eventos, vínculos rastreáveis, calendário derivado e ausência de duplicação de cronograma.

Resultado: atendido.

## 3. Autoridade única de eventos

A autoridade nativa permanece `public.sparks_events`, com participantes em `public.sparks_event_participants`.

Foram revalidados no DEV os contratos:

- `create_sparks_event`;
- `update_sparks_event`;
- `transition_sparks_event_lifecycle`;
- `get_sparks_event_participant_management`;
- `set_sparks_event_participant`;
- `remove_sparks_event_participant` / `remove_sparks_event_participant_by_id`;
- `record_sparks_event_attendance`;
- `get_my_sparks_agenda`;
- `get_my_skpe_agenda_projection`.

Não foi criada entidade paralela de calendário, card ou cronograma.

## 4. Vínculo polimórfico governado

As migrations finais endurecem o contrato de origem de eventos:

- `20260829190418_extend_sparks_event_source_to_initiatives_actions`;
- `20260829190604_harden_sparks_event_source_polymorphic_links`.

Tipos governados relevantes no SK-PE:

- `skpe_journey_item`;
- `sparks_initiative`;
- `sparks_initiative_action`.

O guard `can_manage_sparks_event_source(...)` exige contexto organizacional, tipo reconhecido, objeto de origem existente e autorização correspondente. Evento sem origem continua sendo evento nativo da organização; evento vinculado não pode usar tipo arbitrário como atalho.

## 5. Operação contextual

O frontend reutiliza o mesmo diálogo governado de criação de eventos.

A criação contextual passou a estar disponível em:

- Jornada Estratégica;
- iniciativa;
- ação do Kanban.

Commit relevante:

- `e17bccf2de1dd30da90ec56c0eb68043b0f146e4` — `feat(skpe): create agenda events from initiatives and actions`.

A execução local desse incremento registrou 112/112 testes, build aprovado, push concluído e worktree limpa.

## 6. Agenda e calendário derivados

A seção Agenda consome exclusivamente `get_my_sparks_agenda`, que compõe:

1. eventos nativos de `sparks_events` dos quais o usuário participa;
2. projeções SK-PE derivadas de autoridades do módulo;
3. preferências pessoais de visibilidade.

A UI disponibiliza calendário mensal e lista cronológica do período, sem persistir representação gráfica própria.

## 7. Prazos e marcos

A auditoria final identificou que o adapter SK-PE originalmente projetava apenas reuniões estratégicas. A lacuna foi corrigida pela migration:

- `20260829232922_extend_skpe_agenda_projection_with_initiative_deadlines`.

Commit de reconciliação:

- `f84cc5114f08ca0a01ced3f773beec007269159c` — `feat(skpe): project initiative deadlines into agenda`.

O contrato `get_my_skpe_agenda_projection` passa a projetar, sem persistência paralela:

- reuniões de revisão estratégica como `event`;
- prazo canônico de iniciativa como `deadline`;
- prazo de ação como `deadline`;
- ação do tipo milestone como `milestone`.

Para ações, a data projetada respeita a ordem de autoridade temporal disponível: forecast, plano vigente e baseline. A projeção não reescreve nenhuma dessas datas.

No estado DEV inspecionado em 2026-08-29 não existiam iniciativas/ações SK-PE com prazo preenchido suficientes para produzir exemplos reais dessas novas linhas; nenhum dado fictício foi criado apenas para demonstrar a projeção.

## 8. Recorrência

O roadmap define recorrência “quando necessária”. Nenhuma necessidade funcional comprovada exigiu engine de recorrência neste gate. Portanto, não foi criada nova autoridade ou mecanismo antecipado.

## 9. Participantes, presença e visibilidade

A fundação de participantes e presença já existente foi mantida.

A agenda pessoal respeita participação do usuário em eventos nativos e preferências de visibilidade por item. As projeções SK-PE continuam submetidas a leitura da organização e acesso ao módulo.

## 10. Não duplicação de Jornada e Gantt

O gate não converte MegaFases/Fases/Etapas em eventos.

Itens metodológicos da Jornada podem possuir eventos associados, preservando sua natureza original.

Prazos e marcos de iniciativas/ações aparecem como projeções de agenda, não como novos registros de cronograma. O Gantt continua derivado das autoridades temporais canônicas do 6H.

## 11. Evidências de UX correlatas

Durante a validação do gate foram corrigidas regressões do shell sem alterar a semântica de agenda:

- `ab48a2b148cac3209a9eea3af265a60809e9c9ac` — cards legíveis, etapa atual descritiva e shell compacto;
- `f4f1c68a1f214d1901ec553aab4616d63613ac1d` — comportamento e iconografia transversal dos menus laterais.

O último hardening local registrou 112/112 testes, build aprovado, push concluído e worktree limpa.

## 12. Conclusão

Os critérios funcionais e arquiteturais do `17-B.5F.3C.6I` estão atendidos:

- autoridade única de eventos: PASS;
- vínculo polimórfico governado e rastreável: PASS;
- eventos vinculáveis a Jornada, iniciativas e ações: PASS;
- participantes/presença/visibilidade: PASS;
- calendário pessoal derivado: PASS;
- prazos de iniciativas e prazos/marcos de ações projetados sem duplicação: PASS;
- ausência de cronograma concorrente: PASS;
- recorrência tratada apenas quando necessária: PASS.

`SKPE_17_B_5F_3C_6I = PASS/CLOSED`

Próximo gate canônico: `17-B.5F.3C.6J — Custos, Esforço e Controle Econômico de Execução`.
