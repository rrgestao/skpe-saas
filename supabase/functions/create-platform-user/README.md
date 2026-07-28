# create-platform-user

Edge Function exclusiva do SUPER-ADMIN para criar uma conta ativa sem convite.

## Esta versão

- carrega e aceita todos os perfis globais ativos;
- permite múltiplos perfis globais, exceto o VISITANTE, que é exclusivo;
- permite selecionar um perfil para cada módulo habilitado da organização;
- cria o VISITANTE em modo somente leitura;
- impede VISITANTE como administrador local;
- impede VISITANTE com papéis modulares de escrita;
- mantém a chave `service_role` somente no servidor;
- realiza rollback da conta se qualquer etapa falhar;
- registra auditoria privilegiada.

## Perfil VISITANTE

O VISITANTE:

- precisa possuir vínculo ativo com ao menos uma organização;
- acessa os módulos habilitados das organizações vinculadas;
- recebe somente permissões de leitura reconhecidas pelo banco;
- não pode criar, editar, excluir, aprovar, administrar usuários ou alterar configurações;
- não recebe acesso automático a organizações sem vínculo ou sem política hierárquica autorizada.
