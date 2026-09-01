import { useEffect, useMemo, useRef, useState } from 'react'
import type { ChangeEvent, FormEvent } from 'react'

import { supabase } from '../../lib/supabase'

import './UserProfileDialog.css'

type ProfileRow = {
  user_id: string
  email: string | null
  full_name: string | null
  display_name: string | null
  phone: string | null
  avatar_storage_path: string | null
  active: boolean
  updated_at: string | null
}

type UserProfileDialogProps = {
  open: boolean
  userId: string
  email: string
  onClose: () => void
  onSaved: () => void
}

const ACCEPTED_TYPES = [
  'image/png',
  'image/jpeg',
  'image/webp',
]

function getInitials(name: string, email: string) {
  const source = name.trim() || email.trim() || 'Usuário'
  const parts = source.split(/\s+/).filter(Boolean)

  if (parts.length >= 2) {
    return `${parts[0][0]}${parts[parts.length - 1][0]}`.toUpperCase()
  }

  return source.slice(0, 2).toUpperCase()
}

export function UserProfileDialog({
  open,
  userId,
  email,
  onClose,
  onSaved,
}: UserProfileDialogProps) {
  const avatarInputRef = useRef<HTMLInputElement | null>(null)
  const [loading, setLoading] = useState(false)
  const [fullName, setFullName] = useState('')
  const [displayName, setDisplayName] = useState('')
  const [phone, setPhone] = useState('')
  const [avatarPath, setAvatarPath] = useState<string | null>(null)
  const [avatarUrl, setAvatarUrl] = useState<string | null>(null)
  const [avatarFile, setAvatarFile] = useState<File | null>(null)
  const [removeAvatar, setRemoveAvatar] = useState(false)
  const [reason, setReason] = useState('')
  const [message, setMessage] = useState('')
  const [messageType, setMessageType] =
    useState<'info' | 'success' | 'error'>('info')
  const [requestingPasswordChange, setRequestingPasswordChange] =
    useState(false)

  const initials = useMemo(
    () => getInitials(displayName || fullName, email),
    [displayName, email, fullName],
  )

  useEffect(() => {
    if (!open) {
      return
    }

    let active = true

    const loadProfile = async () => {
      setLoading(true)
      setMessage('')
      setAvatarFile(null)
      setRemoveAvatar(false)

      const { data, error } = await supabase.rpc(
        'get_my_transversal_profile',
      )

      if (!active) {
        return
      }

      if (error) {
        setMessage(`Erro ao carregar perfil: ${error.message}`)
        setMessageType('error')
        setLoading(false)
        return
      }

      const profile = ((data ?? [])[0] ?? null) as ProfileRow | null

      if (!profile) {
        setMessage('Perfil do usuário não encontrado.')
        setMessageType('error')
        setLoading(false)
        return
      }

      setFullName(profile.full_name ?? '')
      setDisplayName(profile.display_name ?? '')
      setPhone(profile.phone ?? '')
      setAvatarPath(profile.avatar_storage_path)
      setReason('')

      if (profile.avatar_storage_path) {
        const { data: signedData, error: signedError } =
          await supabase.storage
            .from('user-avatars')
            .createSignedUrl(profile.avatar_storage_path, 60 * 60)

        if (!active) {
          return
        }

        if (signedError) {
          setAvatarUrl(null)
        } else {
          setAvatarUrl(signedData.signedUrl)
        }
      } else {
        setAvatarUrl(null)
      }

      setLoading(false)
    }

    void loadProfile()

    return () => {
      active = false
    }
  }, [open])

  const handleAvatarChange = (
    event: ChangeEvent<HTMLInputElement>,
  ) => {
    const file = event.target.files?.[0] ?? null

    if (!file) {
      return
    }

    if (!ACCEPTED_TYPES.includes(file.type)) {
      setMessage('Use uma imagem PNG, JPG ou WebP.')
      setMessageType('error')
      event.target.value = ''
      return
    }

    if (file.size > 5 * 1024 * 1024) {
      setMessage('A imagem deve ter no máximo 5 MB.')
      setMessageType('error')
      event.target.value = ''
      return
    }

    setAvatarFile(file)
    setRemoveAvatar(false)
    setAvatarUrl(URL.createObjectURL(file))
    setMessage('Nova imagem selecionada. Salve para confirmar.')
    setMessageType('info')
  }

  const handleRemoveAvatar = () => {
    setAvatarFile(null)
    setAvatarUrl(null)
    setRemoveAvatar(true)
    setMessage('A foto será removida ao salvar.')
    setMessageType('info')
  }

  const handlePasswordChangeRequest = async () => {
    const normalizedEmail = email.trim().toLowerCase()

    if (!normalizedEmail) {
      setMessage('Não foi possível identificar o e-mail da conta.')
      setMessageType('error')
      return
    }

    setRequestingPasswordChange(true)
    setMessage('')

    const { error } = await supabase.auth.resetPasswordForEmail(
      normalizedEmail,
      {
        redirectTo: window.location.origin,
      },
    )

    if (error) {
      setMessage(
        `Não foi possível solicitar a alteração da senha: ${error.message}`,
      )
      setMessageType('error')
      setRequestingPasswordChange(false)
      return
    }

    setMessage(
      'Enviamos as instruções para alteração da senha ao e-mail da sua conta.',
    )
    setMessageType('success')
    setRequestingPasswordChange(false)
  }
  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault()

    if (!fullName.trim()) {
      setMessage('Informe o nome completo.')
      setMessageType('error')
      return
    }

    if (!reason.trim()) {
      setMessage('Informe o motivo da alteração.')
      setMessageType('error')
      return
    }

    setLoading(true)
    setMessage('')

    let nextAvatarPath = removeAvatar ? null : avatarPath
    let uploadedPath: string | null = null

    if (avatarFile) {
      const extension =
        avatarFile.name.split('.').pop()?.toLowerCase() || 'png'
      uploadedPath =
        `${userId}/avatar-${Date.now()}.${extension}`

      const { error: uploadError } = await supabase.storage
        .from('user-avatars')
        .upload(uploadedPath, avatarFile, {
          upsert: false,
          contentType: avatarFile.type,
        })

      if (uploadError) {
        setMessage(`Erro ao enviar avatar: ${uploadError.message}`)
        setMessageType('error')
        setLoading(false)
        return
      }

      nextAvatarPath = uploadedPath
    }

    const { error } = await supabase.rpc(
      'update_my_transversal_profile',
      {
        input_full_name: fullName.trim(),
        input_display_name: displayName.trim() || null,
        input_phone: phone.trim() || null,
        input_avatar_storage_path: nextAvatarPath,
        change_reason: reason.trim(),
      },
    )

    if (error) {
      if (uploadedPath) {
        await supabase.storage
          .from('user-avatars')
          .remove([uploadedPath])
      }

      setMessage(`Erro ao atualizar perfil: ${error.message}`)
      setMessageType('error')
      setLoading(false)
      return
    }

    const obsoletePath =
      avatarPath && avatarPath !== nextAvatarPath
        ? avatarPath
        : null

    if (obsoletePath) {
      await supabase.storage
        .from('user-avatars')
        .remove([obsoletePath])
    }

    setAvatarPath(nextAvatarPath)
    setAvatarFile(null)
    setRemoveAvatar(false)
    setReason('')
    setMessage('Perfil atualizado com sucesso.')
    setMessageType('success')
    setLoading(false)
    onSaved()
  }

  if (!open) {
    return null
  }

  return (
    <div
      className="user-profile-dialog-backdrop"
      role="presentation"
      onMouseDown={(event) => {
        if (event.target === event.currentTarget && !loading) {
          onClose()
        }
      }}
    >
      <section
        className="user-profile-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="user-profile-dialog-title"
      >
        <header className="user-profile-dialog-header">
          <div>
            <p className="eyebrow">Perfil transversal</p>
            <h2 id="user-profile-dialog-title">Meu perfil</h2>
            <p>
              Seus dados e sua foto serão usados em toda a Plataforma SPARKs.
            </p>
          </div>

          <button
            type="button"
            className="user-profile-dialog-close"
            onClick={onClose}
            disabled={loading}
            aria-label="Fechar perfil"
            title="Fechar"
          >
            ×
          </button>
        </header>

        <form
          className="user-profile-dialog-form"
          onSubmit={handleSubmit}
        >
          <div className="user-profile-account-cards">
          <section className="user-profile-account-card user-profile-photo-card">
            <div className="user-profile-account-card-heading">
              <div>
                <strong>Foto do perfil</strong>
                <p>Identidade visual usada em toda a Plataforma SPARKs.</p>
              </div>
            </div>

            <div className="user-profile-avatar-editor">
              <button
                type="button"
                className="user-profile-avatar-preview"
                onClick={() => avatarInputRef.current?.click()}
                disabled={loading}
                aria-label={
                  avatarUrl
                    ? 'Alterar foto do perfil'
                    : 'Adicionar foto do perfil'
                }
                title={
                  avatarUrl
                    ? 'Alterar foto do perfil. PNG, JPG ou WebP, até 5 MB.'
                    : 'Adicionar foto do perfil. PNG, JPG ou WebP, até 5 MB.'
                }
              >
                {avatarUrl ? (
                  <img src={avatarUrl} alt="" />
                ) : (
                  <span aria-hidden="true">{initials}</span>
                )}

                <span
                  className="user-profile-avatar-overlay"
                  aria-hidden="true"
                >
                  PNG, JPG ou WebP · até 5 MB
                </span>
              </button>

              <div>
                <strong>Foto do perfil</strong>

                <div className="user-profile-avatar-actions">
                  <input
                    ref={avatarInputRef}
                    className="user-profile-avatar-file-input"
                    type="file"
                    accept="image/png,image/jpeg,image/webp"
                    onChange={handleAvatarChange}
                    disabled={loading}
                  />

                  <button
                    type="button"
                    className="secondary-button"
                    onClick={() => avatarInputRef.current?.click()}
                    disabled={loading}
                  >
                    Selecionar foto
                  </button>

                  {(avatarUrl || avatarPath) && (
                    <button
                      type="button"
                      className="text-button"
                      onClick={handleRemoveAvatar}
                      disabled={loading}
                    >
                      Remover foto
                    </button>
                  )}
                </div>
              </div>
            </div>
          </section>

          <section className="user-profile-account-card user-profile-security-card">
            <button
              type="button"
              className="user-profile-security-icon user-profile-security-action"
              onClick={() => void handlePasswordChangeRequest()}
              disabled={loading || requestingPasswordChange}
              aria-label={
                requestingPasswordChange
                  ? 'Solicitando alteração de senha'
                  : 'Alterar senha'
              }
              title={
                requestingPasswordChange
                  ? 'Solicitando...'
                  : 'Alterar senha'
              }
            >
              <svg viewBox="0 0 24 24" focusable="false" aria-hidden="true">
                <path
                  d="M7 10V8a5 5 0 0 1 10 0v2m-9 0h8a2 2 0 0 1 2 2v7H6v-7a2 2 0 0 1 2-2Zm4 4v2"
                />
              </svg>
            </button>

            <div className="user-profile-security-content">
              <strong>Segurança da conta</strong>
              <p>Solicite um link seguro para definir uma nova senha.</p>


            </div>
          </section>
          </div>
          <div className="user-profile-fields">
            <label>
              Nome completo
              <input
                value={fullName}
                onChange={(event) => setFullName(event.target.value)}
                required
                disabled={loading}
              />
            </label>

            <label>
              Nome de exibição
              <input
                value={displayName}
                onChange={(event) => setDisplayName(event.target.value)}
                disabled={loading}
              />
            </label>

            <label>
              E-mail
              <input value={email} readOnly />
            </label>

            <label>
              Telefone
              <input
                value={phone}
                onChange={(event) => setPhone(event.target.value)}
                disabled={loading}
              />
            </label>
          </div>

          <label>
            Motivo da alteração
            <textarea
              value={reason}
              onChange={(event) => setReason(event.target.value)}
              rows={3}
              required
              disabled={loading}
              placeholder="Ex.: atualização dos meus dados cadastrais."
            />
          </label>

          {message && (
            <p
              className={`message message-${messageType}`}
              role={messageType === 'error' ? 'alert' : 'status'}
            >
              {message}
            </p>
          )}

          <footer className="user-profile-dialog-footer">
            <button
              type="button"
              className="secondary-button"
              onClick={onClose}
              disabled={loading}
            >
              Cancelar
            </button>

            <button
              type="submit"
              className="primary-button"
              disabled={loading}
            >
              {loading ? 'Salvando...' : 'Salvar perfil'}
            </button>
          </footer>
        </form>
      </section>
    </div>
  )
}