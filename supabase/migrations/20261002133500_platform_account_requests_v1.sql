create table if not exists public.platform_account_requests (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  email text not null,
  organization_name text,
  requested_role text,
  phone text,
  request_reason text,
  status text not null default 'pending'
    check (status in ('pending','approved','rejected','cancelled')),
  privacy_policy_version text not null,
  privacy_accepted_at timestamptz not null,
  source text not null default 'login',
  created_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid references auth.users(id),
  review_notes text
);create unique index if not exists platform_account_requests_pending_email_uidx
  on public.platform_account_requests (lower(email))
  where status = 'pending';

alter table public.platform_account_requests enable row level security;

revoke all on table public.platform_account_requests from anon, authenticated;

create or replace function public.submit_platform_account_request(
  p_full_name text,
  p_email text,
  p_organization_name text default null,
  p_requested_role text default null,
  p_phone text default null,
  p_request_reason text default null,
  p_privacy_policy_version text default 'SPARKS-PRIVACY-2026-10-02'
)
returns uuidlanguage plpgsql
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
  limit 1;  if v_id is not null then
    return v_id;
  end if;

  insert into public.platform_account_requests (
    full_name, email, organization_name, requested_role, phone,
    request_reason, privacy_policy_version, privacy_accepted_at, source
  )
  values (
    trim(p_full_name), v_email, nullif(trim(coalesce(p_organization_name,'')), ''),
    nullif(trim(coalesce(p_requested_role,'')), ''),
    nullif(trim(coalesce(p_phone,'')), ''),
    nullif(trim(coalesce(p_request_reason,'')), ''),
    p_privacy_policy_version, now(), 'login'
  )
  returning id into v_id;

  return v_id;
end;
$$;

grant execute on function public.submit_platform_account_request(
  text,text,text,text,text,text,text
) to anon, authenticated;