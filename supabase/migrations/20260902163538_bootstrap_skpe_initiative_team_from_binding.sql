-- SK-PE-CONT-01
-- POS-6J.IR-01
-- Bootstrap governado da equipe inicial da Iniciativa PE.
--
-- O usuario que cria o novo binding da Jornada recebe temporariamente
-- owner + sponsor + facilitator. A equipe real deve ser reconciliada
-- na Reuniao de Abertura, preservando historico e identidade canonica.
--
-- Esta migration materializa no repositorio o DDL ja validado no DEV.
-- No DEV atual, o historico sera reconciliado com migration repair,
-- sem reexecutar o DDL.

create or replace function public.bootstrap_skpe_initiative_team_from_binding()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_session_user_id uuid;
  v_effective_date date;
  v_organization_person_id uuid;
  v_relationship_count integer;
  v_initiative_source_module text;
  v_initiative_archived_at timestamptz;
begin
  if tg_op <> 'INSERT' then
    raise exception
      'bootstrap_skpe_initiative_team_from_binding somente pode ser executado em INSERT.'
      using errcode = '55000';
  end if;

  if new.created_by is null then
    raise exception
      'Nao e possivel criar a Jornada Estrategica sem identificar o usuario criador.'
      using errcode = '23502';
  end if;

  v_session_user_id := auth.uid();

  if v_session_user_id is not null
     and v_session_user_id is distinct from new.created_by then
    raise exception
      'O usuario criador do binding deve corresponder ao usuario autenticado.'
      using errcode = '42501';
  end if;

  select i.source_module_code, i.archived_at
    into v_initiative_source_module, v_initiative_archived_at
  from public.sparks_initiatives i
  where i.id = new.initiative_id
    and i.organization_id = new.organization_id;

  if not found then
    raise exception
      'Iniciativa vinculada nao encontrada no mesmo escopo organizacional.'
      using errcode = '23503';
  end if;

  if v_initiative_archived_at is not null then
    raise exception
      'Nao e possivel inicializar equipe para iniciativa arquivada.'
      using errcode = '23514';
  end if;

  if coalesce(v_initiative_source_module, '') <> 'SK-PE' then
    raise exception
      'O bootstrap automatico de equipe exige iniciativa com source_module_code = SK-PE.'
      using errcode = '23514';
  end if;

  select
    timezone(
      coalesce(nullif(trim(o.timezone_name), ''), 'UTC'),
      new.created_at
    )::date
  into v_effective_date
  from public.organizations o
  where o.id = new.organization_id;

  if v_effective_date is null then
    raise exception
      'Nao foi possivel determinar a data efetiva da organizacao.'
      using errcode = '22023';
  end if;

  select count(*)::integer, min(sop.id)
    into v_relationship_count, v_organization_person_id
  from public.sparks_people sp
  join public.sparks_organization_people sop
    on sop.person_id = sp.id
   and sop.organization_id = new.organization_id
   and sop.status = 'active'
   and (sop.start_date is null or sop.start_date <= v_effective_date)
   and (sop.end_date is null or sop.end_date >= v_effective_date)
  where sp.profile_user_id = new.created_by
    and sp.person_status = 'active'
    and sp.archived_at is null;

  if v_relationship_count = 0 then
    raise exception
      'O usuario criador nao possui vinculo canonico Pessoa->Organizacao ativo na data efetiva %.',
      v_effective_date
      using errcode = '23514';
  end if;

  if v_relationship_count > 1 then
    raise exception
      'O usuario criador possui % vinculos Pessoa->Organizacao ativos na data efetiva %. A Jornada exige exatamente um vinculo canonico.',
      v_relationship_count, v_effective_date
      using errcode = '23514';
  end if;

  insert into public.sparks_responsibility_assignments (
    organization_id,
    module_code,
    object_type,
    object_id,
    organization_person_id,
    responsibility_type,
    valid_from,
    status,
    assignment_reason,
    metadata,
    created_by,
    updated_by,
    assignment_source
  )
  select
    new.organization_id,
    'SK-PE',
    'initiative',
    new.initiative_id,
    v_organization_person_id,
    role_name,
    v_effective_date,
    'active',
    'Bootstrap governado da equipe inicial da Iniciativa PE a partir do usuario que abriu a Jornada Estrategica. Os papeis devem ser reconciliados na Reuniao de Abertura.',
    jsonb_build_object(
      'source', 'skpe_project_initiative_binding',
      'binding_id', new.id,
      'skpe_project_id', new.skpe_project_id,
      'bootstrap_team', true,
      'pending_opening_reconciliation', true,
      'bootstrap_profile_user_id', new.created_by,
      'bootstrap_effective_date', v_effective_date
    ),
    new.created_by,
    new.created_by,
    'integration'
  from (
    values
      ('owner'::text),
      ('sponsor'::text),
      ('facilitator'::text)
  ) as roles(role_name)
  on conflict (
    organization_id,
    module_code,
    object_type,
    object_id,
    organization_person_id,
    responsibility_type
  )
  where status = 'active'
  do nothing;

  update public.sparks_initiatives i
  set
    metadata = coalesce(i.metadata, '{}'::jsonb) || jsonb_build_object(
      'bootstrap_team', true,
      'pending_opening_reconciliation', true,
      'bootstrap_binding_id', new.id,
      'bootstrap_profile_user_id', new.created_by,
      'bootstrap_organization_person_id', v_organization_person_id,
      'bootstrap_effective_date', v_effective_date
    ),
    updated_at = timezone('utc', now()),
    updated_by = new.created_by
  where i.id = new.initiative_id
    and i.organization_id = new.organization_id;

  return new;
end;
$function$;

revoke all on function public.bootstrap_skpe_initiative_team_from_binding() from public;
revoke all on function public.bootstrap_skpe_initiative_team_from_binding() from anon;
revoke all on function public.bootstrap_skpe_initiative_team_from_binding() from authenticated;

drop trigger if exists trg_skpe_bootstrap_initiative_team_from_binding
  on public.skpe_project_initiative_bindings;

create trigger trg_skpe_bootstrap_initiative_team_from_binding
after insert on public.skpe_project_initiative_bindings
for each row
execute function public.bootstrap_skpe_initiative_team_from_binding();