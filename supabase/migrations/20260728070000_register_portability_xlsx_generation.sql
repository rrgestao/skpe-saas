begin;

create or replace function public.register_portability_generated_file(
  target_package_id uuid,
  target_format text,
  target_file_name text,
  target_metadata jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_package public.sparks_portability_packages%rowtype;
  v_now timestamptz := clock_timestamp();
begin
  select * into v_package
  from public.sparks_portability_packages
  where id = target_package_id;

  if not found then
    raise exception 'Pacote de portabilidade não encontrado.';
  end if;

  if v_package.direction <> 'export' then
    raise exception 'Somente pacotes de exportação podem registrar arquivos gerados.';
  end if;

  if not (
    public.is_platform_super_admin()
    or public.can_view_skpe_governance(v_package.organization_id)
  ) then
    raise exception 'Acesso negado para registrar o arquivo gerado.' using errcode = '42501';
  end if;

  if lower(coalesce(target_format, '')) not in ('xlsx', 'json', 'html', 'zip') then
    raise exception 'Formato de arquivo não suportado: %', coalesce(target_format, '(nulo)');
  end if;

  if nullif(trim(target_file_name), '') is null then
    raise exception 'O nome do arquivo é obrigatório.';
  end if;

  update public.sparks_portability_packages
  set status = 'completed',
      file_name = trim(target_file_name),
      completed_at = coalesce(completed_at, v_now),
      error_message = null,
      metadata = coalesce(metadata, '{}'::jsonb)
        || jsonb_build_object(
          'last_generated_format', lower(target_format),
          'last_generated_file_name', trim(target_file_name),
          'last_generation_at', v_now
        )
        || coalesce(target_metadata, '{}'::jsonb),
      updated_at = v_now,
      updated_by = auth.uid()
  where id = target_package_id;

  insert into public.sparks_portability_audit (
    package_id,
    organization_id,
    actor_user_id,
    action_code,
    action_description,
    new_data,
    metadata
  ) values (
    v_package.id,
    v_package.organization_id,
    auth.uid(),
    upper(target_format) || '_EXPORT_GENERATED',
    'Arquivo de portabilidade gerado para download.',
    jsonb_build_object(
      'format', lower(target_format),
      'file_name', trim(target_file_name)
    ),
    coalesce(target_metadata, '{}'::jsonb)
  );
end;
$$;

grant execute on function public.register_portability_generated_file(uuid, text, text, jsonb) to authenticated;

comment on function public.register_portability_generated_file(uuid, text, text, jsonb)
is 'Registra, com auditoria, a geração local controlada de arquivos de portabilidade.';

commit;
