# Fundação de Importação, Exportação e Portabilidade

## Princípio
Quando a organização opera no SaaS, a Plataforma SPARKs é a fonte oficial. A planilha e o HTML são canais portáteis, operacionais e documentais, gerados e reconciliados de forma controlada.

## Fluxo de exportação
Solicitação → preparação → validação → geração → verificação de integridade → disponibilização → auditoria.

## Fluxo de importação
Seleção → identificação do leiaute → staging → validação → classificação → resolução de conflitos → confirmação → transação → relatório final.

## Classificações de item
Novo, sem alteração, atualização disponível, conflito, duplicado, referência ausente, inválido, pertencente a outra organização, incompatível, aceito, rejeitado, importado, exportado ou falhou.

## Formatos canônicos iniciais
- Planilha Canônica de Gestão Estratégica (`xlsx`);
- Portal Estratégico Portátil (`html`);
- Dados Estruturados (`json`);
- Pacote Estratégico Portável (`zip`).

## Segurança
Toda operação é vinculada a organização, projeto, módulo, usuário, leiaute e versão. O acesso depende do SUPER-ADMIN ou da permissão de gestão da organização.
