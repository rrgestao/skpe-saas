# Relatório de Inspeção e Decisão Arquitetural — FE-09.A

## 1. Identificação

- Repositório: `rrgestao/skpe-saas`
- Branch: `feature/formulacao-estrategica-operacional`
- Commit-base: `0fd801bfe076c07fd6f06ac2aea94a8aa094115f`
- Branch-base: `develop`
- Comparação confirmada: 14 commits à frente e 0 atrás
- FE-08: concluída e publicada
- Merge: não autorizado

## 2. Evidências inspecionadas

Foram considerados:

- `apps/web/package.json`;
- `apps/web/src/main.tsx`;
- `apps/web/src/lib/supabase.ts`;
- `apps/web/src/App.tsx`;
- `apps/web/src/modules/skpe/SkpeCockpit.tsx`;
- `MethodologyArtifactsSection.tsx`;
- requisitos FE-01 a FE-09;
- migrations FE-00 a FE-08;
- scripts de instalação e validação da FE-08;
- benchmark visual fornecido;
- demandas relatadas após apresentação à OCB.

## 3. Diagnóstico

### 3.1 Pontos fortes existentes

- autenticação;
- seleção organizacional;
- administração global;
- administração organizacional;
- menu lateral;
- cockpit;
- jornada;
- artefatos;
- cards interativos;
- temas claro e escuro;
- estrutura visual reutilizável;
- contratos robustos no banco.

### 3.2 Lacunas aplicacionais

- ausência de roteamento;
- contexto incompleto;
- seleção implícita de projeto;
- falta de Formulação e versão no workspace;
- cliente Supabase sem tipos;
- chamadas RPC dentro dos componentes;
- componente monolítico;
- autorização visual baseada em nomes de perfis;
- uso recorrente de `window.prompt`, `window.alert` e `window.confirm`;
- telas FE-00 a FE-08 ainda não operacionalizadas de forma integrada;
- ausência de Meu Espaço de Trabalho;
- ausência de Painel Principal por usuário;
- ausência de central de notificações;
- ausência de RAE/RAD na interface.

## 4. Decisões

### 4.1 Não criar tabela por presunção

A FE-09.A começa pela fundação frontend. Qualquer necessidade de RPC ou persistência adicional deverá ser comprovada após inspeção do catálogo real.

### 4.2 Refatoração incremental

O cockpit atual permanece funcional. Novas rotas e features serão introduzidas progressivamente.

### 4.3 Permissões por capacidade

A interface deixa de depender apenas de `administrator`, `manager`, `editor`, `approver` e `viewer`.

### 4.4 Painéis padronizados

A primeira versão terá painéis padronizados, filtros, favoritos e Painel Principal. O construtor livre é adiado.

### 4.5 Extensões OCB

Foram incorporados como requisitos de evolução:

- coortes, núcleos e carteiras;
- portfólios sistêmicos;
- mensageria;
- conversacional;
- importação assistida.

## 5. Classificação

### Reutilizar

- autenticação;
- seleção da organização;
- administração;
- identidade visual;
- componentes de cards;
- jornada;
- artefatos.

### Evoluir

- `App.tsx`;
- `SkpeCockpit.tsx`;
- navegação;
- contexto;
- permissões;
- Iniciativas;
- governança;
- feedback;
- formulários;
- cliente Supabase.

### Criar

- workspace;
- rotas;
- contexto Projeto–Formulação–Ciclo;
- camada API;
- capacidades;
- prontidão;
- transições auditadas;
- Meu Espaço de Trabalho;
- Painéis Disponíveis;
- Painel Principal;
- favoritos;
- notificações;
- telas FE-00 a FE-08;
- testes automatizados.

## 6. Decisão final

```text
FE-09.A APROVADA PARA IMPLEMENTAÇÃO INCREMENTAL
NOVA TABELA NÃO AUTORIZADA NESTE MOMENTO
MIGRATION NÃO PREPARADA
PACOTE ARQUITETURAL PREPARADO
IMPLEMENTAÇÃO REACT PENDENTE
MERGE NÃO AUTORIZADO
```
