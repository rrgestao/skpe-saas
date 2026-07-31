# Critérios de Aceite e Testes — FE-09.A

## 1. Testes de contexto

- organização explícita;
- projeto explícito;
- Formulação explícita;
- versão exibida;
- ciclo exigido somente onde aplicável;
- URL preserva contexto;
- contexto inválido é bloqueado;
- nenhum primeiro registro é escolhido silenciosamente.

## 2. Testes de autorização

Perfis mínimos:

- administrador;
- gestor;
- elaborador;
- validador;
- aprovador;
- monitor;
- ratificador;
- visualizador;
- acesso hierárquico somente leitura;
- perfil customizado.

Validar:

- rota;
- ação;
- mutação;
- mensagem;
- backend continua bloqueando acesso indevido.

## 3. Testes de navegação

- refresh;
- back;
- forward;
- link direto;
- breadcrumb;
- troca de contexto;
- retorno aos módulos;
- logout.

## 4. Testes de componentes

- prontidão com bloqueios;
- prontidão com recomendações;
- modal de transição;
- motivo obrigatório;
- estado vazio;
- erro;
- loading;
- alterações não salvas;
- notificação lida/não lida;
- favorito.

## 5. Testes visuais e acessibilidade

- teclado;
- foco;
- `aria-label`;
- contraste;
- zoom;
- leitura por leitor de tela;
- desktop;
- tablet;
- mobile;
- gráfico com alternativa textual.

## 6. Testes de regressão

- login;
- recuperação de senha;
- seleção de organização;
- administração global;
- administração organizacional;
- Jornada;
- Iniciativas atuais;
- Artefatos;
- tema.

## 7. Qualidade técnica

Comandos obrigatórios:

```powershell
npm ci
npm run lint
npm run build
```

Quando a suíte for introduzida:

```powershell
npm run test
npm run test:e2e
```

## 8. Critério de saída

```text
lint = aprovado
build = aprovado
testes = aprovados
acessibilidade crítica = sem falha
arquivos = somente lista branca
git diff --check = aprovado
SHA-256 = recalculado
commit = controlado
push = confirmado
merge = não realizado
```
