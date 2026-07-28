-- Verifica se a funcao foi criada
select p.proname, pg_get_function_identity_arguments(p.oid) as arguments
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname = 'skpe_list_import_batches';

-- Verificacao administrativa do lote conhecido
select
  id, source_file, schema_version, status,
  staged_record_count, valid_record_count,
  blocked_record_count, conflict_count, created_at
from public.skpe_import_batches
where id = 'c6c255e6-46d1-4072-9ebd-e0640345c98b'::uuid;
