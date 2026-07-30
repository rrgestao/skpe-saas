# REQ-SKPE-FE-007 — OKRs, Resultados-Chave e Desdobramento Estratégico

**Projeto:** Plataforma SPARKs — Módulo SK-PE<br>
**Etapa:** FE-06 — OKRs, Resultados-Chave e Desdobramento Estratégico<br>
**Aplicabilidade:** multi-organização e multiprojeto, sem customização por organização<br>
**Branch canônica:** `feature/formulacao-estrategica-operacional`<br>
**Commit-base inspecionado:** `b428c8c8e2d0663b88e16271ca2f9554a32534cb`<br>
**Situação deste documento:** pacote técnico preparado; execução e validação no Supabase pendentes

---

## 1. Objetivo

Implantar a capacidade operacional, segura, versionada e auditável para que uma organização possa, quando metodologicamente aplicável:

- configurar a adoção de OKRs por versão da Formulação Estratégica;
- manter ciclos anuais, semestrais, trimestrais ou customizados;
- desdobrar Objetivos Estratégicos em OKRs de ciclo;
- vincular um OKR a um ou mais Objetivos Estratégicos;
- manter Resultados-Chave quantitativos e mensuráveis;
- registrar linha de base, alvo, valor atual, unidade, polaridade, método, fonte e frequência;
- atribuir responsáveis e áreas responsáveis;
- ponderar Resultados-Chave;
- calcular progresso dos KRs e dos OKRs;
- registrar alinhamentos, dependências e hierarquias entre OKRs;
- submeter, validar e devolver o pacote FE-06;
- consultar prontidão, conteúdo consolidado e histórico de auditoria;
- preservar e remapear o conteúdo ao criar revisão da Formulação.

A FE-06 não torna OKRs obrigatórios para todas as organizações.

---

## 2. Separação metodológica

### 2.1 Indicador Estratégico

Mede continuamente o desempenho de um Objetivo Estratégico de longo prazo. É administrado pela FE-05.

### 2.2 Meta de Longo Prazo

Define o resultado esperado para o horizonte da Formulação Estratégica. É administrada pela FE-05.

### 2.3 OKR

Representa um compromisso qualitativo de resultado para um ciclo de gestão delimitado. Não substitui o Objetivo Estratégico do BSC e não deve duplicar sua redação.

### 2.4 Resultado-Chave

Expressa quantitativamente a evidência de alcance do OKR. Deve possuir linha de base quando exigida, alvo, unidade, polaridade, método e fonte de dados.

### 2.5 Iniciativa

Representa projeto, programa, melhoria, processo ou ação executada para contribuir com um ou mais Resultados-Chave. A FE-06 apenas preserva os vínculos existentes; a gestão completa de Iniciativas permanece em etapa posterior.

---

## 3. Resultado da inspeção técnica

### 3.1 Estruturas existentes reutilizadas

A solução reutiliza integralmente:

- `skpe_okr_cycles`;
- `skpe_okrs`;
- `skpe_okr_objectives`;
- `skpe_key_results`;
- `skpe_indicators`;
- `skpe_indicator_targets`;
- `skpe_strategic_objectives`;
- `skpe_strategic_formulations`;
- `skpe_initiative_key_results`;
- `skpe_operational_audit`.

Não são criadas tabelas paralelas para ciclos, OKRs ou Resultados-Chave.

### 3.2 Lacunas reais comprovadas

Foram identificadas somente as seguintes insuficiências:

1. ausência de cabeçalho de governança e aplicabilidade do pacote FE-06;
2. ausência de estrutura para alinhamentos e dependências entre OKRs;
3. ausência de situação individual de validação no registro do OKR;
4. ausência de operações públicas auditadas e prontidão específica da FE-06;
5. incompatibilidade entre o bloqueio estrutural da Formulação e a necessidade de acompanhar progresso após a aprovação.

### 3.3 Estruturas novas estritamente necessárias

A migration cria somente:

- `skpe_okr_packages`;
- `skpe_okr_alignments`.

Também acrescenta apenas a coluna:

- `skpe_okrs.validation_status`.

---

## 4. Configurações metodológicas por Formulação

Cada versão pode configurar:

| Configuração | Padrão | Regra |
|---|---:|---|
| `okr_enabled` | `false` | adoção opt-in; desabilitado não bloqueia a Formulação |
| `okr_required_for_all_objectives` | `false` | não exige OKR para todos os OEs por padrão |
| `okr_cycle_required` | `true` | OKRs habilitados exigem ciclo válido |
| `minimum_key_results_per_okr` | `3` | referência metodológica mínima |
| `maximum_key_results_per_okr` | `5` | limite de foco por OKR |
| `key_result_baseline_required` | `true` | exige base comparável para o progresso |
| `okr_owner_required` | `false` | responsável é recomendado, não universalmente obrigatório |
| `key_result_owner_required` | `false` | pode ser ativado pela organização |
| `key_result_owner_recommended` | `true` | gera recomendação quando ausente |
| `key_result_weights_required` | `false` | ponderação é opcional por padrão |
| `okr_alignment_enabled` | `true` | permite alinhamentos e dependências |
| `automatic_progress_calculation` | `true` | cálculo automático preferencial |
| `allow_manual_progress_override` | `false` | substituição manual somente por decisão explícita |
| `cycle_overlap_policy` | `warn` | `allow`, `warn` ou `block` |
| `clone_progress_policy` | `reset_to_baseline` | não herda progresso operacional como novo ponto de partida |

Os padrões preservam flexibilidade metodológica sem enfraquecer a mensurabilidade.

---

## 5. Modelo de ciclos

A estrutura existente admite:

- `annual`;
- `semester`;
- `quarter`;
- `custom`.

Regras:

1. o ciclo pertence a uma Formulação, organização e projeto;
2. o período final não pode anteceder o inicial;
3. o ciclo não pode ultrapassar o horizonte da Formulação;
4. sobreposições seguem a política configurada;
5. encerramento muda a situação para `completed`;
6. reabertura é auditada e bloqueada para Formulações substituídas ou arquivadas;
7. ciclos encerrados não recebem novas medições até reabertura controlada.

Encerramento e reabertura são transições operacionais e não alteram a definição metodológica validada do pacote.

---

## 6. Regras dos OKRs

Cada OKR utiliza a tabela existente `skpe_okrs` e pode registrar:

- código;
- título;
- descrição;
- ciclo;
- responsável;
- área responsável;
- prioridade;
- situação;
- progresso;
- racional;
- ordem de exibição;
- OKR pai;
- metadados;
- situação de validação;
- auditoria.

A área responsável utiliza o domínio organizacional `ORGANIZATIONAL_AREA`, sem criar cadastro paralelo.

O vínculo com Objetivos Estratégicos permanece em `skpe_okr_objectives` e admite:

- múltiplos OEs;
- OE principal;
- peso de contribuição;
- notas.

---

## 7. Regras dos Resultados-Chave

Cada KR utiliza `skpe_key_results` e registra:

- código;
- nome;
- definição;
- OKR;
- Objetivo Estratégico principal compatível;
- linha de base;
- alvo;
- valor atual;
- unidade;
- polaridade;
- fórmula;
- método de cálculo;
- fonte de dados;
- frequência de acompanhamento;
- período;
- responsável;
- área responsável;
- peso;
- progresso;
- situação;
- situação de validação;
- referência opcional a Indicador Estratégico;
- metadados e auditoria.

Os atributos complementares são armazenados em `metadata` para preservar a função de clonagem existente e evitar alterações desnecessárias no esquema.

O Indicador opcional é preservado por código estável da Formulação. Na consulta consolidada, o código é resolvido para o Indicador da versão corrente, evitando manter referência ao registro da versão anterior após clonagem.

---

## 8. Cálculo de progresso

### 8.1 Polaridades

- `higher_is_better`;
- `lower_is_better`;
- `target_is_better`;
- `range_is_better`.

### 8.2 Regras comuns

- resultado limitado entre `0` e `100`;
- arredondamento em duas casas decimais;
- proteção contra divisão por zero;
- valores nulos não geram cálculo artificial;
- superação do alvo permanece em `100` no progresso armazenado;
- linha de base igual ao alvo resulta em `100` somente quando a condição-alvo é atendida;
- `range_is_better` utiliza limites inferior e superior;
- substituição manual exige configuração explícita e auditoria;
- divergência entre progresso manual e automático é preservada em metadados.

### 8.3 Progresso do OKR

- média ponderada quando todos os KRs possuem peso e a soma é positiva;
- média simples nos demais casos;
- quando pesos são obrigatórios, a prontidão exige preenchimento integral e soma de `100%` por OKR.

---

## 9. Distinção entre mutação estrutural e acompanhamento operacional

A Formulação existente congela seu conteúdo fora de `draft` e `in_elaboration`. Entretanto, os KRs precisam receber valores atuais durante a execução da estratégia.

A FE-06 substitui o gatilho genérico somente em:

- `skpe_okr_cycles`;
- `skpe_okrs`;
- `skpe_key_results`.

Após o bloqueio da Formulação:

- inserção e exclusão continuam proibidas;
- campos estruturais continuam imutáveis;
- somente situação operacional, valor atual, progresso, metadados de medição e campos técnicos de atualização podem mudar;
- toda operação continua ocorrendo por RPC auditada;
- escrita direta permanece revogada.

Alterações estruturais invalidam a validação do pacote. Atualizações de medição não invalidam a definição metodológica validada.

---

## 10. Alinhamentos entre OKRs

A tabela `skpe_okr_alignments` admite relações direcionais:

- `vertical`;
- `horizontal`;
- `depends_on`;
- `supports`;
- `contributes_to`;
- `parent_child`.

Regras:

- origem e destino devem pertencer à mesma Formulação, organização e projeto;
- autorrelacionamento é bloqueado;
- cada OKR pode possuir no máximo um pai ativo;
- ciclos na hierarquia `parent_child` são bloqueados;
- duplicidade de origem, destino e tipo é bloqueada;
- arquivamento preserva histórico;
- qualquer mutação estrutural invalida a validação anterior do pacote.

---

## 11. Prontidão metodológica

### 11.1 Pendências bloqueantes

A prontidão verifica, entre outras:

- pacote habilitado sem ciclo válido;
- ciclo fora do horizonte;
- sobreposição quando a política é `block`;
- OKR sem código, título, descrição ou racional suficientes;
- OKR sem vínculo com OE ou com vínculo fora de escopo;
- OE sem OKR quando configurado como obrigatório;
- responsável ausente quando obrigatório;
- OKR sem KR;
- quantidade de KRs abaixo do mínimo ou acima do máximo;
- KR sem código, definição mensurável, alvo, unidade ou polaridade;
- linha de base ausente quando exigida;
- fonte de dados ausente;
- KR fora do ciclo;
- alvo incompatível com polaridade ou faixa;
- KR, OKR, OE ou Indicador de outro escopo;
- pesos ausentes ou soma diferente de `100%` quando obrigatórios;
- duplicidade de códigos ou KRs;
- pacote ainda não validado.

### 11.2 Recomendações

- OKR sem responsável;
- KR sem responsável;
- KR sem Indicador Estratégico relacionado;
- coleta não automatizável;
- frequência incompatível com o ciclo;
- OKR com um único KR;
- concentração de OKRs em um único OE;
- ausência de alinhamentos;
- ausência de pesos;
- redação semelhante a atividade;
- medição desatualizada;
- divergência relevante entre progresso manual e automático;
- ausência de histórico de acompanhamento;
- sobreposição de ciclos quando a política é `warn`.

### 11.3 Não aplicabilidade

Quando `okr_enabled = false`:

- `applicability = not_applicable`;
- `readyForValidation = true`;
- `readyForFormulation = true`;
- a Formulação não recebe bloqueio artificial.

---

## 12. Fluxo de validação

```text
Em elaboração
→ Pendente de validação
→ Validado
```

A devolução retorna para **Em elaboração**.

Qualquer mutação estrutural em configuração, ciclo, OKR, vínculo com OE, KR, peso, linha de base, alvo, responsável ou alinhamento:

1. redefine o pacote para `in_elaboration`;
2. limpa submissão e validação anteriores;
3. redefine OKRs e KRs para `draft` no controle de validação;
4. registra auditoria.

---

## 13. Operações públicas

### Configuração

- `configure_skpe_okr_package`

### Ciclos

- `upsert_skpe_okr_cycle`
- `close_skpe_okr_cycle`
- `reopen_skpe_okr_cycle`

### OKRs e vínculos

- `upsert_skpe_okr`
- `archive_skpe_okr`
- `link_skpe_okr_objective`
- `unlink_skpe_okr_objective`

### Resultados-Chave

- `upsert_skpe_key_result`
- `archive_skpe_key_result`
- `update_skpe_key_result_progress`

### Alinhamentos

- `upsert_skpe_okr_alignment`
- `delete_skpe_okr_alignment`

### Prontidão, validação e consulta

- `get_skpe_okrs_readiness`
- `transition_skpe_okr_package`
- `get_skpe_okrs_package`
- `get_skpe_okrs_audit`

---

## 14. Funções internas protegidas

- `ensure_skpe_okr_package`;
- `skpe_invalidate_okr_package`;
- `skpe_assert_valid_responsible_area`;
- `skpe_calculate_key_result_progress`;
- `skpe_okr_parent_would_create_cycle`;
- `skpe_recalculate_okr_progress`;
- `skpe_guard_okr_operational_content`;
- `skpe_guard_formulation_okrs_ready`.

Somente `service_role` recebe execução explícita dessas funções.

---

## 15. Versionamento e clonagem

A função existente `clone_skpe_formulation_content` já clona:

- ciclos;
- OKRs;
- vínculos com Objetivos Estratégicos;
- Resultados-Chave;
- Indicadores e suas referências;
- pesos, metadados e responsáveis.

A FE-06 não reescreve essa função extensa.

O complemento ocorre em `ensure_skpe_okr_package`:

1. herda configurações do pacote da versão de origem;
2. clona alinhamentos remapeando ciclos e OKRs por código;
3. redefine validações para rascunho;
4. aplica `clone_progress_policy`;
5. por padrão, retorna o valor atual à linha de base e preserva o valor anterior em metadados;
6. mantém histórico da versão anterior intacto.

---

## 16. Consulta consolidada

`get_skpe_okrs_package` devolve em um único JSON:

- Formulação;
- configurações do pacote;
- ciclos;
- Objetivos Estratégicos;
- OKRs;
- vínculos OKR–OE;
- Resultados-Chave;
- Indicadores relacionados resolvidos na versão;
- alinhamentos;
- referências existentes a Iniciativas;
- prontidão;
- bloqueios e recomendações;
- histórico de validação.

O contrato prepara a futura interface visual sem antecipar sua implementação completa.

---

## 17. Segurança

- RLS habilitada em todas as tabelas controladas;
- leitura por `can_view_skpe_formulation`;
- nenhuma política `ALL` para `authenticated`;
- DML direto revogado para `public`, `anon` e `authenticated`;
- escrita somente por RPCs `SECURITY DEFINER`;
- `set search_path = ''` em todas as funções da FE-06;
- justificativa mínima centralizada em `skpe_assert_reason`;
- autorização verificada nas RPCs;
- validação de organização, projeto, Formulação, ciclo, OE, OKR, KR e Indicador;
- auditoria anterior e posterior;
- funções internas sem execução para `authenticated`.

---

## 18. Escopo excluído

Não integram a FE-06:

- implementação completa de Iniciativas;
- programas e projetos;
- planos de ação e 5W2H;
- gestão de portfólio;
- orçamento e cronograma das Iniciativas;
- riscos e benefícios das Iniciativas;
- acompanhamento operacional completo;
- integração financeira completa.

---

## 19. Critérios de aceite

A FE-06 estará tecnicamente validada quando:

1. a migration for executada integralmente no Supabase Web;
2. `skpe_okr_packages` e `skpe_okr_alignments` existirem;
3. as estruturas preexistentes forem reutilizadas sem duplicação;
4. todas as funções esperadas existirem;
5. todas forem `SECURITY DEFINER` com `search_path` vazio;
6. somente funções públicas forem executáveis por `authenticated`;
7. DML direto permanecer revogado;
8. os gatilhos estruturais e operacionais estiverem ativos;
9. os quatro cálculos de polaridade retornarem os resultados esperados;
10. a não aplicabilidade não bloquear a Formulação;
11. a clonagem existente e seu complemento FE-06 estiverem preservados;
12. o verificador consolidado retornar somente `status = OK`.

Até que haja evidência desses resultados, a situação correta permanece **pacote técnico preparado, execução pendente**.
