# ESPECIFICAÇÃO FUNCIONAL — BLOCO 1.7

## Pacote Estratégico Portátil SPARKs

### Objetivo

Gerar um arquivo ZIP único, versionado e rastreável, reunindo as principais representações portáteis do Planejamento Estratégico da organização selecionada.

### Conteúdo do pacote

- `manifest.json`: manifesto do pacote e governança de uso;
- `dados/dados_estruturados.json`: fonte estruturada segregada por organização;
- `planilha/*.xlsx`: Planilha Canônica de Gestão Estratégica;
- `portal/*.html`: Portal HTML Portátil somente leitura;
- `documentos/`: estrutura preparada para relatórios, apresentações, decisões, evidências e prompts.

### Regras de negócio

1. Somente solicitações de exportação podem gerar ZIP.
2. A coleta de dados continua usando `generate_portability_json_export`.
3. A organização e o projeto são os mesmos do pacote solicitado.
4. Não existe fallback para projeto de outra organização.
5. O ZIP é gerado no navegador e registrado por `register_portability_generated_file` com formato `zip`.
6. A Plataforma SPARKs permanece como fonte oficial quando o SaaS estiver em uso.
7. Importações futuras deverão passar por validação, prévia, conflitos e confirmação auditável.

### Dependência

- `jszip`

### Critérios de aceite

- botão `Gerar ZIP` visível em Cards e Linhas;
- download de arquivo `.zip`;
- presença do manifesto, JSON, XLSX, HTML e estrutura documental;
- dados exclusivos da organização selecionada;
- registro da geração no histórico;
- build TypeScript concluído sem erros.
