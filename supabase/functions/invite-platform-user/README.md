# create-platform-user

Edge Function exclusiva do SUPER-ADMIN para criar uma conta ativa sem convite.

## Segurança

- valida a sessão do solicitante;
- exige perfil global SUPER-ADMIN;
- utiliza a chave de serviço somente no ambiente seguro da Edge Function;
- não registra nem devolve a senha inicial;
- cria perfil, vínculo organizacional e perfil global opcionalmente;
- remove a conta caso alguma etapa posterior falhe;
- registra a criação em `privileged_access_audit`.
