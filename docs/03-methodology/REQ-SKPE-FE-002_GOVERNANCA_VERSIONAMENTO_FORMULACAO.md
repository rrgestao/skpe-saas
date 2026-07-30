# REQ-SKPE-FE-002 — Governança e Versionamento da Formulação Estratégica

**Módulo:** SK-PE
**Etapa:** FE-01
**Situação:** Implementação técnica preparada
**Aplicabilidade:** Multi-organização e multiprojeto, sem customização por código

## 1. Objetivo

Implantar a camada operacional que controla a criação, elaboração, validação, aprovação, substituição e arquivamento das versões da Formulação Estratégica.

A Formulação não será alterada por escrita direta nas tabelas. Todas as operações relevantes ocorrerão por funções auditadas e autorizadas.

## 2. Ciclo de vida

```text
Rascunho
→ Em elaboração
→ Pendente de validação
→ Validada
→ Pendente de aprovação
→ Aprovada
→ Substituída
→ Arquivada
```

Uma devolução para ajustes retorna a versão para **Em elaboração**.

## 3. Regras canônicas

1. Somente uma versão aberta pode existir por projeto.
2. Somente uma versão aprovada pode estar vigente por projeto.
3. A criação independente é permitida apenas antes de existir histórico aprovado; depois disso, toda nova versão deve ser uma revisão derivada da versão aprovada vigente.
4. O conteúdo somente pode ser alterado nos estados `draft` e `in_elaboration`.
5. A submissão à validação exige ausência de pendências metodológicas bloqueantes.
6. A aprovação revalida a prontidão metodológica.
7. Ao aprovar uma nova versão, a versão aprovada anterior é automaticamente marcada como substituída.
8. Toda alteração exige justificativa com o padrão de auditoria já adotado pela Plataforma.
9. Uma revisão é derivada de uma versão aprovada ou substituída.
10. A revisão clona o conteúdo estruturado e os snapshots dos insumos de negócio.
11. Iniciativas não são clonadas; devem ser avaliadas e vinculadas novamente aos novos OEs e KRs.

## 4. Operações públicas

- `create_skpe_formulation`
- `update_skpe_formulation`
- `create_skpe_formulation_revision`
- `transition_skpe_formulation`
- `get_skpe_formulations`
- `get_skpe_formulation_audit`

## 5. Transições aceitas

- `begin_elaboration`
- `submit_validation`
- `validate`
- `return_for_adjustments`
- `submit_approval`
- `approve`
- `archive`

## 6. Clonagem da revisão

São clonados:

- Identidade Estratégica;
- Propósito, Missão e Visão;
- Valores e comportamentos;
- vínculos e snapshots dos insumos compartilhados;
- Temas Estratégicos;
- Perspectivas BSC;
- Objetivos Estratégicos e relações causais;
- ciclos e Objetivos dos OKRs;
- Resultados-Chave;
- indicadores;
- metas;
- referências de benchmarking.

Não são clonados:

- iniciativas;
- execução histórica;
- decisões de validação e aprovação;
- progresso operacional da versão anterior.

## 7. Correção de compatibilidade

As unicidades legadas de Objetivos Estratégicos e Indicadores por projeto impediam repetir códigos em uma nova versão.

A FE-01 substitui essas restrições por unicidades vinculadas à versão da Formulação, preservando índices parciais para registros legados ainda sem `formulation_id`.

## 8. Segurança

- leitura controlada pelas permissões da Formulação;
- escrita direta permanece revogada;
- operações executadas por funções `SECURITY DEFINER`;
- autorização verificada dentro de cada função;
- conteúdo congelado durante validação e aprovação;
- versões aprovadas, substituídas e arquivadas são imutáveis.

## 9. Critérios de aceite

A etapa estará aprovada quando:

1. todas as colunas de governança existirem;
2. as funções operacionais estiverem disponíveis;
3. as funções públicas tiverem execução concedida ao perfil `authenticated`;
4. o conteúdo estiver protegido fora dos estados editáveis;
5. as restrições legadas incompatíveis com versionamento tiverem sido removidas;
6. os novos índices versionados existirem;
7. a auditoria puder ser consultada por usuários autorizados;
8. não houver duplicidade de versão aberta ou aprovada por projeto;
9. o verificador consolidado retornar somente `OK`.
