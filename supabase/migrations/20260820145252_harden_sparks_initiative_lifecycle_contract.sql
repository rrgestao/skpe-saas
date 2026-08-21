begin;

create or replace function public.transition_sparks_initiative_lifecycle(
  target_initiative_id uuid,
  target_status text,
  change_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_initiative public.sparks_initiatives%rowtype;
  v_target_status text;
  v_now timestamptz := timezone('utc', now());
  v_before jsonb;
  v_after jsonb;
begin
  select *
    into v_initiative
  from public.sparks_initiatives
  where id = target_initiative_id
    and archived_at is null
  for update;

  if v_initiative.id is null then
    raise exception 'Iniciativa não encontrada ou já arquivada.'
      using errcode = '22023';
  end if;

  if auth.uid() is null then
    raise exception 'Operação exige usuário autenticado.'
      using errcode = '42501';
  end if;

  if not public.can_manage_sparks_initiatives(
    v_initiative.organization_id,
    v_initiative.source_module_code
  ) then
    raise exception 'Acesso negado: o usuário não pode gerir esta iniciativa.'
      using errcode = '42501';
  end if;

  if change_reason is null or length(trim(change_reason)) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.'
      using errcode = '22023';
  end if;

  v_target_status := lower(trim(target_status));

  if v_target_status is null or v_target_status not in (
    'proposed','under_analysis','approved','planned','in_progress',
    'on_hold','blocked','completed','cancelled','archived'
  ) then
    raise exception 'Status de lifecycle inválido: %.', target_status
      using errcode = '22023';
  end if;

  if v_target_status = v_initiative.status then
    raise exception 'A iniciativa já está no status "%".', v_target_status
      using errcode = '22023';
  end if;

  if not (
    (v_initiative.status = 'proposed' and v_target_status in ('under_analysis','cancelled'))
    or (v_initiative.status = 'under_analysis' and v_target_status in ('proposed','approved','cancelled'))
    or (v_initiative.status = 'approved' and v_target_status in ('planned','cancelled'))
    or (v_initiative.status = 'planned' and v_target_status in ('in_progress','cancelled'))
    or (v_initiative.status = 'in_progress' and v_target_status in ('on_hold','blocked','completed','cancelled'))
    or (v_initiative.status = 'on_hold' and v_target_status in ('in_progress','cancelled'))
    or (v_initiative.status = 'blocked' and v_target_status in ('in_progress','on_hold','cancelled'))
    or (v_initiative.status = 'completed' and v_target_status = 'archived')
    or (v_initiative.status = 'cancelled' and v_target_status = 'archived')
  ) then
    raise exception 'Transição de lifecycle não permitida: % -> %.',
      v_initiative.status, v_target_status
      using errcode = '22023';
  end if;

  v_before := jsonb_build_object(
    'status', v_initiative.status,
    'progress', v_initiative.progress,
    'health_status', v_initiative.health_status,
    'completed_at', v_initiative.completed_at,
    'archived_at', v_initiative.archived_at
  );

  update public.sparks_initiatives
  set
    status = v_target_status,
    progress = case
      when v_target_status = 'completed' then 100
      else progress
    end,
    health_status = case
      when v_target_status = 'completed' then 'completed'
      else health_status
    end,
    completed_at = case
      when v_target_status = 'completed' then v_now
      else completed_at
    end,
    archived_at = case
      when v_target_status = 'archived' then v_now
      else archived_at
    end,
    archived_by = case
      when v_target_status = 'archived' then auth.uid()
      else archived_by
    end,
    last_update_at = v_now,
    updated_at = v_now,
    updated_by = auth.uid()
  where id = v_initiative.id;

  select jsonb_build_object(
    'status', status,
    'progress', progress,
    'health_status', health_status,
    'completed_at', completed_at,
    'archived_at', archived_at
  )
    into v_after
  from public.sparks_initiatives
  where id = v_initiative.id;

  insert into public.sparks_initiative_audit (
    organization_id,
    initiative_id,
    actor_user_id,
    source_module_code,
    action_code,
    change_reason,
    previous_data,
    new_data
  )
  values (
    v_initiative.organization_id,
    v_initiative.id,
    auth.uid(),
    v_initiative.source_module_code,
    'initiative_lifecycle_transitioned',
    trim(change_reason),
    v_before,
    v_after
  );

  return v_after;
end;
$$;

revoke all
on function public.transition_sparks_initiative_lifecycle(uuid, text, text)
from public, anon;

grant execute
on function public.transition_sparks_initiative_lifecycle(uuid, text, text)
to authenticated, service_role;

comment on function public.transition_sparks_initiative_lifecycle(uuid, text, text) is
  'Executa transição governada do lifecycle organizacional transversal de uma iniciativa SPARKs conforme contrato canônico do Gate 17-B.5F.3C.6B, sem sincronização automática com status metodológicos de módulos especializados.';

commit;
