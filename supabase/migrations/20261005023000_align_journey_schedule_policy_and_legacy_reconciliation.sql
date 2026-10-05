-- Align SPARKs PE schedule policy with the governed operating practice:
-- usual delivery = 45 business days, extendable to 90; post-delivery follow-up = up to 90.
-- Contract/Service Order dates override these defaults when explicitly provided.

update public.sparks_parameter_definitions
set
  name = 'Prazo usual para entrega da Jornada',
  description = 'Referencia SPARKs para concluir a entrega do Planejamento Estrategico quando a Ordem de Servico ou contrato nao definir prazo especifico.',
  default_value = '45'::jsonb,
  metadata = coalesce(metadata,'{}'::jsonb) || jsonb_build_object(
    'policy','usual_delivery',
    'contract_overrides_default',true,
    'updated_by_governance','2026-10-05'
  )
where parameter_key='SKPE.JOURNEY.STANDARD_DURATION';

insert into public.sparks_parameter_definitions (
  parameter_key,parameter_group,name,description,value_type,default_value,module_code,unit,validation_rule,metadata
)
values (
  'SKPE.JOURNEY.EXTENDED_DURATION',
  'skpe.journey.temporal',
  'Prazo ampliado para entrega da Jornada',
  'Referencia maxima usual de ampliacao da entrega quando a complexidade ou o escopo exigirem e nao houver prazo contratual especifico.',
  'number','90'::jsonb,'SK-PE','days','{"min":1,"max":730}'::jsonb,
  '{"source":"SPARKs PE default","ownership":"parameter_engine","policy":"extended_delivery","contract_overrides_default":true}'::jsonb
)
on conflict (parameter_key) do update
set name=excluded.name,
    description=excluded.description,
    default_value=excluded.default_value,
    metadata=coalesce(public.sparks_parameter_definitions.metadata,'{}'::jsonb) || excluded.metadata;

update public.sparks_parameter_definitions
set
  name='Referencia acelerada da Jornada',
  description='Referencia de 45 dias uteis para entrega da Jornada; mantida por compatibilidade com configuracoes anteriores.',
  default_value='45'::jsonb
where parameter_key='SKPE.JOURNEY.ACCELERATED_DURATION';

update public.sparks_parameter_definitions
set
  name='Acompanhamento apos a entrega',
  description='Periodo sugerido de acompanhamento da implantacao apos a entrega do Planejamento Estrategico.',
  default_value='90'::jsonb
where parameter_key='SKPE.JOURNEY.POST_DELIVERY_FOLLOWUP';

-- 45 business days across PEM-00..PEM-04.
update public.sparks_parameter_definitions
set default_value = case parameter_key
  when 'SKPE.JOURNEY.PEM00_DURATION' then '8'::jsonb
  when 'SKPE.JOURNEY.PEM01_DURATION' then '9'::jsonb
  when 'SKPE.JOURNEY.PEM02_DURATION' then '10'::jsonb
  when 'SKPE.JOURNEY.PEM03_DURATION' then '9'::jsonb
  when 'SKPE.JOURNEY.PEM04_DURATION' then '9'::jsonb
  else default_value
end
where parameter_key in (
  'SKPE.JOURNEY.PEM00_DURATION','SKPE.JOURNEY.PEM01_DURATION','SKPE.JOURNEY.PEM02_DURATION',
  'SKPE.JOURNEY.PEM03_DURATION','SKPE.JOURNEY.PEM04_DURATION'
);

-- Phase-level distribution for the 45-day usual delivery window.
update public.sparks_parameter_definitions
set default_value = case parameter_key
  when 'SKPE.JOURNEY.PEM00.01_DURATION' then '1'::jsonb
  when 'SKPE.JOURNEY.PEM00.02_DURATION' then '1'::jsonb
  when 'SKPE.JOURNEY.PEM00.03_DURATION' then '1'::jsonb
  when 'SKPE.JOURNEY.PEM00.04_DURATION' then '1'::jsonb
  when 'SKPE.JOURNEY.PEM00.05_DURATION' then '1'::jsonb
  when 'SKPE.JOURNEY.PEM00.06_DURATION' then '1'::jsonb
  when 'SKPE.JOURNEY.PEM00.07_DURATION' then '1'::jsonb
  when 'SKPE.JOURNEY.PEM00.08_DURATION' then '1'::jsonb

  when 'SKPE.JOURNEY.PEM01.01_DURATION' then '1'::jsonb
  when 'SKPE.JOURNEY.PEM01.02_DURATION' then '1'::jsonb
  when 'SKPE.JOURNEY.PEM01.03_DURATION' then '2'::jsonb
  when 'SKPE.JOURNEY.PEM01.04_DURATION' then '1'::jsonb
  when 'SKPE.JOURNEY.PEM01.05_DURATION' then '2'::jsonb
  when 'SKPE.JOURNEY.PEM01.06_DURATION' then '2'::jsonb

  when 'SKPE.JOURNEY.PEM02.01_DURATION' then '1'::jsonb
  when 'SKPE.JOURNEY.PEM02.02_DURATION' then '2'::jsonb
  when 'SKPE.JOURNEY.PEM02.03_DURATION' then '2'::jsonb
  when 'SKPE.JOURNEY.PEM02.04_DURATION' then '2'::jsonb
  when 'SKPE.JOURNEY.PEM02.05_DURATION' then '3'::jsonb

  when 'SKPE.JOURNEY.PEM03.01_DURATION' then '2'::jsonb
  when 'SKPE.JOURNEY.PEM03.02_DURATION' then '3'::jsonb
  when 'SKPE.JOURNEY.PEM03.03_DURATION' then '2'::jsonb
  when 'SKPE.JOURNEY.PEM03.04_DURATION' then '2'::jsonb

  when 'SKPE.JOURNEY.PEM04.01_DURATION' then '3'::jsonb
  when 'SKPE.JOURNEY.PEM04.02_DURATION' then '2'::jsonb
  when 'SKPE.JOURNEY.PEM04.03_DURATION' then '2'::jsonb
  when 'SKPE.JOURNEY.PEM04.04_DURATION' then '2'::jsonb
  else default_value
end
where parameter_key like 'SKPE.JOURNEY.PEM%.%_DURATION';

create or replace function public.reconcile_skpe_journey_schedule_proposal(
  p_project_id uuid,
  p_reference_date date default current_date
)
returns uuid
language plpgsql
security definer
set search_path=''
as $function$
declare
  v_project public.skpe_projects%rowtype;
  v_version public.skpe_journey_schedule_versions%rowtype;
  v_cad jsonb;
  v_phase jsonb;
  v_mode text;
  v_followup integer;
  v_cursor date;
  v_duration integer;
  v_item record;
  v_root text;
  v_followup_count integer;
  v_followup_index integer := 0;
  v_followup_start_offset integer;
  v_followup_end_offset integer;
begin
  if auth.uid() is null then
    raise exception using errcode='42501', message='Usuario nao autenticado.';
  end if;

  select * into v_project
  from public.skpe_projects
  where id=p_project_id and archived_at is null;

  if v_project.id is null then
    raise exception using errcode='22023', message='Projeto SK-PE ativo nao encontrado.';
  end if;

  if not public.can_manage_skpe_journey_schedule(v_project.organization_id) then
    raise exception using errcode='42501', message='Acesso negado para gerenciar o cronograma da Jornada.';
  end if;

  select * into v_version
  from public.skpe_journey_schedule_versions
  where project_id=p_project_id
    and schedule_kind='baseline'
    and governance_status='draft'
  order by version_number desc
  limit 1
  for update;

  if v_version.id is null then
    insert into public.skpe_journey_schedule_versions(
      organization_id,project_id,version_number,schedule_kind,governance_status,
      title,notes,is_current_plan,metadata,created_by,updated_by
    )
    values(
      v_project.organization_id,v_project.id,
      coalesce((select max(version_number) from public.skpe_journey_schedule_versions where project_id=p_project_id),0)+1,
      'baseline','draft',
      'Cronograma proposto da Jornada',
      'Proposta SPARKs sujeita a revisao do lider do projeto e validacao da Organizacao.',
      false,
      jsonb_build_object(
        'proposal_origin','sparks_parameter_engine',
        'proposal_status','proposed_for_validation',
        'contract_or_service_order_precedence',true
      ),
      auth.uid(),auth.uid()
    )
    returning * into v_version;
  end if;

  delete from public.skpe_journey_schedule_items
  where schedule_version_id=v_version.id;

  v_cad:=public.get_skpe_journey_cadence_snapshot(v_project.organization_id,v_project.id);
  v_phase:=v_cad->'phase_cadence'->'phases';
  v_mode:=v_cad->'duration_mode'->>'value';
  v_followup:=(v_cad->'post_delivery_followup'->>'value')::integer;
  v_cursor:=public.sparks_date_at_offset(coalesce(p_reference_date,current_date),0,v_mode);

  -- Historical reconciliation: completed leaf items use their real execution dates.
  insert into public.skpe_journey_schedule_items(
    organization_id,project_id,schedule_version_id,journey_item_id,
    planned_start_date,planned_end_date,source_mode,planning_note,metadata,created_by,updated_by
  )
  select
    v_project.organization_id,v_project.id,v_version.id,i.id,
    coalesce(i.actual_start_date,i.actual_end_date),
    coalesce(i.actual_end_date,i.actual_start_date),
    'explicit',
    'Projeto ja estava em andamento quando o cronograma foi reconciliado; periodo proposto preserva o realizado conhecido.',
    jsonb_build_object('schedule_origin','legacy_actual_reconciliation','proposal_status','proposed_for_validation'),
    auth.uid(),auth.uid()
  from public.skpe_journey_items i
  where i.project_id=v_project.id
    and i.archived_at is null
    and i.status='completed'
    and (i.actual_start_date is not null or i.actual_end_date is not null)
    and not exists (
      select 1 from public.skpe_journey_items c
      where c.parent_item_id=i.id and c.archived_at is null and c.status<>'cancelled'
    );

  select count(*) into v_followup_count
  from public.skpe_journey_items i
  where i.project_id=v_project.id
    and i.archived_at is null
    and i.status<>'completed'
    and i.code like 'PEM-05.%'
    and i.item_type<>'gate'
    and not exists (
      select 1 from public.skpe_journey_items c
      where c.parent_item_id=i.id and c.archived_at is null and c.status<>'cancelled'
    );

  for v_item in
    select i.*
    from public.skpe_journey_items i
    where i.project_id=v_project.id
      and i.archived_at is null
      and i.status<>'completed'
      and not exists (
        select 1 from public.skpe_journey_items c
        where c.parent_item_id=i.id and c.archived_at is null and c.status<>'cancelled'
      )
    order by i.display_order,i.code
  loop
    v_root:=split_part(v_item.code,'.',1);

    if v_item.item_type='gate' then
      insert into public.skpe_journey_schedule_items(
        organization_id,project_id,schedule_version_id,journey_item_id,
        planned_start_date,planned_end_date,source_mode,planning_note,metadata,created_by,updated_by
      )
      values(
        v_project.organization_id,v_project.id,v_version.id,v_item.id,
        null,
        case
          when v_root='PEM-05'
            then public.sparks_date_at_offset(v_cursor,greatest(v_followup,1)-1,v_mode)
          else v_cursor
        end,
        'explicit',
        'Marco proposto para decisao institucional; nao consome duracao propria.',
        jsonb_build_object('schedule_origin','sparks_methodological_suggestion','proposal_status','proposed_for_validation'),
        auth.uid(),auth.uid()
      );

      if v_root<>'PEM-05' then
        v_cursor:=public.sparks_date_at_offset(v_cursor,1,v_mode);
      end if;
      continue;
    end if;

    if v_root='PEM-05' then
      v_followup_start_offset:=floor((v_followup_index*v_followup::numeric)/greatest(v_followup_count,1))::integer;
      v_followup_end_offset:=greatest(
        v_followup_start_offset,
        floor(((v_followup_index+1)*v_followup::numeric)/greatest(v_followup_count,1))::integer-1
      );

      insert into public.skpe_journey_schedule_items(
        organization_id,project_id,schedule_version_id,journey_item_id,
        planned_start_date,planned_end_date,source_mode,planning_note,metadata,created_by,updated_by
      )
      values(
        v_project.organization_id,v_project.id,v_version.id,v_item.id,
        public.sparks_date_at_offset(v_cursor,v_followup_start_offset,v_mode),
        public.sparks_date_at_offset(v_cursor,v_followup_end_offset,v_mode),
        'explicit',
        'Janela proposta para acompanhamento da implantacao apos a entrega do Planejamento Estrategico.',
        jsonb_build_object('schedule_origin','sparks_methodological_suggestion','proposal_status','proposed_for_validation','post_delivery_followup',true),
        auth.uid(),auth.uid()
      );

      v_followup_index:=v_followup_index+1;
      continue;
    end if;

    v_duration:=coalesce((v_phase->v_item.code->>'value')::integer,1);

    insert into public.skpe_journey_schedule_items(
      organization_id,project_id,schedule_version_id,journey_item_id,
      planned_start_date,planned_end_date,source_mode,planning_note,metadata,created_by,updated_by
    )
    values(
      v_project.organization_id,v_project.id,v_version.id,v_item.id,
      v_cursor,
      public.sparks_date_at_offset(v_cursor,greatest(v_duration,1)-1,v_mode),
      'explicit',
      'Periodo sugerido pelo SPARKs a partir da cadencia metodologica vigente; sujeito a validacao da Organizacao.',
      jsonb_build_object(
        'schedule_origin','sparks_methodological_suggestion',
        'proposal_status','proposed_for_validation',
        'duration',v_duration,
        'duration_mode',v_mode
      ),
      auth.uid(),auth.uid()
    );

    v_cursor:=public.sparks_date_at_offset(v_cursor,greatest(v_duration,1),v_mode);
  end loop;

  perform public.skpe_rollup_journey_schedule_internal(v_version.id,auth.uid());

  update public.skpe_journey_schedule_versions
  set
    title='Cronograma proposto da Jornada',
    notes='Proposta SPARKs: entrega usual em ate 45 dias uteis, ampliavel a 90 conforme escopo; acompanhamento pos-entrega de ate 90 dias uteis. Ordem de Servico/contrato prevalece quando trouxer prazo especifico.',
    metadata=coalesce(metadata,'{}'::jsonb) || jsonb_build_object(
      'proposal_origin','sparks_parameter_engine',
      'proposal_status','proposed_for_validation',
      'usual_delivery_business_days',45,
      'extended_delivery_business_days',90,
      'post_delivery_followup_business_days',90,
      'contract_or_service_order_precedence',true,
      'legacy_reconciliation',exists(
        select 1 from public.skpe_journey_items i
        where i.project_id=v_project.id and i.status='completed'
      ),
      'reference_date',p_reference_date
    ),
    updated_at=timezone('utc',now()),
    updated_by=auth.uid()
  where id=v_version.id;

  insert into public.skpe_journey_audit(
    organization_id,project_id,journey_item_id,actor_user_id,
    action_code,reason,previous_data,new_data
  )
  values(
    v_project.organization_id,v_project.id,null,auth.uid(),
    'journey_schedule_proposal_reconciled',
    'Cronograma proposto reconciliado com o realizado e com a cadencia metodologica SPARKs.',
    null,
    jsonb_build_object(
      'schedule_version_id',v_version.id,
      'proposal_status','proposed_for_validation',
      'usual_delivery_business_days',45,
      'extended_delivery_business_days',90,
      'post_delivery_followup_business_days',90,
      'reference_date',p_reference_date
    )
  );

  return v_version.id;
end;
$function$;

revoke all on function public.reconcile_skpe_journey_schedule_proposal(uuid,date) from public,anon;
grant execute on function public.reconcile_skpe_journey_schedule_proposal(uuid,date) to authenticated,service_role;

comment on function public.reconcile_skpe_journey_schedule_proposal(uuid,date) is
'Creates/reconciles a non-approved SPARKs Journey schedule proposal. Completed legacy items preserve actual dates; remaining work follows the effective cadence. Contract/Service Order dates take precedence when available.';


-- User-facing enrichment for PEM-02.GATE: expose the strategic horizon as years,
-- keeping UUIDs as internal traceability only.
alter function public.get_skpe_pem02_gate_readiness(uuid)
  rename to get_skpe_pem02_gate_readiness_pre_user_facing_20261005;

create or replace function public.get_skpe_pem02_gate_readiness(
  target_project_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $function$
declare
  base_readiness jsonb;
  horizon_row public.skpe_strategic_horizons%rowtype;
begin
  base_readiness :=
    public.get_skpe_pem02_gate_readiness_pre_user_facing_20261005(target_project_id);

  select * into horizon_row
  from public.skpe_strategic_horizons
  where project_id=target_project_id
    and is_current=true
  limit 1;

  return base_readiness || jsonb_build_object(
    'strategicHorizonStartYear',horizon_row.horizon_start_year,
    'strategicHorizonEndYear',horizon_row.horizon_end_year,
    'userFacingLanguage','pt-BR'
  );
end;
$function$;

revoke all on function public.get_skpe_pem02_gate_readiness(uuid) from public,anon;
grant execute on function public.get_skpe_pem02_gate_readiness(uuid) to authenticated,service_role;

comment on function public.get_skpe_pem02_gate_readiness(uuid) is
'PEM-02.GATE readiness enriched for user-facing presentation in Portuguese; internal identifiers remain available for traceability but need not be displayed.';


-- User-facing wording: the validation point explains the sequence without exposing
-- internal codes or suggesting that PEM-03 may start before Macrophase 2 ratification.
update public.skpe_journey_items
set
  description='Ratificar a Formulação Estratégica e o Plano de Evolução antes de iniciar o Desdobramento Estratégico.',
  updated_at=timezone('utc',now()),
  updated_by=auth.uid()
where code='PEM-02.GATE'
  and archived_at is null;

update public.skpe_methodology_template_items
set
  description='Ratificar a Formulação Estratégica e o Plano de Evolução antes de iniciar o Desdobramento Estratégico.',
  updated_at=timezone('utc',now()),
  updated_by=auth.uid()
where code='PEM-02.GATE';
