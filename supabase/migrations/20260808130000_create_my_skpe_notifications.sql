begin;

-- ============================================================
-- FE-09.A.13 — MEU ESPAÇO DE TRABALHO — NOTIFICAÇÕES
-- Central básica derivada de pendências reais do SK-PE.
-- Persiste somente o estado pessoal de leitura.
-- ============================================================

create table if not exists public.skpe_user_notification_states (
  id uuid primary key default gen_random_uuid(),

  user_id uuid not null
    references public.profiles(id)
    on delete cascade,

  organization_id uuid not null
    references public.organizations(id)
    on delete cascade,

  notification_key text not null,

  read_at timestamptz,

  created_at timestamptz not null
    default timezone('utc', now()),

  updated_at timestamptz not null
    default timezone('utc', now()),

  constraint skpe_user_notification_states_key_not_blank
    check (length(trim(notification_key)) > 0),

  constraint skpe_user_notification_states_key_length
    check (length(notification_key) <= 220),

  constraint skpe_user_notification_states_unique
    unique (
      user_id,
      organization_id,
      notification_key
    )
);

comment on table public.skpe_user_notification_states is
  'FE-09.A.13: estado pessoal de leitura das notificações derivadas de itens reais do SK-PE.';

comment on column public.skpe_user_notification_states.notification_key is
  'Chave estável da notificação, derivada do pending_id da fonte operacional.';

comment on column public.skpe_user_notification_states.read_at is
  'Data e hora em que o usuário marcou a notificação como lida. Nulo significa não lida.';

create index if not exists idx_skpe_user_notification_states_user_org
  on public.skpe_user_notification_states(
    user_id,
    organization_id
  );

create index if not exists idx_skpe_user_notification_states_unread
  on public.skpe_user_notification_states(
    user_id,
    organization_id,
    read_at
  );

alter table public.skpe_user_notification_states
  enable row level security;

revoke all on table public.skpe_user_notification_states
from public, anon, authenticated;

grant select on table public.skpe_user_notification_states
to authenticated;

grant all on table public.skpe_user_notification_states
to service_role;

drop policy if exists
  skpe_user_notification_states_select_own
on public.skpe_user_notification_states;

create policy skpe_user_notification_states_select_own
on public.skpe_user_notification_states
for select
to authenticated
using (
  user_id = (select auth.uid())
  and public.is_active_member(organization_id)
  and public.has_module_access(
    organization_id,
    'SK-PE'
  )
);

-- ============================================================
-- CONSULTA PESSOAL DE NOTIFICAÇÕES
-- ============================================================

create or replace function public.get_my_skpe_notifications(
  target_organization_id uuid,
  target_project_id uuid default null,
  target_formulation_id uuid default null
)
returns table (
  notification_key text,
  source_type text,
  source_id uuid,
  organization_id uuid,
  project_id uuid,
  formulation_id uuid,
  source_code text,
  title text,
  description text,
  priority text,
  generated_at timestamptz,
  due_date date,
  overdue boolean,
  due_soon boolean,
  blocked boolean,
  normalized_status text,
  action_recommended text,
  route_section text,
  read_at timestamptz,
  is_read boolean,
  priority_order integer
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'Usuário não autenticado.'
      using errcode = '42501';
  end if;

  if target_organization_id is null then
    raise exception 'Informe a organização.'
      using errcode = '22023';
  end if;

  if not (
    public.is_active_member(target_organization_id)
    and public.has_module_access(
      target_organization_id,
      'SK-PE'
    )
  ) then
    raise exception
      'Acesso negado: o usuário não pode consultar notificações do SK-PE nesta organização.'
      using errcode = '42501';
  end if;

  return query
  select
    pending.pending_id as notification_key,
    pending.source_type,
    pending.source_id,
    pending.organization_id,
    pending.project_id,
    pending.formulation_id,
    pending.source_code,
    pending.title,
    pending.description,
    pending.priority,

    pending.updated_at as generated_at,

    pending.due_date,
    pending.overdue,
    pending.due_soon,
    pending.blocked,
    pending.normalized_status,

    case
      when pending.blocked then
        'Verifique o bloqueio e defina a ação necessária para liberar o item.'

      when pending.normalized_status = 'overdue' then
        'Regularize o item em atraso ou atualize seu prazo e situação.'

      when pending.normalized_status = 'awaiting_validation' then
        'Revise o item e conclua a validação pendente.'

      when pending.normalized_status = 'due_soon' then
        'Acompanhe o item e conclua as ações necessárias antes do vencimento.'

      when pending.normalized_status = 'in_progress' then
        'Acompanhe a execução e atualize o andamento quando necessário.'

      else
        'Revise o item e defina a próxima ação necessária.'
    end as action_recommended,

    pending.route_section,

    state.read_at,

    state.read_at is not null as is_read,

    pending.priority_order

  from public.get_my_skpe_pending_items(
    target_organization_id,
    target_project_id,
    target_formulation_id
  ) as pending

  left join public.skpe_user_notification_states state
    on state.user_id = current_user_id
   and state.organization_id = pending.organization_id
   and state.notification_key = pending.pending_id

  order by
    case
      when state.read_at is null then 0
      else 1
    end,
    pending.priority_order,
    pending.due_date nulls last,
    pending.updated_at desc,
    pending.title;
end;
$$;

comment on function public.get_my_skpe_notifications(
  uuid,
  uuid,
  uuid
) is
  'FE-09.A.13: consolida notificações pessoais do SK-PE a partir das pendências reais, acrescentando estado lida/não lida e ação recomendada.';

revoke all on function public.get_my_skpe_notifications(
  uuid,
  uuid,
  uuid
)
from public, anon;

grant execute on function public.get_my_skpe_notifications(
  uuid,
  uuid,
  uuid
)
to authenticated, service_role;

-- ============================================================
-- MARCAR NOTIFICAÇÃO COMO LIDA / NÃO LIDA
-- ============================================================

create or replace function public.set_my_skpe_notification_read_state(
  target_organization_id uuid,
  target_notification_key text,
  target_is_read boolean
)
returns table (
  notification_key text,
  read_at timestamptz,
  is_read boolean
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  normalized_notification_key text;
  saved_read_at timestamptz;
  notification_exists boolean;
begin
  if current_user_id is null then
    raise exception 'Usuário não autenticado.'
      using errcode = '42501';
  end if;

  if target_organization_id is null then
    raise exception 'Informe a organização.'
      using errcode = '22023';
  end if;

  normalized_notification_key :=
    trim(coalesce(target_notification_key, ''));

  if normalized_notification_key = '' then
    raise exception 'Informe a notificação.'
      using errcode = '22023';
  end if;

  if length(normalized_notification_key) > 220 then
    raise exception 'A chave da notificação é inválida.'
      using errcode = '22023';
  end if;

  if target_is_read is null then
    raise exception 'Informe o estado de leitura.'
      using errcode = '22023';
  end if;

  if not (
    public.is_active_member(target_organization_id)
    and public.has_module_access(
      target_organization_id,
      'SK-PE'
    )
  ) then
    raise exception
      'Acesso negado: o usuário não pode alterar notificações do SK-PE nesta organização.'
      using errcode = '42501';
  end if;

  select exists (
    select 1
    from public.get_my_skpe_pending_items(
      target_organization_id,
      null,
      null
    ) as pending
    where pending.pending_id =
      normalized_notification_key
      and pending.organization_id =
        target_organization_id
  )
  into notification_exists;

  if not notification_exists then
    raise exception
      'A notificação informada não está disponível para o usuário.'
      using errcode = '22023';
  end if;

  if target_is_read then

    insert into public.skpe_user_notification_states (
      user_id,
      organization_id,
      notification_key,
      read_at
    )
    values (
      current_user_id,
      target_organization_id,
      normalized_notification_key,
      timezone('utc', now())
    )
    on conflict (
      user_id,
      organization_id,
      notification_key
    )
    do update set
      read_at = excluded.read_at,
      updated_at = timezone('utc', now())
    returning
      skpe_user_notification_states.read_at
    into saved_read_at;

  else

    delete from public.skpe_user_notification_states state
    where state.user_id = current_user_id
      and state.organization_id =
        target_organization_id
      and state.notification_key =
        normalized_notification_key;

    saved_read_at := null;

  end if;

  return query
  select
    normalized_notification_key,
    saved_read_at,
    target_is_read;
end;
$$;

comment on function public.set_my_skpe_notification_read_state(
  uuid,
  text,
  boolean
) is
  'FE-09.A.13: marca uma notificação pessoal derivada do SK-PE como lida ou não lida.';

revoke all on function public.set_my_skpe_notification_read_state(
  uuid,
  text,
  boolean
)
from public, anon;

grant execute on function public.set_my_skpe_notification_read_state(
  uuid,
  text,
  boolean
)
to authenticated, service_role;

commit;
