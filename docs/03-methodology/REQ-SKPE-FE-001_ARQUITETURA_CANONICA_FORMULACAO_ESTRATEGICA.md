# REQ-SKPE-FE-001 — Arquitetura Canônica da Formulação Estratégica

**Projeto:** Plataforma SPARKs — Módulo SK-PE
**Situação:** Aprovado para implementação controlada
**Organização de validação:** COOTAQUARA — Projeto Zero
**Aplicabilidade:** Multi-organização e multiprojeto, sem customização por código
**Data de consolidação:** 30/07/2026

---

## 1. Decisão metodológica central

A Formulação Estratégica da metodologia SPARKs parte da identidade da organização e constitui uma cadeia integrada de geração de valor, desdobramento, execução, mensuração e aprendizado.

A lógica canônica é:

1. **Missão** — base operacional e identitária da estratégia;
2. **Valores** — princípios inegociáveis e transversais;
3. **Visão de Longo Prazo** — condição futura desejada;
4. **Cadeia de Valor** — tradução da Missão em capacidades, processos, entregas, resultados e impactos;
5. **Temas Estratégicos** — grandes escolhas e frentes de transformação;
6. **Mapa Estratégico — BSC** — perspectivas, Objetivos Estratégicos e relações de causa e efeito;
7. **KPIs e Metas dos OEs** — mensuração do desempenho estratégico de longo prazo;
8. **BMK** — referência de benchmarking associada, sempre que possível, à fundamentação das metas dos OEs;
9. **OKRs** — desdobramento dos OEs em ciclos de mais curto prazo;
10. **KRs** — resultados mensuráveis que contribuem para os KPIs e metas dos OEs;
11. **Iniciativas** — execução orientada aos KRs, preferencialmente por projetos estratégicos, IPAs, projetos de melhoria operacional, implantação de soluções, programas ou planos de ação;
12. **Monitoramento e aprendizado** — acompanhamento por KR, KPI, OE, Tema e Visão, incluindo RAE e comunicação do desempenho estratégico às instâncias de governança e Assembleias.

O BSC estrutura a estratégia de longo prazo. Os OKRs não substituem o BSC: criam foco, cadência e mobilização para contribuir com o alcance dos Objetivos Estratégicos e de suas metas.

---

## 2. Arquitetura funcional

```text
FORMULAÇÃO ESTRATÉGICA
│
├── 1. Identidade Estratégica
│   ├── Propósito, quando adotado
│   ├── Missão
│   ├── Visão de Longo Prazo
│   └── Valores
│       ├── Significado
│       ├── Comportamentos esperados
│       └── Comportamentos incompatíveis
│
├── 2. Cadeia de Valor
│   ├── Partes interessadas
│   ├── Necessidades e expectativas
│   ├── Entradas
│   ├── Capacidades e recursos
│   ├── Macroprocessos finalísticos
│   ├── Macroprocessos de apoio
│   ├── Produtos, serviços e experiências
│   ├── Entregas de valor
│   ├── Resultados
│   └── Impactos
│
├── 3. Temas Estratégicos
│
├── 4. Mapa Estratégico — BSC
│   ├── Perspectivas estratégicas
│   ├── Objetivos Estratégicos — OEs
│   └── Relações de causa e efeito
│
├── 5. Desempenho Estratégico dos OEs
│   └── Para cada OE
│       ├── KPIs
│       ├── Linhas de base
│       ├── Metas por período
│       ├── Meta de longo prazo
│       ├── Faixas de desempenho
│       └── BMKs de referência
│
├── 6. Desdobramento dos OEs em OKRs
│   └── Para cada OE
│       └── Objetivos do ciclo
│           └── Resultados-Chave — KRs
│               ├── Indicador do KR
│               ├── Linha de base
│               ├── Meta anualizada ou do ciclo
│               ├── Peso de contribuição
│               ├── Prazo
│               └── Responsável
│
├── 7. Desdobramento dos KRs em Iniciativas
│   └── Para cada KR
│       ├── Projeto Estratégico
│       ├── Instrução de Prática Assistida — IPA
│       ├── Projeto de Melhoria Operacional
│       ├── Implantação de solução
│       ├── Programa
│       └── Plano de ação estruturado
│
└── 8. Monitoramento, Governança e Aprendizado
    ├── Execução física e financeira das iniciativas
    ├── Entregas e marcos
    ├── Evolução dos indicadores dos KRs
    ├── Alcance das metas dos KRs
    ├── Contribuição dos KRs para KPIs e metas dos OEs
    ├── Desempenho dos OEs
    ├── Desempenho dos Temas
    ├── Progresso em direção à Visão
    ├── Reuniões de Análise da Estratégia — RAE
    ├── Revisões da estratégia
    └── Prestação de informações às instâncias de governança e Assembleias
```

---

## 3. Cadeia de contribuição

```text
Missão + Valores
        ↓
Cadeia de Valor
        ↓
Temas Estratégicos
        ↓
Objetivos Estratégicos e relações de causa e efeito
        ↓
KPIs + Linhas de Base + Metas + BMKs
        ↓
OKRs do ciclo
        ↓
Resultados-Chave
        ↓
Iniciativas
        ↓
Entregas e resultados
        ↓
Contribuição para KPIs e metas dos OEs
        ↓
Avanço dos Temas
        ↓
Alcance progressivo da Visão de Longo Prazo
```

---

## 4. Regras metodológicas e cardinalidades

### 4.1 Identidade Estratégica

- A Identidade Estratégica pertence a uma organização e a um projeto estratégico.
- Deve ser versionada.
- Uma versão aprovada não pode ser sobrescrita.
- Alterações posteriores geram nova versão.
- O Propósito é opcional.
- Missão, Visão e ao menos um Valor são obrigatórios para aprovação.
- Cada Valor deve possuir significado e pode conter comportamentos esperados e incompatíveis.

### 4.2 Temas e Objetivos Estratégicos

- Um Tema possui vários Objetivos Estratégicos.
- Um Objetivo Estratégico pertence a um Tema principal.
- Um OE pode possuir relações de contribuição com vários outros OEs.
- Relações de causa e efeito devem impedir ciclos lógicos inválidos.
- Cada OE deve possuir perspectiva, resultado esperado, responsável, horizonte e situação.

### 4.3 KPIs, Metas e BMKs

- Cada OE deve possuir um ou mais KPIs.
- Cada KPI pode possuir várias metas por período.
- Cada KPI deve possuir, quando disponível, linha de base e data-base.
- Cada meta pode ser fundamentada por zero ou mais BMKs.
- O BMK não substitui a meta; fundamenta sua ambição e evidencia a lacuna.
- Deve ser possível registrar fonte, organização de referência, período, valor e aplicabilidade.

### 4.4 OKRs e KRs

- Um Objetivo do OKR deve estar relacionado a pelo menos um OE.
- A recomendação metodológica é de no mínimo 3 KRs por Objetivo do OKR.
- Cada KR deve possuir pelo menos um indicador e uma meta do ciclo.
- As metas dos KRs devem ser anualizadas ou definidas conforme o ciclo.
- Cada KR pode contribuir para um ou mais KPIs de OEs.
- A contribuição deve poder ser ponderada e justificada.
- O sistema deve diferenciar KPI estratégico do OE e indicador operacional do KR.

### 4.5 Iniciativas

- Cada iniciativa deve possuir um KR principal.
- Uma iniciativa pode contribuir adicionalmente para outros KRs.
- A recomendação metodológica é de no mínimo 3 iniciativas por KR.
- Tipos mínimos:
  - Projeto Estratégico;
  - IPA;
  - Projeto de Melhoria Operacional;
  - Implantação de solução;
  - Programa;
  - Plano de ação.
- A existência de menos de 3 iniciativas deve gerar alerta metodológico, não bloqueio absoluto.
- A contribuição múltipla não pode gerar dupla contagem automática do resultado.

---

## 5. Governança e estados

Estados mínimos dos artefatos:

```text
Rascunho
→ Em elaboração
→ Pendente de validação
→ Validado
→ Pendente de aprovação
→ Aprovado
→ Substituído
→ Arquivado
```

Regras:

- Elaboradores podem criar e editar rascunhos.
- Validadores registram parecer, ressalvas e decisão.
- Aprovadores registram deliberação e data de vigência.
- Toda mudança relevante exige justificativa.
- Eventos de criação, alteração, validação, aprovação, substituição e arquivamento devem ser auditados.
- A aprovação deve registrar usuário, data, observação, instância deliberativa e evidência, quando aplicável.

---

## 6. Escopo e isolamento

Toda entidade operacional deve ser vinculada, conforme aplicável, a:

- `organization_id`;
- `project_id`;
- versão/ciclo;
- responsável;
- situação;
- datas de vigência;
- usuário criador e usuário atualizador.

Requisitos:

- isolamento multi-tenant;
- suporte a múltiplos projetos estratégicos por organização;
- nenhuma seleção implícita baseada em “primeiro projeto retornado”;
- seleção explícita do projeto estratégico;
- permissões por organização, módulo e função;
- acesso hierárquico de consulta não concede poder de edição.

---

## 7. Primeiro corte funcional

### FE-00 — Fundação

1. Auditoria das estruturas existentes;
2. seleção explícita do projeto estratégico;
3. contratos canônicos de escopo, versão, situação e auditoria;
4. RLS e RPCs;
5. prevenção de duplicação de entidades já existentes.

### FE-01 — Identidade Estratégica

1. pacote versionado de identidade;
2. Propósito opcional;
3. Missão;
4. Visão de Longo Prazo;
5. Valores estruturados;
6. comportamentos esperados e incompatíveis;
7. validação;
8. aprovação;
9. histórico e auditoria;
10. visualização da versão vigente e das versões anteriores.

### FE-02 — Cadeia de Valor

1. partes interessadas;
2. necessidades e expectativas;
3. macroprocessos;
4. capacidades e recursos;
5. entregas de valor;
6. resultados e impactos;
7. representação visual e rastreabilidade com Missão, Temas e OEs.

---

## 8. Critérios de aceite do primeiro corte

- O usuário seleciona explicitamente organização e projeto.
- O sistema não utiliza o primeiro projeto retornado como escolha implícita.
- É possível criar uma versão de Identidade Estratégica.
- É possível cadastrar Missão, Visão e Valores.
- Cada Valor aceita significado, comportamentos esperados e incompatíveis.
- É possível submeter para validação e aprovação.
- Uma versão aprovada torna-se somente leitura.
- Uma revisão cria nova versão sem apagar a anterior.
- A versão vigente é identificada de forma inequívoca.
- Todas as operações respeitam organização, projeto, permissões e auditoria.
- A interface utiliza cards e linhas com hover e clique transversal, conforme padrão da Plataforma SPARKs.
- Ações primárias usam ícone e texto; ações secundárias universais podem usar somente ícone com `title` e `aria-label`.
- Formulários longos possuem ações no topo e no final e protegem alterações não salvas.

---

## 9. Itens deliberadamente posteriores

Não integram o primeiro corte, embora o modelo de dados deva permitir sua evolução:

- editor visual completo da Cadeia de Valor;
- Mapa Estratégico gráfico;
- cálculo avançado de contribuição ponderada;
- dashboards analíticos;
- automação de RAE;
- importação automática de BMKs;
- simulações e cenários;
- relatórios executivos completos;
- apresentação do desempenho estratégico em Assembleias.

---

## 10. Decisão de implementação

A COOTAQUARA será o Projeto Zero da Formulação Estratégica.

A implementação deve:

- preservar integralmente o conteúdo já validado na Macrofase 2;
- evitar referências fixas à COOTAQUARA no código;
- permitir posterior replicação para COOPERCOMPANY, QUERUBIM, SPARKOOP e demais organizações;
- trabalhar com templates metodológicos e instâncias organizacionais;
- integrar Formulação, Indicadores, OKRs, Iniciativas, Projetos, Governança, Riscos, Evidências e Gestão Documental.
