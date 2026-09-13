export type MonitoringPackageProposalItem = {
  key: string
  label: string
  value: string | number | boolean | null
  source: 'runtime_default' | 'human_decision'
  rationale: string
}

export const monitoringPackageInitialProposal: MonitoringPackageProposalItem[] = [
  { key: 'cycleFrequency', label: 'Frequência dos ciclos', value: 'monthly', source: 'runtime_default', rationale: 'Default técnico atual do FE-08; deve ser validado conforme a cadência de gestão da Organização.' },
  { key: 'reviewFrequency', label: 'Frequência das RAEs', value: 'quarterly', source: 'runtime_default', rationale: 'Default técnico atual do FE-08; a governança deve validar a cadência adequada.' },
  { key: 'cycleOverlapPolicy', label: 'Sobreposição de ciclos', value: 'block', source: 'runtime_default', rationale: 'Evita dois ciclos oficiais concorrentes no mesmo período.' },
  { key: 'evidenceRequired', label: 'Evidência obrigatória', value: true, source: 'runtime_default', rationale: 'Preserva rastreabilidade das medições e check-ins.' },
  { key: 'dataQualityRequired', label: 'Qualidade do dado obrigatória', value: true, source: 'runtime_default', rationale: 'Impede que registros não validados se tornem leitura oficial.' },
  { key: 'confidenceRequiredForKeyResults', label: 'Confiança obrigatória nos KRs', value: true, source: 'runtime_default', rationale: 'Torna explícita a confiança associada ao check-in do Resultado-Chave.' },
  { key: 'allowManualProgressOverride', label: 'Override manual de progresso', value: false, source: 'runtime_default', rationale: 'Evita substituir cálculo automático sem governança explícita.' },
  { key: 'dataFreshnessDays', label: 'Atualidade esperada dos dados', value: 45, source: 'runtime_default', rationale: 'Default técnico do runtime; requer validação conforme a natureza dos indicadores.' },
  { key: 'lateToleranceDays', label: 'Tolerância de atraso', value: 5, source: 'runtime_default', rationale: 'Default técnico do runtime; deve refletir a cadência real de gestão.' },
  { key: 'aggregationPolicy', label: 'Política de agregação', value: 'explicit_weight', source: 'runtime_default', rationale: 'Permite ponderação explícita dos KPIs; pesos ausentes permanecem sujeitos à regra governada do runtime.' },
  { key: 'criticalThreshold', label: 'Faixa crítica', value: 50, source: 'runtime_default', rationale: 'Limite técnico inicial para classificação de desempenho; exige validação humana.' },
  { key: 'attentionThreshold', label: 'Faixa de atenção', value: 75, source: 'runtime_default', rationale: 'Limite técnico inicial para classificação de desempenho; exige validação humana.' },
  { key: 'onTrackThreshold', label: 'Faixa no caminho', value: 100, source: 'runtime_default', rationale: 'Limite técnico inicial para classificação de desempenho; exige validação humana.' },
  { key: 'ownerUserId', label: 'Responsável pelo monitoramento', value: null, source: 'human_decision', rationale: 'Responsabilidade não pode ser inferida automaticamente; deve ser atribuída a usuário elegível.' },
  { key: 'governanceOwnerUserId', label: 'Responsável pela governança/RAE', value: null, source: 'human_decision', rationale: 'Responsabilidade de governança exige deliberação humana explícita.' },
]

export function monitoringPackageProposalIsMaterializable() {
  return monitoringPackageInitialProposal.every(
    (item) => item.source !== 'human_decision' || item.value !== null,
  )
}

export function monitoringPackageProposalDisplayValue(
  item: MonitoringPackageProposalItem,
) {
  if (item.value === null) return 'Definição humana necessária'
  if (typeof item.value === 'boolean') return item.value ? 'Sim' : 'Não'
  return String(item.value)
}
