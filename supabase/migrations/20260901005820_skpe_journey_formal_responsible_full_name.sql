create or replace function public.get_skpe_journey(target_organization_id uuid)
returns table(
  project_id uuid,
  project_code text,
  project_name text,
  project_status text,
  project_progress numeric,
  item_id uuid,
  parent_item_id uuid,
  item_type text,
  item_code text,
  item_name text,
  item_description text,
  item_status text,
  item_progress numeric,
  display_order integer,
  is_current boolean,
  responsible_user_id uuid,
  responsible_name text,
  planned_start_date date,
  planned_end_date date,
  validation_required boolean,
  validation_status text,
  blocked boolean,
  blocking_reason text
)
language plpgsql
stable
security definer
set search_path to ''
as $function$
begin
  if not public.can_view_skpe_journey(target_organization_id) then
    raise exception
      'Acesso negado: o usuario nao pode consultar a jornada estrategica desta organizacao.'
      using errcode = '42501';
  end if;

  return query
  select
    p.id,
    p.code,
    p.name,
    p.status,
    p.progress,
    i.id,
    i.parent_item_id,
    i.item_type,
    i.code,
    i.name,
    i.description,
    i.status,
    i.progress,
    i.display_order,
    i.is_current,
    i.responsible_user_id,
    coalesce(nullif(trim(pr.full_name), ''), nullif(trim(pr.display_name), ''), pr.email),
    i.planned_start_date,
    i.planned_end_date,
    i.validation_required,
    i.validation_status,
    i.blocked,
    i.blocking_reason
  from public.skpe_projects p
  join public.skpe_journey_items i
    on i.project_id = p.id
  left join public.profiles pr
    on pr.id = i.responsible_user_id
  where p.organization_id = target_organization_id
    and p.archived_at is null
    and i.archived_at is null
  order by p.created_at, i.display_order, i.code;
end;
$function$;
