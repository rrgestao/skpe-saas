-- SPARKs PE - Cadencia Default v1 por Fase para PEM-02.
-- O total operacional da PEM-02 passa a ser a soma das Fases.
begin;

insert into public.sparks_parameter_definitions (
  parameter_key, parameter_group, name, description, value_type,
  default_value, module_code, unit, validation_rule, metadata
) values
  ('SKPE.JOURNEY.PEM02.01_DURATION','skpe.journey.cadence.pem02','PEM-02.01 · Abertura da Formulacao Estrategica','Duracao default da fase.','number','2'::jsonb,'SK-PE','days','{"min":1,"max":90}'::jsonb,'{"source":"SPARKs PE phase cadence v1"}'::jsonb),
  ('SKPE.JOURNEY.PEM02.02_DURATION','skpe.journey.cadence.pem02','PEM-02.02 · Direcionadores Estrategicos','Duracao default da fase.','number','5'::jsonb,'SK-PE','days','{"min":1,"max":90}'::jsonb,'{"source":"SPARKs PE phase cadence v1"}'::jsonb),
  ('SKPE.JOURNEY.PEM02.03_DURATION','skpe.journey.cadence.pem02','PEM-02.03 · Escolhas e Posicionamento Estrategico','Duracao default da fase.','number','5'::jsonb,'SK-PE','days','{"min":1,"max":90}'::jsonb,'{"source":"SPARKs PE phase cadence v1"}'::jsonb),
  ('SKPE.JOURNEY.PEM02.04_DURATION','skpe.journey.cadence.pem02','PEM-02.04 · Objetivos Estrategicos','Duracao default da fase.','number','7'::jsonb,'SK-PE','days','{"min":1,"max":90}'::jsonb,'{"source":"SPARKs PE phase cadence v1"}'::jsonb),
  ('SKPE.JOURNEY.PEM02.05_DURATION','skpe.journey.cadence.pem02','PEM-02.05 · Modelo Estrategico Futuro','Duracao default da fase.','number','6'::jsonb,'SK-PE','days','{"min":1,"max":90}'::jsonb,'{"source":"SPARKs PE phase cadence v1"}'::jsonb)
on conflict (parameter_key) do nothing;
with latest as (
  select v.id from public.skpe_methodology_template_versions v
  join public.skpe_methodology_templates t on t.id=v.template_id
  where t.code='SKPE-OFICIAL' and t.is_recommended=true and v.status='published'
  order by v.effective_from desc nulls last,v.created_at desc limit 1
), cadence(code,duration_days) as (
  values ('PEM-02.01',2),('PEM-02.02',5),('PEM-02.03',5),('PEM-02.04',7),('PEM-02.05',6)
)
update public.skpe_methodology_template_items i
set metadata=coalesce(i.metadata,'{}'::jsonb)||jsonb_build_object(
  'cadence_default_days',c.duration_days,'duration_unit','business_days',
  'cadence_source','SPARKs PE phase cadence v1','detailed_duration_status','configured_phase_v1'
)
from latest,cadence c
where i.template_version_id=latest.id and i.code=c.code and i.item_type='phase';
create or replace function public.get_skpe_phase_cadence_snapshot(
  p_organization_id uuid,p_project_id uuid default null
) returns jsonb language plpgsql security definer set search_path='' as $$
declare
  v_keys text[]:=array[
    'SKPE.JOURNEY.PEM00.01_DURATION','SKPE.JOURNEY.PEM00.02_DURATION','SKPE.JOURNEY.PEM00.03_DURATION','SKPE.JOURNEY.PEM00.04_DURATION','SKPE.JOURNEY.PEM00.05_DURATION','SKPE.JOURNEY.PEM00.06_DURATION','SKPE.JOURNEY.PEM00.07_DURATION','SKPE.JOURNEY.PEM00.08_DURATION',
    'SKPE.JOURNEY.PEM01.01_DURATION','SKPE.JOURNEY.PEM01.02_DURATION','SKPE.JOURNEY.PEM01.03_DURATION','SKPE.JOURNEY.PEM01.04_DURATION','SKPE.JOURNEY.PEM01.05_DURATION','SKPE.JOURNEY.PEM01.06_DURATION',
    'SKPE.JOURNEY.PEM02.01_DURATION','SKPE.JOURNEY.PEM02.02_DURATION','SKPE.JOURNEY.PEM02.03_DURATION','SKPE.JOURNEY.PEM02.04_DURATION','SKPE.JOURNEY.PEM02.05_DURATION'];
  v_codes text[]:=array[
    'PEM-00.01','PEM-00.02','PEM-00.03','PEM-00.04','PEM-00.05','PEM-00.06','PEM-00.07','PEM-00.08',
    'PEM-01.01','PEM-01.02','PEM-01.03','PEM-01.04','PEM-01.05','PEM-01.06',
    'PEM-02.01','PEM-02.02','PEM-02.03','PEM-02.04','PEM-02.05'];
  v_result jsonb:='{}'::jsonb; v_param jsonb; v_i int;
  v_pem00 int:=0; v_pem01 int:=0; v_pem02 int:=0;
begin
  for v_i in 1..array_length(v_keys,1) loop
    v_param:=public.get_sparks_effective_parameter(v_keys[v_i],p_organization_id,'SK-PE',p_project_id);
    v_result:=v_result||jsonb_build_object(v_codes[v_i],v_param);
    if v_codes[v_i] like 'PEM-00.%' then v_pem00:=v_pem00+(v_param->>'value')::int;
    elsif v_codes[v_i] like 'PEM-01.%' then v_pem01:=v_pem01+(v_param->>'value')::int;
    else v_pem02:=v_pem02+(v_param->>'value')::int; end if;
  end loop;
  return jsonb_build_object(
    'phases',v_result,'pem00_total',v_pem00,'pem01_total',v_pem01,
    'pem02_total',v_pem02,'matrix_version','SPARKs PE phase cadence v1'
  );
end; $$;

create or replace function public.get_skpe_journey_cadence_snapshot(
  p_organization_id uuid,p_project_id uuid default null
) returns jsonb language plpgsql security definer set search_path='' as $$
declare
  v_mode jsonb; v_followup jsonb; v_p0 jsonb; v_p1 jsonb; v_p2 jsonb; v_p3 jsonb; v_p4 jsonb;
  v_phase jsonb; v_total int;
begin
  v_mode:=public.get_sparks_effective_parameter('SKPE.JOURNEY.DURATION_MODE',p_organization_id,'SK-PE',p_project_id);
  v_followup:=public.get_sparks_effective_parameter('SKPE.JOURNEY.POST_DELIVERY_FOLLOWUP',p_organization_id,'SK-PE',p_project_id);
  v_p0:=public.get_sparks_effective_parameter('SKPE.JOURNEY.PEM00_DURATION',p_organization_id,'SK-PE',p_project_id);
  v_p1:=public.get_sparks_effective_parameter('SKPE.JOURNEY.PEM01_DURATION',p_organization_id,'SK-PE',p_project_id);
  v_p2:=public.get_sparks_effective_parameter('SKPE.JOURNEY.PEM02_DURATION',p_organization_id,'SK-PE',p_project_id);
  v_p3:=public.get_sparks_effective_parameter('SKPE.JOURNEY.PEM03_DURATION',p_organization_id,'SK-PE',p_project_id);
  v_p4:=public.get_sparks_effective_parameter('SKPE.JOURNEY.PEM04_DURATION',p_organization_id,'SK-PE',p_project_id);
  v_phase:=public.get_skpe_phase_cadence_snapshot(p_organization_id,p_project_id);
  v_total:=(v_phase->>'pem00_total')::int+(v_phase->>'pem01_total')::int+(v_phase->>'pem02_total')::int+(v_p3->>'value')::int+(v_p4->>'value')::int;
  return jsonb_build_object(
    'duration_mode',v_mode,'implementation_total',v_total,
    'pem00',v_p0,'pem01',v_p1,'pem02',v_p2,'pem03',v_p3,'pem04',v_p4,
    'pem00_effective_total',(v_phase->>'pem00_total')::int,
    'pem01_effective_total',(v_phase->>'pem01_total')::int,
    'pem02_effective_total',(v_phase->>'pem02_total')::int,
    'phase_cadence',v_phase,'post_delivery_followup',v_followup
  );
end; $$;

comment on function public.get_skpe_phase_cadence_snapshot(uuid,uuid) is
  'Resolve a cadencia efetiva por Fase de PEM-00, PEM-01 e PEM-02, com proveniencia dos parametros.';
create or replace function public.initialize_skpe_journey_business_day_baseline(p_project_id uuid)
returns uuid language plpgsql security definer set search_path='' as $$
declare
  v_project public.skpe_projects%rowtype; v_version_id uuid; v_existing_id uuid;
  v_start date; v_end date; v_mode text; v_followup int; v_cad jsonb; v_phase jsonb;
  v_p0 int; v_p1 int; v_p2 int; v_p3 int; v_p4 int; v_impl int;
  v_item record; v_seg_start int; v_seg_duration int; v_start_off int; v_end_off int;
  d001 int;d002 int;d003 int;d004 int;d005 int;d006 int;d007 int;d008 int;
  d101 int;d102 int;d103 int;d104 int;d105 int;d106 int;
  d201 int;d202 int;d203 int;d204 int;d205 int;
begin
  if auth.uid() is null then raise exception 'Usuario nao autenticado.' using errcode='42501'; end if;
  select * into v_project from public.skpe_projects where id=p_project_id and archived_at is null;
  if v_project.id is null then raise exception 'Projeto SK-PE ativo nao encontrado.'; end if;
  if not public.can_manage_skpe_journey_schedule(v_project.organization_id) then
    raise exception 'Acesso negado para gerenciar o cronograma da Jornada.' using errcode='42501';
  end if;
  select id into v_existing_id from public.skpe_journey_schedule_versions
  where project_id=p_project_id and schedule_kind='baseline'
    and governance_status in ('draft','pending_approval','approved')
  order by version_number desc limit 1;
  if v_existing_id is not null then return v_existing_id; end if;
  v_cad:=public.get_skpe_journey_cadence_snapshot(v_project.organization_id,v_project.id);
  v_phase:=v_cad->'phase_cadence'->'phases';
  v_mode:=v_cad->'duration_mode'->>'value';
  v_followup:=(v_cad->'post_delivery_followup'->>'value')::int;
  v_p0:=(v_cad->>'pem00_effective_total')::int;
  v_p1:=(v_cad->>'pem01_effective_total')::int;
  v_p2:=(v_cad->>'pem02_effective_total')::int;
  v_p3:=(v_cad->'pem03'->>'value')::int;
  v_p4:=(v_cad->'pem04'->>'value')::int;
  v_impl:=v_p0+v_p1+v_p2+v_p3+v_p4;

  d001:=(v_phase->'PEM-00.01'->>'value')::int; d002:=(v_phase->'PEM-00.02'->>'value')::int;
  d003:=(v_phase->'PEM-00.03'->>'value')::int; d004:=(v_phase->'PEM-00.04'->>'value')::int;
  d005:=(v_phase->'PEM-00.05'->>'value')::int; d006:=(v_phase->'PEM-00.06'->>'value')::int;
  d007:=(v_phase->'PEM-00.07'->>'value')::int; d008:=(v_phase->'PEM-00.08'->>'value')::int;
  d101:=(v_phase->'PEM-01.01'->>'value')::int; d102:=(v_phase->'PEM-01.02'->>'value')::int;
  d103:=(v_phase->'PEM-01.03'->>'value')::int; d104:=(v_phase->'PEM-01.04'->>'value')::int;
  d105:=(v_phase->'PEM-01.05'->>'value')::int; d106:=(v_phase->'PEM-01.06'->>'value')::int;
  d201:=(v_phase->'PEM-02.01'->>'value')::int; d202:=(v_phase->'PEM-02.02'->>'value')::int;
  d203:=(v_phase->'PEM-02.03'->>'value')::int; d204:=(v_phase->'PEM-02.04'->>'value')::int;
  d205:=(v_phase->'PEM-02.05'->>'value')::int;
  v_start:=coalesce(v_project.start_date,current_date);
  v_end:=public.sparks_date_at_offset(v_start,v_impl-1,v_mode);
  update public.skpe_projects
    set target_end_date=v_end,updated_at=timezone('utc',now()),updated_by=auth.uid()
    where id=v_project.id;
  update public.sparks_initiatives si
    set target_end_date=v_end,updated_at=timezone('utc',now()),updated_by=auth.uid()
  from public.skpe_project_initiative_bindings b
  where b.skpe_project_id=v_project.id and b.initiative_id=si.id;

  insert into public.skpe_journey_schedule_versions (
    organization_id,project_id,version_number,schedule_kind,governance_status,
    title,notes,is_current_plan,metadata,created_by,updated_by
  ) values (
    v_project.organization_id,v_project.id,
    coalesce((select max(version_number) from public.skpe_journey_schedule_versions where project_id=p_project_id),0)+1,
    'baseline','draft','Linha de Base Proposta da Jornada Estrategica',
    format('Proposta SPARKs PE com PEM-00, PEM-01 e PEM-02 detalhadas por Fase; implantacao total %s %s.',v_impl,v_mode),
    false,jsonb_build_object(
      'proposal_origin','sparks_parameter_engine','implementation_duration',v_impl,
      'duration_mode',v_mode,'post_delivery_followup',v_followup,
      'cadence_matrix_version','SPARKs PE phase cadence v1','parameter_snapshot',v_cad,
      'internal_allocation','phase_governed_leaf_provisional',
      'methodological_detail_status','pem00_pem01_pem02_phase_configured'
    ),auth.uid(),auth.uid()
  ) returning id into v_version_id;
  for v_item in
    with recursive tree as (
      select ji.id,ji.parent_item_id,ji.code,ji.item_type,ji.display_order,
             ji.code as root_code,null::text as phase_code
      from public.skpe_journey_items ji
      where ji.project_id=p_project_id and ji.archived_at is null and ji.parent_item_id is null
      union all
      select c.id,c.parent_item_id,c.code,c.item_type,c.display_order,t.root_code,
             case when c.item_type='phase' then c.code else t.phase_code end
      from public.skpe_journey_items c
      join tree t on c.parent_item_id=t.id
      where c.project_id=p_project_id and c.archived_at is null
    ), leaves as (
      select t.*,
        row_number() over(partition by coalesce(phase_code,root_code) order by display_order,code)-1 as leaf_index,
        count(*) over(partition by coalesce(phase_code,root_code)) as leaf_count
      from tree t
      where not exists (
        select 1 from public.skpe_journey_items c
        where c.parent_item_id=t.id and c.archived_at is null
      )
    )
    select * from leaves order by display_order,code
  loop
    if v_item.item_type='gate' then
      v_end_off:=case v_item.root_code
        when 'PEM-00' then v_p0-1 when 'PEM-01' then v_p0+v_p1-1
        when 'PEM-02' then v_p0+v_p1+v_p2-1
        when 'PEM-03' then v_p0+v_p1+v_p2+v_p3-1
        when 'PEM-04' then v_impl-1 else v_impl+greatest(v_followup,1)-1 end;
      insert into public.skpe_journey_schedule_items (
        organization_id,project_id,schedule_version_id,journey_item_id,
        planned_start_date,planned_end_date,source_mode,planning_note,
        metadata,created_by,updated_by
      ) values (
        v_project.organization_id,v_project.id,v_version_id,v_item.id,
        null,public.sparks_date_at_offset(v_start,v_end_off,v_mode),'derived',
        'Gate posicionado no fechamento da janela governada; nao consome duracao propria.',
        jsonb_build_object('root_macrophase',v_item.root_code,'allocation_status','governed_milestone','duration_mode',v_mode),
        auth.uid(),auth.uid()
      );
      continue;
    end if;

    if v_item.root_code='PEM-00' then
      v_seg_start:=case v_item.phase_code when 'PEM-00.01' then 0 when 'PEM-00.02' then d001 when 'PEM-00.03' then d001+d002 when 'PEM-00.04' then d001+d002+d003 when 'PEM-00.05' then d001+d002+d003+d004 when 'PEM-00.06' then d001+d002+d003+d004+d005 when 'PEM-00.07' then d001+d002+d003+d004+d005+d006 when 'PEM-00.08' then d001+d002+d003+d004+d005+d006+d007 else 0 end;
      v_seg_duration:=case v_item.phase_code when 'PEM-00.01' then d001 when 'PEM-00.02' then d002 when 'PEM-00.03' then d003 when 'PEM-00.04' then d004 when 'PEM-00.05' then d005 when 'PEM-00.06' then d006 when 'PEM-00.07' then d007 when 'PEM-00.08' then d008 else v_p0 end;
    elsif v_item.root_code='PEM-01' then
      v_seg_start:=v_p0+case v_item.phase_code when 'PEM-01.01' then 0 when 'PEM-01.02' then d101 when 'PEM-01.03' then d101+d102 when 'PEM-01.04' then d101+d102+d103 when 'PEM-01.05' then d101+d102+d103+d104 when 'PEM-01.06' then d101+d102+d103+d104+d105 else 0 end;
      v_seg_duration:=case v_item.phase_code when 'PEM-01.01' then d101 when 'PEM-01.02' then d102 when 'PEM-01.03' then d103 when 'PEM-01.04' then d104 when 'PEM-01.05' then d105 when 'PEM-01.06' then d106 else v_p1 end;
    elsif v_item.root_code='PEM-02' then
      v_seg_start:=v_p0+v_p1+case v_item.phase_code when 'PEM-02.01' then 0 when 'PEM-02.02' then d201 when 'PEM-02.03' then d201+d202 when 'PEM-02.04' then d201+d202+d203 when 'PEM-02.05' then d201+d202+d203+d204 else 0 end;
      v_seg_duration:=case v_item.phase_code when 'PEM-02.01' then d201 when 'PEM-02.02' then d202 when 'PEM-02.03' then d203 when 'PEM-02.04' then d204 when 'PEM-02.05' then d205 else v_p2 end;
    elsif v_item.root_code='PEM-03' then v_seg_start:=v_p0+v_p1+v_p2; v_seg_duration:=v_p3;
    elsif v_item.root_code='PEM-04' then v_seg_start:=v_p0+v_p1+v_p2+v_p3; v_seg_duration:=v_p4;
    elsif v_item.root_code='PEM-05' then v_seg_start:=v_impl; v_seg_duration:=greatest(v_followup,1);
    else continue; end if;

    v_start_off:=v_seg_start+floor((v_item.leaf_index*v_seg_duration::numeric)/v_item.leaf_count)::int;
    v_end_off:=v_seg_start+greatest(floor((v_item.leaf_index*v_seg_duration::numeric)/v_item.leaf_count)::int,floor(((v_item.leaf_index+1)*v_seg_duration::numeric)/v_item.leaf_count)::int-1);
    insert into public.skpe_journey_schedule_items (organization_id,project_id,schedule_version_id,journey_item_id,planned_start_date,planned_end_date,source_mode,planning_note,metadata,created_by,updated_by)
    values (v_project.organization_id,v_project.id,v_version_id,v_item.id,case when v_item.item_type='deliverable' then null else public.sparks_date_at_offset(v_start,v_start_off,v_mode) end,public.sparks_date_at_offset(v_start,v_end_off,v_mode),'derived',case when v_item.root_code in ('PEM-00','PEM-01','PEM-02') then 'Janela da Fase governada; distribuicao entre atividades/entregaveis permanece provisoria.' else 'Janela da Megafase governada; detalhamento por Fase ainda provisório.' end,jsonb_build_object('root_macrophase',v_item.root_code,'phase_code',v_item.phase_code,'allocation_status',case when v_item.root_code in ('PEM-00','PEM-01','PEM-02') then 'phase_governed_leaf_provisional' else 'macrophase_governed_leaf_provisional' end,'duration_mode',v_mode),auth.uid(),auth.uid());
  end loop;
  insert into public.skpe_journey_audit (organization_id,project_id,journey_item_id,actor_user_id,action_code,reason,previous_data,new_data)
  values (v_project.organization_id,v_project.id,null,auth.uid(),'journey_baseline_proposal_initialized','Linha de Base Proposta criada com PEM-00, PEM-01 e PEM-02 governadas por Fase.',null,jsonb_build_object('schedule_version_id',v_version_id,'governance_status','draft','implementation_duration',v_impl,'duration_mode',v_mode,'implementation_target_end_date',v_end,'post_delivery_followup',v_followup,'cadence_matrix_version','SPARKs PE phase cadence v1','parameter_snapshot',v_cad));
  return v_version_id;
end; $$;

comment on function public.initialize_skpe_journey_business_day_baseline(uuid) is
  'Cria Linha de Base Proposta: PEM-00..PEM-02 por Fase; PEM-03..04 por Megafase; Gates como marcos; PEM-05 pos-entrega.';
revoke all on function public.get_skpe_phase_cadence_snapshot(uuid,uuid) from public,anon;
grant execute on function public.get_skpe_phase_cadence_snapshot(uuid,uuid) to authenticated,service_role;
commit;
