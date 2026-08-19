---
id: SKPE-SPEC-INIT-BMC-VPC-PEM00
version: 2.0.0
status: active-with-transverse-initiative-domain
domain: SK-PE
owner_module: SK-PE
created_at: 2026-07-27
updated_at: 2026-08-19
origin: SK-PE-CONT-01
supersedes_version: 2026.07.27
depends_on:
  - ADR-PLAT-INIT-001
  - REQ-PLAT-INIT-001
---

# SK-PE — Especificação Consolidada

## Painel de Iniciativas, integração BMC/VPC e inteligência do checklist da PEM-00

**Versão:** 2026.08.19
**Situação:** Fundação funcional aprovada, atualizada para consumir o domínio transversal de Gestão de Iniciativas.

## 1. Princípio orientador

A Plataforma SPARKs não será um repositório de formulários ou planos estáticos. Ela deverá transformar evidências, diagnósticos, objetivos, iniciativas e resultados em inteligência estratégica rastreável, acompanhada e acionável.

### 1.1 Atualização arquitetural de 19/08/2026

A Gestão de Iniciativas deixa de ser conceitualmente propriedade exclusiva do SK-PE e passa a ser tratada como **capacidade transversal da Plataforma SPARKs**, conforme `ADR-PLAT-INIT-001`.

O SK-PE continua sendo um dos principais produtores e consumidores de Iniciativas Estratégicas, porém a existência da Iniciativa é organizacional.

A **Implantação do Planejamento Estratégico** deverá ser tratada como uma Iniciativa da:

- Classe: Projeto;
- Categoria/Natureza: Estratégica;

e deverá constar no Portfólio de Iniciativas da Organização.

A Jornada Estratégica do SK-PE será a especialização operacional desse Projeto, evitando dois objetos concorrentes para representar a mesma implantação.

## 2. Painel Gerencial de Iniciativas

A entrada da área **Iniciativas** deverá ser um painel gerencial, e não a abertura direta de um Canvas.

No SK-PE, esse painel poderá ser apresentado em contexto estratégico, mas deverá consumir a mesma fonte transversal de Iniciativas da Organização.

Indicadores mínimos:

- total de iniciativas;
- iniciativas propostas, em execução, concluídas, atrasadas e bloqueadas;
- iniciativas críticas;
- iniciativas sem responsável;
- iniciativas sem atualização recente;
- progresso médio;
- custos planejados e realizados;
- benefícios planejados e realizados;
- iniciativas com e sem instrumento contextual.

Filtros mínimos:

- classe;
- categoria/natureza;
- tipo/contexto de iniciativa;
- área responsável;
- Objetivo Estratégico — OKRs;
- responsável;
- situação;
- prioridade;
- período;
- tema estratégico;
- risco;
- instrumento existente;
- Programa;
- módulo/contexto de origem.

## 3. Classes e contextos de iniciativa

### 3.1 Classes canônicas

- Projeto;
- Programa;
- Iniciativa;
- Ação Estruturante.

### 3.2 Contextos/categorias

A classificação estratégica, operacional, de processos, ESG, comunicação/marketing e demais naturezas deverá ser tratada separadamente da classe, permitindo evolução governada.

A tipologia histórica do SK-PE:

- Projeto Estratégico;
- Melhoria Operacional;
- Iniciativa de Processo;
- Ação Simples;
- Programa Estratégico;

deverá ser preservada durante a transição, mas reconciliada com o modelo transversal para impedir que “Projeto” e “Estratégico” permaneçam fundidos em uma única dimensão técnica.

### 3.3 Instrumentos contextuais

- Projeto → TAP/Canvas do Projeto;
- Programa → Canvas do Programa e projetos vinculados;
- Iniciativa de Processo → SIPOC Canvas, quando aplicável;
- Ação Estruturante → Plano de Ação/5W2H;
- demais contextos → instrumento do módulo especialista.

O instrumento será acessado por ícone ou ação dentro da iniciativa. Não integrará o menu principal do SK-PE.

## 4. Relação entre PE, Iniciativa e Jornada

O Planejamento Estratégico poderá:

- identificar;
- propor;
- priorizar;
- selecionar;
- validar;
- vincular;
- acompanhar;

Iniciativas.

Entretanto, não deverá determinar a existência permanente da Iniciativa.

A relação canônica é:

```text
Planejamento Estratégico
        │
        ├── propõe / seleciona / vincula
        ↓
Iniciativa Organizacional
        │
        └── quando Projeto de Implantação do PE
                ↓
        Jornada Estratégica especializada SK-PE
```

A Jornada não deverá competir com a Gestão de Iniciativas em:

- identidade do Projeto;
- responsável;
- patrocinador;
- custos;
- benefícios;
- riscos;
- progresso;
- cronograma;
- status.

Quando houver dados especializados de Jornada, deverá existir regra explícita de autoridade e projeção.

## 5. Objetivos Estratégicos — OKRs

A estrutura suportará os modelos:

- simplificado;
- BSC;
- OKRs;
- híbrido BSC + OKRs.

Cada iniciativa poderá contribuir para um ou mais Objetivos Estratégicos — OKRs, com tipo e peso de contribuição.

Esse vínculo será governado e versionado; a remoção ou revisão do Objetivo Estratégico — OKR não implica exclusão automática da Iniciativa.

## 6. Continuidade entre ciclos estratégicos

Uma Iniciativa poderá atravessar:

- versões do PE;
- Formulações Estratégicas;
- Ciclos de Evolução;
- revisões de Objetivos Estratégicos — OKRs.

A plataforma deverá preservar histórico dos vínculos e permitir continuidade, reclassificação, arquivamento ou nova priorização.

## 7. BMC/VPC organizacional

O SK-PE deverá utilizar o BMC e o VPC como evidências estratégicas estruturadas.

Origens permitidas:

- integração nativa com o SK-PN;
- construção no próprio SK-PE;
- importação externa;
- preenchimento manual assistido.

Deverão ser preservados:

- origem;
- versão;
- data de referência;
- responsável;
- arquivo de origem;
- situação de validação;
- histórico;
- vínculos com jornada, achados, objetivos e iniciativas.

## 8. Checklist dinâmico da PEM-00

O checklist será gerado conforme o perfil da organização:

- tipo e natureza;
- ramo;
- porte;
- maturidade;
- quadro social e funcional;
- escopo contratado;
- modelos de referência aplicáveis.

Cada item aceitará múltiplos arquivos e documentos.

Situações de coleta:

- Não solicitado;
- Solicitado;
- Recebido parcialmente;
- Recebido;
- Em análise;
- Necessita complementação;
- Não aplicável;
- Encerrado.

## 9. Avaliação frente às melhores práticas

Escala canônica:

- 0 — Não apresentado;
- 1 — Evidência insuficiente;
- 2 — Atendimento parcial;
- 3 — Atendimento adequado;
- 4 — Boa prática implementada;
- 5 — Prática madura e sistematizada.

Dimensões avaliadas:

- qualidade;
- completude;
- atualidade;
- confiabilidade;
- atendimento global.

Saídas:

- pontos fortes;
- lacunas;
- riscos;
- recomendações;
- necessidade de complementação;
- insumos para o diagnóstico.

## 10. Integração com o SK-DOC

Cada arquivo do checklist possuirá referência futura ao documento oficial no SK-DOC. O SK-PE deverá usar o documento sem duplicá-lo, preservando metadados, confidencialidade, versão e rastreabilidade.

A mesma regra aplica-se às evidências vinculadas a Iniciativas e Projetos.

## 11. Integração com outros módulos

O núcleo transversal de Iniciativas deverá ser reutilizado por:

- SK-PE;
- SK-PN;
- SK-BPM;
- SK-PCM;
- SPARK Impacto Coop;
- outros módulos da Plataforma SPARKs.

Cada módulo poderá fornecer especializações e artefatos sem duplicar a identidade da Iniciativa.

## 12. Decisão de implementação

A implementação será realizada em camadas:

1. auditoria de convergência entre `skpe_projects`, `skpe_initiatives`, Jornada e Portfólio;
2. definição do modelo canônico transversal;
3. migração governada e compatibilidade;
4. funções operacionais auditadas;
5. painel gerencial transversal de iniciativas;
6. especialização SK-PE da Implantação do Planejamento Estratégico;
7. evolução para Gantt, Kanban, Agenda, custos, riscos e benefícios integrados;
8. checklist e gestão de evidências da PEM-00;
9. integração BMC/VPC com o SK-PN;
10. SIPOC Canvas;
11. wizard especialista contextual.

Nenhum DDL de convergência será executado antes do fechamento da auditoria `17-B.5F.1`.

O wizard será construído após a estabilização dos modelos, regras, fluxos e campos, para orientar preenchimentos, avaliar lacunas e sugerir boas práticas com contexto real.

## 13. Guardrails

- não criar dois Projetos para representar a mesma Implantação do PE;
- não manter duas fontes de verdade de cronograma, progresso, custos ou responsáveis;
- não fazer a Iniciativa depender existencialmente de uma Formulação Estratégica;
- não confundir classe com categoria/natureza;
- não confundir Programa com Projeto;
- não reconstruir Gestão de Projetos dentro de cada módulo;
- preservar origem, autoria, validação, histórico e vínculos;
- manter regras críticas no backend;
- preservar segurança multi-organização;
- evitar drift entre banco, APIs, tipos, frontend, documentação e metodologia.
