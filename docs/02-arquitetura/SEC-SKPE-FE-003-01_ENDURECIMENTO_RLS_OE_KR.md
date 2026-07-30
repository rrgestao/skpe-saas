# SEC-SKPE-FE-003-01 — Endurecimento de RLS de Objetivos Estratégicos e Resultados-Chave

**Módulo:** SK-PE
**Classificação:** Correção de segurança e alinhamento arquitetural
**Escopo:** `skpe_strategic_objectives` e `skpe_key_results`

## 1. Achado

A verificação transversal de RLS identificou:

- RLS habilitada nas 22 tabelas controladas;
- políticas de leitura existentes nas 22 tabelas;
- privilégios diretos de `INSERT`, `UPDATE` e `DELETE` concedidos ao papel `authenticated` nas tabelas de Objetivos Estratégicos e Resultados-Chave;
- política legada `skpe_key_results_manage`, com comando `ALL`, permitindo escrita direta em Resultados-Chave.

Em Objetivos Estratégicos, os privilégios DML estavam concedidos, embora a ausência de política DML restringisse a efetivação pela RLS. Mesmo assim, os privilégios eram incompatíveis com o princípio do menor privilégio.

## 2. Decisão

1. Remover a política legada `skpe_key_results_manage`.
2. Revogar DML de `PUBLIC`, `anon` e `authenticated`.
3. Preservar DML para `service_role`.
4. Manter escrita de usuários somente por RPCs auditadas `SECURITY DEFINER`.
5. Preservar leitura para os dois usos legítimos:
   - módulo de Iniciativas;
   - Formulação Estratégica.

## 3. Efeito funcional

A correção não exclui dados nem altera registros.

A clonagem de versões e as futuras operações de FE-04 continuarão funcionando por funções `SECURITY DEFINER` e pelo `service_role`.

Qualquer tela antiga que tentasse gravar diretamente nessas tabelas deverá ser migrada para as operações auditadas da FE-04.

## 4. Critério de aceite

A correção estará concluída quando:

- `authenticated` possuir somente `SELECT`;
- não existir política DML para `authenticated`;
- `skpe_key_results_manage` estiver ausente;
- as políticas de leitura reconhecerem permissões de Iniciativas e Formulação;
- `service_role` mantiver escrita operacional;
- o verificador retornar somente `OK`;
- o verificador transversal FE-00 a FE-03 passar a indicar zero tabelas com escrita direta.
