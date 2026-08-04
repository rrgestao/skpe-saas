begin;

create or replace function public.set_platform_admin_user_avatar(
  target_user_id uuid,
  input_avatar_storage_path text,
  change_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  actor_id uuid := auth.uid();
  normalized_path text := nullif(trim(input_avatar_storage_path), '');
  previous_path text;
begin
  if actor_id is null then
    raise exception 'Usuário não autenticado.';
  end if;

  if not public.is_platform_super_admin() then
    raise exception 'Apenas SUPER-ADMIN pode alterar o avatar de outro usuário.';
  end if;

  if nullif(trim(coalesce(change_reason, '')), '') is null
     or char_length(trim(change_reason)) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.';
  end if;

  select p.avatar_url
  into previous_path
  from public.profiles as p
  where p.id = target_user_id;

  if not found then
    raise exception 'Usuário-alvo não encontrado.';
  end if;

  if normalized_path is not null
     and normalized_path !~ ('^' || target_user_id::text || '/[A-Za-z0-9._/-]+$') then
    raise exception 'O caminho do avatar não pertence ao usuário-alvo.';
  end if;

  update public.profiles
  set
    avatar_url = normalized_path,
    updated_at = timezone('utc', now())
  where id = target_user_id;

  insert into public.privileged_access_audit (
    actor_user_id,
    event_type,
    event_description,
    entity_schema,
    entity_table,
    entity_id,
    metadata
  )
  values (
    actor_id,
    'data_updated',
    case
      when normalized_path is null
        then 'Avatar removido administrativamente.'
      else 'Avatar atualizado administrativamente.'
    end,
    'public',
    'profiles',
    target_user_id::text,
    jsonb_build_object(
      'source', 'platform_admin_user_maintenance',
      'target_user_id', target_user_id,
      'reason', trim(change_reason),
      'previous_avatar_storage_path', previous_path,
      'avatar_storage_path', normalized_path,
      'operation',
        case
          when normalized_path is null then 'avatar_removed'
          else 'avatar_updated'
        end
    )
  );
end;
$function$;

revoke all on function public.set_platform_admin_user_avatar(uuid, text, text) from public;
grant execute on function public.set_platform_admin_user_avatar(uuid, text, text) to authenticated;

commit;