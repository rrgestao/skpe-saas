# Matriz de Preferências do Usuário — FE-09.A.06

## 1. Identificação

- Projeto: SPARKs-PaaS / SK-PE SaaS
- Frente: Formulação Estratégica Operacional
- Etapa: FE-09.A.06
- Entrega: FE-09.A.06-A
- Objeto: matriz transversal de preferências por usuário, organização e módulo

## 2. Objetivo

Definir as dimensões, regras, chaves, valores, validações, fallback e critérios de segurança para a futura fundação de preferências da Plataforma SPARKs.

## 3. Princípios

- preferência pertence ao usuário autenticado;
- preferência é isolada por organização;
- preferência é isolada por módulo;
- preferência não substitui autorização;
- preferência não substitui contexto;
- preferência não torna painel indisponível em painel válido;
- preferência não será persistida em navegador como solução definitiva;
- leitura e gravação deverão ocorrer por contratos protegidos;
- alterações deverão ser auditadas;
- ausência de preferência é um estado válido;
- valores inválidos deverão produzir fallback seguro;
- a fundação deverá ser reutilizável por outros módulos.
## 4. Dimensões da preferência

| Dimensão | Origem | Obrigatória | Regra |
|---|---|---:|---|
| Usuário | auth.uid() | Sim | Não poderá ser informado livremente pelo frontend. |
| Organização | contexto atual | Sim | Deverá existir e estar acessível ao usuário. |
| Módulo | catálogo public.modules | Sim | Deverá existir, estar ativo e disponível na organização. |
| Chave | contrato funcional | Sim | Deverá pertencer à lista branca de preferências suportadas. |
| Valor | payload estruturado | Sim | Deverá respeitar o esquema da chave informada. |
| Origem | contrato de gravação | Sim | Deverá registrar a funcionalidade que solicitou a alteração. |
| Criado em | banco | Sim | Gerado automaticamente. |
| Atualizado em | banco | Sim | Atualizado automaticamente. |

## 5. Primeiro caso de uso

| Campo | Valor |
|---|---|
| Módulo | SK-PE |
| Chave | workspace.primary_dashboard |
| Tipo lógico | WorkspaceDashboardId |
| Escopo | usuário + organização + módulo |
| Permissão administrativa | Não exigida |
| Persistência em navegador | Não permitida como solução definitiva |
| Auditoria | Obrigatória |
| Fallback | Obrigatório |
| Exclusão ou redefinição | Permitida |
## 6. Matriz de elegibilidade dos painéis

| Painel | Identificador | Estado atual | Elegível como Painel Principal | Condição |
|---|---|---|---:|---|
| Meu Trabalho | my-work | Habilitado | Sim | Organização, usuário autenticado e capacidade de visão geral. |
| Executivo | executive | Habilitado | Sim | Organização, projeto ativo e capacidade de visão geral. |
| Organização | organization | Indisponível | Não | Sem destino funcional operacional na entrega atual. |
| Formulação | formulation | Em breve | Não | Depende de Formulação selecionada e ativação funcional futura. |
| Indicadores | indicators | Em breve | Não | Depende de Formulação selecionada e ativação funcional futura. |
| Objetivos Estratégicos — OKRs | okrs | Em breve | Não | Depende de Formulação selecionada e ativação funcional futura. |
| Portfólio | portfolio | Habilitado | Sim | Organização, projeto ativo e capacidade de visualizar Iniciativas. |
| Monitoramento | monitoring | Em breve | Não | Depende de Formulação, ciclo e ativação funcional futura. |
| Governança | governance | Habilitado | Sim | Organização, projeto ativo e capacidade de visualizar Governança. |

A elegibilidade deverá ser derivada do catálogo declarativo e validada novamente no momento da leitura e da gravação da preferência.
## 7. Regras de validação

| Regra | Momento | Resultado esperado |
|---|---|---|
| Usuário autenticado | leitura e gravação | Operação recusada quando auth.uid() estiver ausente. |
| Organização existente | leitura e gravação | Operação recusada quando a organização não existir. |
| Acesso ativo à organização | leitura e gravação | Operação recusada quando o usuário não possuir vínculo válido. |
| Módulo existente | leitura e gravação | Operação recusada quando o módulo não existir. |
| Módulo ativo na organização | leitura e gravação | Operação recusada quando o módulo estiver suspenso, cancelado ou desabilitado. |
| Chave permitida | gravação | Operação recusada quando a chave não estiver na lista branca. |
| Valor compatível | gravação | Operação recusada quando o valor não respeitar o contrato da chave. |
| Painel existente | leitura e gravação | Preferência inválida quando o identificador não existir no catálogo. |
| Painel elegível | gravação | Operação recusada para painel inelegível. |
| Contexto suficiente | leitura e gravação | Preferência não aplicada quando faltar contexto obrigatório. |
| Capacidade efetiva | leitura e gravação | Preferência não aplicada quando faltar permissão. |
| Destino funcional | leitura e gravação | Preferência não aplicada quando não houver comportamento operacional válido. |

## 8. Matriz de fallback

| Situação | Resultado | Grava preferência automaticamente |
|---|---|---:|
| Preferência válida e painel elegível | Aplicar Painel Principal persistido. | Não |
| Preferência ausente e my-work elegível | Usar my-work como fallback visual. | Não |
| my-work inelegível e executive elegível | Usar executive como fallback visual. | Não |
| Nenhum painel elegível | Permanecer no Meu Espaço de Trabalho sem navegação automática. | Não |
| Identificador desconhecido | Ignorar preferência e aplicar fallback seguro. | Não |
| Painel sem contexto | Ignorar preferência no contexto atual. | Não |
| Painel sem capacidade | Impedir aplicação e usar fallback seguro. | Não |
| Organização diferente | Não reutilizar a preferência. | Não |
| Módulo diferente | Não reutilizar a preferência. | Não |

## 9. Matriz de auditoria

| Operação | event_type | previous_data | new_data | metadata mínima |
|---|---|---|---|---|
| Criar preferência | configuration_changed | null | nova preferência | módulo, chave, origem e painel |
| Substituir preferência | configuration_changed | preferência anterior | preferência atualizada | módulo, chave, origem e painel |
| Remover preferência | configuration_changed | preferência anterior | null | módulo, chave, origem e motivo |
| Tentativa inválida | não registrar como alteração concluída | não aplicável | não aplicável | erro retornado ao chamador |

A auditoria deverá registrar somente operações efetivamente concluídas.
## 10. Matriz de segurança

| Controle | Regra |
|---|---|
| Identidade | Utilizar auth.uid() como autoridade do usuário. |
| Leitura | Retornar somente preferências pertencentes ao usuário autenticado. |
| Gravação | Permitir somente alteração de preferências do próprio usuário. |
| Organização | Validar vínculo ativo ou acesso descendente autorizado. |
| Módulo | Validar módulo ativo e disponível na organização. |
| Escrita direta | Revogar INSERT, UPDATE e DELETE diretos para authenticated. |
| RPC | Utilizar security definer com search_path controlado. |
| RLS | Habilitar e manter políticas restritivas. |
| Parâmetro user_id | Não aceitar como autoridade enviada pelo frontend. |
| Auditoria | Registrar somente operações concluídas. |
| Dados sensíveis | Não armazenar conteúdo sensível desnecessário no valor ou na auditoria. |

## 11. Evolução futura

A fundação poderá suportar novas chaves, desde que cada uma possua contrato próprio, lista branca e esquema de valor validável.

Casos futuros previstos:

- workspace.favorites;
- workspace.last_valid_view;
- display.density;
- display.ordering;
- filters.saved;
- dashboards.pinned.

Nenhuma dessas chaves será ativada automaticamente pela FE-09.A.06.

## 12. Critérios de aceite da matriz

1. Dimensões obrigatórias definidas.
2. Primeiro caso de uso definido.
3. Elegibilidade dos painéis documentada.
4. Regras de validação documentadas.
5. Fallback seguro documentado.
6. Auditoria documentada.
7. Segurança documentada.
8. Evolução futura separada do escopo atual.
9. Ausência de persistência fictícia.
10. Ausência de dependência de localStorage como solução definitiva.
11. Textos em Português do Brasil.
12. UTF-8 preservado.

## 13. Decisão da etapa

A FE-09.A.06-A somente será considerada concluída após:

- revisão conjunta do contrato;
- revisão conjunta desta matriz;
- validação do nome da tabela transversal;
- validação das RPCs previstas;
- validação da estratégia de RLS;
- validação do registro de auditoria;
- autorização explícita para iniciar a migration.
