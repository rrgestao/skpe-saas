-- AUDITORIA SOMENTE DE LEITURA
-- Pessoas, vínculos, papéis, designações e responsabilidades da COOTAQUARA
-- Nenhuma instrução INSERT, UPDATE, DELETE ou DDL permanente é executada.

-- 1. Organização-alvo
select
  o.id as organization_id,
  o.code,
  o.legal_name,
  o.trade_name,
  o.organization_type,
  o.cooperative_branch,
  o.status
from public.organizations o
where upper(coalesce(o.code, '')) = 'COOTAQUARA'
   or upper(coalesce(o.trade_name, '')) like '%COOTAQUARA%'
   or upper(coalesce(o.legal_name, '')) like '%COOTAQUARA%'
order by o.created_at;

-- 2. Pessoas vinculadas à organização
with target_organization as (
  select o.id
  from public.organizations o
  where upper(coalesce(o.code, '')) = 'COOTAQUARA'
     or upper(coalesce(o.trade_name, '')) like '%COOTAQUARA%'
     or upper(coalesce(o.legal_name, '')) like '%COOTAQUARA%'
  order by o.created_at
  limit 1
)
select
  op.id as organization_person_id,
  p.id as person_id,
  p.full_name,
  p.preferred_name,
  p.primary_email,
  p.primary_phone,
  p.mobile_phone,
  p.person_status,
  p.data_source,
  op.relationship_type,
  op.registration_number,
  op.job_title,
  op.organizational_area,
  op.organizational_unit,
  op.start_date,
  op.end_date,
  op.status as relationship_status,
  op.is_primary_relationship,
  op.is_cooperative_member,
  op.is_employee,
  op.is_director,
  op.is_board_member,
  op.is_committee_member,
  op.is_organization_contact,
  op.is_primary_contact,
  op.contact_function
from public.sparks_organization_people op
join target_organization t on t.id = op.organization_id
join public.sparks_people p on p.id = op.person_id
order by
  case when op.status = 'active' then 0 else 1 end,
  p.full_name;

-- 3. Papéis organizacionais cadastrados
with target_organization as (
  select o.id
  from public.organizations o
  where upper(coalesce(o.code, '')) = 'COOTAQUARA'
     or upper(coalesce(o.trade_name, '')) like '%COOTAQUARA%'
     or upper(coalesce(o.legal_name, '')) like '%COOTAQUARA%'
  order by o.created_at
  limit 1
)
select
  r.id as organizational_role_id,
  r.code,
  r.name,
  r.role_type,
  r.description,
  r.organizational_area,
  r.is_governance_role,
  r.requires_mandate,
  r.active,
  r.authority_level,
  r.reports_to_role_id,
  parent.name as reports_to_role_name,
  r.responsibilities_summary,
  r.created_at,
  r.updated_at
from public.sparks_organizational_roles r
join target_organization t on t.id = r.organization_id
left join public.sparks_organizational_roles parent on parent.id = r.reports_to_role_id
order by
  case when r.active then 0 else 1 end,
  r.name;

-- 4. Designações de pessoas para papéis
with target_organization as (
  select o.id
  from public.organizations o
  where upper(coalesce(o.code, '')) = 'COOTAQUARA'
     or upper(coalesce(o.trade_name, '')) like '%COOTAQUARA%'
     or upper(coalesce(o.legal_name, '')) like '%COOTAQUARA%'
  order by o.created_at
  limit 1
)
select
  a.id as assignment_id,
  p.full_name,
  p.preferred_name,
  r.code as role_code,
  r.name as role_name,
  r.role_type,
  r.organizational_area,
  a.mandate_start_date,
  a.mandate_end_date,
  case
    when a.mandate_end_date is null then 'Prazo indeterminado'
    else to_char(a.mandate_end_date, 'DD/MM/YYYY')
  end as mandate_end_display,
  a.assignment_status,
  a.appointment_document_reference,
  a.appointment_document_id,
  a.appointment_document_source,
  a.appointment_document_status,
  a.appointment_evidence_id,
  a.notes,
  a.created_at,
  a.created_by,
  a.updated_at,
  a.updated_by
from public.sparks_person_role_assignments a
join target_organization t on t.id = a.organization_id
join public.sparks_organization_people op on op.id = a.organization_person_id
join public.sparks_people p on p.id = op.person_id
join public.sparks_organizational_roles r on r.id = a.organizational_role_id
order by
  case when a.assignment_status = 'active' then 0 else 1 end,
  p.full_name,
  r.name;

-- 5. Responsabilidades estratégicas
with target_organization as (
  select o.id
  from public.organizations o
  where upper(coalesce(o.code, '')) = 'COOTAQUARA'
     or upper(coalesce(o.trade_name, '')) like '%COOTAQUARA%'
     or upper(coalesce(o.legal_name, '')) like '%COOTAQUARA%'
  order by o.created_at
  limit 1
)
select
  ra.id as responsibility_assignment_id,
  p.full_name,
  p.preferred_name,
  ra.module_code,
  ra.object_type,
  ra.object_id,
  ra.responsibility_type,
  ra.allocation_percentage,
  ra.valid_from,
  ra.valid_until,
  case
    when ra.valid_until is null then 'Prazo indeterminado'
    else to_char(ra.valid_until, 'DD/MM/YYYY')
  end as valid_until_display,
  ra.status,
  ra.assignment_reason,
  ra.authority_level,
  ra.approval_limit,
  ra.assignment_source,
  ra.delegated_from_assignment_id,
  ra.delegated_by_person_id,
  delegator.full_name as delegated_by_person_name,
  ra.delegation_reason,
  ra.delegation_started_at,
  ra.delegated_until,
  ra.created_at,
  ra.created_by,
  ra.updated_at,
  ra.updated_by
from public.sparks_responsibility_assignments ra
join target_organization t on t.id = ra.organization_id
join public.sparks_organization_people op on op.id = ra.organization_person_id
join public.sparks_people p on p.id = op.person_id
left join public.sparks_people delegator on delegator.id = ra.delegated_by_person_id
order by
  case when ra.status = 'active' then 0 else 1 end,
  ra.object_type,
  p.full_name,
  ra.responsibility_type;

-- 6. Resumo quantitativo e lacunas básicas
with target_organization as (
  select o.id
  from public.organizations o
  where upper(coalesce(o.code, '')) = 'COOTAQUARA'
     or upper(coalesce(o.trade_name, '')) like '%COOTAQUARA%'
     or upper(coalesce(o.legal_name, '')) like '%COOTAQUARA%'
  order by o.created_at
  limit 1
)
select
  (select count(*)
     from public.sparks_organization_people op
     join target_organization t on t.id = op.organization_id) as total_vinculos_pessoas,
  (select count(*)
     from public.sparks_organization_people op
     join target_organization t on t.id = op.organization_id
    where op.status = 'active') as vinculos_ativos,
  (select count(*)
     from public.sparks_organizational_roles r
     join target_organization t on t.id = r.organization_id) as total_papeis,
  (select count(*)
     from public.sparks_organizational_roles r
     join target_organization t on t.id = r.organization_id
    where r.active = true) as papeis_ativos,
  (select count(*)
     from public.sparks_person_role_assignments a
     join target_organization t on t.id = a.organization_id) as total_designacoes,
  (select count(*)
     from public.sparks_person_role_assignments a
     join target_organization t on t.id = a.organization_id
    where a.assignment_status = 'active'
      and a.mandate_start_date <= current_date
      and (a.mandate_end_date is null or a.mandate_end_date >= current_date)) as designacoes_vigentes,
  (select count(*)
     from public.sparks_person_role_assignments a
     join target_organization t on t.id = a.organization_id
    where a.appointment_document_reference is null
      and a.appointment_document_id is null) as designacoes_sem_evidencia_documental,
  (select count(*)
     from public.sparks_responsibility_assignments ra
     join target_organization t on t.id = ra.organization_id) as total_responsabilidades,
  (select count(*)
     from public.sparks_responsibility_assignments ra
     join target_organization t on t.id = ra.organization_id
    where ra.status = 'active'
      and ra.valid_from <= current_date
      and (ra.valid_until is null or ra.valid_until >= current_date)) as responsabilidades_vigentes,
  (select count(*)
     from public.sparks_responsibility_assignments ra
     join target_organization t on t.id = ra.organization_id
    where ra.status = 'active'
      and ra.valid_until is null) as responsabilidades_por_prazo_indeterminado;
