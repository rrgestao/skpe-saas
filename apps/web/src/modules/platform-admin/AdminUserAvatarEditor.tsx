import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import type { ChangeEvent } from 'react'

import { supabase } from '../../lib/supabase'

import './AdminUserAvatarEditor.css'

type AdminUserAvatarEditorProps = {
  userId: string
  userName: string
}

const ACCEPTED_TYPES = [
  'image/png',
  'image/jpeg',
  'image/webp',
]

function getInitial(name: string) {
  return (name.trim() || 'U').slice(0, 1).toLocaleUpperCase('pt-BR')
}

export function AdminUserAvatarEditor({
  userId,
  userName,
}: AdminUserAvatarEditorProps) {
  const inputRef = useRef<HTMLInputElement | null>(null)
  const [open, setOpen] = useState(false)
  const [saving, setSaving] = useState(false)
  const [avatarPath, setAvatarPath] = useState<string | null>(null)
  const [avatarUrl, setAvatarUrl] = useState<string | null>(null)
  const [selectedFile, setSelectedFile] = useState<File | null>(null)
  const [removeAvatar, setRemoveAvatar] = useState(false)
  const [reason, setReason] = useState('')
  const [message, setMessage] = useState('')

  const initial = useMemo(() => getInitial(userName), [userName])

  const loadAvatar = useCallback(async () => {
    const { data, error } = await supabase.rpc(
      'get_platform_admin_user_avatar',
      { target_user_id: userId },
    )

    if (error) {
      setMessage((current) =>
        current === error.message ? current : error.message,
      )
      return
    }

    const row = ((data ?? [])[0] ?? null) as {
      avatar_storage_path: string | null
    } | null

    const path = row?.avatar_storage_path ?? null
    setAvatarPath((current) => (current === path ? current : path))

    if (!path) {
      setAvatarUrl((current) => (current === null ? current : null))
      return
    }

    const { data: signedData, error: signedUrlError } =
      await supabase.storage
        .from('user-avatars')
        .createSignedUrl(path, 60 * 60)

    if (signedUrlError) {
      setMessage((current) =>
        current === signedUrlError.message
          ? current
          : signedUrlError.message,
      )
      return
    }

    const signedUrl = signedData?.signedUrl ?? null
    setAvatarUrl((current) =>
      current === signedUrl ? current : signedUrl,
    )
  }, [userId])

  useEffect(() => {
    void loadAvatar()
  }, [loadAvatar])

  const handleFile = (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0] ?? null

    if (!file) {
      return
    }

    if (!ACCEPTED_TYPES.includes(file.type)) {
      setMessage('Use uma imagem PNG, JPG ou WebP.')
      event.target.value = ''
      return
    }

    if (file.size > 5 * 1024 * 1024) {
      setMessage('A imagem deve ter no máximo 5 MB.')
      event.target.value = ''
      return
    }

    setSelectedFile(file)
    setRemoveAvatar(false)
    setAvatarUrl(URL.createObjectURL(file))
    setMessage('')
  }

  const save = async () => {
    if (reason.trim().length < 10) {
      setMessage('Informe uma justificativa com pelo menos 10 caracteres.')
      return
    }

    setSaving(true)
    setMessage('')

    let nextPath = removeAvatar ? null : avatarPath
    let uploadedPath: string | null = null

    if (selectedFile) {
      const extension =
        selectedFile.name.split('.').pop()?.toLowerCase() || 'png'
      uploadedPath = `${userId}/admin-avatar-${Date.now()}.${extension}`

      const { error: uploadError } = await supabase.storage
        .from('user-avatars')
        .upload(uploadedPath, selectedFile, {
          upsert: false,
          contentType: selectedFile.type,
        })

      if (uploadError) {
        setMessage(`Erro ao enviar foto: ${uploadError.message}`)
        setSaving(false)
        return
      }

      nextPath = uploadedPath
    }

    const { error } = await supabase.rpc(
      'set_platform_admin_user_avatar',
      {
        target_user_id: userId,
        input_avatar_storage_path: nextPath,
        change_reason: reason.trim(),
      },
    )

    if (error) {
      if (uploadedPath) {
        await supabase.storage
          .from('user-avatars')
          .remove([uploadedPath])
      }

      setMessage(error.message)
      setSaving(false)
      return
    }

    if (avatarPath && avatarPath !== nextPath) {
      await supabase.storage
        .from('user-avatars')
        .remove([avatarPath])
    }

    setSelectedFile(null)
    setRemoveAvatar(false)
    setReason('')
    setOpen(false)
    setSaving(false)
    await loadAvatar()
    window.dispatchEvent(
      new CustomEvent('platform-user-avatar-changed', {
        detail: { userId },
      }),
    )
}

  return (
    <>
      <button
        type="button"
        className="pa-admin-avatar-trigger"
        onClick={() => setOpen(true)}
        aria-label={`Alterar foto de ${userName}`}
        title="Alterar foto do usuário"
      >
        {avatarUrl ? (
          <img src={avatarUrl} alt="" />
        ) : (
          <span aria-hidden="true">{initial}</span>
        )}
        <small aria-hidden="true">Alterar</small>
      </button>

      {open && (
        <div
          className="pa-admin-avatar-backdrop"
          role="presentation"
          onMouseDown={(event) => {
            if (event.target === event.currentTarget && !saving) {
              setOpen(false)
            }
          }}
        >
          <section
            className="pa-admin-avatar-dialog"
            role="dialog"
            aria-modal="true"
            aria-label={`Foto de ${userName}`}
          >
            <header>
              <div>
                <p>Identidade do usuário</p>
                <h3>Foto de {userName}</h3>
              </div>
              <button
                type="button"
                onClick={() => setOpen(false)}
                disabled={saving}
                aria-label="Fechar"
              >
                ×
              </button>
            </header>

            <div className="pa-admin-avatar-body">
              <button
                type="button"
                className="pa-admin-avatar-preview"
                onClick={() => inputRef.current?.click()}
                disabled={saving}
              >
                {avatarUrl ? (
                  <img src={avatarUrl} alt="" />
                ) : (
                  <span>{initial}</span>
                )}
                <small>Selecionar foto</small>
              </button>

              <input
                ref={inputRef}
                type="file"
                accept="image/png,image/jpeg,image/webp"
                onChange={handleFile}
                hidden
              />

              <div className="pa-admin-avatar-actions">
                <button
                  type="button"
                  onClick={() => inputRef.current?.click()}
                  disabled={saving}
                >
                  Selecionar foto
                </button>

                {(avatarUrl || avatarPath) && (
                  <button
                    type="button"
                    onClick={() => {
                      setSelectedFile(null)
                      setAvatarUrl(null)
                      setRemoveAvatar(true)
                    }}
                    disabled={saving}
                  >
                    Remover foto
                  </button>
                )}
              </div>

              <label>
                Justificativa administrativa
                <textarea
                  value={reason}
                  onChange={(event) => setReason(event.target.value)}
                  rows={3}
                  placeholder="Ex.: carga inicial dos dados e identidade do usuário."
                  disabled={saving}
                />
              </label>

              {message && <p role="alert">{message}</p>}
            </div>

            <footer>
              <button
                type="button"
                onClick={() => setOpen(false)}
                disabled={saving}
              >
                Cancelar
              </button>
              <button
                type="button"
                onClick={() => void save()}
                disabled={saving}
              >
                {saving ? 'Salvando...' : 'Salvar foto'}
              </button>
            </footer>
          </section>
        </div>
      )}
    </>
  )
}