# SK-PE — Checkpoint de Continuidade — 2026-10-03 — 011

Status: ATIVO
Gate: Administração da Organização — Importação e Exportação

## Continuidade

Anterior: `SKPE_CONTINUITY_CHECKPOINT_20261003_010.md`

SHA funcional:

`72d24f3657101594a77e185a632558e2a00d388b`

## Problema confirmado

O Administrador da Organização não conseguia acessar plenamente Importação e Exportação por dois motivos independentes:

1. a área administrativa iniciava em Usuários e Acessos e não oferecia navegação para Portabilidade quando o usuário também podia administrar usuários;
2. `get_portability_layouts` restringia a leitura do catálogo de leiautes a Super Admin da Plataforma ou service role.

As operações críticas de organização já estavam corretamente protegidas por `can_manage_skpe_governance` ou `can_view_skpe_governance`.

## Correção funcional

A Administração da Organização passa a oferecer abas:

- Usuários e Acessos;
- Importação e Exportação.

`canManagePortability` passa a usar diretamente `canManageGovernance`, inclusive em `mode=organization-admin`.

O componente `PortabilityAdmin` permanece fixado na organização por:

`fixedOrganizationId={organizationId}`

Portanto, o Administrador da Organização não recebe seletor livre para operar outra organização.

## Correção de backend

Migration:

`20261003184500_enable_organization_admin_portability_layouts.sql`

Aplicada com sucesso em DEV.

O catálogo global e não sensível de leiautes passa a poder ser consultado por usuário autenticado:

`auth.uid() is not null`

Permissões de criação, alteração, staging, simulação, resolução e readiness continuam governadas pelos RPCs específicos de organização.

## Verificação de autorização

`can_manage_skpe_governance(target_organization_id)` reconhece:

- Administrador da Organização; ou
- papel com `strategic_governance.manage`; ou
- papel com `strategic_governance.ratify`.

Foi confirmado no DEV que o vínculo administrativo da COOTAQUARA está ativo.

## Linguagem da interface

No escopo da organização:

- título: `Importação e Exportação`;
- contexto: `Dados da organização`;
- importação descrita como dados históricos para revisão controlada;
- `Primeiro pacote de Diagnóstico` substituído por `Dados históricos do Diagnóstico — revisão humana`;
- `Preparar pacote completo` substituído por `Preparar dados históricos para revisão`;
- linguagem de `materialização` removida das mensagens principais em favor de `incorporação ao planejamento atual`.

## Validação

Contratos executados:

- `organizationAdminPortabilityContract.test.ts`;
- `incorporationReviewPreparationContract.test.ts`.

Resultado:

**8/8 PASS**

O build completo foi iniciado, porém o processo local permaneceu retido em `tsc -b && vite build` sem erro emitido, comportamento já conhecido deste ambiente.

## Sincronização

SHA `72d24f3657101594a77e185a632558e2a00d388b` confirmado nos dois remotos governados antes da aplicação da migration DEV.

## Próximo gate

Validação humana na Administração da Organização COOTAQUARA:

1. atualizar a aplicação;
2. abrir Administração da Organização;
3. acessar a aba `Importação e Exportação`;
4. confirmar que a organização permanece fixa em COOTAQUARA;
5. retomar o lote v26;
6. validar a nova apresentação `Dados históricos do Diagnóstico`.

Somente após essa validação seguir para preparação e revisão dos 35 registros.
