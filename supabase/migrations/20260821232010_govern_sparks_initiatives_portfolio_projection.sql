-- ============================================================
-- Plataforma SPARKs / SK-PE-CONT-01
-- 17-B.5F.3C.6G-C2A.1
-- Convergencia Governada de Leitura do Portfolio
--
-- Autoridade:
--   public.sparks_initiatives
--
-- Garantias:
--   - somente leitura;
--   - nenhuma dependencia da tabela legada de iniciativas SK-PE;
--   - binding SK-PE somente como contexto especializado;
--   - nenhuma semantica de atraso/forecast (6H);
--   - nenhuma agenda/evento (6I);
--   - nenhum custo/esforco (6J).
-- ============================================================

begin;

create or replace function public.get_sparks_initiatives_portfolio(
  target_organization_id uuid,
  target_status text default null,
  target_initiative_class text default null,
  target_category_code text default null,
  target_source_module_code text default null
)
returns table (
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
as $$
begin
  if auth.uid() is null then
    raise exception
      'Operacao exige usuario autenticado.'
      using errcode = '42501';
  end if;

  if not public.can_read_organization(target_organization_id) then
    raise exception
      'Acesso negado: o usuario nao pode consultar as iniciativas desta organizacao.'
      using errcode = '42501';
  end if;

  return query
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
    select
      area_value.code,
      area_value.name
    from public.sparks_domain_values area_value
    join public.sparks_domains area_domain
      on area_domain.id = area_value.domain_id
     and area_domain.code = 'ORGANIZATIONAL_AREA'
     and area_domain.scope_type = 'organization'
     and area_domain.organization_id = si.organization_id
    where area_value.id = si.responsible_area_id
    limit 1
  ) responsible_area
    on true

  where si.organization_id = target_organization_id
    and si.archived_at is null

    and (
      target_status is null
      or si.status = lower(trim(target_status))
    )

    and (
      target_initiative_class is null
      or si.initiative_class = lower(trim(target_initiative_class))
    )

    and (
      target_category_code is null
      or category_value.code = lower(trim(target_category_code))
    )

    and (
      target_source_module_code is null
      or upper(si.source_module_code) =
         upper(trim(target_source_module_code))
    )

  order by
    case si.priority
      when 'critical' then 1
      when 'high' then 2
      when 'medium' then 3
      when 'low' then 4
      else 5
    end,
    si.target_end_date nulls last,
    si.created_at,
    si.code;
end;
$$;

revoke all
on function public.get_sparks_initiatives_portfolio(
  uuid, text, text, text, text
)
from public, anon;

grant execute
on function public.get_sparks_initiatives_portfolio(
  uuid, text, text, text, text
)
to authenticated, service_role;


create or replace function public.get_sparks_initiatives_portfolio_dashboard(
  target_organization_id uuid,
  target_status text default null,
  target_initiative_class text default null,
  target_category_code text default null,
  target_source_module_code text default null
)
returns table (
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
as $$
begin
  if auth.uid() is null then
    raise exception
      'Operacao exige usuario autenticado.'
      using errcode = '42501';
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
      where portfolio.initiative_status in (
        'proposed',
        'under_analysis',
        'approved',
        'planned'
      )
    )::bigint,

    count(*) filter (
      where portfolio.initiative_status = 'in_progress'
    )::bigint,

    count(*) filter (
      where portfolio.initiative_status = 'completed'
    )::bigint,

    count(*) filter (
      where portfolio.initiative_status = 'blocked'
    )::bigint,

    count(*) filter (
      where portfolio.priority = 'critical'
         or portfolio.criticality = 'critical'
         or portfolio.risk_level = 'critical'
         or portfolio.health_status = 'critical'
    )::bigint,

    coalesce(
      round(avg(portfolio.progress), 2),
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
$$;

revoke all
on function public.get_sparks_initiatives_portfolio_dashboard(
  uuid, text, text, text, text
)
from public, anon;

grant execute
on function public.get_sparks_initiatives_portfolio_dashboard(
  uuid, text, text, text, text
)
to authenticated, service_role;

comment on function public.get_sparks_initiatives_portfolio(
  uuid, text, text, text, text
) is
  'Projeta o portfolio organizacional transversal a partir de sparks_initiatives. Binding SK-PE e somente contexto especializado de leitura.';

comment on function public.get_sparks_initiatives_portfolio_dashboard(
  uuid, text, text, text, text
) is
  'Agrega metricas atuais do portfolio transversal sem atraso, forecast, agenda, custos ou esforco.';

commit;

