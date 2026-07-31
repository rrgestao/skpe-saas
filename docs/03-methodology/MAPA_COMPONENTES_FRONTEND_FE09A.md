# Mapa de Componentes Frontend — FE-09.A

## 1. Estrutura proposta

```text
modules/skpe/
├── app/
│   ├── SkpeWorkspace.tsx
│   ├── SkpeWorkspaceLayout.tsx
│   └── SkpeWorkspaceRoutes.tsx
├── context/
│   ├── SkpeWorkspaceContext.tsx
│   └── SkpeCapabilitiesContext.tsx
├── api/
│   ├── formulations.api.ts
│   ├── identity.api.ts
│   ├── business-architecture.api.ts
│   ├── strategic-map.api.ts
│   ├── indicators.api.ts
│   ├── okrs.api.ts
│   ├── initiatives.api.ts
│   ├── monitoring.api.ts
│   └── governance.api.ts
├── features/
│   ├── workspace/
│   ├── formulations/
│   ├── identity/
│   ├── business-architecture/
│   ├── strategic-map/
│   ├── indicators/
│   ├── okrs/
│   ├── initiatives/
│   ├── monitoring/
│   └── governance/
└── shared/
    ├── components/
    ├── forms/
    ├── readiness/
    ├── audit/
    ├── status/
    └── types/
```

## 2. Componentes transversais

- `ContextSelector`;
- `WorkspaceHeader`;
- `PackageHeader`;
- `ReadinessPanel`;
- `AuditTimeline`;
- `TransitionDialog`;
- `ReasonField`;
- `StatusBadge`;
- `EmptyState`;
- `ErrorState`;
- `LoadingState`;
- `UnsavedChangesGuard`;
- `MetricCard`;
- `DrillDownChart`;
- `NotificationsBell`;
- `FavoriteButton`.

## 3. Refatoração do cockpit

### Manter

- casca visual;
- menu lateral;
- tema;
- estilos reutilizáveis;
- componentes de organização;
- jornada;
- artefatos.

### Extrair

- tipos;
- ícones;
- chamadas RPC;
- cada seção funcional;
- formulários;
- modais;
- utilitários;
- mapeamentos de rótulos.

### Não fazer

- reescrever tudo em um único commit;
- duplicar CSS sem design tokens;
- alterar o banco para simplificar o frontend;
- manter contratos legados como fonte principal quando houver contrato FE canônico.

## 4. Estado

Estado de servidor:

- consultas;
- pacotes;
- registros;
- auditoria;
- notificações.

Estado local:

- formulários;
- filtros;
- modal;
- seleção temporária;
- preferências visuais.

Redux não é obrigatório na FE-09.A.
