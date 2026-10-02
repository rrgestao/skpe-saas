-- SPARKs PE - Matriz Default v1 de cadencia por Megafase.
-- Implantacao = soma de PEM-00..PEM-04. PEM-05 = acompanhamento pos-entrega.
begin;

insert into public.sparks_parameter_definitions (
  parameter_key, parameter_group, name, description, value_type,
  default_value, module_code, unit, validation_rule, metadata
) values
  ('SKPE.JOURNEY.PEM00_DURATION','skpe.journey.cadence','PEM-00 · Governanca e preparacao',
   'Duracao default da PEM-00 na implantacao da Jornada Estrategica.',
   'number','10'::jsonb,'SK-PE','days','{"min":1,"max":180}'::jsonb,
   '{"source":"SPARKs PE cadence matrix v1","cadence_role":"implementation"}'::jsonb),
  ('SKPE.JOURNEY.PEM01_DURATION','skpe.journey.cadence','PEM-01 · Diagnostico',
   'Duracao default da PEM-01 na implantacao da Jornada Estrategica.',
   'number','20'::jsonb,'SK-PE','days','{"min":1,"max":180}'::jsonb,
   '{"source":"SPARKs PE cadence matrix v1","cadence_role":"implementation"}'::jsonb),
  ('SKPE.JOURNEY.PEM02_DURATION','skpe.journey.cadence','PEM-02 · Formulacao Estrategica',
   'Duracao default da PEM-02 na implantacao da Jornada Estrategica.',
   'number','25'::jsonb,'SK-PE','days','{"min":1,"max":180}'::jsonb,
   '{"source":"SPARKs PE cadence matrix v1","cadence_role":"implementation"}'::jsonb),
  ('SKPE.JOURNEY.PEM03_DURATION','skpe.journey.cadence','PEM-03 · Desdobramento Estrategico',
   'Duracao default da PEM-03 na implantacao da Jornada Estrategica.',
   'number','20'::jsonb,'SK-PE','days','{"min":1,"max":180}'::jsonb,
   '{"source":"SPARKs PE cadence matrix v1","cadence_role":"implementation"}'::jsonb),
  ('SKPE.JOURNEY.PEM04_DURATION','skpe.journey.cadence','PEM-04 · Implementacao e Mobilizacao',
   'Duracao default da PEM-04 na implantacao da Jornada Estrategica.',
   'number','15'::jsonb,'SK-PE','days','{"min":1,"max":180}'::jsonb,
   '{"source":"SPARKs PE cadence matrix v1","cadence_role":"implementation"}'::jsonb)
on conflict (parameter_key) do nothing;

update public.sparks_parameter_definitions
set description = 'Referencia global SPARKs PE. A duracao efetiva da implantacao e composta pela soma das cadencias de PEM-00 a PEM-04.'
where parameter_key = 'SKPE.JOURNEY.STANDARD_DURATION';
with latest as (
  select v.id
  from public.skpe_methodology_template_versions v
  join public.skpe_methodology_templates t on t.id = v.template_id
  where t.code = 'SKPE-OFICIAL' and t.is_recommended = true and v.status = 'published'
  order by v.effective_from desc nulls last, v.created_at desc
  limit 1
), cadence(code, duration_days, role) as (
  values
    ('PEM-00',10,'implementation'),
    ('PEM-01',20,'implementation'),
    ('PEM-02',25,'implementation'),
    ('PEM-03',20,'implementation'),
    ('PEM-04',15,'implementation')
)
update public.skpe_methodology_template_items i
set metadata = coalesce(i.metadata,'{}'::jsonb) || jsonb_build_object(
      'duration_unit','business_days',
      'cadence_default_days',c.duration_days,
      'detailed_duration_status','configured_macrophase_v1',
      'cadence_role',c.role,
      'cadence_source','SPARKs PE cadence matrix v1'
    )
from latest, cadence c
where i.template_version_id = latest.id and i.code = c.code and i.item_type = 'macrophase';

with latest as (
  select v.id
  from public.skpe_methodology_template_versions v
  join public.skpe_methodology_templates t on t.id=v.template_id
  where t.code='SKPE-OFICIAL' and t.is_recommended=true and v.status='published'
  order by v.effective_from desc nulls last,v.created_at desc limit 1
)
update public.skpe_methodology_template_items i
set metadata = coalesce(i.metadata,'{}'::jsonb) || jsonb_build_object(
  'cadence_role','post_delivery_continuous',
  'cadence_parameter','SKPE.JOURNEY.POST_DELIVERY_FOLLOWUP',
  'cadence_source','SPARKs PE cadence matrix v1'
)
from latest
where i.template_version_id=latest.id and i.code='PEM-05' and i.item_type='macrophase';

create or replace function public.get_skpe_journey_cadence_snapshot(
  p_organization_id uuid,
  p_project_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_mode jsonb;
  v_followup jsonb;
  v_p0 jsonb; v_p1 jsonb; v_p2 jsonb; v_p3 jsonb; v_p4 jsonb;
  v_total integer;
begin
  v_mode := public.get_sparks_effective_parameter('SKPE.JOURNEY.DURATION_MODE',p_organization_id,'SK-PE',p_project_id);
  v_followup := public.get_sparks_effective_parameter('SKPE.JOURNEY.POST_DELIVERY_FOLLOWUP',p_organization_id,'SK-PE',p_project_id);
  v_p0 := public.get_sparks_effective_parameter('SKPE.JOURNEY.PEM00_DURATION',p_organization_id,'SK-PE',p_project_id);
  v_p1 := public.get_sparks_effective_parameter('SKPE.JOURNEY.PEM01_DURATION',p_organization_id,'SK-PE',p_project_id);
  v_p2 := public.get_sparks_effective_parameter('SKPE.JOURNEY.PEM02_DURATION',p_organization_id,'SK-PE',p_project_id);
  v_p3 := public.get_sparks_effective_parameter('SKPE.JOURNEY.PEM03_DURATION',p_organization_id,'SK-PE',p_project_id);
  v_p4 := public.get_sparks_effective_parameter('SKPE.JOURNEY.PEM04_DURATION',p_organization_id,'SK-PE',p_project_id);
  v_total := (v_p0->>'value')::int + (v_p1->>'value')::int + (v_p2->>'value')::int + (v_p3->>'value')::int + (v_p4->>'value')::int;
  return jsonb_build_object(
    'duration_mode',v_mode,'implementation_total',v_total,'pem00',v_p0,'pem01',v_p1,'pem02',v_p2,'pem03',v_p3,'pem04',v_p4,'post_delivery_followup',v_followup
  );
end;
$$;
create or replace function public.initialize_skpe_journey_business_day_baseline(
  p_project_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_project public.skpe_projects%rowtype;
  v_version_id uuid;
  v_existing_id uuid;
  v_start_date date;
  v_impl_end date;
  v_mode text;
  v_followup integer;
  v_p0 integer; v_p1 integer; v_p2 integer; v_p3 integer; v_p4 integer;
  v_impl_duration integer;
  v_cadence jsonb;
  v_item record;
  v_segment_start integer;
  v_segment_duration integer;
  v_start_offset integer;
  v_end_offset integer;
begin
  if auth.uid() is null then raise exception 'Usuario nao autenticado.' using errcode='42501'; end if;
  select * into v_project from public.skpe_projects where id=p_project_id and archived_at is null;
  if v_project.id is null then raise exception 'Projeto SK-PE ativo nao encontrado.'; end if;
  if not public.can_manage_skpe_journey_schedule(v_project.organization_id) then raise exception 'Acesso negado para gerenciar o cronograma da Jornada.' using errcode='42501'; end if;
  select id into v_existing_id
  from public.skpe_journey_schedule_versions
  where project_id=p_project_id
    and schedule_kind='baseline'
    and governance_status in ('draft','pending_approval','approved')
  order by version_number desc
  limit 1;
  if v_existing_id is not null then return v_existing_id; end if;

  v_cadence := public.get_skpe_journey_cadence_snapshot(v_project.organization_id,v_project.id);
  v_mode := v_cadence->'duration_mode'->>'value';
  v_followup := (v_cadence->'post_delivery_followup'->>'value')::int;
  v_p0 := (v_cadence->'pem00'->>'value')::int;
  v_p1 := (v_cadence->'pem01'->>'value')::int;
  v_p2 := (v_cadence->'pem02'->>'value')::int;
  v_p3 := (v_cadence->'pem03'->>'value')::int;
  v_p4 := (v_cadence->'pem04'->>'value')::int;
  v_impl_duration := v_p0+v_p1+v_p2+v_p3+v_p4;
  v_start_date := coalesce(v_project.start_date,current_date);
  v_impl_end := public.sparks_date_at_offset(v_start_date,v_impl_duration-1,v_mode);

  update public.skpe_projects
  set target_end_date=v_impl_end, updated_at=timezone('utc',now()), updated_by=auth.uid()
  where id=v_project.id;

  update public.sparks_initiatives si
  set target_end_date=v_impl_end, updated_at=timezone('utc',now()), updated_by=auth.uid()
  from public.skpe_project_initiative_bindings b
  where b.skpe_project_id=v_project.id and b.initiative_id=si.id;
  insert into public.skpe_journey_schedule_versions (
    organization_id,project_id,version_number,schedule_kind,governance_status,
    title,notes,is_current_plan,metadata,created_by,updated_by
  ) values (
    v_project.organization_id,v_project.id,
    coalesce((select max(version_number) from public.skpe_journey_schedule_versions where project_id=p_project_id),0)+1,
    'baseline','draft','Linha de Base Proposta da Jornada Estrategica',
    format('Proposta SPARKs PE composta por PEM-00..PEM-04 em %s %s, seguida de %s %s de acompanhamento inicial.',v_impl_duration,v_mode,v_followup,v_mode),
    false,
    jsonb_build_object(
      'proposal_origin','sparks_parameter_engine',
      'implementation_duration',v_impl_duration,
      'duration_mode',v_mode,
      'post_delivery_followup',v_followup,
      'cadence_matrix_version','SPARKs PE v1',
      'parameter_snapshot',v_cadence,
      'internal_allocation','macrophase_governed_leaf_provisional',
      'methodological_detail_status','pem_configured_phase_pending'
    ),auth.uid(),auth.uid()
  ) returning id into v_version_id;

  for v_item in
    with recursive tree as (
      select ji.id,ji.parent_item_id,ji.code,ji.item_type,ji.display_order,ji.code as root_code
      from public.skpe_journey_items ji
      where ji.project_id=p_project_id and ji.archived_at is null and ji.parent_item_id is null
      union all
      select c.id,c.parent_item_id,c.code,c.item_type,c.display_order,t.root_code
      from public.skpe_journey_items c join tree t on c.parent_item_id=t.id
      where c.project_id=p_project_id and c.archived_at is null
    ), leaves as (
      select t.*,
        row_number() over(partition by root_code order by display_order,code)-1 as leaf_index,
        count(*) over(partition by root_code) as leaf_count
      from tree t
      where not exists (select 1 from public.skpe_journey_items c where c.parent_item_id=t.id and c.archived_at is null)
    ) select * from leaves order by display_order,code
  loop
    case v_item.root_code
      when 'PEM-00' then v_segment_start:=0; v_segment_duration:=v_p0;
      when 'PEM-01' then v_segment_start:=v_p0; v_segment_duration:=v_p1;
      when 'PEM-02' then v_segment_start:=v_p0+v_p1; v_segment_duration:=v_p2;
      when 'PEM-03' then v_segment_start:=v_p0+v_p1+v_p2; v_segment_duration:=v_p3;
      when 'PEM-04' then v_segment_start:=v_p0+v_p1+v_p2+v_p3; v_segment_duration:=v_p4;
      when 'PEM-05' then v_segment_start:=v_impl_duration; v_segment_duration:=greatest(v_followup,1);
      else continue;
    end case;

    v_start_offset := v_segment_start + floor((v_item.leaf_index * v_segment_duration::numeric) / v_item.leaf_count)::int;
    v_end_offset := v_segment_start + greatest(
      floor((v_item.leaf_index * v_segment_duration::numeric) / v_item.leaf_count)::int,
      floor(((v_item.leaf_index + 1) * v_segment_duration::numeric) / v_item.leaf_count)::int - 1
    );

    insert into public.skpe_journey_schedule_items (
      organization_id,project_id,schedule_version_id,journey_item_id,
      planned_start_date,planned_end_date,source_mode,planning_note,
      metadata,created_by,updated_by
    ) values (
      v_project.organization_id,v_project.id,v_version_id,v_item.id,
      case when v_item.item_type in ('gate','deliverable') then null else public.sparks_date_at_offset(v_start_date,v_start_offset,v_mode) end,
      public.sparks_date_at_offset(v_start_date,v_end_offset,v_mode),
      'derived',
      'Sugestao SPARKs PE: janela da Megafase governada; distribuicao interna entre fases/atividades ainda provisoria.',
      jsonb_build_object('root_macrophase',v_item.root_code,'allocation_status','macrophase_governed_leaf_provisional','duration_mode',v_mode),
      auth.uid(),auth.uid()
    );
  end loop;
  insert into public.skpe_journey_audit (
    organization_id,project_id,journey_item_id,actor_user_id,
    action_code,reason,previous_data,new_data
  ) values (
    v_project.organization_id,v_project.id,null,auth.uid(),
    'journey_baseline_proposal_initialized',
    'Linha de Base Proposta criada com Matriz Default SPARKs PE por Megafase.',
    null,
    jsonb_build_object(
      'schedule_version_id',v_version_id,
      'governance_status','draft',
      'implementation_duration',v_impl_duration,
      'duration_mode',v_mode,
      'implementation_target_end_date',v_impl_end,
      'post_delivery_followup',v_followup,
      'cadence_matrix_version','SPARKs PE v1',
      'parameter_snapshot',v_cadence
    )
  );

  return v_version_id;
end;
$$;

comment on function public.initialize_skpe_journey_business_day_baseline(uuid) is
  'Cria Linha de Base Proposta usando cadencia efetiva por Megafase: PEM-00..PEM-04 compoem a implantacao e PEM-05 usa acompanhamento pos-entrega.';
create or replace function public.start_skpe_project_pem00(
  target_organization_id uuid,
  target_project_name text default null,
  target_horizon_start_year integer default extract(year from current_date)::integer,
  target_horizon_end_year integer default (extract(year from current_date)::integer + 4)
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  organization_record public.organizations%rowtype;
  existing_project_id uuid;
  created_project_id uuid;
  baseline_version_id uuid;
  base_code text;
  candidate_code text;
  suffix integer := 1;
  journey_target_end_date date;
  cadence_snapshot jsonb;
  journey_duration integer;
  journey_duration_mode text;
begin
  if not public.can_manage_skpe_journey(target_organization_id) then
    raise exception 'Acesso negado: o usuario nao pode iniciar o Planejamento Estrategico desta organizacao.' using errcode='42501';
  end if;
  if target_horizon_start_year is null or target_horizon_end_year is null or target_horizon_end_year < target_horizon_start_year then
    raise exception 'Informe um horizonte estrategico valido.' using errcode='22023';
  end if;
  select * into organization_record
  from public.organizations
  where id=target_organization_id and status='active';
  if organization_record.id is null then
    raise exception 'Organizacao ativa nao localizada.' using errcode='22023';
  end if;

  select p.id into existing_project_id
  from public.skpe_projects p
  where p.organization_id=target_organization_id
    and p.archived_at is null
    and p.status <> 'archived'
  order by p.created_at desc
  limit 1;
  if existing_project_id is not null then return existing_project_id; end if;

  cadence_snapshot := public.get_skpe_journey_cadence_snapshot(target_organization_id,null);
  journey_duration := (cadence_snapshot->>'implementation_total')::int;
  journey_duration_mode := cadence_snapshot->'duration_mode'->>'value';

  base_code := regexp_replace(
    upper(coalesce(nullif(trim(organization_record.code),''),'ORGANIZACAO')),
    '[^A-Z0-9]+','-','g'
  );
  candidate_code := format('PE-%s-%s',trim(both '-' from base_code),target_horizon_start_year);
  while exists (
    select 1 from public.sparks_initiatives si
    where si.organization_id=target_organization_id and si.code=candidate_code
  ) or exists (
    select 1 from public.skpe_projects p
    where p.organization_id=target_organization_id and p.code=candidate_code
  ) loop
    suffix := suffix + 1;
    candidate_code := format('PE-%s-%s-%s',trim(both '-' from base_code),target_horizon_start_year,suffix);
  end loop;

  journey_target_end_date := public.sparks_date_at_offset(
    current_date,journey_duration-1,journey_duration_mode
  );

  created_project_id := public.create_skpe_project_from_template(
    target_organization_id,
    candidate_code,
    coalesce(nullif(trim(target_project_name),''),
      'Planejamento Estrategico de ' || coalesce(
        nullif(trim(organization_record.trade_name),''),
        organization_record.legal_name,
        organization_record.code
      )
    ),
    'Jornada estrategica iniciada pela Metafase de Governanca e Preparacao - PEM-00.',
    current_date,journey_target_end_date,null
  );
  update public.skpe_projects
  set current_phase_code='PEM-00',
      planning_horizon_start_year=target_horizon_start_year,
      planning_horizon_end_year=target_horizon_end_year,
      reference_year=target_horizon_start_year,
      review_cycle='Revisao anual',
      valid_from=current_date,
      valid_until=make_date(target_horizon_end_year,12,31),
      start_date=current_date,
      target_end_date=journey_target_end_date,
      progress=0,
      status='draft',
      updated_at=timezone('utc',now()),
      updated_by=auth.uid()
  where id=created_project_id;

  update public.skpe_journey_items
  set is_current=false,updated_at=timezone('utc',now()),updated_by=auth.uid()
  where project_id=created_project_id;

  update public.skpe_journey_items
  set status='in_progress',is_current=true,
      planned_start_date=coalesce(planned_start_date,current_date),
      updated_at=timezone('utc',now()),updated_by=auth.uid()
  where project_id=created_project_id and code='PEM-00';

  baseline_version_id := public.initialize_skpe_journey_business_day_baseline(created_project_id);
  insert into public.skpe_journey_audit (
    organization_id,project_id,actor_user_id,action_code,reason,new_data
  ) values (
    target_organization_id,created_project_id,auth.uid(),
    'project_started_pem00',
    'Planejamento Estrategico iniciado com Horizonte Estrategico separado da cadencia parametrizada por Megafase.',
    jsonb_build_object(
      'current_phase_code','PEM-00',
      'horizon_start_year',target_horizon_start_year,
      'horizon_end_year',target_horizon_end_year,
      'journey_start_date',current_date,
      'journey_target_end_date',journey_target_end_date,
      'journey_duration_value',journey_duration,
      'journey_duration_mode',journey_duration_mode,
      'cadence_matrix_version','SPARKs PE v1',
      'cadence_snapshot',cadence_snapshot,
      'baseline_proposal_version_id',baseline_version_id
    )
  );

  return created_project_id;
end;
$$;

comment on function public.start_skpe_project_pem00(uuid,text,integer,integer) is
  'Inicia Projeto SK-PE usando soma da cadencia efetiva de PEM-00..PEM-04 como janela de implantacao; PEM-05 permanece pos-entrega.';

revoke all on function public.get_skpe_journey_cadence_snapshot(uuid,uuid) from public,anon;
grant execute on function public.get_skpe_journey_cadence_snapshot(uuid,uuid) to authenticated,service_role;

commit;
