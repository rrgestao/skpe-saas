select public.skpe_assess_import_batch_readiness(
  'c6c255e6-46d1-4072-9ebd-e0640345c98b'::uuid
);

select
  id,
  status,
  payload_metadata->'readinessAssessment' as readiness_assessment
from public.skpe_import_batches
where id = 'c6c255e6-46d1-4072-9ebd-e0640345c98b'::uuid;
