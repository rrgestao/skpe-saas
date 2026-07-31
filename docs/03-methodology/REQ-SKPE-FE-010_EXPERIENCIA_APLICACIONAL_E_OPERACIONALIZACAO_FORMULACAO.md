# REQ-SKPE-FE-010 — Experiência Aplicacional e Operacionalização da Formulação Estratégica

**Projeto:** Plataforma SPARKs — Módulo SK-PE
**Etapa:** FE-09
**Primeira onda:** FE-09.A — Fundação Aplicacional
**Aplicabilidade:** multi-organização, multiprojeto, multiformulação e multiciclo
**Branch canônica:** `feature/formulacao-estrategica-operacional`
**Commit-base:** `0fd801bfe076c07fd6f06ac2aea94a8aa094115f`
**Situação:** arquitetura aprovada; implementação incremental pendente

---

## 1. Objetivo

Disponibilizar uma experiência aplicacional completa para elaborar, validar, aprovar, executar, monitorar, governar, aprender e comunicar a estratégia, utilizando como fonte de verdade os contratos canônicos implantados nas FE-00 a FE-08.

A camada React deve:

- preservar regras de negócio no PostgreSQL;
- operar exclusivamente por contratos autorizados;
- tornar explícito o contexto de organização, projeto, Formulação, versão e ciclo;
- suportar navegação profunda e compartilhável;
- refletir permissões e escopos do usuário;
- apresentar bloqueios e recomendações de prontidão;
- permitir transições auditadas com motivo obrigatório;
- evitar duplicação de cálculos e validações;
- proporcionar experiência visual competitiva;
- preparar a Plataforma para gestão sistêmica, mensageria e importação assistida.

---

## 2. Princípios obrigatórios

### 2.1 Simplicidade na superfície, rigor na estrutura

A interface deve ser amigável para dirigentes, analistas e consultores, sem expor complexidade técnica desnecessária. O rigor metodológico, a segurança, a rastreabilidade e a segregação permanecem preservados no backend.

### 2.2 Contexto explícito

Nenhuma operação estratégica poderá depender do primeiro projeto ou da primeira Formulação retornada. O usuário deve selecionar ou confirmar explicitamente:

```text
Organização
→ Projeto Estratégico
→ Formulação e versão
→ Ciclo, quando aplicável
```

### 2.3 Regras no banco

A interface não recalcula prontidão, polaridade, agregação, estados permitidos ou autorização. Ela consulta os contratos do banco, apresenta o resultado e solicita a transição autorizada.

### 2.4 Migração incremental

O `SkpeCockpit` atual será decomposto progressivamente. A aplicação não será reescrita integralmente em uma única entrega.

### 2.5 Acesso por capacidade e escopo

O frontend deve distinguir:

```text
o que o usuário pode fazer
+
onde pode fazer
+
por quais registros é responsável
```

Perfis não devem proliferar para representar combinações de regiões, programas, consultores ou carteiras.

---

## 3. Contexto transversal

Toda rota operacional deve conhecer:

- `organizationId`;
- `projectId`;
- `formulationId`;
- `formulationVersion`;
- `formulationStatus`;
- `accessMode`;
- `capabilities`.

Rotas de acompanhamento também devem conhecer:

- `monitoringCycleId`.

O cabeçalho do workspace deve apresentar:

- organização;
- projeto;
- Formulação e versão;
- situação;
- horizonte;
- ciclo ativo, quando aplicável;
- modo de acesso;
- indicador de prontidão;
- ações autorizadas.

---

## 4. Módulos funcionais da experiência

### 4.1 Meu Espaço de Trabalho

Deve consolidar:

- minhas pendências;
- meus indicadores;
- meus KRs;
- minhas Iniciativas;
- minhas decisões;
- validações aguardando atuação;
- reuniões próximas;
- alertas;
- prazos vencidos;
- favoritos.

### 4.2 Painéis

O usuário poderá:

- consultar painéis disponíveis conforme perfil e escopo;
- definir um Painel Principal;
- salvar favoritos;
- aplicar filtros;
- navegar por drill-down até os registros de origem.

Painéis mínimos:

- Meu Trabalho;
- Executivo;
- Organização;
- Formulação;
- Indicadores;
- OKRs;
- Portfólio;
- Monitoramento;
- Governança.

### 4.3 Formulação Estratégica

Deve operacionalizar:

- governança e versões;
- Identidade Estratégica;
- Fundamentação do Negócio;
- Cadeia de Valor;
- Temas;
- Perspectivas;
- Objetivos;
- Mapa Estratégico;
- Indicadores;
- metas;
- benchmarking;
- OKRs;
- Resultados-Chave.

### 4.4 Execução

Deve operacionalizar:

- portfólio organizacional;
- programas;
- projetos;
- Iniciativas;
- ações e marcos;
- riscos;
- dependências;
- resultados e benefícios.

### 4.5 Monitoramento, governança e aprendizado

Deve operacionalizar:

- ciclos;
- medições;
- check-ins;
- desempenho agregado;
- RAE;
- RAD e demais tipos de reunião;
- decisões;
- aprendizados;
- snapshots.

---

## 5. Painéis e visualizações

Todos os painéis devem oferecer, conforme aplicabilidade:

- total;
- concluídos;
- em andamento;
- pendentes;
- atrasados;
- críticos;
- sem responsável;
- aguardando validação;
- sem atualização recente;
- baixa qualidade de dados.

Visualizações recomendadas:

- cartões;
- tendência temporal;
- meta versus realizado;
- distribuição por situação;
- mapa de calor;
- faixas de atraso;
- desempenho por Tema e OE;
- evolução de KRs;
- saúde do portfólio;
- carga por responsável.

Todo elemento analítico deve permitir drill-down.

A primeira versão não inclui construtor livre de dashboards por arrastar e soltar.

---

## 6. Notificações na primeira versão

A FE-09 deve fornecer a fundação de uma central básica de notificações:

- sino de notificações;
- lida/não lida;
- prioridade;
- vínculo com o item;
- data de geração;
- vencimento;
- ação recomendada;
- painel de pendências.

O modelo deve admitir evolução futura para:

- e-mail;
- resumos periódicos;
- escalonamento;
- conversacional;
- webhooks;
- aplicativos de mensagens.

A política completa de mensageria será tratada em etapa posterior.

---

## 7. Reuniões de análise

A interface deve tratar RAE, RAD e outras reuniões como templates de análise estratégica.

Cada template pode definir:

- periodicidade;
- pauta;
- participantes;
- papéis;
- informações obrigatórias;
- itens analisáveis;
- decisão e ratificação;
- artefatos gerados.

Não deve existir um módulo isolado e duplicado para RAD quando a estrutura de reuniões estratégicas puder ser reutilizada.

---

## 8. Gestão sistêmica futura

A arquitetura deve admitir:

- coortes;
- núcleos;
- carteiras;
- grupos estáticos;
- grupos dinâmicos;
- regras de pertencimento;
- vigência;
- responsáveis;
- painéis sistêmicos;
- acesso multi-organização.

Essas capacidades não serão improvisadas como novos perfis.

---

## 9. Importação assistida futura

A arquitetura deve admitir pipeline auditável:

```text
documento
→ extração
→ classificação
→ mapeamento
→ staging
→ revisão humana
→ prontidão
→ publicação controlada
```

Cada dado importado deverá preservar:

- documento;
- página;
- trecho;
- lote;
- método;
- confiança;
- revisor;
- decisão;
- alteração;
- hash do documento.

Importação nunca aprova automaticamente uma Formulação.

---

## 10. Segurança e auditoria

A aplicação deve preservar:

- RLS;
- escrita por RPC;
- motivo obrigatório;
- segregação entre elaborar, validar, aprovar, monitorar e ratificar;
- escopo por organização e projeto;
- proteção de versões aprovadas;
- histórico;
- imutabilidade de snapshots;
- nenhuma DML direta.

---

## 11. Critérios de aceite da FE-09.A

A fundação será aceita quando:

1. houver roteamento e contexto explícito;
2. nenhuma seleção depender do primeiro registro retornado;
3. capacidades forem derivadas de permissões reais;
4. a base de API estiver separada dos componentes;
5. o cliente Supabase estiver tipado ou houver plano executável de geração de tipos;
6. componentes transversais estiverem definidos;
7. o `SkpeCockpit` puder ser decomposto sem ruptura;
8. existirem testes de contexto, rota e autorização;
9. o build e o lint forem aprovados;
10. nenhum merge tiver sido realizado sem autorização.

---

## 12. Fora de escopo da FE-09.A

- implementação integral das telas FE-01 a FE-08;
- construtor livre de dashboards;
- portfólio sistêmico completo;
- motor completo de mensageria;
- conversacional;
- importação de PDFs;
- alteração de banco por presunção;
- merge.
