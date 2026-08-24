-- ============================================================
-- Plataforma SPARKs / SK-PE-CONT-01
-- 17-B.5F.3C.6G-C2B.5C.2
-- Governed Parent Initiative Selection
--
-- Authority:
--   public.sparks_initiatives
--
-- Eligibility intentionally mirrors create_sparks_initiative:
--   - same organization;
--   - archived_at is null.
--
-- Explicitly NOT filtered by:
--   - portfolio UI filters;
--   - source module;
--   - category;
--   - initiative class;
--   - lifecycle status.
--
-- Out of scope:
--   - legacy public.skpe_initiatives;
--   - hierarchy mutation;
--   - cycle validation for existing initiatives;
--   - 6H delay/forecast;
--   - 6I agenda/events;
--   - 6J costs/effort.
-- ============================================================

begin;

create or replace function public.get_sparks_initiative_parent_candidates(
  target_organization_id uuid
)
returns table (
  initiative_id uuid,
  parent_initiative_id uuid,
  initiative_code text,
  initiative_name text,
  initiative_class text,
  initiative_status text,
  source_module_code text
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
      'Acesso negado: o usuario nao pode consultar iniciativas-pai desta organizacao.'
      using errcode = '42501';
  end if;

  return query
  select
    initiative.id,
    initiative.parent_initiative_id,
    initiative.code,
    initiative.name,
    initiative.initiative_class,
    initiative.status,
    initiative.source_module_code
  from public.sparks_initiatives initiative
  where initiative.organization_id = target_organization_id
    and initiative.archived_at is null
  order by
    lower(initiative.code),
    lower(initiative.name),
    initiative.id;
end;
$$;

revoke all
on function public.get_sparks_initiative_parent_candidates(uuid)
from public, anon;

grant execute
on function public.get_sparks_initiative_parent_candidates(uuid)
to authenticated, service_role;

comment on function public.get_sparks_initiative_parent_candidates(uuid) is
  'Lista candidatos canônicos a iniciativa-pai na mesma organização, excluindo somente iniciativas arquivadas, em alinhamento com create_sparks_initiative.';

commit;