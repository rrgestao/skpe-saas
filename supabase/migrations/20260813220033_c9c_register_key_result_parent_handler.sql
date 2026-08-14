insert into public.skpe_incorporation_resolution_handlers(
  handler_code,handler_name,description,handler_type,handler_version,status,
  input_contract,output_contract,configuration_contract,allows_semantic_inference,metadata
)
select
  'key_result_parent_okr_candidate',
  'Key Result por OKR pai canônico',
  'Resolve deterministicamente o candidato canônico de Key Result a partir do código do KR e do OKR pai informado na origem, exigindo OKR materializado e Objetivo Estratégico primário no mesmo projeto e formulação.',
  'custom',1,'active',
  '{"required":["source_value","project_id","formulation_id","import_record_id"]}'::jsonb,
  '{"fields":["target_entity_id","target_external_key","target_reference","resolution_status","resolution_mode","resolution_details","warnings","blockers","requires_human_review"]}'::jsonb,
  '{"required":["formulation_id","import_record_id"],"defaults":{"same_project":true,"same_formulation":true}}'::jsonb,
  false,
  '{"roadmap_step":"CO-IMPORT-04-C9-C","deterministic":true,"semantic_inference":false,"materializes_entity":false,"parent_relation":"okr","objective_relation":"primary_objective_of_parent_okr"}'::jsonb
where not exists (
  select 1 from public.skpe_incorporation_resolution_handlers where handler_code='key_result_parent_okr_candidate'
);

create or replace function public.skpe_execute_incorporation_resolution_handler(p_handler_code text,p_source_value text,p_project_id uuid,p_config jsonb)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_handler public.skpe_incorporation_resolution_handlers%rowtype;
begin
  if nullif(btrim(p_handler_code),'') is null then
    raise exception using errcode='22023',message='resolver_handler_code é obrigatório.';
  end if;
  select * into v_handler from public.skpe_incorporation_resolution_handlers where handler_code=p_handler_code;
  if v_handler.id is null then
    raise exception using errcode='55000',message='Handler de resolução não cadastrado.';
  end if;
  if v_handler.status <> 'active' then
    raise exception using errcode='55000',message='Handler de resolução não está ativo.';
  end if;
  case p_handler_code
    when 'journey_item_by_numeric_token' then
      return public.skpe_execute_resolution_handler_journey_item_by_numeric_token(p_source_value,p_project_id,p_config);
    when 'create_new_entity_by_source_key' then
      return public.skpe_execute_resolution_handler_create_new_entity_by_source_key(p_source_value,p_project_id,p_config);
    when 'canonical_entity_by_code' then
      return public.skpe_execute_resolution_handler_canonical_entity_by_code(p_source_value,p_project_id,p_config);
    when 'cross_sheet_positional_create_new_candidate' then
      return public.skpe_execute_resolution_handler_cross_sheet_positional_create_new_candidate(p_source_value,p_project_id,p_config);
    when 'key_result_parent_okr_candidate' then
      return public.skpe_execute_resolution_handler_key_result_parent_okr_candidate(p_source_value,p_project_id,p_config);
    else
      raise exception using errcode='0A000',message='Handler cadastrado ainda não possui executor implementado.';
  end case;
end;
$function$;