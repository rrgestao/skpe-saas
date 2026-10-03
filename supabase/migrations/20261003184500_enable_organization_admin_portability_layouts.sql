-- SK-PE - Organization-admin portability access
-- Layout catalog is global, non-sensitive metadata.
-- Allow authenticated users to read active portability layouts while
-- all organization-scoped operations remain protected by governance RPCs.

create or replace function public.get_portability_layouts(
  target_module_code text default null::text,
  target_direction text default null::text
)
returns table(
  layout_id uuid,
  module_code text,
  layout_code text,
  layout_name text,
  layout_version text,
  file_type text,
  direction text,
  description text,
  minimum_platform_version text,
  active boolean
)
language sql
security definer
set search_path to 'public'
as $function$
  select
    l.id,
    l.module_code,
    l.layout_code,
    l.layout_name,
    l.layout_version,
    l.file_type,
    l.direction,
    l.description,
    l.minimum_platform_version,
    l.active
  from public.sparks_portability_layouts l
  where (target_module_code is null or l.module_code = target_module_code)
    and (target_direction is null or l.direction in (target_direction, 'both'))
    and (auth.uid() is not null or auth.role() = 'service_role')
  order by l.layout_name asc, l.layout_version desc;
$function$;

revoke all on function public.get_portability_layouts(text, text) from public;
grant execute on function public.get_portability_layouts(text, text) to authenticated;
grant execute on function public.get_portability_layouts(text, text) to service_role;
