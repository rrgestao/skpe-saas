# REQ-SKPE-FE-004 — Fundamentação do Negócio e Cadeia de Valor Essencial

**Módulo:** SK-PE
**Etapa:** FE-03
**Situação:** Implementação técnica preparada
**Aplicabilidade:** Multi-organização e multiprojeto, sem customização por organização

## 1. Objetivo

Implantar as operações auditadas da Fundamentação do Negócio e da Cadeia de Valor em nível essencial, utilizando os objetos compartilhados da Plataforma SPARKs.

O SK-PE deve produzir todos os insumos necessários à Formulação Estratégica mesmo quando a organização não possuir licença do SK-PN.

## 2. Regra arquitetural central

> O SK-PE é autossuficiente para desenvolver todos os insumos necessários à Formulação Estratégica. O SK-PN, quando contratado, recebe esses insumos estruturados, aprofunda-os segundo sua metodologia e devolve novos conhecimentos ao ciclo estratégico da organização.

Os artefatos não são duplicados por módulo. VPC, BMC, Cadeia de Valor, Fundamentação do Negócio e demais Canvas permanecem objetos compartilhados, versionados e rastreáveis.

## 3. Fundamentação do Negócio essencial

A prontidão exige conteúdo ativo em nove blocos:

1. segmentos de clientes;
2. necessidades e trabalhos a realizar;
3. oferta e proposta central de valor;
4. produtos e serviços;
5. canais e relacionamentos;
6. capacidades e recursos críticos;
7. parceiros;
8. lógica econômica, receitas e custos;
9. riscos e hipóteses do negócio.

Os códigos canônicos são:

```text
customer_segments
needs_jobs
value_offering
products_services
channels_relationships
capabilities_resources
partners
economic_logic
risks_hypotheses
```

## 4. Cadeia de Valor essencial

A Cadeia de Valor deve conter ao menos um elemento ativo em cada grupo:

```text
governance_management
core_business
support
```

Também deve existir ao menos uma relação do tipo `flow` entre elementos.

## 5. Ciclo de vida dos artefatos

```text
Rascunho
→ Em elaboração
→ Pendente de validação
→ Validado
→ Publicado
→ Substituído
```

Uma devolução retorna a versão validada ou pendente para **Em elaboração**. Uma revisão formal somente pode ser derivada de versão publicada ou substituída.

## 6. Snapshot da Formulação

O vínculo entre a Formulação e o artefato preserva:

- identificação do artefato;
- número e rótulo da versão;
- situação e maturidade;
- conteúdo estruturado;
- elementos;
- relações;
- data de captura;
- versão do esquema do snapshot;
- origem e módulo produtor.

Uma evolução futura do artefato não altera retroativamente a Formulação aprovada.

## 7. Operações públicas

- `create_skpe_business_artifact`
- `update_skpe_business_artifact_version`
- `upsert_skpe_business_artifact_element`
- `archive_skpe_business_artifact_element`
- `upsert_skpe_business_element_relation`
- `delete_skpe_business_element_relation`
- `get_skpe_business_artifact_version_readiness`
- `transition_skpe_business_artifact_version`
- `create_skpe_business_artifact_revision`
- `link_skpe_business_input`
- `dismiss_skpe_business_input`
- `get_skpe_business_foundation_readiness`
- `get_skpe_formulation_business_architecture`
- `get_skpe_business_architecture_audit`

## 8. Bloqueio integrado

A Formulação não poderá avançar para validação, aprovação ou publicação quando:

- não houver Fundamentação do Negócio primária;
- não houver Cadeia de Valor primária;
- alguma versão vinculada não estiver validada ou publicada;
- algum bloco essencial estiver ausente;
- a Cadeia de Valor não possuir fluxo entre seus elementos.

A ausência do SK-PN nunca será pendência bloqueante.

## 9. Segurança

- escrita direta continua revogada;
- operações públicas usam `SECURITY DEFINER`;
- funções internas não são executáveis por `authenticated`;
- autorização é verificada dentro das funções;
- conteúdo de versões não editáveis é protegido por gatilhos;
- toda alteração exige justificativa e auditoria.

## 10. Critérios de aceite

A etapa estará aprovada quando:

1. os três índices complementares existirem;
2. as funções operacionais existirem;
3. todas as funções forem `SECURITY DEFINER`;
4. as funções públicas forem executáveis por `authenticated`;
5. as funções internas permanecerem protegidas;
6. os três gatilhos estiverem ativos;
7. as regras dos nove blocos estiverem presentes;
8. a Cadeia de Valor exigir gestão, negócio, apoio e fluxo;
9. o snapshot estiver integrado ao vínculo;
10. as escritas diretas permanecerem bloqueadas;
11. não houver inconsistências ou duplicidades;
12. o verificador consolidado retornar somente `OK`.
