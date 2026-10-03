import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

type RequestPayload = {
  action?: 'prepare_review' | 'get_review'
  importRecordId?: string
  requestId?: string
  reason?: string | null
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

  if (!payload.action || !['prepare_review', 'get_review'].includes(payload.action)) {
    return jsonResponse({ error: 'Ação inválida.' }, 400)
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  })

  let organizationId: string | null = null
  let importRecordId: string | null = payload.importRecordId?.trim() || null
  let requestId: string | null = payload.requestId?.trim() || null

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

    const [{ data: canManage, error: manageError }, { data: isSuperAdmin, error: superError }] =
      await Promise.all([
        userClient.rpc('can_manage_skpe_journey', { target_organization_id: organizationId }),
        userClient.rpc('is_platform_super_admin'),
      ])

    if (manageError || superError) {
      return jsonResponse({ error: 'Não foi possível validar a autorização.' }, 500)
    }
    if (canManage !== true && isSuperAdmin !== true) {
      return jsonResponse({ error: 'Sem permissão para preparar incorporação nesta organização.' }, 403)
    }

    const actorType = isSuperAdmin === true ? 'sparks_consultancy' : 'organization'
    const { data: prepared, error: prepareError } = await adminClient.rpc(
      'skpe_prepare_import_incorporation_review',
      {
        p_import_record_id: importRecordId,
        p_requested_by_actor_type: actorType,
        p_requested_by_user_id: requesterData.user.id,
        p_request_reason: payload.reason?.trim() || 'Preparação para revisão humana de incorporação histórica.',
        p_metadata: {
          source: 'skpe-import-incorporation-edge',
          action: 'prepare_review',
          authenticated_actor_user_id: requesterData.user.id,
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
  } else {
    if (!requestId) return jsonResponse({ error: 'Request de incorporação é obrigatório.' }, 400)

    const { data: requestRow, error: requestLookupError } = await adminClient
      .from('skpe_import_incorporation_requests')
      .select('id, organization_id, import_record_id')
      .eq('id', requestId)
      .maybeSingle()

    if (requestLookupError) return jsonResponse({ error: 'Não foi possível consultar o Request.' }, 500)
    if (!requestRow) return jsonResponse({ error: 'Request de incorporação não encontrado.' }, 404)

    organizationId = String(requestRow.organization_id)
    importRecordId = String(requestRow.import_record_id)

    const [{ data: canManage, error: manageError }, { data: isSuperAdmin, error: superError }] =
      await Promise.all([
        userClient.rpc('can_manage_skpe_journey', { target_organization_id: organizationId }),
        userClient.rpc('is_platform_super_admin'),
      ])

    if (manageError || superError) {
      return jsonResponse({ error: 'Não foi possível validar a autorização.' }, 500)
    }
    if (canManage !== true && isSuperAdmin !== true) {
      return jsonResponse({ error: 'Sem permissão para consultar esta incorporação.' }, 403)
    }
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

  return jsonResponse({
    success: true,
    action: payload.action,
    materializationExecuted: false,
    request: requestResponse.data,
    importRecord: recordResponse.data,
    items: itemsResponse.data ?? [],
    targetResolution: resolutionResponse.data?.[0] ?? null,
    decisions: decisionsResponse.data ?? [],
  })
})
