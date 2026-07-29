# REQ-PLAT-ORG-001 — Home da Organização e Roteamento Inteligente

## 1. Identificação

- **Produto:** Plataforma SPARKs
- **Camada:** Plataforma / Experiência de acesso
- **Status:** Aprovado
- **Natureza:** Requisito canônico com implementação futura
- **Data da decisão:** 2026-07-29
- **Prioridade:** Alta, após estabilização e uso real da solução com a próxima cooperativa
- **Branch futura sugerida:** `feature/home-organizacao-roteamento-inteligente`

## 2. Decisão

A Plataforma SPARKs deverá possuir uma **Home da Organização — Visão Consolidada de Gestão**, utilizada como ponto principal de entrada do usuário após a autenticação, quando houver uma organização operacional direta e inequivocamente selecionável.

A tela **Minhas Organizações** continuará existindo como seletor de contexto organizacional, tela de escolha inicial e mecanismo permanente de troca de organização.

A implementação foi deliberadamente adiada para não comprometer a estabilização e o uso imediato da solução no próximo projeto real de Planejamento Estratégico.

## 3. Objetivos

1. Reduzir cliques desnecessários após o login.
2. Posicionar a organização, e não um módulo isolado, como contexto principal da Plataforma SPARKs.
3. Dar acesso imediato ao desempenho consolidado, aos módulos disponíveis e às prioridades do usuário.
4. Preservar uma experiência segura para usuários vinculados a múltiplas organizações.
5. Separar claramente vínculo direto, acesso hierárquico e acesso somente para leitura.

## 4. Regras de roteamento após o login

### 4.1 SUPER-ADMIN

O usuário SUPER-ADMIN deverá acessar inicialmente a **Administração Global da Plataforma**, antes de selecionar qualquer organização.

### 4.2 Uma única organização direta

Quando o usuário possuir vínculo direto com somente uma organização válida, deverá acessar imediatamente a **Home da Organização**.

### 4.3 Múltiplas organizações diretas sem preferência válida

Quando o usuário possuir vínculo direto com mais de uma organização e não existir uma última organização válida registrada, deverá acessar a tela **Minhas Organizações**.

### 4.4 Múltiplas organizações diretas com preferência válida

Quando o usuário possuir vínculo direto com mais de uma organização e houver uma última organização válida registrada, poderá acessar diretamente a **Home da última organização utilizada**.

A troca de organização deverá permanecer disponível em área claramente visível.

### 4.5 Acesso hierárquico ou somente para leitura

Organizações acessíveis apenas por relacionamento hierárquico ou permissão somente para leitura não deverão, isoladamente, determinar a organização operacional inicial do usuário.

Exemplo: um administrador do SESCOOP/DF com vínculo direto ao SESCOOP/DF e acesso hierárquico de leitura à COOTAQUARA deverá acessar prioritariamente a Home do SESCOOP/DF.

### 4.6 Acesso revogado ou organização inválida

Quando a última organização utilizada não estiver mais válida, ativa ou acessível, o sistema deverá ignorar a preferência e encaminhar o usuário para **Minhas Organizações**.

## 5. Conteúdo futuro da Home da Organização

A Home deverá evoluir como um cockpit organizacional e poderá consolidar:

- desempenho global da organização;
- módulos contratados, ativos e disponíveis;
- andamento do Planejamento Estratégico;
- projetos, fases e entregas;
- alertas críticos;
- pendências e prioridades;
- validações aguardando ação;
- responsabilidades atribuídas ao usuário;
- reuniões, decisões e evidências pendentes;
- documentos com revisão necessária;
- atividades recentes;
- atalhos para ações frequentes;
- troca de organização.

## 6. Princípios funcionais

1. A Home da Organização não deverá ser apenas um menu de módulos.
2. Alertas deverão possuir origem, criticidade, responsável, prazo e estado.
3. O usuário deverá visualizar apenas informações permitidas por seu perfil e escopo.
4. A visibilidade hierárquica não deverá conceder capacidade de edição.
5. O painel deverá ser extensível para outros módulos da Plataforma SPARKs.
6. A ausência de pendências deverá ser explicitamente informada.
7. A interface deverá funcionar adequadamente em desktop e telas menores.
8. O acesso à tela Minhas Organizações deverá permanecer disponível.

## 7. Estratégia de implementação futura

### Incremento 1 — Roteamento inteligente

- identificar organizações diretas;
- diferenciar acesso direto, hierárquico e somente leitura;
- registrar última organização utilizada;
- validar a preferência antes de reutilizá-la;
- encaminhar o usuário para a tela correta;
- disponibilizar troca de organização.

### Incremento 2 — Home básica da Organização

- identificação institucional;
- módulos ativos e disponíveis;
- atalhos principais;
- resumo do Planejamento Estratégico;
- atividades recentes.

### Incremento 3 — Central de alertas e pendências

- modelo transversal de alertas;
- criticidade;
- prioridade;
- atribuição a usuários;
- prazos;
- resolução;
- auditoria;
- origem por módulo.

### Incremento 4 — Visão consolidada de desempenho

- indicadores organizacionais;
- indicadores por módulo;
- filtros;
- tendências;
- compromissos estratégicos;
- painéis executivos.

## 8. Critérios mínimos de aceite do roteamento

1. SUPER-ADMIN entra na Administração Global.
2. Usuário com uma organização direta entra na Home dessa organização.
3. Usuário com múltiplas organizações diretas e sem preferência entra em Minhas Organizações.
4. Usuário com múltiplas organizações e preferência válida entra na última organização.
5. Acesso apenas hierárquico não substitui a organização direta principal.
6. Preferência inválida ou acesso revogado encaminha para Minhas Organizações.
7. Usuário consegue trocar de organização.
8. Nenhuma regra amplia permissões de leitura ou edição.
9. O comportamento é auditável e testável.
10. O fluxo atual permanece disponível até a implantação definitiva.

## 9. Dependências

- modelo de organizações e vínculos;
- classificação de acesso direto e hierárquico;
- perfis e permissões;
- estado de ativação das organizações;
- persistência segura da última organização;
- serviços de consolidação de indicadores e pendências;
- definição transversal de alertas da Plataforma SPARKs.

## 10. Decisão de prioridade

O requisito está aprovado, porém não deverá interromper a preparação da solução para uso com a próxima cooperativa.

Antes da implementação, o uso real deverá fornecer evidências sobre:

- informações procuradas logo após o login;
- alertas realmente relevantes;
- prioridades por perfil;
- indicadores essenciais;
- frequência de troca de organização;
- diferenças entre gestores, consultores, validadores e usuários somente leitura.
