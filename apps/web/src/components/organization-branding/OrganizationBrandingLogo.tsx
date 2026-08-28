import { useEffect, useState } from 'react'

import { supabase } from '../../lib/supabase'
import './OrganizationBrandingLogo.css'

type Props = {
  organizationId: string | null
  organizationName?: string | null
  logoStoragePath?: string | null
  className?: string
}

type LogoState = {
  url: string | null
  path: string | null
  loading: boolean
}

const BUCKET = 'organization-branding'
const SIGNED_URL_TTL_SECONDS = 3600

export function OrganizationBrandingLogo({
  organizationId,
  organizationName,
  logoStoragePath = null,
  className = '',
}: Props) {
  const [state, setState] = useState<LogoState>({
    url: null,
    path: null,
    loading: false,
  })

  useEffect(() => {
    let active = true
    let renewalTimer: number | null = null

    const loadLogo = async () => {
      if (!organizationId) {
        setState({ url: null, path: null, loading: false })
        return
      }

      setState((current) => ({ ...current, loading: true }))

      let path = logoStoragePath?.trim() || null

      // Compatibilidade com organizações antigas que ainda não projetam
      // explicitamente o caminho canônico da identidade visual.
      if (!path) {
        const folder = `${organizationId}/logo`
        const { data: files, error: listError } = await supabase.storage
          .from(BUCKET)
          .list(folder, {
            limit: 100,
            sortBy: { column: 'created_at', order: 'desc' },
          })

        if (!active) return

        if (listError || !files?.length) {
          console.warn('Logo institucional nao localizada.', listError)
          setState({ url: null, path: null, loading: false })
          return
        }

        const candidate = files.find((file) =>
          /\.(png|jpe?g|webp|svg)$/i.test(file.name),
        )

        if (!candidate) {
          setState({ url: null, path: null, loading: false })
          return
        }

        path = `${folder}/${candidate.name}`
      }

      const { data, error } = await supabase.storage
        .from(BUCKET)
        .createSignedUrl(path, SIGNED_URL_TTL_SECONDS)

      if (!active) return

      if (error || !data?.signedUrl) {
        console.warn('Nao foi possivel assinar a logo institucional.', error)
        setState({ url: null, path, loading: false })
        return
      }

      setState({ url: data.signedUrl, path, loading: false })

      renewalTimer = window.setTimeout(
        () => void loadLogo(),
        (SIGNED_URL_TTL_SECONDS - 300) * 1000,
      )
    }

    void loadLogo()

    return () => {
      active = false
      if (renewalTimer !== null) window.clearTimeout(renewalTimer)
    }
  }, [organizationId, logoStoragePath])

  if (!organizationId) return null

  if (state.url) {
    return (
      <img
        className={`organization-branding-logo ${className}`.trim()}
        src={state.url}
        alt={organizationName ? `Logo da ${organizationName}` : 'Logo da organização'}
        data-storage-path={state.path ?? undefined}
      />
    )
  }

  return (
    <div
      className={`organization-branding-fallback ${className}`.trim()}
      aria-label={state.loading ? 'Carregando logo da organização' : 'Identidade da organização'}
      title={organizationName ?? undefined}
    >
      {state.loading ? '…' : (organizationName?.trim().charAt(0).toUpperCase() || 'O')}
    </div>
  )
}
