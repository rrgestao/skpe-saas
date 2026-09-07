import { Fragment, useEffect, useMemo, useState } from 'react'

import { WorkspaceTabs } from '../../../../components/design-system'
import { supabase } from '../../../../lib/supabase'
import { translateBackendMessage } from '../../../../shared/i18n/ptBR'
import type { JourneyTemporalReadRow } from '../../contracts/journey'
import {
  loadDiagnosisArtifact,
  type DiagnosisArtifactKind,
  type ImportedDiagnosisRecord,
} from './strategicDiagnosisImportLoader.ts'
import { StrategicRisksSmartGrid } from './StrategicRisksSmartGrid.tsx'

import { StrategicEvidenceSection } from './StrategicEvidenceSection'

import './StrategicDiagnosisSection.css'

type DiagnosisTab = 'overview' | 'evidence' | 'pestel' | 'swot' | 'tows' | 'risks'

type Props = {
  organizationId: string
  projectId: string
}

const phaseByTab: Record<Exclude<DiagnosisTab, 'overview' | 'evidence'>, string> = {
  pestel: 'PEM-01.03',
  swot: 'PEM-01.05',
  tows: 'PEM-01.05',
  risks: 'PEM-01.06',
}

const copyByTab: Record<
  Exclude<DiagnosisTab, 'overview' | 'evidence'>,
  { title: string; purpose: string }
> = {
  pestel: {
    title: 'PESTEL',
    purpose:
      'Leitura estruturada do ambiente político, econômico, social, tecnológico, ambiental e legal.',
  },
  swot: {
    title: 'SWOT',
    purpose:
      'Síntese das forças, fraquezas, oportunidades e ameaças relevantes para a organização.',
  },
  tows: {
    title: 'TOWS',
    purpose:
      'Cruzamento orientado à decisão entre fatores internos e externos para derivar alternativas estratégicas.',
  },
  risks: {
    title: 'Riscos',
    purpose:
      'Consolidação dos riscos estratégicos identificados no diagnóstico importado.',
  },
}

const pestelReferenceRows = [
  {
    letter: 'P',
    dimension: 'Política',
    focus:
      'Políticas públicas, prioridades governamentais, estabilidade institucional e relações com o poder público.',
    examples:
      'Compras públicas, incentivos, programas governamentais e políticas setoriais.',
  },
  {
    letter: 'E',
    dimension: 'Econômica',
    focus:
      'Condições econômicas que afetam custos, demanda, margens, caixa e capacidade de investimento.',
    examples:
      'Inflação, juros, crédito, renda, custos, preços e capital de giro.',
  },
  {
    letter: 'S',
    dimension: 'Social',
    focus:
      'Mudanças sociais, demográficas, culturais e comportamentais que alteram necessidades e relações.',
    examples:
      'Hábitos de consumo, trabalho, inclusão, segurança alimentar e dinâmica populacional.',
  },
  {
    letter: 'T',
    dimension: 'Tecnológica',
    focus:
      'Tecnologias que modificam processos, produtividade, relacionamento, controle e competitividade.',
    examples:
      'Digitalização, automação, rastreabilidade, dados, integração de sistemas e IA.',
  },
  {
    letter: 'E',
    dimension: 'Ambiental',
    focus:
      'Condições ecológicas, climáticas e de sustentabilidade que afetam operação, recursos e resiliência.',
    examples:
      'Clima, água, energia, resíduos, emissões, uso de recursos e biodiversidade.',
  },
  {
    letter: 'L',
    dimension: 'Legal',
    focus:
      'Leis, normas, regulações e requisitos obrigatórios que condicionam a atuação da organização.',
    examples:
      'Legislação sanitária, trabalhista e tributária, registros, licenças e conformidade.',
  },
] as const

const swotReferenceRows = [
  {
    code: 'S',
    dimension: 'Strengths · Forças',
    origin: 'Ambiente interno',
    reading:
      'Capacidades, ativos, competências e condições internas que favorecem o desempenho e a execução da estratégia.',
  },
  {
    code: 'W',
    dimension: 'Weaknesses · Fraquezas',
    origin: 'Ambiente interno',
    reading:
      'Limitações, lacunas, fragilidades e condições internas que reduzem a capacidade de executar a estratégia.',
  },
  {
    code: 'O',
    dimension: 'Opportunities · Oportunidades',
    origin: 'Ambiente externo',
    reading:
      'Mudanças, tendências e condições externas que podem ser aproveitadas para gerar valor, crescimento ou posicionamento.',
  },
  {
    code: 'T',
    dimension: 'Threats · Ameaças',
    origin: 'Ambiente externo',
    reading:
      'Mudanças, pressões e condições externas que podem comprometer resultados, continuidade ou competitividade.',
  },
] as const

const towsReferenceRows = [
  {
    code: 'FO',
    crossing: 'Forças + Oportunidades',
    orientation: 'Alavancar',
    question:
      'Como usar forças existentes para capturar oportunidades relevantes?',
  },
  {
    code: 'WO',
    crossing: 'Fraquezas + Oportunidades',
    orientation: 'Desenvolver',
    question:
      'Que fraquezas precisam ser superadas para aproveitar oportunidades?',
  },
  {
    code: 'ST',
    crossing: 'Forças + Ameaças',
    orientation: 'Proteger',
    question:
      'Como usar forças existentes para reduzir exposição às ameaças?',
  },
  {
    code: 'WT',
    crossing: 'Fraquezas + Ameaças',
    orientation: 'Conter',
    question:
      'Que exposições críticas exigem redução, bloqueio, contingência ou gate?',
  },
] as const

const riskReferenceRows = [
  {
    element: 'Evento de risco',
    meaning: 'Situação incerta que, se ocorrer, pode afetar os objetivos estratégicos.',
    use: 'Descrever o risco de forma objetiva, sem confundir evento com causa ou consequência.',
  },
  {
    element: 'Causa',
    meaning: 'Condição, fragilidade ou fator que pode provocar o evento de risco.',
    use: 'Permite atuar preventivamente sobre a origem do risco.',
  },
  {
    element: 'Consequência',
    meaning: 'Efeito esperado caso o evento se materialize.',
    use: 'Explicita impacto sobre resultados, continuidade, reputação, conformidade ou valor.',
  },
  {
    element: 'Controles existentes',
    meaning: 'Medidas já implantadas para prevenir, detectar ou responder ao risco.',
    use: 'Diferencia proteção existente de tratamento ainda necessário.',
  },
  {
    element: 'Lacunas de controle',
    meaning: 'Proteções ausentes, insuficientes ou ainda não comprovadas.',
    use: 'Orienta priorização de tratamento sem presumir controles não evidenciados.',
  },
  {
    element: 'Probabilidade e impacto',
    meaning: 'Avaliação da chance de ocorrência e da severidade de seus efeitos.',
    use: 'Suporta classificação e priorização do risco.',
  },
  {
    element: 'Nível inerente',
    meaning: 'Exposição ao risco antes de considerar a efetividade do tratamento planejado.',
    use: 'Permite comparar criticidade inicial entre riscos.',
  },
  {
    element: 'Resposta e tratamento',
    meaning: 'Decisão e plano para evitar, reduzir, compartilhar, aceitar ou tratar o risco.',
    use: 'Transforma análise em ação governada, com responsável e prazo.',
  },
  {
    element: 'Risco residual',
    meaning: 'Exposição remanescente após controles e tratamentos considerados.',
    use: 'Apoia decisão de aceite, escalonamento ou tratamento adicional.',
  },
  {
    element: 'Indicador e evidência',
    meaning: 'Medidas e registros usados para acompanhar o risco e comprovar a execução do tratamento.',
    use: 'Fecha a rastreabilidade ISO 31000 entre risco, ação, monitoramento e evidência.',
  },
] as const

const preferredFields: Record<DiagnosisArtifactKind, string[]> = {
  pestel: [
    'codigo',
    'dimensao',
    'fator_externo',
    'natureza',
    'efeito',
    'impacto',
    'probabilidade',
    'horizonte',
    'implicacao_para_cootaquara',
    'resposta_preliminar',
    'swot_relacionada',
    'risco_relacionado',
    'fonte_evidencia',
  ],
  swot: [
    'codigo',
    'quadrante',
    'fator',
    'descricao_evidencia',
    'impacto',
    'prioridade',
    'responsavel',
    'origem_pestel',
    'evidencias_relacionadas',
    'status',
  ],
  tows: [
    'codigo',
    'tipo',
    'estrategia_formulada',
    'forcas_fraquezas',
    'oportunidades_ameacas',
    'tema_decisorio',
    'prioridade',
    'horizonte',
    'responsavel',
    'condicao_gate',
    'status',
  ],
  risks: [
    'codigo',
    'evento_de_risco',
    'categoria',
    'causa',
    'consequencia',
    'probabilidade',
    'impacto',
    'nivel_inerente',
    'controles_existentes',
    'resposta',
    'plano_de_tratamento',
    'prazo',
    'risco_residual',
    'evidencia',
    'reconhecimento_pela_direcao',
    'aceite_do_risco',
    'evidencia_do_aceite',
    'ciclo_de_implementacao',
    'destino_no_portfolio',
    'conclusao',
    'oe_relacionado',
    'status',
  ],
}

const fieldLabels: Record<string, string> = {
  codigo: 'Código',
  dimensao: 'Dimensão',
  fator_externo: 'Fator externo',
  natureza: 'Natureza',
  efeito: 'Efeito',
  impacto: 'Impacto',
  probabilidade: 'Probabilidade',
  horizonte: 'Horizonte',
  implicacao_para_cootaquara: 'Implica\u00e7\u00e3o para a COOTAQUARA',
  resposta_preliminar: 'Resposta preliminar',
  swot_relacionada: 'SWOT relacionada',
  risco_relacionado: 'Risco relacionado',
  fonte_evidencia: 'Fonte / evidência',
  quadrante: 'Quadrante',
  fator: 'Fator',
  descricao_evidencia: 'Descrição / evidência',
  prioridade: 'Prioridade',
  responsavel: 'Responsável',
  origem_pestel: 'Origem PESTEL',
  evidencias_relacionadas: 'Evidências relacionadas',
  status: 'Status',
  tipo: 'Tipo',
  estrategia_formulada: 'Estratégia formulada',
  forcas_fraquezas: 'Forças / Fraquezas',
  oportunidades_ameacas: 'Oportunidades / Ameaças',
  tema_decisorio: 'Tema decisório',
  condicao_gate: 'Condi\u00e7\u00e3o de avan\u00e7o',
  evento_de_risco: 'Evento de risco',
  nivel_inerente: 'Nível inerente',
  controles_existentes: 'Controles existentes',
  resposta: 'Resposta',
  plano_de_tratamento: 'Plano de tratamento',
  prazo: 'Prazo',
  risco_residual: 'Risco residual',
  evidencia: 'Evidência',
  reconhecimento_pela_direcao: 'Reconhecimento pela direção',
  aceite_do_risco: 'Aceite do risco',
  evidencia_do_aceite: 'Evidência do aceite',
  ciclo_de_implementacao: 'Ciclo de implementação',
  destino_no_portfolio: 'Destino no portfólio',
  conclusao: 'Conclusão (%)',
  oe_relacionado: 'OE relacionado',
  risco: 'Risco',
  descricao: 'Descrição',
  categoria: 'Categoria',
  causa: 'Causa',
  consequencia: 'Consequência',
  nivel: 'Nível',
  tratamento: 'Tratamento',
}

function statusLabel(value: string) {
  const labels: Record<string, string> = {
    not_started: 'Não iniciado',
    in_progress: 'Em execução',
    blocked: 'Bloqueado',
    pending_validation: 'Pendente de validação',
    completed: 'Concluído',
    cancelled: 'Cancelado',
  }
  return labels[value] ?? value
}

type PresentationTabStatus =
  | 'not_started'
  | 'in_progress'
  | 'completed'
  | 'blocked'

function diagnosisTabPresentationStatus(
  row:
    | {
        item_status: string
        item_progress: number | null
        validation_status: string
      }
    | null
    | undefined,
): { status: PresentationTabStatus; statusLabel: string } {
  if (!row) {
    return { status: 'not_started', statusLabel: 'Ainda não iniciado' }
  }

  if (row.item_status === 'blocked' || row.validation_status === 'rejected') {
    return { status: 'blocked', statusLabel: 'Bloqueado' }
  }

  if (
    row.item_status === 'completed' ||
    row.validation_status === 'approved' ||
    row.validation_status === 'validated'
  ) {
    return { status: 'completed', statusLabel: 'Concluído' }
  }

  if (
    Number(row.item_progress ?? 0) > 0 ||
    row.item_status === 'in_progress' ||
    row.item_status === 'pending_validation' ||
    row.validation_status === 'pending'
  ) {
    return { status: 'in_progress', statusLabel: 'Em andamento' }
  }

  return { status: 'not_started', statusLabel: 'Ainda não iniciado' }
}

function validationLabel(value: string) {
  const labels: Record<string, string> = {
    approved: 'Aprovado',
    validated: 'Validado',
    not_required: 'Não exigida nesta fase',
    pending: 'Pendente',
    rejected: 'Rejeitado',
  }
  return labels[value] ?? value
}

function displayValue(value: unknown): string {
  if (value === null || value === undefined || value === '') return '—'
  if (typeof value === 'string' || typeof value === 'number') {
    return String(value)
  }
  if (typeof value === 'boolean') return value ? 'Sim' : 'Não'
  return JSON.stringify(value)
}


function normalizeDiagnosisToken(value: unknown): string {
  return String(value ?? '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .trim()
    .toLowerCase()
}

function ArtifactRecordCards({
  kind,
  records,
}: {
  kind: DiagnosisArtifactKind
  records: ImportedDiagnosisRecord[]
}) {
  return (
    <div className="skpe-strategic-diagnosis-records">
      {records.map((record) => {
        const preferred = preferredFields[kind]
        const existingPreferred = preferred.filter((field) => field in record.values)
        const remaining = Object.keys(record.values).filter(
          (field) => !existingPreferred.includes(field),
        )
        const fields = [...existingPreferred, ...remaining]

        return (
          <article key={record.externalKey}>
            <header>
              <div>
                <small>{displayValue(record.values.codigo) || record.externalKey}</small>
                <strong>
                  {displayValue(
                    record.values.fator_externo ??
                      record.values.fator ??
                      record.values.estrategia_formulada ??
                      record.values.evento_de_risco ??
                      record.values.risco ??
                      record.values.descricao,
                  )}
                </strong>
              </div>
              <span>{record.sourceSheet} · linha {record.sourceRow ?? '—'}</span>
            </header>

            <dl>
              {fields.map((field) => (
                <div key={field}>
                  <dt>{fieldLabels[field] ?? field}</dt>
                  <dd>{displayValue(record.values[field])}</dd>
                </div>
              ))}
            </dl>

            <footer>
              <span>Reconciliação: {record.simulationStatus ?? 'não informada'}</span>
            </footer>
          </article>
        )
      })}
    </div>
  )
}

function SwotMatrix({ records }: { records: ImportedDiagnosisRecord[] }) {
  const quadrants = [
    {
      code: 'S',
      title: 'Forças',
      aliases: ['forca', 'strength'],
      toneClass: 'skpe-strategic-diagnosis-matrix-cell-swot-s',
      alignClass: 'skpe-strategic-diagnosis-matrix-cell-align-end',
    },
    {
      code: 'W',
      title: 'Fraquezas',
      aliases: ['fraqueza', 'weakness'],
      toneClass: 'skpe-strategic-diagnosis-matrix-cell-swot-w',
      alignClass: 'skpe-strategic-diagnosis-matrix-cell-align-start',
    },
    {
      code: 'O',
      title: 'Oportunidades',
      aliases: ['oportunidade', 'opportunity'],
      toneClass: 'skpe-strategic-diagnosis-matrix-cell-swot-o',
      alignClass: 'skpe-strategic-diagnosis-matrix-cell-align-end',
    },
    {
      code: 'T',
      title: 'Ameaças',
      aliases: ['ameaca', 'threat'],
      toneClass: 'skpe-strategic-diagnosis-matrix-cell-swot-t',
      alignClass: 'skpe-strategic-diagnosis-matrix-cell-align-start',
    },
  ] as const

  return (
    <section className="skpe-strategic-diagnosis-matrix" aria-label="Matriz SWOT">
      {quadrants.map((quadrant) => {
        const items = records.filter((record) =>
          quadrant.aliases.includes(
            normalizeDiagnosisToken(record.values.quadrante) as never,
          ),
        )

        return (
          <article
            key={quadrant.code}
            className={`skpe-strategic-diagnosis-matrix-cell ${quadrant.toneClass} ${quadrant.alignClass}`}
          >
            <header>
              {quadrant.alignClass === 'skpe-strategic-diagnosis-matrix-cell-align-end' ? (
                <>
                  <div>
                    <strong>{quadrant.title}</strong>
                    <small>{items.length} fator(es)</small>
                  </div>
                  <span className="skpe-strategic-diagnosis-method-letter">{quadrant.code}</span>
                </>
              ) : (
                <>
                  <span className="skpe-strategic-diagnosis-method-letter">{quadrant.code}</span>
                  <div>
                    <strong>{quadrant.title}</strong>
                    <small>{items.length} fator(es)</small>
                  </div>
                </>
              )}
            </header>

            <div className="skpe-strategic-diagnosis-matrix-items">
              {items.map((record) => (
                <article key={record.externalKey}>
                  <small>{displayValue(record.values.codigo)}</small>
                  <strong>{displayValue(record.values.fator)}</strong>
                  <p>{displayValue(record.values.descricao_evidencia)}</p>
                  <footer>
                    <span>Impacto: {displayValue(record.values.impacto)}</span>
                    <span>Prioridade: {displayValue(record.values.prioridade)}</span>
                  </footer>
                </article>
              ))}
            </div>
          </article>
        )
      })}
    </section>
  )
}

function TowsMatrix({ records }: { records: ImportedDiagnosisRecord[] }) {
  const quadrants = [
    {
      code: 'FO',
      title: 'Forças + Oportunidades',
      toneClass: 'skpe-strategic-diagnosis-matrix-cell-tows-fo',
      alignClass: 'skpe-strategic-diagnosis-matrix-cell-align-end',
    },
    {
      code: 'WO',
      title: 'Fraquezas + Oportunidades',
      toneClass: 'skpe-strategic-diagnosis-matrix-cell-tows-wo',
      alignClass: 'skpe-strategic-diagnosis-matrix-cell-align-start',
    },
    {
      code: 'ST',
      title: 'Forças + Ameaças',
      toneClass: 'skpe-strategic-diagnosis-matrix-cell-tows-st',
      alignClass: 'skpe-strategic-diagnosis-matrix-cell-align-end',
    },
    {
      code: 'WT',
      title: 'Fraquezas + Ameaças',
      toneClass: 'skpe-strategic-diagnosis-matrix-cell-tows-wt',
      alignClass: 'skpe-strategic-diagnosis-matrix-cell-align-start',
    },
  ] as const

  return (
    <section className="skpe-strategic-diagnosis-matrix" aria-label="Matriz TOWS">
      {quadrants.map((quadrant) => {
        const items = records.filter(
          (record) =>
            String(record.values.tipo ?? '').trim().toUpperCase() === quadrant.code,
        )

        return (
          <article
            key={quadrant.code}
            className={`skpe-strategic-diagnosis-matrix-cell ${quadrant.toneClass} ${quadrant.alignClass}`}
          >
            <header>
              {quadrant.alignClass === 'skpe-strategic-diagnosis-matrix-cell-align-end' ? (
                <>
                  <div>
                    <strong>{quadrant.title}</strong>
                    <small>{items.length} estratégia(s)</small>
                  </div>
                  <span className="skpe-strategic-diagnosis-method-letter skpe-strategic-diagnosis-method-letter-wide">
                    {quadrant.code}
                  </span>
                </>
              ) : (
                <>
                  <span className="skpe-strategic-diagnosis-method-letter skpe-strategic-diagnosis-method-letter-wide">
                    {quadrant.code}
                  </span>
                  <div>
                    <strong>{quadrant.title}</strong>
                    <small>{items.length} estratégia(s)</small>
                  </div>
                </>
              )}
            </header>

            <div className="skpe-strategic-diagnosis-matrix-items">
              {items.map((record) => (
                <article key={record.externalKey}>
                  <small>{displayValue(record.values.codigo)}</small>
                  <strong>{displayValue(record.values.estrategia_formulada)}</strong>
                  <p>
                    {displayValue(record.values.forcas_fraquezas)} ×{' '}
                    {displayValue(record.values.oportunidades_ameacas)}
                  </p>
                  <footer>
                    <span>Prioridade: {displayValue(record.values.prioridade)}</span>
                    <span>Horizonte: {displayValue(record.values.horizonte)}</span>
                  </footer>
                </article>
              ))}
            </div>
          </article>
        )
      })}
    </section>
  )
}


function StrategicRiskMatrix({ records }: { records: ImportedDiagnosisRecord[] }) {
  type RiskCardFilter =
    | 'all'
    | 'inProgress'
    | 'maxInherent'
    | 'maxResidual'
    | 'blocked'

  const [activeCard, setActiveCard] = useState<RiskCardFilter>('all')

  const normalizeRiskLabel = (value: unknown) => normalizeDiagnosisToken(value)

  const numeric = (value: unknown): number | null => {
    const parsed = Number(String(value ?? '').replace(',', '.'))
    return Number.isFinite(parsed) ? parsed : null
  }

  const displayRiskCode = (record: ImportedDiagnosisRecord, index: number): string => {
    const values = record.values as Record<string, unknown>
    const raw = values.codigo ?? values.code ?? values.risk_id ?? record.id
    const text = String(raw ?? '').trim()
    return text || `R${String(index + 1).padStart(2, '0')}`
  }

  const ordinalRiskValue = (
    value: unknown,
    axis: 'probability' | 'impact',
  ): number | null => {
    const token = normalizeRiskLabel(value)

    if (axis === 'probability') {
      const map: Record<string, number> = {
        'muito baixa': 1,
        baixa: 2,
        media: 3,
        alta: 4,
        'muito alta': 5,
      }
      return map[token] ?? null
    }

    const map: Record<string, number> = {
      'muito baixo': 1,
      baixo: 2,
      medio: 3,
      alto: 4,
      'muito alto': 5,
    }
    return map[token] ?? null
  }

  const getTargetOrdinal = (
    record: ImportedDiagnosisRecord,
    axis: 'probability' | 'impact',
  ): number | null => {
    const values = record.values as Record<string, unknown>
    const keys =
      axis === 'probability'
        ? ['probabilidade_residual', 'probabilidade_mitigada', 'probabilidade_alvo']
        : ['impacto_residual', 'impacto_mitigado', 'impacto_alvo']

    for (const key of keys) {
      const candidate = ordinalRiskValue(values[key], axis)
      if (candidate !== null) return candidate
    }

    return null
  }

  const inherentScores = records
    .map((record) => numeric(record.values.nivel_inerente))
    .filter((value): value is number => value !== null)

  const residualScores = records
    .map((record) => numeric(record.values.risco_residual))
    .filter((value): value is number => value !== null)

  const maxInherent =
    inherentScores.length > 0 ? Math.max(...inherentScores) : null
  const maxResidual =
    residualScores.length > 0 ? Math.max(...residualScores) : null

  const inProgress = records.filter(
    (record) =>
      normalizeDiagnosisToken(record.values.status) === 'em andamento',
  ).length

  const blocked = records.filter(
    (record) =>
      normalizeDiagnosisToken(record.values.status) === 'bloqueado por gate',
  ).length

  const filteredRecords = records.filter((record) => {
    if (activeCard === 'all') return true

    if (activeCard === 'inProgress') {
      return normalizeDiagnosisToken(record.values.status) === 'em andamento'
    }

    if (activeCard === 'blocked') {
      return (
        normalizeDiagnosisToken(record.values.status) === 'bloqueado por gate'
      )
    }

    if (activeCard === 'maxInherent') {
      return numeric(record.values.nivel_inerente) === maxInherent
    }

    return numeric(record.values.risco_residual) === maxResidual
  })

  const cards: Array<{
    id: RiskCardFilter
    label: string
    value: number | string
  }> = [
    { id: 'all', label: 'Riscos mapeados', value: records.length },
    { id: 'inProgress', label: 'Em andamento', value: inProgress },
    {
      id: 'maxInherent',
      label: 'Maior nível inerente',
      value: maxInherent ?? '—',
    },
    {
      id: 'maxResidual',
      label: 'Maior risco residual',
      value: maxResidual ?? '—',
    },
    { id: 'blocked', label: 'Bloqueados por gate', value: blocked },
  ]

  const probabilityAxis = [
    { value: 5, label: 'Muito alta' },
    { value: 4, label: 'Alta' },
    { value: 3, label: 'Média' },
    { value: 2, label: 'Baixa' },
    { value: 1, label: 'Muito baixa' },
  ]

  const impactAxis = [
    { value: 1, label: 'Muito baixo' },
    { value: 2, label: 'Baixo' },
    { value: 3, label: 'Médio' },
    { value: 4, label: 'Alto' },
    { value: 5, label: 'Muito alto' },
  ]

  function heatBand(score: number): number {
    if (score <= 4) return 1
    if (score <= 9) return 2
    if (score <= 14) return 3
    if (score <= 19) return 4
    return 5
  }

  const residualBandSummary = [1, 2, 3, 4, 5].map((band) => ({
    band,
    count: records.filter((record) => {
      const score = numeric(record.values.risco_residual)
      return score !== null && heatBand(score) === band
    }).length,
  }))

  const residualTargetAvailable = records.some(
    (record) =>
      getTargetOrdinal(record, 'probability') !== null &&
      getTargetOrdinal(record, 'impact') !== null,
  )

  function recordsForCell(
    sourceRecords: ImportedDiagnosisRecord[],
    probability: number,
    impact: number,
    mode: 'current' | 'mitigated',
  ) {
    return sourceRecords.filter((record) => {
      const probabilityValue =
        mode === 'current'
          ? ordinalRiskValue(record.values.probabilidade, 'probability')
          : getTargetOrdinal(record, 'probability')

      const impactValue =
        mode === 'current'
          ? ordinalRiskValue(record.values.impacto, 'impact')
          : getTargetOrdinal(record, 'impact')

      return probabilityValue === probability && impactValue === impact
    })
  }

  function HeatmapPanel({
    code,
    title,
    helper,
    ariaLabel,
    mode,
  }: {
    code: string
    title: string
    helper: string
    ariaLabel: string
    mode: 'current' | 'mitigated'
  }) {
    return (
      <div className="skpe-strategic-diagnosis-risk-heatmap-block">
        <div className="skpe-strategic-diagnosis-risk-focus-heading">
          <div>
            <p className="skpe-card-code">{code}</p>
            <h4>{title}</h4>
          </div>
          <span>{helper}</span>
        </div>

        <div
          className="skpe-strategic-diagnosis-risk-heatmap"
          role="table"
          aria-label={ariaLabel}
        >
          <div className="skpe-risk-heatmap-corner" aria-hidden="true">
            P × I
          </div>
          {impactAxis.map((impact) => (
            <div
              key={`impact-${mode}-${impact.value}`}
              className="skpe-risk-heatmap-axis skpe-risk-heatmap-axis-impact"
              role="columnheader"
            >
              <strong>{impact.value}</strong>
              <span>{impact.label}</span>
            </div>
          ))}

          {probabilityAxis.map((probability) => (
            <Fragment key={`prob-${mode}-${probability.value}`}>
              <div
                className="skpe-risk-heatmap-axis skpe-risk-heatmap-axis-probability"
                role="rowheader"
              >
                <strong>{probability.value}</strong>
                <span>{probability.label}</span>
              </div>

              {impactAxis.map((impact) => {
                const score = probability.value * impact.value
                const cellRecords = recordsForCell(
                  records,
                  probability.value,
                  impact.value,
                  mode,
                )

                return (
                  <div
                    key={`${mode}-${probability.value}-${impact.value}`}
                    className={`skpe-risk-heatmap-cell skpe-risk-heatmap-band-${heatBand(score)}`}
                    role="cell"
                    title={`${probability.label} × ${impact.label}`}
                  >
                    {cellRecords.length > 0 ? (
                      <div className="skpe-risk-heatmap-id-list">
                        {cellRecords.map((record, index) => (
                          <span
                            key={`${record.id}-${displayRiskCode(record, index)}`}
                            className="skpe-risk-heatmap-id-chip"
                          >
                            {displayRiskCode(record, index)}
                          </span>
                        ))}
                      </div>
                    ) : (
                      <span className="skpe-risk-heatmap-empty">—</span>
                    )}
                  </div>
                )
              })}
            </Fragment>
          ))}
        </div>
      </div>
    )
  }

  return (
    <section
      className="skpe-strategic-diagnosis-risk-dashboard"
      aria-label="Matrizes de riscos estratégicos"
    >
      <div className="skpe-strategic-diagnosis-risk-heatmaps">
        <HeatmapPanel
          code="MATRIZ DE RISCOS ESTRATÉGICOS"
          title="Riscos priorizados e governados"
          helper="IDs dos riscos posicionados na escala 5 × 5"
          ariaLabel="Matriz 5 por 5 de probabilidade e impacto"
          mode="current"
        />

        {residualTargetAvailable ? (
          <HeatmapPanel
            code="MATRIZ DE RISCOS MITIGADOS"
            title="Destino esperado após mitigação"
            helper="Posicionamento alvo com base nos campos residuais canônicos"
            ariaLabel="Matriz 5 por 5 de riscos mitigados"
            mode="mitigated"
          />
        ) : (
          <div className="skpe-strategic-diagnosis-risk-heatmap-block skpe-strategic-diagnosis-risk-heatmap-block--placeholder">
            <div className="skpe-strategic-diagnosis-risk-focus-heading">
              <div>
                <p className="skpe-card-code">MATRIZ DE RISCOS MITIGADOS</p>
                <h4>Destino esperado após mitigação</h4>
              </div>
              <span>Concepção SPARKs preservada sem heurística indevida</span>
            </div>

            <div className="skpe-strategic-diagnosis-risk-placeholder">
              <p>
                Cada risco aprovado deve originar no mínimo 1 ação de mitigação e,
                quando fizer sentido, 1 iniciativa estratégica vinculada ao Plano de
                Iniciativas do PE.
              </p>
              <ul>
                <li>
                  {records.length} risco(s) aprovados ⇒ mínimo de {records.length}{' '}
                  iniciativa(s) propostas com fonte em mitigação de risco.
                </li>
                <li>
                  O termo de abertura de cada iniciativa deve conter no mínimo 5W2H.
                </li>
                <li>
                  Para materializar a matriz mitigada 5 × 5 sem inferência, o modelo
                  deve registrar probabilidade residual e impacto residual por risco.
                </li>
              </ul>

              <div className="skpe-strategic-diagnosis-risk-residual-summary">
                {residualBandSummary.map((item) => (
                  <div
                    key={`residual-band-${item.band}`}
                    className={`skpe-strategic-diagnosis-risk-residual-pill skpe-risk-heatmap-band-${item.band}`}
                  >
                    <strong>Faixa {item.band}</strong>
                    <span>{item.count} risco(s)</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}
      </div>

      <div
        className="skpe-strategic-diagnosis-risk-summary"
        aria-label="Filtros rápidos da matriz de riscos"
      >
        {cards.map((card) => (
          <button
            key={card.id}
            type="button"
            className={[
              'sparks-metric-card',
              'sparks-metric-card--interactive',
              activeCard === card.id ? 'sparks-metric-card--active' : '',
            ]
              .filter(Boolean)
              .join(' ')}
            aria-pressed={activeCard === card.id}
            onClick={() => setActiveCard(card.id)}
          >
            <span className="sparks-metric-card__label">{card.label}</span>
            <strong className="sparks-metric-card__value">{card.value}</strong>
          </button>
        ))}
      </div>

      <div className="skpe-strategic-diagnosis-risk-focus">
        <div className="skpe-strategic-diagnosis-risk-focus-heading">
          <div>
            <p className="skpe-card-code">GRID DE RISCOS</p>
            <h4>Riscos priorizados e governados</h4>
          </div>
          <span>
            {filteredRecords.length} de {records.length} risco(s)
          </span>
        </div>

        <StrategicRisksSmartGrid records={filteredRecords} />
      </div>

      <p className="skpe-strategic-diagnosis-risk-scale-note">
        As cores apoiam a leitura visual da escala numérica governada. A matriz atual
        posiciona os riscos pelos seus IDs, enquanto a matriz mitigada depende dos
        campos residuais canônicos para posicionamento 5 × 5 sem perda semântica.
      </p>
    </section>
  )
}
function ArtifactRecords({
  kind,
  records,
}: {
  kind: DiagnosisArtifactKind
  records: ImportedDiagnosisRecord[]
}) {
  if (records.length === 0) {
    return (
      <div className="skpe-strategic-diagnosis-empty">
        Nenhum registro válido foi localizado para este instrumento.
      </div>
    )
  }

  return (
    <>
      {kind === 'swot' ? <SwotMatrix records={records} /> : null}
      {kind === 'tows' ? <TowsMatrix records={records} /> : null}
      {kind === 'risks' ? <StrategicRiskMatrix records={records} /> : null}

      {kind === 'swot' ? (
            <section
              className="skpe-strategic-diagnosis-method-reference"
              aria-labelledby="skpe-swot-reference-title"
            >
              <div className="skpe-strategic-diagnosis-method-reference-heading">
                <div>
                  <p className="skpe-card-code">REFERÊNCIA METODOLÓGICA</p>
                  <h4 id="skpe-swot-reference-title">Como ler a matriz SWOT</h4>
                </div>
                <p>
                  A SWOT organiza fatores internos e externos em quatro dimensões complementares.
                  O objetivo não é produzir uma lista isolada, mas sintetizar evidências que serão
                  cruzadas na TOWS e convertidas em escolhas estratégicas.
                </p>
              </div>

              <div className="skpe-strategic-diagnosis-method-table-wrap">
                <table className="skpe-strategic-diagnosis-method-table">
                  <thead>
                    <tr>
                      <th scope="col">Sigla</th>
                      <th scope="col">Dimensão</th>
                      <th scope="col">Origem</th>
                      <th scope="col">Leitura estratégica</th>
                    </tr>
                  </thead>
                  <tbody>
                    {swotReferenceRows.map((row) => (
                      <tr key={row.code}>
                        <td>
                          <span
                            className="skpe-strategic-diagnosis-method-letter"
                            aria-label={`${row.code} · ${row.dimension}`}
                          >
                            {row.code}
                          </span>
                        </td>
                        <td><strong>{row.dimension}</strong></td>
                        <td>{row.origin}</td>
                        <td>{row.reading}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </section>
          ) : null}

{kind === 'tows' ? (
            <section
              className="skpe-strategic-diagnosis-method-reference"
              aria-labelledby="skpe-tows-reference-title"
            >
              <div className="skpe-strategic-diagnosis-method-reference-heading">
                <div>
                  <p className="skpe-card-code">REFERÊNCIA METODOLÓGICA</p>
                  <h4 id="skpe-tows-reference-title">Como ler os cruzamentos TOWS</h4>
                </div>
                <p>
                  A TOWS deriva diretamente da SWOT e transforma fatores internos e externos em
                  alternativas de decisão. As siglas abaixo preservam a codificação utilizada no
                  artefato histórico importado.
                </p>
              </div>

              <div className="skpe-strategic-diagnosis-method-table-wrap">
                <table className="skpe-strategic-diagnosis-method-table">
                  <thead>
                    <tr>
                      <th scope="col">Sigla</th>
                      <th scope="col">Cruzamento</th>
                      <th scope="col">Orientação</th>
                      <th scope="col">Pergunta de decisão</th>
                    </tr>
                  </thead>
                  <tbody>
                    {towsReferenceRows.map((row) => (
                      <tr key={row.code}>
                        <td>
                          <span
                            className="skpe-strategic-diagnosis-method-letter skpe-strategic-diagnosis-method-letter-wide"
                            aria-label={`${row.code} · ${row.crossing}`}
                          >
                            {row.code}
                          </span>
                        </td>
                        <td><strong>{row.crossing}</strong></td>
                        <td>{row.orientation}</td>
                        <td>{row.question}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </section>
          ) : null}

{kind === 'risks' ? (
            <section
              className="skpe-strategic-diagnosis-method-reference"
              aria-labelledby="skpe-risk-reference-title"
            >
              <div className="skpe-strategic-diagnosis-method-reference-heading">
                <div>
                  <p className="skpe-card-code">REFERÊNCIA METODOLÓGICA</p>
                  <h4 id="skpe-risk-reference-title">Como ler a matriz de riscos estratégicos</h4>
                </div>
                <p>
                  A leitura segue a lógica da ISO 31000 e conecta evento, causa, consequência,
                  controles, lacunas, tratamento, monitoramento e evidências. Riscos estratégicos
                  do diagnóstico permanecem distintos dos riscos de execução das iniciativas.
                </p>
              </div>

              <div className="skpe-strategic-diagnosis-method-table-wrap">
                <table className="skpe-strategic-diagnosis-method-table skpe-strategic-diagnosis-risk-reference-table">
                  <thead>
                    <tr>
                      <th scope="col">Elemento</th>
                      <th scope="col">O que representa</th>
                      <th scope="col">Como usar</th>
                    </tr>
                  </thead>
                  <tbody>
                    {riskReferenceRows.map((row) => (
                      <tr key={row.element}>
                        <td><strong>{row.element}</strong></td>
                        <td>{row.meaning}</td>
                        <td>{row.use}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </section>
          ) : null}

      {kind !== 'risks' ? (
        <>
          <div className="skpe-strategic-diagnosis-detail-heading">
            <div>
              <p className="skpe-card-code">DETALHAMENTO</p>
              <h4>Registros do instrumento</h4>
            </div>
            <span>{records.length} registro(s)</span>
          </div>

          <ArtifactRecordCards kind={kind} records={records} />
        </>
      ) : null}
    </>
  )
}

export function StrategicDiagnosisSection({
  organizationId,
  projectId,
}: Props) {
  const [activeTab, setActiveTab] = useState<DiagnosisTab>('overview')
  const [rows, setRows] = useState<JourneyTemporalReadRow[]>([])
  const [artifactRecords, setArtifactRecords] = useState<
    Partial<Record<DiagnosisArtifactKind, ImportedDiagnosisRecord[]>>
  >({})
  const [loading, setLoading] = useState(true)
  const [artifactLoading, setArtifactLoading] = useState(false)
  const [errorMessage, setErrorMessage] = useState('')
  const [artifactError, setArtifactError] = useState('')

  useEffect(() => {
    let active = true

    async function loadDiagnosis() {
      setLoading(true)
      setErrorMessage('')

      const { data, error } = await supabase.rpc(
        'get_skpe_journey_temporal_read_model',
        {
          target_organization_id: organizationId,
          target_project_id: projectId,
          target_as_of_date: null,
        },
      )

      if (!active) return

      if (error) {
        setRows([])
        setErrorMessage(
          `Não foi possível carregar o Diagnóstico Estratégico: ${translateBackendMessage(error.message)}`,
        )
      } else {
        setRows((data ?? []) as JourneyTemporalReadRow[])
      }

      setLoading(false)
    }

    void loadDiagnosis()

    return () => {
      active = false
    }
  }, [organizationId, projectId])

  useEffect(() => {
    let active = true

    if (activeTab === 'overview' || activeTab === 'evidence') {
      setArtifactError('')
      return () => {
        active = false
      }
    }

    const kind = activeTab as DiagnosisArtifactKind

    if (artifactRecords[kind]) {
      return () => {
        active = false
      }
    }

    async function loadArtifact() {
      setArtifactLoading(true)
      setArtifactError('')

      try {
        const records = await loadDiagnosisArtifact(
          organizationId,
          projectId,
          kind,
        )
        if (!active) return
        setArtifactRecords((current) => ({ ...current, [kind]: records }))
      } catch (error) {
        if (!active) return
        setArtifactError(
          error instanceof Error
            ? error.message
            : 'Não foi possível carregar o instrumento importado.',
        )
      } finally {
        if (active) setArtifactLoading(false)
      }
    }

    void loadArtifact()

    return () => {
      active = false
    }
  }, [activeTab, artifactRecords, organizationId, projectId])

  const diagnosisMacrophase = useMemo(
    () => rows.find((row) => row.item_code === 'PEM-01') ?? null,
    [rows],
  )

  const selectedPhase =
    activeTab === 'overview' || activeTab === 'evidence'
      ? null
      : rows.find((row) => row.item_code === phaseByTab[activeTab]) ?? null

  const selectedKind =
    activeTab === 'overview' || activeTab === 'evidence'
      ? null
      : (activeTab as DiagnosisArtifactKind)

  return (
    <section className="skpe-strategic-diagnosis">
      <header className="skpe-strategic-diagnosis-header">
        <div>
          <p className="skpe-eyebrow">Diagnóstico Estratégico</p>
          <h2>Leitura integrada do contexto estratégico</h2>
          <p>
            PESTEL, SWOT, TOWS e Riscos preservam o conteúdo importado da
            planilha e a rastreabilidade com a Jornada.
          </p>
        </div>

        {diagnosisMacrophase ? (
          <span className="skpe-status-chip">
            {validationLabel(diagnosisMacrophase.validation_status)}
          </span>
        ) : null}
      </header>

      <WorkspaceTabs
        ariaLabel={'Perspectivas do Diagn\u00f3stico Estrat\u00e9gico'}
        activeId={activeTab}
        onChange={(id) => setActiveTab(id as DiagnosisTab)}
        tabs={[
          {
            id: 'overview',
            label: 'Visão Geral',
            ...diagnosisTabPresentationStatus(diagnosisMacrophase),
          },
          {
            id: 'evidence',
            label: 'Evid\u00eancias',
          },
          {
            id: 'pestel',
            label: 'PESTEL',
            ...diagnosisTabPresentationStatus(
              rows.find((row) => row.item_code === phaseByTab.pestel),
            ),
          },
          {
            id: 'swot',
            label: 'SWOT',
            ...diagnosisTabPresentationStatus(
              rows.find((row) => row.item_code === phaseByTab.swot),
            ),
          },
          {
            id: 'tows',
            label: 'TOWS',
            ...diagnosisTabPresentationStatus(
              rows.find((row) => row.item_code === phaseByTab.tows),
            ),
          },
          {
            id: 'risks',
            label: 'Riscos',
            ...diagnosisTabPresentationStatus(
              rows.find((row) => row.item_code === phaseByTab.risks),
            ),
          },
        ]}
      />

      {errorMessage ? (
        <div className="skpe-admin-message skpe-admin-message-error">
          {errorMessage}
        </div>
      ) : loading ? (
        <section className="skpe-admin-state-card">
          <p>Carregando diagnóstico...</p>
        </section>
      ) : activeTab === 'overview' ? (
        <section className="skpe-strategic-diagnosis-overview">
          <article>
            <small>Megafase</small>
            <strong>
              {diagnosisMacrophase?.item_name ??
                'Diagnóstico e Entendimento Estratégico'}
            </strong>
          </article>
          <article>
            <small>Situação</small>
            <strong>
              {diagnosisMacrophase
                ? statusLabel(diagnosisMacrophase.item_status)
                : 'Não localizada'}
            </strong>
          </article>
          <article>
            <small>Progresso</small>
            <strong>{diagnosisMacrophase?.item_progress ?? 0}%</strong>
          </article>
          <article>
            <small>Validação</small>
            <strong>
              {diagnosisMacrophase
                ? validationLabel(diagnosisMacrophase.validation_status)
                : 'Não localizada'}
            </strong>
          </article>
          <div className="skpe-strategic-diagnosis-interpretation">
            <p className="skpe-card-code">{'S\u00cdNTESE EXECUTIVA DO DIAGN\u00d3STICO'}</p>
            <h3>{'Leitura integrada da realidade estrat\u00e9gica'}</h3>
            <p>
              {'O diagn\u00f3stico re\u00fane PESTEL, SWOT, TOWS e Riscos como instrumentos complementares para compreender o contexto, explicitar tens\u00f5es, preservar as evid\u00eancias j\u00e1 incorporadas e orientar as escolhas da Formula\u00e7\u00e3o Estrat\u00e9gica sem criar uma leitura paralela dos dados.'}
            </p>
            <p className="skpe-strategic-diagnosis-interpretation-note">
              {'Os instrumentos permanecem vinculados ao hist\u00f3rico governado de importa\u00e7\u00e3o e \u00e0s respectivas evid\u00eancias, hip\u00f3teses e valida\u00e7\u00f5es.'}
            </p>
          </div>
</section>
      ) : activeTab === 'evidence' ? (
        <StrategicEvidenceSection organizationId={organizationId} />
      ) : (
        <section className="skpe-strategic-diagnosis-artifact">
          <header>
            <div>
              <p className="skpe-card-code">{selectedPhase?.item_code}</p>
              <h3>{copyByTab[activeTab].title}</h3>
              <p>{copyByTab[activeTab].purpose}</p>
            </div>
            {selectedPhase ? (
              <span className="skpe-status-chip">
                {statusLabel(selectedPhase.item_status)}
              </span>
            ) : null}
          </header>

          {activeTab === 'pestel' ? (
            <section
              className="skpe-strategic-diagnosis-method-reference"
              aria-labelledby="skpe-pestel-reference-title"
            >
              <div className="skpe-strategic-diagnosis-method-reference-heading">
                <div>
                  <p className="skpe-card-code">REFERÊNCIA METODOLÓGICA</p>
                  <h4 id="skpe-pestel-reference-title">Como ler o acrônimo PESTEL</h4>
                </div>
                <p>
                  O PESTEL estrutura a leitura do ambiente externo em seis dimensões. Esses
                  fatores não estão sob controle direto da organização, mas podem gerar
                  oportunidades, ameaças, riscos e necessidades de adaptação estratégica.
                </p>
              </div>

              <div className="skpe-strategic-diagnosis-method-table-wrap">
                <table className="skpe-strategic-diagnosis-method-table">
                  <thead>
                    <tr>
                      <th scope="col">Sigla</th>
                      <th scope="col">Dimensão</th>
                      <th scope="col">O que analisa</th>
                      <th scope="col">Exemplos de temas</th>
                    </tr>
                  </thead>
                  <tbody>
                    {pestelReferenceRows.map((row, index) => (
                      <tr key={`${row.letter}-${row.dimension}`}>
                        <td>
                          <span
                            className="skpe-strategic-diagnosis-method-letter"
                            aria-label={`${row.letter} de ${row.dimension}`}
                          >
                            {row.letter}
                          </span>
                        </td>
                        <td>
                          <strong>{row.dimension}</strong>
                          {index === 4 ? (
                            <small>Segunda sigla E do acrônimo</small>
                          ) : null}
                        </td>
                        <td>{row.focus}</td>
                        <td>{row.examples}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </section>
          ) : null}







          <div className="skpe-strategic-diagnosis-meta">
            <article>
              <small>Fase canônica</small>
              <strong>{selectedPhase?.item_name ?? 'Não materializada'}</strong>
            </article>
            <article>
              <small>Progresso</small>
              <strong>{selectedPhase?.item_progress ?? 0}%</strong>
            </article>
            <article>
              <small>Validação da fase</small>
              <strong>
                {selectedPhase
                  ? validationLabel(selectedPhase.validation_status)
                  : 'Não localizada'}
              </strong>
            </article>
          </div>

          {artifactError ? (
            <div className="skpe-admin-message skpe-admin-message-error">
              {artifactError}
            </div>
          ) : artifactLoading ? (
            <div className="skpe-strategic-diagnosis-empty">
              Carregando instrumento importado...
            </div>
          ) : selectedKind ? (
            <ArtifactRecords
              kind={selectedKind}
              records={artifactRecords[selectedKind] ?? []}
            />
          ) : null}
        </section>
      )}
    </section>
  )
}
