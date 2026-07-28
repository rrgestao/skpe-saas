# Bloco 1.10B-6 — Tratamento assistido dos conflitos

Este bloco:

- apresenta os seis conflitos do lote;
- preserva a decisão proposta `accept_canonical`;
- exige justificativa humana;
- registra usuário, data, decisão e evento de auditoria;
- corrige o critério de prontidão para reconhecer os estados formais `approved`, `adjusted` e `rejected`;
- altera o status do lote para `ready` somente após todos os critérios serem atendidos;
- não executa carga definitiva;
- preserva MF1 aprovada, MF2 em andamento e PEM-02.04 bloqueado;
- substitui o botão textual de retorno por um ícone circular no padrão visual do portal.

## Ordem de instalação

1. Execute a migration `20260728234500_add_skpe_conflict_assisted_resolution.sql` no SQL Editor do Supabase.
2. Substitua integralmente `CanonicalImportStaging.tsx` e `CanonicalImportStaging.css`.
3. Execute `npm run build`.
4. Execute `npm run dev`.
5. Retome o lote, clique em `Avaliar prontidão para carga`, revise os seis conflitos, informe a justificativa e confirme o tratamento.
6. A aplicação reavalia a prontidão automaticamente.
