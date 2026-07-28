-- 1. Confirmar a funcao
select routine_schema, routine_name
from information_schema.routines
where routine_schema='public'
  and routine_name='skpe_simulate_import_batch';

-- 2. Conferir os lotes mais recentes
select id, source_file, schema_version, status,
       staged_record_count, valid_record_count,
       quarantined_record_count, blocked_record_count, conflict_count,
       payload_metadata
from public.skpe_import_batches
order by created_at desc
limit 5;

-- 3. Substitua o UUID abaixo pelo lote exibido na interface
-- select public.skpe_get_import_batch_summary('UUID_DO_LOTE'::uuid);
