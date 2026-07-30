# Relatório de Inspeção e Decisão Arquitetural — FE-07

## 1. Identificação

- Repositório: `rrgestao/skpe-saas`
- Branch: `feature/formulacao-estrategica-operacional`
- Commit-base completo: `dd1a993825658e7674b4dcfb2b10ec35ebbd9056`
- Branch-base: `develop`
- Comparação remota: 12 commits à frente e 0 atrás
- Merge: não realizado e não autorizado

## 2. Estruturas inspecionadas

Foram inspecionadas as migrations e estruturas relacionadas a:

- Iniciativas;
- programas, projetos e ações;
- vínculos com Objetivos Estratégicos e Resultados-Chave;
- Canvas e instrumentos contextuais;
- 5W2H;
- custos, benefícios, risco e saúde;
- auditoria;
- Formulação, versionamento, clonagem e prontidão;
- RLS, privilégios e RPCs.

## 3. Estruturas reutilizadas

### `skpe_initiatives`

Já suporta tipos de Iniciativa, hierarquia, responsáveis, patrocinador, datas, progresso, custo, benefício, risco e saúde. Foi escolhida como registro mestre permanente.

### `skpe_initiative_objectives`

Já suporta vínculo com Objetivos Estratégicos, tipo e peso de contribuição. Foi evoluída para carregar Formulação e item de portfólio.

### `skpe_initiative_key_results`

Já suporta vínculo com Resultados-Chave. Foi evoluída para carregar Formulação e item de portfólio, e teve a escrita direta legada removida.

### `skpe_initiative_instruments`

Já admite Canvas de projeto, SIPOC, plano de ação e Canvas de programa. Foi preservada.

### `skpe_operational_audit`

Já suporta entidade, ação, justificativa, estado anterior, estado posterior, usuário e data. Foi reutilizada integralmente.

## 4. Lacunas comprovadas

As estruturas existentes não eram suficientes para:

- governança formal do pacote FE-07;
- seleção e priorização versionada do portfólio;
- snapshot da decisão estratégica;
- vários itens de plano de ação por Iniciativa;
- dependências de execução;
- riscos estruturados;
- resultados e critérios de sucesso com Indicadores;
- prontidão específica;
- clonagem seletiva entre Formulações;
- contrato consolidado para futura interface.

## 5. Decisão de modelagem

Foi adotada a separação:

```text
Iniciativa operacional permanente
≠
Participação estratégica versionada
```

Consequências:

- `skpe_initiatives` não é clonada;
- `skpe_initiative_portfolio_items` é versionada;
- progresso e histórico operacional permanecem únicos;
- snapshots preservam a decisão aprovada;
- revisões podem selecionar, adiar ou excluir a mesma Iniciativa sem duplicá-la.

## 6. Estruturas criadas

- `skpe_initiative_packages`;
- `skpe_initiative_portfolio_items`;
- `skpe_initiative_actions`;
- `skpe_initiative_dependencies`;
- `skpe_initiative_risks`;
- `skpe_initiative_outcomes`.

## 7. Segurança

A inspeção identificou uma política histórica `FOR ALL` em `skpe_initiative_key_results`. A FE-03.01 corrigiu `skpe_key_results`, mas não demonstrou correção equivalente para a tabela de vínculos.

A migration da FE-07:

- remove a política legada;
- revoga DML de `public`, `anon` e `authenticated`;
- mantém leitura por RLS;
- concede DML somente ao `service_role`;
- exige mutações por RPCs auditadas;
- revoga execução autenticada das RPCs legadas de mutação.

## 8. Versionamento

A clonagem é realizada sob demanda por `ensure_skpe_initiative_package`.

São clonados:

- configuração;
- itens de portfólio;
- pontuações e decisões;
- vínculos com OEs e KRs remapeados;
- resultados, benefícios e critérios;
- dependências.

Não são clonados:

- Iniciativas mestres;
- progresso;
- custos e benefícios realizados;
- ações executadas;
- riscos ocorridos;
- auditoria.

## 9. Limitações da inspeção

A inspeção foi realizada sobre o repositório remoto e os arquivos versionados. Não foi executada conexão com o banco do Supabase nesta etapa.

Portanto:

- a validação do desenho é estática;
- a execução real no PostgreSQL permanece pendente;
- catálogo, privilégios e dados reais deverão ser confirmados pelo verificador;
- nenhum commit, push ou merge foi realizado.
