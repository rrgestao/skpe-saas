-- Govern the sequential dependency chain of PEM-02 for every SK-PE project.
-- This migration changes methodology/dependency contracts only.
-- It does not complete, approve or advance any journey item.

create or replace function public.skpe_assert_journey_item_dependencies()
returns trigger
language plpgsql
security definer
set search_path=''
as $function$
declare
  dependency jsonb;
  prerequisite_status text;
begin
  if new.status not in ('in_progress','pending_validation','completed') then
    return new;
  end if;

  if jsonb_typeof(coalesce(new.metadata,'{}'::jsonb)->'unblock_dependencies') <> 'array' then
    return new;
  end if;

  for dependency in
    select value
    from jsonb_array_elements(new.metadata->'unblock_dependencies')
  loop
    if coalesce(dependency->>'code','') = ''
       or coalesce(dependency->>'required_status','') = '' then
      raise exception using
        errcode='22023',
        message='Dependencia metodologica da Jornada esta incompleta.';
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
          'Etapa %s nao pode assumir status %s: depende de %s em status %s.',
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

drop trigger if exists skpe_journey_items_dependency_guard
  on public.skpe_journey_items;

create trigger skpe_journey_items_dependency_guard
before update of status,progress
on public.skpe_journey_items
for each row
execute function public.skpe_assert_journey_item_dependencies();

-- Complete sequential contract for PEM-02.
update public.skpe_methodology_template_items
set metadata=jsonb_set(
  coalesce(metadata,'{}'::jsonb),
  '{unblock_dependencies}',
  case code
    when 'PEM-02.02' then '[{"code":"PEM-02.01","required_status":"completed"}]'::jsonb
    when 'PEM-02.03' then '[{"code":"PEM-02.02","required_status":"completed"}]'::jsonb
    when 'PEM-02.04' then '[{"code":"PEM-02.03","required_status":"completed"}]'::jsonb
    when 'PEM-02.05' then '[{"code":"PEM-02.04","required_status":"completed"}]'::jsonb
    when 'PEM-02.GATE' then '[{"code":"PEM-02.05","required_status":"completed"}]'::jsonb
  end,
  true
)
where code in ('PEM-02.02','PEM-02.03','PEM-02.04','PEM-02.05','PEM-02.GATE');

update public.skpe_journey_items
set metadata=jsonb_set(
  coalesce(metadata,'{}'::jsonb),
  '{unblock_dependencies}',
  case code
    when 'PEM-02.02' then '[{"code":"PEM-02.01","required_status":"completed"}]'::jsonb
    when 'PEM-02.03' then '[{"code":"PEM-02.02","required_status":"completed"}]'::jsonb
    when 'PEM-02.04' then '[{"code":"PEM-02.03","required_status":"completed"}]'::jsonb
    when 'PEM-02.05' then '[{"code":"PEM-02.04","required_status":"completed"}]'::jsonb
    when 'PEM-02.GATE' then '[{"code":"PEM-02.05","required_status":"completed"}]'::jsonb
  end,
  true
),
updated_at=timezone('utc',now())
where archived_at is null
  and code in ('PEM-02.02','PEM-02.03','PEM-02.04','PEM-02.05','PEM-02.GATE');

revoke all on function public.skpe_assert_journey_item_dependencies()
  from public,anon,authenticated;

comment on function public.skpe_assert_journey_item_dependencies() is
'Fail-closed guard for SK-PE journey transitions. An item cannot enter in_progress, pending_validation or completed until every metadata.unblock_dependencies prerequisite has the required status.';
