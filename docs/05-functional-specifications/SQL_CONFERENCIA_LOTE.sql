select
  id,
  source_file,
  schema_version,
  staged_record_count,
  valid_record_count,
  quarantined_record_count,
  blocked_record_count,
  conflict_count,
  status,
  staged_at
from public.skpe_import_batches
order by created_at desc
limit 10;

select
  entity_code,
  simulation_status,
  count(*) as quantidade
from public.skpe_import_records
where batch_id = '<COLE_AQUI_O_ID_DO_LOTE>'::uuid
group by entity_code, simulation_status
order by entity_code, simulation_status;
