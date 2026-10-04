-- Completion contract for PEM-02.05.
-- A journey item cannot be completed until the validated strategic map
-- has a matching immutable official version and canonical readiness is clean.

create or replace function public.skpe_assert_pem0205_completion_ready()
returns trigger
language plpgsql
security definer
set search_path=''
as $function$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  package_row public.skpe_strategic_map_packages%rowtype;
  readiness jsonb;
  official_version public.skpe_strategic_map_versions%rowtype;
begin
  if new.code <> 'PEM-02.05'
     or new.status <> 'completed'
     or old.status = 'completed' then
    return new;
  end if;

  select * into formulation_row
  from public.skpe_strategic_formulations
  where project_id=new.project_id
    and archived_at is null
  order by
    case status
      when 'in_elaboration' then 1
      when 'draft' then 2
      when 'pending_validation' then 3
      when 'validated' then 4
      when 'approved' then 5
      else 9
    end,
    version_number desc
  limit 1;

  if formulation_row.id is null then
    raise exception using
      errcode='55000',
      message='PEM-02.05 não pode ser concluída: não existe Formulação Estratégica ativa para o projeto.';
  end if;

  select * into package_row
  from public.skpe_strategic_map_packages
  where formulation_id=formulation_row.id;

  if package_row.id is null or package_row.status <> 'validated' then
    raise exception using
      errcode='55000',
      message='PEM-02.05 não pode ser concluída: o Mapa Estratégico ainda não está validado.';
  end if;

  readiness:=public.get_skpe_strategic_map_readiness(formulation_row.id);

  if not coalesce((readiness->>'readyForFormulation')::boolean,false) then
    raise exception using
      errcode='55000',
      message='PEM-02.05 não pode ser concluída: o Mapa possui pendências de readiness.',
      detail=readiness::text;
  end if;

  select * into official_version
  from public.skpe_strategic_map_versions
  where formulation_id=formulation_row.id
    and package_id=package_row.id
  order by version_number desc
  limit 1;

  if official_version.id is null then
    raise exception using
      errcode='55000',
      message='PEM-02.05 não pode ser concluída: não existe versão oficial imutável do Mapa.';
  end if;

  if official_version.source_validated_at is distinct from package_row.validated_at then
    raise exception using
      errcode='55000',
      message='PEM-02.05 não pode ser concluída: a versão oficial não corresponde à validação atual do Mapa.';
  end if;

  new.metadata:=coalesce(new.metadata,'{}'::jsonb) || jsonb_build_object(
    'completionEvidence',jsonb_build_object(
      'strategicMapPackageId',package_row.id,
      'strategicMapVersionId',official_version.id,
      'strategicMapVersionNumber',official_version.version_number,
      'mapValidatedAt',package_row.validated_at,
      'readinessVerifiedAt',timezone('utc',now())
    )
  );

  return new;
end;
$function$;

drop trigger if exists skpe_pem0205_completion_readiness_guard
on public.skpe_journey_items;

create trigger skpe_pem0205_completion_readiness_guard
before update of status
on public.skpe_journey_items
for each row
execute function public.skpe_assert_pem0205_completion_ready();

revoke all on function public.skpe_assert_pem0205_completion_ready()
from public,anon,authenticated;

comment on function public.skpe_assert_pem0205_completion_ready() is
'Fail-closed completion gate for PEM-02.05: requires validated map, clean readiness and matching official immutable version.';
