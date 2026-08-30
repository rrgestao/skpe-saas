import { useEffect, useMemo, useState } from 'react'

import { supabase } from '../../lib/supabase'
import './OrganizationVisualIdentity.css'

type VisualIdentityMode = 'sparks_default' | 'organization'
type PaletteSource = 'default' | 'manual' | 'logo_suggested'

type VisualIdentityColors = {
  primary: string
  secondary: string
  accent: string
  on_primary: string
}

type EffectiveVisualIdentity = {
  schema_version: number
  mode: VisualIdentityMode
  palette_source: PaletteSource
  colors: VisualIdentityColors
  suggested_from_logo?: {
    logo_version?: number
    colors?: string[]
  } | null
}

type VisualIdentityRpcRow = {
  organization_id: string
  logo_url: string | null
  logo_storage_path: string | null
  logo_version: number
  visual_identity_metadata: Record<string, unknown>
  effective_visual_identity: EffectiveVisualIdentity
}

const SPARKS_DEFAULT: EffectiveVisualIdentity = {
  schema_version: 1,
  mode: 'sparks_default',
  palette_source: 'default',
  colors: {
    primary: '#176B53',
    secondary: '#123F34',
    accent: '#1F8C69',
    on_primary: '#FFFFFF',
  },
  suggested_from_logo: null,
}

function normalizeHex(value: string) {
  const trimmed = value.trim().toUpperCase()
  return /^#[0-9A-F]{6}$/.test(trimmed) ? trimmed : null
}

function applyVisualIdentity(identity: EffectiveVisualIdentity) {
  const root = document.documentElement
  const colors = identity.colors ?? SPARKS_DEFAULT.colors

  root.dataset.organizationVisualIdentity = identity.mode
  root.style.setProperty('--organization-primary', colors.primary)
  root.style.setProperty('--organization-secondary', colors.secondary)
  root.style.setProperty('--organization-accent', colors.accent)
  root.style.setProperty('--organization-on-primary', colors.on_primary)
}

async function loadVisualIdentity(organizationId: string) {
  const { data, error } = await supabase.rpc(
    'get_sparks_organization_visual_identity',
    { target_organization_id: organizationId },
  )

  if (error) throw error

  return (((data ?? [])[0] ?? null) as VisualIdentityRpcRow | null)
}

async function extractLogoPalette(logoUrl: string): Promise<string[]> {
  const image = new Image()
  image.crossOrigin = 'anonymous'
  image.decoding = 'async'

  await new Promise<void>((resolve, reject) => {
    image.onload = () => resolve()
    image.onerror = () => reject(new Error('Não foi possível analisar a logo.'))
    image.src = logoUrl
  })

  const canvas = document.createElement('canvas')
  canvas.width = 72
  canvas.height = 72
  const context = canvas.getContext('2d', { willReadFrequently: true })
  if (!context) throw new Error('O navegador não disponibilizou análise de imagem.')

  context.clearRect(0, 0, canvas.width, canvas.height)
  context.drawImage(image, 0, 0, canvas.width, canvas.height)

  const { data } = context.getImageData(0, 0, canvas.width, canvas.height)
  const counts = new Map<string, number>()

  for (let index = 0; index < data.length; index += 16) {
    const r = data[index]
    const g = data[index + 1]
    const b = data[index + 2]
    const a = data[index + 3]
    if (a < 180) continue

    const max = Math.max(r, g, b)
    const min = Math.min(r, g, b)
    if (max > 245 && min > 235) continue
    if (max < 25) continue

    const qr = Math.round(r / 32) * 32
    const qg = Math.round(g / 32) * 32
    const qb = Math.round(b / 32) * 32
    const hex = `#${[qr, qg, qb]
      .map((value) => Math.min(255, value).toString(16).padStart(2, '0'))
      .join('')}`.toUpperCase()

    counts.set(hex, (counts.get(hex) ?? 0) + 1)
  }

  return [...counts.entries()]
    .sort((first, second) => second[1] - first[1])
    .slice(0, 6)
    .map(([hex]) => hex)
}

export function OrganizationVisualIdentityTheme({ organizationId }: { organizationId: string }) {
  useEffect(() => {
    let cancelled = false

    void loadVisualIdentity(organizationId)
      .then((row) => {
        if (cancelled) return
        applyVisualIdentity(row?.effective_visual_identity ?? SPARKS_DEFAULT)
      })
      .catch(() => {
        if (!cancelled) applyVisualIdentity(SPARKS_DEFAULT)
      })

    return () => {
      cancelled = true
    }
  }, [organizationId])

  return null
}

type OrganizationVisualIdentityCardProps = {
  organizationId: string
  canManage: boolean
  logoUrl: string | null
}

export function OrganizationVisualIdentityCard({
  organizationId,
  canManage,
  logoUrl,
}: OrganizationVisualIdentityCardProps) {
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [extracting, setExtracting] = useState(false)
  const [mode, setMode] = useState<VisualIdentityMode>('sparks_default')
  const [paletteSource, setPaletteSource] = useState<PaletteSource>('default')
  const [primary, setPrimary] = useState(SPARKS_DEFAULT.colors.primary)
  const [secondary, setSecondary] = useState(SPARKS_DEFAULT.colors.secondary)
  const [accent, setAccent] = useState(SPARKS_DEFAULT.colors.accent)
  const [suggestedColors, setSuggestedColors] = useState<string[]>([])
  const [changeReason, setChangeReason] = useState('')
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null)

  const previewColors = useMemo(
    () => ({
      primary: normalizeHex(primary) ?? SPARKS_DEFAULT.colors.primary,
      secondary: normalizeHex(secondary) ?? SPARKS_DEFAULT.colors.secondary,
      accent: normalizeHex(accent) ?? SPARKS_DEFAULT.colors.accent,
    }),
    [accent, primary, secondary],
  )

  const hydrate = async () => {
    setLoading(true)
    setMessage(null)

    try {
      const row = await loadVisualIdentity(organizationId)
      const identity = row?.effective_visual_identity ?? SPARKS_DEFAULT
      setMode(identity.mode)
      setPaletteSource(identity.palette_source)
      setPrimary(identity.colors.primary)
      setSecondary(identity.colors.secondary)
      setAccent(identity.colors.accent)
      setSuggestedColors(identity.suggested_from_logo?.colors ?? [])
      applyVisualIdentity(identity)
    } catch (error) {
      setMessage({
        type: 'error',
        text: error instanceof Error ? error.message : 'Não foi possível carregar a identidade visual.',
      })
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void hydrate()
  }, [organizationId])

  const suggestFromLogo = async () => {
    if (!logoUrl || extracting) return
    setExtracting(true)
    setMessage(null)

    try {
      const palette = await extractLogoPalette(logoUrl)
      if (palette.length === 0) throw new Error('A logo não produziu uma paleta utilizável.')

      setMode('organization')
      setPaletteSource('logo_suggested')
      setSuggestedColors(palette)
      setPrimary(palette[0] ?? SPARKS_DEFAULT.colors.primary)
      setSecondary(palette[1] ?? palette[0] ?? SPARKS_DEFAULT.colors.secondary)
      setAccent(palette[2] ?? palette[0] ?? SPARKS_DEFAULT.colors.accent)
      setMessage({
        type: 'success',
        text: 'Paleta sugerida a partir da logo. Revise as cores antes de salvar.',
      })
    } catch (error) {
      setMessage({
        type: 'error',
        text: error instanceof Error ? error.message : 'Não foi possível sugerir a paleta pela logo.',
      })
    } finally {
      setExtracting(false)
    }
  }

  const save = async () => {
    if (!canManage || saving) return
    if (changeReason.trim().length < 10) {
      setMessage({ type: 'error', text: 'Informe uma justificativa com pelo menos 10 caracteres.' })
      return
    }

    if (mode === 'organization' && (!normalizeHex(primary) || !normalizeHex(secondary) || !normalizeHex(accent))) {
      setMessage({ type: 'error', text: 'Revise as cores. Use o formato hexadecimal #RRGGBB.' })
      return
    }

    setSaving(true)
    setMessage(null)

    const { data, error } = await supabase.rpc(
      'update_sparks_organization_visual_identity',
      {
        target_organization_id: organizationId,
        target_theme_mode: mode,
        target_primary_color: mode === 'organization' ? primary : null,
        target_secondary_color: mode === 'organization' ? secondary : null,
        target_accent_color: mode === 'organization' ? accent : null,
        target_palette_source: mode === 'organization' ? paletteSource : 'default',
        target_logo_palette: mode === 'organization' ? suggestedColors : [],
        change_reason: changeReason.trim(),
      },
    )

    if (error) {
      setMessage({ type: 'error', text: error.message })
      setSaving(false)
      return
    }

    const metadata = data as {
      mode?: VisualIdentityMode
      palette_source?: PaletteSource
      colors?: VisualIdentityColors
    } | null

    applyVisualIdentity({
      schema_version: 1,
      mode: metadata?.mode ?? mode,
      palette_source: metadata?.palette_source ?? paletteSource,
      colors: metadata?.colors ?? {
        ...previewColors,
        on_primary: '#FFFFFF',
      },
    })

    setChangeReason('')
    setMessage({ type: 'success', text: 'Identidade visual atualizada com sucesso.' })
    setSaving(false)
    await hydrate()
  }

  return (
    <section className="skpe-visual-identity-card">
      <div className="skpe-visual-identity-heading">
        <div>
          <p className="skpe-card-code">Identidade visual</p>
          <h2>Cores da organização</h2>
          <p>Use o padrão SPARKs ou aplique uma paleta institucional governada. A logo apenas sugere cores; nada é aplicado sem confirmação.</p>
        </div>
        <div
          className="skpe-visual-identity-preview"
          style={{
            '--preview-primary': previewColors.primary,
            '--preview-secondary': previewColors.secondary,
            '--preview-accent': previewColors.accent,
          } as React.CSSProperties}
          aria-label="Pré-visualização da paleta"
        >
          <span />
          <span />
          <span />
        </div>
      </div>

      {loading ? (
        <p>Carregando identidade visual...</p>
      ) : (
        <>
          <div className="skpe-visual-identity-mode">
            <label>
              <input
                type="radio"
                name={`visual-identity-${organizationId}`}
                checked={mode === 'sparks_default'}
                onChange={() => {
                  setMode('sparks_default')
                  setPaletteSource('default')
                }}
                disabled={!canManage}
              />
              <span><strong>Padrão SPARKs</strong><small>Usa a identidade visual padrão da plataforma.</small></span>
            </label>
            <label>
              <input
                type="radio"
                name={`visual-identity-${organizationId}`}
                checked={mode === 'organization'}
                onChange={() => {
                  setMode('organization')
                  if (paletteSource === 'default') setPaletteSource('manual')
                }}
                disabled={!canManage}
              />
              <span><strong>Identidade da organização</strong><small>Personaliza apenas os tokens institucionais previstos pelo design system.</small></span>
            </label>
          </div>

          {mode === 'organization' && (
            <>
              <div className="skpe-visual-identity-colors">
                {[
                  ['Cor principal', primary, setPrimary],
                  ['Cor secundária', secondary, setSecondary],
                  ['Cor de destaque', accent, setAccent],
                ].map(([label, value, setter]) => (
                  <label key={label as string}>
                    <span>{label as string}</span>
                    <div>
                      <input
                        type="color"
                        value={(normalizeHex(value as string) ?? '#176B53').toLowerCase()}
                        onChange={(event) => {
                          ;(setter as (value: string) => void)(event.target.value.toUpperCase())
                          setPaletteSource('manual')
                        }}
                        disabled={!canManage}
                      />
                      <input
                        value={value as string}
                        onChange={(event) => {
                          ;(setter as (value: string) => void)(event.target.value.toUpperCase())
                          setPaletteSource('manual')
                        }}
                        disabled={!canManage}
                        maxLength={7}
                      />
                    </div>
                  </label>
                ))}
              </div>

              <div className="skpe-visual-identity-logo-actions">
                <button type="button" onClick={() => void suggestFromLogo()} disabled={!canManage || !logoUrl || extracting}>
                  {extracting ? 'Analisando logo...' : 'Sugerir paleta pela logo'}
                </button>
                {!logoUrl && <small>Cadastre uma logo para habilitar a sugestão automática de paleta.</small>}
              </div>

              {suggestedColors.length > 0 && (
                <div className="skpe-visual-identity-swatches" aria-label="Cores sugeridas pela logo">
                  {suggestedColors.map((color) => (
                    <button
                      key={color}
                      type="button"
                      style={{ background: color }}
                      title={`Usar ${color} como cor principal`}
                      aria-label={`Usar ${color} como cor principal`}
                      onClick={() => {
                        setPrimary(color)
                        setPaletteSource('logo_suggested')
                      }}
                      disabled={!canManage}
                    />
                  ))}
                </div>
              )}
            </>
          )}

          {canManage && (
            <div className="skpe-visual-identity-save">
              <label>
                <span>Justificativa da alteração *</span>
                <input
                  value={changeReason}
                  onChange={(event) => setChangeReason(event.target.value)}
                  placeholder="Ex.: adequação à identidade institucional aprovada"
                />
              </label>
              <button type="button" onClick={() => void save()} disabled={saving}>
                {saving ? 'Salvando...' : 'Salvar identidade visual'}
              </button>
            </div>
          )}
        </>
      )}

      {message && <p className={`skpe-visual-identity-message skpe-visual-identity-message-${message.type}`}>{message.text}</p>}
    </section>
  )
}
