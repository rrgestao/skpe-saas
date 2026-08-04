# Guia de Validação — FE-09.A.01

## 1. Pré-condições

- branch $ExpectedBranch;
- HEAD $ExpectedBaseCommit;
- Supabase Web disponível;
- usuário autenticável;
- pelo menos uma organização com SK-PE habilitado.

## 2. Validação técnica

`powershell
cd apps/web
npm run lint
npm run build
cd ../..
git --no-pager diff --check
`

## 3. Validação funcional

1. entrar na plataforma;
2. selecionar uma organização;
3. confirmar a URL /organizations/:organizationId;
4. abrir o SK-PE;
5. confirmar a URL /organizations/:organizationId/modules/SK-PE;
6. utilizar Voltar e Avançar do navegador;
7. atualizar a página na rota do módulo;
8. confirmar restauração da organização e do módulo;
9. abrir a Administração da Plataforma como SUPER-ADMIN;
10. confirmar /platform-admin;
11. testar rota inválida e retorno controlado.

## 4. Resultado esperado

A navegação deixa de depender exclusivamente do estado volátil do componente. A URL passa a representar organização, módulo e, quando informado, Projeto e Formulação.
