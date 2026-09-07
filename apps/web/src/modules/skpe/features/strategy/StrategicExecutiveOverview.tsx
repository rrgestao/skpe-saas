import { useEffect, useMemo, useState } from 'react'

import { supabase } from '../../../../lib/supabase'

import './StrategicExecutiveOverview.css'

type Props = {
  organizationId: string
  projectId: string
}

type IdentityItemRow = {
  element_type: string
  content: string
  validation_status: string | null
}

type StatusRow = {
  id: string
  status?: string | null
  validation_status?: string | null
  metadata?: Record<string, unknown> | null
}

type Snapshot = {
  identityStatus: string | null
  coherenceStatement: string | null
  identityItems: IdentityItemRow[]
  themes: StatusRow[]
  perspectives: StatusRow[]
  objectives: StatusRow[]
  okrs: StatusRow[]
  keyResults: StatusRow[]
  initiatives: StatusRow[]
}

const emptySnapshot: Snapshot = {
  identityStatus: null,
  coherenceStatement: null,
  identityItems: [],
  themes: [],
  perspectives: [],
  objectives: [],
  okrs: [],
  keyResults: [],
  initiatives: [],
}

function hasPilotProvenance(row: StatusRow) {
  const metadata = row.metadata ?? {}
  return Boolean(
    metadata.pilot ||
      metadata.technical_incorporation ||
      metadata.governed_materialization ||
      metadata.institutional_validation_pending,
  )
}

function resolveStatus(rows: StatusRow[], approvedStatus = 'approved') {
  if (rows.length === 0) return 'Lacuna'

  if (
    rows.every(
      (row) =>
        row.validation_status === approvedStatus || row.status === approvedStatus,
    )
  ) {
    return 'Aprovado'
  }

  if (rows.some(hasPilotProvenance)) return 'Piloto importado'

  if (
    rows.some((row) =>
      ['draft', 'under_review', 'pending_validation'].includes(
        row.validation_status ?? row.status ?? '',
      ),
    )
  ) {
    return 'Em valida\u00e7\u00e3o'
  }

  return 'Materializado'
}

function findApprovedIdentity(items: IdentityItemRow[], type: string) {
  return (
    items.find(
      (item) => item.element_type === type && item.validation_status === 'approved',
    )?.content ?? null
  )
}

export function StrategicExecutiveOverview({ organizationId, projectId }: Props) {
  const [snapshot, setSnapshot] = useState<Snapshot>(emptySnapshot)
  const [loading, setLoading] = useState(true)
  const [errorMessage, setErrorMessage] = useState('')

  useEffect(() => {
    let active = true

    async function load() {
      setLoading(true)
      setErrorMessage('')

      const [
        identityResponse,
        identityItemsResponse,
        themesResponse,
        perspectivesResponse,
        objectivesResponse,
        okrsResponse,
        keyResultsResponse,
        initiativesResponse,
      ] = await Promise.all([
        supabase
          .from('skpe_strategic_identity')
          .select('status, coherence_statement')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId)
          .maybeSingle(),
        supabase
          .from('skpe_strategic_identity_items')
          .select('element_type, content, validation_status')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId)
          .order('display_order'),
        supabase
          .from('skpe_strategic_themes')
          .select('id, status')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId),
        supabase
          .from('skpe_bsc_perspectives')
          .select('id, status')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId),
        supabase
          .from('skpe_strategic_objectives')
          .select('id, status, validation_status')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId),
        supabase
          .from('skpe_okrs')
          .select('id, status, validation_status, metadata')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId),
        supabase
          .from('skpe_key_results')
          .select('id, status, validation_status, metadata')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId),
        supabase
          .from('sparks_initiatives')
          .select('id, status')
          .eq('organization_id', organizationId)
          .is('archived_at', null),
      ])

      if (!active) return

      const responses = [
        identityResponse,
        identityItemsResponse,
        themesResponse,
        perspectivesResponse,
        objectivesResponse,
        okrsResponse,
        keyResultsResponse,
        initiativesResponse,
      ]
      const firstError = responses.find((response) => response.error)?.error

      if (firstError) {
        setErrorMessage(
          `N\u00e3o foi poss\u00edvel consolidar a S\u00edntese Executiva: ${firstError.message}`,
        )
        setLoading(false)
        return
      }

      setSnapshot({
        identityStatus: identityResponse.data?.status ?? null,
        coherenceStatement: identityResponse.data?.coherence_statement ?? null,
        identityItems: (identityItemsResponse.data ?? []) as IdentityItemRow[],
        themes: (themesResponse.data ?? []) as StatusRow[],
        perspectives: (perspectivesResponse.data ?? []) as StatusRow[],
        objectives: (objectivesResponse.data ?? []) as StatusRow[],
        okrs: (okrsResponse.data ?? []) as StatusRow[],
        keyResults: (keyResultsResponse.data ?? []) as StatusRow[],
        initiatives: (initiativesResponse.data ?? []) as StatusRow[],
      })
      setLoading(false)
    }

    void load()

    return () => {
      active = false
    }
  }, [organizationId, projectId])

  const synthesis = useMemo(() => {
    if (loading) return 'Consolidando a identidade e as escolhas estrat\u00e9gicas validadas.'

    const purpose = findApprovedIdentity(snapshot.identityItems, 'purpose')
    const mission = findApprovedIdentity(snapshot.identityItems, 'mission')
    const vision = findApprovedIdentity(snapshot.identityItems, 'vision')

    if (snapshot.identityStatus !== 'approved' || !purpose || !mission || !vision) {
      return 'A identidade estrat\u00e9gica ainda est\u00e1 em evolu\u00e7\u00e3o. A S\u00edntese Executiva ganhar\u00e1 densidade \u00e0 medida que prop\u00f3sito, miss\u00e3o, vis\u00e3o e demais escolhas forem institucionalmente validados.'
    }

    return `A Formula\u00e7\u00e3o Estrat\u00e9gica parte de uma identidade institucional aprovada. O prop\u00f3sito estabelece: ${purpose} A miss\u00e3o traduz essa raz\u00e3o de existir em atua\u00e7\u00e3o: ${mission} A vis\u00e3o projeta a ambi\u00e7\u00e3o de futuro: ${vision} Essa identidade orienta a constru\u00e7\u00e3o de uma estrat\u00e9gia capaz de transformar coopera\u00e7\u00e3o em capacidade de execu\u00e7\u00e3o, aprendizado e gera\u00e7\u00e3o sustent\u00e1vel de valor. Temas, perspectivas, Objetivos Estrat\u00e9gicos e seus desdobramentos permanecem explicitamente diferenciados conforme seu est\u00e1gio de valida\u00e7\u00e3o, para que a leitura executiva preserve coer\u00eancia, foco e rastreabilidade sem antecipar decis\u00f5es institucionais.`
  }, [loading, snapshot])

  if (errorMessage) {
    return <section className="skpe-executive-overview-state is-error">{errorMessage}</section>
  }

  const metrics = [
    {
      label: 'Temas',
      value: snapshot.themes.length,
      status: resolveStatus(snapshot.themes),
    },
    {
      label: 'Perspectivas',
      value: snapshot.perspectives.length,
      status: resolveStatus(snapshot.perspectives),
    },
    {
      label: 'OEs',
      value: snapshot.objectives.length,
      status: resolveStatus(snapshot.objectives),
    },
    {
      label: 'OKRs',
      value: snapshot.okrs.length,
      status: resolveStatus(snapshot.okrs),
    },
    {
      label: 'KRs',
      value: snapshot.keyResults.length,
      status: resolveStatus(snapshot.keyResults),
    },
    {
      label: 'Iniciativas',
      value: snapshot.initiatives.length,
      status: resolveStatus(snapshot.initiatives),
    },
  ]

  return (
    <section className="skpe-executive-overview">
      <article className="skpe-executive-overview-hero">
        <small>{'S\u00edntese Executiva Estrat\u00e9gica'}</small>
        <h2>{'A estrat\u00e9gia em uma leitura executiva'}</h2>
        <p>{synthesis}</p>
        {snapshot.coherenceStatement ? (
          <div className="skpe-executive-overview-coherence">
              <strong>{'Leitura de coer\u00eancia'}</strong>
              <p title={snapshot.coherenceStatement}>
                {'Identidade estrat\u00e9gica aprovada e protegida como refer\u00eancia da Formula\u00e7\u00e3o.'}
              </p>
            </div>
        ) : null}
      </article>
      <section className="skpe-executive-overview-metrics" aria-label={'Resumo da Formula\u00e7\u00e3o Estrat\u00e9gica'}>
        {metrics.map((metric) => (
          <article key={metric.label}>
            <span>{metric.label}</span>
            <strong>{metric.value}</strong>
            <small>{metric.status}</small>
          </article>
        ))}
      </section>

      <p className="skpe-executive-overview-note">
        {'As quantidades representam registros materializados. Materializa\u00e7\u00e3o n\u00e3o equivale, por si s\u00f3, a aprova\u00e7\u00e3o institucional.'}
      </p>
      <section className="skpe-executive-overview-flow" aria-label={'Arquitetura estrat\u00e9gica'}>
        <article>
          <small>1</small>
          <strong>Identidade</strong>
          <span>PMVV define quem somos, por que existimos e aonde queremos chegar.</span>
        </article>
        <div aria-hidden="true">{'\u2192'}</div>
        <article>
          <small>2</small>
          <strong>Escolhas</strong>
          <span>{'Temas, perspectivas e OEs organizam as prioridades e a l\u00f3gica de valor.'}</span>
        </article>
        <div aria-hidden="true">{'\u2192'}</div>
        <article>
          <small>3</small>
          <strong>{'Execu\u00e7\u00e3o'}</strong>
          <span>{'OKRs, KRs, indicadores, metas e iniciativas transformam a estrat\u00e9gia em compromisso mensur\u00e1vel.'}</span>
        </article>
        <div aria-hidden="true">{'\u2192'}</div>
        <article>
          <small>4</small>
          <strong>Valor</strong>
          <span>{'Monitoramento, aprendizado e evolu\u00e7\u00e3o sustentam a consecu\u00e7\u00e3o da estrat\u00e9gia e o pr\u00f3ximo ciclo de valor.'}</span>
        </article>
      </section>
    </section>
  )
}