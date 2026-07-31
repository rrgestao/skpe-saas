# Arquitetura de Informação e Navegação — FE-09.A

## 1. Estrutura principal

```text
Meu Espaço de Trabalho
│
├── Painel Principal
├── Minhas Pendências
├── Meus Indicadores
├── Meus KRs
├── Minhas Iniciativas
├── Minhas Decisões
├── Reuniões
├── Notificações
└── Favoritos

SK-PE
│
├── Visão Executiva
├── Jornada Estratégica
├── Formulação Estratégica
│   ├── Governança e Versões
│   ├── Identidade
│   ├── Fundamentação
│   ├── Cadeia de Valor
│   ├── Mapa Estratégico
│   ├── Indicadores e Metas
│   └── OKRs e KRs
├── Execução
│   ├── Portfólio
│   ├── Programas
│   ├── Projetos
│   ├── Iniciativas
│   ├── Planos de Ação
│   ├── Riscos
│   └── Resultados e Benefícios
├── Monitoramento
│   ├── Ciclos
│   ├── Medições
│   ├── Check-ins
│   └── Desempenho
├── Governança e Aprendizado
│   ├── RAE/RAD
│   ├── Decisões
│   ├── Aprendizados
│   └── Snapshots
├── Artefatos e Evidências
└── Administração
```

## 2. Cabeçalho persistente

O workspace deve mostrar:

- organização;
- projeto;
- Formulação;
- versão;
- situação;
- horizonte;
- ciclo;
- acesso;
- prontidão.

Trocas de contexto devem ser explícitas e registradas na URL.

## 3. Padrões de interação

- card ou linha: clique abre o registro;
- hover: destaca e revela ações rápidas;
- ação destrutiva: confirmação estruturada;
- transição: modal com impacto e justificativa;
- bloqueio: painel com motivo e ligação para correção;
- recomendação: aviso não bloqueante;
- gráfico: clique abre os dados;
- detalhe: breadcrumb real;
- saída de formulário alterado: proteção contra perda.

## 4. Painéis

### Meu Trabalho

Orientado ao usuário.

### Executivo

Orientado a resultado, risco e decisão.

### Organização

Orientado ao Planejamento Estratégico da organização.

### Formulação

Orientado à completude e prontidão.

### Monitoramento

Orientado à atualização e desempenho.

### Portfólio

Orientado à priorização, capacidade, progresso e risco.

### Sistêmico

Reservado para evolução com coortes e organizações múltiplas.

## 5. Responsividade

- desktop: navegação lateral completa;
- tablet: navegação recolhível;
- mobile: foco em consulta, pendências e atualização rápida;
- tabelas extensas: alternativa em cards;
- gráficos: resumo textual acessível.
