create or replace function public.delete_platform_measure_reference_catalog_draft(
  target_reference_catalog_id uuid,
  target_change_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  current_user_id uuid := auth.uid();
  current_row public.skpe_indicator_reference_catalog%rowtype;
  previous_row public.skpe_indicator_reference_catalog%rowtype;
  benchmark_count integer := 0;
  adopted_indicator_count integer := 0;
  transition_count integer := 0;
  restored_reference_id uuid := null;
begin
  perform public.require_platform_super_admin();

  if target_reference_catalog_id is null then
    raise exception 'Informe a referência do Catálogo GERAL a excluir.' using errcode = '22023';
  end if;

  if length(trim(coalesce(target_change_reason, ''))) = 0 then
    raise exception 'Informe o motivo da exclusão do rascunho.' using errcode = '22023';
  end if;

  select * into current_row
  from public.skpe_indicator_reference_catalog
  where id = target_reference_catalog_id
  for update;

  if not found then
    raise exception 'Referência do Catálogo GERAL não encontrada.' using errcode = '22023';
  end if;

  if current_row.status <> 'draft' then
    raise exception 'Somente referências em rascunho podem ser excluídas. Use arquivamento para referências legítimas do histórico.' using errcode = '22023';
  end if;

  select count(*) into transition_count
  from jsonb_array_elements(coalesce(current_row.metadata->'changeHistory', '[]'::jsonb)) as item
  where item->>'action' = 'status_transition';

  if transition_count > 0 then
    raise exception 'O rascunho já possui histórico de transições e deve ser preservado por arquivamento.' using errcode = '22023';
  end if;

  select count(*) into benchmark_count
  from public.skpe_indicator_reference_benchmarks
  where reference_indicator_id = current_row.id;

  if benchmark_count > 0 then
    raise exception 'A referência possui benchmark(s) vinculado(s) e não pode ser excluída.' using errcode = '23503';
  end if;

  select count(*) into adopted_indicator_count
  from public.skpe_indicators
  where reference_catalog_id = current_row.id;

  if adopted_indicator_count > 0 then
    raise exception 'A referência já foi adotada por indicador(es) e não pode ser excluída.' using errcode = '23503';
  end if;

  if current_row.is_current then
    select * into previous_row
    from public.skpe_indicator_reference_catalog
    where upper(trim(catalog_code)) = upper(trim(current_row.catalog_code))
      and id <> current_row.id
      and status <> 'archived'
    order by version_number desc
    limit 1
    for update;

    if found then
      restored_reference_id := previous_row.id;
      update public.skpe_indicator_reference_catalog
      set is_current = true,
          metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
            'restoredAfterDraftDeletion', true,
            'restoredAfterDraftDeletionAt', timezone('utc', now()),
            'restoredAfterDraftDeletionBy', current_user_id,
            'restoredAfterDraftDeletionReason', trim(target_change_reason)
          ),
          updated_at = timezone('utc', now()),
          updated_by = current_user_id
      where id = previous_row.id;
    end if;
  end if;

  delete from public.skpe_indicator_reference_catalog where id = current_row.id;

  return jsonb_build_object(
    'deletedReferenceId', current_row.id,
    'catalogCode', current_row.catalog_code,
    'versionNumber', current_row.version_number,
    'restoredReferenceId', restored_reference_id,
    'reason', trim(target_change_reason)
  );
end;
$function$;

revoke all on function public.delete_platform_measure_reference_catalog_draft(uuid, text) from public;
grant execute on function public.delete_platform_measure_reference_catalog_draft(uuid, text) to authenticated, service_role;

create or replace function public.delete_platform_measure_reference_benchmark_draft(
  target_benchmark_id uuid,
  target_change_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  current_row public.skpe_indicator_reference_benchmarks%rowtype;
  reference_row public.skpe_indicator_reference_catalog%rowtype;
begin
  perform public.require_platform_super_admin();

  if target_benchmark_id is null then
    raise exception 'Informe o benchmark a excluir.' using errcode = '22023';
  end if;

  if length(trim(coalesce(target_change_reason, ''))) = 0 then
    raise exception 'Informe o motivo da exclusão do benchmark em rascunho.' using errcode = '22023';
  end if;

  select * into current_row
  from public.skpe_indicator_reference_benchmarks
  where id = target_benchmark_id
  for update;

  if not found then
    raise exception 'Benchmark não encontrado.' using errcode = '22023';
  end if;

  if current_row.status <> 'draft' then
    raise exception 'Somente benchmarks em rascunho podem ser excluídos. Use inativação ou arquivamento para benchmarks legítimos do histórico.' using errcode = '22023';
  end if;

  if current_row.verified_at is not null or current_row.verified_by is not null then
    raise exception 'O benchmark já foi validado anteriormente e deve permanecer rastreável.' using errcode = '22023';
  end if;

  select * into reference_row
  from public.skpe_indicator_reference_catalog
  where id = current_row.reference_indicator_id;

  delete from public.skpe_indicator_reference_benchmarks where id = current_row.id;

  return jsonb_build_object(
    'deletedBenchmarkId', current_row.id,
    'referenceCatalogId', current_row.reference_indicator_id,
    'catalogCode', reference_row.catalog_code,
    'sourceName', current_row.source_name,
    'reason', trim(target_change_reason)
  );
end;
$function$;

revoke all on function public.delete_platform_measure_reference_benchmark_draft(uuid, text) from public;
grant execute on function public.delete_platform_measure_reference_benchmark_draft(uuid, text) to authenticated, service_role;
