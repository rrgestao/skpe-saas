-- ============================================================
-- Plataforma SPARKs
-- Níveis organizacionais por tipo de organização
-- Regra canônica para organizações do tipo Sistema:
-- Nacional, Regional ou Estadual.
-- ============================================================

alter type public.organization_level add value if not exists 'national';
alter type public.organization_level add value if not exists 'regional';
alter type public.organization_level add value if not exists 'state';

-- Valores necessários à estrutura Matriz > Filial > Unidade,
-- já prevista na arquitetura organizacional da Plataforma SPARKs.
alter type public.organization_level add value if not exists 'matrix';
alter type public.organization_level add value if not exists 'branch';
alter type public.organization_level add value if not exists 'unit';

create or replace function public.validate_organization_type_and_level()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if lower(coalesce(new.organization_type, '')) = 'system'
     and new.organization_level::text not in ('national', 'regional', 'state') then
    raise exception using
      errcode = '23514',
      message = 'Organizações do tipo Sistema devem utilizar o nível Nacional, Regional ou Estadual.';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_validate_organization_type_and_level
  on public.organizations;

create trigger trg_validate_organization_type_and_level
before insert or update of organization_type, organization_level
on public.organizations
for each row
execute function public.validate_organization_type_and_level();

create or replace function public.get_platform_admin_organization_levels()
returns table (
  level_code text,
  level_name text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public.require_platform_super_admin();

  return query
  select
    enum_value::text,
    case enum_value::text
      when 'singular' then 'Cooperativa singular'
      when 'federation_central' then 'Central ou federação'
      when 'confederation' then 'Confederação'
      when 'system_guardian' then 'Organização guardiã do sistema'
      when 'national' then 'Nacional'
      when 'regional' then 'Regional'
      when 'state' then 'Estadual'
      when 'matrix' then 'Matriz'
      when 'branch' then 'Filial'
      when 'unit' then 'Unidade'
      else initcap(replace(enum_value::text, '_', ' '))
    end
  from unnest(enum_range(null::public.organization_level)) enum_value
  order by 2;
end;
$$;

comment on function public.validate_organization_type_and_level() is
  'Valida a compatibilidade entre tipo e nível organizacional. Para Sistema, aceita apenas Nacional, Regional ou Estadual.';

-- Verificação segura pelo catálogo do PostgreSQL, sem depender do uso
-- imediato dos novos valores do enum dentro da mesma transação.
select
  e.enumlabel as level_code,
  case e.enumlabel
    when 'national' then 'Nacional'
    when 'regional' then 'Regional'
    when 'state' then 'Estadual'
    when 'matrix' then 'Matriz'
    when 'branch' then 'Filial'
    when 'unit' then 'Unidade'
    else e.enumlabel
  end as level_name
from pg_type t
join pg_enum e on e.enumtypid = t.oid
join pg_namespace n on n.oid = t.typnamespace
where n.nspname = 'public'
  and t.typname = 'organization_level'
order by e.enumsortorder;
