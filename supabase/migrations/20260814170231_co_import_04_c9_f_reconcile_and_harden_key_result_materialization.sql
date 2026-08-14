-- CO-IMPORT-04-C9-F
-- Reconciliação pós-materialização e hardening de Key Results.
-- Forward-only: não rematerializa entidades e não altera requests/items/proveniência.

revoke all on function public.skpe_assert_governed_import_materialization(uuid)
  from public, anon, authenticated;
grant execute on function public.skpe_assert_governed_import_materialization(uuid)
  to service_role;

revoke all on function public.skpe_finalize_governed_import_materialization(uuid,text,uuid,text,uuid,jsonb)
  from public, anon, authenticated;
grant execute on function public.skpe_finalize_governed_import_materialization(uuid,text,uuid,text,uuid,jsonb)
  to service_role;

revoke all on function public.skpe_materialize_import_request_as_key_result(uuid,text,uuid,jsonb)
  from public, anon, authenticated;
grant execute on function public.skpe_materialize_import_request_as_key_result(uuid,text,uuid,jsonb)
  to service_role;

revoke all on function public.skpe_execute_governed_import_materialization_c8(uuid,text,uuid,jsonb)
  from public, anon, authenticated;
grant execute on function public.skpe_execute_governed_import_materialization_c8(uuid,text,uuid,jsonb)
  to service_role;

revoke all on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
  from public, anon, authenticated;
grant execute on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
  to service_role;

do $$
declare
  v_updated_count integer;
begin
  update public.skpe_incorporation_mapping_versions v
  set metadata =
        (coalesce(v.metadata, '{}'::jsonb)
          - 'materialization_pending'
          - 'provenance_pending')
        || jsonb_build_object(
             'roadmap_step', 'CO-IMPORT-04-C9-F',
             'materialization_status', 'completed',
             'provenance_status', 'completed',
             'security_hardening_status', 'service_role_only',
             'semantic_inference', false,
             'institutional_validation_separated', true
           )
  from public.skpe_incorporation_mapping_catalogs c
  where c.id = v.catalog_id
    and c.mapping_code = 'key_result_to_key_result'
    and v.version_number = c.current_version
    and v.version_status = 'active';

  get diagnostics v_updated_count = row_count;

  if v_updated_count <> 1 then
    raise exception using
      errcode = '55000',
      message = format(
        'C9-F esperava reconciliar exatamente 1 mapping ativo de Key Results; encontrados %s.',
        v_updated_count
      );
  end if;
end;
$$;
