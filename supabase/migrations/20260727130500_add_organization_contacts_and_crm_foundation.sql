begin;

alter table public.sparks_people
  add column if not exists mobile_phone text,
  add column if not exists secondary_email text;

alter table public.sparks_people
  drop constraint if exists sparks_people_primary_phone_format_check;
alter table public.sparks_people
  add constraint sparks_people_primary_phone_format_check
  check (primary_phone is null or primary_phone ~ '^[0-9]{10}$');

alter table public.sparks_people
  drop constraint if exists sparks_people_mobile_phone_format_check;
alter table public.sparks_people
  add constraint sparks_people_mobile_phone_format_check
  check (mobile_phone is null or mobile_phone ~ '^[0-9]{11}$');

alter table public.sparks_organization_people
  add column if not exists is_organization_contact boolean not null default false,
  add column if not exists is_primary_contact boolean not null default false,
  add column if not exists contact_function text,
  add column if not exists crm_sync_status text not null default 'not_integrated',
  add column if not exists crm_external_id text,
  add column if not exists last_crm_sync_at timestamptz;

alter table public.sparks_organization_people
  drop constraint if exists sparks_organization_people_crm_status_check;
alter table public.sparks_organization_people
  add constraint sparks_organization_people_crm_status_check
  check (crm_sync_status in ('not_integrated','pending','synchronized','error','disabled'));

create unique index if not exists idx_sparks_org_people_one_primary_contact
  on public.sparks_organization_people(organization_id)
  where is_primary_contact and status = 'active';

create index if not exists idx_sparks_org_people_contacts
  on public.sparks_organization_people(organization_id, is_organization_contact, status);

create or replace function public.get_sparks_organization_contacts(
  target_organization_id uuid
)
returns table (
  organization_person_id uuid,
  person_id uuid,
  full_name text,
  contact_function text,
  job_title text,
  phone text,
  mobile_phone text,
  email text,
  is_primary_contact boolean,
  status text,
  crm_sync_status text
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not (
    public.is_organization_member(target_organization_id)
    or public.is_organization_admin(target_organization_id)
  ) then
    raise exception 'Acesso negado aos contatos desta organização.';
  end if;

  return query
  select
    op.id,
    p.id,
    p.full_name::text,
    coalesce(op.contact_function, op.job_title)::text,
    op.job_title::text,
    p.primary_phone::text,
    p.mobile_phone::text,
    p.primary_email::text,
    op.is_primary_contact,
    op.status::text,
    op.crm_sync_status::text
  from public.sparks_organization_people op
  join public.sparks_people p on p.id = op.person_id
  where op.organization_id = target_organization_id
    and op.is_organization_contact = true
    and p.archived_at is null
  order by op.is_primary_contact desc, p.full_name;
end;
$$;

create or replace function public.upsert_sparks_organization_contact(
  target_organization_id uuid,
  target_organization_person_id uuid,
  target_full_name text,
  target_contact_function text,
  target_phone text,
  target_mobile_phone text,
  target_email text,
  target_is_primary_contact boolean,
  change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  target_person_id uuid;
  result_id uuid;
begin
  if not public.is_organization_admin(target_organization_id) then
    raise exception 'Acesso negado: somente administradores podem alterar contatos.';
  end if;
  if length(trim(coalesce(target_full_name,''))) < 3 then
    raise exception 'Informe o nome completo do contato.';
  end if;
  if length(trim(coalesce(change_reason,''))) < 10 then
    raise exception 'A justificativa deve ter pelo menos 10 caracteres.';
  end if;
  if target_phone is not null and regexp_replace(target_phone, '\D', '', 'g') !~ '^[0-9]{10}$' then
    raise exception 'Telefone inválido. Informe DDD e 8 dígitos.';
  end if;
  if target_mobile_phone is not null and regexp_replace(target_mobile_phone, '\D', '', 'g') !~ '^[0-9]{11}$' then
    raise exception 'Celular inválido. Informe DDD e 9 dígitos.';
  end if;

  if target_is_primary_contact then
    update public.sparks_organization_people
       set is_primary_contact = false,
           updated_by = auth.uid()
     where organization_id = target_organization_id
       and is_primary_contact = true
       and (target_organization_person_id is null or id <> target_organization_person_id);
  end if;

  if target_organization_person_id is null then
    insert into public.sparks_people(
      full_name, primary_email, primary_phone, mobile_phone,
      data_source, created_by, updated_by
    ) values (
      trim(target_full_name), nullif(lower(trim(target_email)), ''),
      nullif(regexp_replace(target_phone, '\D', '', 'g'), ''),
      nullif(regexp_replace(target_mobile_phone, '\D', '', 'g'), ''),
      'sk_asm', auth.uid(), auth.uid()
    ) returning id into target_person_id;

    insert into public.sparks_organization_people(
      organization_id, person_id, relationship_type, job_title,
      contact_function, status, is_organization_contact,
      is_primary_contact, created_by, updated_by
    ) values (
      target_organization_id, target_person_id, 'representative',
      nullif(trim(target_contact_function), ''),
      nullif(trim(target_contact_function), ''), 'active', true,
      target_is_primary_contact, auth.uid(), auth.uid()
    ) returning id into result_id;
  else
    select person_id into target_person_id
      from public.sparks_organization_people
     where id = target_organization_person_id
       and organization_id = target_organization_id;
    if target_person_id is null then
      raise exception 'Contato não encontrado nesta organização.';
    end if;

    update public.sparks_people
       set full_name = trim(target_full_name),
           primary_email = nullif(lower(trim(target_email)), ''),
           primary_phone = nullif(regexp_replace(target_phone, '\D', '', 'g'), ''),
           mobile_phone = nullif(regexp_replace(target_mobile_phone, '\D', '', 'g'), ''),
           updated_by = auth.uid()
     where id = target_person_id;

    update public.sparks_organization_people
       set job_title = nullif(trim(target_contact_function), ''),
           contact_function = nullif(trim(target_contact_function), ''),
           is_organization_contact = true,
           is_primary_contact = target_is_primary_contact,
           updated_by = auth.uid()
     where id = target_organization_person_id
     returning id into result_id;
  end if;

  return result_id;
end;
$$;

revoke all on function public.get_sparks_organization_contacts(uuid) from public, anon;
revoke all on function public.upsert_sparks_organization_contact(uuid,uuid,text,text,text,text,text,boolean,text) from public, anon;
grant execute on function public.get_sparks_organization_contacts(uuid) to authenticated, service_role;
grant execute on function public.upsert_sparks_organization_contact(uuid,uuid,text,text,text,text,text,boolean,text) to authenticated, service_role;

commit;
