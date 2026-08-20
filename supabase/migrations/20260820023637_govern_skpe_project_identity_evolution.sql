-- ============================================================
-- Plataforma SPARKs / SK-PE-CONT-01
-- 17-B.5F.3C.5 - Governed Identity Evolution
--
-- Decisoes canonicas:
-- - sparks_initiatives e a autoridade da identidade transversal.
-- - skpe_projects conserva a projecao metodologica compativel.
-- - Alteracoes identitarias devem ocorrer atomicamente nos dois dominios.
-- - Status, progresso, categoria, classe e lifecycle nao sao alterados aqui.
-- - Todo ajuste exige justificativa e auditoria.
-- ============================================================

begin;

create or replace function public.update_skpe_project_identity(
  target_project_id uuid,
  target_code text,
  target_name text,
  target_description text,
  change_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_project public.skpe_projects%rowtype;
  v_initiative public.sparks_initiatives%rowtype;
  v_binding public.skpe_project_initiative_bindings%rowtype;

  v_binding_count integer;

  v_code text;
  v_name text;
  v_description text;

  v_before jsonb;
  v_after jsonb;
begin
  -- ----------------------------------------------------------
  -- 1. Projeto especializado existente.
  -- ----------------------------------------------------------
  select *
    into v_project
  from public.skpe_projects
  where id = target_project_id
    and archived_at is null
  for update;

  if v_project.id is null then
    raise exception
      'Projeto SK-PE não encontrado.'
      using errcode = '22023';
  end if;

  -- ----------------------------------------------------------
  -- 2. Autorização.
  -- ----------------------------------------------------------
  if not public.can_manage_skpe_journey(v_project.organization_id) then
    raise exception
      'Acesso negado: o usuário não pode alterar a identidade deste projeto.'
      using errcode = '42501';
  end if;

  -- ----------------------------------------------------------
  -- 3. Justificativa obrigatória.
  -- ----------------------------------------------------------
  if change_reason is null
     or length(trim(change_reason)) < 10 then
    raise exception
      'Informe uma justificativa com pelo menos 10 caracteres.'
      using errcode = '22023';
  end if;

  -- ----------------------------------------------------------
  -- 4. Binding 1:1 obrigatório.
  -- ----------------------------------------------------------
  select count(*)
    into v_binding_count
  from public.skpe_project_initiative_bindings b
  where b.skpe_project_id = target_project_id
    and b.binding_type = 'strategic_plan_implementation';

  if v_binding_count <> 1 then
    raise exception
      'Atualização bloqueada: esperado exatamente 1 vínculo transversal para o projeto; encontrados %.',
      v_binding_count
      using errcode = '55000';
  end if;

  select *
    into v_binding
  from public.skpe_project_initiative_bindings b
  where b.skpe_project_id = target_project_id
    and b.binding_type = 'strategic_plan_implementation'
  for update;

  if v_binding.organization_id <> v_project.organization_id then
    raise exception
      'Atualização bloqueada: organização do vínculo divergente do projeto.'
      using errcode = '55000';
  end if;

  -- ----------------------------------------------------------
  -- 5. Iniciativa transversal vinculada.
  -- ----------------------------------------------------------
  select *
    into v_initiative
  from public.sparks_initiatives
  where id = v_binding.initiative_id
    and archived_at is null
  for update;

  if v_initiative.id is null then
    raise exception
      'Atualização bloqueada: iniciativa transversal vinculada não encontrada.'
      using errcode = '55000';
  end if;

  if v_initiative.organization_id <> v_project.organization_id then
    raise exception
      'Atualização bloqueada: organização da iniciativa divergente do projeto.'
      using errcode = '55000';
  end if;

  if v_initiative.initiative_class <> 'project' then
    raise exception
      'Atualização bloqueada: a iniciativa vinculada não possui classe project.'
      using errcode = '55000';
  end if;

  -- ----------------------------------------------------------
  -- 6. Normalização dos atributos identitários.
  -- ----------------------------------------------------------
  v_code := trim(target_code);
  v_name := trim(target_name);
  v_description := nullif(trim(target_description), '');

  if v_code is null or length(v_code) = 0 then
    raise exception
      'Informe o código do projeto.'
      using errcode = '22023';
  end if;

  if v_name is null or length(v_name) = 0 then
    raise exception
      'Informe o nome do projeto.'
      using errcode = '22023';
  end if;

  -- ----------------------------------------------------------
  -- 7. Colisão transversal.
  -- ----------------------------------------------------------
  if exists (
    select 1
    from public.sparks_initiatives si
    where si.organization_id = v_project.organization_id
      and si.code = v_code
      and si.id <> v_initiative.id
  ) then
    raise exception
      'Já existe outra iniciativa organizacional com o código "%".',
      v_code
      using errcode = '23505';
  end if;

  -- Defesa de compatibilidade no workspace especializado.
  if exists (
    select 1
    from public.skpe_projects p
    where p.organization_id = v_project.organization_id
      and p.code = v_code
      and p.id <> v_project.id
  ) then
    raise exception
      'Já existe outro projeto SK-PE com o código "%".',
      v_code
      using errcode = '23505';
  end if;

  -- ----------------------------------------------------------
  -- 8. Snapshot anterior.
  -- ----------------------------------------------------------
  v_before := jsonb_build_object(
    'identity_authority', 'sparks_initiatives',
    'initiative', jsonb_build_object(
      'id', v_initiative.id,
      'code', v_initiative.code,
      'name', v_initiative.name,
      'description', v_initiative.description
    ),
    'skpe_project_projection', jsonb_build_object(
      'id', v_project.id,
      'code', v_project.code,
      'name', v_project.name,
      'description', v_project.description
    ),
    'projection_matches_authority',
      v_project.code is not distinct from v_initiative.code
      and v_project.name is not distinct from v_initiative.name
      and v_project.description is not distinct from v_initiative.description
  );

  if v_initiative.code is not distinct from v_code
     and v_initiative.name is not distinct from v_name
     and v_initiative.description is not distinct from v_description
     and v_project.code is not distinct from v_code
     and v_project.name is not distinct from v_name
     and v_project.description is not distinct from v_description then
    raise exception
      'Nenhuma alteração identitária foi identificada.'
      using errcode = '22023';
  end if;

  -- ----------------------------------------------------------
  -- 9. Autoridade transversal primeiro.
  -- ----------------------------------------------------------
  update public.sparks_initiatives
  set
    code = v_code,
    name = v_name,
    description = v_description,
    updated_at = timezone('utc', now()),
    updated_by = auth.uid(),
    last_update_at = timezone('utc', now())
  where id = v_initiative.id;

  -- ----------------------------------------------------------
  -- 10. Projeção metodológica compatível.
  -- ----------------------------------------------------------
  update public.skpe_projects
  set
    code = v_code,
    name = v_name,
    description = v_description,
    updated_at = timezone('utc', now()),
    updated_by = auth.uid()
  where id = v_project.id;

  -- ----------------------------------------------------------
  -- 11. Snapshot posterior.
  -- ----------------------------------------------------------
  v_after := jsonb_build_object(
    'identity_authority', 'sparks_initiatives',
    'initiative', jsonb_build_object(
      'id', v_initiative.id,
      'code', v_code,
      'name', v_name,
      'description', v_description
    ),
    'skpe_project_projection', jsonb_build_object(
      'id', v_project.id,
      'code', v_code,
      'name', v_name,
      'description', v_description
    ),
    'projection_matches_authority', true
  );

  -- ----------------------------------------------------------
  -- 12. Auditoria.
  -- ----------------------------------------------------------
  insert into public.skpe_journey_audit (
    organization_id,
    project_id,
    actor_user_id,
    action_code,
    reason,
    previous_data,
    new_data
  )
  values (
    v_project.organization_id,
    v_project.id,
    auth.uid(),
    'project_identity_updated',
    trim(change_reason),
    v_before,
    v_after || jsonb_build_object(
      'binding_id', v_binding.id
    )
  );
end;
$$;

revoke all
on function public.update_skpe_project_identity(
  uuid,
  text,
  text,
  text,
  text
)
from public, anon;

grant execute
on function public.update_skpe_project_identity(
  uuid,
  text,
  text,
  text,
  text
)
to authenticated, service_role;

comment on function public.update_skpe_project_identity(
  uuid,
  text,
  text,
  text,
  text
) is
  'Atualiza de forma governada e atômica a identidade transversal do Projeto SK-PE em sparks_initiatives e sua projeção compatível em skpe_projects.';

commit;