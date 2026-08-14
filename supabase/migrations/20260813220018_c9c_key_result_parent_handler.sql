create or replace function public.skpe_execute_resolution_handler_key_result_parent_okr_candidate(p_source_value text,p_project_id uuid,p_config jsonb)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_kr_code text := nullif(btrim(p_source_value),'');
  v_formulation_id uuid;
  v_import_record_id uuid;
  v_parent_code text;
  v_parent_id uuid;
  v_parent_title text;
  v_parent_count integer;
  v_objective_id uuid;
  v_objective_code text;
  v_objective_name text;
  v_objective_count integer;
begin
  if p_config is null or jsonb_typeof(p_config) <> 'object' then
    raise exception using errcode='22023',message='Configuração do handler deve ser objeto JSON.';
  end if;
  if p_project_id is null or v_kr_code is null then
    return jsonb_build_object('resolution_status','blocked','resolution_mode','unresolved','target_entity_id',null,'target_external_key',v_kr_code,'warnings','[]'::jsonb,'blockers',jsonb_build_array(jsonb_build_object('code','KEY_RESULT_RESOLUTION_INPUT_MISSING')),'requires_human_review',true);
  end if;
  begin
    v_formulation_id := nullif(btrim(p_config->>'formulation_id'),'')::uuid;
    v_import_record_id := nullif(btrim(p_config->>'import_record_id'),'')::uuid;
  exception when others then
    raise exception using errcode='22023',message='formulation_id/import_record_id inválido no resolver_config.';
  end;
  select nullif(btrim(r.values_json->>'okr'),'') into v_parent_code
  from public.skpe_import_records r
  where r.id=v_import_record_id and r.project_id=p_project_id and r.entity_code='key_result';
  if v_parent_code is null then
    return jsonb_build_object('resolution_status','blocked','resolution_mode','unresolved','target_entity_id',null,'target_external_key',v_kr_code,'warnings','[]'::jsonb,'blockers',jsonb_build_array(jsonb_build_object('code','PARENT_OKR_CODE_MISSING')),'requires_human_review',true);
  end if;
  select count(*) into v_parent_count
  from public.skpe_okrs o
  where o.project_id=p_project_id and o.formulation_id=v_formulation_id and o.code=v_parent_code;
  if v_parent_count=0 then
    return jsonb_build_object('resolution_status','requires_review','resolution_mode','unresolved','target_entity_id',null,'target_external_key',v_parent_code||':'||v_kr_code,'target_reference',jsonb_build_object('entity_type','key_result','code',v_kr_code,'parent_okr_code',v_parent_code),'resolution_details',jsonb_build_object('parent_match_count',0,'match_strategy','exact_parent_okr_then_primary_objective','semantic_inference',false),'warnings',jsonb_build_array(jsonb_build_object('code','PARENT_OKR_NOT_MATERIALIZED','parent_okr_code',v_parent_code)),'blockers','[]'::jsonb,'requires_human_review',true);
  elsif v_parent_count>1 then
    return jsonb_build_object('resolution_status','blocked','resolution_mode','unresolved','target_entity_id',null,'target_external_key',v_parent_code||':'||v_kr_code,'warnings','[]'::jsonb,'blockers',jsonb_build_array(jsonb_build_object('code','PARENT_OKR_AMBIGUOUS','match_count',v_parent_count)),'requires_human_review',true);
  end if;
  select o.id,o.title into v_parent_id,v_parent_title
  from public.skpe_okrs o
  where o.project_id=p_project_id and o.formulation_id=v_formulation_id and o.code=v_parent_code;
  select count(*) into v_objective_count
  from public.skpe_okr_objectives oo
  join public.skpe_strategic_objectives so on so.id=oo.strategic_objective_id
  where oo.okr_id=v_parent_id and oo.is_primary=true and so.project_id=p_project_id and so.formulation_id=v_formulation_id;
  if v_objective_count=0 then
    return jsonb_build_object('resolution_status','requires_review','resolution_mode','unresolved','target_entity_id',null,'target_external_key',v_parent_code||':'||v_kr_code,'target_reference',jsonb_build_object('entity_type','key_result','code',v_kr_code,'parent_okr_id',v_parent_id,'parent_okr_code',v_parent_code),'warnings',jsonb_build_array(jsonb_build_object('code','PRIMARY_STRATEGIC_OBJECTIVE_NOT_FOUND')),'blockers','[]'::jsonb,'requires_human_review',true);
  elsif v_objective_count>1 then
    return jsonb_build_object('resolution_status','blocked','resolution_mode','unresolved','target_entity_id',null,'target_external_key',v_parent_code||':'||v_kr_code,'warnings','[]'::jsonb,'blockers',jsonb_build_array(jsonb_build_object('code','PRIMARY_STRATEGIC_OBJECTIVE_AMBIGUOUS','match_count',v_objective_count)),'requires_human_review',true);
  end if;
  select so.id,so.code,so.name into v_objective_id,v_objective_code,v_objective_name
  from public.skpe_okr_objectives oo join public.skpe_strategic_objectives so on so.id=oo.strategic_objective_id
  where oo.okr_id=v_parent_id and oo.is_primary=true and so.project_id=p_project_id and so.formulation_id=v_formulation_id;
  return jsonb_build_object('resolution_status','resolved','resolution_mode','create_new_entity','target_entity_id',null,'target_external_key',v_parent_code||':'||v_kr_code,'target_reference',jsonb_build_object('entity_type','key_result','code',v_kr_code,'parent_okr_id',v_parent_id,'parent_okr_code',v_parent_code,'parent_okr_title',v_parent_title,'strategic_objective_id',v_objective_id,'strategic_objective_code',v_objective_code,'strategic_objective_name',v_objective_name,'project_id',p_project_id,'formulation_id',v_formulation_id),'resolution_details',jsonb_build_object('parent_match_count',1,'primary_objective_match_count',1,'match_strategy','exact_parent_okr_then_primary_objective','semantic_inference',false),'warnings','[]'::jsonb,'blockers','[]'::jsonb,'requires_human_review',true);
end;
$function$;