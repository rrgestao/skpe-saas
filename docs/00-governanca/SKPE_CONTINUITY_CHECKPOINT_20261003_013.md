# SK-PE — Checkpoint de Continuidade — 2026-10-03 — 013

Status: ATIVO
Gate: Hierarquia e Autoridade dos Parâmetros do SK-PE

## Continuidade

Anterior: `SKPE_CONTINUITY_CHECKPOINT_20261003_012.md`

SHA funcional:

`1c3a16587e751e07b03f27f6277270ff85140bd9`

## Decisão arquitetural

A parametrização do SK-PE passa a ser operada explicitamente em níveis herdáveis, usando o motor canônico já existente.

Precedência confirmada no runtime:

1. Projeto;
2. Organização × Módulo;
3. Organização;
4. Módulo;
5. Plataforma;
6. Default da definição.

Para o SK-PE, o padrão administrado no escopo `module` funciona como **Padrão SPARKs · SK-PE** e é herdado por cada organização até que exista uma adaptação no escopo `organization_module`.

## Administração da Plataforma

Nova área:

`Parâmetros do SK-PE`

Disponível na Administração da Plataforma.

Objetivo:

- definir o padrão SPARKs do SK-PE;
- manter justificativa auditável;
- preservar herança;
- permitir retorno ao default SPARKs.

Escopo persistido:

`module`

Módulo:

`SK-PE`

Autoridade de escrita:

`is_platform_super_admin()`

## Administração da Organização

O Cadastro Institucional passa a ser dividido em duas abas:

1. `Informações institucionais`;
2. `Parâmetros do SK-PE`.

A aba de parâmetros usa o mesmo componente e o mesmo catálogo canônico de parâmetros.

Escopo persistido:

`organization_module`

Organização:

organização corrente.

Módulo:

`SK-PE`

## Autoridade do módulo

A migration:

`20261003205000_align_skpe_parameter_authority.sql`

foi aplicada com sucesso no Supabase DEV.

Para o escopo `organization_module` do SK-PE, a autorização passa a usar:

`can_manage_skpe_governance(organization_id)`

Essa função reconhece:

- Administrador da Organização;
- usuário com `strategic_governance.manage`;
- usuário com `strategic_governance.ratify`.

Assim, um administrador/gestor autorizado do módulo SK-PE pode parametrizar o módulo na organização sem precisar ser Administrador da Organização.

Os escopos globais `platform` e `module` permanecem restritos ao Super Admin da Plataforma.

## Rastreabilidade

As gravações continuam usando:

- `set_sparks_parameter_value`;
- `clear_sparks_parameter_value`;
- `sparks_parameter_audit`.

Nenhuma tabela paralela foi criada.

Toda alteração continua exigindo justificativa auditável.

## Interface

Componente:

`OrganizationParametersPanel`

passou a suportar:

- `scopeType="module"`;
- `scopeType="organization_module"`.

Na Administração da Plataforma:

- título: `Padrão SPARKs · SK-PE`;
- texto explica herança pelas organizações.

Na Administração da Organização:

- título: `Parâmetros da Organização · SK-PE`;
- restauração retorna ao padrão herdado do SK-PE.

## Validação

Contratos focados:

- `parameterHierarchyContract.test.ts`;
- `organizationAdminPortabilityContract.test.ts`.

Resultado:

**8/8 PASS**

O processo `tsc -b` permaneceu bloqueado sem emitir erro, comportamento recorrente deste ambiente; foi encerrado sem alterar o servidor local.

## Sincronização

SHA funcional `1c3a16587e751e07b03f27f6277270ff85140bd9` confirmado nos dois remotos governados antes da aplicação da migration DEV.

## Próximo gate

Validação humana visual:

1. Administração da Plataforma → Parâmetros do SK-PE;
2. Cadastro institucional compartilhado → aba Informações institucionais;
3. Cadastro institucional compartilhado → aba Parâmetros do SK-PE;
4. confirmar que os valores herdados mostram a origem efetiva;
5. confirmar que Admin da Organização e autoridade administrativa do módulo possuem ação de edição no escopo da organização;
6. confirmar que o padrão global continua restrito à Administração da Plataforma.
