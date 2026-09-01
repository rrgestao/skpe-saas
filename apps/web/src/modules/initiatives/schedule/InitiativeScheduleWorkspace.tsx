import { useEffect, useState } from 'react'

import { supabase } from '../../../lib/supabase'
import { translateBackendMessage } from '../../../shared/i18n/ptBR'
import type {
  JourneyTemporalReadRow,
  JourneyTemporalRow,
} from '../../skpe/contracts/journey'
import { SvarJourneyGantt } from '../../skpe/features/journey/SvarJourneyGantt'

type Props = {
  organizationId: string
  initiativeId: string
  initiativeName: string
  skpeProjectId: string | null
}

export function InitiativeScheduleWorkspace({
  organizationId,
  initiativeId,
  initiativeName,
  skpeProjectId,
}: Props) {
  const [rows, setRows] = useState<JourneyTemporalRow[]>([])
  const [loading, setLoading] = useState(Boolean(skpeProjectId))
  const [errorMessage, setErrorMessage] = useState('')

  useEffect(() => {
    let active = true

    const load = async () => {
      if (!skpeProjectId) {
        setRows([])
        setLoading(false)
        setErrorMessage('')
        return
      }

      setLoading(true)
      setErrorMessage('')

      const { data, error } = await supabase.rpc(
        'get_skpe_journey_temporal_read_model',
        {
          target_organization_id: organizationId,
          target_project_id: skpeProjectId,
          target_as_of_date: null,
        },
      )

      if (!active) return

      if (error) {
        setRows([])
        setErrorMessage(translateBackendMessage(error.message))
        setLoading(false)
        return
      }

      const journeyRows = ((data ?? []) as JourneyTemporalReadRow[]).map(
        (row): JourneyTemporalRow => ({
          ...row,
          planned_start_date: row.current_plan_start_date,
          planned_end_date: row.current_plan_end_date,
        }),
      )

      setRows(journeyRows)
      setLoading(false)
    }

    void load()

    return () => {
      active = false
    }
  }, [initiativeId, organizationId, skpeProjectId])

  if (!skpeProjectId) {
    return (
      <section className="skpe-admin-state-card">
        <strong>Cronograma ainda não materializado para esta iniciativa</strong>
        <p>
          A infraestrutura temporal está preparada, mas esta classe de iniciativa
          ainda não possui um Projeto/Jornada governado vinculado. Nenhuma data
          será inferida.
        </p>
      </section>
    )
  }

  if (loading) {
    return (
      <section className="skpe-admin-state-card">
        <p>Carregando cronograma de {initiativeName}...</p>
      </section>
    )
  }

  if (errorMessage) {
    return (
      <section className="skpe-admin-message skpe-admin-message-error">
        {errorMessage}
      </section>
    )
  }

  if (rows.length === 0) {
    return (
      <section className="skpe-admin-state-card">
        <strong>Cronograma sem itens projetáveis</strong>
        <p>
          O Projeto está vinculado, mas ainda não há estrutura temporal
          materializada para exibição.
        </p>
      </section>
    )
  }

  return (
    <section aria-label={`Cronograma da iniciativa ${initiativeName}`}>
      <SvarJourneyGantt rows={rows} />
    </section>
  )
}