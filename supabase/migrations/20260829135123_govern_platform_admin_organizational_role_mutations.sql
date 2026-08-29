create unique index if not exists ux_sparks_person_role_assignments_active
  on public.sparks_person_role_assignments (
    organization_id,
    organization_person_id,
    organizational_role_id
  )
  where assignment_status = 'active';

create or replace function public.sparks_assign_person_role_canonical(
  target_organization_id uuid,
  target_organization_person_id uuid,
  target_organizational_role_id uuid,
  target_mandate_start_date date,
  target_mandate_end_date date,
  target_appointment_document_reference text,
  target_notes text,
  change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  assignment_id uuid;
  generated_document_id uuid;
  generated_document_code text;
  generated_file_name text;
  organization_name text;
  person_name text;
  role_name text;
  role_area text;
  responsible_user text;
  generated_html text;
  new_record jsonb;
begin
  perform public.skpe_assert_reason(change_reason);

  select coalesce(nullif(trim(o.trade_name), ''), o.legal_name)
    into organization_name
  from public.organizations o
  where o.id = target_organization_id;

  select p.full_name
    into person_name
  from public.sparks_organization_people op
  join public.sparks_people p on p.id = op.person_id
  where op.id = target_organization_person_id
    and op.organization_id = target_organization_id
    and op.status = 'active';

  if person_name is null then
    raise exception 'Pessoa não vinculada ativamente à organização.';
  end if;

  select r.name, r.organizational_area
    into role_name, role_area
  from public.sparks_organizational_roles r
  where r.id = target_organizational_role_id
    and r.organization_id = target_organization_id
    and r.active;

  if role_name is null then
    raise exception 'Papel organizacional não encontrado ou inativo.';
  end if;

  if target_mandate_end_date is not null
     and target_mandate_start_date is not null
     and target_mandate_end_date < target_mandate_start_date then
    raise exception 'A data de término não pode ser anterior à data de início.';
  end if;

  if exists (
    select 1
    from public.sparks_person_role_assignments a
    where a.organization_id = target_organization_id
      and a.organization_person_id = target_organization_person_id
      and a.organizational_role_id = target_organizational_role_id
      and a.assignment_status = 'active'
  ) then
    raise exception 'Já existe uma atribuição ativa deste papel para esta pessoa na organização.'
      using errcode = '23505';
  end if;

  select coalesce(
    nullif(trim(au.raw_user_meta_data ->> 'full_name'), ''),
    nullif(trim(au.raw_user_meta_data ->> 'name'), ''),
    au.email,
    auth.uid()::text
  ) into responsible_user
  from auth.users au
  where au.id = auth.uid();

  insert into public.sparks_person_role_assignments (
    organization_id, organization_person_id, organizational_role_id,
    mandate_start_date, mandate_end_date, assignment_status,
    appointment_document_reference, appointment_document_source,
    appointment_document_status, notes, created_by, updated_by
  ) values (
    target_organization_id, target_organization_person_id, target_organizational_role_id,
    target_mandate_start_date, target_mandate_end_date, 'active',
    nullif(trim(target_appointment_document_reference), ''),
    case when nullif(trim(target_appointment_document_reference), '') is null then 'system_generated' else 'formal_reference' end,
    'active', nullif(trim(target_notes), ''), auth.uid(), auth.uid()
  ) returning id into assignment_id;

  if nullif(trim(target_appointment_document_reference), '') is null then
    generated_document_code := 'DES-' || to_char(timezone('utc', now()), 'YYYY') || '-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
    generated_file_name := regexp_replace(upper(coalesce(organization_name, 'ORGANIZACAO')), '[^A-Z0-9]+', '_', 'g') || '_' || generated_document_code || '.html';

    generated_html :=
      '<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><title>' || public.sparks_html_escape(generated_document_code) || '</title>' ||
      '<style>body{font-family:Arial,sans-serif;color:#1f2d27;max-width:900px;margin:40px auto;padding:0 28px;line-height:1.55}h1{font-size:24px;text-align:center}h2{font-size:16px;margin-top:28px}.meta{border:1px solid #cfdad5;border-radius:10px;padding:18px}.row{display:grid;grid-template-columns:220px 1fr;gap:12px;padding:7px 0;border-bottom:1px solid #edf1ef}.row:last-child{border-bottom:0}.label{font-weight:700;color:#3b564b}.notice{margin-top:28px;padding:16px;border-left:4px solid #176b53;background:#eef6f2}.footer{margin-top:34px;font-size:12px;color:#66756f}</style></head><body>' ||
      '<h1>TERMO DE REGISTRO DE DESIGNAÇÃO</h1>' ||
      '<div class="meta">' ||
      '<div class="row"><div class="label">Organização</div><div>' || public.sparks_html_escape(organization_name) || '</div></div>' ||
      '<div class="row"><div class="label">Pessoa designada</div><div>' || public.sparks_html_escape(person_name) || '</div></div>' ||
      '<div class="row"><div class="label">Papel organizacional</div><div>' || public.sparks_html_escape(role_name) || '</div></div>' ||
      '<div class="row"><div class="label">Área ou instância</div><div>' || public.sparks_html_escape(coalesce(role_area, 'Não informada')) || '</div></div>' ||
      '<div class="row"><div class="label">Início do mandato</div><div>' || coalesce(to_char(target_mandate_start_date, 'DD/MM/YYYY'), 'Não informado') || '</div></div>' ||
      '<div class="row"><div class="label">Término do mandato</div><div>' || coalesce(to_char(target_mandate_end_date, 'DD/MM/YYYY'), 'Prazo indeterminado') || '</div></div>' ||
      '<div class="row"><div class="label">Documento formal de origem</div><div>Não informado</div></div>' ||
      '<div class="row"><div class="label">Responsável pelo registro</div><div>' || public.sparks_html_escape(responsible_user) || '</div></div>' ||
      '<div class="row"><div class="label">Data e horário do registro</div><div>' || to_char(timezone('America/Sao_Paulo', now()), 'DD/MM/YYYY HH24:MI:SS') || ' (horário de Brasília)</div></div>' ||
      '<div class="row"><div class="label">Justificativa</div><div>' || public.sparks_html_escape(change_reason) || '</div></div>' ||
      '<div class="row"><div class="label">Identificador</div><div>' || public.sparks_html_escape(generated_document_code) || '</div></div>' ||
      '</div>' ||
      '<div class="notice"><strong>Natureza deste registro.</strong> Este documento registra no sistema a designação informada pela organização. Não substitui ata, resolução, portaria, contrato, termo de posse ou outro ato formal quando estes forem legalmente, estatutariamente ou normativamente exigidos.</div>' ||
      '<div class="footer">Documento gerado automaticamente pela Plataforma SPARKs. O registro estruturado e a trilha de auditoria permanecem preservados no acervo documental.</div>' ||
      '</body></html>';

    insert into public.sparks_document_records (
      organization_id, document_code, document_type, title, file_name,
      mime_type, document_source, document_status, content_html, content_json,
      related_entity_type, related_entity_id, generated_by, created_by, updated_by,
      metadata
    ) values (
      target_organization_id, generated_document_code, 'designation_record',
      'Termo de Registro de Designação — ' || person_name || ' — ' || role_name,
      generated_file_name, 'text/html', 'system_generated', 'active', generated_html,
      jsonb_build_object(
        'organization_name', organization_name,
        'person_name', person_name,
        'role_name', role_name,
        'organizational_area', role_area,
        'mandate_start_date', target_mandate_start_date,
        'mandate_end_date', target_mandate_end_date,
        'indefinite_term', target_mandate_end_date is null,
        'registered_by', responsible_user,
        'registered_at', timezone('utc', now()),
        'change_reason', change_reason
      ),
      'person_role_assignment', assignment_id, auth.uid(), auth.uid(), auth.uid(),
      jsonb_build_object('archive_class', 'governance', 'access_level', 'institutional')
    ) returning id into generated_document_id;

    update public.sparks_person_role_assignments
       set appointment_document_id = generated_document_id,
           appointment_document_reference = generated_document_code,
           updated_by = auth.uid()
     where id = assignment_id;
  end if;

  select to_jsonb(assignment) into new_record
  from public.sparks_person_role_assignments assignment
  where assignment.id = assignment_id;

  perform public.skpe_record_operational_audit(
    target_organization_id, null, 'person_role_assignment', assignment_id,
    'assign', change_reason, null, new_record
  );

  return assignment_id;
end;
$function$;

revoke all on function public.sparks_assign_person_role_canonical(uuid, uuid, uuid, date, date, text, text, text) from public, anon, authenticated, service_role;

create or replace function public.sparks_revoke_person_role_canonical(
  target_assignment_id uuid,
  change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  assignment_record public.sparks_person_role_assignments%rowtype;
  previous_record jsonb;
  new_record jsonb;
begin
  perform public.skpe_assert_reason(change_reason);

  select *
    into assignment_record
  from public.sparks_person_role_assignments
  where id = target_assignment_id
  for update;

  if assignment_record.id is null then
    raise exception 'Atribuição de papel não encontrada.';
  end if;

  if assignment_record.assignment_status <> 'active' then
    raise exception 'Somente uma atribuição ativa pode ser revogada.';
  end if;

  previous_record := to_jsonb(assignment_record);

  update public.sparks_person_role_assignments
  set assignment_status = 'revoked',
      updated_at = timezone('utc', now()),
      updated_by = auth.uid(),
      metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
        'revoked_at', timezone('utc', now()),
        'revoked_by', auth.uid(),
        'revocation_reason', change_reason
      )
  where id = target_assignment_id;

  select to_jsonb(assignment) into new_record
  from public.sparks_person_role_assignments assignment
  where assignment.id = target_assignment_id;

  perform public.skpe_record_operational_audit(
    assignment_record.organization_id, null, 'person_role_assignment', target_assignment_id,
    'revoke', change_reason, previous_record, new_record
  );

  return target_assignment_id;
end;
$function$;

revoke all on function public.sparks_revoke_person_role_canonical(uuid, text) from public, anon, authenticated, service_role;

create or replace function public.assign_skpe_person_role(
  target_organization_id uuid,
  target_organization_person_id uuid,
  target_organizational_role_id uuid,
  target_mandate_start_date date default null,
  target_mandate_end_date date default null,
  target_appointment_document_reference text default null,
  target_notes text default null,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if not public.can_manage_skpe_governance(target_organization_id) then
    raise exception 'Acesso negado para atribuir papéis.';
  end if;

  return public.sparks_assign_person_role_canonical(
    target_organization_id,
    target_organization_person_id,
    target_organizational_role_id,
    target_mandate_start_date,
    target_mandate_end_date,
    target_appointment_document_reference,
    target_notes,
    change_reason
  );
end;
$function$;

grant execute on function public.assign_skpe_person_role(uuid, uuid, uuid, date, date, text, text, text) to anon, authenticated, service_role;

create or replace function public.revoke_skpe_person_role(
  target_assignment_id uuid,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  target_organization_id uuid;
begin
  select organization_id
    into target_organization_id
  from public.sparks_person_role_assignments
  where id = target_assignment_id;

  if target_organization_id is null then
    raise exception 'Atribuição de papel não encontrada.';
  end if;

  if not public.can_manage_skpe_governance(target_organization_id) then
    raise exception 'Acesso negado para revogar papéis.';
  end if;

  return public.sparks_revoke_person_role_canonical(target_assignment_id, change_reason);
end;
$function$;

grant execute on function public.revoke_skpe_person_role(uuid, text) to authenticated, service_role;
revoke execute on function public.revoke_skpe_person_role(uuid, text) from anon;

create or replace function public.set_platform_admin_user_organizational_role(
  target_user_id uuid,
  target_organization_id uuid,
  target_organizational_role_id uuid,
  input_assigned boolean,
  input_mandate_start_date date default null,
  input_mandate_end_date date default null,
  input_appointment_document_reference text default null,
  input_notes text default null,
  input_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  selected_organization_person_id uuid;
  selected_assignment_id uuid;
  previous_assignment jsonb;
  resulting_assignment jsonb;
begin
  perform public.require_platform_super_admin();
  perform public.skpe_assert_reason(input_reason);

  select sop.id
    into selected_organization_person_id
  from public.organization_memberships om
  join public.sparks_people sp
    on sp.profile_user_id = om.user_id
   and sp.archived_at is null
  join public.sparks_organization_people sop
    on sop.organization_id = om.organization_id
   and sop.person_id = sp.id
   and sop.status = 'active'
  where om.user_id = target_user_id
    and om.organization_id = target_organization_id
    and om.status::text = 'active'
  order by sop.created_at
  limit 1;

  if selected_organization_person_id is null then
    raise exception 'O usuário precisa possuir identidade canônica ativa na organização.';
  end if;

  if input_assigned then
    select to_jsonb(a), a.id
      into previous_assignment, selected_assignment_id
    from public.sparks_person_role_assignments a
    where a.organization_id = target_organization_id
      and a.organization_person_id = selected_organization_person_id
      and a.organizational_role_id = target_organizational_role_id
      and a.assignment_status = 'active'
    limit 1;

    if selected_assignment_id is null then
      selected_assignment_id := public.sparks_assign_person_role_canonical(
        target_organization_id,
        selected_organization_person_id,
        target_organizational_role_id,
        input_mandate_start_date,
        input_mandate_end_date,
        input_appointment_document_reference,
        input_notes,
        input_reason
      );
    end if;
  else
    select to_jsonb(a), a.id
      into previous_assignment, selected_assignment_id
    from public.sparks_person_role_assignments a
    where a.organization_id = target_organization_id
      and a.organization_person_id = selected_organization_person_id
      and a.organizational_role_id = target_organizational_role_id
      and a.assignment_status = 'active'
    order by a.created_at desc
    limit 1;

    if selected_assignment_id is not null then
      perform public.sparks_revoke_person_role_canonical(selected_assignment_id, input_reason);
    end if;
  end if;

  if selected_assignment_id is not null then
    select to_jsonb(a)
      into resulting_assignment
    from public.sparks_person_role_assignments a
    where a.id = selected_assignment_id;
  end if;

  insert into public.privileged_access_audit (
    actor_user_id,
    organization_id,
    event_type,
    event_description,
    entity_schema,
    entity_table,
    entity_id,
    previous_data,
    new_data,
    metadata
  ) values (
    auth.uid(),
    target_organization_id,
    'configuration_changed',
    input_reason,
    'public',
    'sparks_person_role_assignments',
    coalesce(selected_assignment_id::text, target_user_id::text),
    previous_assignment,
    resulting_assignment,
    jsonb_build_object(
      'source', 'platform_admin',
      'target_user_id', target_user_id,
      'organization_person_id', selected_organization_person_id,
      'organizational_role_id', target_organizational_role_id,
      'assigned', input_assigned
    )
  );
end;
$function$;

grant execute on function public.set_platform_admin_user_organizational_role(uuid, uuid, uuid, boolean, date, date, text, text, text) to anon, authenticated, service_role;