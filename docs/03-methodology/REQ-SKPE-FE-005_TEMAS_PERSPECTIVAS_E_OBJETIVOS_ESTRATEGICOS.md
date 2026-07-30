# REQ-SKPE-FE-005 — Temas, Perspectivas e Objetivos Estratégicos Operacionais

**Projeto:** Plataforma SPARKs — Módulo SK-PE
**Etapa:** FE-04 — Temas, Perspectivas, Objetivos Estratégicos e Mapa Estratégico
**Situação:** Implementação técnica preparada; execução no Supabase ainda não realizada
**Aplicabilidade:** Multi-organização e multiprojeto, sem regra fixa para a COOTAQUARA
**Branch canônica:** `feature/formulacao-estrategica-operacional`
**Base técnica inspecionada:** commit `1d927a5db86db5fb1c512cd8978d49c0d2fadf1d`

---

## 1. Objetivo

Implantar a capacidade operacional, versionada, auditada e segura para gerir:

- Temas Estratégicos;
- Perspectivas Estratégicas configuráveis;
- Objetivos Estratégicos de longo prazo;
- relações causais direcionais entre Objetivos;
- ordenação e posicionamento para o futuro Mapa Estratégico visual;
- prontidão metodológica específica da FE-04;
- submissão, validação e devolução do pacote;
- bloqueio do avanço da Formulação enquanto a FE-04 estiver incompleta ou não validada;
- consulta consolidada e histórico auditável.

A FE-04 não antecipa a obrigatoriedade de Indicadores, Metas, OKRs, Resultados-Chave ou Iniciativas. Esses vínculos aparecem apenas como recomendações ou como informação de integração com etapas posteriores.

---

## 2. Resultado da inspeção técnica

A inspeção confirmou que as estruturas centrais já existiam e deveriam ser reaproveitadas:

- `skpe_strategic_themes`;
- `skpe_bsc_perspectives`;
- `skpe_strategic_objectives`;
- `skpe_objective_relations`;
- `skpe_strategic_formulations`;
- `skpe_operational_audit`.

Também foram preservadas as integrações futuras com:

- `skpe_indicators`;
- `skpe_indicator_targets`;
- `skpe_okrs`;
- `skpe_okr_objectives`;
- `skpe_key_results`;
- iniciativas e seus vínculos com Objetivos Estratégicos.

### 2.1 Lacuna real constatada

As tabelas de conteúdo existiam, mas não havia um cabeçalho próprio para controlar o ciclo de validação do conjunto do Mapa Estratégico. Por isso foi criada somente uma nova estrutura:

- `skpe_strategic_map_packages`.

Essa tabela não duplica Temas, Perspectivas, Objetivos ou relações. Ela registra a governança do pacote FE-04, suas regras metodológicas configuráveis e seu estado de validação.

### 2.2 Decisão para evitar quebra do versionamento

Os atributos visuais e de posicionamento foram mantidos em `metadata`, porque as rotinas de clonagem já preservam esse JSON entre versões. Assim, a FE-04 não precisa reescrever a extensa função de clonagem da FE-01 e não perde:

- cor visual;
- natureza metodológica da Perspectiva;
- classificação entre Perspectiva padrão e customizada;
- ordem do Objetivo;
- posição do Objetivo no Canvas;
- peso da relação causal.

A configuração do pacote FE-04 é herdada de forma controlada quando uma nova Formulação é derivada de versão anterior.

---

## 3. Modelo operacional do pacote

### 3.1 Estados

```text
Em elaboração
→ Pendente de validação
→ Validado
```

Uma devolução retorna o pacote para **Em elaboração**.

Qualquer mutação posterior em Tema, Perspectiva, Objetivo ou relação causal:

1. invalida a validação anterior;
2. retorna o pacote para `in_elaboration`;
3. limpa os registros de submissão e validação;
4. redefine os Objetivos como `draft` no controle de validação;
5. registra auditoria.

### 3.2 Configurações metodológicas

Cada versão pode configurar:

- `theme_required`: exige ou não Tema principal para cada Objetivo ativo;
- `causal_cycle_policy`:
  - `warn`: permite o ciclo e gera recomendação metodológica;
  - `block`: impede a criação de relação que produza ciclo;
- `owner_recommended`: recomenda responsável para cada Objetivo ativo.

A configuração padrão é:

```text
theme_required = true
causal_cycle_policy = warn
owner_recommended = true
```

A política padrão para ciclos é **sinalizar**, e não bloquear. O bloqueio pode ser ativado quando a metodologia da organização determinar que o Mapa deve ser estritamente acíclico.

---

## 4. Temas Estratégicos

A operação permite:

- criar e atualizar;
- arquivar;
- definir código e nome;
- registrar descrição e racional;
- definir prioridade;
- definir horizonte;
- indicar responsável;
- ordenar para exibição;
- registrar identidade visual em `metadata.visualColor`;
- vincular à versão exata da Formulação;
- exigir justificativa;
- registrar auditoria antes/depois.

A unicidade permanece controlada por:

```text
(formulation_id, code)
```

Um Tema não pode ser arquivado enquanto possuir Objetivos não arquivados. A organização deve primeiro reatribuir ou arquivar os Objetivos vinculados.

---

## 5. Perspectivas Estratégicas

A solução não limita a organização às quatro perspectivas clássicas do BSC.

Cada Perspectiva pode registrar:

- código;
- nome;
- descrição;
- ordem vertical do Mapa;
- situação ativa ou inativa;
- `methodologicalNature` em `metadata`;
- `perspectiveModel`:
  - `bsc_standard`;
  - `custom`;
- `visualColor` em `metadata`.

A unicidade permanece controlada por:

```text
(formulation_id, code)
```

Uma Perspectiva não pode ser arquivada enquanto possuir Objetivos não arquivados.

---

## 6. Objetivos Estratégicos

Cada Objetivo pode registrar:

- código;
- título;
- descrição;
- resultado esperado;
- racional estratégico;
- Tema principal;
- Perspectiva;
- prioridade;
- horizonte;
- responsável;
- situação;
- ordem de exibição;
- posição no Mapa;
- identidade visual;
- metadados;
- situação de validação.

### 6.1 Compatibilidade preservada

O Objetivo continua utilizando a tabela compartilhada já empregada por Formulação e Iniciativas. A FE-04 sincroniza:

- `management_model = 'bsc'`;
- `perspective_id` e o campo legado `perspective_code`;
- `strategic_theme_id` e o campo legado `strategic_theme`;
- sincronização auditada dos campos legados quando o código do Tema ou da Perspectiva for alterado;
- `validation_status`;
- vínculos futuros com KPIs, OKRs, KRs e Iniciativas.

### 6.2 Campos visuais preservados em metadados

```json
{
  "displayOrder": 100,
  "mapPosition": {
    "x": 0,
    "y": 0,
    "lane": 1,
    "column": 1
  },
  "visualColor": "#000000"
}
```

O objeto `mapPosition` é livre para permitir evolução da interface sem nova alteração de esquema.

### 6.3 Arquivamento

Ao arquivar um Objetivo:

- o registro permanece no histórico;
- suas relações causais são removidas para impedir referência a Objetivo arquivado;
- cada relação removida é auditada;
- a validação do pacote é invalidada.

Os vínculos históricos de Indicadores, OKRs ou Iniciativas não são apagados automaticamente nesta etapa.

---

## 7. Relações causais

Os tipos aceitos são:

```text
cause_effect
supports
enables
contributes_to
depends_on
influences
```

Cada relação registra:

- Objetivo de origem;
- Objetivo de destino;
- tipo;
- força: `low`, `medium` ou `high`;
- peso opcional de 0 a 100 em `metadata.relationWeight`;
- racional;
- ordem;
- metadados;
- auditoria.

São bloqueados:

- autorrelacionamento;
- Objetivos de Formulações diferentes;
- Objetivos de organizações ou projetos incompatíveis;
- referência a Objetivo arquivado;
- duplicidade de origem, destino e tipo;
- mutação quando a Formulação não estiver editável;
- ciclo causal quando a política estiver definida como `block`.

---

## 8. Prontidão metodológica da FE-04

### 8.1 Bloqueios de conteúdo

- ausência de Tema ativo;
- ausência de Perspectiva ativa;
- ausência de Objetivo ativo;
- Objetivo ativo sem Perspectiva ativa;
- Objetivo ativo sem Tema quando `theme_required = true`;
- Objetivo ativo sem resultado esperado;
- Objetivo ativo sem racional estratégico;
- Objetivo fora do escopo da Formulação;
- relação fora do escopo da Formulação;
- relação com Objetivo arquivado;
- duplicidade impeditiva na ordem de exibição dos Temas;
- duplicidade impeditiva na ordem vertical das Perspectivas;
- duplicidade impeditiva na ordem de Objetivos da mesma Perspectiva;
- ciclo causal quando `causal_cycle_policy = block`.

### 8.2 Bloqueio de avanço da Formulação

Mesmo quando o conteúdo está completo, a Formulação não pode avançar enquanto o pacote FE-04 não estiver `validated`.

A prontidão retorna dois controles distintos:

```text
readyForValidation
readyForFormulation
```

- `readyForValidation`: considera somente a completude do conteúdo FE-04;
- `readyForFormulation`: exige completude e pacote validado.

### 8.3 Recomendações

- Tema sem Objetivos;
- Perspectiva sem Objetivos;
- Objetivo sem relação causal;
- Objetivo sem KPI, identificado como responsabilidade de etapa posterior;
- Objetivo sem responsável;
- concentração superior a 60% dos Objetivos em uma única Perspectiva;
- ciclo causal quando a política é `warn`;
- Objetivo com redação excessivamente extensa, usando heurística de revisão de foco.

### 8.4 Exclusões rigorosas desta etapa

A FE-04 informa explicitamente:

```text
indicatorRequiredInFe04 = false
okrRequiredInFe04 = false
initiativeRequiredInFe04 = false
```

A ausência desses elementos não impede a validação do pacote FE-04.

---

## 9. Operações públicas

```text
configure_skpe_strategic_map

upsert_skpe_strategic_theme
archive_skpe_strategic_theme

upsert_skpe_bsc_perspective
archive_skpe_bsc_perspective

upsert_skpe_strategic_objective
archive_skpe_strategic_objective

upsert_skpe_objective_relation
delete_skpe_objective_relation

get_skpe_strategic_map_readiness
transition_skpe_strategic_map
get_skpe_strategic_map
get_skpe_strategic_map_audit
```

## 9.1 Funções internas protegidas

```text
ensure_skpe_strategic_map_package
skpe_invalidate_strategic_map_package
skpe_objective_relation_would_create_cycle
skpe_guard_formulation_strategic_map_ready
```

Somente `service_role` recebe execução explícita dessas funções internas.

---

## 10. Consulta consolidada

`get_skpe_strategic_map` devolve um único JSON com:

- Formulação;
- cabeçalho do pacote;
- Temas;
- Perspectivas;
- Objetivos;
- relações causais;
- ordem e posição visual;
- prontidão e recomendações.

Esse contrato prepara o backend para futura interface em Canvas ou diagrama visual sem impor a implementação da interface nesta etapa.

---

## 11. Segurança

A FE-04 preserva o padrão transversal consolidado:

- funções públicas `SECURITY DEFINER`;
- `set search_path = ''`;
- verificação de organização e projeto;
- verificação da versão da Formulação;
- verificação da situação editável;
- justificativa mínima obrigatória;
- auditoria operacional;
- leitura por RLS;
- nenhuma política de escrita para `authenticated`;
- nenhum privilégio direto de `INSERT`, `UPDATE` ou `DELETE` para `authenticated`;
- funções internas não executáveis por `authenticated`;
- DML operacional preservado para `service_role`.

A política de leitura de `skpe_operational_audit` passa a reconhecer também usuários autorizados a consultar a Formulação Estratégica.

---

## 12. Auditoria

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
strategic_map_package
strategic_theme
bsc_perspective
strategic_objective
objective_relation
```

---

## 13. Integração com o ciclo da Formulação

O trigger:

```text
skpe_strategic_formulations_guard_strategic_map_ready
```

impede transições da Formulação para:

- `pending_validation`;
- `validated`;
- `pending_approval`;
- `approved`;

quando a FE-04 estiver incompleta ou não validada.

A implementação não substitui nem remove os gatilhos já existentes de:

- Identidade Estratégica;
- Fundamentação do Negócio;
- Cadeia de Valor.

---

## 14. Critérios de aceite

A FE-04 somente estará concluída após evidência objetiva de que:

1. a migration executou integralmente no Supabase Web;
2. o verificador retornou somente `OK`;
3. a tabela do pacote possui RLS e política somente de leitura;
4. todas as funções esperadas existem;
5. todas são `SECURITY DEFINER`;
6. somente APIs públicas são executáveis por `authenticated`;
7. funções internas permanecem protegidas;
8. Temas podem ser criados, atualizados e arquivados por RPC;
9. Perspectivas padrão e customizadas podem ser geridas por RPC;
10. Objetivos podem ser geridos, posicionados e auditados;
11. relações causais podem ser geridas e auditadas;
12. inconsistências de escopo são bloqueadas;
13. ciclos são tratados conforme a política configurada;
14. a prontidão separa FE-04 de etapas posteriores;
15. alterações invalidam a validação anterior;
16. o pacote pode ser submetido, validado e devolvido;
17. o avanço da Formulação exige a FE-04 validada;
18. não existe escrita direta para `authenticated`;
19. os arquivos foram versionados somente na branch canônica;
20. o push remoto foi confirmado sem merge em `develop` ou `main`.

---

## 15. Artefatos desta entrega

```text
supabase/migrations/
20260730060000_create_strategic_themes_perspectives_and_objectives_operations.sql

supabase/verification/
verificar_fe04_temas_perspectivas_objetivos_estrategicos.sql

docs/03-methodology/
REQ-SKPE-FE-005_TEMAS_PERSPECTIVAS_E_OBJETIVOS_ESTRATEGICOS.md
```

A migration não insere conteúdo da COOTAQUARA nem de qualquer outra organização.
