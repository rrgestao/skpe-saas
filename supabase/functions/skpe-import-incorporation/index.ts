import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

type RequestPayload = {
  action?: 'prepare_review' | 'get_review' | 'review_item' | 'review_request_items' | 'decide_request'
  importRecordId?: string
  requestId?: string
  itemId?: string
  reason?: string | null
  reviewOutcome?: 'validated' | 'validated_with_reservations' | 'requires_adjustment' | 'rejected'
  decisionOutcome?: 'approved' | 'approved_with_reservations' | 'rejected' | 'deferred' | 'returned_for_adjustment'
  reservations?: unknown[]
}

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

function compactError(error: unknown) {
  if (error && typeof error === 'object' && 'message' in error) {
    return String((error as { message?: unknown }).message ?? 'Erro desconhecido.')
  }
  return String(error ?? 'Erro desconhecido.')
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (request.method !== 'POST') return jsonResponse({ error: 'Método não permitido.' }, 405)

  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  const authorization = request.headers.get('Authorization')

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return jsonResponse({ error: 'Configuração do ambiente incompleta.' }, 500)
  }
  if (!authorization) return jsonResponse({ error: 'Sessão não informada.' }, 401)

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { autoRefreshToken: false, persistSession: false },
  })

  const { data: requesterData, error: requesterError } = await userClient.auth.getUser()
  if (requesterError || !requesterData.user) {
    return jsonResponse({ error: 'Sessão inválida ou expirada.' }, 401)
  }

  let payload: RequestPayload
  try {
    payload = await request.json() as RequestPayload
  } catch {
    return jsonResponse({ error: 'Conteúdo da requisição inválido.' }, 400)
  }

  const supportedActions = ['prepare_review', 'get_review', 'review_item', 'review_request_items', 'decide_request']
  if (!payload.action || !supportedActions.includes(payload.action)) {
    return jsonResponse({ error: 'Ação inválida.' }, 400)
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  })

  let organizationId: string | null = null
  let importRecordId: string | null = payload.importRecordId?.trim() || null
  let requestId: string | null = payload.requestId?.trim() || null
  let itemId: string | null = payload.itemId?.trim() || null

  if (payload.action === 'prepare_review') {
    if (!importRecordId) return jsonResponse({ error: 'ImportRecord é obrigatório.' }, 400)

    const { data: record, error: recordError } = await adminClient
      .from('skpe_import_records')
      .select('id, organization_id, project_id, batch_id, entity_code, external_key, quality_status')
      .eq('id', importRecordId)
      .maybeSingle()

    if (recordError) return jsonResponse({ error: 'Não foi possível consultar o ImportRecord.' }, 500)
    if (!record) return jsonResponse({ error: 'ImportRecord não encontrado.' }, 404)
    organizationId = String(record.organization_id)
  } else if (payload.action === 'review_item') {
    if (!itemId) return jsonResponse({ error: 'Item de incorporação é obrigatório.' }, 400)

    const { data: item, error: itemError } = await adminClient
      .from('skpe_import_incorporation_items')
      .select('id, incorporation_request_id')
      .eq('id', itemId)
      .maybeSingle()

    if (itemError) return jsonResponse({ error: 'Não foi possível consultar o item de incorporação.' }, 500)
    if (!item) return jsonResponse({ error: 'Item de incorporação não encontrado.' }, 404)

    requestId = String(item.incorporation_request_id)
  }

  if (payload.action !== 'prepare_review') {
    if (!requestId) return jsonResponse({ error: 'Request de incorporação é obrigatório.' }, 400)

    const { data: requestRow, error: requestLookupError } = await adminClient
      .from('skpe_import_incorporation_requests')
      .select('id, organization_id, import_record_id, eligibility_status, request_status')
      .eq('id', requestId)
      .maybeSingle()

    if (requestLookupError) return jsonResponse({ error: 'Não foi possível consultar o Request.' }, 500)
    if (!requestRow) return jsonResponse({ error: 'Request de incorporação não encontrado.' }, 404)

    organizationId = String(requestRow.organization_id)
    importRecordId = String(requestRow.import_record_id)
  }

  if (!organizationId) return jsonResponse({ error: 'Organização não determinada.' }, 500)

  const [{ data: canManage, error: manageError }, { data: isSuperAdmin, error: superError }] =
    await Promise.all([
      userClient.rpc('can_manage_skpe_journey', { target_organization_id: organizationId }),
      userClient.rpc('is_platform_super_admin'),
    ])

  if (manageError || superError) {
    return jsonResponse({ error: 'Não foi possível validar a autorização.' }, 500)
  }
  if (canManage !== true && isSuperAdmin !== true) {
    return jsonResponse({ error: 'Sem permissão para operar esta incorporação.' }, 403)
  }

  const actorType = isSuperAdmin === true ? 'sparks_consultancy' : 'organization'
  const actorUserId = requesterData.user.id
  const reservations = Array.isArray(payload.reservations) ? payload.reservations : []

  if (payload.action === 'prepare_review') {
    const { data: prepared, error: prepareError } = await adminClient.rpc(
      'skpe_prepare_import_incorporation_review',
      {
        p_import_record_id: importRecordId,
        p_requested_by_actor_type: actorType,
        p_requested_by_user_id: actorUserId,
        p_request_reason: payload.reason?.trim() || 'Preparação para revisão humana de incorporação histórica.',
        p_metadata: {
          source: 'skpe-import-incorporation-edge',
          action: 'prepare_review',
          authenticated_actor_user_id: actorUserId,
          semantic_inference: false,
          materialization_requested: false,
        },
      },
    )

    if (prepareError) return jsonResponse({ error: compactError(prepareError) }, 400)
    const preparedObject = prepared && typeof prepared === 'object'
      ? prepared as Record<string, unknown>
      : {}
    requestId = String(preparedObject.requestId ?? '')
    if (!requestId) return jsonResponse({ error: 'Preparação não retornou Request válido.' }, 500)
  }

  if (payload.action === 'review_item') {
    if (!itemId || !payload.reviewOutcome) {
      return jsonResponse({ error: 'Item e resultado da revisão são obrigatórios.' }, 400)
    }
    const reason = payload.reason?.trim()
    if (!reason) return jsonResponse({ error: 'Justificativa da revisão é obrigatória.' }, 400)
    if (payload.reviewOutcome === 'validated_with_reservations' && reservations.length === 0) {
      return jsonResponse({ error: 'Validação com ressalvas exige ao menos uma ressalva.' }, 400)
    }

    const { error: reviewError } = await adminClient.rpc('skpe_review_import_incorporation_item', {
      p_incorporation_item_id: itemId,
      p_review_outcome: payload.reviewOutcome,
      p_review_reason: reason,
      p_reviewer_actor_type: actorType,
      p_reviewer_user_id: actorUserId,
      p_reservations: reservations,
      p_metadata: {
        source: 'skpe-import-incorporation-edge',
        action: 'review_item',
        authenticated_actor_user_id: actorUserId,
        semantic_inference: false,
        materialization_requested: false,
      },
    })

    if (reviewError) return jsonResponse({ error: compactError(reviewError) }, 400)

    const { error: evaluateError } = await adminClient.rpc('skpe_evaluate_import_incorporation_request', {
      p_request_id: requestId,
      p_evaluated_by_actor_type: actorType,
      p_evaluated_by_user_id: actorUserId,
    })
    if (evaluateError) return jsonResponse({ error: compactError(evaluateError) }, 400)
  }

  if (payload.action === 'review_request_items') {
    const reason = payload.reason?.trim()
    if (!reason) return jsonResponse({ error: 'Justificativa da revisão do registro é obrigatória.' }, 400)

    const { data: itemsToReview, error: itemsLookupError } = await adminClient
      .from('skpe_import_incorporation_items')
      .select('id, information_state, validation_state')
      .eq('incorporation_request_id', requestId)
      .order('item_sequence')

    if (itemsLookupError) return jsonResponse({ error: compactError(itemsLookupError) }, 500)
    if (!itemsToReview || itemsToReview.length === 0) {
      return jsonResponse({ error: 'Request não possui campos preparados para revisão.' }, 409)
    }

    const nonProvided = itemsToReview.filter((item) => item.information_state !== 'provided')
    if (nonProvided.length > 0) {
      return jsonResponse({
        error: 'Este registro possui campos ausentes ou não fornecidos. A revisão deve ser feita campo a campo.',
      }, 409)
    }

    const pendingItems = itemsToReview.filter(
      (item) => !['validated', 'validated_with_reservations'].includes(String(item.validation_state ?? '')),
    )

    for (const item of pendingItems) {
      const { error: reviewError } = await adminClient.rpc('skpe_review_import_incorporation_item', {
        p_incorporation_item_id: item.id,
        p_review_outcome: 'validated',
        p_review_reason: reason,
        p_reviewer_actor_type: actorType,
        p_reviewer_user_id: actorUserId,
        p_reservations: [],
        p_metadata: {
          source: 'skpe-import-incorporation-edge',
          action: 'review_request_items',
          authenticated_actor_user_id: actorUserId,
          human_bulk_review: true,
          semantic_inference: false,
          materialization_requested: false,
        },
      })

      if (reviewError) return jsonResponse({ error: compactError(reviewError) }, 400)
    }

    const { error: evaluateError } = await adminClient.rpc('skpe_evaluate_import_incorporation_request', {
      p_request_id: requestId,
      p_evaluated_by_actor_type: actorType,
      p_evaluated_by_user_id: actorUserId,
    })
    if (evaluateError) return jsonResponse({ error: compactError(evaluateError) }, 400)
  }

  if (payload.action === 'decide_request') {
    if (!payload.decisionOutcome) return jsonResponse({ error: 'Resultado da decisão é obrigatório.' }, 400)
    const reason = payload.reason?.trim()
    if (!reason) return jsonResponse({ error: 'Justificativa da decisão é obrigatória.' }, 400)
    if (payload.decisionOutcome === 'approved_with_reservations' && reservations.length === 0) {
      return jsonResponse({ error: 'Aprovação com ressalvas exige ao menos uma ressalva.' }, 400)
    }

    const { data: eligibility, error: evaluateError } = await adminClient.rpc(
      'skpe_evaluate_import_incorporation_request',
      {
        p_request_id: requestId,
        p_evaluated_by_actor_type: actorType,
        p_evaluated_by_user_id: actorUserId,
      },
    )
    if (evaluateError) return jsonResponse({ error: compactError(evaluateError) }, 400)

    if (
      ['approved', 'approved_with_reservations'].includes(payload.decisionOutcome)
      && !['eligible', 'eligible_with_reservations'].includes(String(eligibility))
    ) {
      return jsonResponse({
        error: `Request ainda não está apto para aprovação. Elegibilidade atual: ${String(eligibility)}.`,
      }, 409)
    }

    const { error: decisionError } = await adminClient.rpc('skpe_record_import_incorporation_decision', {
      p_request_id: requestId,
      p_decision_outcome: payload.decisionOutcome,
      p_decision_reason: reason,
      p_decided_by_actor_type: actorType,
      p_decided_by_user_id: actorUserId,
      p_reservations: reservations,
      p_decision_evidence: {
        source: 'authenticated_human_review',
        edge_function: 'skpe-import-incorporation',
      },
      p_metadata: {
        source: 'skpe-import-incorporation-edge',
        action: 'decide_request',
        authenticated_actor_user_id: actorUserId,
        materialization_requested: false,
      },
    })

    if (decisionError) return jsonResponse({ error: compactError(decisionError) }, 400)
  }

  if (!requestId || !importRecordId) {
    return jsonResponse({ error: 'Contexto da incorporação incompleto.' }, 500)
  }

  const [requestResponse, recordResponse, itemsResponse, resolutionResponse, decisionsResponse] =
    await Promise.all([
      adminClient.from('skpe_import_incorporation_requests').select('*').eq('id', requestId).single(),
      adminClient
        .from('skpe_import_records')
        .select('id, batch_id, organization_id, project_id, entity_code, entity_name, source_sheet, source_row, external_key, quality_status, simulation_status, values_json, reviewed, review_decision, review_notes')
        .eq('id', importRecordId)
        .single(),
      adminClient
        .from('skpe_import_incorporation_items')
        .select('*')
        .eq('incorporation_request_id', requestId)
        .order('item_sequence'),
      adminClient
        .from('skpe_import_target_resolution_events')
        .select('id, mapping_version_id, resolution_sequence, resolution_status, resolution_mode, source_entity_code, target_entity_type, target_entity_id, target_external_key, warnings, blockers, resolved_at, metadata')
        .eq('import_record_id', importRecordId)
        .order('resolved_at', { ascending: false })
        .order('resolution_sequence', { ascending: false })
        .limit(1),
      adminClient
        .from('skpe_import_incorporation_decisions')
        .select('*')
        .eq('incorporation_request_id', requestId)
        .order('decision_sequence', { ascending: false }),
    ])

  const firstError =
    requestResponse.error ||
    recordResponse.error ||
    itemsResponse.error ||
    resolutionResponse.error ||
    decisionsResponse.error

  if (firstError) return jsonResponse({ error: compactError(firstError) }, 500)

  const targetResolution = resolutionResponse.data?.[0] ?? null
  let targetSnapshot: Record<string, unknown> | null = null

  if (
    targetResolution?.resolution_mode === 'existing_entity'
    && targetResolution?.target_entity_id
  ) {
    const targetTableByType: Record<string, string> = {
      pestel_item: 'skpe_pestel_items',
      swot_item: 'skpe_swot_items',
      tows_item: 'skpe_tows_items',
      strategic_risk_item: 'skpe_strategic_risk_items',
    }
    const targetTable = targetTableByType[String(targetResolution.target_entity_type ?? '')]

    if (targetTable) {
      const { data: targetRow, error: targetError } = await adminClient
        .from(targetTable)
        .select('*')
        .eq('id', String(targetResolution.target_entity_id))
        .maybeSingle()

      if (targetError) return jsonResponse({ error: compactError(targetError) }, 500)
      targetSnapshot = (targetRow ?? null) as Record<string, unknown> | null
    }
  }

  return jsonResponse({
    success: true,
    action: payload.action,
    materializationExecuted: false,
    request: requestResponse.data,
    importRecord: recordResponse.data,
    items: itemsResponse.data ?? [],
    targetResolution,
    targetSnapshot,
    decisions: decisionsResponse.data ?? [],
  })
})
