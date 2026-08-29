---
id: SKPE-RELATORIO-FECHAMENTO-17-B-5F-3C-6H
version: 1.0.0
status: approved
domain: SPARKs PaaS
owner: SPARKs PE
canonical_context: SK-PE-CONT-01
gate: 17-B.5F.3C.6H
created_at: 2026-08-29
updated_at: 2026-08-29
---

# Relatório de Fechamento — 17-B.5F.3C.6H — Gantt, Baseline e Desvio Temporal

## 1. Resultado

**17-B.5F.3C.6H = PASS / CLOSED em 2026-08-29.**

O Gantt permanece projeção gerencial derivada das autoridades temporais existentes, sem entidade gráfica persistente, sem duplicação de datas e sem lifecycle próprio.

## 2. Autoridades preservadas

- Jornada temporal: `get_skpe_journey_temporal_read_model(uuid, uuid, date)`;
- iniciativa/ações temporais: `get_sparks_initiative_temporal_projection(uuid, uuid, date, boolean)`;
- baseline da iniciativa: `set_sparks_initiative_temporal_baseline`;
- plano vigente da iniciativa: `update_sparks_initiative_temporal_plan`;
- forecast da iniciativa: `update_sparks_initiative_temporal_forecast`;
- forecast da ação: `update_sparks_initiative_action_temporal_forecast`;
- projeção integrada consumida pela UX: `get_skpe_project_operational_projection`.

Nenhuma migration adicional foi necessária para o fechamento do 6H porque o domínio temporal governado já estava materializado no DEV.

## 3. Projeção temporal final

A UX representa, na mesma régua temporal:

- baseline original;
- plano institucional vigente;
- forecast operacional;
- datas realizadas;
- eventos da Jornada;
- data de referência.

As métricas explícitas de desvio são consumidas diretamente dos read models canônicos:

- plano vigente × baseline;
- forecast × plano vigente;
- realizado × plano vigente.

Valores nulos ou iguais a zero não geram ruído visual; desvios diferentes de zero são apresentados em dias com sinal explícito.

## 4. UX hierárquica e condensada

Guardrail associado:

`docs/00-governanca/GUARDRAIL_UX_BASILAR_6G_6H_JORNADA.md`.

O Gantt foi endurecido para:

- iniciar em estado condensado;
- preservar hierarquia pai-filho da Jornada;
- preservar hierarquia iniciativa/ações;
- expandir e recolher ramos individualmente;
- disponibilizar `Recolher tudo`;
- disponibilizar `Expandir tudo`;
- evitar renderização profunda desnecessária como estado inicial;
- manter a janela temporal derivada do conjunto canônico completo, evitando saltos de escala ao expandir/recolher;
- preservar a alternância entre Jornada completa e Jornada obrigatória.

## 5. Dependências e caminho crítico

O gate não introduziu dependências artificiais nem cálculo de caminho crítico.

Conforme o contrato do roadmap, dependências só devem ser representadas quando houver contrato próprio semanticamente justificado; caminho crítico só pode ser calculado quando a semântica de dependência estiver formalmente suportada. O 6H não inventa essas relações.

## 6. Evidências técnicas

### Hardening hierárquico

Commit:

`80cada6d20ec931ee5940c3a82c3603e728a4af9`

Mensagem:

`feat(skpe): condense gantt hierarchy by default`

Gate local:

`SKPE_6H_GANTT_HIERARCHY_HARDENING=PASS`

### Desvios temporais explícitos

Commit técnico final:

`ccee191d8f51dd45ffec146a8ca7653d4b6cfb31`

Mensagem:

`feat(skpe): expose canonical gantt temporal deviations`

Gate local:

`SKPE_6H_GANTT_TEMPORAL_DEVIATIONS=PASS`

### Testes e build

Nos dois incrementos finais:

- total de testes frontend: 112;
- PASS: 112;
- FAIL: 0;
- TypeScript build: PASS;
- Vite build: PASS;
- 174 módulos transformados;
- worktree final limpa após cada gate;
- commits publicados no branch canônico.

O warning de bundle superior a 500 kB permanece não bloqueante e não altera o contrato funcional do 6H.

## 7. Critérios de saída

| Critério | Resultado |
|---|---|
| Gantt derivado do domínio canônico | PASS |
| Sem persistência gráfica paralela | PASS |
| Baseline representada | PASS |
| Plano vigente representado | PASS |
| Forecast representado | PASS |
| Realizado representado | PASS |
| Desvios reproduzíveis | PASS |
| Atraso/adiantamento explicitável | PASS |
| Replanejamento rastreável pelas versões/contratos temporais | PASS |
| Hierarquia colapsável | PASS |
| Estado inicial condensado | PASS |
| Recolher tudo / Expandir tudo | PASS |
| Dependências não inventadas | PASS |
| Caminho crítico não inventado | PASS |
| Testes | PASS |
| Build | PASS |

## 8. Continuidade

Gate seguinte:

`17-B.5F.3C.6I — Agenda, Calendário e Eventos Operacionais`.

O 6I deve reutilizar a autoridade temporal, Jornada, iniciativas e ações já existentes; não deve transformar macrofases/fases/etapas em eventos nem duplicar o cronograma do Gantt.

**SKPE_17_B_5F_3C_6H = PASS/CLOSED.**