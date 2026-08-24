-- ============================================================
-- Plataforma SPARKs / SK-PE-CONT-01
-- 17-B.5F.3C.6G-C2B.3A
-- Governed Transversal Initiative Creation
--
-- Authority:
--   public.sparks_initiatives
--
-- Explicitly out of scope:
--   - skpe_initiatives;
--   - owner/sponsor responsibility assignment;
--   - SK-PE project/journey binding;
--   - 5W2H;
--   - instruments;
--   - delay/forecast (6H);
--   - agenda/events (6I);
--   - costs/benefits/effort (6J).
-- ============================================================

begin;

create or replace function public.create_sparks_initiative(
  target_organization_id uuid,
  target_initiative_class text,
  target_category_code text,
  target_code text,
  target_name text,
  target_description text default null,
  target_priority text default 'medium',
  target_criticality text default 'medium',
  target_responsible_area_id uuid default null,
  target_parent_initiative_id uuid default null,
  target_proposal_origin text default 'organization',
  target_source_module_code text default null,
  target_proposal_source_reference text default null,
  target_strategic_theme text default null,
  target_start_date date default null,
  target_end_date date default null,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_category_id uuid;
  v_initiative_id uuid;
  v_validation_status text;
  v_new_data jsonb;
begin
  if auth.uid() is null then
    raise exception
      'Operacao exige usuario autenticado.'
      using errcode = '42501';
  end if;

  if length(trim(coalesce(change_reason, ''))) < 10 then
    raise exception
      'Informe uma justificativa com pelo menos 10 caracteres.'
      using errcode = '22023';
  end if;

  if not exists (
    select 1
    from public.organizations organization_row
    where organization_row.id = target_organization_id
  ) then
    raise exception
      'Organizacao nao encontrada.'
      using errcode = '22023';
  end if;

  if not public.can_manage_sparks_initiatives(
    target_organization_id,
    target_source_module_code
  ) then
    raise exception
      'Acesso negado: o usuario nao pode criar iniciativas nesta organizacao.'
      using errcode = '42501';
  end if;

  if target_initiative_class not in (
    'program',
    'project',
    'initiative',
    'structuring_action'
  ) then
    raise exception
      'Classe de iniciativa invalida.'
      using errcode = '22023';
  end if;

  if target_priority not in (
    'low',
    'medium',
    'high',
    'critical'
  ) then
    raise exception
      'Prioridade invalida.'
      using errcode = '22023';
  end if;

  if target_criticality not in (
    'low',
    'medium',
    'high',
    'critical'
  ) then
    raise exception
      'Criticidade invalida.'
      using errcode = '22023';
  end if;

  if target_proposal_origin not in (
    'sparks_suggestion',
    'organization',
    'joint_construction',
    'previous_plan',
    'assessment',
    'action_plan',
    'bmc_vpc',
    'benchmark',
    'module',
    'import',
    'integration',
    'legacy'
  ) then
    raise exception
      'Origem da iniciativa invalida.'
      using errcode = '22023';
  end if;

  if length(trim(coalesce(target_code, ''))) = 0 then
    raise exception
      'Codigo da iniciativa e obrigatorio.'
      using errcode = '22023';
  end if;

  if length(trim(coalesce(target_name, ''))) = 0 then
    raise exception
      'Nome da iniciativa e obrigatorio.'
      using errcode = '22023';
  end if;

  if (
    target_start_date is not null
    and target_end_date is not null
    and target_end_date < target_start_date
  ) then
    raise exception
      'A data de termino-alvo nao pode ser anterior ao inicio.'
      using errcode = '22023';
  end if;

  select dv.id
  into v_category_id
  from public.sparks_domain_values dv
  join public.sparks_domains d
    on d.id = dv.domain_id
  where d.code = 'INITIATIVE_CATEGORY'
    and d.active
    and dv.active
    and dv.code = lower(trim(target_category_code))
    and (
      (
        d.scope_type = 'global'
        and d.organization_id is null
        and d.module_code is null
      )
      or (
        d.scope_type = 'organization'
        and d.organization_id = target_organization_id
      )
    )
  order by
    case when d.scope_type = 'organization' then 1 else 2 end
  limit 1;

  if v_category_id is null then
    raise exception
      'Categoria de iniciativa invalida ou inativa para esta organizacao.'
      using errcode = '22023';
  end if;

  if target_parent_initiative_id is not null
     and not exists (
       select 1
       from public.sparks_initiatives parent
       where parent.id = target_parent_initiative_id
         and parent.organization_id = target_organization_id
         and parent.archived_at is null
     ) then
    raise exception
      'Iniciativa-pai invalida para esta organizacao.'
      using errcode = '22023';
  end if;

  v_validation_status :=
    case
      when target_proposal_origin = 'organization'
        then 'not_required'
      else 'pending_validation'
    end;

  insert into public.sparks_initiatives (
    organization_id,
    parent_initiative_id,
    category_id,
    responsible_area_id,
    code,
    name,
    description,
    initiative_class,
    status,
    priority,
    criticality,
    strategic_theme,
    proposal_origin,
    source_module_code,
    proposal_source_reference,
    validation_status,
    start_date,
    target_end_date,
    progress,
    risk_level,
    health_status,
    last_update_at,
    created_by,
    updated_by
  )
  values (
    target_organization_id,
    target_parent_initiative_id,
    v_category_id,
    target_responsible_area_id,
    trim(target_code),
    trim(target_name),
    nullif(trim(target_description), ''),
    target_initiative_class,
    'proposed',
    target_priority,
    target_criticality,
    nullif(trim(target_strategic_theme), ''),
    target_proposal_origin,
    nullif(upper(trim(target_source_module_code)), ''),
    nullif(trim(target_proposal_source_reference), ''),
    v_validation_status,
    target_start_date,
    target_end_date,
    0,
    'not_assessed',
    'not_assessed',
    timezone('utc', now()),
    auth.uid(),
    auth.uid()
  )
  returning id into v_initiative_id;

  select to_jsonb(si)
  into v_new_data
  from public.sparks_initiatives si
  where si.id = v_initiative_id;

  insert into public.sparks_initiative_audit (
    organization_id,
    initiative_id,
    actor_user_id,
    source_module_code,
    action_code,
    change_reason,
    previous_data,
    new_data
  )
  values (
    target_organization_id,
    v_initiative_id,
    auth.uid(),
    nullif(upper(trim(target_source_module_code)), ''),
    'initiative.created',
    trim(change_reason),
    null,
    v_new_data
  );

  return v_initiative_id;
end;
$$;

revoke all
on function public.create_sparks_initiative(
  uuid, text, text, text, text, text,
  text, text, uuid, uuid, text, text,
  text, text, date, date, text
)
from public, anon;

grant execute
on function public.create_sparks_initiative(
  uuid, text, text, text, text, text,
  text, text, uuid, uuid, text, text,
  text, text, date, date, text
)
to authenticated, service_role;

comment on function public.create_sparks_initiative(
  uuid, text, text, text, text, text,
  text, text, uuid, uuid, text, text,
  text, text, date, date, text
) is
  'Cria uma iniciativa organizacional transversal governada. Nao cria identidade SK-PE, responsabilidades pessoais, instrumentos, 5W2H, custos, agenda ou forecast.';

commit;