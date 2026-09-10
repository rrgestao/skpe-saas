import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import '@fontsource-variable/manrope'
import '@fontsource-variable/inter'
import './index.css'
import App from './App.tsx'
import './responsive.css'
import './responsive-stabilization.css'
import './components/design-system/platform-shell-hardening.css'
import './components/design-system/platform-shell-hardening'
import './components/design-system/adaptive-geometry.css'
import './components/design-system/transversal-dark-theme.css'
import './components/design-system/portal-home-grid.css'
import './components/design-system/portal-hierarchy.css'
import './components/design-system/visual-canon.css'
import './components/design-system/portal-tree-grid.css'
import './components/application-shell/TransversalWorkspace.css'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrowserRouter>
      <App />
    </BrowserRouter>
  </StrictMode>,
)
