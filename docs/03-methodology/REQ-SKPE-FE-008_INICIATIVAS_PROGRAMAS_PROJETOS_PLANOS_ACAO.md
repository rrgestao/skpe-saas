# REQ-SKPE-FE-008 — Iniciativas Estratégicas, Programas, Projetos e Planos de Ação

**Projeto:** Plataforma SPARKs — Módulo SK-PE
**Etapa:** FE-07 — Iniciativas Estratégicas, Programas, Projetos e Planos de Ação
**Aplicabilidade:** multi-organização e multiprojeto
**Branch canônica:** `feature/formulacao-estrategica-operacional`
**Commit-base inspecionado:** `dd1a993825658e7674b4dcfb2b10ec35ebbd9056`
**Situação:** pacote técnico preparado; execução no PostgreSQL pendente

---

## 1. Objetivo

Implantar a capacidade metodológica, operacional, auditável, versionada e segura para desdobrar a Formulação Estratégica em Iniciativas, programas, projetos e ações estruturantes, preservando a separação entre a estratégia aprovada e sua execução operacional.

A FE-07 deve permitir:

- manter a Iniciativa como objeto operacional permanente;
- selecionar e priorizar a Iniciativa em uma versão da Formulação;
- organizar programas, projetos, Iniciativas e ações estruturantes;
- demonstrar contribuição para Objetivos Estratégicos e Resultados-Chave;
- registrar resultados esperados, benefícios e critérios de sucesso;
- estabelecer planos de ação, marcos, dependências e riscos;
- estimar custos, esforço e recursos em alto nível;
- submeter e validar formalmente o pacote;
- preservar snapshots da decisão estratégica;
- acompanhar a execução sem alterar retroativamente a Formulação validada.

---

## 2. Separação arquitetural obrigatória

### 2.1 Iniciativa operacional permanente

A tabela `skpe_initiatives` permanece como registro mestre. Ela não é clonada a cada revisão do Planejamento Estratégico.

### 2.2 Participação estratégica versionada

A tabela `skpe_initiative_portfolio_items` registra como uma Iniciativa participa de uma Formulação específica, incluindo seleção, priorização, pontuação, decisão e snapshot.

### 2.3 Regra de versionamento

Ao criar uma revisão da Formulação:

- a Iniciativa operacional é reutilizada;
- o item de portfólio é recriado para a nova versão;
- vínculos com OEs, KRs e Indicadores são remapeados;
- resultados e critérios são copiados como nova definição em elaboração;
- progresso, custos realizados, riscos ocorridos e auditoria não são clonados.

---

## 3. Estruturas reutilizadas

A FE-07 reutiliza e evolui:

- `skpe_initiatives`;
- `skpe_initiative_objectives`;
- `skpe_initiative_key_results`;
- `skpe_initiative_instruments`;
- `skpe_strategic_objectives`;
- `skpe_okrs`;
- `skpe_key_results`;
- `skpe_indicators`;
- `skpe_strategic_formulations`;
- `skpe_operational_audit`;
- funções transversais de autorização, editabilidade, justificativa e auditoria.

Não são criadas tabelas centrais paralelas para programas ou projetos estratégicos. Esses conceitos permanecem especializações de `skpe_initiatives`.

---

## 4. Estruturas novas

### 4.1 `skpe_initiative_packages`

Controla aplicabilidade, configurações metodológicas, pesos de priorização, submissão e validação da FE-07.

### 4.2 `skpe_initiative_portfolio_items`

Registra seleção, decisão, ranking, pontuação, avaliações e snapshot de cada Iniciativa na Formulação.

### 4.3 `skpe_initiative_actions`

Mantém ações e marcos com 5W2H, responsabilidade, cronograma, custo, esforço, progresso e hierarquia.

### 4.4 `skpe_initiative_dependencies`

Mantém dependências, precedências e relações habilitadoras entre itens do portfólio da mesma Formulação.

### 4.5 `skpe_initiative_risks`

Mantém riscos estratégicos de alto nível com causa, consequência, probabilidade, impacto, resposta, responsável e risco residual.

### 4.6 `skpe_initiative_outcomes`

Mantém resultados esperados, benefícios e critérios de sucesso, com vínculo opcional a Indicador Estratégico.

---

## 5. Classificação das Iniciativas

A classificação canônica admite:

- `initiative`;
- `program`;
- `project`;
- `structuring_action`.

O campo legado `initiative_type` é preservado para compatibilidade e detalhamento.

### 5.1 Hierarquia

São permitidas as relações:

```text
Programa
├── Projeto
└── Iniciativa

Projeto
└── Ação estruturante

Iniciativa
└── Ação estruturante
```

São bloqueados:

- autorrelacionamento;
- ciclos;
- pai e filho de organizações ou projetos diferentes;
- programa subordinado;
- projeto sem programa pai quando houver pai;
- ação estruturante sem Iniciativa ou projeto pai;
- ação estruturante com filhos.

---

## 6. Portfólio e priorização

Cada item do portfólio pode assumir:

- `candidate`;
- `selected`;
- `deferred`;
- `excluded`.

A priorização utiliza, por padrão:

| Critério | Peso |
|---|---:|
| Valor estratégico | 30% |
| Benefício esperado | 20% |
| Urgência | 15% |
| Adequação à capacidade | 15% |
| Viabilidade de esforço | 10% |
| Gerenciabilidade de risco | 5% |
| Gerenciabilidade de dependências | 5% |

Os pesos são configuráveis por Formulação e devem totalizar 100%.

Cada critério recebe pontuação entre 0 e 100. A pontuação total é calculada pelas ponderações do pacote.

---

## 7. Rastreabilidade estratégica

Vínculos persistidos diretamente:

- Iniciativa → Objetivo Estratégico;
- Iniciativa → Resultado-Chave;
- Resultado, benefício ou critério → Indicador Estratégico.

Relações derivadas no contrato consolidado:

- Iniciativa → OE → Perspectiva → Tema;
- Iniciativa → KR → OKR.

A FE-07 não cria vínculos redundantes diretos para Tema, Perspectiva e OKR quando a relação pode ser determinada de forma íntegra por OE ou KR.

---

## 8. Planos de ação

Cada ação ou marco admite:

- código, nome e descrição;
- ação pai opcional;
- 5W2H;
- responsável, substituto e área;
- início, término e conclusão;
- prioridade, situação e progresso;
- custo estimado e realizado;
- esforço estimado e unidade;
- obrigatoriedade para a prontidão;
- auditoria.

A FE-07 não implementa Gantt detalhado, timesheet, alocação diária de pessoas ou integração contábil.

---

## 9. Riscos

A escala de probabilidade e impacto utiliza valores de 1 a 5. A exposição é calculada automaticamente pela multiplicação.

Respostas permitidas:

- evitar;
- mitigar;
- transferir;
- aceitar.

Riscos altos ou críticos exigem resposta suficiente. Riscos críticos exigem responsável.

A estrutura não substitui um futuro módulo corporativo especializado de riscos.

---

## 10. Resultados, benefícios e critérios de sucesso

Tipos:

- `expected_result`;
- `benefit`;
- `success_criterion`.

Formas de medição:

- qualitativa: exige critério de aceitação;
- quantitativa: exige meta e unidade.

O Indicador Estratégico é opcional, mas recomendado. Quando informado, deve pertencer à mesma Formulação.

---

## 11. Separação entre definição e acompanhamento

### 11.1 Alterações estruturais

Invalidam o pacote:

- seleção e priorização;
- classificação e hierarquia;
- problema ou justificativa;
- responsáveis estruturais;
- vínculos estratégicos;
- resultados, benefícios e critérios;
- dependências;
- definição de riscos;
- ações obrigatórias.

### 11.2 Atualizações operacionais

Podem ocorrer após a aprovação, por RPC auditada, sem invalidar a definição metodológica:

- progresso da Iniciativa;
- custo e benefício realizados;
- progresso e conclusão de ações;
- situação de dependências;
- situação e ocorrência de riscos;
- valor atual e realização de resultados.

---

## 12. Prontidão

### 12.1 Bloqueios

A prontidão verifica, no mínimo:

- pacote ausente ou não validado;
- nenhuma Iniciativa selecionada;
- limite de portfólio excedido;
- identificação ou justificativa incompleta;
- responsável ou área ausente quando obrigatórios;
- datas fora do horizonte;
- ausência de vínculo com OE ou KR;
- priorização incompleta;
- avaliação de capacidade ou risco ausente;
- ausência de resultado, benefício ou critério de sucesso;
- plano de ação ausente ou 5W2H incompleto;
- programa sem componentes;
- ação estruturante sem pai;
- dependência crítica sem resposta;
- risco alto ou crítico sem resposta.

### 12.2 Recomendações

A prontidão recomenda, entre outros:

- patrocinador;
- responsável substituto;
- vínculo com Indicador;
- vínculo com KR quando OKRs estiverem habilitados;
- marcos relevantes.

### 12.3 Não aplicabilidade

A não aplicabilidade é formal e auditável. Quando desabilitado, o pacote fica em `not_applicable` e não bloqueia a Formulação.

---

## 13. Fluxo de validação

```text
Em elaboração
→ Pendente de validação
→ Validado
```

A devolução retorna para `in_elaboration`.

Na validação:

1. a prontidão é reavaliada;
2. os registros estruturais recebem situação validada;
3. cada item selecionado recebe snapshot imutável da decisão;
4. a auditoria registra estado anterior, estado posterior, usuário e justificativa.

---

## 14. Segurança

A FE-07 exige:

- RLS em todas as tabelas novas;
- leitura condicionada ao escopo autorizado;
- escrita somente por RPCs `SECURITY DEFINER`;
- `set search_path = ''`;
- justificativa obrigatória;
- auditoria antes/depois;
- ausência de política `ALL` para `authenticated`;
- ausência de DML direto para `authenticated`;
- funções internas não executáveis por usuários comuns;
- revogação das RPCs legadas de mutação.

A política legada de escrita direta em `skpe_initiative_key_results` é removida expressamente.

---

## 15. Clonagem e revisão

`ensure_skpe_initiative_package` realiza a preparação idempotente e sob demanda do pacote da nova Formulação.

São remapeados por código estável:

- Objetivos Estratégicos;
- OKRs e Resultados-Chave;
- Indicadores.

Não são clonados estados operacionais realizados.

---

## 16. Contrato consolidado

`get_skpe_initiatives_package` retorna:

- configuração;
- prontidão;
- portfólio;
- hierarquia;
- OEs e KRs vinculados;
- Temas, Perspectivas, OKRs e Indicadores derivados;
- ações;
- riscos;
- dependências;
- resultados e benefícios;
- histórico de validação.

---

## 17. Limites da entrega

O pacote técnico preparado não comprova:

- execução no Supabase;
- compatibilidade real com o catálogo PostgreSQL do ambiente;
- sucesso do verificador;
- testes autenticados;
- commit;
- push;
- merge.

A etapa somente poderá ser considerada tecnicamente validada após a migration e o verificador serem executados no projeto `skpe-saas-dev` e todos os controles retornarem `status = OK`.
