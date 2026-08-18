create or replace function public.upsert_skpe_strategic_horizon_proposal(
  target_project_id uuid,
  target_proposal_id uuid,
  proposed_start_year integer,
  proposed_end_year integer,
  proposal_origin_type text,
  proposal_rationale text,
  proposal_source_reference text,
  change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_project public.skpe_projects%rowtype;
  v_proposal public.skpe_strategic_horizon_proposals%rowtype;
  v_id uuid;
  v_version integer;
  v_proposed_start_year integer := proposed_start_year;
  v_proposed_end_year integer := proposed_end_year;
begin
  perform public.skpe_assert_reason(change_reason);

  select *
    into v_project
  from public.skpe_projects
  where id = target_project_id
    and archived_at is null
  for update;

  if v_project.id is null then
    raise exception 'Projeto SK-PE não encontrado.'
      using errcode = '22023';
  end if;

  if not public.can_manage_skpe_governance(v_project.organization_id) then
    raise exception 'Acesso negado à gestão da proposta de Horizonte Estratégico.'
      using errcode = '42501';
  end if;

  if proposed_start_year is null
     or proposed_end_year is null
     or proposed_end_year < proposed_start_year then
    raise exception 'Informe um Horizonte Estratégico válido.'
      using errcode = '22023';
  end if;

  if proposal_origin_type not in (
    'consultancy_suggestion',
    'organization',
    'diagnostic',
    'historical_import',
    'system'
  ) then
    raise exception 'Origem da proposta de Horizonte Estratégico inválida.'
      using errcode = '22023';
  end if;

  if target_proposal_id is null then

    if exists (
      select 1
      from public.skpe_strategic_horizon_proposals
      where project_id = target_project_id
        and status in (
          'draft',
          'proposed',
          'under_review',
          'adjusted',
          'deferred'
        )
    ) then
      raise exception 'Já existe proposta de Horizonte Estratégico em aberto para este projeto.'
        using errcode = '55000';
    end if;

    select coalesce(max(version_number), 0) + 1
      into v_version
    from public.skpe_strategic_horizon_proposals
    where project_id = target_project_id;

    insert into public.skpe_strategic_horizon_proposals (
      organization_id,
      project_id,
      version_number,
      status,
      proposed_start_year,
      proposed_end_year,
      origin_type,
      rationale,
      source_reference,
      metadata,
      created_by,
      updated_by
    )
    values (
      v_project.organization_id,
      target_project_id,
      v_version,
      'draft',
      proposed_start_year,
      proposed_end_year,
      proposal_origin_type,
      nullif(trim(proposal_rationale), ''),
      nullif(trim(proposal_source_reference), ''),
      jsonb_build_object(
        'created_during_phase',
        v_project.current_phase_code
      ),
      auth.uid(),
      auth.uid()
    )
    returning id into v_id;

  else

    select *
      into v_proposal
    from public.skpe_strategic_horizon_proposals
    where id = target_proposal_id
    for update;

    if v_proposal.id is null
       or v_proposal.project_id <> target_project_id then
      raise exception 'Proposta de Horizonte Estratégico não encontrada neste projeto.'
        using errcode = '22023';
    end if;

    if v_proposal.status not in ('draft', 'adjusted') then
      raise exception 'Somente proposta em rascunho ou ajuste pode ser editada.'
        using errcode = '55000';
    end if;

    update public.skpe_strategic_horizon_proposals
    set
      proposed_start_year = v_proposed_start_year,
      proposed_end_year = v_proposed_end_year,
      origin_type = proposal_origin_type,
      rationale = nullif(trim(proposal_rationale), ''),
      source_reference = nullif(trim(proposal_source_reference), ''),
      updated_at = timezone('utc', now()),
      updated_by = auth.uid()
    where id = target_proposal_id
    returning id into v_id;

  end if;

  insert into public.skpe_journey_audit (
    organization_id,
    project_id,
    actor_user_id,
    action_code,
    reason,
    new_data
  )
  values (
    v_project.organization_id,
    target_project_id,
    auth.uid(),
    'strategic_horizon_proposal_upserted',
    change_reason,
    jsonb_build_object(
      'proposal_id', v_id,
      'start_year', proposed_start_year,
      'end_year', proposed_end_year,
      'origin_type', proposal_origin_type
    )
  );

  return v_id;
end;
$$;