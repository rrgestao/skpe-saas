select id, external_key, simulation_status, reviewed, review_decision, review_notes, values_json
from public.skpe_import_records
where batch_id='c6c255e6-46d1-4072-9ebd-e0640345c98b'::uuid
  and external_key='version_control:v17';
