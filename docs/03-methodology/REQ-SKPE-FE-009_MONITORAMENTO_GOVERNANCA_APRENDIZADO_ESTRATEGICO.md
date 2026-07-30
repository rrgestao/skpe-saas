# REQ-SKPE-FE-009 — Monitoramento, Governança e Aprendizado Estratégico

**Projeto:** Plataforma SPARKs — Módulo SK-PE
**Etapa:** FE-08 — Monitoramento, Governança e Aprendizado Estratégico
**Aplicabilidade:** multi-organização e multiprojeto
**Branch canônica:** `feature/formulacao-estrategica-operacional`
**Commit-base inspecionado:** `db4eaa4a4c2db42384823b6f621e730d2a2d4b4c`
**Branch-base:** `develop`
**Situação:** pacote técnico preparado; execução no PostgreSQL pendente
**Interface React:** fora do escopo desta entrega

---

## 1. Objetivo

Implantar a camada operacional, histórica, auditável e segura que transforma a Formulação Estratégica aprovada em um ciclo contínuo de:

```text
medição
→ análise
→ decisão
→ responsabilização
→ correção
→ aprendizado
→ revisão controlada
```

A FE-08 deve permitir acompanhar, no tempo:

- Indicadores Estratégicos e suas metas;
- Resultados-Chave e OKRs;
- Iniciativas, programas, projetos e ações estruturantes;
- resultados, benefícios, marcos, riscos, custos e saúde das Iniciativas;
- desempenho dos Objetivos e Temas Estratégicos;
- progresso agregado em direção à Visão de Longo Prazo;
- Reuniões de Análise da Estratégia — RAE;
- decisões, responsáveis e prazos;
- aprendizados e recomendações para revisão da estratégia;
- snapshots imutáveis do desempenho apresentado à governança.

---

## 2. Premissas arquiteturais

### 2.1 Formulação aprovada é imutável

A FE-08 não altera retroativamente Missão, Visão, Valores, Temas, Objetivos, Indicadores, metas, OKRs ou portfólio aprovados.

A separação canônica é:

```text
Formulação aprovada
≠
execução e acompanhamento
```

### 2.2 Estado corrente não substitui histórico

As tabelas existentes continuam sendo a projeção operacional atual. A FE-08 adiciona registros append-only para demonstrar a evolução no tempo.

### 2.3 Validação precede atualização da projeção

Check-ins e medições são inicialmente `submitted`. A projeção corrente de KR, Iniciativa ou resultado somente é atualizada quando o registro é formalmente `validated`.

Esse desenho impede que um dado rejeitado permaneça indevidamente como estado oficial.

### 2.4 Correção por supersessão

Registros históricos não são sobrescritos. Uma correção:

1. cria novo registro submetido;
2. preserva o registro validado anterior até a nova validação;
3. supersede o validado anterior somente quando o novo registro é validado;
4. mantém a cadeia de rastreabilidade.

### 2.5 Um ciclo, uma leitura oficial

Cada ciclo pode conter várias versões históricas, mas apenas:

- um registro submetido corrente; e
- um registro validado corrente

por Indicador, KR, Iniciativa ou resultado.

---

## 3. Escopo funcional

### 3.1 Configuração metodológica

Cada Formulação deve possuir um pacote FE-08 com:

- frequência dos ciclos;
- frequência das RAEs;
- política de sobreposição de ciclos;
- obrigatoriedade de evidências;
- obrigatoriedade de validação da qualidade dos dados;
- exigência de confiança para KRs;
- permissão ou bloqueio de ajuste manual de progresso;
- atualidade esperada dos dados;
- tolerância de atraso;
- política de agregação;
- faixas de criticidade e desempenho;
- responsáveis por monitoramento e governança.

### 3.2 Ciclos de monitoramento

Tipos admitidos:

- mensal;
- trimestral;
- semestral;
- anual;
- customizado.

Fluxo:

```text
planned
→ open
→ collecting
→ under_review
→ pending_ratification
→ closed
```

Estados excepcionais:

```text
cancelled
reopened
```

### 3.3 Medições de Indicadores Estratégicos

Cada medição registra:

- ciclo;
- Indicador e Meta aplicável;
- data e período;
- valor observado;
- desempenho automático;
- eventual ajuste manual autorizado;
- desempenho efetivo;
- qualidade do dado;
- fonte e referência;
- evidência;
- observações;
- situação de validação;
- registro supersedido.

### 3.4 Check-ins de Resultados-Chave

Cada check-in registra:

- valor atual;
- progresso automático;
- eventual ajuste manual;
- progresso efetivo;
- situação operacional;
- saúde;
- confiança;
- previsão de valor e data;
- impedimentos;
- observações e evidências.

Após validação, o KR e seu OKR são recalculados.

### 3.5 Check-ins de Iniciativas

Cada check-in registra:

- progresso;
- situação operacional;
- saúde;
- nível de risco;
- custo realizado;
- benefício realizado;
- previsão de término;
- marcos;
- atrasos;
- bloqueios;
- decisão necessária;
- observações e evidências.

Após validação, a projeção operacional da Iniciativa é atualizada.

### 3.6 Medições de resultados e benefícios

Resultados quantitativos exigem valor observado. Resultados qualitativos exigem avaliação textual.

Após validação, são atualizados:

- valor atual;
- situação;
- realização;
- desempenho mais recente.

### 3.7 Reuniões de Análise da Estratégia — RAE

A RAE deve permitir:

- agenda e identificação;
- data programada e realizada;
- presidência e secretaria;
- participantes;
- síntese executiva;
- conclusões;
- referência da ata;
- itens analisados;
- causas, recomendações e decisões;
- ratificação formal.

Fluxo:

```text
draft
→ scheduled
→ in_progress
→ pending_ratification
→ ratified
→ closed
```

A RAE ratificada é imutável quanto ao seu conteúdo estrutural.

### 3.8 Itens de análise

Um item da RAE deve apontar exatamente para uma entidade principal:

- Tema Estratégico;
- Objetivo Estratégico;
- Indicador;
- OKR;
- Resultado-Chave;
- Iniciativa;
- ação;
- risco;
- resultado ou benefício.

Não são utilizados identificadores polimórficos sem chave estrangeira.

### 3.9 Decisões de governança

Cada decisão registra:

- código e título;
- decisão e fundamento;
- tipo e prioridade;
- responsável e prazo;
- escalonamento;
- vínculo com item da RAE;
- vínculo opcional com ação de Iniciativa;
- situação;
- conclusão;
- ratificação.

### 3.10 Aprendizado estratégico

Cada aprendizado registra:

- evidência;
- interpretação;
- lição;
- impacto;
- recomendação;
- decisão de governança;
- situação;
- eventual Formulação de revisão.

Fluxo controlado:

```text
identified
→ under_analysis
→ accepted ou rejected
→ incorporated
→ archived
```

### 3.11 Snapshot do ciclo

O fechamento gera um snapshot imutável contendo:

- desempenho consolidado;
- medições correntes;
- check-ins de KRs;
- check-ins de Iniciativas;
- resultados e benefícios;
- RAEs;
- decisões;
- aprendizados;
- data de geração;
- versão;
- SHA-256.

---

## 4. Estruturas reutilizadas

A FE-08 reutiliza, sem duplicação:

- `skpe_projects`;
- `skpe_strategic_formulations`;
- `skpe_strategic_themes`;
- `skpe_bsc_perspectives`;
- `skpe_strategic_objectives`;
- `skpe_indicators`;
- `skpe_indicator_targets`;
- `skpe_okrs`;
- `skpe_key_results`;
- `skpe_initiatives`;
- `skpe_initiative_portfolio_items`;
- `skpe_initiative_actions`;
- `skpe_initiative_risks`;
- `skpe_initiative_outcomes`;
- `skpe_operational_audit`;
- funções transversais de autorização, justificativa e auditoria.

---

## 5. Estruturas criadas

### 5.1 `skpe_monitoring_packages`

Configuração e validação metodológica da FE-08 por Formulação.

### 5.2 `skpe_monitoring_cycles`

Períodos formais de coleta, análise, RAE, ratificação e fechamento.

### 5.3 `skpe_indicator_measurements`

Série histórica dos KPIs estratégicos.

### 5.4 `skpe_key_result_check_ins`

Histórico dos KRs.

### 5.5 `skpe_initiative_check_ins`

Histórico de execução das Iniciativas.

### 5.6 `skpe_initiative_outcome_measurements`

Histórico de resultados, benefícios e critérios de sucesso.

### 5.7 `skpe_strategy_reviews`

RAEs e demais instâncias formais de análise.

### 5.8 `skpe_strategy_review_items`

Itens estruturados analisados em cada RAE.

### 5.9 `skpe_governance_decisions`

Deliberações, responsabilização e acompanhamento.

### 5.10 `skpe_strategic_learnings`

Aprendizados e insumos para revisão controlada.

### 5.11 `skpe_performance_snapshots`

Leitura oficial e imutável de cada fechamento.

---

## 6. Agregação de desempenho

Políticas suportadas:

```text
equal_weight
explicit_weight
```

### 6.1 Peso igual

Todos os Indicadores Estratégicos válidos recebem peso 1.

### 6.2 Peso explícito

O peso é obtido de:

```json
{
  "monitoringWeight": 2.5
}
```

no `metadata` do Indicador.

Peso ausente, inválido ou não positivo recebe valor 1 e gera recomendação metodológica.

### 6.3 Cadeia de agregação

```text
Medição
→ Indicador
→ Objetivo Estratégico
→ Tema Estratégico
→ progresso em direção à Visão
```

O resultado consolidado nunca substitui a análise qualitativa da RAE.

---

## 7. Permissões

### `strategic_monitoring.view`

Consulta ciclos, medições, check-ins, desempenho, RAEs, decisões, aprendizados e snapshots.

### `strategic_monitoring.manage`

Abre ciclos e registra medições e check-ins.

### `strategic_governance.manage`

Prepara RAEs, itens, decisões e aprendizados, além de validar ou rejeitar registros.

### `strategic_governance.ratify`

Ratifica RAEs e decisões, fecha ou reabre ciclos e incorpora aprendizados.

A segregação preserva:

```text
editar estratégia
≠
informar desempenho
≠
validar dados
≠
ratificar governança
```

---

## 8. Segurança obrigatória

Todas as estruturas devem manter:

- RLS habilitada;
- leitura autorizada por organização;
- DML revogado para `public`, `anon` e `authenticated`;
- escrita por RPCs `SECURITY DEFINER`;
- `set search_path = ''`;
- justificativa obrigatória;
- auditoria antes/depois;
- escopo de organização, projeto e Formulação;
- funções internas não executáveis por `authenticated`;
- nenhuma política `ALL`;
- snapshots imutáveis;
- correção por supersessão;
- fechamento e reabertura controlados.

### 8.1 Bloqueio das mutações legadas

As seguintes RPCs deixam de ser executáveis por `authenticated` para impedir alteração da projeção sem histórico FE-08:

- `update_skpe_key_result_progress`;
- `update_skpe_initiative_operational_progress`;
- `update_skpe_initiative_outcome_progress`.

Permanecem reservadas ao `service_role` para compatibilidade administrativa controlada.

---

## 9. Prontidão do pacote

Bloqueios:

- pacote inexistente;
- responsável pelo monitoramento ausente;
- responsável pela governança ausente;
- Indicador ativo sem frequência de apuração.

Recomendações:

- Indicador ativo sem responsável;
- agregação explícita sem peso positivo no Indicador.

A Formulação somente pode avançar quando o pacote estiver validado.

---

## 10. Prontidão do ciclo

Bloqueios para fechamento:

- KPI ativo sem medição;
- KR ativo sem check-in;
- Iniciativa selecionada sem check-in;
- RAE não ratificada;
- decisão crítica sem responsável ou prazo;
- registros submetidos sem validação, quando a qualidade for obrigatória;
- KR sem confiança avaliada, quando exigido.

Recomendações:

- ausência de evidência;
- decisão vencida;
- ciclo atrasado;
- dados com baixa qualidade;
- bloqueios e riscos críticos.

---

## 11. RPCs públicas

### Pacote

- `get_skpe_monitoring_package_readiness`;
- `configure_skpe_monitoring_package`;
- `transition_skpe_monitoring_package`.

### Ciclos e dados

- `open_skpe_monitoring_cycle`;
- `record_skpe_indicator_measurement`;
- `record_skpe_key_result_check_in`;
- `record_skpe_initiative_check_in`;
- `record_skpe_initiative_outcome_measurement`;
- `transition_skpe_monitoring_cycle`;
- `transition_skpe_monitoring_record`.

### Governança

- `upsert_skpe_strategy_review`;
- `upsert_skpe_strategy_review_item`;
- `record_skpe_governance_decision`;
- `transition_skpe_governance_decision`;
- `record_skpe_strategic_learning`;
- `transition_skpe_strategic_learning`;
- `ratify_skpe_strategy_review`.

### Desempenho e encerramento

- `get_skpe_monitoring_readiness`;
- `get_skpe_strategic_performance`;
- `close_skpe_monitoring_cycle`;
- `reopen_skpe_monitoring_cycle`;
- `get_skpe_monitoring_cycle`;
- `get_skpe_monitoring_audit`.

---

## 12. Versionamento e clonagem

### Clonar para nova Formulação

- configuração metodológica;
- cadências;
- políticas;
- faixas de desempenho;
- responsáveis padrão;
- metadados de configuração.

### Não clonar

- ciclos;
- medições;
- check-ins;
- progresso;
- custos realizados;
- benefícios realizados;
- RAEs;
- decisões;
- snapshots;
- auditoria.

Aprendizados permanecem históricos e podem apontar para uma revisão-alvo.

---

## 13. Fora de escopo

A FE-08 não implementa:

- interface React;
- dashboard visual definitivo;
- construtor de relatórios;
- apresentação automatizada;
- integração contábil completa;
- timesheet;
- Gantt detalhado;
- módulo corporativo completo de riscos;
- armazenamento documental paralelo;
- notificações externas;
- dados específicos da COOTAQUARA ou de qualquer cliente.

---

## 14. Critérios de aceite técnico

A etapa somente pode ser declarada tecnicamente executada quando:

1. a migration for executada integralmente no `skpe-saas-dev`;
2. não houver erro no PostgreSQL;
3. o verificador consolidado retornar todos os controles como `OK`;
4. forem realizados testes autenticados mínimos;
5. os arquivos forem instalados somente pela lista branca;
6. `git diff --check` não indicar erro;
7. SHA-256 for recalculado;
8. commit e push forem realizados na branch correta;
9. SHA local e remoto forem idênticos;
10. nenhum merge em `develop` ou `main` for realizado sem autorização expressa.

---

## 15. Situação desta entrega

```text
DESENHO E MIGRATION PREPARADOS
VERIFICADOR PREPARADO
DOCUMENTAÇÃO PREPARADA
VALIDAÇÃO ESTÁTICA LOCAL REALIZADA
EXECUÇÃO NO SUPABASE PENDENTE
TESTE AUTENTICADO PENDENTE
COMMIT PENDENTE
PUSH PENDENTE
MERGE NÃO AUTORIZADO
```
