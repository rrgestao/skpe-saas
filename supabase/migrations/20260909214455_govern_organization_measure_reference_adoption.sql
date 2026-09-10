create table if not exists public.sparks_measure_organization_indicators (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  reference_catalog_id uuid not null references public.skpe_indicator_reference_catalog(id) on delete restrict,
  status text not null default 'active' check (status in ('active','archived')),
  code_override text,
  name_override text,
  description_override text,
  formula_text_override text,
  unit_override text,
  polarity_override text,
  measurement_frequency_override text,
  data_source_override text,
  owner_user_id uuid,
  reference_adaptation_notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid,
  unique (organization_id, reference_catalog_id)
);

alter table public.sparks_measure_organization_indicators enable row level security;

revoke all on table public.sparks_measure_organization_indicators from anon, authenticated;
grant select, insert, update, delete on table public.sparks_measure_organization_indicators to service_role;

create index if not exists idx_sparks_measure_org_indicators_org_status
  on public.sparks_measure_organization_indicators (organization_id, status);

create index if not exists idx_sparks_measure_org_indicators_reference
  on public.sparks_measure_organization_indicators (reference_catalog_id);

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
    coalesce(nullif(trim(oi.code_override), ''), rc.catalog_code),
    rc.version_number,
    coalesce(nullif(trim(oi.name_override), ''), rc.name),
    coalesce(nullif(trim(oi.description_override), ''), rc.description),
    coalesce(nullif(trim(oi.formula_text_override), ''), rc.formula_text),
    coalesce(nullif(trim(oi.unit_override), ''), rc.unit),
    coalesce(nullif(trim(oi.polarity_override), ''), rc.polarity),
    coalesce(nullif(trim(oi.measurement_frequency_override), ''), rc.measurement_frequency),
    rc.indicator_category,
    oi.status,
    oi.reference_adaptation_notes,
    coalesce(u.usage_count, 0)::bigint,
    coalesce(u.usage_summary, '{}'::jsonb),
    oi.updated_at
  from public.sparks_measure_organization_indicators oi
  join public.skpe_indicator_reference_catalog rc on rc.id = oi.reference_catalog_id
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
      and si.reference_catalog_id = oi.reference_catalog_id
      and lower(trim(coalesce(si.status, 'draft'))) <> 'archived'
  ) u on true
  where oi.organization_id = target_organization_id
    and oi.status = 'active'
  order by lower(coalesce(nullif(trim(oi.name_override), ''), rc.name)), rc.catalog_code;
end;
$function$;

create or replace function public.adopt_sparks_measure_references_for_organization(
  target_organization_id uuid,
  target_reference_catalog_ids uuid[],
  target_change_reason text
)
returns table(organization_indicator_id uuid, reference_catalog_id uuid)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  current_user_id uuid := auth.uid();
  reference_id uuid;
  adopted_id uuid;
  active_reference record;
begin
  if current_user_id is null then
    raise exception 'Usuário não autenticado.' using errcode = '42501';
  end if;

  if target_organization_id is null then
    raise exception 'Informe a organização.' using errcode = '22023';
  end if;

  if not (public.is_platform_super_admin() or public.is_organization_admin(target_organization_id)) then
    raise exception 'Acesso negado: somente a Administração da Organização pode adotar indicadores.'
      using errcode = '42501';
  end if;

  if coalesce(array_length(target_reference_catalog_ids, 1), 0) = 0 then
    raise exception 'Selecione ao menos um indicador do Catálogo GERAL.' using errcode = '22023';
  end if;

  if length(trim(coalesce(target_change_reason, ''))) = 0 then
    raise exception 'Informe o motivo da adoção organizacional.' using errcode = '22023';
  end if;

  foreach reference_id in array target_reference_catalog_ids loop
    select id, catalog_code, name, version_number
      into active_reference
    from public.skpe_indicator_reference_catalog
    where id = reference_id
      and is_current = true
      and lower(trim(coalesce(status, 'active'))) = 'active';

    if not found then
      raise exception 'Referência vigente do Catálogo GERAL não encontrada: %', reference_id
        using errcode = '22023';
    end if;

    insert into public.sparks_measure_organization_indicators (
      organization_id, reference_catalog_id, status, metadata, created_by, updated_by
    ) values (
      target_organization_id,
      reference_id,
      'active',
      jsonb_build_object(
        'organizationAdoption', true,
        'referenceCatalogCode', active_reference.catalog_code,
        'referenceCatalogVersion', active_reference.version_number,
        'adoptedAt', timezone('utc', now()),
        'adoptedBy', current_user_id,
        'changeReason', trim(target_change_reason)
      ),
      current_user_id,
      current_user_id
    )
    on conflict (organization_id, reference_catalog_id)
    do update set
      status = 'active',
      metadata = coalesce(public.sparks_measure_organization_indicators.metadata, '{}'::jsonb)
        || jsonb_build_object(
          'organizationAdoption', true,
          'referenceCatalogCode', active_reference.catalog_code,
          'referenceCatalogVersion', active_reference.version_number,
          'reactivatedAt', timezone('utc', now()),
          'reactivatedBy', current_user_id,
          'changeReason', trim(target_change_reason)
        ),
      updated_at = timezone('utc', now()),
      updated_by = current_user_id
    returning id into adopted_id;

    organization_indicator_id := adopted_id;
    reference_catalog_id := reference_id;
    return next;
  end loop;
end;
$function$;

create or replace function public.archive_sparks_measure_reference_adoptions_for_organization(
  target_organization_id uuid,
  target_reference_catalog_ids uuid[],
  target_change_reason text
)
returns table(organization_indicator_id uuid, reference_catalog_id uuid)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  current_user_id uuid := auth.uid();
  reference_id uuid;
  adoption_row public.sparks_measure_organization_indicators%rowtype;
  linked_count bigint;
begin
  if current_user_id is null then
    raise exception 'Usuário não autenticado.' using errcode = '42501';
  end if;

  if target_organization_id is null then
    raise exception 'Informe a organização.' using errcode = '22023';
  end if;

  if not (public.is_platform_super_admin() or public.is_organization_admin(target_organization_id)) then
    raise exception 'Acesso negado: somente a Administração da Organização pode retirar indicadores.'
      using errcode = '42501';
  end if;

  if coalesce(array_length(target_reference_catalog_ids, 1), 0) = 0 then
    raise exception 'Selecione ao menos um Indicador da Organização.' using errcode = '22023';
  end if;

  if length(trim(coalesce(target_change_reason, ''))) = 0 then
    raise exception 'Informe o motivo da retirada organizacional.' using errcode = '22023';
  end if;

  foreach reference_id in array target_reference_catalog_ids loop
    select * into adoption_row
    from public.sparks_measure_organization_indicators
    where organization_id = target_organization_id
      and reference_catalog_id = reference_id
      and status = 'active';

    if not found then
      continue;
    end if;

    select count(*) into linked_count
    from public.skpe_indicators si
    where si.organization_id = target_organization_id
      and si.reference_catalog_id = reference_id
      and lower(trim(coalesce(si.status, 'draft'))) <> 'archived';

    if linked_count > 0 then
      raise exception 'O indicador % possui % vínculo(s) contextual(is) ativo(s) e não pode ser retirado da Organização.', reference_id, linked_count
        using errcode = '23503';
    end if;

    update public.sparks_measure_organization_indicators
    set
      status = 'archived',
      metadata = coalesce(metadata, '{}'::jsonb)
        || jsonb_build_object(
          'archivedAt', timezone('utc', now()),
          'archivedBy', current_user_id,
          'archiveReason', trim(target_change_reason)
        ),
      updated_at = timezone('utc', now()),
      updated_by = current_user_id
    where id = adoption_row.id;

    organization_indicator_id := adoption_row.id;
    reference_catalog_id := reference_id;
    return next;
  end loop;
end;
$function$;

revoke all on function public.get_sparks_measure_organization_indicators(uuid) from public, anon;
revoke all on function public.adopt_sparks_measure_references_for_organization(uuid, uuid[], text) from public, anon;
revoke all on function public.archive_sparks_measure_reference_adoptions_for_organization(uuid, uuid[], text) from public, anon;

grant execute on function public.get_sparks_measure_organization_indicators(uuid) to authenticated, service_role;
grant execute on function public.adopt_sparks_measure_references_for_organization(uuid, uuid[], text) to authenticated, service_role;
grant execute on function public.archive_sparks_measure_reference_adoptions_for_organization(uuid, uuid[], text) to authenticated, service_role;
