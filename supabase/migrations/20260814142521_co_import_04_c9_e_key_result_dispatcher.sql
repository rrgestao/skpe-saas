do $$
begin
  if to_regprocedure('public.skpe_execute_governed_import_materialization_c8(uuid,text,uuid,jsonb)') is null
     and to_regprocedure('public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)') is not null then
    alter function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
      rename to skpe_execute_governed_import_materialization_c8;
  end if;
end;
$$;

CREATE OR REPLACE FUNCTION public.skpe_execute_governed_import_materialization(p_request_id uuid, p_materialized_by_actor_type text, p_materialized_by_user_id uuid DEFAULT NULL::uuid, p_metadata jsonb DEFAULT '{}'::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_request public.skpe_import_incorporation_requests%rowtype;
  v_record public.skpe_import_records%rowtype;
  v_entity_id uuid;
  v_finalize jsonb;
begin
  if p_request_id is null then raise exception using errcode='22023',message='p_request_id é obrigatório.'; end if;
  select * into v_request from public.skpe_import_incorporation_requests where id=p_request_id;
  if v_request.id is null then raise exception using errcode='22023',message='Incorporation Request não encontrado.'; end if;
  select * into v_record from public.skpe_import_records where id=v_request.import_record_id;
  if v_record.id is null then raise exception using errcode='55000',message='ImportRecord do Request não encontrado.'; end if;

  if v_record.entity_code <> 'key_result' then
    return public.skpe_execute_governed_import_materialization_c8(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,p_metadata
    );
  end if;

  if v_request.request_status='applied' then
    begin v_entity_id:=nullif(v_request.metadata->>'materialized_target_entity_id','')::uuid;
    exception when invalid_text_representation then
      raise exception using errcode='55000',message='Request applied possui materialized_target_entity_id inválido.';
    end;
    if v_request.metadata->>'materialized_target_entity_type'<>'key_result' or v_entity_id is null
       or not exists(select 1 from public.skpe_key_results where id=v_entity_id) then
      raise exception using errcode='55000',message='Request key_result applied não possui alvo materializado verificável.';
    end if;
    return jsonb_build_object(
      'request_id',v_request.id,'import_record_id',v_record.id,'source_family','key_result',
      'handler_name','skpe_materialize_import_request_as_key_result',
      'context_target_id',null,'materialized_entity_type','key_result','materialized_entity_id',v_entity_id,
      'request_status','applied','already_materialized',true,'already_finalized',true,
      'dispatcher','skpe_execute_governed_import_materialization','dispatcher_version','C9-E'
    );
  end if;

  v_entity_id:=public.skpe_materialize_import_request_as_key_result(
    p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
    p_metadata||jsonb_build_object(
      'dispatcher','skpe_execute_governed_import_materialization','dispatcher_version','C9-E',
      'source_family','key_result','target_family','key_result','roadmap_step','CO-IMPORT-04-C9-E',
      'technical_incorporation',true,'institutional_validation',false,
      'institutional_validation_pending',true,'semantic_inference',false
    )
  );

  v_finalize:=public.skpe_finalize_governed_import_materialization(
    p_request_id,'key_result',v_entity_id,p_materialized_by_actor_type,p_materialized_by_user_id,
    p_metadata||jsonb_build_object(
      'dispatcher','skpe_execute_governed_import_materialization','dispatcher_version','C9-E',
      'handler_name','skpe_materialize_import_request_as_key_result','roadmap_step','CO-IMPORT-04-C9-E',
      'technical_incorporation',true,'institutional_validation',false,
      'institutional_validation_pending',true,'semantic_inference',false
    )
  );

  return jsonb_build_object(
    'request_id',v_request.id,'import_record_id',v_record.id,'source_family','key_result',
    'handler_name','skpe_materialize_import_request_as_key_result','context_target_id',null,
    'materialized_entity_type','key_result','materialized_entity_id',v_entity_id,
    'request_status','applied','already_materialized',false,'already_finalized',false,
    'finalization',v_finalize,'dispatcher','skpe_execute_governed_import_materialization',
    'dispatcher_version','C9-E'
  );
end;
$function$;

revoke all on function public.skpe_execute_governed_import_materialization_c8(uuid,text,uuid,jsonb) from public,anon,authenticated;
grant execute on function public.skpe_execute_governed_import_materialization_c8(uuid,text,uuid,jsonb) to service_role;
revoke all on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb) from public;
grant execute on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb) to authenticated,service_role;
