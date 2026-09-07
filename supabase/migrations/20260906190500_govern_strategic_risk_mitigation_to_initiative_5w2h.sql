-- SK-PE — Govern many-to-many strategic risk mitigation -> initiative -> 5W2H
-- Reconciled with DEV on 2026-09-06. Migration-only artifact. Do not apply automatically.

begin;

alter table public.skpe_strategic_risk_items
  add column if not exists residual_probability_label text,
  add column if not exists residual_impact_label text,
  add column if not exists residual_assessment_status text not null default 'not_assessed',
  add column if not exists residual_assessment_evidence_reference text,
  add column if not exists residual_assessed_at timestamptz,
  add column if not exists residual_assessed_by uuid references public.profiles(id);

comment on column public.skpe_strategic_risk_items.residual_probability_label is
  'Probabilidade residual/reavaliada do risco apos execucao e avaliacao das acoes de mitigacao. Usada para posicionamento na matriz de riscos mitigados.';

comment on column public.skpe_strategic_risk_items.residual_impact_label is
  'Impacto residual/reavaliado do risco apos execucao e avaliacao das acoes de mitigacao. Usado para posicionamento na matriz de riscos mitigados.';

comment on column public.skpe_strategic_risk_items.residual_score is
  'Nivel residual numerico. Isoladamente nao comprova mitigacao efetiva nem posiciona o risco na matriz 5x5; deve ser acompanhado de probabilidade residual, impacto residual e avaliacao de efetividade.';

comment on column public.skpe_strategic_risk_items.residual_assessment_status is
  'Estado da avaliacao residual: not_assessed, planned ou assessed. Apenas assessed, com evidencia e mitigacao efetiva, habilita a matriz de riscos mitigados.';

comment on column public.skpe_strategic_risk_items.residual_assessment_evidence_reference is
  'Referencia da evidencia que sustenta a reavaliacao residual apos a mitigacao.';

alter table public.skpe_strategic_risk_items
  add constraint skpe_strategic_risk_items_residual_assessment_status_check
  check (residual_assessment_status in ('not_assessed', 'planned', 'assessed'));

alter table public.skpe_strategic_risk_items
  add constraint skpe_strategic_risk_items_residual_probability_label_check
  check (
    residual_probability_label is null
    or lower(residual_probability_label) in ('muito baixa', 'baixa', 'média', 'media', 'alta', 'muito alta')
  ),
  add constraint skpe_strategic_risk_items_residual_impact_label_check
  check (
    residual_impact_label is null
    or lower(residual_impact_label) in ('muito baixo', 'baixo', 'médio', 'medio', 'alto', 'muito alto')
  );

create or replace function public.skpe_risk_axis_ordinal(p_value text)
returns integer
language sql
immutable
as $$
  select case lower(btrim(coalesce(p_value, '')))
    when 'muito baixa' then 1
    when 'muito baixo' then 1
    when 'baixa' then 2
    when 'baixo' then 2
    when 'média' then 3
    when 'media' then 3
    when 'médio' then 3
    when 'medio' then 3
    when 'alta' then 4
    when 'alto' then 4
    when 'muito alta' then 5
    when 'muito alto' then 5
    else null
  end;
$$;

create or replace function public.skpe_assert_strategic_risk_residual_assessment()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_probability integer;
  v_impact integer;
begin
  if new.residual_assessment_status = 'assessed' then
    v_probability := public.skpe_risk_axis_ordinal(new.residual_probability_label);
    v_impact := public.skpe_risk_axis_ordinal(new.residual_impact_label);

    if v_probability is null or v_impact is null then
      raise exception 'Assessed residual risk requires governed probability and impact labels';
    end if;

    if new.residual_score is null or new.residual_score <> (v_probability * v_impact) then
      raise exception 'Residual score must equal residual probability x impact';
    end if;

    if not public.skpe_text_is_present(new.residual_assessment_evidence_reference) then
      raise exception 'Assessed residual risk requires residual assessment evidence';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_skpe_assert_strategic_risk_residual_assessment
  on public.skpe_strategic_risk_items;

create trigger trg_skpe_assert_strategic_risk_residual_assessment
before insert or update on public.skpe_strategic_risk_items
for each row execute function public.skpe_assert_strategic_risk_residual_assessment();

-- Cardinalidade canônica: risco 1..N mitigacoes; iniciativa 1..N riscos.
-- Apenas a mitigacao primaria e unica POR RISCO, nunca por iniciativa.
-- Efetividade, evidencia e contribuicao sao registradas por vinculo risco x mitigacao.

create table public.skpe_strategic_risk_mitigation_links (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  project_id uuid not null references public.skpe_projects(id) on delete cascade,
  strategic_risk_id uuid not null references public.skpe_strategic_risk_items(id) on delete cascade,
  initiative_id uuid not null references public.skpe_initiatives(id) on delete cascade,
  initiative_action_id uuid not null references public.skpe_initiative_actions(id) on delete cascade,
  mitigation_role text not null default 'primary',
  link_status text not null default 'proposed',
  effectiveness_status text not null default 'not_assessed',
  effectiveness_evidence_reference text,
  contribution_statement text not null,
  notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc'::text, now()),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default timezone('utc'::text, now()),
  updated_by uuid references public.profiles(id),
  archived_at timestamptz,
  constraint skpe_strategic_risk_mitigation_links_role_check
    check (mitigation_role in ('primary', 'supporting')),
  constraint skpe_strategic_risk_mitigation_links_status_check
    check (link_status in ('proposed', 'validated', 'executing', 'effective', 'ineffective', 'cancelled')),
  constraint skpe_strategic_risk_mitigation_links_effectiveness_check
    check (effectiveness_status in ('not_assessed', 'pending', 'effective', 'partially_effective', 'ineffective')),
  constraint skpe_strategic_risk_mitigation_links_unique_action
    unique (strategic_risk_id, initiative_action_id)
);

comment on table public.skpe_strategic_risk_mitigation_links is
  'Vinculo governado muitos-para-muitos entre risco estrategico, iniciativa do PE e acao de mitigacao. Uma iniciativa pode mitigar varios riscos e um risco pode ter varias iniciativas. Cada risco pode ter no maximo uma mitigacao primaria ativa e nao cancelada; a efetividade e avaliada por vinculo risco x mitigacao, com evidencia e reavaliacao residual.';

comment on column public.skpe_strategic_risk_mitigation_links.contribution_statement is
  'Declaracao objetiva de como a iniciativa/acao contribui para tratar o risco especifico deste vinculo. Obrigatoria porque uma mesma iniciativa pode mitigar riscos diferentes por mecanismos diferentes.';

create index idx_skpe_strategic_risk_mitigation_links_scope
  on public.skpe_strategic_risk_mitigation_links (organization_id, project_id, strategic_risk_id);

create index idx_skpe_strategic_risk_mitigation_links_initiative
  on public.skpe_strategic_risk_mitigation_links (initiative_id, initiative_action_id);

create unique index uq_skpe_strategic_risk_primary_mitigation_per_risk
  on public.skpe_strategic_risk_mitigation_links (strategic_risk_id)
  where mitigation_role = 'primary' and archived_at is null and link_status <> 'cancelled';

create or replace function public.skpe_text_is_present(p_value text)
returns boolean
language sql
immutable
as $$
  select nullif(btrim(coalesce(p_value, '')), '') is not null;
$$;

create or replace function public.skpe_initiative_has_complete_5w2h(p_initiative_id uuid)
returns boolean
language sql
stable
security invoker
set search_path = public
as $$
  select coalesce((
    select
      public.skpe_text_is_present(i.what_text)
      and public.skpe_text_is_present(i.why_text)
      and public.skpe_text_is_present(i.where_text)
      and public.skpe_text_is_present(i.when_text)
      and public.skpe_text_is_present(i.who_text)
      and public.skpe_text_is_present(i.how_text)
      and public.skpe_text_is_present(i.how_much_text)
    from public.skpe_initiatives i
    where i.id = p_initiative_id
      and i.archived_at is null
  ), false);
$$;

create or replace function public.skpe_initiative_action_has_complete_5w2h(p_action_id uuid)
returns boolean
language sql
stable
security invoker
set search_path = public
as $$
  select coalesce((
    select
      public.skpe_text_is_present(a.what_text)
      and public.skpe_text_is_present(a.why_text)
      and public.skpe_text_is_present(a.where_text)
      and public.skpe_text_is_present(a.when_text)
      and public.skpe_text_is_present(a.who_text)
      and public.skpe_text_is_present(a.how_text)
      and public.skpe_text_is_present(a.how_much_text)
    from public.skpe_initiative_actions a
    where a.id = p_action_id
      and a.archived_at is null
  ), false);
$$;

create or replace function public.skpe_strategic_risk_requires_mitigation(p_risk_id uuid)
returns boolean
language sql
stable
security invoker
set search_path = public
as $$
  select coalesce((
    select
      lower(coalesce(r.validation_status, '')) in ('approved', 'validated')
      or lower(coalesce(r.status, '')) in ('approved', 'validated')
      or (
        lower(coalesce(r.risk_acceptance, '')) in ('aceito', 'accepted', 'aprovado', 'approved')
        and public.skpe_text_is_present(r.acceptance_evidence)
        and public.skpe_text_is_present(r.management_recognition)
      )
    from public.skpe_strategic_risk_items r
    where r.id = p_risk_id
      and r.archived_at is null
  ), false);
$$;

comment on function public.skpe_strategic_risk_requires_mitigation(uuid) is
  'Considera validacao formal do risco ou aceite formal com evidencia e reconhecimento da direcao. Evita confundir status operacional Em andamento/Planejado com validacao metodologica.';

create or replace function public.validate_skpe_strategic_risk_mitigation_link()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_risk_org uuid;
  v_risk_project uuid;
  v_initiative_org uuid;
  v_initiative_project uuid;
  v_action_org uuid;
  v_action_project uuid;
  v_action_initiative uuid;
  v_residual_assessment_status text;
  v_residual_probability_label text;
  v_residual_impact_label text;
  v_residual_score numeric;
  v_residual_evidence text;
begin
  select
    organization_id,
    project_id,
    residual_assessment_status,
    residual_probability_label,
    residual_impact_label,
    residual_score,
    residual_assessment_evidence_reference
  into
    v_risk_org,
    v_risk_project,
    v_residual_assessment_status,
    v_residual_probability_label,
    v_residual_impact_label,
    v_residual_score,
    v_residual_evidence
  from public.skpe_strategic_risk_items
  where id = new.strategic_risk_id
    and archived_at is null;

  if v_risk_org is null then
    raise exception 'Strategic risk % does not exist or is archived', new.strategic_risk_id;
  end if;

  select organization_id, project_id
    into v_initiative_org, v_initiative_project
  from public.skpe_initiatives
  where id = new.initiative_id
    and archived_at is null;

  if v_initiative_org is null then
    raise exception 'Initiative % does not exist or is archived', new.initiative_id;
  end if;

  select organization_id, project_id, initiative_id
    into v_action_org, v_action_project, v_action_initiative
  from public.skpe_initiative_actions
  where id = new.initiative_action_id
    and archived_at is null;

  if v_action_org is null then
    raise exception 'Initiative action % does not exist or is archived', new.initiative_action_id;
  end if;

  if new.organization_id <> v_risk_org
     or new.organization_id <> v_initiative_org
     or new.organization_id <> v_action_org
     or new.project_id <> v_risk_project
     or new.project_id <> v_initiative_project
     or new.project_id <> v_action_project then
    raise exception 'Risk, initiative, action and mitigation link must share organization/project scope';
  end if;

  if v_action_initiative <> new.initiative_id then
    raise exception 'Mitigation action % does not belong to initiative %', new.initiative_action_id, new.initiative_id;
  end if;

  if not public.skpe_text_is_present(new.contribution_statement) then
    raise exception 'Risk mitigation link requires contribution_statement';
  end if;

  if new.link_status in ('validated', 'executing', 'effective') then
    if not public.skpe_initiative_has_complete_5w2h(new.initiative_id) then
      raise exception 'Initiative % must have complete 5W2H before mitigation link can be %', new.initiative_id, new.link_status;
    end if;

    if not public.skpe_initiative_action_has_complete_5w2h(new.initiative_action_id) then
      raise exception 'Mitigation action % must have complete 5W2H before mitigation link can be %', new.initiative_action_id, new.link_status;
    end if;
  end if;

  if new.link_status = 'effective' then
    if new.effectiveness_status <> 'effective' then
      raise exception 'Effective mitigation link requires effectiveness_status=effective';
    end if;

    if not public.skpe_text_is_present(new.effectiveness_evidence_reference) then
      raise exception 'Effective mitigation link requires effectiveness evidence';
    end if;

    if v_residual_assessment_status <> 'assessed'
       or not public.skpe_text_is_present(v_residual_probability_label)
       or not public.skpe_text_is_present(v_residual_impact_label)
       or v_residual_score is null
       or not public.skpe_text_is_present(v_residual_evidence) then
      raise exception 'Effective mitigation requires assessed residual probability, impact, score and evidence';
    end if;
  end if;

  new.updated_at := timezone('utc'::text, now());
  return new;
end;
$$;

create trigger trg_validate_skpe_strategic_risk_mitigation_link
before insert or update on public.skpe_strategic_risk_mitigation_links
for each row execute function public.validate_skpe_strategic_risk_mitigation_link();

alter table public.skpe_strategic_risk_mitigation_links enable row level security;

create policy skpe_strategic_risk_mitigation_links_select
  on public.skpe_strategic_risk_mitigation_links
  for select
  using (public.can_view_skpe_journey(organization_id));

create policy skpe_strategic_risk_mitigation_links_manage
  on public.skpe_strategic_risk_mitigation_links
  for all
  using (public.can_manage_skpe_journey(organization_id))
  with check (public.can_manage_skpe_journey(organization_id));

create or replace view public.skpe_strategic_risk_mitigation_readiness
with (security_invoker = true)
as
select
  r.id as strategic_risk_id,
  r.organization_id,
  r.project_id,
  r.code as risk_code,
  r.risk_event,
  r.status as risk_status,
  r.validation_status as risk_validation_status,
  r.risk_acceptance,
  public.skpe_strategic_risk_requires_mitigation(r.id) as mitigation_required,
  count(distinct l.id) filter (where l.archived_at is null and l.link_status <> 'cancelled') as mitigation_link_count,
  count(distinct l.initiative_id) filter (where l.archived_at is null and l.link_status <> 'cancelled') as linked_initiative_count,
  count(distinct l.initiative_action_id) filter (where l.archived_at is null and l.link_status <> 'cancelled') as linked_action_count,
  count(distinct sibling.strategic_risk_id) filter (
    where sibling.archived_at is null
      and sibling.link_status <> 'cancelled'
      and sibling.strategic_risk_id <> r.id
  ) as other_risks_sharing_linked_initiatives,
  count(distinct l.id) filter (
    where l.archived_at is null
      and l.link_status <> 'cancelled'
      and l.mitigation_role = 'primary'
  ) as primary_mitigation_count,
  coalesce(bool_or(
    l.archived_at is null
    and l.link_status <> 'cancelled'
    and l.mitigation_role = 'primary'
    and public.skpe_initiative_has_complete_5w2h(l.initiative_id)
    and public.skpe_initiative_action_has_complete_5w2h(l.initiative_action_id)
  ), false) as has_primary_mitigation_with_complete_5w2h,
  coalesce(bool_or(
    l.archived_at is null
    and l.link_status = 'effective'
    and l.mitigation_role = 'primary'
    and l.effectiveness_status = 'effective'
    and public.skpe_text_is_present(l.effectiveness_evidence_reference)
  ), false) as has_effective_primary_mitigation,
  r.residual_probability_label,
  r.residual_impact_label,
  r.residual_score,
  r.residual_assessment_status,
  r.residual_assessment_evidence_reference,
  r.residual_assessed_at,
  case
    when not public.skpe_strategic_risk_requires_mitigation(r.id) then 'not_required_yet'
    when coalesce(bool_or(
      l.archived_at is null
      and l.link_status <> 'cancelled'
      and l.mitigation_role = 'primary'
      and public.skpe_initiative_has_complete_5w2h(l.initiative_id)
      and public.skpe_initiative_action_has_complete_5w2h(l.initiative_action_id)
    ), false) then 'ready'
    else 'missing_primary_mitigation_or_5w2h'
  end as readiness_status,
  (
    r.residual_assessment_status = 'assessed'
    and public.skpe_text_is_present(r.residual_probability_label)
    and public.skpe_text_is_present(r.residual_impact_label)
    and r.residual_score is not null
    and public.skpe_text_is_present(r.residual_assessment_evidence_reference)
    and coalesce(bool_or(
      l.archived_at is null
      and l.link_status = 'effective'
      and l.mitigation_role = 'primary'
      and l.effectiveness_status = 'effective'
      and public.skpe_text_is_present(l.effectiveness_evidence_reference)
    ), false)
  ) as mitigated_matrix_ready
from public.skpe_strategic_risk_items r
left join public.skpe_strategic_risk_mitigation_links l
  on l.strategic_risk_id = r.id
left join public.skpe_strategic_risk_mitigation_links sibling
  on sibling.initiative_id = l.initiative_id
  and sibling.strategic_risk_id <> r.id
where r.archived_at is null
group by
  r.id,
  r.organization_id,
  r.project_id,
  r.code,
  r.risk_event,
  r.status,
  r.validation_status,
  r.risk_acceptance,
  r.residual_probability_label,
  r.residual_impact_label,
  r.residual_score,
  r.residual_assessment_status,
  r.residual_assessment_evidence_reference,
  r.residual_assessed_at;

comment on view public.skpe_strategic_risk_mitigation_readiness is
  'Read model governado: risco formalmente aceito/validado -> ao menos uma mitigacao, com no maximo uma primaria por risco -> iniciativa/acao 5W2H -> efetividade avaliada por vinculo -> reavaliacao residual com evidencia -> matriz mitigada. Iniciativas podem ser compartilhadas entre riscos.';

create or replace view public.skpe_risk_mitigation_initiative_projection
with (security_invoker = true)
as
select
  l.id as mitigation_link_id,
  l.organization_id,
  l.project_id,
  r.id as strategic_risk_id,
  r.code as risk_code,
  r.risk_event,
  l.mitigation_role,
  l.link_status,
  l.effectiveness_status,
  l.contribution_statement,
  i.id as initiative_id,
  i.code as initiative_code,
  i.name as initiative_name,
  i.status as initiative_status,
  a.id as initiative_action_id,
  a.code as initiative_action_code,
  a.name as initiative_action_name,
  public.skpe_initiative_has_complete_5w2h(i.id) as initiative_5w2h_complete,
  public.skpe_initiative_action_has_complete_5w2h(a.id) as action_5w2h_complete,
  ('Mitigacao de Risco · ' || r.code) as source_label
from public.skpe_strategic_risk_mitigation_links l
join public.skpe_strategic_risk_items r
  on r.id = l.strategic_risk_id
join public.skpe_initiatives i
  on i.id = l.initiative_id
join public.skpe_initiative_actions a
  on a.id = l.initiative_action_id
where l.archived_at is null
  and l.link_status <> 'cancelled'
  and r.archived_at is null
  and i.archived_at is null
  and a.archived_at is null;

comment on view public.skpe_risk_mitigation_initiative_projection is
  'Projecao para Plano de Iniciativas e navegacao Risco -> Iniciativa -> Acao -> 5W2H. Uma iniciativa pode aparecer associada a varios riscos; cada linha preserva a contribuicao e a efetividade por vinculo risco x mitigacao.';

commit;
