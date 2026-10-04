-- Guard PEM-03.03 completion using the canonical initiatives readiness contract.
-- This migration does not create, prioritize, validate or approve initiatives.

create or replace function public.skpe_guard_pem0303_completion()
returns trigger
language plpgsql
security definer
set search_path=''
as $function$
declare
  readiness jsonb;
  formulation_id uuid;
begin
  if new.code<>'PEM-03.03' or new.status<>'completed' then
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
      message='PEM-03.03 não pode ser concluída sem Formulação Estratégica.';
  end if;

  readiness:=public.get_skpe_initiatives_readiness(formulation_id,true);

  if not coalesce((readiness->>'readyForFormulation')::boolean,false) then
    raise exception using
      errcode='55000',
      message='PEM-03.03 não pode ser concluída: o portfólio de Iniciativas ainda possui bloqueadores ou pacote não validado.';
  end if;

  new.metadata:=jsonb_set(
    coalesce(new.metadata,'{}'::jsonb),
    '{completionEvidence}',
    jsonb_build_object(
      'packageStatus',readiness->>'packageStatus',
      'applicability',readiness->>'applicability',
      'readinessVerifiedAt',timezone('utc',now()),
      'readinessSnapshot',readiness
    ),
    true
  );

  return new;
end;
$function$;

drop trigger if exists skpe_pem0303_completion_guard
on public.skpe_journey_items;

create trigger skpe_pem0303_completion_guard
before update of status,progress
on public.skpe_journey_items
for each row
execute function public.skpe_guard_pem0303_completion();

comment on function public.skpe_guard_pem0303_completion() is
'Fail-closed completion guard for PEM-03.03. Reuses get_skpe_initiatives_readiness and requires the initiative portfolio to be content-ready and validated.';
