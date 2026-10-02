# SK-PE â€” Contrato de ValidaÃ§Ã£o e SincronizaÃ§Ã£o

Status: ATIVO
Data de vigÃªncia: 2026-10-02

## Regra central

Nenhum bloco funcional ou visual considerado em validaÃ§Ã£o humana deve ser sincronizado com os repositÃ³rios remotos antes da aprovaÃ§Ã£o explÃ­cita do usuÃ¡rio.

A partir de cada validaÃ§Ã£o humana aprovada, o mesmo estado validado deve ser promovido de forma controlada e verificÃ¡vel.

## SequÃªncia obrigatÃ³ria

1. Preservar checkpoint local do estado anterior.
2. Executar testes focados, build aplicÃ¡vel e `git diff --check`.
3. Confirmar que nÃ£o existem alteraÃ§Ãµes estranhas ao bloco validado misturadas ao commit.
4. Registrar um Ãºnico commit canÃ´nico para o bloco validado.
5. Publicar primeiro no remoto `rrgestao`.
6. Ler novamente o SHA remoto e confirmar igualdade com o SHA local.
7. Publicar o mesmo SHA no remoto `sparkooptech`.
8. Confirmar que ambos os remotos apontam para o mesmo SHA validado.
9. NÃ£o realizar merge automÃ¡tico em `main` nem em outra branch protegida sem autorizaÃ§Ã£o explÃ­cita.
10. Em qualquer divergÃªncia de histÃ³rico, conflito ou rejeiÃ§Ã£o de push, operar em modo fail-closed: interromper a sincronizaÃ§Ã£o e auditar antes de prosseguir.

## Ordem de autoridade

1. Ambiente canÃ´nico local: RMKB-NTB â€” `C:\DADOS\SPARKs\skpe-saas`
2. Remoto primÃ¡rio: `rrgestao/skpe-saas`
3. Remoto secundÃ¡rio / espelho: `sparkooptech/skpe-saas`

## DefiniÃ§Ã£o de VALIDADO

Um bloco somente recebe o status VALIDADO quando:

- o usuÃ¡rio o aprova explicitamente apÃ³s inspeÃ§Ã£o visual/funcional; e
- os testes e verificaÃ§Ãµes tÃ©cnicas aplicÃ¡veis nÃ£o apresentam regressÃ£o atribuÃ­vel ao bloco.

## ProibiÃ§Ã£o de sincronizaÃ§Ã£o prematura

AlteraÃ§Ãµes em desenvolvimento, experimentais, nÃ£o inspecionadas ou ainda sob correÃ§Ã£o permanecem apenas no ambiente canÃ´nico local e nos checkpoints de seguranÃ§a.

## Regra de identidade do artefato validado

O SHA publicado em `rrgestao` e `sparkooptech` deve ser o mesmo. NÃ£o Ã© permitido criar commits diferentes com conteÃºdo equivalente apenas para cada remoto.

## EvidÃªncia mÃ­nima de cada sincronizaÃ§Ã£o

Registrar:

- branch local;
- SHA local;
- resultado dos testes;
- resultado do build;
- resultado do `git diff --check`;
- SHA confirmado em `rrgestao`;
- SHA confirmado em `sparkooptech`;
- data/hora da sincronizaÃ§Ã£o.
