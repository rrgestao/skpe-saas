-- Guard PEM-03.04 completion using canonical monitoring/governance readiness.
-- This migration does not assign owners, configure cadence, validate packages or create reviews.

create or replace function public.skpe_guard_pem0304_completion()
returns trigger
language plpgsql
security definer
set search_path=''
as $function$
declare
  readiness jsonb;
  formulation_id uuid;
begin
  if new.code<>'PEM-03.04' or new.status<>'completed' then
    return new;
  end if;

  select id into formulation_id
  from public.skpe_strategic_formulations
  where project_id=new.project_id
    and archived_at is null
  order by version_number desc
  limit 1;

  if formulation_id is null then
    raise exception using
      errcode='55000',
      message='PEM-03.04 não pode ser concluída sem Formulação Estratégica.';
  end if;

  readiness:=public.get_skpe_monitoring_package_readiness(formulation_id,true);

  if not coalesce((readiness->>'readyForFormulation')::boolean,false) then
    raise exception using
      errcode='55000',
      message='PEM-03.04 não pode ser concluída: a governança da execução ainda possui bloqueadores ou pacote não validado.';
  end if;

  new.metadata:=jsonb_set(
    coalesce(new.metadata,'{}'::jsonb),
    '{completionEvidence}',
    jsonb_build_object(
      'monitoringPackageId',readiness->>'packageId',
      'packageStatus',readiness->>'packageStatus',
      'readinessVerifiedAt',timezone('utc',now()),
      'readinessSnapshot',readiness
    ),
    true
  );

  return new;
end;
$function$;

drop trigger if exists skpe_pem0304_completion_guard
on public.skpe_journey_items;

create trigger skpe_pem0304_completion_guard
before update of status,progress
on public.skpe_journey_items
for each row
execute function public.skpe_guard_pem0304_completion();

comment on function public.skpe_guard_pem0304_completion() is
'Fail-closed completion guard for PEM-03.04. Requires canonical monitoring/governance readiness and a validated FE-08 package.';
