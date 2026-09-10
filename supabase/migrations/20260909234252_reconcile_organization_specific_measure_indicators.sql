alter table public.sparks_measure_organization_indicators
  alter column reference_catalog_id drop not null;

alter table public.sparks_measure_organization_indicators
  add column if not exists legacy_indicator_id uuid references public.skpe_indicators(id) on delete restrict;

alter table public.sparks_measure_organization_indicators
  drop constraint if exists sparks_measure_organization_i_organization_id_reference_cat_key;

create unique index if not exists ux_sparks_measure_org_indicator_catalog
  on public.sparks_measure_organization_indicators (organization_id, reference_catalog_id)
  where reference_catalog_id is not null;

create unique index if not exists ux_sparks_measure_org_indicator_legacy
  on public.sparks_measure_organization_indicators (organization_id, legacy_indicator_id)
  where legacy_indicator_id is not null;

alter table public.sparks_measure_organization_indicators
  drop constraint if exists sparks_measure_organization_indicator_origin_check;

alter table public.sparks_measure_organization_indicators
  add constraint sparks_measure_organization_indicator_origin_check
  check (reference_catalog_id is not null or legacy_indicator_id is not null);

create or replace function public.get_sparks_measure_organization_indicators(
  target_organization_id uuid
)
returns table(
  organization_indicator_id uuid,
  organization_id uuid,
  reference_catalog_id uuid,
  catalog_code text,
  version_number integer,
  name text,
  description text,
  formula_text text,
  unit text,
  polarity text,
  measurement_frequency text,
  indicator_category text,
  status text,
  reference_adaptation_notes text,
  usage_count bigint,
  usage_summary jsonb,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if auth.uid() is null then
    raise exception 'Usuário não autenticado.' using errcode = '42501';
  end if;

  if target_organization_id is null then
    raise exception 'Informe a organização.' using errcode = '22023';
  end if;

  if not (
    public.is_platform_super_admin()
    or public.is_organization_admin(target_organization_id)
  ) then
    raise exception 'Acesso negado: somente a Administração da Organização pode consultar os Indicadores da Organização.'
      using errcode = '42501';
  end if;

  return query
  select
    oi.id,
    oi.organization_id,
    oi.reference_catalog_id,
    coalesce(
      nullif(trim(oi.code_override), ''),
      rc.catalog_code,
      li.code
    ) as catalog_code,
    coalesce(rc.version_number, 1) as version_number,
    coalesce(
      nullif(trim(oi.name_override), ''),
      rc.name,
      li.name
    ) as name,
    coalesce(
      nullif(trim(oi.description_override), ''),
      rc.description,
      li.description
    ) as description,
    coalesce(
      nullif(trim(oi.formula_text_override), ''),
      rc.formula_text,
      li.formula_text
    ) as formula_text,
    coalesce(
      nullif(trim(oi.unit_override), ''),
      rc.unit,
      li.unit
    ) as unit,
    coalesce(
      nullif(trim(oi.polarity_override), ''),
      rc.polarity,
      li.polarity
    ) as polarity,
    coalesce(
      nullif(trim(oi.measurement_frequency_override), ''),
      rc.measurement_frequency,
      li.measurement_frequency
    ) as measurement_frequency,
    coalesce(rc.indicator_category, nullif(li.metadata->>'indicator_category', '')) as indicator_category,
    oi.status,
    oi.reference_adaptation_notes,
    coalesce(u.usage_count, 0)::bigint as usage_count,
    coalesce(u.usage_summary, '{}'::jsonb) as usage_summary,
    oi.updated_at
  from public.sparks_measure_organization_indicators oi
  left join public.skpe_indicator_reference_catalog rc
    on rc.id = oi.reference_catalog_id
  left join public.skpe_indicators li
    on li.id = oi.legacy_indicator_id
  left join lateral (
    select
      count(*)::bigint as usage_count,
      jsonb_build_object(
        'strategicObjectives', count(*) filter (where si.strategic_objective_id is not null),
        'keyResults', count(*) filter (where si.key_result_id is not null),
        'activeRecords', count(*) filter (where lower(trim(coalesce(si.status, 'draft'))) <> 'archived')
      ) as usage_summary
    from public.skpe_indicators si
    where si.organization_id = oi.organization_id
      and lower(trim(coalesce(si.status, 'draft'))) <> 'archived'
      and (
        (oi.reference_catalog_id is not null and si.reference_catalog_id = oi.reference_catalog_id)
        or (oi.legacy_indicator_id is not null and si.id = oi.legacy_indicator_id)
      )
  ) u on true
  where oi.organization_id = target_organization_id
    and oi.status = 'active'
  order by lower(coalesce(nullif(trim(oi.name_override), ''), rc.name, li.name)), coalesce(rc.catalog_code, li.code);
end;
$function$;

insert into public.sparks_measure_organization_indicators (
  organization_id,
  legacy_indicator_id,
  status,
  code_override,
  name_override,
  description_override,
  formula_text_override,
  unit_override,
  polarity_override,
  measurement_frequency_override,
  data_source_override,
  owner_user_id,
  reference_adaptation_notes,
  metadata,
  created_by,
  updated_by
)
select
  si.organization_id,
  si.id,
  'active',
  si.code,
  si.name,
  si.description,
  si.formula_text,
  si.unit,
  si.polarity,
  si.measurement_frequency,
  si.data_source,
  si.owner_user_id,
  'Indicador preexistente reconciliado com a camada organizacional; ainda sem associação a referência do Catálogo GERAL.',
  jsonb_build_object(
    'organizationSpecific', true,
    'legacyReconciled', true,
    'legacyIndicatorId', si.id,
    'sourceStatus', si.status,
    'reconciledAt', timezone('utc', now())
  ),
  auth.uid(),
  auth.uid()
from public.skpe_indicators si
where si.id = 'b234bd6c-cecf-42fc-b8c6-63c15812b9b5'::uuid
  and not exists (
    select 1
    from public.sparks_measure_organization_indicators oi
    where oi.organization_id = si.organization_id
      and oi.legacy_indicator_id = si.id
  );
