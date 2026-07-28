-- SPARKs PE - Bloco 1.10B-5
-- Tratamento assistido do registro bloqueado version_control:v17.
-- Nao executa carga definitiva.

create or replace function public.skpe_get_blocked_import_record_review(
  p_batch_id uuid,
  p_external_key text
)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'auth'
as $function$
declare
  v_batch public.skpe_import_batches%rowtype;
  v_record public.skpe_import_records%rowtype;
  v_suggested jsonb;
begin
  select * into v_batch from public.skpe_import_batches where id=p_batch_id;
  if v_batch.id is null then raise exception 'Lote nao encontrado.'; end if;
  if not public.can_manage_skpe_journey(v_batch.organization_id) then
    raise exception 'Usuario sem permissao para revisar este lote.';
  end if;
  select * into v_record
  from public.skpe_import_records
  where batch_id=p_batch_id and external_key=p_external_key;
  if v_record.id is null then raise exception 'Registro nao encontrado.'; end if;
  if v_record.simulation_status <> 'blocked' then
    raise exception 'O registro informado nao esta bloqueado. Situacao atual: %', v_record.simulation_status;
  end if;

  v_suggested := case when p_external_key='version_control:v17' then
    jsonb_build_object(
      'versao','v17',
      'data','24/07/2026',
      'arquivo',v_batch.source_file,
      'base','v16',
      'alteracoes_principais',coalesce(v_record.values_json->>'arquivo',''),
      'dados_preservados','Sim',
      'validacao','Em validacao',
      'responsavel',coalesce(v_record.values_json->>'base','Consultoria'),
      'status',coalesce(v_record.values_json->>'alteracoes_principais','Atual'),
      'observacoes',coalesce(v_record.values_json->>'dados_preservados','Substitui v16')
    )
  else v_record.values_json end;

  return jsonb_build_object(
    'batchId',v_batch.id,
    'recordId',v_record.id,
    'entityCode',v_record.entity_code,
    'externalKey',v_record.external_key,
    'sourceSheet',v_record.source_sheet,
    'sourceRow',v_record.source_row,
    'currentValues',v_record.values_json,
    'suggestedValues',v_suggested,
    'validationMessages',v_record.validation_messages,
    'requiresHumanConfirmation',true,
    'inferenceNotice','A proposta reorganiza os campos deslocados e deve ser validada por uma pessoa antes da liberacao.'
  );
end;
$function$;

create or replace function public.skpe_approve_blocked_import_record_correction(
  p_batch_id uuid,
  p_external_key text,
  p_corrected_values jsonb,
  p_review_notes text,
  p_confirm boolean
)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'auth'
as $function$
declare
  v_batch public.skpe_import_batches%rowtype;
  v_record public.skpe_import_records%rowtype;
  v_blocked integer;
  v_invalid integer;
  v_pending integer;
begin
  if coalesce(p_confirm,false) is not true then
    raise exception 'A confirmacao humana e obrigatoria.';
  end if;
  if nullif(btrim(coalesce(p_review_notes,'')),'') is null then
    raise exception 'Informe a justificativa da revisao.';
  end if;
  if p_corrected_values is null or jsonb_typeof(p_corrected_values) <> 'object' then
    raise exception 'Os valores corrigidos devem ser um objeto JSON.';
  end if;

  select * into v_batch from public.skpe_import_batches where id=p_batch_id;
  if v_batch.id is null then raise exception 'Lote nao encontrado.'; end if;
  if not public.can_manage_skpe_journey(v_batch.organization_id) then
    raise exception 'Usuario sem permissao para corrigir este lote.';
  end if;
  if v_batch.status not in ('reviewed','ready') then
    raise exception 'O lote precisa estar revisado. Status atual: %',v_batch.status;
  end if;

  select * into v_record
  from public.skpe_import_records
  where batch_id=p_batch_id and external_key=p_external_key
  for update;
  if v_record.id is null then raise exception 'Registro nao encontrado.'; end if;
  if v_record.simulation_status <> 'blocked' then
    raise exception 'O registro nao esta bloqueado. Situacao atual: %',v_record.simulation_status;
  end if;

  update public.skpe_import_records
  set values_json=p_corrected_values,
      fingerprint=md5(p_corrected_values::text),
      quality_status='valid',
      simulation_status='new',
      proposed_action='insert',
      reviewed=true,
      review_decision='manual_correction_approved',
      review_notes=p_review_notes,
      reviewed_at=timezone('utc',now()),
      reviewed_by=auth.uid(),
      validation_messages=coalesce(validation_messages,'[]'::jsonb) || jsonb_build_array(jsonb_build_object(
        'code','MANUAL_CORRECTION_APPROVED',
        'severity','info',
        'message','Campos desalinhados reorganizados e validados por usuario autorizado.',
        'reviewNotes',p_review_notes
      ))
  where id=v_record.id;

  select
    count(*) filter(where simulation_status='blocked'),
    count(*) filter(where simulation_status='invalid'),
    count(*) filter(where simulation_status='pending_mapping')
  into v_blocked,v_invalid,v_pending
  from public.skpe_import_records where batch_id=p_batch_id;

  update public.skpe_import_batches
  set blocked_record_count=v_blocked,
      valid_record_count=(select count(*) from public.skpe_import_records where batch_id=p_batch_id and quality_status='valid'),
      status='reviewed',
      payload_metadata=coalesce(payload_metadata,'{}'::jsonb) || jsonb_build_object(
        'lastManualCorrectionAt',timezone('utc',now()),
        'lastManualCorrectionExternalKey',p_external_key,
        'readyForReassessment',v_blocked=0 and v_invalid=0 and v_pending=0
      )
  where id=p_batch_id;

  insert into public.skpe_import_events(batch_id,organization_id,project_id,event_code,event_data)
  values(v_batch.id,v_batch.organization_id,v_batch.project_id,'IMPORT_BLOCKED_RECORD_CORRECTED',jsonb_build_object(
    'externalKey',p_external_key,
    'recordId',v_record.id,
    'reviewNotes',p_review_notes,
    'remainingBlocked',v_blocked,
    'databaseWritesDefinitive',false
  ));

  return jsonb_build_object(
    'corrected',true,
    'batchId',p_batch_id,
    'recordId',v_record.id,
    'externalKey',p_external_key,
    'remainingBlocked',v_blocked,
    'remainingInvalid',v_invalid,
    'remainingPending',v_pending,
    'readyForReassessment',v_blocked=0 and v_invalid=0 and v_pending=0
  );
end;
$function$;

grant execute on function public.skpe_get_blocked_import_record_review(uuid,text) to authenticated;
grant execute on function public.skpe_approve_blocked_import_record_correction(uuid,text,jsonb,text,boolean) to authenticated;
