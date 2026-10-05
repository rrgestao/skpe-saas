-- Expand artifact requirements for PEM-03..PEM-05 phases and make automatic
-- Journey artifact materialization requirement-driven. This extends the
-- generic fallback created in 20261005032000 without changing Journey status.

with requirement_seed as (
  select *
  from (
    values
      ('REQ-PEM0301-MATRIZ','Matriz de OKRs e Resultados-Chave','PEM-03','PEM-03.01',null::text,'ANALYTICAL_MATRIX',
       'Matriz de trabalho com Objetivos de OKR, KRs, linhas de base, métricas, fontes e metas anualizadas.',10),
      ('REQ-PEM0301-VALIDACAO','Pacote de Validação de OKRs e Resultados-Chave','PEM-03','PEM-03.01',null::text,'EXECUTIVE_VALIDATION_PACKAGE',
       'Pacote para apresentação e validação humana dos OKRs e Resultados-Chave propostos.',20),
      ('REQ-PEM0302-MATRIZ','Matriz de Indicadores e Metas','PEM-03','PEM-03.02',null::text,'ANALYTICAL_MATRIX',
       'Matriz de indicadores, fórmulas, fontes, periodicidades, linhas de base e metas.',30),
      ('REQ-PEM0302-VALIDACAO','Pacote de Validação de Indicadores e Metas','PEM-03','PEM-03.02',null::text,'EXECUTIVE_VALIDATION_PACKAGE',
       'Pacote para validação dos indicadores e metas estratégicas.',40),
      ('REQ-PEM0303-PLANO','Portfólio de Iniciativas e Projetos Estratégicos','PEM-03','PEM-03.03',null::text,'ACTION_PLAN',
       'Portfólio de iniciativas e projetos vinculados aos KRs, priorizados e alocados aos Ciclos de Evolução.',50),
      ('REQ-PEM0303-VALIDACAO','Pacote de Validação de Iniciativas e Projetos','PEM-03','PEM-03.03',null::text,'EXECUTIVE_VALIDATION_PACKAGE',
       'Pacote para validação das iniciativas e projetos estratégicos.',60),
      ('REQ-PEM0304-MATRIZ','Matriz de Responsabilidades e Governança da Execução','PEM-03','PEM-03.04',null::text,'ANALYTICAL_MATRIX',
       'Matriz de responsabilidades, alçadas, ritos, escalonamentos e governança da execução.',70),
      ('REQ-PEM0304-VALIDACAO','Pacote de Validação da Governança da Execução','PEM-03','PEM-03.04',null::text,'EXECUTIVE_VALIDATION_PACKAGE',
       'Pacote para validação das responsabilidades e da governança da execução.',80),

      ('REQ-PEM0401-PLANO','Plano de Ativação da Estratégia','PEM-04','PEM-04.01',null::text,'ACTION_PLAN',
       'Plano de ativação com prioridades, dependências, marcos e prontidão para implantação.',110),
      ('REQ-PEM0401-VALIDACAO','Pacote de Validação da Ativação','PEM-04','PEM-04.01',null::text,'EXECUTIVE_VALIDATION_PACKAGE',
       'Pacote para validação da ativação do Plano de Implementação.',120),
      ('REQ-PEM0402-PLANO','Plano de Comunicação e Mobilização','PEM-04','PEM-04.02',null::text,'ACTION_PLAN',
       'Plano por público, objetivo, mensagem, canal, responsável e evidência de alcance.',130),
      ('REQ-PEM0402-VALIDACAO','Pacote de Validação da Comunicação e Mobilização','PEM-04','PEM-04.02',null::text,'EXECUTIVE_VALIDATION_PACKAGE',
       'Pacote para validação da comunicação e mobilização da estratégia.',140),
      ('REQ-PEM0403-PLANO','Plano de Capacidades e Gestão da Mudança','PEM-04','PEM-04.03',null::text,'ACTION_PLAN',
       'Plano para capacidades, lacunas, mudança e desenvolvimento necessários à execução.',150),
      ('REQ-PEM0403-VALIDACAO','Pacote de Validação de Capacidades e Mudança','PEM-04','PEM-04.03',null::text,'EXECUTIVE_VALIDATION_PACKAGE',
       'Pacote para validação das ações de capacidades e mudança.',160),
      ('REQ-PEM0404-MATRIZ','Matriz de Riscos da Implementação','PEM-04','PEM-04.04',null::text,'ANALYTICAL_MATRIX',
       'Matriz de riscos da implementação com causas, consequências, controles, tratamentos, indicadores e evidências.',170),
      ('REQ-PEM0404-VALIDACAO','Pacote de Validação dos Riscos da Implementação','PEM-04','PEM-04.04',null::text,'EXECUTIVE_VALIDATION_PACKAGE',
       'Pacote para validação dos riscos e tratamentos da implementação.',180),

      ('REQ-PEM0501-REGISTRO','Registro da Rotina de Monitoramento','PEM-05','PEM-05.01',null::text,'FOLLOW_UP_RECORD',
       'Registro estruturado da rotina de monitoramento da estratégia, KRs, iniciativas e riscos.',210),
      ('REQ-PEM0501-VALIDACAO','Pacote de Validação da Rotina de Monitoramento','PEM-05','PEM-05.01',null::text,'EXECUTIVE_VALIDATION_PACKAGE',
       'Pacote para validação da rotina de monitoramento.',220),
      ('REQ-PEM0502-MATRIZ','Análise Crítica de Desempenho','PEM-05','PEM-05.02',null::text,'ANALYTICAL_MATRIX',
       'Análise crítica comparando resultado, meta, causa do desvio, evidências e decisões necessárias.',230),
      ('REQ-PEM0502-VALIDACAO','Pacote de Validação da Análise Crítica','PEM-05','PEM-05.02',null::text,'EXECUTIVE_VALIDATION_PACKAGE',
       'Pacote para validação das conclusões da análise crítica de desempenho.',240),
      ('REQ-PEM0503-REGISTRO','Registro de Aprendizados e Melhorias','PEM-05','PEM-05.03',null::text,'FOLLOW_UP_RECORD',
       'Registro de aprendizados, causas, práticas eficazes e oportunidades de melhoria.',250),
      ('REQ-PEM0503-PLANO','Plano de Melhorias Priorizadas','PEM-05','PEM-05.03',null::text,'ACTION_PLAN',
       'Plano de melhorias derivado dos aprendizados e análises críticas.',260),
      ('REQ-PEM0504-MATRIZ','Proposta de Atualização Estratégica','PEM-05','PEM-05.04',null::text,'ANALYTICAL_MATRIX',
       'Proposta rastreável de atualização estratégica baseada em evidências e aprendizados.',270),
      ('REQ-PEM0504-VALIDACAO','Pacote de Validação da Atualização Estratégica','PEM-05','PEM-05.04',null::text,'EXECUTIVE_VALIDATION_PACKAGE',
       'Pacote para validação de eventual atualização da estratégia.',280)
  ) s(requirement_code,requirement_name,macrophase_code,phase_code,stage_code,artifact_type_code,requirement_description,sort_order)
)
insert into public.sparks_methodology_delivery_requirements(
  module_code,methodology_version,macrophase_code,phase_code,stage_code,
  artifact_type_id,requirement_code,requirement_name,requirement_description,
  mandatory,minimum_quantity,validation_required,blocks_closure,
  active,sort_order,metadata,created_by,updated_by
)
select
  'SK-PE','1.0.0',s.macrophase_code,s.phase_code,s.stage_code,
  t.id,s.requirement_code,s.requirement_name,s.requirement_description,
  true,1,true,false,
  true,s.sort_order,
  jsonb_build_object(
    'autoMaterializeOnOpen',true,
    'proposalOnly',true,
    'humanValidationRequired',true,
    'scope','journey_item'
  ),
  auth.uid(),auth.uid()
from requirement_seed s
join public.sparks_methodology_artifact_types t
  on t.module_code='SK-PE'
 and t.artifact_type_code=s.artifact_type_code
 and t.active=true
on conflict(module_code,methodology_version,requirement_code) do update
set
  requirement_name=excluded.requirement_name,
  requirement_description=excluded.requirement_description,
  macrophase_code=excluded.macrophase_code,
  phase_code=excluded.phase_code,
  stage_code=excluded.stage_code,
  artifact_type_id=excluded.artifact_type_id,
  mandatory=excluded.mandatory,
  minimum_quantity=excluded.minimum_quantity,
  validation_required=excluded.validation_required,
  blocks_closure=excluded.blocks_closure,
  active=true,
  sort_order=excluded.sort_order,
  metadata=excluded.metadata,
  updated_at=now(),
  updated_by=auth.uid();

create or replace function public.ensure_skpe_journey_item_artifacts(
  target_item_id uuid,
  target_reason text default 'Abertura governada da etapa da Jornada'
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $function$
declare
  v_item public.skpe_journey_items%rowtype;
  v_project public.skpe_projects%rowtype;
  v_req record;
  v_match_count integer:=0;
  v_role text;
  v_type_code text;
  v_title text;
  v_suffix text;
  v_requirement_id uuid;
  v_artifact_code text;
  v_type_id uuid;
  v_artifact_id uuid;
  v_content text;
  v_created integer:=0;
  v_existing integer:=0;
  v_macrophase_code text;
  v_phase_code text;
  v_stage_code text;
  v_file_name text;
  v_actor uuid;
begin
  select * into v_item
  from public.skpe_journey_items
  where id=target_item_id
    and archived_at is null
  for update;

  if v_item.id is null then
    raise exception using errcode='22023',message='Item da Jornada não encontrado.';
  end if;

  if v_item.item_type='gate' then
    return jsonb_build_object(
      'itemId',v_item.id,'itemCode',v_item.code,'createdCount',0,'existingCount',0,
      'skipped',true,'reason','Pontos de validação utilizam artefatos e decisão institucional próprios.'
    );
  end if;

  if v_item.item_type not in ('macrophase','phase','activity','deliverable') then
    return jsonb_build_object(
      'itemId',v_item.id,'itemCode',v_item.code,'createdCount',0,'existingCount',0,
      'skipped',true,'reason','Tipo de item sem pacote automático configurado.'
    );
  end if;

  if v_item.status not in ('in_progress','completed') then
    raise exception using
      errcode='55000',
      message='Os artefatos da etapa ficam disponíveis quando ela é aberta. Itens ainda bloqueados ou não iniciados não podem materializar propostas.';
  end if;

  select * into v_project
  from public.skpe_projects
  where id=v_item.project_id
    and archived_at is null;

  if v_project.id is null then
    raise exception using errcode='22023',message='Projeto SK-PE ativo não encontrado.';
  end if;

  if auth.uid() is not null
     and not (
       public.can_manage_methodology_artifacts(v_project.organization_id)
       or public.can_manage_skpe_journey(v_project.organization_id)
     ) then
    raise exception using errcode='42501',message='Acesso negado para preparar os artefatos da etapa.';
  end if;

  v_actor:=coalesce(auth.uid(),v_item.updated_by,v_item.created_by);
  v_macrophase_code:=split_part(v_item.code,'.',1);
  if v_item.item_type='macrophase' then
    v_macrophase_code:=v_item.code;
  end if;
  v_phase_code:=case when v_item.item_type='phase' then v_item.code else null end;
  v_stage_code:=case when v_item.item_type in ('activity','deliverable') then v_item.code else null end;

  for v_req in
    select
      r.id as requirement_id,
      r.requirement_code,
      r.requirement_name,
      r.artifact_type_id,
      t.artifact_type_code
    from public.sparks_methodology_delivery_requirements r
    join public.sparks_methodology_artifact_types t on t.id=r.artifact_type_id
    where r.module_code='SK-PE'
      and r.methodology_version='1.0.0'
      and r.active=true
      and coalesce((r.metadata->>'autoMaterializeOnOpen')::boolean,false)=true
      and r.gate_code is null
      and (
        (v_item.item_type='macrophase'
          and r.macrophase_code=v_item.code
          and r.phase_code is null
          and r.stage_code is null)
        or
        (v_item.item_type='phase' and r.phase_code=v_item.code)
        or
        (v_item.item_type in ('activity','deliverable') and r.stage_code=v_item.code)
      )
    order by r.sort_order,r.requirement_name
  loop
    v_match_count:=v_match_count+1;
    v_requirement_id:=v_req.requirement_id;
    v_type_id:=v_req.artifact_type_id;
    v_type_code:=v_req.artifact_type_code;
    v_title:=v_req.requirement_name;
    v_suffix:=regexp_replace(upper(v_req.requirement_code),'[^A-Z0-9]+','-','g');

    v_role:=case v_type_code
      when 'EXECUTIVE_VALIDATION_PACKAGE' then 'validation'
      when 'ACTION_PLAN' then 'activity_plan'
      when 'FOLLOW_UP_RECORD' then 'followup'
      else 'working'
    end;

    v_artifact_code:='AUTO-'||regexp_replace(upper(v_item.code),'[^A-Z0-9]+','-','g')||'-'||v_suffix;

    select id into v_artifact_id
    from public.sparks_methodology_artifacts
    where organization_id=v_project.organization_id
      and project_id=v_project.id
      and artifact_code=v_artifact_code
    limit 1;

    if v_artifact_id is not null then
      v_existing:=v_existing+1;
      continue;
    end if;

    v_content:=public.skpe_build_journey_artifact_markdown(v_item.id,v_role);
    v_file_name:=regexp_replace(v_artifact_code,'[^A-Z0-9._-]+','_','g')||'_v1.md';

    insert into public.sparks_methodology_artifacts(
      organization_id,project_id,module_code,artifact_type_id,requirement_id,
      artifact_code,title,purpose,
      macrophase_code,phase_code,stage_code,status,
      responsible_user_id,current_version_number,planned_due_date,
      source,metadata,created_by,updated_by
    )
    values(
      v_project.organization_id,v_project.id,'SK-PE',v_type_id,v_requirement_id,
      v_artifact_code,v_title,
      'Artefato requerido pela metodologia e disponibilizado automaticamente com sugestões SPARKs para a etapa.',
      v_macrophase_code,v_phase_code,v_stage_code,'in_preparation',
      v_item.responsible_user_id,1,coalesce(v_item.planned_end_date,v_item.actual_end_date),
      'SPARKs PE — Jornada',
      jsonb_build_object(
        'journeyItemId',v_item.id,
        'journeyItemCode',v_item.code,
        'journeyItemType',v_item.item_type,
        'autoMaterializedOnOpen',true,
        'proposalOnly',true,
        'humanValidationRequired',true,
        'artifactRole',v_role,
        'requirementCode',v_req.requirement_code,
        'reason',coalesce(nullif(trim(target_reason),''),'Abertura governada da etapa da Jornada')
      ),
      v_actor,v_actor
    )
    returning id into v_artifact_id;

    insert into public.sparks_methodology_artifact_versions(
      artifact_id,version_number,version_label,version_status,
      content_markdown,content_json,file_name,file_extension,
      change_summary,generated_by_ai,generated_prompt,generated_model,
      generated_at,created_by
    )
    values(
      v_artifact_id,1,'v1','draft',
      v_content,
      jsonb_build_object(
        'proposalOnly',true,
        'journeyItemId',v_item.id,
        'journeyItemCode',v_item.code,
        'artifactRole',v_role,
        'requirementCode',v_req.requirement_code,
        'humanValidationRequired',true,
        'generatedByMethodologyEngine',true
      ),
      v_file_name,'md',
      'Versão inicial requerida pela etapa e disponibilizada automaticamente.',
      false,null,null,null,v_actor
    );

    insert into public.sparks_methodology_artifact_audit(
      organization_id,project_id,artifact_id,actor_user_id,
      action_code,action_description,new_data
    )
    values(
      v_project.organization_id,v_project.id,v_artifact_id,v_actor,
      'JOURNEY_ARTIFACT_AUTO_MATERIALIZED',
      'Artefato metodológico requerido pela etapa foi disponibilizado automaticamente.',
      jsonb_build_object(
        'journey_item_id',v_item.id,
        'journey_item_code',v_item.code,
        'requirement_code',v_req.requirement_code,
        'artifact_role',v_role,
        'proposal_only',true
      )
    );

    v_created:=v_created+1;
  end loop;

  -- Fallback: every eligible opened item still gets a working and validation pair
  -- when no explicit methodology requirements have been configured for it.
  if v_match_count=0 then
    for v_role,v_type_code,v_title,v_suffix in
      select *
      from (
        values
          (
            case when v_item.item_type='activity' then 'activity_plan' else 'working' end,
            case when v_item.item_type='activity' then 'ACTION_PLAN' else 'ANALYTICAL_MATRIX' end,
            case when v_item.item_type='activity' then 'Plano de Trabalho' else 'Caderno de Trabalho e Recomendações' end,
            'TRABALHO'
          ),
          (
            case when v_item.item_type='activity' then 'followup' else 'validation' end,
            case when v_item.item_type='activity' then 'FOLLOW_UP_RECORD' else 'EXECUTIVE_VALIDATION_PACKAGE' end,
            case when v_item.item_type='activity' then 'Registro de Acompanhamento' else 'Pacote para Validação' end,
            case when v_item.item_type='activity' then 'ACOMPANHAMENTO' else 'VALIDACAO' end
          )
      ) q(role_code,type_code,title_text,suffix_text)
    loop
      v_requirement_id:=null;
      v_artifact_code:='AUTO-'||regexp_replace(upper(v_item.code),'[^A-Z0-9]+','-','g')||'-'||v_suffix;

      select id into v_artifact_id
      from public.sparks_methodology_artifacts
      where organization_id=v_project.organization_id
        and project_id=v_project.id
        and artifact_code=v_artifact_code
      limit 1;

      if v_artifact_id is not null then
        v_existing:=v_existing+1;
        continue;
      end if;

      select id into v_type_id
      from public.sparks_methodology_artifact_types
      where module_code='SK-PE'
        and artifact_type_code=v_type_code
        and active=true
      limit 1;

      if v_type_id is null then
        raise exception using
          errcode='55000',
          message='Tipo de artefato obrigatório não está configurado: '||v_type_code;
      end if;

      v_content:=public.skpe_build_journey_artifact_markdown(v_item.id,v_role);
      v_file_name:=regexp_replace(v_artifact_code,'[^A-Z0-9._-]+','_','g')||'_v1.md';

      insert into public.sparks_methodology_artifacts(
        organization_id,project_id,module_code,artifact_type_id,
        artifact_code,title,purpose,
        macrophase_code,phase_code,stage_code,status,
        responsible_user_id,current_version_number,planned_due_date,
        source,metadata,created_by,updated_by
      )
      values(
        v_project.organization_id,v_project.id,'SK-PE',v_type_id,
        v_artifact_code,v_title||' — '||v_item.name,
        'Artefato de trabalho gerado automaticamente com sugestões SPARKs para apoiar a evolução e a validação da etapa.',
        v_macrophase_code,v_phase_code,v_stage_code,'in_preparation',
        v_item.responsible_user_id,1,coalesce(v_item.planned_end_date,v_item.actual_end_date),
        'SPARKs PE — Jornada',
        jsonb_build_object(
          'journeyItemId',v_item.id,
          'journeyItemCode',v_item.code,
          'journeyItemType',v_item.item_type,
          'autoMaterializedOnOpen',true,
          'proposalOnly',true,
          'humanValidationRequired',true,
          'artifactRole',v_role,
          'reason',coalesce(nullif(trim(target_reason),''),'Abertura governada da etapa da Jornada')
        ),
        v_actor,v_actor
      )
      returning id into v_artifact_id;

      insert into public.sparks_methodology_artifact_versions(
        artifact_id,version_number,version_label,version_status,
        content_markdown,content_json,file_name,file_extension,
        change_summary,generated_by_ai,generated_prompt,generated_model,
        generated_at,created_by
      )
      values(
        v_artifact_id,1,'v1','draft',
        v_content,
        jsonb_build_object(
          'proposalOnly',true,
          'journeyItemId',v_item.id,
          'journeyItemCode',v_item.code,
          'artifactRole',v_role,
          'humanValidationRequired',true,
          'generatedByMethodologyEngine',true
        ),
        v_file_name,'md',
        'Versão inicial disponibilizada automaticamente com a abertura da etapa.',
        false,null,null,null,v_actor
      );

      insert into public.sparks_methodology_artifact_audit(
        organization_id,project_id,artifact_id,actor_user_id,
        action_code,action_description,new_data
      )
      values(
        v_project.organization_id,v_project.id,v_artifact_id,v_actor,
        'JOURNEY_ARTIFACT_AUTO_MATERIALIZED',
        'Artefato de trabalho disponibilizado automaticamente com a abertura da etapa da Jornada.',
        jsonb_build_object(
          'journey_item_id',v_item.id,
          'journey_item_code',v_item.code,
          'artifact_role',v_role,
          'proposal_only',true
        )
      );

      v_created:=v_created+1;
    end loop;
  end if;

  update public.skpe_journey_items
  set metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object(
        'artifactPackageStatus','available',
        'artifactPackageEnsuredAt',timezone('utc',now()),
        'artifactPackageCreatedCount',v_created,
        'artifactPackageExistingCount',v_existing,
        'artifactPackageRequirementCount',v_match_count
      ),
      updated_at=timezone('utc',now())
  where id=v_item.id;

  return jsonb_build_object(
    'itemId',v_item.id,
    'itemCode',v_item.code,
    'configuredRequirementCount',v_match_count,
    'createdCount',v_created,
    'existingCount',v_existing,
    'availableCount',v_created+v_existing,
    'proposalOnly',true,
    'humanValidationRequired',true
  );
end;
$function$;

revoke all on function public.ensure_skpe_journey_item_artifacts(uuid,text)
from public,anon;
grant execute on function public.ensure_skpe_journey_item_artifacts(uuid,text)
to authenticated,service_role;

comment on function public.ensure_skpe_journey_item_artifacts(uuid,text) is
'Requirement-driven SK-PE artifact materializer. On Journey item opening it creates every configured artifact required for that item; when no requirements exist, it creates a safe working/validation fallback. All outputs remain proposals until human validation.';
