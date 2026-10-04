-- Govern PEM-02.03 completion with explicit positioning readiness.
-- This migration does not create validation decisions, reconcile v26, mutate strategic content,
-- or advance Journey state.

create or replace function public.get_skpe_pem0203_positioning_readiness(
  target_formulation_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $function$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  theme_count integer := 0;
  perspective_count integer := 0;
  decided_theme_count integer := 0;
  decided_perspective_count integer := 0;
  unresolved_decision_count integer := 0;
  counterproof_confirmed boolean := false;
  issues jsonb := '[]'::jsonb;
  blocking_count integer := 0;
begin
  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id=target_formulation_id;

  if formulation_row.id is null then
    raise exception using
      errcode='22023',
      message='Formulação Estratégica não encontrada.';
  end if;

  if not public.can_view_skpe_formulation(formulation_row.organization_id) then
    raise exception using
      errcode='42501',
      message='Acesso negado à prontidão de PEM-02.03.';
  end if;

  select count(*)::integer
  into theme_count
  from public.skpe_strategic_themes theme
  where theme.formulation_id=formulation_row.id
    and theme.organization_id=formulation_row.organization_id
    and theme.project_id=formulation_row.project_id
    and theme.status<>'archived';

  select count(*)::integer
  into perspective_count
  from public.skpe_bsc_perspectives perspective
  where perspective.formulation_id=formulation_row.id
    and perspective.organization_id=formulation_row.organization_id
    and perspective.project_id=formulation_row.project_id
    and perspective.status<>'archived';

  with latest as (
    select distinct on (event.entity_type,event.entity_id)
      event.entity_type,
      event.entity_id,
      event.decision_action,
      event.metadata
    from public.skpe_positioning_validation_events event
    where event.formulation_id=formulation_row.id
    order by event.entity_type,event.entity_id,event.decision_sequence desc
  )
  select
    count(*) filter (where latest.entity_type='strategic_theme')::integer,
    count(*) filter (where latest.entity_type='bsc_perspective')::integer,
    count(*) filter (
      where latest.decision_action in ('adjust','replace','remove')
        and not coalesce(
          (latest.metadata->>'canonical_mutation_applied')::boolean,
          false
        )
    )::integer
  into
    decided_theme_count,
    decided_perspective_count,
    unresolved_decision_count
  from latest;

  select exists (
    select 1
    from public.skpe_evidence_sources evidence
    where evidence.organization_id=formulation_row.organization_id
      and evidence.project_id=formulation_row.project_id
      and evidence.cycle_code='PEM-02.03'
      and (
        lower(coalesce(
          evidence.metadata->'documentary_counterproof'->>'status',
          ''
        )) in ('confirmed','reconciled','validated','accepted','approved')
        or lower(coalesce(
          evidence.metadata->>'counterproof_status',
          ''
        )) in ('confirmed','reconciled','validated','accepted','approved')
      )
  )
  into counterproof_confirmed;

  if theme_count=0 then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0203_THEMES_MISSING',
      'severity','blocking',
      'message','PEM-02.03 exige Temas Estratégicos materializados para validação.'
    ));
  end if;

  if perspective_count=0 then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0203_PERSPECTIVES_MISSING',
      'severity','blocking',
      'message','PEM-02.03 exige Perspectivas Estratégicas materializadas para validação.'
    ));
  end if;

  if decided_theme_count<theme_count then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0203_THEME_DECISIONS_PENDING',
      'severity','blocking',
      'message','Todos os Temas Estratégicos exigem decisão humana explícita.',
      'affectedCount',theme_count-decided_theme_count
    ));
  end if;

  if decided_perspective_count<perspective_count then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0203_PERSPECTIVE_DECISIONS_PENDING',
      'severity','blocking',
      'message','Todas as Perspectivas Estratégicas exigem decisão humana explícita.',
      'affectedCount',perspective_count-decided_perspective_count
    ));
  end if;

  if unresolved_decision_count>0 then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0203_CANONICAL_MUTATION_PENDING',
      'severity','blocking',
      'message','Existem decisões de ajustar, substituir ou remover ainda não materializadas no conteúdo canônico.',
      'affectedCount',unresolved_decision_count
    ));
  end if;

  if not counterproof_confirmed then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0203_V26_COUNTERPROOF_PENDING',
      'severity','blocking',
      'message','A contraprova estruturada v26 precisa ser submetida e reconciliada antes da conclusão de PEM-02.03.'
    ));
  end if;

  select count(*)::integer
  into blocking_count
  from jsonb_array_elements(issues) issue
  where issue->>'severity'='blocking';

  return jsonb_build_object(
    'formulationId',formulation_row.id,
    'projectId',formulation_row.project_id,
    'organizationId',formulation_row.organization_id,
    'readyForCompletion',blocking_count=0,
    'blockingIssueCount',blocking_count,
    'issues',issues,
    'counts',jsonb_build_object(
      'themes',theme_count,
      'themeDecisions',decided_theme_count,
      'perspectives',perspective_count,
      'perspectiveDecisions',decided_perspective_count,
      'unresolvedCanonicalMutations',unresolved_decision_count
    ),
    'counterproof',jsonb_build_object(
      'required',true,
      'confirmed',counterproof_confirmed,
      'expectedArtifacts',jsonb_build_array('planilha v26','HTML v26')
    ),
    'methodologyRules',jsonb_build_object(
      'humanDecisionRequiredForEveryTheme',true,
      'humanDecisionRequiredForEveryPerspective',true,
      'reportedAttestationIsNotEnough',true,
      'counterproofRequiredBeforeCompletion',true,
      'canonicalMutationMustBeResolvedBeforeCompletion',true
    )
  );
end;
$function$;

revoke all on function public.get_skpe_pem0203_positioning_readiness(uuid)
from public,anon;
grant execute on function public.get_skpe_pem0203_positioning_readiness(uuid)
to authenticated,service_role;

create or replace function public.skpe_guard_pem0203_completion()
returns trigger
language plpgsql
security definer
set search_path=''
as $function$
declare
  formulation_id uuid;
  readiness jsonb;
begin
  if new.code<>'PEM-02.03' or new.status<>'completed' then
    return new;
  end if;

  select id
  into formulation_id
  from public.skpe_strategic_formulations
  where project_id=new.project_id
    and archived_at is null
  order by version_number desc
  limit 1;

  if formulation_id is null then
    raise exception using
      errcode='55000',
      message='PEM-02.03 não pode ser concluída sem Formulação Estratégica.';
  end if;

  readiness:=public.get_skpe_pem0203_positioning_readiness(formulation_id);

  if not coalesce((readiness->>'readyForCompletion')::boolean,false) then
    raise exception using
      errcode='55000',
      message='PEM-02.03 não pode ser concluída: há decisões humanas, materializações ou contraprova v26 pendentes.',
      detail=readiness::text;
  end if;

  new.metadata:=jsonb_set(
    coalesce(new.metadata,'{}'::jsonb),
    '{completionEvidence}',
    jsonb_build_object(
      'readinessVerifiedAt',timezone('utc',now()),
      'readinessSnapshot',readiness
    ),
    true
  );

  return new;
end;
$function$;

drop trigger if exists skpe_pem0203_completion_guard
on public.skpe_journey_items;

create trigger skpe_pem0203_completion_guard
before update of status,progress
on public.skpe_journey_items
for each row
execute function public.skpe_guard_pem0203_completion();

comment on function public.get_skpe_pem0203_positioning_readiness(uuid) is
'Canonical readiness for PEM-02.03. Requires explicit human decisions for every Theme/Perspective, resolved canonical mutations and reconciled v26 counterproof.';

comment on function public.skpe_guard_pem0203_completion() is
'Fail-closed completion guard for PEM-02.03. Does not create decisions or reconcile evidence.';
