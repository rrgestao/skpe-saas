begin;

create table if not exists public.sparks_document_records (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  document_code text not null,
  document_type text not null,
  title text not null,
  file_name text not null,
  mime_type text not null default 'text/html',
  document_source text not null default 'system_generated',
  document_status text not null default 'active',
  content_html text,
  content_json jsonb not null default '{}'::jsonb,
  related_entity_type text,
  related_entity_id uuid,
  formal_document_reference text,
  generated_at timestamptz not null default timezone('utc', now()),
  generated_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  constraint sparks_document_records_code_unique unique (organization_id, document_code),
  constraint sparks_document_records_source_check check (document_source in ('formal_reference','uploaded','system_generated')),
  constraint sparks_document_records_status_check check (document_status in ('draft','active','superseded','ended','archived'))
);

create index if not exists idx_sparks_document_records_org_type
  on public.sparks_document_records(organization_id, document_type, document_status);

alter table public.sparks_document_records enable row level security;

drop policy if exists sparks_document_records_select_policy on public.sparks_document_records;
create policy sparks_document_records_select_policy
on public.sparks_document_records
for select
to authenticated
using (public.can_view_skpe_governance(organization_id));

drop policy if exists sparks_document_records_manage_policy on public.sparks_document_records;
create policy sparks_document_records_manage_policy
on public.sparks_document_records
for all
to authenticated
using (public.can_manage_skpe_governance(organization_id))
with check (public.can_manage_skpe_governance(organization_id));

alter table public.sparks_person_role_assignments
  add column if not exists appointment_document_id uuid references public.sparks_document_records(id) on delete set null,
  add column if not exists appointment_document_source text,
  add column if not exists appointment_document_status text;

create index if not exists idx_sparks_person_role_assignments_document
  on public.sparks_person_role_assignments(appointment_document_id)
  where appointment_document_id is not null;

create or replace function public.sparks_html_escape(value text)
returns text
language sql
immutable
set search_path = ''
as $$
  select replace(replace(replace(replace(replace(coalesce(value, ''), '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;')
$$;

create or replace function public.assign_skpe_person_role(
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
as $$
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
  if not public.can_manage_skpe_governance(target_organization_id) then
    raise exception 'Acesso negado para atribuir papéis.';
  end if;

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
    and op.organization_id = target_organization_id;

  if person_name is null then
    raise exception 'Pessoa não vinculada à organização.';
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
  from public.sparks_person_role_assignments assignment where assignment.id = assignment_id;

  perform public.skpe_record_operational_audit(target_organization_id, null, 'person_role_assignment', assignment_id, 'assign', change_reason, null, new_record);

  return assignment_id;
end;
$$;

create or replace function public.get_skpe_person_role_assignments(
  target_organization_id uuid,
  include_inactive boolean default false
)
returns table (
  assignment_id uuid,
  organization_person_id uuid,
  person_name text,
  role_id uuid,
  role_name text,
  organizational_area text,
  mandate_start_date date,
  mandate_end_date date,
  indefinite_term boolean,
  assignment_status text,
  appointment_document_reference text,
  appointment_document_id uuid,
  document_code text,
  document_title text,
  document_file_name text,
  document_source text,
  document_status text,
  created_at timestamptz,
  registered_by text
)
language sql
security definer
set search_path = ''
as $$
  select
    a.id,
    a.organization_person_id,
    p.full_name,
    r.id,
    r.name,
    r.organizational_area,
    a.mandate_start_date,
    a.mandate_end_date,
    a.mandate_end_date is null,
    a.assignment_status,
    a.appointment_document_reference,
    a.appointment_document_id,
    d.document_code,
    d.title,
    d.file_name,
    coalesce(d.document_source, a.appointment_document_source),
    coalesce(d.document_status, a.appointment_document_status),
    a.created_at,
    coalesce(nullif(trim(au.raw_user_meta_data ->> 'full_name'), ''), nullif(trim(au.raw_user_meta_data ->> 'name'), ''), au.email, a.created_by::text)
  from public.sparks_person_role_assignments a
  join public.sparks_organization_people op on op.id = a.organization_person_id
  join public.sparks_people p on p.id = op.person_id
  join public.sparks_organizational_roles r on r.id = a.organizational_role_id
  left join public.sparks_document_records d on d.id = a.appointment_document_id
  left join auth.users au on au.id = a.created_by
  where a.organization_id = target_organization_id
    and public.can_view_skpe_governance(target_organization_id)
    and (include_inactive or a.assignment_status = 'active')
  order by a.created_at desc;
$$;

create or replace function public.get_sparks_document_record(target_document_id uuid)
returns table (
  document_id uuid,
  organization_id uuid,
  document_code text,
  document_type text,
  title text,
  file_name text,
  mime_type text,
  document_source text,
  document_status text,
  content_html text,
  content_json jsonb,
  generated_at timestamptz
)
language sql
security definer
set search_path = ''
as $$
  select d.id, d.organization_id, d.document_code, d.document_type, d.title,
         d.file_name, d.mime_type, d.document_source, d.document_status,
         d.content_html, d.content_json, d.generated_at
  from public.sparks_document_records d
  where d.id = target_document_id
    and public.can_view_skpe_governance(d.organization_id);
$$;

revoke all on public.sparks_document_records from anon;
grant select, insert, update on public.sparks_document_records to authenticated, service_role;
grant execute on function public.assign_skpe_person_role(uuid, uuid, uuid, date, date, text, text, text) to authenticated, service_role;
grant execute on function public.get_skpe_person_role_assignments(uuid, boolean) to authenticated, service_role;
grant execute on function public.get_sparks_document_record(uuid) to authenticated, service_role;

commit;
