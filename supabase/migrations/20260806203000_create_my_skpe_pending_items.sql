begin;

-- ============================================================
-- FE-09.A.07 — MINHAS PENDÊNCIAS
-- Agregador pessoal e somente leitura do SK-PE.
-- ============================================================

create or replace function public.get_my_skpe_pending_items(
  target_organization_id uuid,
  target_project_id uuid default null,
  target_formulation_id uuid default null
)
returns table (
  pending_id text,
  source_type text,
  source_id uuid,
  organization_id uuid,
  project_id uuid,
  formulation_id uuid,
  source_code text,
  title text,
  description text,
  responsibility_type text,
  original_status text,
  normalized_status text,
  priority text,
  due_date date,
  overdue boolean,
  due_soon boolean,
  blocked boolean,
  blocking_reason text,
  route_section text,
  updated_at timestamptz,
  priority_order integer
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'Usuário não autenticado.'
      using errcode = '42501';
  end if;

  if target_organization_id is null then
    raise exception 'Informe a organização.'
      using errcode = '22023';
  end if;

  if not (
    public.is_active_member(target_organization_id)
    and public.has_module_access(target_organization_id, 'SK-PE')
  ) then
    raise exception
      'Acesso negado: o usuário não pode consultar pendências do SK-PE nesta organização.'
      using errcode = '42501';
  end if;

  return query
  with pending_sources as (

    -- ========================================================
    -- 1. ITENS DA JORNADA
    -- ========================================================
    select
      'journey_item:' || item.id::text as pending_id,
      'journey_item'::text as source_type,
      item.id as source_id,
      project.organization_id,
      project.id as project_id,
      target_formulation_id as formulation_id,
      item.code as source_code,
      item.name as title,
      item.description,
      'responsible'::text as responsibility_type,
      item.status as original_status,
      case
        when item.planned_end_date < current_date
          and item.status not in ('completed', 'cancelled')
          then 'overdue'
        when item.blocked or item.status = 'blocked'
          then 'blocked'
        when item.status = 'pending_validation'
          or item.validation_status = 'pending'
          then 'awaiting_validation'
        when item.planned_end_date between current_date and current_date + 7
          then 'due_soon'
        when item.status = 'in_progress'
          then 'in_progress'
        else 'not_started'
      end as normalized_status,
      case
        when item.is_mandatory then 'high'
        else 'medium'
      end as priority,
      item.planned_end_date as due_date,
      (
        item.planned_end_date < current_date
        and item.status not in ('completed', 'cancelled')
      ) as overdue,
      (
        item.planned_end_date between current_date and current_date + 7
        and item.status not in ('completed', 'cancelled')
      ) as due_soon,
      (item.blocked or item.status = 'blocked') as blocked,
      item.blocking_reason,
      'journey'::text as route_section,
      item.updated_at,
      case
        when item.planned_end_date < current_date
          and item.status not in ('completed', 'cancelled') then 10
        when item.blocked or item.status = 'blocked' then 20
        when item.status = 'pending_validation'
          or item.validation_status = 'pending' then 30
        when item.is_mandatory then 40
        when item.planned_end_date between current_date and current_date + 7
          then 50
        else 60
      end as priority_order
    from public.skpe_journey_items item
    join public.skpe_projects project
      on project.id = item.project_id
    where project.organization_id = target_organization_id
      and project.archived_at is null
      and item.archived_at is null
      and item.responsible_user_id = current_user_id
      and item.status not in ('completed', 'cancelled')
      and (
        target_project_id is null
        or project.id = target_project_id
      )

    union all

    -- ========================================================
    -- 2. INICIATIVAS
    -- ========================================================
    select
      'initiative:' || initiative.id::text,
      'initiative'::text,
      initiative.id,
      initiative.organization_id,
      initiative.project_id,
      target_formulation_id,
      initiative.code,
      initiative.name,
      initiative.description,
      'owner'::text,
      initiative.status,
      case
        when initiative.due_date < current_date
          and initiative.status not in (
            'completed', 'cancelled', 'archived'
          )
          then 'overdue'
        when initiative.status = 'blocked'
          then 'blocked'
        when initiative.validation_status in (
          'pending_validation', 'under_review'
        )
          then 'awaiting_validation'
        when initiative.due_date between current_date and current_date + 7
          then 'due_soon'
        when initiative.status = 'in_progress'
          then 'in_progress'
        else 'not_started'
      end,
      initiative.priority,
      initiative.due_date,
      (
        initiative.due_date < current_date
        and initiative.status not in (
          'completed', 'cancelled', 'archived'
        )
      ),
      (
        initiative.due_date between current_date and current_date + 7
        and initiative.status not in (
          'completed', 'cancelled', 'archived'
        )
      ),
      initiative.status = 'blocked',
      case
        when initiative.status = 'blocked'
          then 'Iniciativa bloqueada.'
        else null
      end,
      'initiatives'::text,
      initiative.updated_at,
      case
        when initiative.due_date < current_date
          and initiative.status not in (
            'completed', 'cancelled', 'archived'
          ) then 10
        when initiative.status = 'blocked' then 20
        when initiative.validation_status in (
          'pending_validation', 'under_review'
        ) then 30
        when initiative.priority = 'critical' then 40
        when initiative.priority = 'high' then 45
        when initiative.due_date between current_date and current_date + 7
          then 50
        else 60
      end
    from public.skpe_initiatives initiative
    where initiative.organization_id = target_organization_id
      and initiative.archived_at is null
      and initiative.owner_user_id = current_user_id
      and initiative.status not in (
        'completed', 'cancelled', 'archived'
      )
      and (
        target_project_id is null
        or initiative.project_id = target_project_id
      )

    union all

    -- ========================================================
    -- 3. AÇÕES DAS INICIATIVAS
    -- ========================================================
    select
      'initiative_action:' || action.id::text,
      'initiative_action'::text,
      action.id,
      action.organization_id,
      action.project_id,
      action.origin_formulation_id,
      action.code,
      action.name,
      action.description,
      case
        when action.responsible_user_id = current_user_id
          then 'responsible'
        else 'backup_responsible'
      end,
      action.status,
      case
        when action.due_date < current_date
          and action.status not in (
            'completed', 'cancelled', 'archived'
          )
          then 'overdue'
        when action.status = 'blocked'
          then 'blocked'
        when action.validation_status = 'pending_validation'
          then 'awaiting_validation'
        when action.due_date between current_date and current_date + 7
          then 'due_soon'
        when action.status = 'in_progress'
          then 'in_progress'
        else 'not_started'
      end,
      action.priority,
      action.due_date,
      (
        action.due_date < current_date
        and action.status not in (
          'completed', 'cancelled', 'archived'
        )
      ),
      (
        action.due_date between current_date and current_date + 7
        and action.status not in (
          'completed', 'cancelled', 'archived'
        )
      ),
      action.status = 'blocked',
      case
        when action.status = 'blocked'
          then 'Ação bloqueada.'
        else null
      end,
      'initiatives'::text,
      action.updated_at,
      case
        when action.due_date < current_date
          and action.status not in (
            'completed', 'cancelled', 'archived'
          ) then 10
        when action.status = 'blocked' then 20
        when action.validation_status = 'pending_validation' then 30
        when action.priority = 'critical' then 40
        when action.priority = 'high' then 45
        when action.due_date between current_date and current_date + 7
          then 50
        else 60
      end
    from public.skpe_initiative_actions action
    where action.organization_id = target_organization_id
      and action.archived_at is null
      and (
        action.responsible_user_id = current_user_id
        or action.backup_responsible_user_id = current_user_id
      )
      and action.status not in (
        'completed', 'cancelled', 'archived'
      )
      and (
        target_project_id is null
        or action.project_id = target_project_id
      )
      and (
        target_formulation_id is null
        or action.origin_formulation_id is null
        or action.origin_formulation_id = target_formulation_id
      )

    union all

    -- ========================================================
    -- 4. ITENS DO CHECKLIST DE EVIDÊNCIAS
    -- ========================================================
    select
      'evidence_checklist_item:' || checklist_item.id::text,
      'evidence_checklist_item'::text,
      checklist_item.id,
      checklist.organization_id,
      checklist.project_id,
      target_formulation_id,
      checklist_item.code,
      checklist_item.name,
      checklist_item.description,
      'responsible'::text,
      checklist_item.collection_status,
      case
        when checklist_item.due_date < current_date
          and checklist_item.collection_status not in (
            'received', 'not_applicable', 'closed'
          )
          then 'overdue'
        when checklist_item.collection_status = 'under_review'
          then 'awaiting_validation'
        when checklist_item.due_date
          between current_date and current_date + 7
          then 'due_soon'
        when checklist_item.collection_status in (
          'requested',
          'partially_received',
          'needs_complement'
        )
          then 'in_progress'
        else 'not_started'
      end,
      case
        when checklist_item.is_required then 'high'
        else 'medium'
      end,
      checklist_item.due_date,
      (
        checklist_item.due_date < current_date
        and checklist_item.collection_status not in (
          'received', 'not_applicable', 'closed'
        )
      ),
      (
        checklist_item.due_date
          between current_date and current_date + 7
        and checklist_item.collection_status not in (
          'received', 'not_applicable', 'closed'
        )
      ),
      false,
      null::text,
      'journey'::text,
      checklist_item.updated_at,
      case
        when checklist_item.due_date < current_date
          and checklist_item.collection_status not in (
            'received', 'not_applicable', 'closed'
          ) then 10
        when checklist_item.collection_status = 'under_review'
          then 30
        when checklist_item.is_required then 40
        when checklist_item.due_date
          between current_date and current_date + 7 then 50
        else 60
      end
    from public.skpe_evidence_checklist_items checklist_item
    join public.skpe_evidence_checklists checklist
      on checklist.id = checklist_item.checklist_id
    where checklist.organization_id = target_organization_id
      and checklist.status <> 'archived'
      and checklist_item.responsible_user_id = current_user_id
      and checklist_item.is_applicable
      and checklist_item.collection_status not in (
        'received', 'not_applicable', 'closed'
      )
      and (
        target_project_id is null
        or checklist.project_id = target_project_id
      )

    union all

    -- ========================================================
    -- 5. DECISÕES DE GOVERNANÇA
    -- ========================================================
    select
      'governance_decision:' || decision.id::text,
      'governance_decision'::text,
      decision.id,
      decision.organization_id,
      decision.project_id,
      decision.formulation_id,
      decision.code,
      decision.title,
      decision.decision_text,
      'responsible'::text,
      decision.status,
      case
        when decision.status = 'overdue'
          or (
            decision.due_date < current_date
            and decision.status not in ('completed', 'cancelled')
          )
          then 'overdue'
        when decision.status = 'blocked'
          then 'blocked'
        when decision.due_date between current_date and current_date + 7
          then 'due_soon'
        when decision.status = 'in_progress'
          then 'in_progress'
        else 'not_started'
      end,
      decision.priority,
      decision.due_date,
      (
        decision.status = 'overdue'
        or (
          decision.due_date < current_date
          and decision.status not in ('completed', 'cancelled')
        )
      ),
      (
        decision.due_date between current_date and current_date + 7
        and decision.status not in ('completed', 'cancelled')
      ),
      decision.status = 'blocked',
      case
        when decision.status = 'blocked'
          then decision.rationale
        else null
      end,
      'governance'::text,
      decision.updated_at,
      case
        when decision.status = 'overdue'
          or (
            decision.due_date < current_date
            and decision.status not in ('completed', 'cancelled')
          ) then 10
        when decision.status = 'blocked' then 20
        when decision.priority = 'critical' then 40
        when decision.priority = 'high' then 45
        when decision.due_date between current_date and current_date + 7
          then 50
        else 60
      end
    from public.skpe_governance_decisions decision
    where decision.organization_id = target_organization_id
      and decision.responsible_user_id = current_user_id
      and decision.status not in ('completed', 'cancelled')
      and (
        target_project_id is null
        or decision.project_id = target_project_id
      )
      and (
        target_formulation_id is null
        or decision.formulation_id = target_formulation_id
      )
  )
  select
    source.pending_id,
    source.source_type,
    source.source_id,
    source.organization_id,
    source.project_id,
    source.formulation_id,
    source.source_code,
    source.title,
    source.description,
    source.responsibility_type,
    source.original_status,
    source.normalized_status,
    source.priority,
    source.due_date,
    source.overdue,
    source.due_soon,
    source.blocked,
    source.blocking_reason,
    source.route_section,
    source.updated_at,
    source.priority_order
  from pending_sources source
  order by
    source.priority_order,
    source.due_date nulls last,
    source.updated_at desc,
    source.title;
end;
$$;

comment on function public.get_my_skpe_pending_items(uuid, uuid, uuid) is
  'FE-09.A.07: consolida pendências pessoais do usuário autenticado em Jornada, Iniciativas, Ações, Checklist de Evidências e Governança.';

revoke all on function public.get_my_skpe_pending_items(uuid, uuid, uuid)
from public, anon;

grant execute on function public.get_my_skpe_pending_items(uuid, uuid, uuid)
to authenticated, service_role;

commit;
