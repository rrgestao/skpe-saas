import { useEffect, useState } from 'react'
import { supabase } from '../../../../lib/supabase'
import { useSkpeWorkspace } from '../../context/SkpeWorkspaceContext'
import './StrategicContentSection.css'

type IdentityItem = {
  id: string
  elementType: string
  content: string
  displayOrder: number
  validationStatus: string
}

type IdentityValue = {
  id: string
  code: string
  name: string
  description: string | null
  displayOrder: number
  status: string
}

type IdentityPayload = {
  items: IdentityItem[]
  values: IdentityValue[]
}

type LegacyItem = {
  id: string
  element_type: string
  content: string
  display_order: number
  validation_status: string
}

type LegacyValue = {
  id: string
  code: string
  name: string
  description: string | null
  display_order: number
  status: string
}

type Props = {
  organizationId: string
  projectId?: string | null
  formulationId?: string | null
}

const labels: Record<string, string> = {
  purpose: 'Propósito',
  mission: 'Missão',
  vision: 'Visão',
  proposito: 'Propósito',
  missao: 'Missão',
  visao: 'Visão',
}

export function StrategicIdentitySection({
  organizationId,
  projectId,
  formulationId,
}: Props) {
  const workspace = useSkpeWorkspace()
  const resolvedProjectId = projectId ?? workspace.route.projectId
  const [items, setItems] = useState<IdentityItem[]>([])
  const [values, setValues] = useState<IdentityValue[]>([])
  const [error, setError] = useState('')

  useEffect(() => {
    let active = true
    setError('')

    async function loadIdentity() {
      if (formulationId) {
        const { data, error: rpcError } = await supabase.rpc(
          'get_skpe_strategic_identity',
          { target_formulation_id: formulationId },
        )

        if (!active) return

        if (rpcError) {
          setItems([])
          setValues([])
          setError(
            `Não foi possível carregar a Identidade Estratégica: ${rpcError.message}`,
          )
          return
        }

        const payload = data as IdentityPayload | null
        setItems(payload?.items ?? [])
        setValues(payload?.values ?? [])
        return
      }

      if (!resolvedProjectId) {
        setItems([])
        setValues([])
        return
      }

      const [identityResponse, valuesResponse] = await Promise.all([
        supabase
          .from('skpe_strategic_identity_items')
          .select(
            'id,element_type,content,display_order,validation_status',
          )
          .eq('organization_id', organizationId)
          .eq('project_id', resolvedProjectId)
          .eq('validation_status', 'approved')
          .order('display_order'),
        supabase
          .from('skpe_strategic_values')
          .select('id,code,name,description,display_order,status')
          .eq('organization_id', organizationId)
          .eq('project_id', resolvedProjectId)
          .eq('status', 'active')
          .contains('metadata', { decision: 'Aprovado integralmente' })
          .order('display_order'),
      ])

      if (!active) return

      if (identityResponse.error || valuesResponse.error) {
        setItems([])
        setValues([])
        setError('Não foi possível carregar a Identidade Estratégica.')
        return
      }

      setItems(
        ((identityResponse.data ?? []) as LegacyItem[]).map((item) => ({
          id: item.id,
          elementType: item.element_type,
          content: item.content,
          displayOrder: item.display_order,
          validationStatus: item.validation_status,
        })),
      )

      setValues(
        ((valuesResponse.data ?? []) as LegacyValue[]).map((value) => ({
          id: value.id,
          code: value.code,
          name: value.name,
          description: value.description,
          displayOrder: value.display_order,
          status: value.status,
        })),
      )
    }

    void loadIdentity()

    return () => {
      active = false
    }
  }, [formulationId, organizationId, resolvedProjectId])

  if (error) {
    return <section className="skpe-strategy-state is-error">{error}</section>
  }

  return (
    <section className="skpe-strategy-content">
      <header>
        <span>Arquitetura Estratégica</span>
        <h1>Identidade Estratégica</h1>
      </header>

      <div className="skpe-strategy-identity-grid">
        {items.map((item) => (
          <article key={item.id}>
            <small>{labels[item.elementType] ?? item.elementType}</small>
            <strong>{item.content}</strong>
          </article>
        ))}
      </div>

      <section>
        <h2>Valores</h2>
        <div className="skpe-strategy-values-grid">
          {values.map((value) => (
            <article key={value.id}>
              <small>{value.code}</small>
              <strong>{value.name}</strong>
              {value.description ? <p>{value.description}</p> : null}
            </article>
          ))}
        </div>
      </section>
    </section>
  )
}