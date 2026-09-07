create or replace function public.can_organization_admin_manage_user_avatar(target_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select
    auth.uid() is not null
    and exists (
      select 1
      from public.organization_memberships actor_membership
      join public.organization_memberships target_membership
        on target_membership.organization_id = actor_membership.organization_id
      where actor_membership.user_id = auth.uid()
        and actor_membership.status = 'active'
        and actor_membership.is_organization_admin = true
        and actor_membership.valid_from <= timezone('utc', now())
        and (actor_membership.valid_until is null or actor_membership.valid_until >= timezone('utc', now()))
        and target_membership.user_id = target_user_id
        and target_membership.status = 'active'
        and target_membership.valid_from <= timezone('utc', now())
        and (target_membership.valid_until is null or target_membership.valid_until >= timezone('utc', now()))
    );
$function$;

create or replace function public.can_manage_user_avatar(target_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select auth.uid() is not null
    and (
      auth.uid() = target_user_id
      or public.is_platform_super_admin()
      or public.can_organization_admin_manage_user_avatar(target_user_id)
    );
$function$;

create or replace function public.get_managed_user_avatar(
  target_user_id uuid,
  context_organization_id uuid default null
)
returns table(user_id uuid, avatar_storage_path text)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if auth.uid() is null then
    raise exception 'Usuário não autenticado.';
  end if;

  if auth.uid() <> target_user_id and not public.is_platform_super_admin() then
    if context_organization_id is null then
      raise exception 'Informe a organização de contexto para a manutenção administrativa do avatar.';
    end if;

    if not public.is_organization_admin(context_organization_id) then
      raise exception 'Apenas Administrador da Organização pode alterar o avatar de usuários desta organização.';
    end if;

    if not exists (
      select 1
      from public.organization_memberships membership
      where membership.organization_id = context_organization_id
        and membership.user_id = target_user_id
        and membership.status = 'active'
        and membership.valid_from <= timezone('utc', now())
        and (membership.valid_until is null or membership.valid_until >= timezone('utc', now()))
    ) then
      raise exception 'O usuário-alvo não possui vínculo ativo com a organização informada.';
    end if;
  end if;

  return query
  select p.id, p.avatar_url
  from public.profiles p
  where p.id = target_user_id;
end;
$function$;

create or replace function public.set_managed_user_avatar(
  target_user_id uuid,
  input_avatar_storage_path text,
  change_reason text,
  context_organization_id uuid default null
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
  actor_scope text;
begin
  if actor_id is null then
    raise exception 'Usuário não autenticado.';
  end if;

  if actor_id = target_user_id then
    actor_scope := 'self';
  elsif public.is_platform_super_admin() then
    actor_scope := 'platform_super_admin';
  else
    if context_organization_id is null then
      raise exception 'Informe a organização de contexto para a manutenção administrativa do avatar.';
    end if;

    if not public.is_organization_admin(context_organization_id) then
      raise exception 'Apenas Administrador da Organização pode alterar o avatar de usuários desta organização.';
    end if;

    if not exists (
      select 1
      from public.organization_memberships membership
      where membership.organization_id = context_organization_id
        and membership.user_id = target_user_id
        and membership.status = 'active'
        and membership.valid_from <= timezone('utc', now())
        and (membership.valid_until is null or membership.valid_until >= timezone('utc', now()))
    ) then
      raise exception 'O usuário-alvo não possui vínculo ativo com a organização informada.';
    end if;

    actor_scope := 'organization_admin';
  end if;

  if actor_id <> target_user_id then
    if nullif(trim(coalesce(change_reason, '')), '') is null
       or char_length(trim(change_reason)) < 10 then
      raise exception 'Informe uma justificativa com pelo menos 10 caracteres.';
    end if;
  end if;

  if normalized_path is not null
     and normalized_path !~ ('^' || target_user_id::text || '/[A-Za-z0-9._/-]+$') then
    raise exception 'O caminho do avatar não pertence ao usuário-alvo.';
  end if;

  select p.avatar_url into previous_path
  from public.profiles p
  where p.id = target_user_id;

  if not found then
    raise exception 'Usuário-alvo não encontrado.';
  end if;

  update public.profiles
  set avatar_url = normalized_path,
      updated_at = timezone('utc', now())
  where id = target_user_id;

  insert into public.privileged_access_audit (
    actor_user_id,event_type,event_description,entity_schema,entity_table,entity_id,metadata
  )
  values (
    actor_id,
    'data_updated',
    case when normalized_path is null then 'Avatar removido.' else 'Avatar atualizado.' end,
    'public',
    'profiles',
    target_user_id::text,
    jsonb_build_object(
      'source',
        case
          when actor_scope = 'self' then 'self_profile_avatar'
          when actor_scope = 'organization_admin' then 'organization_admin_user_maintenance'
          else 'platform_admin_user_maintenance'
        end,
      'actor_scope', actor_scope,
      'context_organization_id', context_organization_id,
      'target_user_id', target_user_id,
      'reason', nullif(trim(coalesce(change_reason, '')), ''),
      'previous_avatar_storage_path', previous_path,
      'avatar_storage_path', normalized_path,
      'operation', case when normalized_path is null then 'avatar_removed' else 'avatar_updated' end
    )
  );
end;
$function$;

grant execute on function public.can_organization_admin_manage_user_avatar(uuid) to authenticated;
grant execute on function public.can_manage_user_avatar(uuid) to authenticated;
grant execute on function public.get_managed_user_avatar(uuid, uuid) to authenticated;
grant execute on function public.set_managed_user_avatar(uuid, text, text, uuid) to authenticated;

drop policy if exists user_avatars_select_organization_admin on storage.objects;
create policy user_avatars_select_organization_admin on storage.objects
for select to authenticated
using (
  bucket_id = 'user-avatars'
  and public.can_organization_admin_manage_user_avatar(nullif((storage.foldername(name))[1], '')::uuid)
);

drop policy if exists user_avatars_insert_organization_admin on storage.objects;
create policy user_avatars_insert_organization_admin on storage.objects
for insert to authenticated
with check (
  bucket_id = 'user-avatars'
  and public.can_organization_admin_manage_user_avatar(nullif((storage.foldername(name))[1], '')::uuid)
);

drop policy if exists user_avatars_update_organization_admin on storage.objects;
create policy user_avatars_update_organization_admin on storage.objects
for update to authenticated
using (
  bucket_id = 'user-avatars'
  and public.can_organization_admin_manage_user_avatar(nullif((storage.foldername(name))[1], '')::uuid)
)
with check (
  bucket_id = 'user-avatars'
  and public.can_organization_admin_manage_user_avatar(nullif((storage.foldername(name))[1], '')::uuid)
);

drop policy if exists user_avatars_delete_organization_admin on storage.objects;
create policy user_avatars_delete_organization_admin on storage.objects
for delete to authenticated
using (
  bucket_id = 'user-avatars'
  and public.can_organization_admin_manage_user_avatar(nullif((storage.foldername(name))[1], '')::uuid)
);
