# Contrato Canônico — Shell Aplicacional Transversal da Plataforma SPARKs

## 1. Decisão

Toda área autenticada da Plataforma SPARKs deverá operar dentro de um shell transversal composto por:

1. header contextual;
2. menu lateral persistente;
3. área principal com rolagem independente;
4. footer institucional;
5. adaptação responsiva para dispositivos menores.

## 2. Contextos obrigatórios no header

O header deverá exibir, conforme disponibilidade:

- organização;
- módulo;
- projeto;
- ciclo estratégico;
- fase ou seção atual;
- usuário e perfis ativos.

## 3. Navegação

O menu deverá ser condicionado por:

`PERFIL + PERMISSÕES + ESCOPO + COORTE + RESPONSABILIDADE`

O menu não poderá conceder acesso. Ele apenas refletirá autorizações já resolvidas pelo backend.

## 4. Rolagem

- header, menu e footer não deverão acompanhar a rolagem do conteúdo;
- somente a área principal deverá rolar em desktop;
- modais manterão rolagem própria;
- em mobile, o menu funcionará como drawer.

## 5. Footer

Conteúdo mínimo:

`Plataforma SPARKs — © SPARKOOP — Todos os direitos reservados.`

Poderá incluir:

- versão;
- ambiente;
- suporte;
- termos;
- privacidade.

## 6. Fases de implementação

- FE-09.A.03.1 — fundação reutilizável;
- FE-09.A.03.2 — integração no Portal da Plataforma;
- FE-09.A.03.3 — integração no SK-PE;
- FE-09.A.03.4 — contexto de projeto e ciclo;
- FE-09.A.03.5 — responsividade e acessibilidade;
- FE-09.A.03.6 — padronização das telas existentes.

## 7. Restrições

- não duplicar autorização no frontend;
- não quebrar rotas existentes;
- não misturar contexto global com contexto da página;
- não ocultar organização ou ciclo em operações críticas;
- não realizar migração de banco para uma mudança puramente visual.