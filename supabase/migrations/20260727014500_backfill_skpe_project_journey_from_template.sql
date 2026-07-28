-- ============================================================
-- SPARKs / SK-PE
-- Complementa projetos existentes com a arvore detalhada do
-- modelo metodologico vinculado, preservando itens ja existentes.
-- ============================================================

begin;

create or replace function public.backfill_skpe_project_journey_from_template(
  target_project_id uuid
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_project public.skpe_projects%rowtype;
  template_item record;
  resolved_parent_id uuid;
  existing_item_id uuid;
  inserted_count integer := 0;
begin
  select *
    into target_project
  from public.skpe_projects
  where id = target_project_id;

  if target_project.id is null then
    raise exception 'Projeto nao encontrado.';
  end if;

  if auth.uid() is not null
     and not public.can_manage_skpe_journey(target_project.organization_id) then
    raise exception
      'Acesso negado: o usuario nao pode complementar a jornada deste projeto.'
      using errcode = '42501';
  end if;

  if auth.uid() is null
     and session_user not in ('postgres', 'supabase_admin') then
    raise exception
      'Acesso negado: contexto administrativo invalido.'
      using errcode = '42501';
  end if;

  if target_project.methodology_template_version_id is null then
    raise exception
      'O projeto nao possui versao metodologica vinculada.';
  end if;

  create temporary table if not exists pg_temp.skpe_backfill_map (
    template_item_id uuid primary key,
    journey_item_id uuid not null
  ) on commit drop;

  truncate table pg_temp.skpe_backfill_map;

  for template_item in
    with recursive template_tree as (
      select
        item.*,
        0 as depth
      from public.skpe_methodology_template_items item
      where item.template_version_id =
        target_project.methodology_template_version_id
        and item.parent_item_id is null

      union all

      select
        child.*,
        parent.depth + 1
      from public.skpe_methodology_template_items child
      join template_tree parent
        on parent.id = child.parent_item_id
    )
    select *
    from template_tree
    order by depth, display_order, code
  loop
    resolved_parent_id := null;

    if template_item.parent_item_id is not null then
      select journey_item_id
        into resolved_parent_id
      from pg_temp.skpe_backfill_map
      where template_item_id =
        template_item.parent_item_id;
    end if;

    select journey.id
      into existing_item_id
    from public.skpe_journey_items journey
    where journey.project_id = target_project.id
      and journey.code = template_item.code
    limit 1;

    if existing_item_id is null then
      insert into public.skpe_journey_items (
        project_id,
        parent_item_id,
        item_type,
        code,
        name,
        description,
        status,
        progress,
        display_order,
        is_current,
        is_mandatory,
        planned_start_date,
        planned_end_date,
        validation_required,
        validation_status,
        metadata,
        created_by,
        updated_by
      )
      values (
        target_project.id,
        resolved_parent_id,
        template_item.item_type,
        template_item.code,
        template_item.name,
        template_item.description,
        'not_started',
        0,
        template_item.display_order,
        false,
        template_item.is_mandatory,
        target_project.start_date,
        case
          when target_project.start_date is null
            or template_item.default_duration_days is null
          then null
          else target_project.start_date
            + template_item.default_duration_days
        end,
        template_item.validation_required,
        case
          when template_item.validation_required
          then 'pending'
          else 'not_required'
        end,
        jsonb_build_object(
          'template_item_id', template_item.id,
          'completion_criteria',
            template_item.completion_criteria,
          'template_metadata',
            template_item.metadata,
          'backfilled_at', timezone('utc', now())
        ),
        auth.uid(),
        auth.uid()
      )
      returning id into existing_item_id;

      inserted_count := inserted_count + 1;
    else
      update public.skpe_journey_items
      set
        parent_item_id = resolved_parent_id,
        item_type = template_item.item_type,
        name = template_item.name,
        description = template_item.description,
        display_order = template_item.display_order,
        is_mandatory = template_item.is_mandatory,
        validation_required =
          template_item.validation_required,
        metadata = coalesce(metadata, '{}'::jsonb)
          || jsonb_build_object(
            'template_item_id', template_item.id,
            'completion_criteria',
              template_item.completion_criteria,
            'template_metadata',
              template_item.metadata
          ),
        updated_at = timezone('utc', now()),
        updated_by = auth.uid()
      where id = existing_item_id;
    end if;

    insert into pg_temp.skpe_backfill_map (
      template_item_id,
      journey_item_id
    )
    values (
      template_item.id,
      existing_item_id
    )
    on conflict (template_item_id)
    do update set
      journey_item_id = excluded.journey_item_id;
  end loop;

  if auth.uid() is not null then
    insert into public.skpe_journey_audit (
      organization_id,
      project_id,
      journey_item_id,
      actor_user_id,
      action_code,
      previous_data,
      new_data,
      reason
    )
    values (
      target_project.organization_id,
      target_project.id,
      null,
      auth.uid(),
      'journey_template_backfilled',
      '{}'::jsonb,
      jsonb_build_object(
        'inserted_items', inserted_count,
        'template_version_id',
          target_project.methodology_template_version_id
      ),
      'Complementacao da arvore da jornada a partir do modelo metodologico vinculado.'
    );
  end if;

  return inserted_count;
end;
$$;

revoke all on function
  public.backfill_skpe_project_journey_from_template(uuid)
  from public, anon;

grant execute on function
  public.backfill_skpe_project_journey_from_template(uuid)
  to authenticated, service_role;

-- Complementa automaticamente o projeto inicial da COOTAQUARA.
do $$
declare
  target_project_id uuid;
  inserted_items integer;
begin
  select project.id
    into target_project_id
  from public.skpe_projects project
  join public.organizations organization
    on organization.id = project.organization_id
  where organization.code = 'COOTAQUARA'
    and project.code = 'PE-COOTAQUARA-2026'
  limit 1;

  if target_project_id is not null then
    inserted_items :=
      public.backfill_skpe_project_journey_from_template(
        target_project_id
      );
  end if;
end;
$$;

commit;
