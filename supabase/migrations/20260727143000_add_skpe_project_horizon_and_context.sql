-- ============================================================
-- SPARKs / SK-PE
-- Contexto do projeto e horizonte estratégico
-- COOTAQUARA: horizonte canônico 2026-2030
-- ============================================================

begin;

alter table public.skpe_projects
  add column if not exists planning_horizon_start_year integer,
  add column if not exists planning_horizon_end_year integer,
  add column if not exists reference_year integer,
  add column if not exists review_cycle text,
  add column if not exists valid_from date,
  add column if not exists valid_until date;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'skpe_projects_planning_horizon_check'
  ) then
    alter table public.skpe_projects
      add constraint skpe_projects_planning_horizon_check
      check (
        planning_horizon_start_year is null
        or planning_horizon_end_year is null
        or planning_horizon_end_year >= planning_horizon_start_year
      );
  end if;
end;
$$;

update public.skpe_projects p
set
  planning_horizon_start_year = 2026,
  planning_horizon_end_year = 2030,
  reference_year = 2026,
  review_cycle = 'Revisão anual',
  valid_from = date '2026-08-01',
  valid_until = date '2030-12-31',
  updated_at = timezone('utc', now())
from public.organizations o
where o.id = p.organization_id
  and o.code = 'COOTAQUARA'
  and p.archived_at is null;

create or replace function public.get_skpe_project_context(
  target_organization_id uuid
)
returns table (
  project_id uuid,
  project_code text,
  project_name text,
  project_status text,
  project_progress numeric,
  current_phase_code text,
  planning_horizon_start_year integer,
  planning_horizon_end_year integer,
  reference_year integer,
  review_cycle text,
  valid_from date,
  valid_until date
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.can_view_skpe_journey(target_organization_id) then
    raise exception
      'Acesso negado: o usuario nao pode consultar o contexto estrategico desta organizacao.'
      using errcode = '42501';
  end if;

  return query
  select
    p.id,
    p.code,
    p.name,
    p.status,
    p.progress,
    p.current_phase_code,
    p.planning_horizon_start_year,
    p.planning_horizon_end_year,
    p.reference_year,
    p.review_cycle,
    p.valid_from,
    p.valid_until
  from public.skpe_projects p
  where p.organization_id = target_organization_id
    and p.archived_at is null
  order by p.created_at desc
  limit 1;
end;
$$;

revoke all on function public.get_skpe_project_context(uuid) from public, anon;
grant execute on function public.get_skpe_project_context(uuid) to authenticated, service_role;

comment on function public.get_skpe_project_context(uuid) is
  'Retorna o contexto central do projeto estrategico, incluindo horizonte, ano-base, ciclo de revisao e validade.';

commit;
