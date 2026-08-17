import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

type ModuleRoleAssignment = {
  organizationModuleId?: string
  moduleRoleId?: string
}

type CreateUserPayload = {
  email?: string
  password?: string
  fullName?: string
  phone?: string | null
  organizationId?: string | null
  platformRoleId?: string | null
  platformRoleIds?: string[]
  moduleRoleAssignments?: ModuleRoleAssignment[]
  isOrganizationAdmin?: boolean
  jobTitle?: string | null
  changeReason?: string | null
}

type PlatformRoleRow = {
  id: string
  code: string
  active: boolean
}

type OrganizationModuleRow = {
  id: string
  organization_id: string
  module_id: string
  enabled: boolean
  status: string
}

type ModuleRoleRow = {
  id: string
  module_id: string
  active: boolean
  code: string
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

function uniqueNonEmpty(values: Array<string | null | undefined>) {
  return Array.from(new Set(values.map((value) => value?.trim()).filter(Boolean))) as string[]
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

  const { data: requesterData, error: requesterError } =
    await userClient.auth.getUser()

  if (requesterError || !requesterData.user) {
    return jsonResponse({ error: 'Sessão inválida ou expirada.' }, 401)
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
  const organizationId = payload.organizationId?.trim() || null
  const platformRoleIds = uniqueNonEmpty([
    ...(Array.isArray(payload.platformRoleIds) ? payload.platformRoleIds : []),
    payload.platformRoleId,
  ])
  const requestedModuleAssignments = Array.isArray(payload.moduleRoleAssignments)
    ? payload.moduleRoleAssignments
        .map((assignment) => ({
          organizationModuleId: assignment.organizationModuleId?.trim() ?? '',
          moduleRoleId: assignment.moduleRoleId?.trim() ?? '',
        }))
        .filter((assignment) => assignment.organizationModuleId && assignment.moduleRoleId)
    : []

  const [superAdminResponse, organizationAdminResponse] = await Promise.all([
    userClient.rpc('is_platform_super_admin'),
    organizationId
      ? userClient.rpc('is_organization_admin', {
          target_organization_id: organizationId,
        })
      : Promise.resolve({ data: false, error: null }),
  ])

  if (superAdminResponse.error) {
    return jsonResponse({ error: 'Não foi possível validar a autorização global.' }, 500)
  }

  if (organizationId && organizationAdminResponse.error) {
    return jsonResponse({ error: 'Não foi possível validar a autorização organizacional.' }, 500)
  }

  const isSuperAdmin = superAdminResponse.data === true
  const isOrganizationAdmin = organizationAdminResponse.data === true

  if (!isSuperAdmin && !isOrganizationAdmin) {
    return jsonResponse({ error: 'Acesso restrito a administradores autorizados.' }, 403)
  }

  if (!isSuperAdmin && !organizationId) {
    return jsonResponse({ error: 'O administrador local deve informar sua organização.' }, 403)
  }

  if (!isSuperAdmin && platformRoleIds.length > 0) {
    return jsonResponse({ error: 'Administradores locais não podem atribuir perfis globais.' }, 403)
  }

  if (!fullName) {
    return jsonResponse({ error: 'Informe o nome completo.' }, 400)
  }

  if (!email || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
    return jsonResponse({ error: 'Informe um e-mail válido.' }, 400)
  }

  if (password.length < 10) {
    return jsonResponse({ error: 'A senha inicial deve possuir pelo menos 10 caracteres.' }, 400)
  }

  if (payload.isOrganizationAdmin === true && !organizationId) {
    return jsonResponse({ error: 'Selecione uma organização para definir o usuário como administrador local.' }, 400)
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  })

  let selectedPlatformRoles: PlatformRoleRow[] = []

  if (platformRoleIds.length > 0) {
    const { data, error } = await adminClient
      .from('platform_roles')
      .select('id, code, active')
      .in('id', platformRoleIds)

    if (error) {
      return jsonResponse({ error: `Não foi possível validar os perfis globais: ${error.message}` }, 500)
    }

    selectedPlatformRoles = (data ?? []) as PlatformRoleRow[]

    if (selectedPlatformRoles.length !== platformRoleIds.length) {
      return jsonResponse({ error: 'Um ou mais perfis globais informados não existem.' }, 400)
    }

    if (selectedPlatformRoles.some((role) => !role.active)) {
      return jsonResponse({ error: 'Um ou mais perfis globais informados estão inativos.' }, 400)
    }
  }

  const visitorSelected = selectedPlatformRoles.some((role) => role.code === 'visitor')

  if (visitorSelected && selectedPlatformRoles.length > 1) {
    return jsonResponse({ error: 'O perfil VISITANTE deve ser exclusivo.' }, 400)
  }

  if (visitorSelected && !organizationId) {
    return jsonResponse({ error: 'O perfil VISITANTE exige uma organização inicial para definir o escopo de consulta.' }, 400)
  }

  if (visitorSelected && payload.isOrganizationAdmin === true) {
    return jsonResponse({ error: 'O VISITANTE não pode ser administrador da organização.' }, 400)
  }

  if (visitorSelected && requestedModuleAssignments.length > 0) {
    return jsonResponse({ error: 'O VISITANTE utiliza acesso dinâmico somente leitura e não pode receber papéis modulares adicionais.' }, 400)
  }

  if (requestedModuleAssignments.length > 0 && !organizationId) {
    return jsonResponse({ error: 'Selecione uma organização antes de atribuir perfis de módulo.' }, 400)
  }

  if (requestedModuleAssignments.length > 0 && organizationId) {
    const organizationModuleIds = uniqueNonEmpty(
      requestedModuleAssignments.map((assignment) => assignment.organizationModuleId),
    )
    const moduleRoleIds = uniqueNonEmpty(
      requestedModuleAssignments.map((assignment) => assignment.moduleRoleId),
    )

    const [organizationModulesResponse, moduleRolesResponse] = await Promise.all([
      adminClient
        .from('organization_modules')
        .select('id, organization_id, module_id, enabled, status')
        .in('id', organizationModuleIds),
      adminClient
        .from('module_roles')
        .select('id, module_id, active, code')
        .in('id', moduleRoleIds),
    ])

    if (organizationModulesResponse.error) {
      return jsonResponse({ error: `Não foi possível validar os módulos da organização: ${organizationModulesResponse.error.message}` }, 500)
    }

    if (moduleRolesResponse.error) {
      return jsonResponse({ error: `Não foi possível validar os perfis dos módulos: ${moduleRolesResponse.error.message}` }, 500)
    }

    const organizationModules = (organizationModulesResponse.data ?? []) as OrganizationModuleRow[]
    const moduleRoles = (moduleRolesResponse.data ?? []) as ModuleRoleRow[]
    const organizationModuleMap = new Map(organizationModules.map((row) => [row.id, row]))
    const moduleRoleMap = new Map(moduleRoles.map((row) => [row.id, row]))

    for (const assignment of requestedModuleAssignments) {
      const organizationModule = organizationModuleMap.get(assignment.organizationModuleId)
      const moduleRole = moduleRoleMap.get(assignment.moduleRoleId)

      if (!organizationModule || organizationModule.organization_id !== organizationId) {
        return jsonResponse({ error: 'Um dos módulos informados não pertence à organização inicial.' }, 400)
      }

      if (!organizationModule.enabled || !['trial', 'active'].includes(organizationModule.status)) {
        return jsonResponse({ error: 'Um dos módulos informados não está habilitado para a organização.' }, 400)
      }

      if (!moduleRole || !moduleRole.active || moduleRole.module_id !== organizationModule.module_id) {
        return jsonResponse({ error: 'Um dos perfis selecionados não pertence ao módulo correspondente ou está inativo.' }, 400)
      }

      if (moduleRole.code === 'visitor') {
        return jsonResponse({ error: 'Para acesso VISITANTE, selecione o perfil global VISITANTE em vez de atribuir o papel modular individualmente.' }, 400)
      }
    }
  }

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

  if (organizationId) {
    const { error: membershipError } = await adminClient
      .from('organization_memberships')
      .upsert({
        organization_id: organizationId,
        user_id: userId,
        status: 'active',
        is_organization_admin: visitorSelected ? false : payload.isOrganizationAdmin === true,
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

  if (platformRoleIds.length > 0) {
    const roleRows = platformRoleIds.map((platformRoleId) => ({
      user_id: userId,
      platform_role_id: platformRoleId,
      status: 'active',
      valid_from: now,
      assigned_at: now,
      assigned_by: actorUserId,
      assignment_reason: 'Usuário criado diretamente pela Administração da Plataforma.',
    }))

    const { error: roleError } = await adminClient
      .from('user_platform_roles')
      .upsert(roleRows, { onConflict: 'user_id,platform_role_id' })

    if (roleError) {
      await rollback()
      return jsonResponse({ error: `Os perfis globais não puderam ser atribuídos: ${roleError.message}` }, 500)
    }
  }

  if (requestedModuleAssignments.length > 0) {
    const moduleRoleRows = requestedModuleAssignments.map((assignment) => ({
      organization_module_id: assignment.organizationModuleId,
      user_id: userId,
      module_role_id: assignment.moduleRoleId,
      status: 'active',
      valid_from: now,
      assigned_at: now,
      assigned_by: actorUserId,
    }))

    const { error: moduleRoleError } = await adminClient
      .from('user_module_roles')
      .upsert(moduleRoleRows, {
        onConflict: 'organization_module_id,user_id,module_role_id',
      })

    if (moduleRoleError) {
      await rollback()
      return jsonResponse({ error: `Os perfis dos módulos não puderam ser atribuídos: ${moduleRoleError.message}` }, 500)
    }
  }

  const { error: auditError } = await adminClient
    .from('privileged_access_audit')
    .insert({
      actor_user_id: actorUserId,
      organization_id: organizationId,
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
        source: isSuperAdmin ? 'platform_admin' : 'organization_admin',
        created_without_invitation: true,
        change_reason: payload.changeReason?.trim() || null,
        organization_id: organizationId,
        platform_role_ids: platformRoleIds,
        platform_role_codes: selectedPlatformRoles.map((role) => role.code),
        module_role_assignments: requestedModuleAssignments,
        is_organization_admin: visitorSelected ? false : payload.isOrganizationAdmin === true,
        visitor_read_only: visitorSelected,
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
    organizationId,
    platformRoleIds,
    moduleRoleAssignments: requestedModuleAssignments,
    visitorReadOnly: visitorSelected,
  })
})
