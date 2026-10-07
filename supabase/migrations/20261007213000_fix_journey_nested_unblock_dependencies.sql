-- V1-B02: enforce Journey unblock dependencies cloned under template_metadata.
-- Preserve compatibility with legacy items that stored unblock_dependencies at top level.

create or replace function public.skpe_assert_journey_item_dependencies()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  dependency jsonb;
  dependencies jsonb;
  prerequisite_status text;
begin
  if new.status not in ('in_progress','pending_validation','completed') then
    return new;
  end if;

  dependencies := coalesce(
    new.metadata -> 'unblock_dependencies',
    new.metadata -> 'template_metadata' -> 'unblock_dependencies'
  );

  if jsonb_typeof(dependencies) is distinct from 'array' then
    return new;
  end if;

  for dependency in
    select value
    from jsonb_array_elements(dependencies)
  loop
    if coalesce(dependency->>'code','') = ''
       or coalesce(dependency->>'required_status','') = '' then
      raise exception using
        errcode='22023',
        message='Dependência metodológica da Jornada está incompleta.';
    end if;

    select status
      into prerequisite_status
    from public.skpe_journey_items
    where project_id=new.project_id
      and archived_at is null
      and code=dependency->>'code'
    limit 1;

    if prerequisite_status is distinct from dependency->>'required_status' then
      raise exception using
        errcode='55000',
        message=format(
          'Etapa %s não pode assumir status %s: depende de %s em status %s.',
          new.code,
          new.status,
          dependency->>'code',
          dependency->>'required_status'
        );
    end if;
  end loop;

  return new;
end;
$function$;
