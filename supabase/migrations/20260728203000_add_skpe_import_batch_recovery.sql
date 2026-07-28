-- Bloco 1.10B-3.1 — listagem e retomada autenticada de lotes de importacao

create or replace function public.skpe_list_import_batches(
  p_organization_id uuid,
  p_project_id uuid,
  p_limit integer default 20
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $function$
declare
  v_limit integer := greatest(1, least(coalesce(p_limit, 20), 100));
  v_result jsonb;
begin
  if p_organization_id is null or p_project_id is null then
    raise exception 'Organizacao e projeto sao obrigatorios.';
  end if;

  if not public.can_manage_skpe_journey(p_organization_id) then
    raise exception 'Usuario sem permissao para consultar os lotes desta organizacao.';
  end if;

  if not exists (
    select 1
    from public.skpe_projects p
    where p.id = p_project_id
      and p.organization_id = p_organization_id
  ) then
    raise exception 'Projeto nao pertence a organizacao informada.';
  end if;

  select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb)
  into v_result
  from (
    select
      b.id,
      b.organization_id,
      b.project_id,
      b.schema_code,
      b.schema_version,
      b.source_file,
      b.source_file_fingerprint,
      b.organization_label,
      b.horizon,
      b.declared_record_count,
      b.staged_record_count,
      b.valid_record_count,
      b.quarantined_record_count,
      b.blocked_record_count,
      b.conflict_count,
      b.status,
      b.created_at,
      b.staged_at,
      b.confirmed_at,
      b.cancelled_at
    from public.skpe_import_batches b
    where b.organization_id = p_organization_id
      and b.project_id = p_project_id
    order by b.created_at desc
    limit v_limit
  ) x;

  return v_result;
end;
$function$;

revoke all on function public.skpe_list_import_batches(uuid, uuid, integer) from public;
grant execute on function public.skpe_list_import_batches(uuid, uuid, integer) to authenticated;

comment on function public.skpe_list_import_batches(uuid, uuid, integer)
is 'Lista lotes de importacao do projeto para retomada pela interface autenticada, respeitando a autorizacao da jornada.';
