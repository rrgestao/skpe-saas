-- ============================================================
-- Plataforma SPARKs
-- ETAPA A - Inclusao segura dos niveis organizacionais.
-- Execute este arquivo isoladamente e aguarde a confirmacao de sucesso
-- antes de executar a ETAPA B.
-- ============================================================

alter type public.organization_level add value if not exists 'national';
alter type public.organization_level add value if not exists 'regional';
alter type public.organization_level add value if not exists 'state';
alter type public.organization_level add value if not exists 'matrix';
alter type public.organization_level add value if not exists 'branch';
alter type public.organization_level add value if not exists 'unit';

select
  e.enumlabel as codigo,
  case e.enumlabel
    when 'singular' then 'Cooperativa singular'
    when 'federation_central' then 'Central ou federacao'
    when 'confederation' then 'Confederacao'
    when 'system_guardian' then 'Organizacao guardia do sistema'
    when 'national' then 'Nacional'
    when 'regional' then 'Regional'
    when 'state' then 'Estadual'
    when 'matrix' then 'Matriz'
    when 'branch' then 'Filial'
    when 'unit' then 'Unidade'
    else e.enumlabel
  end as nome_publico
from pg_type t
join pg_enum e on e.enumtypid = t.oid
join pg_namespace n on n.oid = t.typnamespace
where n.nspname = 'public'
  and t.typname = 'organization_level'
order by e.enumsortorder;
