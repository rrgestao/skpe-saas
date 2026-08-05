# Matriz de Painéis, Contextos e Capacidades — FE-09.A.05

## 1. Identificação

- Projeto: Plataforma SPARKs
- Módulo: SK-PE — Planejamento Estratégico
- Etapa: FE-09.A.05
- Entrega inicial: FE-09.A.05.1
- Branch canônica: `feature/formulacao-estrategica-operacional`
- Commit-base: `3e31b5d00e7b7bfe435fd3745f1cc7afe90cd0f9`
- Escopo: definição controlada dos painéis do Meu Espaço de Trabalho
- Banco de dados: sem alteração nesta entrega

## 2. Objetivo

Definir quais painéis poderão compor o Meu Espaço de Trabalho do SK-PE, quais contextos são exigidos, quais capacidades deverão ser observadas, quais rotas serão utilizadas e em qual situação cada painel poderá ser disponibilizado.

A matriz não autoriza dados simulados, rotas fictícias ou ações sem contrato funcional.

## 3. Regras gerais

Cada painel deverá declarar:

- identificador técnico;
- nome visível;
- finalidade;
- seção de destino;
- contexto mínimo;
- capacidade mínima;
- situação inicial;
- comportamento quando indisponível;
- possibilidade de drill-down.

A disponibilidade deverá considerar simultaneamente:

```text
capacidade do usuário
+
organização selecionada
+
projeto estratégico selecionado
+
Formulação selecionada
+
estágio de operacionalização da seção
```

## 4. Contextos reconhecidos

| Código | Contexto | Regra |
|---|---|---|
| `organization` | Organização | Obrigatório para qualquer operação do SK-PE. |
| `project` | Projeto Estratégico | Obrigatório para Jornada, visão executiva e conteúdos vinculados ao projeto. |
| `formulation` | Formulação e versão | Obrigatório para áreas de Formulação Estratégica e seus desdobramentos. |
| `cycle` | Ciclo de monitoramento | Obrigatório somente para áreas de acompanhamento dependentes de ciclo. |
| `user` | Usuário autenticado | Obrigatório para conteúdos pessoais, responsabilidades e preferências. |

## 5. Capacidades de referência

A primeira entrega deverá reutilizar as capacidades existentes no `SkpeCockpit`.

| Capacidade existente | Aplicação inicial |
|---|---|
| `can_view_overview` | Visualizar Meu Espaço de Trabalho e visão executiva. |
| `can_view_journey` | Acessar Jornada Estratégica. |
| `can_view_initiatives` | Acessar Iniciativas e Portfólio. |
| `can_view_artifacts` | Acessar Artefatos Metodológicos. |
| `can_view_governance` | Acessar Governança. |
| `can_manage_journey` | Executar ações autorizadas na Jornada. |
| `can_manage_artifacts` | Executar ações autorizadas em Artefatos. |
| `can_manage_skpe` | Executar ações amplas de gestão do módulo. |
| `can_generate_delivery_kit` | Gerar kit de entrega, quando aplicável. |
| `can_administer_users` | Administrar usuários, fora do escopo central do painel pessoal. |
| `can_administer_memberships` | Administrar vínculos, fora do escopo central do painel pessoal. |
| `can_administer_settings` | Administrar configurações, fora do escopo central do painel pessoal. |

Capacidades específicas para Indicadores, OKRs, Monitoramento e Formulação deverão ser vinculadas somente quando já existirem no catálogo efetivo. Até essa comprovação, a interface não deverá inventar novos códigos de autorização.

## 6. Matriz canônica dos painéis

| ID técnico | Painel visível | Finalidade | Seção de destino | Contexto mínimo | Capacidade mínima | Situação inicial |
|---|---|---|---|---|---|---|
| `my-work` | Meu Trabalho | Consolidar pendências, responsabilidades e acessos pessoais. | `overview` | `organization`, `user` | `can_view_overview` | Ativo como superfície inicial, com conteúdo limitado aos dados reais disponíveis. |
| `executive` | Executivo | Apresentar situação do projeto, progresso, etapa atual e horizonte. | `overview` | `organization`, `project` | `can_view_overview` | Ativo e integrado à página inicial. |
| `organization` | Organização | Acessar informações institucionais e administrativas autorizadas. | rota administrativa existente | `organization` | capacidade administrativa já existente | Não deve ser duplicado como painel operacional do SK-PE. Usar acesso contextual existente. |
| `formulation` | Formulação | Acessar governança, versões e conteúdos da Formulação Estratégica. | `formulations` | `organization`, `project`, `formulation` | capacidade efetiva de visualização da Formulação | Habilitar somente quando a seção estiver operacional e a capacidade estiver comprovada. |
| `indicators` | Indicadores | Acessar indicadores, metas e benchmarking. | `indicators` | `organization`, `project`, `formulation` | capacidade efetiva de indicadores | Habilitar somente com rota e contrato funcional comprovados. |
| `okrs` | Objetivos Estratégicos — OKRs | Acessar Objetivos Estratégicos, OKRs e Resultados-Chave. | `okrs` | `organization`, `project`, `formulation` | capacidade efetiva de OKRs | Habilitar somente com rota e contrato funcional comprovados. |
| `portfolio` | Portfólio | Acessar Iniciativas, programas, projetos e planos de ação. | `initiatives` | `organization`, `project` | `can_view_initiatives` | Ativo quando houver acesso autorizado. |
| `monitoring` | Monitoramento | Acessar ciclos, medições, check-ins e acompanhamento. | `monitoring` | `organization`, `project`, `formulation`; `cycle` quando exigido | capacidade efetiva de monitoramento | Habilitar somente quando a seção estiver operacional. |
| `governance` | Governança | Acessar papéis, decisões, validações e controles metodológicos. | `governance` | `organization`, `project` | `can_view_governance` | Ativo quando houver acesso autorizado. |

## 7. Acessos rápidos iniciais

Os acessos rápidos da FE-09.A.05.1 deverão ser restritos às áreas com destino válido.

| Acesso | Seção | Condição |
|---|---|---|
| Jornada Estratégica | `journey` | Exibir quando `can_view_journey` for verdadeiro e houver projeto. |
| Formulações | `formulations` | Exibir quando a rota estiver operacional e houver Formulação selecionada ou processo válido de seleção. |
| Identidade Estratégica | `identity` | Exibir quando a seção estiver operacional e houver Formulação. |
| Fundamentação do Negócio | `business-foundation` | Exibir quando a seção estiver operacional e houver Formulação. |
| Cadeia de Valor | `value-chain` | Exibir quando a seção estiver operacional e houver Formulação. |
| Mapa Estratégico | `strategic-map` | Exibir quando a seção estiver operacional e houver Formulação. |
| Indicadores | `indicators` | Exibir quando a seção e a capacidade estiverem comprovadas. |
| Objetivos Estratégicos — OKRs | `okrs` | Exibir quando a seção e a capacidade estiverem comprovadas. |
| Iniciativas | `initiatives` | Exibir quando `can_view_initiatives` for verdadeiro. |
| Monitoramento | `monitoring` | Exibir quando a seção e a capacidade estiverem comprovadas. |
| Governança | `governance` | Exibir quando `can_view_governance` for verdadeiro. |
| Artefatos | `artifacts` | Exibir quando `can_view_artifacts` for verdadeiro. |

## 8. Estados por ausência de contexto

| Contexto ausente | Comportamento obrigatório |
|---|---|
| Organização | Bloquear o conteúdo operacional e orientar retorno à seleção de organização. |
| Projeto Estratégico | Apresentar estado de jornada ainda não iniciada, sem usar dados de outra organização. |
| Formulação | Explicar que a área depende de Formulação selecionada e oferecer ação válida de seleção ou criação, quando autorizada. |
| Ciclo | Manter o painel indisponível quando o conteúdo depender de ciclo e explicar o motivo. |
| Usuário | Encerrar o fluxo autenticado e não renderizar conteúdo pessoal. |

## 9. Estados por ausência de capacidade

Quando o usuário não possuir a capacidade exigida:

- ocultar o painel quando sua existência não agregar orientação;
- apresentar o painel desabilitado quando for útil explicar a indisponibilidade;
- informar o motivo em Português do Brasil;
- não oferecer ação que resulte em erro de autorização;
- preservar modo somente leitura quando o backend autorizar consulta sem edição.

Mensagens recomendadas:

```text
Você não possui permissão para acessar este painel.
```

```text
Este painel está disponível somente para perfis autorizados neste contexto.
```

```text
A consulta está disponível em modo somente leitura.
```

## 10. Situação de habilitação

O registro declarativo deverá admitir, no mínimo:

```ts
type WorkspaceDashboardAvailability =
  | 'enabled'
  | 'disabled'
  | 'coming-soon'
  | 'requires-context'
  | 'forbidden'
```

Significados:

| Situação | Uso |
|---|---|
| `enabled` | Destino funcional, contexto válido e capacidade autorizada. |
| `disabled` | Estrutura conhecida, mas indisponível por decisão funcional temporária. |
| `coming-soon` | Área prevista, ainda não operacionalizada. Não deve simular funcionalidade. |
| `requires-context` | Depende de projeto, Formulação ou ciclo ainda não selecionado. |
| `forbidden` | Usuário sem capacidade para o contexto atual. |

## 11. Drill-down

Todo painel analítico habilitado deverá permitir navegação até registros de origem.

Na FE-09.A.05.1:

- cards executivos poderão abrir Jornada ou Governança;
- acessos rápidos abrirão seções existentes;
- nenhum card deverá apontar para rota inexistente;
- nenhum painel deverá usar ação genérica sem destino;
- o clique deverá funcionar também por teclado;
- o navegador deverá preservar back, forward e refresh.

## 12. Conteúdos pessoais

Os conteúdos abaixo fazem parte do roadmap, mas somente poderão ser exibidos após comprovação da origem de dados:

| Conteúdo | Situação na FE-09.A.05.1 |
|---|---|
| Minhas pendências | Pendente de contrato consolidado ou adaptação segura de dados existentes. |
| Meus indicadores | Pendente de vínculo comprovado entre indicador e usuário. |
| Meus KRs | Pendente de vínculo comprovado entre KR e usuário. |
| Minhas Iniciativas | Pode ser ativado quando o vínculo de responsabilidade estiver comprovado. |
| Minhas decisões | Pendente de contrato de decisões por responsável ou participante. |
| Validações aguardando atuação | Pode ser derivado apenas se a origem real estiver disponível. |
| Reuniões próximas | Pendente de contrato funcional comprovado. |
| Alertas | Somente alertas derivados de dados reais; não criar central fictícia. |
| Prazos vencidos | Pode ser derivado de registros reais com prazo e responsabilidade. |
| Favoritos | Pendente de persistência transversal de preferência do usuário. |

## 13. Registro declarativo proposto

A implementação poderá utilizar uma estrutura equivalente a:

```ts
import type { SkpeRouteSection } from '../app/skpeRoutes'

export type WorkspaceDashboardId =
  | 'my-work'
  | 'executive'
  | 'organization'
  | 'formulation'
  | 'indicators'
  | 'okrs'
  | 'portfolio'
  | 'monitoring'
  | 'governance'

export type WorkspaceRequiredContext =
  | 'organization'
  | 'project'
  | 'formulation'
  | 'cycle'
  | 'user'

export type WorkspaceDashboardDefinition = {
  id: WorkspaceDashboardId
  label: string
  description: string
  section: SkpeRouteSection | null
  requiredContext: WorkspaceRequiredContext[]
  requiredCapability: string | null
  enabled: boolean
}
```

A estrutura final deverá usar os tipos já existentes sempre que possível.

## 14. Proibições

Nesta entrega, é proibido:

- criar capacidade de frontend sem contrato correspondente;
- considerar rótulo de perfil como autorização suficiente;
- criar painel sem rota válida;
- criar card com número simulado;
- criar favorito não persistente;
- criar notificação fictícia;
- exibir dados de outra organização como fallback;
- duplicar a administração da organização dentro do SK-PE;
- criar migration sem lacuna comprovada;
- realizar merge.

## 15. Critérios de aceite da matriz

A matriz será considerada validada quando:

- todos os painéis canônicos estiverem catalogados;
- cada painel tiver contexto mínimo definido;
- cada painel tiver capacidade ou pendência de capacidade identificada;
- nenhuma rota fictícia estiver autorizada;
- painéis não operacionalizados estiverem explicitamente marcados;
- conteúdos pessoais sem contrato real permanecerem desabilitados;
- o modo somente leitura estiver previsto;
- o drill-down estiver associado a destinos válidos;
- não houver necessidade de alteração no banco nesta entrega.
