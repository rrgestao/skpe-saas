# Patch manual para PortabilityAdmin.tsx

Adicione junto aos imports:

```ts
import { CanonicalImportStaging } from './CanonicalImportStaging'
```

Logo depois de:

```tsx
<CanonicalWorkbookImportPreview organizations={organizations} />
```

adicione:

```tsx
<CanonicalImportStaging organizations={organizations} />
```
