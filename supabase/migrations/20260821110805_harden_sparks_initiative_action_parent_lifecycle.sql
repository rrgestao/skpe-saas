begin;

-- ============================================================
-- SPARKs PaaS
-- Gate 17-B.5F.3C.6D — Parent Lifecycle Hardening
--
-- Garante precedencia entre lifecycle da iniciativa e lifecycle
-- operacional das suas acoes.
--
-- Nao implementa roll-up.
-- Nao altera progresso da iniciativa pai.
-- ============================================================

create or replace function public.sparks_validate_initiative_action_parent_lifecycle()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_initiative_status text;
  v_initiative_archived_at timestamptz;
begin
  select
    initiative.status,
    initiative.archived_at
  into
    v_initiative_status,
    v_initiative_archived_at
  from public.sparks_initiatives initiative
  where initiative.id = new.initiative_id
    and initiative.organization_id = new.organization_id;

  if v_initiative_status is null then
    raise exception
      'Iniciativa pai nao encontrada para a acao.'
      using errcode = '23503';
  end if;

  -- ----------------------------------------------------------
  -- NASCIMENTO DA ACAO
  -- ----------------------------------------------------------

  if tg_op = 'INSERT' then
    if v_initiative_archived_at is not null
       or v_initiative_status not in (
         'approved',
         'planned',
         'in_progress',
         'on_hold',
         'blocked'
       ) then
      raise exception
        'Acoes somente podem ser criadas para iniciativas aprovadas ou em planejamento/execucao. Status atual: %.',
        v_initiative_status
        using errcode = '55000';
    end if;

    return new;
  end if;

  -- ----------------------------------------------------------
  -- ARQUIVAMENTO HISTORICO
  --
  -- Acao completed/cancelled pode ser arquivada mesmo quando a
  -- iniciativa pai ja estiver completed/cancelled/archived.
  -- ----------------------------------------------------------

  if new.status = 'archived'
     and old.status in ('completed', 'cancelled') then
    return new;
  end if;

  -- ----------------------------------------------------------
  -- INICIATIVA ENCERRADA
  -- ----------------------------------------------------------

  if v_initiative_archived_at is not null
     or v_initiative_status in (
       'completed',
       'cancelled',
       'archived'
     ) then
    raise exception
      'A iniciativa pai esta encerrada (%); somente o arquivamento historico de acoes encerradas e permitido.',
      v_initiative_status
      using errcode = '55000';
  end if;

  -- ----------------------------------------------------------
  -- EXECUCAO REAL DA ACAO
  --
  -- in_progress / on_hold / completed ou progresso positivo
  -- somente existem quando a iniciativa pai esta em execucao
  -- organizacional.
  -- ----------------------------------------------------------

  if (
       new.status in ('in_progress', 'on_hold', 'completed')
       or new.progress > 0
     )
     and v_initiative_status not in (
       'in_progress',
       'on_hold',
       'blocked'
     ) then
    raise exception
      'A acao nao pode entrar em execucao enquanto a iniciativa pai estiver no status %.',
      v_initiative_status
      using errcode = '55000';
  end if;

  return new;
end;
$$;

create trigger sparks_initiative_actions_validate_parent_lifecycle
before insert or update of status, progress
on public.sparks_initiative_actions
for each row
execute function public.sparks_validate_initiative_action_parent_lifecycle();

revoke all
on function public.sparks_validate_initiative_action_parent_lifecycle()
from public, anon, authenticated;

grant execute
on function public.sparks_validate_initiative_action_parent_lifecycle()
to service_role;

comment on function public.sparks_validate_initiative_action_parent_lifecycle() is
  'Preserva a precedencia do lifecycle organizacional da iniciativa sobre o lifecycle operacional das acoes, sem implementar roll-up.';

commit;