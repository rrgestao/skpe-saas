# Contrato do Meu Espaço de Trabalho — FE-09.A.05

## 1. Identificação

- Projeto: Plataforma SPARKs
- Módulo: SK-PE — Planejamento Estratégico
- Etapa: FE-09.A.05
- Entrega inicial: FE-09.A.05.1
- Branch canônica: `feature/formulacao-estrategica-operacional`
- Commit-base: `3e31b5d00e7b7bfe435fd3745f1cc7afe90cd0f9`
- Situação inicial: contrato arquitetural para validação
- Escopo: frontend incremental, sem migration nesta entrega

## 2. Objetivo

Estabelecer o Meu Espaço de Trabalho como superfície inicial contextual do módulo SK-PE, consolidando informações, acessos e painéis relevantes ao usuário sem duplicar regras de negócio, estruturas de navegação ou contratos já existentes.

A entrega deve preservar:

- contexto organizacional;
- contexto de projeto estratégico;
- contexto de Formulação;
- capacidades e modo de acesso;
- navegação profunda;
- rastreabilidade;
- responsividade;
- compatibilidade com o cockpit existente.

## 3. Decisão arquitetural

O Meu Espaço de Trabalho do SK-PE utilizará a seção canônica:

```text
overview
```

na rota contextual:

```text
/organizations/:organizationId/skpe/projects/:projectId/formulations/:formulationId/overview
```

A rota global `/workspace` não será utilizada como painel operacional do SK-PE nesta entrega, pois representa uma área global da plataforma e não preserva necessariamente o contexto de organização, projeto e Formulação.

Não será criado um segundo sistema de rotas.

## 4. Estruturas obrigatoriamente reutilizadas

A implementação deverá reutilizar:

- `ApplicationShell`;
- `SkpeWorkspace`;
- `SkpeWorkspaceContext`;
- `skpeRoutes`;
- capacidades já carregadas pelo `SkpeCockpit`;
- contexto de projeto estratégico;
- dados reais da Jornada Estratégica;
- rotas existentes de Formulação, Indicadores, OKRs, Iniciativas, Monitoramento, Governança e Artefatos;
- catálogo de textos em Português do Brasil;
- estilos responsivos já estabilizados.

## 5. Escopo da FE-09.A.05.1

A primeira entrega deverá contemplar:

1. página contextual denominada “Meu Espaço de Trabalho”;
2. síntese do projeto estratégico atualmente selecionado;
3. acessos rápidos para áreas existentes;
4. registro declarativo dos Painéis Disponíveis;
5. estados sem projeto e sem Formulação;
6. indicação de acesso somente leitura;
7. uso exclusivo de dados reais já disponíveis;
8. preservação da visão executiva existente;
9. navegação por rotas válidas;
10. funcionamento em desktop, tablet e mobile.

## 6. Conteúdos previstos

O Meu Espaço de Trabalho poderá apresentar, conforme disponibilidade real dos contratos:

- situação do projeto estratégico;
- progresso estimado;
- etapa atual;
- horizonte estratégico;
- pendências atribuídas;
- itens vencidos;
- validações aguardando atuação;
- indicadores sob responsabilidade;
- Resultados-Chave sob responsabilidade;
- Iniciativas sob responsabilidade;
- decisões;
- reuniões;
- alertas derivados;
- acessos rápidos;
- Painéis Disponíveis.

A presença no contrato não autoriza a apresentação de dados simulados. Cada conteúdo somente poderá ser ativado quando houver origem de dados e regra de acesso comprovadas.

## 7. Painéis canônicos

O registro de painéis deverá admitir:

- Meu Trabalho;
- Executivo;
- Organização;
- Formulação;
- Indicadores;
- OKRs;
- Portfólio;
- Monitoramento;
- Governança.

Cada painel deverá declarar:

- identificador;
- nome;
- descrição;
- rota ou seção de destino;
- contexto exigido;
- capacidade exigida;
- situação de habilitação;
- motivo de indisponibilidade, quando aplicável.

## 8. Regras de capacidades

A interface deverá distinguir:

```text
o que o usuário pode visualizar
+
o que o usuário pode executar
+
em qual organização pode executar
+
em qual projeto e Formulação pode executar
```

A ausência de capacidade deverá:

- ocultar ações não aplicáveis ou apresentá-las desabilitadas quando a explicação for metodologicamente útil;
- preservar acesso somente leitura quando autorizado;
- não depender apenas de rótulos de perfil;
- não recalcular autorização no frontend.

## 9. Estados obrigatórios

A página deverá tratar explicitamente:

- carregamento;
- organização indisponível;
- projeto estratégico inexistente;
- Formulação não selecionada;
- ausência de registros;
- acesso somente leitura;
- painel indisponível;
- falha de consulta;
- rota não reconhecida;
- conteúdo ainda não operacionalizado.

Nenhum estado vazio poderá ser preenchido com informações de outra organização.

## 10. Regras de dados

Nesta entrega:

- não criar tabela;
- não criar view;
- não criar RPC;
- não criar migration;
- não duplicar entidades;
- não recalcular regras de negócio no React;
- não usar dados simulados;
- não criar persistência fictícia para favoritos;
- não criar notificações sem contrato real;
- não criar botões sem destino funcional.

Caso a inspeção posterior comprove insuficiência dos contratos existentes, uma proposta específica deverá ser apresentada antes de qualquer alteração de banco.

## 11. Favoritos e Painel Principal

Favoritos e Painel Principal fazem parte do roadmap, mas somente poderão ser ativados após comprovação de estrutura persistente para preferências do usuário.

Até essa comprovação:

- não exibir controle de favorito funcional;
- não armazenar preferência apenas em estado transitório;
- não afirmar que uma preferência foi salva;
- não criar tabela específica sem avaliação transversal da Plataforma SPARKs.

## 12. Acessos rápidos

Os acessos rápidos deverão utilizar rotas existentes e poderão incluir:

- Jornada Estratégica;
- Formulações;
- Identidade Estratégica;
- Fundamentação do Negócio;
- Cadeia de Valor;
- Mapa Estratégico;
- Indicadores;
- Objetivos Estratégicos — OKRs;
- Iniciativas;
- Monitoramento;
- Governança;
- Artefatos.

A apresentação deverá considerar capacidade, contexto e estágio de operacionalização de cada área.

## 13. Interação

Os cards e linhas deverão seguir o padrão transversal da Plataforma SPARKs:

- destaque visual no hover;
- ações rápidas quando aplicável;
- clique na área útil para abrir o destino;
- suporte a teclado;
- indicação de foco;
- ausência de abertura automática no hover;
- ação direta em um clique quando segura e aplicável.

## 14. Responsividade e rolagem

A entrega deverá preservar integralmente a estabilização da FE-09.A.04:

- uma única rolagem vertical principal;
- ausência de scroll traps;
- ausência de captura indevida da roda do mouse;
- rolagem horizontal somente em componentes que realmente necessitem;
- ausência de sobreposição;
- cabeçalho compacto em tablet e mobile;
- ausência de rolagem horizontal indevida na aplicação.

## 15. Idioma e nomenclatura

Todos os textos visíveis deverão utilizar Português do Brasil.

A nomenclatura visível deverá utilizar:

```text
Objetivos Estratégicos — OKRs
```

quando houver referência integrada a Objetivos Estratégicos e OKRs.

Não utilizar textos sem acentuação na interface, salvo identificadores técnicos internos.

## 16. Limites da entrega

A FE-09.A.05.1 não contempla:

- construtor livre de dashboards;
- drag and drop de painéis;
- central completa de notificações;
- mensageria;
- decomposição integral do `SkpeCockpit`;
- reescrita do shell;
- substituição do roteamento;
- mudanças em `develop` ou `main`;
- merge;
- persistência nova sem lacuna comprovada.

## 17. Estratégia incremental

A execução seguirá:

```text
FE-09.A.05.1-A — contratos e critérios
FE-09.A.05.1-B — tipos e registro declarativo
FE-09.A.05.1-C — página Meu Espaço de Trabalho
FE-09.A.05.1-D — integração controlada ao overview
FE-09.A.05.1-E — responsividade e acessibilidade
FE-09.A.05.1-F — validação, commit e publicação
```

## 18. Critério de encerramento

A etapa somente poderá ser encerrada após:

- contrato validado;
- lista branca aprovada;
- implementação restrita à branch;
- lint com zero erros;
- build aprovado;
- validação funcional;
- validação responsiva;
- inspeção do diff;
- working tree controlado;
- commit pequeno e reversível;
- push confirmado;
- nenhum merge realizado.
