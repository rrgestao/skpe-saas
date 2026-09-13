---
id: sk-pe-business-rules-hub
title: Índice de regras de negócio do SK-PE
domain: products
type: hub
status: canonical
owner: product
canonicality: canonical
canonical: true
criticality: high
parent:
  - sk-pe-product-hub
related:
  - skpe-fund-neg-01
  - sk-pe-fundamentacao-business-rules
  - skpe-ident-01
  - sk-pe-identidade-business-rules
  - skpe-form-ver-01
  - sk-pe-formulacao-business-rules
  - sk-pe-medidas-business-rules
  - skpe-med-des-01
  - sk-pe-current-state
tags:
  - sk-pe
  - business-rules
language: pt-BR
encoding: UTF-8
semantic_layer: canonical-product-business-rules
created: 2026-09-12
updated: 2026-09-12
lineage:
  - ../README.md
  - ../capabilities/SKPE-MED-DES-01-medidas-desempenho.md
---

# Regras de negócio do SK-PE

Índice e contrato documental do produto. A capability possui o contrato funcional; cada domínio/capability possui **um owner detalhado de regras**. O hub contém apenas índice, contrato e política de manutenção. Não criar arquivo por regra nem copiar definições entre owners.

| Capability | Owner funcional | Owner detalhado | IDs |
| --- | --- | --- | --- |
| SKPE-MED-DES-01 | [Medidas](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md) | [Regras de Medidas](medidas-desempenho.md) | F-MED-001–024; BR-SKPE-MED-001–044 |
| SKPE-FORM-VER-01 | [Formulação e Versionamento](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md) | [Regras de Formulação](formulacao-versionamento.md) | F-FORM-001–019; BR-SKPE-FORM-001–034 |
| SKPE-IDENT-01 | [Identidade Estratégica](../capabilities/SKPE-IDENT-01-identidade-estrategica.md) | [Regras de Identidade](identidade-estrategica.md) | F-IDENT-001–019; BR-SKPE-IDENT-001–028 |
| SKPE-FUND-NEG-01 | [Fundamentação do Negócio](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md) | [Regras de Fundamentação](fundamentacao-negocio.md) | F-FUND-001–033; BR-SKPE-FUND-001–043 |

## Contrato canônico de regra

Campos obrigatórios: `ID`, `TITLE`, `STATEMENT`, `RATIONALE`, `APPLIES_TO`, `ENTITIES`, `PRECONDITIONS`, `TRIGGER`, `CONSTRAINT`, `OUTCOME`, `EXCEPTIONS`, `STATE_TRANSITIONS`, `AUTHORITY_CLASS`, `VERIFICATION_STATUS`, `ACCEPTANCE_STATUS`, `TEST_COVERAGE`.

Rastreabilidade obrigatória: `CAPABILITY`, `SOURCE_TYPE`, `SOURCE_EVIDENCE`, `ACCEPTANCE_EVIDENCE`, `TEST_EVIDENCE`, `CONFIDENCE`, `CONFLICTS`, `PENDING_DECISION`, `OBSERVABILITY`. `ENFORCEMENT` e `CATEGORY` qualificam aplicação técnica e índice. Campos ausentes não são omitidos: usar N/A, NONE ou UNKNOWN com motivo. APPLIES_TO contém IDs de funções, não uma descrição livre que perca os vínculos. Os IDs são chaves locais; o documento possui semantic ID distinto.

| Campo | Valores permitidos | Significado e critério |
| --- | --- | --- |
| AUTHORITY_CLASS | CONFIRMED_PRODUCT_RULE; DOCUMENTED_RULE; IMPLEMENTED_RULE; INFERRED_RULE; CONFLICTING_RULE; PENDING_PRODUCT_DECISION | Natureza da fonte/autoridade; não mede cobertura ou aceite. |
| VERIFICATION_STATUS | DOCUMENT_CONFIRMED; CODE_CONFIRMED; SQL_CONFIRMED; TEST_CONFIRMED; OBSERVED; PARTIAL; UNKNOWN | Evidência de verificação da afirmação no escopo indicado. Uma fonte lida não prova comportamento em runtime. |
| ACCEPTANCE_STATUS | PRODUCT_ACCEPTED; IMPLEMENTED_NOT_ACCEPTED; PENDING_PRODUCT_DECISION; SUPERSEDED; UNKNOWN | Aceite Product é independente da implementação; exige referência explícita. |
| TEST_COVERAGE | DIRECT; INDIRECT; NONE; UNKNOWN | DIRECT testa a regra; INDIRECT exercita comportamento relacionado com vínculo demonstrado; NONE significa busca delimitada sem cobertura encontrada; UNKNOWN significa busca/evidência insuficiente. |

## Autoridade, verificação e aceite

`IMPLEMENTED_RULE != CONFIRMED_PRODUCT_RULE`. Código, SQL, migration e frontend isolados não promovem autoridade. Somente decisão Product ou autoridade canônica equivalente, identificada por documento/commit/trecho, permite CONFIRMED_PRODUCT_RULE e PRODUCT_ACCEPTED. Mudanças de classe preservam histórico e fonte da decisão; jamais derivar aceite de testes verdes.

DOCUMENT_CONFIRMED confirma o registro documental, inclusive de uma decisão pendente; não transforma essa pendência em decisão tomada. CODE_CONFIRMED/SQL_CONFIRMED confirmam predicado no SHA. TEST_CONFIRMED exige teste identificado e resultado relevante; OBSERVED exige evidência observada com ambiente/data/escopo. Quando várias fontes existem, registrar o status primário sustentado e listar todas as fontes; contradição/inferência recebe PARTIAL. Não tratar os estados como escala automática de maturidade.

IMPLEMENTED_NOT_ACCEPTED significa implementação encontrada sem aceite Product localizado, não rejeição Product. PENDING_PRODUCT_DECISION identifica questão explicitamente aberta. UNKNOWN evita inventar aceite para documento ou inferência. SUPERSEDED exige indicação do sucessor e da decisão, preservando ID antigo.

## Escala e manutenção

- Capability: propósito, atores, funcionalidades, lifecycle resumido, integrações, conflitos e links. Owner de regras: definições completas, índice inverso, verificação/aceite/testes e fontes. Hub: descoberta e contrato, sem repetir regras.
- Cada regra tem um único owner e âncora estável; consumidores referenciam o ID. Não renumerar IDs publicados. Ao mover uma regra, atualizar links e registrar destino; nunca deixar duas definições ativas.
- Replicar este contrato apenas em wave autorizada. Primeiro localizar owner existente; não criar arquivo vazio para toda capability.
- Se um owner crescer a ponto de impedir revisão coerente, dividir por domínio semântico coeso, preservando índice e IDs; não dividir mecanicamente por regra nem manter cópias. O piloto usa um único arquivo de 44 regras, com índice navegável e registros compactos.
- Cada mudança valida unicidade de ID/owner, fontes, enums, aceitação/teste obrigatórios e as duas direções de rastreabilidade. Testes ausentes permanecem dívida de qualidade, sem bloquear artificialmente a existência da baseline documental.

O [precedente de índice Corporate](../../produz/business-rules/README.md) orienta navegação; este contrato detalhado é o refinamento do piloto SK-PE, sem impor migração a outros produtos. C01/C02/C04 permanecem OPEN_PRODUCT_DECISION. [Estado atual](../current-state.md) · [Hub SK-PE](../README.md).
