-- Retry/idempotent companion for DEV migration history consistency.
-- The official Login policy acknowledgement is stored independently of the legacy privacy_* compatibility fields.

alter table public.platform_account_requests
  add column if not exists acknowledged_policy_code text,
  add column if not exists acknowledged_policy_revision text,
  add column if not exists acknowledged_policy_effective_date date,
  add column if not exists acknowledged_policy_version text,
  add column if not exists policy_acknowledged_at timestamptz;

create or replace function public.submit_platform_account_request_v2(
  p_full_name text,
  p_email text,
  p_organization_name text default null,
  p_requested_role text default null,
  p_phone text default null,
  p_request_reason text default null,
  p_policy_code text default 'POL-001',
  p_policy_revision text default '00',
  p_policy_effective_date date default '2025-01-08'::date,
  p_policy_version text default 'POL-001-R00-2025-01-08'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_email text := lower(trim(coalesce(p_email, '')));
begin
  if length(trim(coalesce(p_full_name, ''))) < 3 then
    raise exception 'Nome completo obrigatório.';
  end if;

  if v_email = '' or position('@' in v_email) = 0 then
    raise exception 'E-mail válido obrigatório.';
  end if;

  select id into v_id
  from public.platform_account_requests
  where lower(email) = v_email and status = 'pending'
  order by created_at desc
  limit 1;

  if v_id is not null then
    update public.platform_account_requests
    set acknowledged_policy_code = p_policy_code,
        acknowledged_policy_revision = p_policy_revision,
        acknowledged_policy_effective_date = p_policy_effective_date,
        acknowledged_policy_version = p_policy_version,
        policy_acknowledged_at = now(),
        privacy_policy_version = p_policy_version,
        privacy_accepted_at = now()
    where id = v_id;
    return v_id;
  end if;

  insert into public.platform_account_requests (
    full_name, email, organization_name, requested_role, phone,
    request_reason, privacy_policy_version, privacy_accepted_at, source,
    acknowledged_policy_code, acknowledged_policy_revision,
    acknowledged_policy_effective_date, acknowledged_policy_version,
    policy_acknowledged_at
  )
  values (
    trim(p_full_name), v_email,
    nullif(trim(coalesce(p_organization_name,'')), ''),
    nullif(trim(coalesce(p_requested_role,'')), ''),
    nullif(trim(coalesce(p_phone,'')), ''),
    nullif(trim(coalesce(p_request_reason,'')), ''),
    p_policy_version, now(), 'login',
    p_policy_code, p_policy_revision,
    p_policy_effective_date, p_policy_version, now()
  )
  returning id into v_id;

  return v_id;
end;
$$;

revoke all on function public.submit_platform_account_request_v2(text,text,text,text,text,text,text,text,date,text) from public;
grant execute on function public.submit_platform_account_request_v2(text,text,text,text,text,text,text,text,date,text) to anon, authenticated;
