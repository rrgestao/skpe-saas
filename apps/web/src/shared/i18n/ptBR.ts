const STATUS_LABELS_PT_BR: Record<string, string> = {
  draft: 'Rascunho',
  planned: 'Planejado',
  proposed: 'Proposto',
  active: 'Ativo',
  inactive: 'Inativo',
  invited: 'Convidado',
  preparing: 'Em preparação',
  validating: 'Em validação',
  ready: 'Pronto',
  processing: 'Processando',
  in_preparation: 'Em elaboração',
  in_elaboration: 'Em elaboração',
  in_review: 'Em revisão',
  under_review: 'Em análise',
  under_analysis: 'Em análise',
  not_started: 'Não iniciado',
  in_progress: 'Em andamento',
  open: 'Aberto',
  collecting: 'Em coleta',
  on_hold: 'Em espera',
  pending: 'Pendente',
  pending_validation: 'Aguardando validação',
  pending_ratification: 'Aguardando ratificação',
  awaiting_validation: 'Aguardando validação',
  submitted: 'Submetido à validação',
  approved: 'Aprovado',
  approved_with_conditions: 'Aprovado com condicionantes',
  approved_with_reservations: 'Aprovado com ressalvas',
  validated: 'Validado',
  validated_with_reservations: 'Validado com ressalvas',
  rejected: 'Rejeitado',
  blocked: 'Bloqueado',
  suspended: 'Suspenso',
  completed: 'Concluído',
  completed_with_warnings: 'Concluído com alertas',
  closed: 'Encerrado',
  reopened: 'Reaberto',
  cancelled: 'Cancelado',
  archived: 'Arquivado',
  revoked: 'Revogado',
  superseded: 'Substituído',
  waived: 'Dispensado',
  failed: 'Falhou',
  partial: 'Parcial',
  satisfied: 'Atendido',
  not_required: 'Validação não obrigatória',
  not_assessed: 'Não avaliado',
  on_track: 'No caminho esperado',
  attention: 'Requer atenção',
  critical: 'Crítico',
  low: 'Baixo',
  medium: 'Médio',
  high: 'Alto',
  verified: 'Verificado',
  achieved: 'Alcançado',
  not_achieved: 'Não alcançado',
  accepted: 'Aceito',
  sent: 'Enviado',
  trial: 'Avaliação',
  deprecated: 'Descontinuado',
}

const ROLE_LABELS_PT_BR: Record<string, string> = {
  super_admin: 'SUPER-ADMIN da Plataforma',
  platform_admin: 'Administrador da Plataforma',
  support_admin: 'Administrador de Suporte',
  auditor: 'Auditor da Plataforma',
  visitor: 'Visitante',
  administrator: 'Administrador',
  manager: 'Gestor',
  editor: 'Elaborador',
  validator: 'Validador',
  approver: 'Aprovador',
  monitor: 'Monitor',
  ratifier: 'Ratificador',
  viewer: 'Visualizador',
}

const EVENT_LABELS_PT_BR: Record<string, string> = {
  configuration_changed: 'Configuração alterada',
  module_role_assigned: 'Perfil do módulo atribuído',
  module_role_revoked: 'Perfil do módulo revogado',
  membership_created: 'Vínculo criado',
  membership_updated: 'Vínculo atualizado',
  membership_revoked: 'Vínculo revogado',
  user_created: 'Usuário criado',
  user_updated: 'Usuário atualizado',
  status_changed: 'Situação alterada',
  STATUS_CHANGED: 'Situação alterada',
  journey_item_status_changed: 'Situação da jornada alterada',
  journey_template_backfilled: 'Jornada complementada pelo modelo metodológico',
  delivery_kit_generated: 'Kit de Entregas gerado',
  phase_reopened: 'Fase reaberta',
  data_viewed: 'Dados consultados',
  data_created: 'Dados criados',
  data_updated: 'Dados atualizados',
  data_deleted: 'Dados excluídos',
  data_exported: 'Dados exportados',
}

const ARTIFACT_TYPE_LABELS_PT_BR: Record<string, string> = {
  EXECUTIVE_VALIDATION_PACKAGE: 'Pacote executivo de validação',
  EXECUTIVE_DECISION: 'Decisão executiva',
  PHASE_TRANSITION_PROTOCOL: 'Protocolo de transição de fase',
  PHASE_SYNTHESIS: 'Síntese da fase',
  PHASE_EXECUTIVE_REPORT: 'Relatório executivo da fase',
  EXECUTIVE_PRESENTATION: 'Apresentação executiva',
  CANONICAL_WORKBOOK: 'Planilha canônica de gestão',
  PORTABLE_HTML: 'Portal HTML de consulta',
  HANDOFF_PACKAGE: 'Pacote de transição',
  EVIDENCE_PACKAGE: 'Pacote de evidências',
  RISK_MATRIX: 'Matriz de riscos',
  SWOT_MATRIX: 'Matriz SWOT',
  TOWS_MATRIX: 'Matriz TOWS',
}

function normalizeCode(value: string | null | undefined) {
  return String(value ?? '').trim()
}

function looksLikeTechnicalCode(value: string) {
  return /^[A-Z0-9_.-]+$/.test(value) || /^[a-z0-9]+(?:_[a-z0-9]+)+$/.test(value)
}

function appearsEnglish(value: string) {
  return /\b(access|denied|permission|failed|failure|invalid|not found|system role|administrator|viewer|manager|unexpected|network|request|duplicate|violates|constraint)\b/i.test(value)
}

export function statusLabelPtBr(value: string | null | undefined, fallback?: string) {
  const code = normalizeCode(value)
  if (!code) return fallback ?? 'Não informado'
  return STATUS_LABELS_PT_BR[code] ?? STATUS_LABELS_PT_BR[code.toLowerCase()] ?? fallback ?? (looksLikeTechnicalCode(code) ? 'Situação não classificada' : code)
}

export function roleLabelPtBr(value: string | null | undefined, fallback?: string) {
  const code = normalizeCode(value)
  if (!code) return fallback ?? 'Sem perfil'
  const known = ROLE_LABELS_PT_BR[code.toLowerCase()]
  if (known) return known
  if (fallback && !appearsEnglish(fallback) && !looksLikeTechnicalCode(fallback)) return fallback
  return 'Perfil não classificado'
}

export function eventLabelPtBr(value: string | null | undefined) {
  const code = normalizeCode(value)
  if (!code) return 'Evento não informado'
  return EVENT_LABELS_PT_BR[code] ?? EVENT_LABELS_PT_BR[code.toLowerCase()] ?? (looksLikeTechnicalCode(code) ? 'Evento registrado' : code)
}

export function artifactTypeLabelPtBr(value: string | null | undefined, fallback?: string) {
  const code = normalizeCode(value)
  if (!code) return fallback ?? 'Artefato metodológico'
  return ARTIFACT_TYPE_LABELS_PT_BR[code] ?? fallback ?? (looksLikeTechnicalCode(code) ? 'Artefato metodológico' : code)
}

export function translateBackendMessage(value: string | null | undefined) {
  const text = normalizeCode(value)
  if (!text) return 'Não foi possível concluir a operação.'
  const normalized = text.toLocaleLowerCase('pt-BR')

  if (normalized.includes('access denied') || normalized.includes('permission denied')) return 'Acesso negado para esta operação.'
  if (normalized.includes('row-level security')) return 'A operação foi bloqueada pelas regras de segurança da organização.'
  if (normalized.includes('duplicate key') || normalized.includes('already exists')) return 'Já existe um registro com essas informações.'
  if (normalized.includes('not found') || normalized.includes('could not find')) return 'O registro ou recurso solicitado não foi localizado.'
  if (normalized.includes('invalid') || normalized.includes('violates check constraint')) return 'Os dados informados não atendem às regras de validação.'
  if (normalized.includes('failed to fetch') || normalized.includes('network request failed')) return 'Não foi possível comunicar com o serviço. Verifique a conexão e tente novamente.'
  if (normalized.includes('function') && normalized.includes('schema cache')) return 'A atualização do banco ainda não está disponível para a aplicação. Atualize o esquema e tente novamente.'
  if (appearsEnglish(text)) return 'Não foi possível concluir a operação. O detalhe técnico foi preservado no console e na auditoria.'
  return text
}
