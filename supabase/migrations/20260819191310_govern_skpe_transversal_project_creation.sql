-- ============================================================
-- Plataforma SPARKs / SK-PE-CONT-01
-- 17-B.5F.3C.3 - Criacao transversal governada de projeto SK-PE
--
-- Decisoes canonicas:
-- - sparks_initiatives e a identidade organizacional transversal.
-- - skpe_projects permanece o workspace metodologico especializado.
-- - A assinatura e o retorno da RPC existente sao preservados.
-- - A criacao e atomica: iniciativa -> projeto SK-PE -> binding -> Jornada -> auditoria.
-- - Nao ha sincronizacao permanente de status/progresso entre os dois dominios.
-- ============================================================

begin;

create or replace function public.create_skpe_project_from_template(
  target_organization_id uuid,
  project_code text,
  project_name text,
  project_description text default null,
  project_start_date date default null,
  project_target_end_date date default null,
  target_template_version_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  selected_version public.skpe_methodology_template_versions%rowtype;
  selected_template public.skpe_methodology_templates%rowtype;

  strategic_category_id uuid;
  strategic_category_count integer;

  new_initiative_id uuid := gen_random_uuid();
  new_project_id uuid := gen_random_uuid();

  template_item record;
  new_parent_id uuid;
  new_item_id uuid;

  normalized_project_code text;
  normalized_project_name text;
  normalized_project_description text;
begin
  if not public.can_manage_skpe_journey(target_organization_id) then
    raise exception
      'Acesso negado: o usuario nao pode criar projetos estrategicos para esta organizacao.'
      using errcode = '42501';
  end if;

  normalized_project_code := trim(project_code);
  normalized_project_name := trim(project_name);
  normalized_project_description := nullif(trim(project_description), '');

  if normalized_project_code is null
     or length(normalized_project_code) = 0 then
    raise exception
      'Informe o codigo do projeto.'
      using errcode = '22023';
  end if;

  if normalized_project_name is null
     or length(normalized_project_name) = 0 then
    raise exception
      'Informe o nome do projeto.'
      using errcode = '22023';
  end if;

  if project_target_end_date is not null
     and project_start_date is not null
     and project_target_end_date < project_start_date then
    raise exception
      'A data final nao pode ser anterior a data inicial.'
      using errcode = '22023';
  end if;

  if exists (
    select 1
    from public.sparks_initiatives si
    where si.organization_id = target_organization_id
      and si.code = normalized_project_code
  ) then
    raise exception
      'Ja existe uma iniciativa organizacional com o codigo "%".',
      normalized_project_code
      using errcode = '23505';
  end if;

  if exists (
    select 1
    from public.skpe_projects p
    where p.organization_id = target_organization_id
      and p.code = normalized_project_code
  ) then
    raise exception
      'Ja existe um projeto SK-PE com o codigo "%".',
      normalized_project_code
      using errcode = '23505';
  end if;

  if target_template_version_id is null then
    select v.*
      into selected_version
    from public.skpe_methodology_template_versions v
    join public.skpe_methodology_templates t
      on t.id = v.template_id
    where t.status = 'active'
      and t.is_recommended = true
      and v.status = 'published'
    order by
      v.effective_from desc nulls last,
      v.created_at desc
    limit 1;
  else
    select *
      into selected_version
    from public.skpe_methodology_template_versions
    where id = target_template_version_id
      and status = 'published';
  end if;

  if selected_version.id is null then
    raise exception
      'Nenhuma versao metodologica publicada foi encontrada.'
      using errcode = '22023';
  end if;

  select *
    into selected_template
  from public.skpe_methodology_templates
  where id = selected_version.template_id
    and status = 'active';

  if selected_template.id is null then
    raise exception
      'O modelo metodologico selecionado nao esta ativo.'
      using errcode = '22023';
  end if;

  select count(*)
    into strategic_category_count
  from public.sparks_domain_values dv
  join public.sparks_domains d
    on d.id = dv.domain_id
  where d.code = 'INITIATIVE_CATEGORY'
    and d.scope_type = 'global'
    and d.organization_id is null
    and d.module_code is null
    and d.active
    and dv.code = 'strategic'
    and dv.active;

  if strategic_category_count <> 1 then
    raise exception
      'Criacao bloqueada: esperado exatamente 1 valor ativo strategic no dominio INITIATIVE_CATEGORY; encontrados %.',
      strategic_category_count
      using errcode = '22023';
  end if;

  select dv.id
    into strategic_category_id
  from public.sparks_domain_values dv
  join public.sparks_domains d
    on d.id = dv.domain_id
  where d.code = 'INITIATIVE_CATEGORY'
    and d.scope_type = 'global'
    and d.organization_id is null
    and d.module_code is null
    and d.active
    and dv.code = 'strategic'
    and dv.active;

  insert into public.sparks_initiatives (
    id,
    organization_id,
    category_id,
    code,
    name,
    description,
    initiative_class,
    status,
    proposal_origin,
    source_module_code,
    proposal_source_reference,
    validation_status,
    start_date,
    target_end_date,
    progress,
    metadata,
    created_by,
    updated_by
  )
  values (
    new_initiative_id,
    target_organization_id,
    strategic_category_id,
    normalized_project_code,
    normalized_project_name,
    normalized_project_description,
    'project',
    'proposed',
    'organization',
    'SK-PE',
    'skpe_projects:' || new_project_id::text,
    'not_required',
    project_start_date,
    project_target_end_date,
    0,
    jsonb_build_object(
      'creation_operation', 'create_skpe_project_from_template',
      'specialization', 'SK-PE',
      'binding_type', 'strategic_plan_implementation',
      'methodology_template_id', selected_template.id,
      'methodology_template_version_id', selected_version.id,
      'methodology_version_code', selected_version.version_code
    ),
    auth.uid(),
    auth.uid()
  );

  insert into public.skpe_projects (
    id,
    organization_id,
    code,
    name,
    description,
    status,
    start_date,
    target_end_date,
    progress,
    methodology_version,
    methodology_template_id,
    methodology_template_version_id,
    template_cloned_at,
    created_without_template,
    created_by,
    updated_by
  )
  values (
    new_project_id,
    target_organization_id,
    normalized_project_code,
    normalized_project_name,
    normalized_project_description,
    'draft',
    project_start_date,
    project_target_end_date,
    0,
    selected_version.version_code,
    selected_template.id,
    selected_version.id,
    timezone('utc', now()),
    false,
    auth.uid(),
    auth.uid()
  );

  insert into public.skpe_project_initiative_bindings (
    organization_id,
    initiative_id,
    skpe_project_id,
    binding_type,
    created_by
  )
  values (
    target_organization_id,
    new_initiative_id,
    new_project_id,
    'strategic_plan_implementation',
    auth.uid()
  );

  create temporary table if not exists pg_temp.skpe_template_clone_map (
    template_item_id uuid primary key,
    journey_item_id uuid not null
  ) on commit drop;

  truncate table pg_temp.skpe_template_clone_map;

  for template_item in
    with recursive template_tree as (
      select
        i.*,
        0 as depth
      from public.skpe_methodology_template_items i
      where i.template_version_id = selected_version.id
        and i.parent_item_id is null

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
    new_parent_id := null;

    select journey_item_id
      into new_parent_id
    from pg_temp.skpe_template_clone_map
    where template_item_id = template_item.parent_item_id;

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
      new_project_id,
      new_parent_id,
      template_item.item_type,
      template_item.code,
      template_item.name,
      template_item.description,
      'not_started',
      0,
      template_item.display_order,
      false,
      template_item.is_mandatory,
      case
        when project_start_date is null then null
        else project_start_date
      end,
      case
        when project_start_date is null
          or template_item.default_duration_days is null then null
        else project_start_date + template_item.default_duration_days
      end,
      template_item.validation_required,
      case
        when template_item.validation_required then 'pending'
        else 'not_required'
      end,
      jsonb_build_object(
        'template_item_id', template_item.id,
        'completion_criteria', template_item.completion_criteria,
        'template_metadata', template_item.metadata
      ),
      auth.uid(),
      auth.uid()
    )
    returning id into new_item_id;

    insert into pg_temp.skpe_template_clone_map (
      template_item_id,
      journey_item_id
    )
    values (
      template_item.id,
      new_item_id
    );
  end loop;

  insert into public.skpe_journey_audit (
    organization_id,
    project_id,
    actor_user_id,
    action_code,
    reason,
    new_data
  )
  values (
    target_organization_id,
    new_project_id,
    auth.uid(),
    'project_created_from_template',
    'Projeto criado a partir do modelo metodologico recomendado e vinculado a identidade transversal da Plataforma SPARKs.',
    jsonb_build_object(
      'initiative_id', new_initiative_id,
      'binding_type', 'strategic_plan_implementation',
      'template_id', selected_template.id,
      'template_code', selected_template.code,
      'template_version_id', selected_version.id,
      'template_version_code', selected_version.version_code,
      'transversal_identity_created', true
    )
  );

  return new_project_id;
end;
$$;

revoke all
on function public.create_skpe_project_from_template(
  uuid, text, text, text, date, date, uuid
)
from public, anon;

grant execute
on function public.create_skpe_project_from_template(
  uuid, text, text, text, date, date, uuid
)
to authenticated, service_role;

commit;
