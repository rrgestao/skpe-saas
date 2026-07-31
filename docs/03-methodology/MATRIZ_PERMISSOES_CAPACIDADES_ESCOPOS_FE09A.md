# Matriz de Permissões, Capacidades e Escopos — FE-09.A

## 1. Modelo

```text
Papel
+ Permissões
+ Escopo
+ Atribuição
= Capacidade efetiva
```

## 2. Capacidades principais

| Capacidade | Permissão de origem |
|---|---|
| `canViewFormulation` | `strategic_formulation.view` |
| `canManageFormulation` | `strategic_formulation.manage` |
| `canValidateFormulation` | `strategic_formulation.validate` |
| `canApproveFormulation` | `strategic_formulation.approve` |
| `canViewMonitoring` | `strategic_monitoring.view` |
| `canManageMonitoring` | `strategic_monitoring.manage` |
| `canManageGovernance` | `strategic_governance.manage` |
| `canRatifyGovernance` | `strategic_governance.ratify` |

Permissões de Identidade, Negócio, Mapa, Indicadores, OKRs e Iniciativas deverão ser mapeadas conforme o catálogo efetivo.

## 3. Escopos

| Escopo | Exemplo |
|---|---|
| Organização | COOTAQUARA |
| Projeto | PE 2026–2030 |
| Formulação | versão 1 |
| Ciclo | 2027-T1 |
| Registro | OE-03 |
| Coorte futura | Agropecuárias do Entorno |
| Programa futuro | Programa de Governança |

## 4. Modos de acesso

- direto;
- administração da organização;
- hierárquico somente leitura;
- atribuição como responsável;
- escopo sistêmico futuro;
- SUPER-ADMIN.

## 5. Regras de interface

- botão oculto não substitui segurança do banco;
- ação desabilitada deve explicar o motivo;
- usuário com consulta não vê mutação;
- validador não precisa ser elaborador;
- aprovador não precisa receber gestão ampla;
- ratificador é distinto de informante de desempenho;
- acesso hierárquico não concede edição;
- perfil customizado deve funcionar por permissões, não por nome.

## 6. Coortes e núcleos

Não criar papel para cada grupo. A evolução deverá manter:

- grupos estáticos;
- grupos dinâmicos;
- vigência;
- responsável;
- associação de usuários ao grupo;
- permissões aplicadas ao escopo.

## 7. Inspeção obrigatória antes de criar RPC

1. localizar RPC que liste permissões efetivas;
2. localizar função de autorização já existente;
3. avaliar exposição segura ao frontend;
4. criar consulta consolidada somente se houver insuficiência comprovada;
5. não criar nova tabela por conveniência.
