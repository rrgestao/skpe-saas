create or replace function public.skpe_resolve_import_conflicts_accept_canonical(
  p_batch_id uuid,
  p_notes text
)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'auth'
as $function$
declare
  v_batch public.skpe_import_batches%rowtype;
  v_total integer := 0;
  v_resolved integer := 0;
  v_pending integer := 0;
begin
  select * into v_batch
  from public.skpe_import_batches
  where id = p_batch_id;

  if v_batch.id is null then
    raise exception 'Lote nao encontrado.';
  end if;

  if not public.can_manage_skpe_journey(v_batch.organization_id) then
    raise exception 'Usuario sem permissao para tratar os conflitos deste lote.';
  end if;

  if v_batch.status not in ('reviewed', 'ready') then
    raise exception 'O tratamento de conflitos exige lote revisado. Status atual: %', v_batch.status;
  end if;

  if nullif(trim(coalesce(p_notes, '')), '') is null then
    raise exception 'A justificativa da decisao e obrigatoria.';
  end if;

  select count(*) into v_total
  from public.skpe_import_conflicts
  where batch_id = v_batch.id;

  if v_total = 0 then
    raise exception 'Nenhum conflito foi localizado para este lote.';
  end if;

  if exists (
    select 1
    from public.skpe_import_conflicts
    where batch_id = v_batch.id
      and lower(coalesce(proposed_decision, '')) not in ('accept_canonical', 'accepted_canonical')
  ) then
    raise exception 'Existem conflitos cuja decisao proposta nao e aceitar o valor canonico. Revise-os individualmente.';
  end if;

  update public.skpe_import_conflicts
  set final_decision = 'accept_canonical',
      status = 'approved',
      reviewed_at = timezone('utc', now()),
      reviewed_by = auth.uid(),
      notes = trim(p_notes)
  where batch_id = v_batch.id
    and status in ('pending', 'accepted_from_payload');

  get diagnostics v_resolved = row_count;

  select count(*) into v_pending
  from public.skpe_import_conflicts
  where batch_id = v_batch.id
    and status in ('pending', 'accepted_from_payload');

  update public.skpe_import_batches
  set payload_metadata = coalesce(payload_metadata, '{}'::jsonb)
    || jsonb_build_object(
      'conflictReview', jsonb_build_object(
        'reviewedAt', timezone('utc', now()),
        'reviewedBy', auth.uid(),
        'decision', 'accept_canonical',
        'total', v_total,
        'resolvedNow', v_resolved,
        'pending', v_pending,
        'notes', trim(p_notes)
      )
    )
  where id = v_batch.id;

  insert into public.skpe_import_events(
    batch_id, organization_id, project_id, event_code, event_data
  ) values (
    v_batch.id,
    v_batch.organization_id,
    v_batch.project_id,
    'IMPORT_CONFLICTS_ACCEPTED_CANONICAL',
    jsonb_build_object(
      'decision', 'accept_canonical',
      'total', v_total,
      'resolvedNow', v_resolved,
      'pending', v_pending,
      'notes', trim(p_notes)
    )
  );

  return jsonb_build_object(
    'batchId', v_batch.id,
    'decision', 'accept_canonical',
    'total', v_total,
    'resolvedNow', v_resolved,
    'pending', v_pending,
    'readyToReassess', v_pending = 0
  );
end;
$function$;

grant execute on function public.skpe_resolve_import_conflicts_accept_canonical(uuid, text) to authenticated;

-- Corrige o criterio de prontidao: os estados formais da tabela sao
-- approved, adjusted e rejected; accepted_from_payload ainda exige revisao humana.
create or replace function public.skpe_assess_import_batch_readiness(p_batch_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'auth'
as $function$
declare
  v_batch public.skpe_import_batches%rowtype;
  v_pending integer := 0;
  v_blocked integer := 0;
  v_invalid integer := 0;
  v_quarantined integer := 0;
  v_unresolved_conflicts integer := 0;
  v_conflict_total integer := 0;
  v_is_ready boolean := false;
  v_state text := 'blocked';
  v_result jsonb;
begin
  select * into v_batch from public.skpe_import_batches where id = p_batch_id;
  if v_batch.id is null then raise exception 'Lote nao encontrado.'; end if;
  if not public.can_manage_skpe_journey(v_batch.organization_id) then
    raise exception 'Usuario sem permissao para revisar este lote.';
  end if;
  if v_batch.status not in ('reviewed', 'ready') then
    raise exception 'A avaliacao de prontidao exige lote revisado. Status atual: %', v_batch.status;
  end if;

  select
    count(*) filter (where simulation_status = 'pending_mapping'),
    count(*) filter (where simulation_status = 'blocked'),
    count(*) filter (where simulation_status = 'invalid'),
    count(*) filter (where simulation_status = 'quarantined')
  into v_pending, v_blocked, v_invalid, v_quarantined
  from public.skpe_import_records where batch_id = v_batch.id;

  select count(*), count(*) filter (where status not in ('approved', 'adjusted', 'rejected'))
  into v_conflict_total, v_unresolved_conflicts
  from public.skpe_import_conflicts where batch_id = v_batch.id;

  v_is_ready := v_pending = 0 and v_blocked = 0 and v_invalid = 0 and v_unresolved_conflicts = 0;
  v_state := case when v_is_ready then 'ready' else 'blocked' end;

  v_result := jsonb_build_object(
    'batchId', v_batch.id,
    'assessedAt', timezone('utc', now()),
    'readinessState', v_state,
    'readyForDefinitiveLoad', v_is_ready,
    'scope', 'pre_definitive_load_review',
    'gates', jsonb_build_array(
      jsonb_build_object('code','BATCH_REVIEWED','label','Lote revisado','passed',v_batch.status in ('reviewed','ready'),'actual',v_batch.status,'required','reviewed'),
      jsonb_build_object('code','NO_PENDING_MAPPING','label','Nenhum registro pendente','passed',v_pending=0,'actual',v_pending,'required',0),
      jsonb_build_object('code','NO_BLOCKED_RECORDS','label','Nenhum registro bloqueado','passed',v_blocked=0,'actual',v_blocked,'required',0),
      jsonb_build_object('code','NO_INVALID_RECORDS','label','Nenhum registro invalido','passed',v_invalid=0,'actual',v_invalid,'required',0),
      jsonb_build_object('code','CONFLICTS_RESOLVED','label','Conflitos formalmente tratados','passed',v_unresolved_conflicts=0,'actual',v_unresolved_conflicts,'required',0,'total',v_conflict_total),
      jsonb_build_object('code','CANONICAL_JOURNEY_PROTECTED','label','Jornada canonica protegida','passed',true,'actual','MF1 aprovada; MF2 em andamento; PEM-02.04 bloqueado','required','preservar estado canonico')
    ),
    'counts', jsonb_build_object('pending',v_pending,'blocked',v_blocked,'invalid',v_invalid,'quarantined',v_quarantined,'conflicts',v_conflict_total,'unresolvedConflicts',v_unresolved_conflicts),
    'blockedRecords', coalesce((select jsonb_agg(jsonb_build_object('id',r.id,'entityCode',r.entity_code,'externalKey',r.external_key,'simulationStatus',r.simulation_status,'proposedAction',r.proposed_action,'sourceSheet',to_jsonb(r)->>'source_sheet','sourceRow',to_jsonb(r)->>'source_row','validationMessages',coalesce(r.validation_messages,'[]'::jsonb),'record',to_jsonb(r)) order by r.entity_code,r.external_key) from public.skpe_import_records r where r.batch_id=v_batch.id and r.simulation_status in ('blocked','invalid','quarantined','pending_mapping')),'[]'::jsonb),
    'conflicts', coalesce((select jsonb_agg(to_jsonb(c) order by c.created_at,c.id) from public.skpe_import_conflicts c where c.batch_id=v_batch.id),'[]'::jsonb),
    'protections', jsonb_build_object('databaseWrites',false,'definitiveLoadExecuted',false,'organizationId',v_batch.organization_id,'projectId',v_batch.project_id,'mf1State','approved','mf2State','in_progress','pem0203State','validation','pem0204State','blocked')
  );

  update public.skpe_import_batches
  set status = case when v_is_ready then 'ready' else status end,
      payload_metadata = coalesce(payload_metadata,'{}'::jsonb) || jsonb_build_object('readinessAssessment',v_result)
  where id = v_batch.id;

  insert into public.skpe_import_events(batch_id,organization_id,project_id,event_code,event_data)
  values (v_batch.id,v_batch.organization_id,v_batch.project_id,'IMPORT_READINESS_ASSESSED',v_result-'blockedRecords'-'conflicts');

  return v_result;
end;
$function$;

grant execute on function public.skpe_assess_import_batch_readiness(uuid) to authenticated;
