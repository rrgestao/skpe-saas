# Matriz de Rotas e Contexto — FE-09.A

## 1. Rotas de entrada

| Rota | Finalidade |
|---|---|
| `/workspace` | Meu Espaço de Trabalho |
| `/workspace/dashboards` | Painéis disponíveis |
| `/workspace/notifications` | Central de notificações |
| `/workspace/favorites` | Favoritos |

## 2. Rotas SK-PE

Base:

```text
/organizations/:organizationId/skpe/projects/:projectId/formulations/:formulationId
```

| Sufixo | Contexto |
|---|---|
| `/overview` | Visão executiva |
| `/journey` | Jornada |
| `/formulations` | Governança e versões |
| `/identity` | Identidade |
| `/business-foundation` | Fundamentação |
| `/value-chain` | Cadeia de Valor |
| `/strategic-map` | Temas, perspectivas e OEs |
| `/indicators` | Indicadores, metas e BMKs |
| `/okrs` | OKRs e KRs |
| `/initiatives` | Portfólio e execução |
| `/monitoring` | Ciclos e desempenho |
| `/governance` | RAE/RAD, decisões e aprendizados |
| `/artifacts` | Artefatos e evidências |

## 3. Rotas de registros

| Rota | Registro |
|---|---|
| `/indicators/:indicatorId` | Indicador |
| `/okrs/:okrId` | OKR |
| `/key-results/:keyResultId` | KR |
| `/initiatives/:initiativeId` | Iniciativa |
| `/monitoring/cycles/:cycleId` | Ciclo |
| `/governance/reviews/:reviewId` | Reunião |
| `/governance/decisions/:decisionId` | Decisão |

## 4. Regras

- a rota deve validar coerência entre organização, projeto e Formulação;
- acesso hierárquico somente leitura deve aparecer visualmente;
- Formulação aprovada não oferece ações estruturais;
- ciclo fechado não oferece mutações;
- rota inválida deve redirecionar para seletor explícito;
- nunca selecionar silenciosamente o primeiro registro.

## 5. Breadcrumb

Exemplo:

```text
COOTAQUARA
› PE 2026–2030
› Formulação v1
› Indicadores
› KPI-FIN-01
```
