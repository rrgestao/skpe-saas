select table_name
from information_schema.tables
where table_schema='public'
  and table_name in (
    'skpe_import_batches','skpe_import_records','skpe_import_conflicts','skpe_import_events'
  )
order by table_name;

select routine_name
from information_schema.routines
where routine_schema='public'
  and routine_name in (
    'skpe_stage_canonical_import',
    'skpe_get_import_batch_summary',
    'skpe_cancel_import_batch'
  )
order by routine_name;
