create or replace function public.get_platform_admin_user_organizational_roles(target_user_id uuid)
returns table(
  organization_id uuid,
  organization_code text,
  organization_name text,
  membership_id uuid,
  membership_status text,
  organization_person_id uuid,
  job_title text,
  role_id uuid,
  role_code text,
  role_name text,
  role_type text,
  organizational_area text,
  authority_level text,
  is_governance_role boolean,
  requires_mandate boolean,
  assigned boolean,
  assignment_id uuid,
  assignment_status text,
  mandate_start_date date,
  mandate_end_date date,
  appointment_document_reference text,
  appointment_document_id uuid,
  document_code text,
  document_title text,
  document_status text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public.require_platform_super_admin();

  return query
  select
    o.id,
    o.code,
    coalesce(o.trade_name, o.legal_name, o.code),
    om.id,
    om.status::text,
    sop.id,
    sop.job_title,
    r.id,
    r.code,
    r.name,
    r.role_type,
    r.organizational_area,
    r.authority_level,
    r.is_governance_role,
    r.requires_mandate,
    coalesce(current_assignment.assignment_status = 'active', false),
    current_assignment.id,
    current_assignment.assignment_status,
    current_assignment.mandate_start_date,
    current_assignment.mandate_end_date,
    current_assignment.appointment_document_reference,
    current_assignment.appointment_document_id,
    d.document_code,
    d.title,
    coalesce(d.document_status, current_assignment.appointment_document_status)
  from public.organization_memberships om
  join public.organizations o
    on o.id = om.organization_id
  join public.sparks_people sp
    on sp.profile_user_id = om.user_id
   and sp.archived_at is null
  join public.sparks_organization_people sop
    on sop.organization_id = om.organization_id
   and sop.person_id = sp.id
   and sop.status = 'active'
  join public.sparks_organizational_roles r
    on r.organization_id = om.organization_id
   and r.active = true
  left join lateral (
    select a.*
    from public.sparks_person_role_assignments a
    where a.organization_id = om.organization_id
      and a.organization_person_id = sop.id
      and a.organizational_role_id = r.id
    order by
      case when a.assignment_status = 'active' then 0 else 1 end,
      a.created_at desc
    limit 1
  ) current_assignment on true
  left join public.sparks_document_records d
    on d.id = current_assignment.appointment_document_id
  where om.user_id = target_user_id
    and om.status::text = 'active'
  order by
    lower(coalesce(o.trade_name, o.legal_name, o.code)),
    r.is_governance_role desc,
    lower(r.name);
end;
$$;

revoke all on function public.get_platform_admin_user_organizational_roles(uuid) from public;
revoke all on function public.get_platform_admin_user_organizational_roles(uuid) from anon;
grant execute on function public.get_platform_admin_user_organizational_roles(uuid) to authenticated;
grant execute on function public.get_platform_admin_user_organizational_roles(uuid) to service_role;
