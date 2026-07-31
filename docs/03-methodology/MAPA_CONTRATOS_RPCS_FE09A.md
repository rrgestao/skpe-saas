# Mapa de Contratos e RPCs — FE-09.A

## 1. Princípio

Cada feature deverá ter uma camada API própria. Componentes não devem espalhar chamadas Supabase e coerções de tipo.

## 2. Contratos consolidados

| Domínio | Contrato prioritário |
|---|---|
| Formulações | `get_skpe_formulations` |
| Identidade | `get_skpe_strategic_identity` |
| Negócio e Cadeia de Valor | `get_skpe_formulation_business_architecture` |
| Mapa Estratégico | `get_skpe_strategic_map` |
| Indicadores | `get_skpe_indicators_package` |
| OKRs | `get_skpe_okrs_package` |
| Iniciativas | `get_skpe_initiatives_package` |
| Monitoramento | `get_skpe_monitoring_cycle` |
| Desempenho | `get_skpe_strategic_performance` |
| Auditoria | contratos específicos de auditoria |

Os nomes deverão ser confirmados no catálogo e nas migrations antes da implementação.

## 3. Operações

A camada API deverá separar:

- leitura;
- criação/alteração;
- transição;
- prontidão;
- auditoria;
- download/exportação.

## 4. Erros

Erros de RPC devem ser normalizados em:

- código;
- mensagem;
- contexto;
- campo, quando aplicável;
- severidade;
- ação recomendada.

## 5. Tipagem

Evolução requerida:

```text
Database gerado
→ tipos das RPCs
→ view models
→ modelos de formulário
```

O cliente deve evoluir para `createClient<Database>()`.

## 6. Contratos legados

Chamadas atuais de Iniciativas e Jornada devem ser classificadas:

- reutilizar;
- adaptar;
- substituir;
- descontinuar.

Nenhuma remoção ocorrerá sem rota substituta e teste de regressão.
