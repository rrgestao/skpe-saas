# Bloco 1.10B-5 — Tratamento assistido do registro bloqueado

Este pacote permite revisar e corrigir manualmente `version_control:v17` no staging.

## Proteções
- exige usuário autenticado e autorizado;
- exige confirmação humana e justificativa;
- registra evento de auditoria;
- não executa carga definitiva;
- preserva MF1 aprovada, MF2 em andamento e PEM-02.04 bloqueado.

## Sequência
1. Execute a migration.
2. Substitua integralmente os arquivos TSX e CSS.
3. Compile e reinicie.
4. Retome o lote e avalie a prontidão.
5. Clique em **Revisar e corrigir**.
6. Compare valores recebidos e proposta.
7. Confirme a correção.
8. Confira a reavaliação automática.
