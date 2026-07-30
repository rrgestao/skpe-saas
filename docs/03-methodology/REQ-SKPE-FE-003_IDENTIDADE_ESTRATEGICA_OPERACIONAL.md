# REQ-SKPE-FE-003 — Identidade Estratégica Operacional

**Módulo:** SK-PE
**Etapa:** FE-02
**Situação:** Implementação técnica preparada
**Aplicabilidade:** Multi-organização e multiprojeto, sem customização por código

## 1. Objetivo

Implantar as operações auditadas e metodologicamente controladas da Identidade Estratégica da organização:

- Propósito, quando adotado;
- Missão;
- Visão de Longo Prazo;
- Valores organizacionais;
- comportamentos esperados;
- comportamentos incompatíveis;
- declaração de coerência da Identidade.

## 2. Princípios

1. O Propósito é opcional.
2. Missão e Visão são obrigatórias.
3. Deve existir ao menos um Valor organizacional ativo.
4. Todo Valor deve possuir ao menos um comportamento esperado.
5. Todo Valor deve explicitar ao menos um comportamento incompatível.
6. Qualquer alteração invalida a validação anterior do pacote.
7. A Formulação somente pode avançar quando a Identidade estiver completa e validada.
8. Todas as alterações exigem justificativa e registro de auditoria.
9. Escritas diretas continuam bloqueadas para usuários autenticados.
10. O pacote respeita organização, projeto e versão da Formulação.

## 3. Operações públicas

- `update_skpe_strategic_identity`
- `upsert_skpe_identity_item`
- `delete_skpe_identity_item`
- `upsert_skpe_strategic_value`
- `archive_skpe_strategic_value`
- `upsert_skpe_value_behavior`
- `delete_skpe_value_behavior`
- `get_skpe_identity_readiness`
- `transition_skpe_strategic_identity`
- `get_skpe_strategic_identity`
- `get_skpe_identity_audit`

## 4. Validação do pacote

```text
Em elaboração
→ Pendente de validação
→ Validada
```

A devolução para ajustes retorna o pacote para **Em elaboração**.

Transições aceitas:

- `submit_validation`
- `validate`
- `return_for_adjustments`

## 5. Bloqueio integrado

O gatilho `skpe_strategic_formulations_guard_identity_ready` impede que a Formulação avance para validação, aprovação ou publicação quando:

- a Missão estiver ausente;
- a Visão estiver ausente;
- não houver Valores ativos;
- algum Valor não possuir comportamento esperado;
- algum Valor não possuir comportamento incompatível;
- o pacote da Identidade ainda não estiver validado.

## 6. Consulta consolidada

A função `get_skpe_strategic_identity` retorna:

- dados da versão da Formulação;
- situação do pacote;
- declaração de coerência;
- Propósito, Missão e Visão;
- Valores;
- comportamentos por Valor;
- indicadores de completude;
- pendências bloqueantes;
- regras metodológicas aplicadas.

## 7. Critérios de aceite

A etapa estará aprovada quando:

1. as funções operacionais existirem;
2. todas forem `SECURITY DEFINER`;
3. somente as funções públicas forem executáveis por `authenticated`;
4. a função interna de garantia do pacote não for pública;
5. o gatilho de bloqueio estiver ativo;
6. as quatro regras metodológicas principais forem verificadas;
7. as escritas diretas permanecerem bloqueadas;
8. não houver inconsistências entre organização, projeto, Formulação, Valores e comportamentos;
9. o verificador consolidado retornar somente `OK`.
