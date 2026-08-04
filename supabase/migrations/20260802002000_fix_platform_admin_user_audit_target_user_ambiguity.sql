begin;

create or replace function public.get_platform_admin_user_audit(
  target_user_id uuid,
  limit_count integer default 100
)
returns table(
  audit_source text,
  audit_id uuid,
  occurred_at timestamp with time zone,
  actor_user_id uuid,
  actor_name text,
  actor_email text,
  organization_id uuid,
  organization_name text,
  event_type text,
  event_description text,
  entity_table text,
  entity_id text,
  details jsonb
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
<<fn>>
begin
  perform public.require_platform_super_admin();

  return query
  select
    consolidated.audit_source,
    consolidated.audit_id,
    consolidated.occurred_at,
    consolidated.actor_user_id,
    consolidated.actor_name,
    consolidated.actor_email,
    consolidated.organization_id,
    consolidated.organization_name,
    consolidated.event_type,
    consolidated.event_description,
    consolidated.entity_table,
    consolidated.entity_id,
    consolidated.details
  from (
    select
      'global'::text as audit_source,
      audit.id as audit_id,
      audit.occurred_at,
      audit.actor_user_id,
      coalesce(actor.display_name, actor.full_name, actor.email, 'Sistema') as actor_name,
      actor.email as actor_email,
      audit.organization_id,
      coalesce(org.trade_name, org.legal_name, org.code) as organization_name,
      audit.event_type,
      audit.event_description,
      audit.entity_table,
      audit.entity_id,
      jsonb_build_object(
        'previous_data', audit.previous_data,
        'new_data', audit.new_data,
        'metadata', audit.metadata
      ) as details
    from public.privileged_access_audit as audit
    left join public.profiles as actor on actor.id = audit.actor_user_id
    left join public.organizations as org on org.id = audit.organization_id
    where audit.entity_id = fn.target_user_id::text
       or audit.metadata ->> 'target_user_id' = fn.target_user_id::text
       or audit.metadata ->> 'user_id' = fn.target_user_id::text

    union all

    select
      'organizacao'::text as audit_source,
      access_audit.id as audit_id,
      access_audit.occurred_at,
      access_audit.actor_user_id,
      coalesce(actor.display_name, actor.full_name, actor.email, 'Sistema') as actor_name,
      actor.email as actor_email,
      access_audit.organization_id,
      coalesce(org.trade_name, org.legal_name, org.code) as organization_name,
      access_audit.action_code as event_type,
      access_audit.reason as event_description,
      'organization_access_audit'::text as entity_table,
      access_audit.target_user_id::text as entity_id,
      jsonb_build_object(
        'module_id', access_audit.module_id,
        'previous_data', access_audit.previous_data,
        'new_data', access_audit.new_data
      ) as details
    from public.organization_access_audit as access_audit
    left join public.profiles as actor on actor.id = access_audit.actor_user_id
    left join public.organizations as org on org.id = access_audit.organization_id
    where access_audit.target_user_id = fn.target_user_id
  ) as consolidated
  order by consolidated.occurred_at desc
  limit least(greatest(coalesce(fn.limit_count, 100), 1), 500);
end;
$function$;

comment on function public.get_platform_admin_user_audit(uuid, integer)
is 'Retorna auditoria global e organizacional de um usuario para SUPER-ADMIN, com parametros qualificados para evitar ambiguidade SQL.';

commit;