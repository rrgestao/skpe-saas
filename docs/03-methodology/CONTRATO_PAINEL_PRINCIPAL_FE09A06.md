# Contrato do Painel Principal — FE-09.A.06

## 1. Identificação

- Projeto: SPARKs-PaaS / SK-PE SaaS
- Frente: Formulação Estratégica Operacional
- Etapa: FE-09.A.06
- Entrega inicial: FE-09.A.06-A
- Objeto: Painel Principal e fundação transversal de preferências do usuário
- Branch: feature/formulacao-estrategica-operacional
- Base: develop

## 2. Objetivo

Estabelecer o contrato funcional, arquitetural e operacional para permitir que o usuário autenticado defina um painel elegível como seu Painel Principal na Plataforma SPARKs.

A preferência deverá ser persistente, auditável e validada conforme:

- usuário autenticado;
- organização;
- módulo;
- contexto disponível;
- capacidades efetivas;
- disponibilidade operacional do painel.
## 3. Contexto

A FE-09.A.05 implementou o Meu Espaço de Trabalho e consolidou:

- catálogo declarativo de painéis;
- identificadores estáveis;
- contextos obrigatórios;
- capacidades exigidas;
- disponibilidade padrão;
- destinos de navegação;
- suporte a drill-down;
- estados Atual, Disponível, Em breve, Requer contexto, Sem permissão e Indisponível.

A inspeção confirmou que não existe estrutura persistente transversal para:

- Painel Principal;
- favoritos;
- preferências funcionais do usuário;
- personalização vinculada a usuário, organização e módulo.
## 4. Decisão arquitetural

O Painel Principal não será armazenado em:

- localStorage;
- sessionStorage;
- estado transitório do React;
- campo específico em public.profiles;
- public.organization_modules.configuration;
- estrutura exclusiva do SK-PE;
- preferência fictícia ou não persistente.

Será criada uma fundação transversal vinculada a:

- usuário;
- organização;
- módulo;
- chave da preferência;
- valor estruturado;
- autoria;
- criação;
- atualização.

A denominação técnica preliminar é public.user_module_preferences.

O nome somente será efetivado após a validação da matriz de preferências e do desenho da migration.
## 5. Primeiro caso de uso

O primeiro caso de uso será a preferência workspace.primary_dashboard.

O valor deverá identificar um item válido do tipo WorkspaceDashboardId.

Identificadores reconhecidos inicialmente:

- my-work;
- executive;
- organization;
- formulation;
- indicators;
- okrs;
- portfolio;
- monitoring;
- governance.

A persistência do identificador não substitui a validação funcional realizada pelo catálogo declarativo.

## 6. Escopo da preferência

A preferência deverá ser isolada por:

- usuário autenticado;
- organização;
- módulo SK-PE.

O mesmo usuário poderá possuir Painéis Principais diferentes em organizações distintas.

Preferências de uma organização não poderão ser aplicadas em outra organização.

Preferências de um módulo não poderão ser reutilizadas por outro módulo sem contrato explícito.

## 7. Elegibilidade

Um painel somente poderá ser definido como Painel Principal quando:

- existir em WORKSPACE_DASHBOARDS;
- estiver marcado como elegível;
- estiver operacionalmente disponível;
- possuir o contexto obrigatório;
- respeitar as capacidades do usuário;
- possuir destino ou comportamento funcional definido;
- não estiver disabled;
- não estiver coming-soon;
- não estiver requires-context;
- não estiver forbidden.

A elegibilidade deverá ser declarativa e não duplicada na interface.
## 8. Leitura

A leitura deverá:

- utilizar o usuário autenticado do banco;
- receber organização e módulo do contexto atual;
- retornar somente a preferência do próprio usuário;
- não expor preferências de terceiros;
- não depender de user_id enviado livremente pelo frontend;
- retornar ausência de preferência sem erro funcional;
- permitir fallback quando o valor persistido não for válido.

## 9. Gravação

A gravação deverá:

- utilizar auth.uid();
- validar a organização;
- validar o módulo;
- validar a chave permitida;
- validar o formato do valor;
- substituir controladamente a preferência anterior;
- registrar o estado anterior e o novo;
- impedir gravação em nome de outro usuário;
- impedir gravação em organização sem acesso ativo;
- impedir gravação em módulo sem acesso ativo.

A alteração do Painel Principal é uma configuração pessoal e não deverá exigir permissão administrativa.

## 10. Auditoria

A alteração deverá registrar evento em public.privileged_access_audit.

Parâmetros esperados:

- actor_user_id: usuário autenticado;
- organization_id: organização atual;
- event_type: configuration_changed;
- entity_schema: public;
- entity_table: tabela transversal de preferências;
- entity_id: identificador da preferência;
- previous_data: estado anterior;
- new_data: estado atualizado;
- metadata: módulo, chave, origem e contexto.

A auditoria não deverá armazenar dados sensíveis desnecessários.
## 11. Redefinição

O usuário deverá poder remover sua preferência.

Quando removida:

- a operação deverá ser auditada;
- o sistema deverá voltar ao fallback;
- nenhuma mensagem poderá afirmar que existe preferência salva.

## 12. Fallback seguro

Na ausência de preferência válida, a ordem proposta será:

1. my-work, quando disponível;
2. executive, quando my-work não estiver elegível;
3. Meu Espaço de Trabalho sem navegação automática.

O fallback:

- não gravará preferência automaticamente;
- não navegará para painel proibido;
- não reutilizará preferência de outra organização;
- não utilizará dados simulados;
- não provocará loop de navegação.

## 13. Preferência inválida

A preferência será considerada inválida quando:

- o identificador não existir no catálogo;
- o painel estiver desabilitado;
- o painel estiver indisponível;
- faltar contexto obrigatório;
- faltar capacidade;
- o usuário perder acesso à organização;
- o módulo estiver suspenso ou desativado;
- o destino funcional deixar de existir.

Nesses casos:

- será aplicado o fallback seguro;
- a navegação indevida será impedida;
- a interface poderá informar a indisponibilidade;
- a preferência não será substituída silenciosamente.
## 14. Catálogo declarativo

WORKSPACE_DASHBOARDS continuará como fonte oficial dos painéis reconhecidos pelo frontend.

O catálogo deverá evoluir para declarar:

- elegibilidade para Painel Principal;
- prioridade de fallback;
- destino operacional;
- disponibilidade;
- contexto;
- capacidade.

A interface não deverá manter listas paralelas ou regras duplicadas.

## 15. Interface

A interface deverá permitir:

- identificar o Painel Principal atual;
- definir um painel elegível como principal;
- substituir a preferência existente;
- remover ou redefinir a preferência;
- apresentar estado de carregamento;
- apresentar estado de salvamento;
- apresentar erro real de persistência;
- impedir ação em painel inelegível;
- operar por clique;
- operar por Enter;
- operar por Espaço;
- manter foco visível;
- utilizar textos em Português do Brasil.

Nenhum controle funcional deverá ser exibido antes da disponibilidade dos contratos persistentes.

## 16. Estados obrigatórios

A implementação deverá tratar:

- carregando preferência;
- preferência ausente;
- preferência válida;
- preferência inválida;
- salvando;
- salvo;
- erro de leitura;
- erro de gravação;
- painel inelegível;
- perda de contexto durante a operação.
## 17. Segurança

A solução deverá:

- habilitar RLS;
- restringir leitura e gravação ao proprietário;
- validar acesso ativo à organização;
- validar acesso ativo ao módulo;
- preferir RPCs security definer;
- controlar o search_path;
- revogar escrita direta para clientes autenticados;
- não aceitar user_id arbitrário como autoridade;
- não confiar apenas no frontend;
- manter trilha de auditoria.

## 18. Evolução transversal

A fundação deverá permitir evolução futura para:

- favoritos;
- última visualização válida;
- preferências de exibição;
- filtros salvos;
- densidade visual;
- ordenação preferida;
- painéis fixados.

Esses casos não fazem parte da implementação funcional desta entrega.

## 19. Fora do escopo

A FE-09.A.06 não contempla:

- implementação funcional de Favoritos;
- construtor livre de painéis;
- criação de painéis personalizados;
- compartilhamento de preferências entre usuários;
- preferência global entre organizações;
- preferências administradas por terceiros;
- central de notificações;
- filtros salvos;
- alterações em develop ou main;
- merge;
- reescrita integral do SkpeCockpit;
- persistência definitiva no navegador.

## 20. Critérios de aceite

1. Contrato documental aprovado.
2. Matriz de preferências aprovada.
3. Persistência isolada por usuário, organização e módulo.
4. Leitura e gravação baseadas no usuário autenticado.
5. RLS habilitado.
6. Escrita direta bloqueada.
7. Alterações auditadas.
8. Somente painéis elegíveis selecionáveis.
9. Preferência inválida resulta em fallback seguro.
10. Preferência permanece após nova sessão.
11. Nenhuma preferência atravessa organizações.
12. Nenhuma navegação indevida ocorre.
13. Controles funcionam por clique, Enter e Espaço.
14. Textos em Português do Brasil.
15. Ausência de dados simulados.
16. Lint sem novos erros.
17. Build de produção aprovado.
18. Validação funcional aprovada.
19. Árvore Git limpa após o commit.
20. Nenhum merge realizado.

## 21. Estratégia incremental

FE-09.A.06-A — contrato e matriz de preferências
FE-09.A.06-B — fundação persistente transversal
FE-09.A.06-C — RPCs, RLS e auditoria
FE-09.A.06-D — integração ao catálogo de painéis
FE-09.A.06-E — seleção e apresentação do Painel Principal
FE-09.A.06-F — fallback, acessibilidade e validação funcional
FE-09.A.06-G — lint, build, documentação, commit e publicação

## 22. Regra de execução

Nenhuma migration ou alteração funcional será iniciada antes da validação deste contrato e da Matriz de Preferências do Usuário.

Nenhum commit será realizado antes de:

- lint;
- build;
- validação funcional;
- validação de acessibilidade;
- validação de UTF-8;
- revisão da documentação.
