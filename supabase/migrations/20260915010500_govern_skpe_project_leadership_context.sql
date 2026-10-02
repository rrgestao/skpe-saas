create or replace function public.get_skpe_project_leadership_context(
  target_organization_id uuid,
  target_project_id uuid
)
returns table(
  project_id uuid,
  active_lead_name text,
  active_lead_email text,
  organization_lead_name text,
  organization_lead_email text,
  sparkoop_lead_name text,
  sparkoop_lead_email text,
  leadership_model text,
  leadership_stage text,
  start_date date,
  target_end_date date,
  implementation_target_date date
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if not public.can_view_skpe_journey(target_organization_id) then
    raise exception
      'Acesso negado: o usuario nao pode consultar o contexto de lideranca deste projeto.'
      using errcode = '42501';
  end if;

  return query
  select
    p.id,
    nullif(trim(p.configuration ->> 'initiative_lead_name'), ''),
    nullif(trim(p.configuration ->> 'initiative_lead_email'), ''),
    nullif(trim(p.configuration ->> 'organization_lead_name'), ''),
    nullif(trim(p.configuration ->> 'organization_lead_email'), ''),
    nullif(trim(p.configuration ->> 'sparkoop_lead_name'), ''),
    nullif(trim(p.configuration ->> 'sparkoop_lead_email'), ''),
    nullif(trim(p.configuration ->> 'leadership_model'), ''),
    nullif(trim(p.configuration ->> 'leadership_stage'), ''),
    p.start_date,
    p.target_end_date,
    case
      when nullif(trim(p.configuration ->> 'implementation_target_date'), '') is not null
        then (p.configuration ->> 'implementation_target_date')::date
      else null
    end
  from public.skpe_projects p
  where p.id = target_project_id
    and p.organization_id = target_organization_id
    and p.archived_at is null;
end;
$function$;

grant execute on function public.get_skpe_project_leadership_context(uuid, uuid)
  to authenticated;
