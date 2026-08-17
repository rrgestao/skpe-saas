---
id: DEV-GOV-001
title: Guardrails de Execução de Agentes
version: 1.0.0
status: active
domain: platform-governance
owner: SPARKs Platform
created_at: 2026-08-17
updated_at: 2026-08-17
source: Gate 17-Q
dependencies:
  - docs/03-methodology/REQ-SKPE-FE-010_EXPERIENCIA_APLICACIONAL_E_OPERACIONALIZACAO_FORMULACAO.md
---

# Guardrails de Execução de Agentes

## 1. Finalidade

Estabelecer regras obrigatórias para qualquer agente, script ou executor que realize alterações no repositório da Plataforma SPARKs.

## 2. Precedência normativa

O estado real do repositório e as fontes canônicas vigentes prevalecem sobre prompts, scripts, instruções ou documentos históricos que tenham se tornado obsoletos.

Nenhuma instrução histórica deve ser executada automaticamente sem confronto com o Git, a documentação canônica e a implementação atual.

## 3. Fonte de verdade

Antes de qualquer alteração, o executor deve validar:

1. repositório correto;
2. branch atual;
3. HEAD local;
4. HEAD de `origin`;
5. referência remota quando aplicável;
6. `git status -sb`;
7. alterações preexistentes;
8. documentos canônicos aplicáveis.

Divergências entre local, `origin` e remoto bloqueiam escrita até serem compreendidas.

## 4. Preservação de trabalho preexistente

Alterações de outras frentes devem ser preservadas integralmente.

É proibido usar, sem autorização explícita e análise de impacto:

- `git reset --hard`;
- `git clean -fd`;
- force push;
- descarte automático de alterações locais;
- merge automático diante de divergência não compreendida.

## 5. Fontes canônicas

Antes de implementar, consultar hubs, ADRs, requisitos, contratos, critérios de aceite e documentos metodológicos aplicáveis.

Não duplicar regra que já possua fonte canônica adequada.

Quando documentação e implementação divergirem, registrar a divergência e determinar qual camada deve ser corrigida antes de prosseguir.

## 6. Mudança mínima e escopo

Toda implementação deve:

- identificar o objetivo exato;
- mapear impacto;
- determinar a mudança mínima suficiente;
- evitar alterações fora do escopo;
- evitar refatorações oportunistas não requeridas;
- preservar compatibilidade com frentes em andamento.

## 7. Coerência arquitetural e semântica

Antes de criar novas estruturas, verificar drift semântico, duplicidade conceitual e divergências entre:

- domínio e regras de negócio;
- banco de dados;
- APIs e RPCs;
- tipos;
- frontend;
- documentação;
- agentes e automações.

A arquitetura deve preservar separação clara entre apresentação, aplicação, domínio e dados/infraestrutura.

Regras de negócio não devem ser deslocadas indevidamente para o frontend.

## 8. Banco, segurança e autorização

Mudanças de banco devem usar migrations governadas e ser avaliadas quanto a:

- integridade;
- constraints;
- RLS;
- policies;
- grants;
- segregação por organização;
- auditoria;
- impacto brownfield;
- rollback ou estratégia de recuperação quando aplicável.

Mudanças de autorização devem incluir testes positivos e negativos proporcionais ao risco.

## 9. Compatibilidade

Quando aplicável, validar os dois cenários:

- greenfield: novos registros, organizações ou projetos;
- brownfield: registros, organizações ou projetos já existentes.

Nenhuma evolução deve interromper silenciosamente jornadas em curso ou destruir histórico.

## 10. Frontend, UX e acessibilidade

Mudanças de interface devem avaliar, quando aplicável:

### Usabilidade

- fluxo compreensível;
- redução de etapas desnecessárias;
- progressive disclosure;
- feedback de sucesso, erro e carregamento;
- estados vazios;
- prevenção de perda de dados.

### Acessibilidade

- navegação por teclado;
- foco visível;
- labels e nomes acessíveis;
- semântica adequada;
- contraste suficiente;
- informação não dependente apenas de cor;
- operação sem mouse quando pertinente.

### Responsividade

- desktop;
- tablet;
- mobile.

## 11. Definition of Done

A validação deve ser proporcional ao tipo e ao risco da mudança.

Quando aplicável, executar:

- testes automatizados existentes;
- novos testes para o comportamento alterado;
- lint;
- build de produção;
- validação de segurança;
- validação de compatibilidade;
- verificação de documentação afetada;
- `git diff --check`;
- revisão do diff final.

Uma implementação não é considerada concluída apenas porque funciona localmente.

## 12. Evidências

Ao final de cada execução, registrar no mínimo:

- arquivos alterados;
- validações executadas;
- testes e resultados;
- divergências encontradas;
- riscos e pendências;
- documentos canônicos consultados ou atualizados;
- estado final do Git;
- próximo passo recomendado.

## 13. Commit e push

Commit e push somente devem ocorrer após:

1. escopo validado;
2. diff revisado;
3. validações concluídas;
4. ausência de arquivos de outras frentes no staging;
5. autorização correspondente ao gate ou fluxo vigente.

Nunca usar `git add .` como atalho quando houver arquivos locais não relacionados.

## 14. Dívida arquitetural

É proibido introduzir conscientemente nova dívida arquitetural apenas para acelerar uma entrega.

Quando uma solução temporária for inevitável, ela deve ser explicitamente registrada com justificativa, risco, prazo ou condição de remediação e aprovação correspondente.

## 15. Tratamento de divergências

Se houver divergência entre Git, banco, documentação, ambiente ou requisitos:

- interromper escrita;
- preservar o estado encontrado;
- documentar a divergência;
- propor a menor ação segura para restabelecer consistência.

## 16. Regra final

Nenhuma implementação da Plataforma SPARKs deve ser iniciada apenas a partir de um prompt isolado.

Toda execução deve partir de:

**estado real do Git + fontes canônicas + análise de impacto + critérios de aceite + validação reproduzível.**
