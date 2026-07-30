# Relatório de Inspeção e Decisão Arquitetural — FE-08

## 1. Identificação

- **Repositório:** `rrgestao/skpe-saas`
- **Branch inspecionada:** `feature/formulacao-estrategica-operacional`
- **Branch-base:** `develop`
- **Commit-base completo:** `db4eaa4a4c2db42384823b6f621e730d2a2d4b4c`
- **Commit-base curto:** `db4eaa4`
- **Mensagem:** `feat: adiciona iniciativas estrategicas portfolio e planos de acao`
- **Comparação remota no início da inspeção:** 13 commits à frente e 0 atrás de `develop`
- **Merge:** não realizado e não autorizado
- **Próxima etapa confirmada:** FE-08 — Monitoramento, Governança e Aprendizado Estratégico
- **Requisito:** `REQ-SKPE-FE-009`

---

## 2. Fontes inspecionadas

Foram inspecionadas as estruturas versionadas das etapas anteriores, com ênfase em:

- FE-00 — Fundação da Formulação e arquitetura compartilhada;
- FE-04 — Temas, Perspectivas, Objetivos e Mapa Estratégico;
- FE-05 — Indicadores, metas e benchmarking;
- FE-06 — OKRs, Resultados-Chave e desdobramento;
- FE-07 — Iniciativas, portfólio e planos de ação;
- autorizações, RLS, auditoria e privilégios;
- guardiões de imutabilidade estrutural;
- funções de prontidão e transição;
- projeções operacionais de KRs, OKRs, Iniciativas e resultados.

A inspeção foi realizada sobre o repositório remoto e os artefatos versionados. Não houve conexão com o banco nesta preparação.

---

## 3. Ponto exato de continuidade

```text
FE-07 concluída e publicada
↓
FE-08 — Monitoramento, Governança e Aprendizado Estratégico
```

Não foi encontrada etapa intermediária canônica que devesse preceder a FE-08.

---

## 4. Estruturas reutilizadas

### 4.1 Formulação e versionamento

Reutilizadas:

- `skpe_strategic_formulations`;
- escopo de organização e projeto;
- estados de elaboração, validação e aprovação;
- proteção de conteúdo aprovado;
- derivação de versões;
- auditoria operacional.

### 4.2 Mapa Estratégico

Reutilizadas:

- `skpe_strategic_themes`;
- `skpe_bsc_perspectives`;
- `skpe_strategic_objectives`;
- relações Tema → Objetivo → Indicador.

### 4.3 Indicadores e metas

Reutilizadas:

- `skpe_indicators`;
- `skpe_indicator_targets`;
- polaridade;
- linha de base;
- unidade;
- frequência;
- fonte;
- metas por período.

### 4.4 OKRs e KRs

Reutilizadas:

- `skpe_okr_cycles`;
- `skpe_okrs`;
- `skpe_key_results`;
- cálculo de progresso por polaridade;
- recálculo do progresso de OKR;
- guardião que separa conteúdo estrutural e operacional.

### 4.5 Iniciativas

Reutilizadas:

- `skpe_initiatives`;
- `skpe_initiative_portfolio_items`;
- `skpe_initiative_actions`;
- `skpe_initiative_risks`;
- `skpe_initiative_outcomes`;
- projeções atuais de progresso, custo, benefício, risco e saúde.

### 4.6 Segurança e auditoria

Reutilizadas:

- `skpe_operational_audit`;
- `skpe_assert_reason`;
- funções de autorização por módulo e organização;
- RLS;
- `SECURITY DEFINER`;
- `set search_path = ''`;
- revogação de DML para usuários autenticados.

---

## 5. Lacunas comprovadas

### 5.1 Ciclos de acompanhamento

Não havia entidade dedicada para:

- período de apuração;
- abertura e fechamento;
- coleta;
- análise;
- ratificação;
- snapshot.

### 5.2 Série histórica de KPIs

`skpe_indicators` define o Indicador, mas não armazena a série histórica observada.

### 5.3 Histórico de KRs

`skpe_key_results` mantém o estado corrente. A auditoria não substitui check-ins com confiança, saúde, previsão, bloqueios e evidências.

### 5.4 Histórico de Iniciativas

`skpe_initiatives` mantém a projeção atual, sem uma série periódica estruturada.

### 5.5 Histórico de resultados e benefícios

`skpe_initiative_outcomes` contém `current_value`, mas não uma sequência de medições por ciclo.

### 5.6 RAE

Não havia estrutura própria para reunião, pauta, itens, síntese, conclusões, ata e ratificação.

### 5.7 Decisões

A auditoria registra mutações, mas não representa deliberação, responsável, prazo, prioridade e escalonamento como objeto de governança.

### 5.8 Aprendizado

Não havia estrutura para evidência, interpretação, lição, impacto, recomendação e incorporação em revisão.

### 5.9 Snapshot

Não havia leitura oficial imutável e verificável do fechamento do ciclo.

### 5.10 Segregação de funções

As permissões da Formulação são excessivas para usuários que apenas registram desempenho ou conduzem governança.

### 5.11 Bypass de histórico

As RPCs operacionais legadas permitiriam atualizar projeções sem criar check-in FE-08.

---

## 6. Decisão arquitetural

### 6.1 Camada histórica separada

Adotou-se:

```text
estado corrente
+
histórico append-only
+
governança formal
+
snapshot imutável
```

Não foram criadas tabelas paralelas para Indicadores, KRs ou Iniciativas.

### 6.2 Projeção somente após validação

O check-in submetido não altera o estado oficial. A projeção é atualizada pela transição `validate`.

Essa decisão elimina o risco de um registro posteriormente rejeitado contaminar o estado oficial.

### 6.3 Dupla unicidade controlada

É permitida a coexistência de:

- um registro validado atual; e
- uma proposta submetida de correção.

A validação da proposta supersede o validado anterior.

### 6.4 Agregação

Foram implementadas:

- média por peso igual;
- média ponderada por `indicator.metadata.monitoringWeight`.

Peso ausente ou inválido recebe 1 e produz recomendação.

### 6.5 RAE imutável após ratificação

RAE, pauta e decisões estruturais não podem ser reeditadas depois da ratificação. Execução das decisões continua por transições auditadas.

### 6.6 Snapshot com SHA-256

O fechamento cria payload `jsonb`, versão, situação ratificada e hash SHA-256.

A reabertura não exclui o snapshot: ele é marcado como `superseded`.

### 6.7 Bloqueio das RPCs legadas

A execução autenticada foi revogada para:

- `update_skpe_key_result_progress`;
- `update_skpe_initiative_operational_progress`;
- `update_skpe_initiative_outcome_progress`.

---

## 7. Estruturas criadas

1. `skpe_monitoring_packages`;
2. `skpe_monitoring_cycles`;
3. `skpe_indicator_measurements`;
4. `skpe_key_result_check_ins`;
5. `skpe_initiative_check_ins`;
6. `skpe_initiative_outcome_measurements`;
7. `skpe_strategy_reviews`;
8. `skpe_strategy_review_items`;
9. `skpe_governance_decisions`;
10. `skpe_strategic_learnings`;
11. `skpe_performance_snapshots`.

---

## 8. Permissões criadas

- `strategic_monitoring.view`;
- `strategic_monitoring.manage`;
- `strategic_governance.manage`;
- `strategic_governance.ratify`.

Distribuição padrão:

- administradores e gestores: todas;
- editores: consulta e lançamento de monitoramento;
- aprovadores: consulta, governança e ratificação;
- visualizadores e visitantes: consulta.

A autorização continua limitada ao escopo organizacional.

---

## 9. Segurança aplicada

- RLS em 11 tabelas;
- políticas somente de leitura para `authenticated`;
- nenhuma política `ALL`;
- DML revogado para `public`, `anon` e `authenticated`;
- DML reservado ao `service_role` e às RPCs;
- funções públicas `SECURITY DEFINER`;
- `set search_path = ''`;
- justificativa obrigatória;
- auditoria operacional;
- funções internas sem execução autenticada;
- validação de escopo;
- snapshot protegido por gatilho;
- pacote estrutural protegido após aprovação.

---

## 10. Prontidão implementada

### Pacote

Bloqueia:

- ausência de pacote;
- ausência de responsáveis;
- KPI ativo sem frequência.

Recomenda:

- KPI sem responsável;
- peso explícito ausente ou inválido.

### Ciclo

Bloqueia:

- KPI sem medição;
- KR sem check-in;
- Iniciativa sem check-in;
- RAE não ratificada;
- decisão crítica sem responsável ou prazo;
- registros não validados, quando exigido;
- confiança de KR não avaliada, quando exigida.

Recomenda:

- evidência ausente;
- decisão vencida;
- ciclo atrasado.

---

## 11. Limitações objetivas

Não foram realizados nesta sessão:

- execução no Supabase Web;
- teste de catálogo real;
- teste autenticado;
- carga de dados;
- commit;
- push;
- interface React;
- merge.

A validação realizada é estática e documental.

---

## 12. Riscos remanescentes para execução

1. divergência entre catálogo remoto e migrations versionadas;
2. função ou constraint criada manualmente no Supabase e não presente no repositório;
3. papel organizacional customizado não contemplado pela distribuição padrão;
4. dados legados inconsistentes com novas constraints;
5. extensão `pgcrypto` instalada em esquema distinto;
6. metadados antigos com peso não numérico;
7. testes funcionais ainda não executados com usuário autenticado.

O verificador consolidado foi preparado para reduzir esses riscos.

---

## 13. Decisão final

```text
APROVADO PARA EXECUÇÃO CONTROLADA NO SUPABASE WEB
```

Condições:

1. executar a migration integralmente;
2. executar o verificador;
3. confirmar todos os controles como `OK`;
4. realizar testes autenticados mínimos;
5. somente então preparar commit e push;
6. não realizar merge.

---

## 14. Situação

```text
PACOTE TÉCNICO PREPARADO
MIGRATION PREPARADA
VERIFICADOR PREPARADO
DOCUMENTAÇÃO PREPARADA
EXECUÇÃO NO SUPABASE PENDENTE
VALIDAÇÃO FUNCIONAL PENDENTE
COMMIT PENDENTE
PUSH PENDENTE
MERGE NÃO REALIZADO
```
