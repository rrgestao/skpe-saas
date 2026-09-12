import type {
  StrategicMapObjective,
  StrategicMapPerspective,
} from '../../contracts/strategic-map.ts'

export type StrategicCauseEffectSuggestion = {
  sourceCode: string
  targetCode: string
  rationale: string
}

export type ResolvedStrategicCauseEffectSuggestion =
  StrategicCauseEffectSuggestion & {
    sourceId: string
    targetId: string
  }

const expectedObjectiveTitles: Record<string, string> = {
  'OE-01': 'Fortalecer a governança e a disciplina de execução da estratégia',
  'OE-02': 'Desenvolver lideranças, pessoas e cultura cooperativista orientadas à estratégia',
  'OE-03': 'Padronizar processos críticos e fortalecer controles e dados gerenciais',
  'OE-04': 'Assegurar qualidade, segurança dos alimentos, conformidade e inovação responsável',
  'OE-05': 'Ampliar a participação dos cooperados e a oferta organizada da produção',
  'OE-06': 'Fortalecer o desenvolvimento produtivo, econômico e inclusivo dos cooperados',
  'OE-07': 'Diversificar clientes, canais e mercados com posicionamento de valor',
  'OE-08': 'Elevar margem, eficiência econômico-financeira e capacidade de investimento',
  'OE-09': 'Fortalecer o relacionamento e a geração de valor compartilhado com a comunidade',
  'OE-10': 'Gerar e demonstrar impacto cooperativista, social, ambiental e territorial',
}

export const strategicCauseEffectSuggestions: StrategicCauseEffectSuggestion[] = [
  {
    sourceCode: 'OE-01',
    targetCode: 'OE-03',
    rationale:
      'Disciplina de governança e execução cria condições para padronização, controles e dados confiáveis.',
  },
  {
    sourceCode: 'OE-01',
    targetCode: 'OE-04',
    rationale:
      'Governança, papéis e pontos de controle sustentam qualidade, conformidade e inovação responsável.',
  },
  {
    sourceCode: 'OE-02',
    targetCode: 'OE-05',
    rationale:
      'Lideranças e cultura orientadas à estratégia favorecem adesão, participação e oferta organizada.',
  },
  {
    sourceCode: 'OE-02',
    targetCode: 'OE-06',
    rationale:
      'Pessoas e cultura são base para desenvolvimento produtivo, econômico e inclusão dos cooperados.',
  },
  {
    sourceCode: 'OE-03',
    targetCode: 'OE-05',
    rationale:
      'Processos e dados confiáveis permitem coordenar a produção e a participação com previsibilidade.',
  },
  {
    sourceCode: 'OE-03',
    targetCode: 'OE-08',
    rationale:
      'Controles e informação gerencial sustentam eficiência econômico-financeira e decisões de investimento.',
  },
  {
    sourceCode: 'OE-04',
    targetCode: 'OE-07',
    rationale:
      'Qualidade, segurança e conformidade habilitam posicionamento de valor e acesso a mercados.',
  },
  {
    sourceCode: 'OE-05',
    targetCode: 'OE-07',
    rationale:
      'Oferta organizada e regular fortalece a capacidade de diversificar clientes, canais e mercados.',
  },
  {
    sourceCode: 'OE-06',
    targetCode: 'OE-08',
    rationale:
      'Desenvolvimento produtivo e econômico dos cooperados fortalece a eficiência e a capacidade econômica do sistema.',
  },
  {
    sourceCode: 'OE-07',
    targetCode: 'OE-08',
    rationale:
      'Diversificação e posicionamento de valor contribuem para margem, previsibilidade e capacidade de investimento.',
  },
  {
    sourceCode: 'OE-06',
    targetCode: 'OE-10',
    rationale:
      'Desenvolvimento inclusivo dos cooperados constitui uma dimensão do impacto cooperativista e territorial.',
  },
  {
    sourceCode: 'OE-08',
    targetCode: 'OE-09',
    rationale:
      'Sustentabilidade econômica amplia a capacidade de gerar valor compartilhado com a comunidade.',
  },
  {
    sourceCode: 'OE-09',
    targetCode: 'OE-10',
    rationale:
      'Relacionamento e valor compartilhado geram resultados que podem ser demonstrados como impacto.',
  },
]

function matchesExpectedObjectiveSignature(
  objectives: StrategicMapObjective[],
): boolean {
  const byCode = new Map(objectives.map((objective) => [objective.code, objective]))
  const entries = Object.entries(expectedObjectiveTitles)

  return (
    entries.length === objectives.length &&
    entries.every(
      ([code, title]) => byCode.get(code)?.title.trim() === title,
    )
  )
}

export function resolveStrategicCauseEffectSuggestions(
  objectives: StrategicMapObjective[],
  perspectives: StrategicMapPerspective[] = [],
): ResolvedStrategicCauseEffectSuggestion[] {
  if (!matchesExpectedObjectiveSignature(objectives)) return []

  const byCode = new Map(objectives.map((objective) => [objective.code, objective]))
  const perspectiveSequence = new Map(
    [...perspectives]
      .sort((left, right) => left.displayOrder - right.displayOrder)
      .map((perspective, index) => [perspective.id, index]),
  )

  return strategicCauseEffectSuggestions.flatMap((suggestion) => {
    const source = byCode.get(suggestion.sourceCode)
    const target = byCode.get(suggestion.targetCode)

    if (!source || !target) return []

    const sourcePerspectiveIndex = source.perspectiveId
      ? perspectiveSequence.get(source.perspectiveId)
      : undefined
    const targetPerspectiveIndex = target.perspectiveId
      ? perspectiveSequence.get(target.perspectiveId)
      : undefined

    // Suggested cause-effect follows the contribution ladder:
    // PE1 -> PE2 -> PE3 -> ... . Do not create cross-layer shortcuts.
    if (
      perspectives.length > 0 &&
      (sourcePerspectiveIndex == null ||
        targetPerspectiveIndex == null ||
        targetPerspectiveIndex !== sourcePerspectiveIndex + 1)
    ) {
      return []
    }

    return [
      {
        ...suggestion,
        sourceId: source.id,
        targetId: target.id,
      },
    ]
  })
}