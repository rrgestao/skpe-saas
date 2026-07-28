-- Auditoria somente leitura: pessoas, papeis e designacoes da organizacao
-- Nao altera dados.

-- 1. Localizar a organizacao COOTAQUARA
select
  id as organization_id,
  code as organization_code,
  legal_name,
  trade_name,
  active
from public.organizations
where upper(coalesce(code, '')) = 'COOTAQUARA'
   or upper(coalesce(trade_name, '')) like '%COOTAQUARA%'
   or upper(coalesce(legal_name, '')) like '%COOTAQUARA%'
order by active desc, trade_name nulls last, legal_name;

-- 2. Pessoas vinculadas a COOTAQUARA e sua origem
select
  op.id as organization_person_id,
  p.id as person_id,
  p.full_name,
  p.email,
  op.relationship_type,
  op.job_title,
  op.organizational_area,
  op.status,
  op.is_primary,
  op.valid_from,
  op.valid_until,
  op.created_at,
  op.updated_at
from public.sparks_organization_people op
join public.sparks_people p on p.id = op.person_id
join public.organizations o on o.id = op.organization_id
where upper(coalesce(o.code, '')) = 'COOTAQUARA'
   or upper(coalesce(o.trade_name, '')) like '%COOTAQUARA%'
   or upper(coalesce(o.legal_name, '')) like '%COOTAQUARA%'
order by op.status, p.full_name;

-- 3. Papeis organizacionais cadastrados para COOTAQUARA
select
  r.id as role_id,
  r.code as role_code,
  r.name as role_name,
  r.role_type,
  r.organizational_area,
  r.authority_level,
  r.is_governance_role,
  r.requires_mandate,
  r.active,
  r.created_at,
  r.updated_at
from public.sparks_organizational_roles r
join public.organizations o on o.id = r.organization_id
where upper(coalesce(o.code, '')) = 'COOTAQUARA'
   or upper(coalesce(o.trade_name, '')) like '%COOTAQUARA%'
   or upper(coalesce(o.legal_name, '')) like '%COOTAQUARA%'
order by r.active desc, r.is_governance_role desc, r.name;

-- 4. Designacoes pessoa x papel existentes
select
  a.id as assignment_id,
  p.full_name,
  r.code as role_code,
  r.name as role_name,
  a.status,
  a.valid_from,
  a.valid_until,
  a.designation_document,
  a.created_at,
  a.updated_at
from public.sparks_person_role_assignments a
join public.sparks_organization_people op on op.id = a.organization_person_id
join public.sparks_people p on p.id = op.person_id
join public.sparks_organizational_roles r on r.id = a.organizational_role_id
join public.organizations o on o.id = a.organization_id
where upper(coalesce(o.code, '')) = 'COOTAQUARA'
   or upper(coalesce(o.trade_name, '')) like '%COOTAQUARA%'
   or upper(coalesce(o.legal_name, '')) like '%COOTAQUARA%'
order by a.status, p.full_name, r.name;

-- 5. Resumo quantitativo para validacao
select
  o.id as organization_id,
  coalesce(o.trade_name, o.legal_name) as organization_name,
  (select count(*) from public.sparks_organization_people op where op.organization_id = o.id) as people_total,
  (select count(*) from public.sparks_organizational_roles r where r.organization_id = o.id) as roles_total,
  (select count(*) from public.sparks_person_role_assignments a where a.organization_id = o.id) as assignments_total,
  (select count(*) from public.sparks_responsibility_assignments a where a.organization_id = o.id) as responsibilities_total
from public.organizations o
where upper(coalesce(o.code, '')) = 'COOTAQUARA'
   or upper(coalesce(o.trade_name, '')) like '%COOTAQUARA%'
   or upper(coalesce(o.legal_name, '')) like '%COOTAQUARA%';
