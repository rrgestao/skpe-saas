# Bloco 1.10A — Prévia e Reconciliação da Carga Canônica da COOTAQUARA

## Situação

Este bloco **não grava dados no Supabase**. Ele lê a Planilha Canônica, inventaria as abas, classifica entidades e apresenta conflitos para decisão antes da carga transacional.

## Fonte analisada

- Arquivo: `SPARKs_PE_Sistema_Gestao_Estrategica_COOTAQUARA_v17_MVP_FUNCIONAL_2026_2030.xlsx`
- Abas: 50
- Abas mapeadas para entidades: 41
- Organização obrigatória: COOTAQUARA
- Horizonte: 2026–2030

## Ponto canônico da jornada

- Macrofase 1: concluída e aprovada.
- Macrofase 2: em andamento.
- Etapa atual: PEM-02.03 — validação assistida do PMVV e demais proposições.
- PEM-02.04: bloqueada até decisão formal do gate.

## Conflitos obrigatórios de reconciliação

### REC-001 — Status da Macrofase 1

- Fonte A: 00_Capa / 18_Decisoes — **Aprovada e concluída**
- Fonte B: 02_Fases — **Em validação; 90%**
- Valor canônico proposto: **Concluída; 100%**
- Regra: Decisões formais e validações prevalecem sobre quadro-resumo desatualizado.

### REC-002 — Status da Macrofase 2

- Fonte A: 00_Capa / 18_Decisoes — **Iniciada e em andamento**
- Fonte B: 02_Fases — **Não iniciado; 0%**
- Valor canônico proposto: **Em andamento**
- Regra: Decisão DEC-02.01 prevalece.

### REC-003 — Versão da solução

- Fonte A: Nome do arquivo — **v17**
- Fonte B: 01_Projeto / 26_Artefatos — **10.0**
- Valor canônico proposto: **17.0 para a carga; preservar 10.0 como versão histórica declarada**
- Regra: Nome/versionamento do pacote prevalece para a versão técnica do arquivo.

### REC-004 — Handoff MF1 → MF2

- Fonte A: 18_Decisoes — **MF2 aberta e aprovada**
- Fonte B: 28_Handoff — **Aguardando validação**
- Valor canônico proposto: **Concluído, com rastreabilidade para a decisão de abertura**
- Regra: Abertura formal da fase comprova transição.

### REC-005 — PMVV

- Fonte A: 34_PMVV_Validacao / DEC-02.03 — **Em validação; decisões individuais pendentes**
- Fonte B: 08_Identidade — **Textos propostos**
- Valor canônico proposto: **Proposta para validação; não institucionalizada**
- Regra: Nenhuma proposta deve ser importada como aprovada sem decisão formal.

### REC-006 — PEM-02.04

- Fonte A: 00_Capa / 27_Pendencias — **Bloqueado por gate**
- Fonte B: Estruturas futuras — **Objetivos, OKRs e indicadores já estruturados**
- Valor canônico proposto: **Bloqueado para execução; conteúdos posteriores importados como proposta/em validação**
- Regra: Conteúdo preparado não equivale a autorização para avanço.

## Resultado desta entrega

A interface permite selecionar um `.xlsx`, analisar localmente no navegador, revisar inventário e conflitos e baixar o JSON da prévia. Nenhuma função de gravação é chamada.

## Próxima etapa

Somente após aprovação da prévia será criado o Bloco 1.10B, com staging no Supabase, confirmação transacional, lote reversível e relatório de reconciliação final.
