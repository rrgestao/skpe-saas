# ADR-FE09-A02-B4 — Avatar Transversal e Integração com o Módulo Assemblear

## Decisão

A Plataforma SPARKs deverá manter cadastro mestre transversal da pessoa e do usuário, com fotografia ou avatar reutilizável pelos módulos autorizados.

A gestão integral da jornada do cooperado pertence ao futuro Módulo Assemblear e Societário, sem duplicação de cadastros.

## Escopo futuro

Identificação, foto, matrícula, situação societária, admissão, capital social, documentos, CAF, localização, participação assemblear, votações, cargos, formação, desenvolvimento, produção, entregas, movimentação econômica, sucessão, inclusão, estatísticas do Sistema OCB e histórico auditável.

## Regra arquitetural

Nesta entrega será criado apenas o espaço visual do avatar, com fallback de iniciais. Persistência, upload, autorização e governança da imagem serão implementados em etapa própria da fundação transversal e do Módulo Assemblear.
