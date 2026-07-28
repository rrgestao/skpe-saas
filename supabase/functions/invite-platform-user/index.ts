import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

type CreateUserPayload = {
  email?: string
  password?: string
  fullName?: string
  phone?: string | null
  organizationId?: string | null
  platformRoleId?: string | null
  isOrganizationAdmin?: boolean
  jobTitle?: string | null
}

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  })
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Método não permitido.' }, 405)
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  const authorization = request.headers.get('Authorization')

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return jsonResponse({ error: 'Configuração do ambiente incompleta.' }, 500)
  }

  if (!authorization) {
    return jsonResponse({ error: 'Sessão não informada.' }, 401)
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
  })

  const [{ data: requesterData, error: requesterError }, { data: isSuperAdmin, error: authorizationError }] = await Promise.all([
    userClient.auth.getUser(),
    userClient.rpc('is_platform_super_admin'),
  ])

  if (requesterError || !requesterData.user) {
    return jsonResponse({ error: 'Sessão inválida ou expirada.' }, 401)
  }

  if (authorizationError || isSuperAdmin !== true) {
    return jsonResponse({ error: 'Acesso restrito ao SUPER-ADMIN.' }, 403)
  }

  let payload: CreateUserPayload

  try {
    payload = await request.json() as CreateUserPayload
  } catch {
    return jsonResponse({ error: 'Conteúdo da requisição inválido.' }, 400)
  }

  const email = payload.email?.trim().toLowerCase()
  const password = payload.password ?? ''
  const fullName = payload.fullName?.trim()
  const phone = payload.phone?.trim() || null

  if (!fullName) {
    return jsonResponse({ error: 'Informe o nome completo.' }, 400)
  }

  if (!email || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
    return jsonResponse({ error: 'Informe um e-mail válido.' }, 400)
  }

  if (password.length < 10) {
    return jsonResponse({ error: 'A senha inicial deve possuir pelo menos 10 caracteres.' }, 400)
  }

  if (payload.isOrganizationAdmin === true && !payload.organizationId) {
    return jsonResponse({ error: 'Selecione uma organização para definir o usuário como administrador local.' }, 400)
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  })

  const { data: createdData, error: createError } = await adminClient.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: {
      full_name: fullName,
      display_name: fullName,
      created_by_platform_admin: true,
    },
  })

  if (createError || !createdData.user) {
    return jsonResponse({ error: createError?.message ?? 'Não foi possível criar o usuário.' }, 400)
  }

  const userId = createdData.user.id
  const actorUserId = requesterData.user.id
  const now = new Date().toISOString()

  const rollback = async () => {
    await adminClient.auth.admin.deleteUser(userId)
  }

  const { error: profileError } = await adminClient
    .from('profiles')
    .upsert({
      id: userId,
      full_name: fullName,
      display_name: fullName,
      email,
      phone,
      active: true,
      updated_at: now,
    }, { onConflict: 'id' })

  if (profileError) {
    await rollback()
    return jsonResponse({ error: `A conta foi criada, mas o perfil não pôde ser consolidado: ${profileError.message}` }, 500)
  }

  if (payload.organizationId) {
    const { error: membershipError } = await adminClient
      .from('organization_memberships')
      .upsert({
        organization_id: payload.organizationId,
        user_id: userId,
        status: 'active',
        is_organization_admin: payload.isOrganizationAdmin === true,
        job_title: payload.jobTitle?.trim() || null,
        valid_from: now,
        activated_at: now,
        invited_by: actorUserId,
        created_by: actorUserId,
        updated_by: actorUserId,
      }, { onConflict: 'organization_id,user_id' })

    if (membershipError) {
      await rollback()
      return jsonResponse({ error: `O vínculo organizacional não pôde ser criado: ${membershipError.message}` }, 500)
    }
  }

  if (payload.platformRoleId) {
    const { error: roleError } = await adminClient
      .from('user_platform_roles')
      .upsert({
        user_id: userId,
        platform_role_id: payload.platformRoleId,
        status: 'active',
        valid_from: now,
        assigned_at: now,
        assigned_by: actorUserId,
        assignment_reason: 'Usuário criado diretamente pela Administração da Plataforma.',
      }, { onConflict: 'user_id,platform_role_id' })

    if (roleError) {
      await rollback()
      return jsonResponse({ error: `O perfil global não pôde ser atribuído: ${roleError.message}` }, 500)
    }
  }

  const { error: auditError } = await adminClient
    .from('privileged_access_audit')
    .insert({
      actor_user_id: actorUserId,
      organization_id: payload.organizationId || null,
      event_type: 'data_created',
      event_description: 'Usuário criado diretamente pela Administração da Plataforma.',
      entity_schema: 'auth',
      entity_table: 'users',
      entity_id: userId,
      new_data: {
        email,
        full_name: fullName,
        active: true,
        email_confirmed: true,
      },
      metadata: {
        source: 'platform_admin',
        created_without_invitation: true,
        organization_id: payload.organizationId || null,
        platform_role_id: payload.platformRoleId || null,
        is_organization_admin: payload.isOrganizationAdmin === true,
      },
    })

  if (auditError) {
    await rollback()
    return jsonResponse({ error: `A criação não pôde ser auditada: ${auditError.message}` }, 500)
  }

  return jsonResponse({
    success: true,
    userId,
    email,
    organizationId: payload.organizationId || null,
    platformRoleId: payload.platformRoleId || null,
  })
})
