begin;

-- ============================================================
-- SPARKs PaaS
-- Gate 17-B.5F.3C.6F
-- Roll-up Governado de Progresso e Saude
--
-- Principios:
-- 1. sparks_initiatives.progress permanece autoridade oficial.
-- 2. sparks_initiatives.health_status permanece autoridade oficial.
-- 3. o roll-up deste gate e derivado e somente leitura.
-- 4. nenhuma action altera automaticamente a initiative.
-- 5. politica inicial de agregacao: equal_weight.
-- 6. hierarquia: bottom-up; somente roots contribuem na initiative.
-- 7. cancelled e archived nao contribuem.
-- 8. responsabilidades, custo, esforco e prioridade nao sao pesos.
-- 9. saude derivada nao antecipa a semantica temporal do 6H.
-- ============================================================


-- ============================================================
-- HELPER INTERNO
-- Calcula o progresso derivado de uma action.
--
-- Regra:
-- - action sem filhos elegiveis -> usa progress governado proprio;
-- - action com filhos elegiveis -> media simples dos filhos;
-- - cancelled / archived -> nao contribuem;
-- - recursion guard protege contra ciclos inesperados.
-- ============================================================

create or replace function public.sparks_calculate_initiative_action_rollup_internal(
  target_action_id uuid,
  visited_action_ids uuid[]
)
returns numeric
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_action public.sparks_initiative_actions%rowtype;
  v_child_count integer := 0;
  v_children_progress numeric;
  v_visited uuid[];
begin
  if target_action_id is null then
    return null;
  end if;

  v_visited := coalesce(visited_action_ids, array[]::uuid[]);

  if target_action_id = any(v_visited) then
    raise exception
      'Ciclo detectado na hierarquia de actions durante o roll-up.'
      using errcode = '55000';
  end if;

  select *
    into v_action
  from public.sparks_initiative_actions
  where id = target_action_id
    and archived_at is null
    and status <> 'cancelled';

  if v_action.id is null then
    return null;
  end if;

  v_visited := array_append(v_visited, v_action.id);

  select
    count(*)::integer,
    round(
      avg(
        public.sparks_calculate_initiative_action_rollup_internal(
          child.id,
          v_visited
        )
      ),
      2
    )
  into
    v_child_count,
    v_children_progress
  from public.sparks_initiative_actions child
  where child.parent_action_id = v_action.id
    and child.initiative_id = v_action.initiative_id
    and child.organization_id = v_action.organization_id
    and child.archived_at is null
    and child.status <> 'cancelled';

  if v_child_count > 0 then
    return v_children_progress;
  end if;

  return round(v_action.progress, 2);
end;
$$;

revoke all
on function public.sparks_calculate_initiative_action_rollup_internal(
  uuid,
  uuid[]
)
from public, anon, authenticated;

grant execute
on function public.sparks_calculate_initiative_action_rollup_internal(
  uuid,
  uuid[]
)
to service_role;

comment on function public.sparks_calculate_initiative_action_rollup_internal(
  uuid,
  uuid[]
) is
  'Helper interno do gate 6F. Calcula progresso bottom-up com equal weight, excluindo actions cancelled/archived, sem escrever em actions ou initiatives.';


-- ============================================================
-- PROJECAO DETALHADA
-- Explica o progresso oficial e calculado por action elegivel.
-- ============================================================

create or replace function public.get_sparks_initiative_action_rollup(
  target_initiative_id uuid
)
returns table (
  action_id uuid,
  parent_action_id uuid,
  depth integer,
  action_type text,
  status text,
  official_progress numeric,
  calculated_progress numeric,
  is_root boolean,
  has_eligible_children boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_initiative public.sparks_initiatives%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.'
      using errcode = '42501';
  end if;

  select *
    into v_initiative
  from public.sparks_initiatives
  where id = target_initiative_id
    and archived_at is null;

  if v_initiative.id is null then
    raise exception 'Iniciativa nao encontrada ou arquivada.'
      using errcode = '22023';
  end if;

  if not public.can_read_organization(v_initiative.organization_id) then
    raise exception
      'Acesso negado: o usuario nao pode consultar esta iniciativa.'
      using errcode = '42501';
  end if;

  return query
  with recursive eligible as (
    select
      a.id,
      a.parent_action_id,
      a.action_type,
      a.status,
      a.progress,
      0::integer as depth
    from public.sparks_initiative_actions a
    where a.initiative_id = v_initiative.id
      and a.organization_id = v_initiative.organization_id
      and a.parent_action_id is null
      and a.archived_at is null
      and a.status <> 'cancelled'

    union all

    select
      child.id,
      child.parent_action_id,
      child.action_type,
      child.status,
      child.progress,
      parent.depth + 1
    from public.sparks_initiative_actions child
    join eligible parent
      on parent.id = child.parent_action_id
    where child.initiative_id = v_initiative.id
      and child.organization_id = v_initiative.organization_id
      and child.archived_at is null
      and child.status <> 'cancelled'
  )
  select
    e.id,
    e.parent_action_id,
    e.depth,
    e.action_type,
    e.status,
    round(e.progress, 2),
    public.sparks_calculate_initiative_action_rollup_internal(
      e.id,
      array[]::uuid[]
    ),
    e.parent_action_id is null,
    exists (
      select 1
      from public.sparks_initiative_actions child
      where child.parent_action_id = e.id
        and child.initiative_id = v_initiative.id
        and child.organization_id = v_initiative.organization_id
        and child.archived_at is null
        and child.status <> 'cancelled'
    )
  from eligible e
  order by e.depth, e.id;
end;
$$;

revoke all
on function public.get_sparks_initiative_action_rollup(uuid)
from public, anon, authenticated;

grant execute
on function public.get_sparks_initiative_action_rollup(uuid)
to authenticated, service_role;

comment on function public.get_sparks_initiative_action_rollup(uuid) is
  'Projecao explicavel do roll-up 6F por action elegivel. Nao altera progresso, lifecycle ou saude oficiais.';


-- ============================================================
-- PROJECAO CONSOLIDADA DA INITIATIVE
-- ============================================================

create or replace function public.get_sparks_initiative_rollup(
  target_initiative_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_initiative public.sparks_initiatives%rowtype;

  v_current_action_count integer := 0;
  v_archived_action_count integer := 0;
  v_cancelled_action_count integer := 0;

  v_eligible_action_count integer := 0;
  v_root_action_count integer := 0;
  v_planned_action_count integer := 0;
  v_in_progress_action_count integer := 0;
  v_on_hold_action_count integer := 0;
  v_blocked_action_count integer := 0;
  v_completed_action_count integer := 0;
  v_milestone_count integer := 0;
  v_max_depth integer := 0;

  v_calculated_progress numeric;
  v_progress_variance numeric;
  v_health_signal text;
  v_completion_consistency text;
  v_ready_for_completion boolean := false;
  v_has_action_hierarchy boolean := false;
begin
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.'
      using errcode = '42501';
  end if;

  select *
    into v_initiative
  from public.sparks_initiatives
  where id = target_initiative_id
    and archived_at is null;

  if v_initiative.id is null then
    raise exception 'Iniciativa nao encontrada ou arquivada.'
      using errcode = '22023';
  end if;

  if not public.can_read_organization(v_initiative.organization_id) then
    raise exception
      'Acesso negado: o usuario nao pode consultar esta iniciativa.'
      using errcode = '42501';
  end if;


  -- ----------------------------------------------------------
  -- Contagem fisica atual.
  -- Cancelled permanece historicamente visivel, mas nao entra
  -- no denominador do roll-up.
  -- ----------------------------------------------------------

  select
    count(*) filter (
      where archived_at is null
    )::integer,
    count(*) filter (
      where archived_at is not null
    )::integer,
    count(*) filter (
      where archived_at is null
        and status = 'cancelled'
    )::integer
  into
    v_current_action_count,
    v_archived_action_count,
    v_cancelled_action_count
  from public.sparks_initiative_actions
  where initiative_id = v_initiative.id
    and organization_id = v_initiative.organization_id;


  -- ----------------------------------------------------------
  -- Conjunto elegivel.
  --
  -- Comeca apenas em roots ativas e nao cancelled.
  -- Descendentes de uma root excluida nao reaparecem
  -- artificialmente como contribuidores independentes.
  -- ----------------------------------------------------------

  with recursive eligible as (
    select
      a.id,
      a.parent_action_id,
      a.action_type,
      a.status,
      a.progress,
      0::integer as depth
    from public.sparks_initiative_actions a
    where a.initiative_id = v_initiative.id
      and a.organization_id = v_initiative.organization_id
      and a.parent_action_id is null
      and a.archived_at is null
      and a.status <> 'cancelled'

    union all

    select
      child.id,
      child.parent_action_id,
      child.action_type,
      child.status,
      child.progress,
      parent.depth + 1
    from public.sparks_initiative_actions child
    join eligible parent
      on parent.id = child.parent_action_id
    where child.initiative_id = v_initiative.id
      and child.organization_id = v_initiative.organization_id
      and child.archived_at is null
      and child.status <> 'cancelled'
  )
  select
    count(*)::integer,
    count(*) filter (
      where parent_action_id is null
    )::integer,
    count(*) filter (
      where status = 'planned'
    )::integer,
    count(*) filter (
      where status = 'in_progress'
    )::integer,
    count(*) filter (
      where status = 'on_hold'
    )::integer,
    count(*) filter (
      where status = 'blocked'
    )::integer,
    count(*) filter (
      where status = 'completed'
    )::integer,
    count(*) filter (
      where action_type = 'milestone'
    )::integer,
    coalesce(max(depth), 0)::integer,
    coalesce(bool_or(parent_action_id is not null), false)
  into
    v_eligible_action_count,
    v_root_action_count,
    v_planned_action_count,
    v_in_progress_action_count,
    v_on_hold_action_count,
    v_blocked_action_count,
    v_completed_action_count,
    v_milestone_count,
    v_max_depth,
    v_has_action_hierarchy
  from eligible;


  -- ----------------------------------------------------------
  -- Somente roots contribuem ao valor consolidado da initiative.
  -- Cada root, por sua vez, e calculada bottom-up.
  -- Isso evita dupla contagem entre pai e filhos.
  -- ----------------------------------------------------------

  select
    round(
      avg(
        public.sparks_calculate_initiative_action_rollup_internal(
          root.id,
          array[]::uuid[]
        )
      ),
      2
    )
  into v_calculated_progress
  from public.sparks_initiative_actions root
  where root.initiative_id = v_initiative.id
    and root.organization_id = v_initiative.organization_id
    and root.parent_action_id is null
    and root.archived_at is null
    and root.status <> 'cancelled';


  if v_calculated_progress is null then
    v_progress_variance := null;
  else
    v_progress_variance :=
      round(v_calculated_progress - v_initiative.progress, 2);
  end if;


  -- ----------------------------------------------------------
  -- Sinal de saude derivado V1.
  --
  -- Nao utiliza atraso, baseline, forecast ou caminho critico.
  -- A semantica temporal detalhada pertence ao gate 6H.
  -- ----------------------------------------------------------

  v_health_signal := case
    when v_initiative.status = 'completed'
      then 'completed'
    when v_eligible_action_count = 0
      then 'not_assessed'
    when v_blocked_action_count > 0
      then 'critical'
    when v_on_hold_action_count > 0
      then 'attention'
    else 'on_track'
  end;


  -- ----------------------------------------------------------
  -- Completude.
  -- Nenhuma transicao automatica e realizada.
  -- ----------------------------------------------------------

  v_ready_for_completion :=
    v_eligible_action_count > 0
    and v_completed_action_count = v_eligible_action_count
    and v_initiative.status not in ('completed', 'cancelled', 'archived');

  v_completion_consistency := case
    when v_eligible_action_count = 0
      then 'not_assessed'
    when v_initiative.status = 'completed'
         and v_completed_action_count = v_eligible_action_count
      then 'consistent'
    when v_initiative.status = 'completed'
      then 'inconsistent'
    else 'not_applicable'
  end;


  return jsonb_build_object(
    'initiativeId', v_initiative.id,
    'organizationId', v_initiative.organization_id,
    'sourceModuleCode', v_initiative.source_module_code,

    'officialStatus', v_initiative.status,
    'officialProgress', v_initiative.progress,
    'calculatedProgress', v_calculated_progress,
    'progressVariance', v_progress_variance,

    'officialHealthStatus', v_initiative.health_status,
    'calculatedHealthSignal', v_health_signal,

    'aggregationPolicy', 'equal_weight',

    'currentActionCount', v_current_action_count,
    'eligibleActionCount', v_eligible_action_count,
    'rootActionCount', v_root_action_count,
    'plannedActionCount', v_planned_action_count,
    'inProgressActionCount', v_in_progress_action_count,
    'onHoldActionCount', v_on_hold_action_count,
    'blockedActionCount', v_blocked_action_count,
    'completedActionCount', v_completed_action_count,
    'cancelledActionCount', v_cancelled_action_count,
    'archivedActionCount', v_archived_action_count,
    'milestoneCount', v_milestone_count,

    'hasActionHierarchy', v_has_action_hierarchy,
    'maxHierarchyDepth', v_max_depth,

    'readyForCompletion', v_ready_for_completion,
    'completionConsistency', v_completion_consistency,

    'calculationBasis', jsonb_build_object(
      'hierarchy', 'bottom_up',
      'initiativeContribution', 'root_actions_only',
      'parentContribution', 'equal_weight_of_eligible_direct_children',
      'leafContribution', 'official_action_progress',
      'cancelledActions', 'excluded',
      'archivedActions', 'excluded',
      'milestones', 'same_progress_contract_as_actions',
      'responsibilitiesAsWeight', false,
      'costAsWeight', false,
      'effortAsWeight', false,
      'priorityAsWeight', false,
      'automaticInitiativeMutation', false,
      'scheduleHealthIncluded', false
    ),

    'calculatedAt', timezone('utc', now())
  );
end;
$$;

revoke all
on function public.get_sparks_initiative_rollup(uuid)
from public, anon, authenticated;

grant execute
on function public.get_sparks_initiative_rollup(uuid)
to authenticated, service_role;

comment on function public.get_sparks_initiative_rollup(uuid) is
  'Projecao governada 6F de progresso e sinal de saude derivados das actions. Preserva progress e health_status oficiais da initiative e nunca os altera automaticamente.';


-- ============================================================
-- GARANTIAS DO GATE 6F
-- ============================================================
-- 1. Nenhuma coluna foi adicionada a sparks_initiative_actions.
-- 2. Nenhuma coluna foi adicionada a sparks_initiatives.
-- 3. Nenhum trigger action -> initiative foi criado.
-- 4. Nenhuma escrita automatica de progress foi criada.
-- 5. Nenhuma escrita automatica de health_status foi criada.
-- 6. Nenhum peso de portfolio foi reutilizado.
-- 7. Nenhum progress_weight foi escondido em metadata.
-- 8. Responsabilidades do 6E nao alteram o calculo.
-- 9. Datas/baseline/atraso continuam reservados ao 6H.
-- 10. Override oficial continua pertencendo ao contrato governado
--     update_sparks_initiative_execution do 6B.
-- ============================================================

commit;