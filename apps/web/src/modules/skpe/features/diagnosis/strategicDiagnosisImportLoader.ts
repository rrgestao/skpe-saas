import { supabase } from '../../../../lib/supabase.ts'
import {
  reconcileImportedDiagnosisRecords,
  type DiagnosisImportRecordRow,
  type ImportedDiagnosisRecord,
} from './strategicDiagnosisImportReconciler.ts'

export type DiagnosisArtifactKind = 'pestel' | 'swot' | 'tows' | 'risks'

export type { ImportedDiagnosisRecord } from './strategicDiagnosisImportReconciler.ts'

const sheetByKind: Record<DiagnosisArtifactKind, string> = {
  pestel: '04_PESTEL',
  swot: '05_SWOT',
  tows: '06_TOWS',
  risks: '07_Riscos',
}

const canonicalTableByKind: Record<DiagnosisArtifactKind, string> = {
  pestel: 'skpe_pestel_items',
  swot: 'skpe_swot_items',
  tows: 'skpe_tows_items',
  risks: 'skpe_strategic_risk_items',
}

type CanonicalDiagnosisRow = Record<string, unknown> & {
  id: string
  code: string
  source_import_record_id: string | null
  source_external_key: string | null
  source_sheet: string | null
  source_row: number | null
  source_payload: Record<string, unknown> | null
  created_at: string
  updated_at: string
}

function joinCodes(value: unknown): string | undefined {
  if (!Array.isArray(value) || value.length === 0) return undefined
  return value.map((item) => String(item)).join('/')
}

function joinEvidence(value: unknown): string | undefined {
  if (!Array.isArray(value) || value.length === 0) return undefined
  return value.map((item) => String(item)).join(' / ')
}

function canonicalValues(
  kind: DiagnosisArtifactKind,
  row: CanonicalDiagnosisRow,
): Record<string, unknown> {
  const source = { ...(row.source_payload ?? {}) }

  if (kind === 'pestel') {
    return {
      ...source,
      codigo: row.code,
      dimensao: row.dimension,
      fator_externo: row.external_factor,
      natureza: row.nature,
      efeito: row.effect,
      impacto: row.impact_label,
      probabilidade: row.probability_label,
      horizonte: row.horizon,
      implicacao_para_cootaquara: row.strategic_implication,
      resposta_preliminar: row.preliminary_response,
      swot_relacionada: joinCodes(row.related_swot_codes),
      risco_relacionado: joinCodes(row.related_risk_codes),
      fonte_evidencia: joinEvidence(row.evidence_references),
      status: row.status,
    }
  }

  if (kind === 'swot') {
    return {
      ...source,
      codigo: row.code,
      quadrante: row.quadrant,
      fator: row.factor,
      descricao_evidencia: row.evidence_description,
      impacto: row.impact_label,
      prioridade: row.priority,
      responsavel: row.owner_label,
      origem_pestel: joinCodes(row.origin_pestel_codes),
      evidencias_relacionadas: joinCodes(row.evidence_references),
      status: row.status,
    }
  }

  if (kind === 'tows') {
    return {
      ...source,
      codigo: row.code,
      tipo: row.tows_type,
      estrategia_formulada: row.strategy_statement,
      forcas_fraquezas: joinCodes(row.internal_factor_codes),
      oportunidades_ameacas: joinCodes(row.external_factor_codes),
      tema_decisorio: row.decision_theme,
      prioridade: row.priority,
      horizonte: row.horizon,
      responsavel: row.owner_label,
      condicao_gate: row.gate_condition,
      status: row.status,
    }
  }

  return {
    ...source,
    codigo: row.code,
    evento_de_risco: row.risk_event,
    categoria: row.category,
    causa: row.cause,
    consequencia: row.consequence,
    probabilidade: row.probability_label,
    impacto: row.impact_label,
    nivel_inerente: row.inherent_score,
    controles_existentes: row.existing_controls,
    lacunas_de_controle: row.control_gaps,
    resposta: row.response_type,
    plano_de_tratamento: row.treatment_plan,
    indicador_monitoramento: row.monitoring_indicator,
    evidencia_monitoramento: row.monitoring_evidence,
    responsavel: row.owner_label,
    prazo: row.due_horizon,
    risco_residual: row.residual_score,
    evidencia: joinEvidence(row.evidence_references),
    reconhecimento_pela_direcao: row.management_recognition,
    aceite_do_risco: row.risk_acceptance,
    evidencia_do_aceite: row.acceptance_evidence,
    ciclo_de_implementacao: row.implementation_cycle,
    destino_no_portfolio: row.portfolio_destination,
    conclusao: row.completion_percent,
    oe_relacionado: joinCodes(row.related_objective_codes),
    status: row.status,
  }
}

const canonicalSelectByKind: Record<DiagnosisArtifactKind, string> = {
  pestel:
    'id,code,dimension,external_factor,nature,effect,impact_label,probability_label,horizon,strategic_implication,preliminary_response,related_swot_codes,related_risk_codes,evidence_references,status,source_import_record_id,source_external_key,source_sheet,source_row,source_payload,created_at,updated_at',
  swot:
    'id,code,quadrant,factor,evidence_description,impact_label,priority,owner_label,origin_pestel_codes,evidence_references,status,source_import_record_id,source_external_key,source_sheet,source_row,source_payload,created_at,updated_at',
  tows:
    'id,code,tows_type,strategy_statement,internal_factor_codes,external_factor_codes,decision_theme,priority,horizon,owner_label,gate_condition,status,source_import_record_id,source_external_key,source_sheet,source_row,source_payload,created_at,updated_at',
  risks:
    'id,code,risk_event,category,cause,consequence,probability_label,impact_label,inherent_score,existing_controls,control_gaps,response_type,treatment_plan,monitoring_indicator,monitoring_evidence,owner_label,due_horizon,residual_score,status,evidence_references,management_recognition,risk_acceptance,acceptance_evidence,implementation_cycle,portfolio_destination,completion_percent,related_objective_codes,source_import_record_id,source_external_key,source_sheet,source_row,source_payload,created_at,updated_at',
}

async function loadCanonicalDiagnosisArtifact(
  organizationId: string,
  projectId: string,
  kind: DiagnosisArtifactKind,
): Promise<ImportedDiagnosisRecord[] | null> {
  const table = canonicalTableByKind[kind]
  const { data, error } = await (supabase as any)
    .from(table)
    .select(canonicalSelectByKind[kind])
    .eq('organization_id', organizationId)
    .eq('project_id', projectId)
    .is('archived_at', null)
    .order('code', { ascending: true })

  if (error) {
    throw new Error(
      `Não foi possível carregar o artefato canônico ${table}: ${error.message}`,
    )
  }

  if (!data || data.length === 0) return null

  const rows: DiagnosisImportRecordRow[] = (data as CanonicalDiagnosisRow[]).map(
    (row) => ({
      id: row.id,
      source_sheet: row.source_sheet ?? sheetByKind[kind],
      source_row: row.source_row,
      external_key: row.source_external_key ?? `${kind}:${row.code}`,
      simulation_status: 'canonical',
      target_record_id: row.id,
      values_json: canonicalValues(kind, row),
      created_at: row.updated_at ?? row.created_at,
    }),
  )

  return reconcileImportedDiagnosisRecords(rows)
}

async function loadStagingDiagnosisArtifact(
  organizationId: string,
  projectId: string,
  kind: DiagnosisArtifactKind,
): Promise<ImportedDiagnosisRecord[]> {
  const { data, error } = await supabase
    .from('skpe_import_records')
    .select(
      'id,source_sheet,source_row,external_key,simulation_status,target_record_id,values_json,created_at',
    )
    .eq('organization_id', organizationId)
    .eq('project_id', projectId)
    .eq('source_sheet', sheetByKind[kind])
    .eq('quality_status', 'valid')
    .order('created_at', { ascending: false })

  if (error) {
    throw new Error(
      `Não foi possível carregar o fallback importado ${sheetByKind[kind]}: ${error.message}`,
    )
  }

  return reconcileImportedDiagnosisRecords(
    (data ?? []) as DiagnosisImportRecordRow[],
  )
}

export async function loadDiagnosisArtifact(
  organizationId: string,
  projectId: string,
  kind: DiagnosisArtifactKind,
): Promise<ImportedDiagnosisRecord[]> {
  const canonical = await loadCanonicalDiagnosisArtifact(
    organizationId,
    projectId,
    kind,
  )

  if (canonical && canonical.length > 0) {
    return canonical
  }

  return loadStagingDiagnosisArtifact(organizationId, projectId, kind)
}

/**
 * Compatibilidade temporária durante a convergência do Diagnóstico.
 * Novos consumidores devem usar loadDiagnosisArtifact.
 */
export const loadImportedDiagnosisArtifact = loadDiagnosisArtifact
