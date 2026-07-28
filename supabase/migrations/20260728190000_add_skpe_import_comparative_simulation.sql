-- ============================================================
-- SPARKs PE - Bloco 1.10B-3
-- Simulacao comparativa entre lotes canonicos.
-- Nao grava em tabelas estrategicas definitivas.
-- ============================================================

create or replace function public.skpe_simulate_import_batch(p_batch_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_batch public.skpe_import_batches%rowtype;
  v_baseline_batch_id uuid;
  v_new integer := 0;
  v_update integer := 0;
  v_unchanged integer := 0;
  v_blocked integer := 0;
  v_quarantined integer := 0;
  v_invalid integer := 0;
  v_pending integer := 0;
begin
  select * into v_batch
  from public.skpe_import_batches
  where id = p_batch_id;

  if v_batch.id is null then
    raise exception 'Lote nao encontrado.';
  end if;

  if not public.can_manage_skpe_journey(v_batch.organization_id) then
    raise exception 'Usuario sem permissao para simular este lote.';
  end if;

  if v_batch.status not in ('staged','reviewed') then
    raise exception 'O lote precisa estar em staging ou revisado. Status atual: %', v_batch.status;
  end if;

  select b.id into v_baseline_batch_id
  from public.skpe_import_batches b
  where b.organization_id = v_batch.organization_id
    and b.project_id = v_batch.project_id
    and b.id <> v_batch.id
    and b.created_at < v_batch.created_at
    and b.status in ('staged','reviewed','ready','applied','rolled_back')
  order by
    case b.status when 'applied' then 0 when 'ready' then 1 when 'reviewed' then 2 else 3 end,
    b.created_at desc
  limit 1;

  -- Preserva bloqueios, quarentenas e invalidos. Classifica somente pendentes.
  update public.skpe_import_records r
  set simulation_status = case
        when prior.id is null then 'new'
        when coalesce(prior.fingerprint,'') = coalesce(r.fingerprint,'') then 'unchanged'
        else 'update'
      end,
      proposed_action = case
        when prior.id is null then 'insert'
        when coalesce(prior.fingerprint,'') = coalesce(r.fingerprint,'') then 'ignore'
        else 'update'
      end,
      target_record_id = prior.id,
      validation_messages = case
        when prior.id is null then coalesce(r.validation_messages,'[]'::jsonb) || jsonb_build_array(jsonb_build_object(
          'code','NO_PRIOR_CANONICAL_RECORD','severity','info','message','Nenhum registro canonico anterior foi localizado para esta chave.'
        ))
        when coalesce(prior.fingerprint,'') = coalesce(r.fingerprint,'') then coalesce(r.validation_messages,'[]'::jsonb) || jsonb_build_array(jsonb_build_object(
          'code','SAME_FINGERPRINT','severity','info','message','Registro identico ao lote canonico de referencia.'
        ))
        else coalesce(r.validation_messages,'[]'::jsonb) || jsonb_build_array(jsonb_build_object(
          'code','FINGERPRINT_CHANGED','severity','medium','message','A chave ja existia, mas o conteudo foi alterado e exige revisao antes da carga definitiva.'
        ))
      end
  from lateral (
    select pr.id, pr.fingerprint
    from public.skpe_import_records pr
    join public.skpe_import_batches pb on pb.id = pr.batch_id
    where pr.organization_id = r.organization_id
      and pr.project_id = r.project_id
      and pr.external_key = r.external_key
      and pr.batch_id <> r.batch_id
      and pb.created_at < v_batch.created_at
      and pb.status in ('staged','reviewed','ready','applied','rolled_back')
      and pr.simulation_status not in ('blocked','invalid','quarantined')
    order by
      case pb.status when 'applied' then 0 when 'ready' then 1 when 'reviewed' then 2 else 3 end,
      pb.created_at desc,
      pr.created_at desc
    limit 1
  ) prior
  where r.batch_id = v_batch.id
    and r.simulation_status = 'pending_mapping';

  -- Registros sem correspondencia nao aparecem no UPDATE ... FROM; classifica como novos.
  update public.skpe_import_records r
  set simulation_status = 'new',
      proposed_action = 'insert',
      validation_messages = coalesce(r.validation_messages,'[]'::jsonb) || jsonb_build_array(jsonb_build_object(
        'code','NO_PRIOR_CANONICAL_RECORD','severity','info','message','Nenhum registro canonico anterior foi localizado para esta chave.'
      ))
  where r.batch_id = v_batch.id
    and r.simulation_status = 'pending_mapping';

  select
    count(*) filter (where simulation_status='new'),
    count(*) filter (where simulation_status='update'),
    count(*) filter (where simulation_status='unchanged'),
    count(*) filter (where simulation_status='blocked'),
    count(*) filter (where simulation_status='quarantined'),
    count(*) filter (where simulation_status='invalid'),
    count(*) filter (where simulation_status='pending_mapping')
  into v_new, v_update, v_unchanged, v_blocked, v_quarantined, v_invalid, v_pending
  from public.skpe_import_records
  where batch_id = v_batch.id;

  update public.skpe_import_batches
  set status = 'reviewed',
      payload_metadata = coalesce(payload_metadata,'{}'::jsonb) || jsonb_build_object(
        'comparativeSimulationAt', timezone('utc',now()),
        'baselineBatchId', v_baseline_batch_id,
        'simulationScope', 'canonical_batches',
        'new', v_new,
        'update', v_update,
        'unchanged', v_unchanged,
        'blocked', v_blocked,
        'quarantined', v_quarantined,
        'invalid', v_invalid
      )
  where id = v_batch.id;

  insert into public.skpe_import_events(batch_id,organization_id,project_id,event_code,event_data)
  values (
    v_batch.id, v_batch.organization_id, v_batch.project_id, 'IMPORT_COMPARATIVE_SIMULATED',
    jsonb_build_object(
      'baselineBatchId', v_baseline_batch_id,
      'scope', 'canonical_batches',
      'new', v_new,
      'update', v_update,
      'unchanged', v_unchanged,
      'blocked', v_blocked,
      'quarantined', v_quarantined,
      'invalid', v_invalid,
      'pending', v_pending
    )
  );

  return public.skpe_get_import_batch_summary(v_batch.id);
end;
$$;

grant execute on function public.skpe_simulate_import_batch(uuid) to authenticated;

comment on function public.skpe_simulate_import_batch(uuid) is
'Compara um lote com registros canonicos de lotes anteriores do mesmo projeto. Nao aplica dados nas tabelas estrategicas definitivas.';
