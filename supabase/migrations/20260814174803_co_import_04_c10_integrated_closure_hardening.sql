do $$
declare
  v_function_count integer;
  v_decision_rows integer;
  v_objective_rows integer;
begin
  select count(*)
    into v_function_count
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'skpe_register_strategic_objective_import_provenance'
    and pg_get_function_identity_arguments(p.oid) =
      'p_strategic_objective_id uuid, p_incorporation_request_id uuid, p_incorporated_by uuid, p_metadata jsonb';

  if v_function_count <> 1 then
    raise exception
      'CO-IMPORT-04-C10 expected exactly one strategic objective provenance function; found %',
      v_function_count;
  end if;

  revoke execute on function public.skpe_register_strategic_objective_import_provenance(
    uuid,
    uuid,
    uuid,
    jsonb
  ) from public, anon, authenticated;

  grant execute on function public.skpe_register_strategic_objective_import_provenance(
    uuid,
    uuid,
    uuid,
    jsonb
  ) to service_role;

  update public.skpe_incorporation_mapping_versions v
  set metadata =
    (
      coalesce(v.metadata, '{}'::jsonb)
      - 'status_reason'
    )
    || jsonb_build_object(
      'roadmap_step', 'CO-IMPORT-04-C10',
      'contract_status', 'completed',
      'activation_status', 'completed',
      'materialization_status', 'completed',
      'provenance_status', 'completed',
      'security_hardening_status', 'service_role_only',
      'closure_reconciled_at', '2026-08-14',
      'semantic_inference', false
    )
  from public.skpe_incorporation_mapping_catalogs c
  where c.id = v.catalog_id
    and c.mapping_code = 'decision_to_gate_decision'
    and c.status = 'active'
    and v.version_status = 'active';

  get diagnostics v_decision_rows = row_count;

  if v_decision_rows <> 1 then
    raise exception
      'CO-IMPORT-04-C10 expected exactly one active decision mapping version; updated %',
      v_decision_rows;
  end if;

  update public.skpe_incorporation_mapping_versions v
  set metadata =
    (
      coalesce(v.metadata, '{}'::jsonb)
      - 'contract_status'
      - 'object_validation_state'
      - 'activation_blocked_until'
    )
    || jsonb_build_object(
      'roadmap_step', 'CO-IMPORT-04-C10',
      'contract_status', 'completed',
      'activation_status', 'completed',
      'materialization_status', 'completed',
      'provenance_status', 'completed',
      'security_hardening_status', 'service_role_only',
      'closure_reconciled_at', '2026-08-14',
      'semantic_inference', false
    )
  from public.skpe_incorporation_mapping_catalogs c
  where c.id = v.catalog_id
    and c.mapping_code = 'strategic_objective_to_strategic_objective'
    and c.status = 'active'
    and v.version_status = 'active';

  get diagnostics v_objective_rows = row_count;

  if v_objective_rows <> 1 then
    raise exception
      'CO-IMPORT-04-C10 expected exactly one active strategic objective mapping version; updated %',
      v_objective_rows;
  end if;
end;
$$;
