-- SK-PE-CONT-01: rollup físico hierárquico e dependências declarativas.
-- Esta migration não materializa payloads de importação.

create or replace function public.skpe_recalculate_journey_project_internal(
  p_project_id uuid,
  p_reason text,
  p_actor_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_project public.skpe_projects%rowtype;
  v_item public.skpe_journey_items%rowtype;
  v_previous jsonb;
  v_progress numeric;
  v_status text;
  v_dependencies_met boolean;
  v_reason text;
  v_project_progress numeric;
begin
  if p_actor_user_id is null then
    raise exception 'Usuário responsável pelo recálculo não informado.';
  end if;
  if p_reason is null or length(trim(p_reason)) < 10 then
    raise exception 'Informe justificativa com pelo menos 10 caracteres.';
  end if;

  select * into v_project
  from public.skpe_projects
  where id = p_project_id and archived_at is null
  for update;
  if v_project.id is null then raise exception 'Projeto estratégico não encontrado.'; end if;

  perform 1 from public.skpe_journey_items
  where project_id=p_project_id and archived_at is null
  order by id for update;

  -- Reavalia dependências declarativas, sempre no mesmo projeto.
  for v_item in
    select * from public.skpe_journey_items
    where project_id = p_project_id
      and archived_at is null
      and jsonb_typeof(metadata->'unblock_dependencies') = 'array'
    order by display_order, code
    for update
  loop
    select not exists (
      select 1
      from jsonb_array_elements(v_item.metadata->'unblock_dependencies') d
      where coalesce(d->>'code', '') = ''
         or coalesce(d->>'required_status', '') = ''
         or not exists (
           select 1 from public.skpe_journey_items prerequisite
           where prerequisite.project_id = v_item.project_id
             and prerequisite.archived_at is null
             and prerequisite.code = d->>'code'
             and prerequisite.status = d->>'required_status'
         )
    ) into v_dependencies_met;

    v_previous := jsonb_build_object('status',v_item.status,'progress',v_item.progress,'blocked',v_item.blocked,'blocking_reason',v_item.blocking_reason);
    if v_dependencies_met and v_item.blocked then
      update public.skpe_journey_items set status='not_started', progress=0, blocked=false,
        blocking_reason=null, is_current=false, updated_by=p_actor_user_id where id=v_item.id;
    elsif not v_dependencies_met and not v_item.blocked then
      update public.skpe_journey_items set status='blocked', blocked=true,
        blocking_reason='Dependência metodológica ainda não atendida.', is_current=false,
        updated_by=p_actor_user_id where id=v_item.id;
    else
      continue;
    end if;
    insert into public.skpe_journey_audit(organization_id,project_id,journey_item_id,actor_user_id,action_code,reason,previous_data,new_data)
    select v_project.organization_id,v_project.id,i.id,p_actor_user_id,'journey_dependency_reassessed',trim(p_reason),v_previous,
      jsonb_build_object('status',i.status,'progress',i.progress,'blocked',i.blocked,'blocking_reason',i.blocking_reason)
    from public.skpe_journey_items i where i.id=v_item.id;
  end loop;

  -- Pais de maior profundidade primeiro. Gates, opcionais, cancelados e arquivados não contam.
  for v_item in
    with recursive hierarchy as (
      select i.id,i.parent_item_id,0 depth
      from public.skpe_journey_items i
      where i.project_id=p_project_id and i.parent_item_id is null and i.archived_at is null
      union all
      select c.id,c.parent_item_id,h.depth+1
      from public.skpe_journey_items c join hierarchy h on c.parent_item_id=h.id
      where c.project_id=p_project_id and c.archived_at is null
    )
    select i.* from public.skpe_journey_items i join hierarchy h on h.id=i.id
    where exists (
      select 1 from public.skpe_journey_items c
      where c.parent_item_id=i.id and c.archived_at is null and c.status<>'cancelled'
        and c.item_type<>'gate' and c.is_mandatory=true
    )
    order by h.depth desc,i.display_order desc,i.code desc
  loop
    select
      round(greatest(0,least(100,
        sum(c.progress * case
          when coalesce(c.metadata->>'progress_weight','') ~ '^[0-9]+([.][0-9]+)?$'
               and (c.metadata->>'progress_weight')::numeric > 0
            then (c.metadata->>'progress_weight')::numeric else 1 end)
        / nullif(sum(case
          when coalesce(c.metadata->>'progress_weight','') ~ '^[0-9]+([.][0-9]+)?$'
               and (c.metadata->>'progress_weight')::numeric > 0
            then (c.metadata->>'progress_weight')::numeric else 1 end),0)
      )),0),
      case
        when bool_and(c.status='completed' and c.progress=100) then 'completed'
        when bool_and(c.status='not_started' and c.progress=0) then 'not_started'
        else 'in_progress'
      end
    into v_progress,v_status
    from public.skpe_journey_items c
    where c.parent_item_id=v_item.id and c.archived_at is null and c.status<>'cancelled'
      and c.item_type<>'gate' and c.is_mandatory=true;

    if v_item.blocked then v_status := 'blocked'; end if;
    if v_item.progress is distinct from v_progress or v_item.status is distinct from v_status then
      v_previous := jsonb_build_object('status',v_item.status,'progress',v_item.progress);
      update public.skpe_journey_items set status=v_status,progress=v_progress,
        is_current=case when v_status='in_progress' then is_current else false end,
        actual_end_date=case when v_status='completed' then coalesce(actual_end_date,current_date) else null end,
        updated_by=p_actor_user_id where id=v_item.id;
      insert into public.skpe_journey_audit(organization_id,project_id,journey_item_id,actor_user_id,action_code,reason,previous_data,new_data)
      values(v_project.organization_id,v_project.id,v_item.id,p_actor_user_id,'journey_rollup_recalculated',trim(p_reason),v_previous,
        jsonb_build_object('status',v_status,'progress',v_progress));
    end if;
  end loop;

  select round(coalesce(sum(i.progress * case
      when coalesce(i.metadata->>'progress_weight','') ~ '^[0-9]+([.][0-9]+)?$' and (i.metadata->>'progress_weight')::numeric>0
        then (i.metadata->>'progress_weight')::numeric else 1 end)
    / nullif(sum(case when coalesce(i.metadata->>'progress_weight','') ~ '^[0-9]+([.][0-9]+)?$'
      and (i.metadata->>'progress_weight')::numeric>0 then (i.metadata->>'progress_weight')::numeric else 1 end),0),v_project.progress),0)
  into v_project_progress
  from public.skpe_journey_items i
  where i.project_id=p_project_id and i.parent_item_id is null and i.archived_at is null
    and i.status<>'cancelled' and i.item_type<>'gate' and i.is_mandatory=true;

  if v_project.progress is distinct from v_project_progress then
    update public.skpe_projects set progress=v_project_progress,updated_by=p_actor_user_id where id=v_project.id;
    insert into public.skpe_journey_audit(organization_id,project_id,journey_item_id,actor_user_id,action_code,reason,previous_data,new_data)
    values(v_project.organization_id,v_project.id,null,p_actor_user_id,'journey_project_progress_recalculated',trim(p_reason),
      jsonb_build_object('progress',v_project.progress),jsonb_build_object('progress',v_project_progress));
  end if;
end;
$$;

create or replace function public.set_skpe_journey_item_status(target_item_id uuid,target_status text,target_progress numeric,change_reason text)
returns void language plpgsql security definer set search_path='' as $$
declare v_item public.skpe_journey_items%rowtype; v_project public.skpe_projects%rowtype;
begin
  select * into v_item from public.skpe_journey_items where id=target_item_id for update;
  if v_item.id is null then raise exception 'Item da jornada não encontrado.'; end if;
  select * into v_project from public.skpe_projects where id=v_item.project_id;
  if not public.can_manage_skpe_journey(v_project.organization_id) then raise exception 'Acesso negado.' using errcode='42501'; end if;
  if v_item.blocked and target_status in ('in_progress','completed','pending_validation') then raise exception 'Item bloqueado não pode ser iniciado ou concluído.'; end if;
  if target_status not in ('not_started','in_progress','blocked','pending_validation','completed','cancelled') then raise exception 'Status inválido.'; end if;
  if target_progress is null or target_progress<0 or target_progress>100 then raise exception 'Progresso inválido.'; end if;
  if change_reason is null or length(trim(change_reason))<10 then raise exception 'Informe justificativa com pelo menos 10 caracteres.'; end if;
  insert into public.skpe_journey_audit(organization_id,project_id,journey_item_id,actor_user_id,action_code,reason,previous_data,new_data)
  values(v_project.organization_id,v_project.id,v_item.id,auth.uid(),'journey_item_status_changed',trim(change_reason),
    jsonb_build_object('status',v_item.status,'progress',v_item.progress),jsonb_build_object('status',target_status,'progress',target_progress));
  update public.skpe_journey_items set status=target_status,progress=target_progress,
    blocked=case when target_status='blocked' then true else blocked end,
    is_current=(target_status='in_progress'),
    actual_start_date=case when target_status='in_progress' then coalesce(actual_start_date,current_date) else actual_start_date end,
    actual_end_date=case when target_status='completed' then coalesce(actual_end_date,current_date) else null end,
    updated_by=auth.uid() where id=target_item_id;
  perform public.skpe_recalculate_journey_project_internal(v_project.id,change_reason,auth.uid());
end; $$;

update public.skpe_methodology_template_items
set metadata=jsonb_set(coalesce(metadata,'{}'::jsonb),'{unblock_dependencies}',
  '[{"code":"PEM-02.02","required_status":"completed"}]'::jsonb,true)
where code='PEM-02.04';
update public.skpe_journey_items
set metadata=jsonb_set(coalesce(metadata,'{}'::jsonb),'{unblock_dependencies}',
  '[{"code":"PEM-02.02","required_status":"completed"}]'::jsonb,true)
where code='PEM-02.04' and archived_at is null;

revoke all on function public.skpe_recalculate_journey_project_internal(uuid,text,uuid) from public,anon,authenticated;
revoke all on function public.set_skpe_journey_item_status(uuid,text,numeric,text) from public,anon;
grant execute on function public.set_skpe_journey_item_status(uuid,text,numeric,text) to authenticated,service_role;