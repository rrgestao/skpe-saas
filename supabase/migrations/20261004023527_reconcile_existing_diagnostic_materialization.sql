-- SK-PE - Reconcile already-existing diagnostic targets during governed materialization.
-- For PESTEL/SWOT/TOWS/Risk resolved to an existing canonical entity, do not recreate
-- or overwrite business content. Verify the target and finalize the governed request.

do $$
begin
  if to_regprocedure('public.skpe_execute_governed_import_materialization_diagnostic_preexisting_v1(uuid,text,uuid,jsonb)') is null
     and to_regprocedure('public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)') is not null then
    alter function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
      rename to skpe_execute_governed_import_materialization_diagnostic_preexisting_v1;
  end if;
end $$;

create or replace function public.skpe_execute_governed_import_materialization(
  p_request_id uuid,
  p_materialized_by_actor_type text,
  p_materialized_by_user_id uuid default null,
  p_metadata jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_request public.skpe_import_incorporation_requests%rowtype;
  v_record public.skpe_import_records%rowtype;
  v_resolution public.skpe_import_target_resolution_events%rowtype;
  v_decision public.skpe_import_incorporation_decisions%rowtype;
  v_target_type text;
  v_target_id uuid;
  v_bad_items integer := 0;
  v_target_mismatch integer := 0;
  v_exists boolean := false;
  v_finalize jsonb;
begin
  if p_request_id is null then
    raise exception using errcode='22023', message='p_request_id é obrigatório.';
  end if;

  select * into v_request
  from public.skpe_import_incorporation_requests
  where id=p_request_id;

  if v_request.id is null then
    raise exception using errcode='22023', message='Incorporation Request não encontrado.';
  end if;

  select * into v_record
  from public.skpe_import_records
  where id=v_request.import_record_id;

  if v_record.id is null then
    raise exception using errcode='55000', message='ImportRecord do Request não encontrado.';
  end if;

  if v_record.entity_code not in ('pestel','swot','tows','risk') then
    return public.skpe_execute_governed_import_materialization_diagnostic_preexisting_v1(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,p_metadata
    );
  end if;

  select * into v_resolution
  from public.skpe_import_target_resolution_events e
  where e.import_record_id=v_record.id
    and e.organization_id=v_request.organization_id
    and e.project_id=v_request.project_id
    and e.formulation_id is not distinct from v_request.formulation_id
    and e.resolution_status='resolved'
  order by e.resolution_sequence desc,e.resolved_at desc
  limit 1;

  if v_resolution.id is null or v_resolution.resolution_mode <> 'existing_entity' then
    return public.skpe_execute_governed_import_materialization_diagnostic_preexisting_v1(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,p_metadata
    );
  end if;

  if v_resolution.target_entity_id is null or coalesce(jsonb_array_length(v_resolution.blockers),0) <> 0 then
    raise exception using errcode='55000', message='Resolução existente do Diagnóstico não possui alvo canônico íntegro.';
  end if;

  select * into v_decision
  from public.skpe_import_incorporation_decisions d
  where d.incorporation_request_id=v_request.id
  order by d.decision_sequence desc
  limit 1;

  if v_decision.id is null
     or v_decision.permits_incorporation <> true
     or v_decision.decision_outcome not in ('approved','approved_with_reservations') then
    raise exception using errcode='55000', message='Decisão vigente não permite reconciliação do Diagnóstico.';
  end if;

  select
    count(*) filter (
      where validation_state not in ('validated','validated_with_reservations')
         or item_status <> 'approved'
         or requires_human_review=true
         or extraction_mode='inferred'
    ),
    count(*) filter (
      where target_resolution_mode <> 'existing_entity'
         or target_resolution_state <> 'resolved'
         or target_entity_id is distinct from v_resolution.target_entity_id
    )
  into v_bad_items,v_target_mismatch
  from public.skpe_import_incorporation_items
  where incorporation_request_id=v_request.id;

  if v_bad_items <> 0 then
    raise exception using errcode='55000', message='Todos os Incorporation Items do Diagnóstico devem estar validados e aprovados.';
  end if;

  if v_target_mismatch <> 0 then
    raise exception using errcode='55000', message='Incorporation Items do Diagnóstico divergem do alvo canônico reconciliado.';
  end if;

  if v_record.entity_code='pestel' then
    v_target_type:='pestel_item';
    select exists(
      select 1 from public.skpe_pestel_items t
      where t.id=v_resolution.target_entity_id
        and t.organization_id=v_request.organization_id
        and t.project_id=v_request.project_id
        and t.archived_at is null
    ) into v_exists;
  elsif v_record.entity_code='swot' then
    v_target_type:='swot_item';
    select exists(
      select 1 from public.skpe_swot_items t
      where t.id=v_resolution.target_entity_id
        and t.organization_id=v_request.organization_id
        and t.project_id=v_request.project_id
        and t.archived_at is null
    ) into v_exists;
  elsif v_record.entity_code='tows' then
    v_target_type:='tows_item';
    select exists(
      select 1 from public.skpe_tows_items t
      where t.id=v_resolution.target_entity_id
        and t.organization_id=v_request.organization_id
        and t.project_id=v_request.project_id
        and t.archived_at is null
    ) into v_exists;
  else
    v_target_type:='strategic_risk_item';
    select exists(
      select 1 from public.skpe_strategic_risk_items t
      where t.id=v_resolution.target_entity_id
        and t.organization_id=v_request.organization_id
        and t.project_id=v_request.project_id
        and t.archived_at is null
    ) into v_exists;
  end if;

  if not v_exists then
    raise exception using errcode='55000', message='Alvo canônico existente do Diagnóstico não pôde ser verificado no mesmo projeto.';
  end if;

  v_target_id:=v_resolution.target_entity_id;

  v_finalize:=public.skpe_finalize_governed_import_materialization(
    p_request_id,
    v_target_type,
    v_target_id,
    p_materialized_by_actor_type,
    p_materialized_by_user_id,
    p_metadata || jsonb_build_object(
      'dispatcher','skpe_execute_governed_import_materialization',
      'dispatcher_version','DIAGNOSTIC-EXISTING-RECON-V1',
      'reconciliation_only',true,
      'existing_target_reused',true,
      'business_content_updated',false,
      'historical_business_approval_preserved',true,
      'semantic_inference',false
    )
  );

  return jsonb_build_object(
    'request_id',v_request.id,
    'import_record_id',v_record.id,
    'source_family',v_record.entity_code,
    'materialized_entity_type',v_target_type,
    'materialized_entity_id',v_target_id,
    'reconciliation_only',true,
    'existing_target_reused',true,
    'business_content_updated',false,
    'finalization',v_finalize,
    'dispatcher','skpe_execute_governed_import_materialization',
    'dispatcher_version','DIAGNOSTIC-EXISTING-RECON-V1'
  );
end;
$function$;

revoke all on function public.skpe_execute_governed_import_materialization_diagnostic_preexisting_v1(uuid,text,uuid,jsonb)
  from public,anon,authenticated;
grant execute on function public.skpe_execute_governed_import_materialization_diagnostic_preexisting_v1(uuid,text,uuid,jsonb)
  to service_role;

revoke all on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
  from public,anon,authenticated;
grant execute on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
  to service_role;
