# REQ-SKPE-FE-006 — Indicadores Estratégicos, Metas de Longo Prazo e Benchmarking

**Projeto:** Plataforma SPARKs — Módulo SK-PE  
**Etapa:** FE-05 — Indicadores Estratégicos, Metas de Longo Prazo e Benchmarking  
**Situação:** pacote técnico preparado para execução controlada no Supabase Web; ainda não executado nem validado no banco  
**Aplicabilidade:** multi-organização e multiprojeto, sem conteúdo fixo da COOTAQUARA  
**Branch canônica:** `feature/formulacao-estrategica-operacional`  
**Base técnica inspecionada:** commit `3df856baa8706cc2951b74d1a69fbe0350925999`

---

## 1. Objetivo

Implantar a capacidade operacional, versionada, auditada e segura para gerir:

- Indicadores Estratégicos vinculados aos Objetivos Estratégicos;
- definição, fórmula, método de cálculo, unidade e polaridade;
- frequência de apuração e fonte de dados;
- linha de base e data de referência;
- responsáveis e áreas responsáveis;
- categorias metodológicas dos Indicadores;
- métodos de coleta e potencial de automação;
- Metas de Longo Prazo;
- metas anuais e intermediárias, quando metodologicamente aplicáveis;
- referências de benchmarking vinculadas ao Indicador ou à Meta;
- verificação e ativação das referências de benchmarking;
- prontidão metodológica específica da FE-05;
- submissão, validação e devolução do pacote;
- bloqueio do avanço da Formulação enquanto a FE-05 estiver incompleta ou não validada;
- consulta consolidada e histórico auditável.

A FE-05 não implementa integralmente OKRs, Resultados-Chave, indicadores de Resultados-Chave ou Iniciativas.

---

## 2. Resultado da inspeção técnica

A inspeção confirmou que as estruturas centrais já existem e devem ser reaproveitadas:

- `skpe_indicators`;
- `skpe_indicator_targets`;
- `skpe_benchmark_references`;
- `skpe_strategic_objectives`;
- `skpe_strategic_formulations`;
- `skpe_operational_audit`.

Também foram confirmados:

- RLS de leitura para as três tabelas da FE-05;
- ausência de escrita direta para `authenticated`;
- proteção transversal das Formulações fora dos estados editáveis;
- auditoria operacional centralizada;
- clonagem de Indicadores, Metas e Benchmarking entre versões;
- unicidade de código por versão da Formulação;
- índices básicos já existentes;
- readiness global que já reconhece KPI, Meta de Longo Prazo e benchmarking.

### 2.1 Lacuna real constatada

Não existe um cabeçalho próprio para controlar o ciclo de elaboração, submissão e validação do conjunto da FE-05. Por isso, a única nova tabela proposta é:

- `skpe_indicator_packages`.

Essa tabela não duplica Indicadores, Metas ou Benchmarking. Ela registra somente:

- o estado do pacote FE-05;
- as regras metodológicas configuráveis;
- datas e responsáveis pela submissão e validação;
- notas de validação;
- metadados do pacote.

### 2.2 Decisão para preservar o versionamento existente

Os atributos adicionais dos Indicadores são mantidos em `skpe_indicators.metadata`, pois a função de clonagem já preserva esse JSON entre versões. O contrato adotado é:

```json
{
  "calculationMethod": "Descrição estruturada do método de cálculo",
  "indicatorCategory": "financial | customer_market | internal_process | people_learning | governance | social | environmental | sustainability | other",
  "collectionMethod": "Descrição do procedimento de coleta",
  "collectionAutomatable": true,
  "responsibleArea": "Área organizacional responsável",
  "baselineRequired": true,
  "validationStatus": "draft | pending_validation | validated",
  "validatedAt": "timestamp opcional",
  "validatedBy": "uuid opcional"
}
```

A propriedade `baselineRequired` é opcional e, quando informada, sobrescreve a regra padrão do pacote para o Indicador específico.

Essa decisão evita reescrever a função extensa de clonagem da FE-01 e preserva integralmente:

- o vínculo do Indicador com o novo Objetivo clonado;
- as Metas vigentes;
- as referências de benchmarking;
- os metadados metodológicos;
- a rastreabilidade da origem.

---

## 3. Modelo operacional do pacote FE-05

### 3.1 Estados

```text
Em elaboração
→ Pendente de validação
→ Validado
```

A devolução retorna para:

```text
Em elaboração
```

Qualquer mutação posterior em Indicador, Meta, Benchmarking ou configuração metodológica:

1. invalida a validação anterior;
2. retorna o pacote para `in_elaboration`;
3. limpa datas e responsáveis pela submissão e validação;
4. redefine a situação de validação dos Indicadores para `draft`;
5. preserva o histórico de auditoria;
6. exige nova submissão e validação.

### 3.2 Configurações metodológicas

Cada versão pode configurar:

- `baseline_required`: exige linha de base por padrão;
- `intermediate_targets_recommended`: recomenda metas anuais ou intermediárias;
- `benchmark_recommended`: recomenda benchmarking verificado ou ativo;
- `automated_collection_recommended`: recomenda método de coleta automatizável;
- `max_indicators_per_objective`: limite recomendado por Objetivo;
- `financial_concentration_threshold`: limiar de concentração financeira;
- `baseline_freshness_months`: atualidade recomendada da linha de base.

Configuração padrão:

```text
baseline_required = true
intermediate_targets_recommended = true
benchmark_recommended = true
automated_collection_recommended = true
max_indicators_per_objective = 5
financial_concentration_threshold = 60%
baseline_freshness_months = 24
```

---

## 4. Indicadores Estratégicos

Cada Indicador Estratégico registra:

- código;
- nome;
- definição;
- Objetivo Estratégico vinculado;
- fórmula ou expressão de cálculo;
- método de cálculo;
- unidade de medida;
- polaridade;
- frequência de apuração;
- fonte de dados;
- linha de base e data;
- responsável;
- categoria metodológica;
- método de coleta;
- possibilidade de automação;
- área responsável;
- situação operacional;
- situação de validação do item;
- metadados;
- auditoria.

### 4.1 Escopo preservado

A FE-05 opera somente Indicadores com:

```text
indicator_scope = strategic_kpi
```

Indicadores vinculados a Resultados-Chave permanecem fora desta etapa.

### 4.2 Polaridades aceitas

```text
higher_is_better
lower_is_better
target_is_better
range_is_better
```

### 4.3 Frequências aceitas

```text
daily
weekly
monthly
bimonthly
quarterly
semiannual
annual
on_demand
```

### 4.4 Categorias metodológicas

```text
financial
customer_market
internal_process
people_learning
governance
social
environmental
sustainability
other
```

---

## 5. Metas

A FE-05 permite:

- Meta de Longo Prazo;
- meta anual;
- meta intermediária.

Metas de ciclo permanecem reservadas ao desdobramento futuro de OKRs.

Cada Meta registra:

- Indicador vinculado;
- tipo;
- período inicial e final;
- valor-alvo;
- valor mínimo;
- valor de desafio;
- tolerâncias inferior e superior;
- responsável;
- situação;
- metadados;
- auditoria.

### 5.1 Regras centrais

- somente uma Meta de Longo Prazo vigente por Indicador;
- período contido no horizonte da Formulação;
- coerência com a polaridade e a linha de base;
- `range_is_better` exige faixa de tolerância válida;
- a substituição histórica usa `superseded`, sem exclusão física.

---

## 6. Benchmarking

Cada referência pode registrar:

- Indicador;
- Meta relacionada, quando aplicável;
- tipo de benchmarking;
- organização de referência;
- fonte;
- referência ou localização da fonte;
- período de referência;
- valor de benchmark;
- aplicabilidade;
- análise de lacuna;
- notas;
- situação;
- data e responsável pela verificação;
- metadados;
- auditoria.

### 6.1 Tipos aceitos

```text
internal
sector
market
best_practice
regulatory
```

### 6.2 Estados da referência

```text
draft
→ verified
→ active
```

Também são permitidos:

```text
return_to_draft
archive
```

A verificação e ativação exigem a permissão de validação da Formulação. A edição permanece limitada aos estados editáveis da Formulação.

---

## 7. Prontidão metodológica da FE-05

### 7.1 Pendências bloqueantes

- Objetivo Estratégico ativo sem Indicador Estratégico ativo;
- Indicador sem código;
- Indicador sem nome;
- Indicador sem definição clara;
- Indicador sem fórmula ou expressão de cálculo;
- Indicador sem método de cálculo;
- Indicador sem unidade de medida;
- Indicador sem polaridade válida;
- Indicador sem frequência de apuração;
- Indicador com frequência fora do catálogo;
- Indicador sem fonte de dados;
- Indicador sem linha de base quando exigida;
- Indicador sem Meta de Longo Prazo vigente;
- mais de uma Meta de Longo Prazo vigente;
- Meta incompatível com a polaridade;
- Meta fora do horizonte da Formulação;
- Indicador vinculado a Objetivo, Formulação, organização ou projeto incompatível;
- Meta vinculada a Indicador ou escopo incompatível;
- Benchmarking vinculado a Indicador, Meta ou escopo incompatível;
- Indicadores duplicados pelo mesmo nome no mesmo Objetivo;
- referências de benchmarking duplicadas;
- pacote ainda não validado para avanço da Formulação.

### 7.2 Recomendações

- Indicador sem responsável;
- Indicador sem benchmarking verificado ou ativo;
- ausência de metas anuais ou intermediárias;
- excesso de Indicadores por Objetivo;
- concentração excessiva em Indicadores financeiros;
- método de coleta não automatizável ou sem avaliação de automação;
- método de coleta não documentado;
- periodicidade exclusivamente anual em horizonte plurianual;
- linha de base desatualizada;
- Indicador sem categoria metodológica.

### 7.3 Controles distintos

A prontidão retorna:

```text
readyForValidation
readyForFormulation
```

- `readyForValidation`: considera a completude do conteúdo FE-05;
- `readyForFormulation`: exige completude e pacote validado.

### 7.4 Exclusões explícitas

```text
keyResultIndicatorsRequiredInFe05 = false
okrRequiredInFe05 = false
initiativeRequiredInFe05 = false
```

---

## 8. Operações públicas

```text
configure_skpe_indicator_package

upsert_skpe_strategic_indicator
archive_skpe_strategic_indicator

upsert_skpe_indicator_target
supersede_skpe_indicator_target

upsert_skpe_benchmark_reference
transition_skpe_benchmark_reference

get_skpe_indicators_readiness
transition_skpe_indicator_package
get_skpe_indicators_package
get_skpe_indicators_audit
```

## 8.1 Funções internas protegidas

```text
ensure_skpe_indicator_package
skpe_invalidate_indicator_package
skpe_guard_formulation_indicators_ready
```

Somente `service_role` recebe execução explícita das funções internas.

---

## 9. Consulta consolidada

`get_skpe_indicators_package` devolve um único JSON com:

- Formulação;
- cabeçalho do pacote;
- Objetivos Estratégicos ativos;
- Indicadores Estratégicos;
- Metas;
- referências de benchmarking;
- prontidão;
- regras metodológicas;
- contagens e recomendações.

---

## 10. Segurança

A FE-05 preserva o padrão transversal consolidado:

- funções públicas `SECURITY DEFINER`;
- `set search_path = ''`;
- validação de organização, projeto, Formulação e Objetivo;
- bloqueio fora de `draft` e `in_elaboration`;
- justificativa mínima obrigatória;
- auditoria operacional;
- leitura por RLS;
- nenhuma política `ALL` para `authenticated`;
- nenhum privilégio direto de `INSERT`, `UPDATE` ou `DELETE` para `authenticated`;
- funções internas não executáveis por `authenticated`;
- DML operacional preservado para `service_role`.

---

## 11. Auditoria

As mutações registram em `skpe_operational_audit`:

- organização;
- projeto;
- tipo da entidade;
- identificador;
- código da ação;
- justificativa;
- estado anterior;
- estado posterior;
- usuário;
- data e hora.

Entidades utilizadas:

```text
indicator_package
strategic_indicator
indicator_target
benchmark_reference
```

---

## 12. Integração com o versionamento

A função de clonagem existente já:

- clona Indicadores;
- remapeia o vínculo para o Objetivo Estratégico da nova versão;
- clona Metas vigentes;
- clona referências de benchmarking;
- redefine situações para rascunho;
- preserva metadados e origem.

O pacote FE-05 é criado de forma controlada na nova versão e herda suas configurações metodológicas do pacote da Formulação de origem.

Não é necessário reescrever a função de clonagem.

---

## 13. Artefatos desta entrega

```text
supabase/migrations/
20260730070000_create_strategic_indicators_targets_and_benchmarking_operations.sql

supabase/verification/
verificar_fe05_indicadores_metas_benchmarking.sql

docs/03-methodology/
REQ-SKPE-FE-006_INDICADORES_METAS_LONGO_PRAZO_BENCHMARKING.md
```

A migration não insere dados da COOTAQUARA nem de qualquer outra organização.

---

## 14. Estado objetivo desta preparação

Foi concluída a preparação estática dos artefatos técnicos. Até o momento deste documento:

- a migration não foi executada no Supabase;
- a verificação não foi executada no Supabase;
- nenhum commit foi criado;
- nenhum push foi realizado;
- nenhum merge foi realizado.

A validação técnica definitiva depende da execução integral no SQL Editor do projeto `skpe-saas-dev` e da obtenção de evidência objetiva do script de verificação.
