-- SK-PE Gate 19.1.3
-- Converge the transversal SPARKs portfolio read model with governed SK-PE suggested drafts.

create or replace function public.get_sparks_initiatives_portfolio(
  target_organization_id uuid,
  target_status text default null::text,
  target_initiative_class text default null::text,
  target_category_code text default null::text,
  target_source_module_code text default null::text
)
returns table(
  initiative_id uuid,
  organization_id uuid,
  skpe_project_id uuid,
  category_id uuid,
  category_code text,
  category_name text,
  initiative_class text,
  initiative_code text,
  initiative_name text,
  initiative_description text,
  initiative_status text,
  priority text,
  criticality text,
  responsible_area_id uuid,
  responsible_area_code text,
  responsible_area_name text,
  proposal_origin text,
  source_module_code text,
  proposal_source_reference text,
  validation_status text,
  strategic_theme text,
  start_date date,
  target_end_date date,
  progress numeric,
  risk_level text,
  health_status text,
  last_update_at timestamptz,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.' using errcode = '42501';
  end if;

  if not public.can_read_organization(target_organization_id) then
    raise exception
      'Acesso negado: o usuario nao pode consultar as iniciativas desta organizacao.'
      using errcode = '42501';
  end if;

  return query
  with unified_portfolio(
    initiative_id, organization_id, skpe_project_id, category_id, category_code,
    category_name, initiative_class, initiative_code, initiative_name,
    initiative_description, initiative_status, priority, criticality,
    responsible_area_id, responsible_area_code, responsible_area_name,
    proposal_origin, source_module_code, proposal_source_reference,
    validation_status, strategic_theme, start_date, target_end_date, progress,
    risk_level, health_status, last_update_at, created_at, updated_at
  ) as (
    select
      si.id,
      si.organization_id,
      binding.skpe_project_id,
      si.category_id,
      category_value.code,
      category_value.name,
      si.initiative_class,
      si.code,
      si.name,
      si.description,
      si.status,
      si.priority,
      si.criticality,
      si.responsible_area_id,
      responsible_area.code,
      responsible_area.name,
      si.proposal_origin,
      si.source_module_code,
      si.proposal_source_reference,
      si.validation_status,
      si.strategic_theme,
      si.start_date,
      si.target_end_date,
      si.progress,
      si.risk_level,
      si.health_status,
      si.last_update_at,
      si.created_at,
      si.updated_at
    from public.sparks_initiatives si
    join public.sparks_domain_values category_value
      on category_value.id = si.category_id
    join public.sparks_domains category_domain
      on category_domain.id = category_value.domain_id
     and category_domain.code = 'INITIATIVE_CATEGORY'
     and (
       (
         category_domain.scope_type = 'global'
         and category_domain.organization_id is null
         and category_domain.module_code is null
       )
       or (
         category_domain.scope_type = 'organization'
         and category_domain.organization_id = si.organization_id
       )
     )
    left join public.skpe_project_initiative_bindings binding
      on binding.initiative_id = si.id
     and binding.organization_id = si.organization_id
     and binding.binding_type = 'strategic_plan_implementation'
    left join lateral (
      select area_value.code, area_value.name
      from public.sparks_domain_values area_value
      join public.sparks_domains area_domain
        on area_domain.id = area_value.domain_id
       and area_domain.code = 'ORGANIZATIONAL_AREA'
       and area_domain.scope_type = 'organization'
       and area_domain.organization_id = si.organization_id
      where area_value.id = si.responsible_area_id
      limit 1
    ) responsible_area on true
    where si.organization_id = target_organization_id
      and si.archived_at is null

    union all

    select
      ki.id,
      ki.organization_id,
      ki.project_id,
      null::uuid,
      'risk_mitigation'::text,
      'Mitigacao de Risco'::text,
      case ki.initiative_type
        when 'strategic_program' then 'program'
        when 'strategic_project' then 'project'
        when 'process_initiative' then 'process'
        when 'operational_improvement' then 'structuring_action'
        when 'simple_action' then 'task'
        else 'project'
      end,
      ki.code,
      ki.name,
      ki.description,
      ki.status,
      ki.priority,
      ki.criticality,
      ki.responsible_area_id,
      responsible_area.code,
      responsible_area.name,
      ki.proposal_origin,
      coalesce(nullif(btrim(ki.suggested_by_module), ''), 'SK-PE'),
      ki.proposal_source_reference,
      ki.validation_status,
      ki.strategic_theme,
      ki.start_date,
      ki.due_date,
      coalesce(ki.progress, 0::numeric),
      null::text,
      null::text,
      ki.updated_at,
      ki.created_at,
      ki.updated_at
    from public.skpe_initiatives ki
    left join lateral (
      select area_value.code, area_value.name
      from public.sparks_domain_values area_value
      join public.sparks_domains area_domain
        on area_domain.id = area_value.domain_id
       and area_domain.code = 'ORGANIZATIONAL_AREA'
       and area_domain.scope_type = 'organization'
       and area_domain.organization_id = ki.organization_id
      where area_value.id = ki.responsible_area_id
      limit 1
    ) responsible_area on true
    where ki.organization_id = target_organization_id
      and ki.archived_at is null
      and ki.proposal_origin = 'sparks_suggestion'
      and not exists (
        select 1
        from public.sparks_initiatives si2
        where si2.organization_id = ki.organization_id
          and si2.code = ki.code
          and si2.archived_at is null
      )
  )
  select
    p.initiative_id, p.organization_id, p.skpe_project_id, p.category_id,
    p.category_code, p.category_name, p.initiative_class, p.initiative_code,
    p.initiative_name, p.initiative_description, p.initiative_status,
    p.priority, p.criticality, p.responsible_area_id, p.responsible_area_code,
    p.responsible_area_name, p.proposal_origin, p.source_module_code,
    p.proposal_source_reference, p.validation_status, p.strategic_theme,
    p.start_date, p.target_end_date, p.progress, p.risk_level, p.health_status,
    p.last_update_at, p.created_at, p.updated_at
  from unified_portfolio p
  where (target_status is null or p.initiative_status = lower(trim(target_status)))
    and (
      target_initiative_class is null
      or p.initiative_class = lower(trim(target_initiative_class))
    )
    and (
      target_category_code is null
      or p.category_code = lower(trim(target_category_code))
    )
    and (
      target_source_module_code is null
      or upper(p.source_module_code) = upper(trim(target_source_module_code))
    )
  order by
    case p.priority
      when 'critical' then 1
      when 'high' then 2
      when 'medium' then 3
      when 'low' then 4
      else 5
    end,
    p.target_end_date nulls last,
    p.created_at,
    p.initiative_code;
end;
$function$;

create or replace function public.get_sparks_initiatives_portfolio_dashboard(
  target_organization_id uuid,
  target_status text default null::text,
  target_initiative_class text default null::text,
  target_category_code text default null::text,
  target_source_module_code text default null::text
)
returns table(
  total_initiatives bigint,
  proposed_count bigint,
  in_progress_count bigint,
  completed_count bigint,
  blocked_count bigint,
  critical_count bigint,
  average_progress numeric
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.' using errcode = '42501';
  end if;

  if not public.can_read_organization(target_organization_id) then
    raise exception
      'Acesso negado: o usuario nao pode consultar o painel de iniciativas desta organizacao.'
      using errcode = '42501';
  end if;

  return query
  select
    count(*)::bigint,
    count(*) filter (
      where portfolio.initiative_status in ('proposed','under_analysis','approved','planned')
    )::bigint,
    count(*) filter (where portfolio.initiative_status = 'in_progress')::bigint,
    count(*) filter (where portfolio.initiative_status = 'completed')::bigint,
    count(*) filter (where portfolio.initiative_status = 'blocked')::bigint,
    count(*) filter (
      where portfolio.priority = 'critical'
         or portfolio.criticality = 'critical'
         or portfolio.risk_level = 'critical'
         or portfolio.health_status = 'critical'
    )::bigint,
    coalesce(
      round(
        avg(portfolio.progress) filter (
          where portfolio.initiative_status not in ('proposed','under_analysis')
        ),
        2
      ),
      0
    )::numeric
  from public.get_sparks_initiatives_portfolio(
    target_organization_id,
    target_status,
    target_initiative_class,
    target_category_code,
    target_source_module_code
  ) portfolio;
end;
$function$;

comment on function public.get_sparks_initiatives_portfolio(uuid,text,text,text,text) is
  'Portfolio convergido: iniciativas transversais SPARKs mais sugestoes SK-PE em rascunho ainda nao promovidas.';

comment on function public.get_sparks_initiatives_portfolio_dashboard(uuid,text,text,text,text) is
  'Dashboard convergido: Total inclui rascunhos; progresso medio exclui proposed e under_analysis.';
