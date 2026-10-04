-- SK-PE - Close legacy ImportRecord review from governed incorporation item review.
-- This bridges the legacy record-level review flags with the newer item-level governed review.
-- It does not create incorporation decisions and does not materialize business entities.

create or replace function public.skpe_confirm_import_record_from_governed_review(
  p_request_id uuid,
  p_reviewer_actor_type text,
  p_reviewer_user_id uuid default null,
  p_review_reason text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_request public.skpe_import_incorporation_requests%rowtype;
  v_record public.skpe_import_records%rowtype;
  v_total integer := 0;
  v_pending integer := 0;
  v_rejected integer := 0;
  v_inferred integer := 0;
  v_with_reservations integer := 0;
  v_outcome text;
  v_reservations jsonb := '[]'::jsonb;
  v_previous_id uuid;
  v_previous_sequence integer := 0;
  v_event_id uuid;
begin
  if p_request_id is null then
    raise exception using errcode='22023', message='p_request_id é obrigatório.';
  end if;
  if p_reviewer_actor_type not in ('organization','sparks_consultancy','external_consultancy','system','ai','unknown') then
    raise exception using errcode='22023', message='p_reviewer_actor_type inválido.';
  end if;
  if btrim(coalesce(p_review_reason,''))='' then
    raise exception using errcode='22023', message='p_review_reason é obrigatório.';
  end if;
  if p_metadata is null or jsonb_typeof(p_metadata)<>'object' then
    raise exception using errcode='22023', message='p_metadata deve ser objeto JSON.';
  end if;

  select * into v_request
  from public.skpe_import_incorporation_requests
  where id=p_request_id;

  if v_request.id is null then
    raise exception using errcode='22023', message='Solicitação de incorporação não encontrada.';
  end if;

  select * into v_record
  from public.skpe_import_records
  where id=v_request.import_record_id;

  if v_record.id is null then
    raise exception using errcode='55000', message='ImportRecord relacionado não encontrado.';
  end if;

  select
    count(*),
    count(*) filter (where validation_state not in ('validated','validated_with_reservations')),
    count(*) filter (where validation_state='rejected' or item_status='rejected'),
    count(*) filter (where extraction_mode='inferred'),
    count(*) filter (where validation_state='validated_with_reservations')
  into v_total,v_pending,v_rejected,v_inferred,v_with_reservations
  from public.skpe_import_incorporation_items
  where incorporation_request_id=p_request_id;

  if v_total=0 then
    raise exception using errcode='55000', message='Request não possui itens governados para revisão.';
  end if;
  if v_pending>0 then
    raise exception using errcode='55000', message='ImportRecord não pode ser confirmado enquanto houver itens pendentes de validação.';
  end if;
  if v_rejected>0 then
    raise exception using errcode='55000', message='ImportRecord não pode ser confirmado enquanto houver itens rejeitados.';
  end if;
  if v_inferred>0 then
    raise exception using errcode='55000', message='ImportRecord não pode ser confirmado enquanto houver itens inferidos sem consolidação humana.';
  end if;

  v_outcome := case when v_with_reservations>0 then 'approved_with_reservations' else 'approved' end;
  if v_with_reservations>0 then
    v_reservations := jsonb_build_array(jsonb_build_object(
      'code','INCORPORATION_ITEMS_VALIDATED_WITH_RESERVATIONS',
      'message','O registro foi confirmado a partir da revisão governada dos itens, preservando as ressalvas registradas nos itens.'
    ));
  end if;

  select id,review_sequence into v_previous_id,v_previous_sequence
  from public.skpe_import_record_review_events
  where import_record_id=v_record.id
  order by review_sequence desc
  limit 1;

  if v_previous_id is not null
     and exists (
       select 1
       from public.skpe_import_record_review_events
       where id=v_previous_id
         and incorporation_request_id=p_request_id
         and review_outcome=v_outcome
         and metadata->>'governed_item_review_bridge'='true'
     ) then
    return v_previous_id;
  end if;

  insert into public.skpe_import_record_review_events(
    import_record_id,incorporation_request_id,review_sequence,review_outcome,
    reviewer_actor_type,reviewer_user_id,review_reason,reservations,
    supersedes_review_id,metadata
  )
  values(
    v_record.id,p_request_id,coalesce(v_previous_sequence,0)+1,v_outcome,
    p_reviewer_actor_type,p_reviewer_user_id,p_review_reason,v_reservations,
    v_previous_id,
    p_metadata || jsonb_build_object(
      'governed_item_review_bridge',true,
      'materialization_requested',false,
      'business_decision_created',false,
      'semantic_inference',false,
      'validated_item_count',v_total,
      'validated_with_reservations_count',v_with_reservations
    )
  )
  returning id into v_event_id;

  update public.skpe_import_records
  set reviewed=true,
      review_decision=v_outcome,
      review_notes=p_review_reason,
      reviewed_at=timezone('utc',now()),
      reviewed_by=p_reviewer_user_id,
      metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object(
        'governed_item_review_bridge',true,
        'latest_record_review_event_id',v_event_id,
        'materialization_requested',false,
        'business_decision_created',false
      )
  where id=v_record.id;

  return v_event_id;
end;
$function$;

revoke all on function public.skpe_confirm_import_record_from_governed_review(uuid,text,uuid,text,jsonb) from public;
revoke all on function public.skpe_confirm_import_record_from_governed_review(uuid,text,uuid,text,jsonb) from authenticated;
grant execute on function public.skpe_confirm_import_record_from_governed_review(uuid,text,uuid,text,jsonb) to service_role;
