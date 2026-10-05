-- Govern automatic, usable methodology artifacts for every SK-PE Journey item opening.
-- Artifact creation is proposal-only and never advances Journey status or fabricates validation.

insert into public.sparks_methodology_artifact_templates (
  artifact_type_id,
  template_code,
  template_name,
  template_version,
  language_code,
  description,
  content_structure,
  instructions,
  active,
  created_by,
  updated_by
)
select
  t.id,
  x.template_code,
  x.template_name,
  '1.0.0',
  'pt-BR',
  x.description,
  x.content_structure,
  x.instructions,
  true,
  auth.uid(),
  auth.uid()
from public.sparks_methodology_artifact_types t
join (
  values
    (
      'ANALYTICAL_MATRIX',
      'SKPE-JOURNEY-WORKING-PACKAGE',
      'Caderno de Trabalho e Recomendações',
      'Artefato de trabalho disponibilizado automaticamente quando uma Macrofase ou Etapa é aberta.',
      jsonb_build_object(
        'sections',jsonb_build_array(
          'Contexto da etapa','Objetivo','Sugestões SPARKs','Questões para análise',
          'Evidências e dados necessários','Decisões pendentes','Registro de ajustes'
        ),
        'proposal_only',true,
        'auto_materialize_on_open',true
      ),
      'Pré-preencher com o contexto da Jornada e recomendações metodológicas. Tratar todo conteúdo como proposta até validação humana.'
    ),
    (
      'EXECUTIVE_VALIDATION_PACKAGE',
      'SKPE-JOURNEY-VALIDATION-PACKAGE',
      'Pacote para Validação da Etapa',
      'Pacote executivo disponibilizado automaticamente para apoiar a interação com Gestão, Conselhos e demais instâncias de validação.',
      jsonb_build_object(
        'sections',jsonb_build_array(
          'O que está sendo submetido','Recomendação SPARKs','Pontos de decisão',
          'Alternativas e ressalvas','Decisão institucional','Próximos passos'
        ),
        'proposal_only',true,
        'auto_materialize_on_open',true
      ),
      'Apresentar somente propostas e fatos rastreáveis. Não registrar aprovação sem decisão humana real.'
    ),
    (
      'ACTION_PLAN',
      'SKPE-JOURNEY-ACTIVITY-PLAN',
      'Plano de Trabalho da Atividade',
      'Plano de trabalho disponibilizado automaticamente quando uma Atividade é aberta.',
      jsonb_build_object(
        'sections',jsonb_build_array(
          'Finalidade','Entregas esperadas','Sugestões SPARKs','Ações','Responsabilidades a validar',
          'Prazo proposto','Evidências esperadas','Riscos e dependências'
        ),
        'proposal_only',true,
        'auto_materialize_on_open',true
      ),
      'Pré-preencher como proposta de execução. Responsáveis, prazos e decisões permanecem sujeitos à validação.'
    ),
    (
      'FOLLOW_UP_RECORD',
      'SKPE-JOURNEY-ACTIVITY-FOLLOWUP',
      'Registro de Acompanhamento da Atividade',
      'Registro de acompanhamento disponibilizado automaticamente com a abertura de uma Atividade.',
      jsonb_build_object(
        'sections',jsonb_build_array(
          'Situação inicial','Avanços','Desvios','Decisões','Próximas ações','Evidências associadas'
        ),
        'proposal_only',true,
        'auto_materialize_on_open',true
      ),
      'Usar para acompanhamento contínuo sem substituir a trilha canônica de decisões e evidências.'
    )
) as x(artifact_type_code,template_code,template_name,description,content_structure,instructions)
  on t.module_code='SK-PE'
 and t.artifact_type_code=x.artifact_type_code
 and t.active=true
on conflict (template_code,template_version) do update
set
  template_name=excluded.template_name,
  description=excluded.description,
  content_structure=excluded.content_structure,
  instructions=excluded.instructions,
  active=true,
  updated_at=now(),
  updated_by=auth.uid();

create or replace function public.skpe_journey_item_suggestion_text(
  target_item_code text,
  target_item_name text,
  target_item_description text,
  target_item_type text
)
returns text
language plpgsql
stable
security definer
set search_path=''
as $function$
declare
  v_specific text;
begin
  v_specific:=case target_item_code
    when 'PEM-03.01' then
      E'- Revisar a formulação dos Objetivos de OKR sem tratar o OE como mera cópia do OKR.\n'
      || E'- Garantir Resultados-Chave mensuráveis, com linha de base, unidade, fonte, polaridade, prazo e metas anualizadas.\n'
      || E'- Tratar 2026 como período de transição/linha de base quando não houver evidência suficiente para meta anual plena.\n'
      || E'- Não impor quantidade fixa de OKRs ou KRs; calibrar pela maturidade e necessidade estratégica.\n'
      || E'- Submeter OKRs e KRs à validação humana antes de concluir a etapa.'
    when 'PEM-03.02' then
      E'- Definir indicadores que meçam os resultados estratégicos e os KRs, com fórmula, fonte, periodicidade e responsável pela apuração.\n'
      || E'- Separar linha histórica, linha de base confirmada, benchmark e meta provisória.\n'
      || E'- Anualizar metas no Horizonte 2026–2030 sem confundir anos com Ciclos de Evolução.\n'
      || E'- Não transformar ausência de dado em meta fictícia; quando necessário, propor primeiro a instrumentação da medição.'
    when 'PEM-03.03' then
      E'- Priorizar iniciativas pela contribuição efetiva aos KRs, e não pela quantidade de ações.\n'
      || E'- Alocar cada iniciativa ao Ciclo de Evolução aplicável e manter seu prazo integralmente dentro desse intervalo.\n'
      || E'- Estimar esforço, custo, dependências, riscos e marcos quando materialmente relevantes.\n'
      || E'- Manter iniciativas substituíveis quando surgir alternativa de maior impacto.'
    when 'PEM-03.04' then
      E'- Propor responsabilidades, alçadas e ritos de execução sem atribuir donos que não tenham sido validados.\n'
      || E'- Definir governança para decisões, acompanhamento, escalonamento e replanejamento.\n'
      || E'- Preservar visibilidade por papel e rastreabilidade das decisões.'
    when 'PEM-04.01' then
      E'- Preparar a ativação do Plano de Implementação sem iniciar ações automaticamente.\n'
      || E'- Confirmar prioridades, dependências, capacidade, marcos e prontidão dos responsáveis antes da mobilização.'
    when 'PEM-04.02' then
      E'- Construir comunicação por público, objetivo, mensagem, canal, responsável e evidência de alcance.\n'
      || E'- Adaptar linguagem para dirigentes, conselhos, equipe, cooperados e demais partes interessadas.'
    when 'PEM-04.03' then
      E'- Identificar capacidades necessárias à execução e lacunas de pessoas, processos, tecnologia e gestão.\n'
      || E'- Propor ações de mudança e desenvolvimento proporcionais à maturidade da Organização.'
    when 'PEM-04.04' then
      E'- Conectar riscos da implementação a causa, consequência, controles, tratamento, responsável, indicador e evidência.\n'
      || E'- Priorizar riscos que possam impedir resultados, não apenas listar ocorrências.'
    when 'PEM-05.01' then
      E'- Operar rotina de monitoramento com dados, evidências, confiança e tratamento de atrasos.\n'
      || E'- Diferenciar acompanhamento de resultado, iniciativa e risco.'
    when 'PEM-05.02' then
      E'- Realizar análise crítica de desempenho comparando resultado, meta, causa do desvio e decisão necessária.\n'
      || E'- Evitar explicações sem evidência e registrar replanejamentos.'
    when 'PEM-05.03' then
      E'- Registrar aprendizados, causas, práticas eficazes e oportunidades de melhoria.\n'
      || E'- Converter aprendizado em decisão, padrão de trabalho ou melhoria verificável.'
    when 'PEM-05.04' then
      E'- Propor atualização estratégica somente quando evidências justificarem mudança.\n'
      || E'- Preservar histórico e versionamento das decisões; não reescrever silenciosamente a estratégia aprovada.'
    else
      case target_item_type
        when 'macrophase' then
          E'- Consolidar o propósito da Macrofase, suas entregas, dependências e pontos de validação.\n'
          || E'- Disponibilizar propostas para análise antes de qualquer decisão institucional.'
        when 'activity' then
          E'- Organizar a atividade em ações, entregas, dependências, prazo proposto e evidências esperadas.\n'
          || E'- Manter responsáveis e decisões como proposta até validação.'
        when 'deliverable' then
          E'- Definir claramente o conteúdo esperado, critérios de qualidade e instância de validação.\n'
          || E'- Preservar versionamento e rastreabilidade do entregável.'
        else
          E'- Preparar propostas metodológicas aderentes ao objetivo da etapa.\n'
          || E'- Diferenciar fatos confirmados, hipóteses, recomendações e decisões pendentes.'
      end
  end;

  return v_specific;
end;
$function$;

create or replace function public.skpe_build_journey_artifact_markdown(
  target_item_id uuid,
  target_artifact_role text
)
returns text
language plpgsql
stable
security definer
set search_path=''
as $function$
declare
  v_item public.skpe_journey_items%rowtype;
  v_project public.skpe_projects%rowtype;
  v_suggestions text;
  v_title text;
begin
  select * into v_item
  from public.skpe_journey_items
  where id=target_item_id
    and archived_at is null;

  if v_item.id is null then
    raise exception using errcode='22023',message='Item da Jornada não encontrado.';
  end if;

  select * into v_project
  from public.skpe_projects
  where id=v_item.project_id
    and archived_at is null;

  if v_project.id is null then
    raise exception using errcode='22023',message='Projeto SK-PE ativo não encontrado.';
  end if;

  v_suggestions:=public.skpe_journey_item_suggestion_text(
    v_item.code,v_item.name,v_item.description,v_item.item_type
  );

  v_title:=case target_artifact_role
    when 'validation' then 'Pacote para Validação'
    when 'followup' then 'Registro de Acompanhamento'
    when 'activity_plan' then 'Plano de Trabalho'
    else 'Caderno de Trabalho e Recomendações'
  end;

  return
    '# '||v_title||' — '||v_item.name||E'\n\n'
    ||'**Situação:** Proposta SPARKs para trabalho e validação.  '||E'\n'
    ||'**Jornada:** '||v_item.code||' — '||v_item.name||'  '||E'\n'
    ||'**Projeto:** '||coalesce(v_project.name,'Planejamento Estratégico')||E'\n\n'
    ||'> Este artefato é disponibilizado automaticamente com a abertura da etapa. '
    ||'Seu conteúdo é uma sugestão metodológica e não representa decisão institucional, aprovação, evidência ou aceite da Organização.'
    ||E'\n\n## Por que esta etapa importa\n\n'
    ||coalesce(nullif(trim(v_item.description),''),'Esta etapa organiza uma parte necessária da evolução do Planejamento Estratégico e prepara decisões rastreáveis para as fases seguintes.')
    ||E'\n\n## Sugestões SPARKs\n\n'
    ||v_suggestions
    ||E'\n\n## O que deve ser analisado nesta etapa\n\n'
    ||E'- Aderência ao diagnóstico, às decisões já validadas e ao nível de maturidade da Organização.\n'
    ||E'- Coerência com o Horizonte Estratégico e com os Ciclos de Evolução aplicáveis.\n'
    ||E'- Evidências, dados, premissas e lacunas que sustentam as propostas.\n'
    ||E'- Alternativas melhores que possam substituir ou aperfeiçoar as sugestões iniciais.\n'
    ||E'- Decisões que realmente precisam ser submetidas à Gestão, Conselhos ou outra instância competente.'
    ||E'\n\n## Propostas para discussão\n\n'
    ||E'1. Registrar as recomendações técnicas produzidas pela SPARKs.\n'
    ||E'2. Identificar ajustes do líder do projeto antes da apresentação à Organização.\n'
    ||E'3. Submeter somente os pontos maduros à validação institucional.\n'
    ||E'4. Registrar a decisão real, suas ressalvas e condições, sem fabricar aceite.'
    ||E'\n\n## Evidências e dados necessários\n\n'
    ||E'- Documentos e dados já reconhecidos como fontes da Jornada.\n'
    ||E'- Contraprovas que sustentem linhas de base, metas, riscos ou decisões quando aplicável.\n'
    ||E'- Registro da interação humana que efetivamente ocorrer.'
    ||E'\n\n## Decisão institucional\n\n'
    ||E'**Situação:** Pendente de validação humana quando aplicável.\n\n'
    ||E'**Decisão:** ________________________________________________\n\n'
    ||E'**Ressalvas/condições:** ______________________________________\n\n'
    ||E'**Referência da reunião/ata:** _________________________________\n\n'
    ||E'## Próximos passos\n\n'
    ||E'- Incorporar somente o que tiver sido efetivamente validado.\n'
    ||E'- Preservar as propostas rejeitadas ou substituídas na trilha de auditoria.\n'
    ||E'- Atualizar os artefatos e a Jornada antes de abrir a etapa dependente.';
end;
$function$;

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
  v_role text;
  v_type_code text;
  v_title text;
  v_suffix text;
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
     and not public.can_manage_methodology_artifacts(v_project.organization_id) then
    raise exception using errcode='42501',message='Acesso negado para preparar os artefatos da etapa.';
  end if;

  v_actor:=coalesce(auth.uid(),v_item.updated_by,v_item.created_by);
  v_macrophase_code:=split_part(v_item.code,'.',1);
  if v_item.item_type='macrophase' then
    v_macrophase_code:=v_item.code;
  end if;
  v_phase_code:=case when v_item.item_type='phase' then v_item.code else null end;
  v_stage_code:=case when v_item.item_type in ('activity','deliverable') then v_item.code else null end;

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
      false,
      null,
      null,
      null,
      v_actor
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

  update public.skpe_journey_items
  set metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object(
        'artifactPackageStatus','available',
        'artifactPackageEnsuredAt',timezone('utc',now()),
        'artifactPackageCreatedCount',v_created,
        'artifactPackageExistingCount',v_existing
      ),
      updated_at=timezone('utc',now())
  where id=v_item.id;

  return jsonb_build_object(
    'itemId',v_item.id,
    'itemCode',v_item.code,
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

create or replace function public.skpe_auto_materialize_journey_artifacts_on_open()
returns trigger
language plpgsql
security definer
set search_path=''
as $function$
begin
  if new.archived_at is null
     and new.item_type in ('macrophase','phase','activity','deliverable')
     and new.status='in_progress'
     and old.status is distinct from new.status then
    perform public.ensure_skpe_journey_item_artifacts(
      new.id,
      'Pacote disponibilizado automaticamente na abertura da etapa.'
    );
  end if;

  return new;
end;
$function$;

drop trigger if exists skpe_journey_artifacts_on_open
on public.skpe_journey_items;

create trigger skpe_journey_artifacts_on_open
after update of status
on public.skpe_journey_items
for each row
execute function public.skpe_auto_materialize_journey_artifacts_on_open();

comment on function public.ensure_skpe_journey_item_artifacts(uuid,text) is
'Ensures two usable proposal artifacts with an initial Markdown version whenever a SK-PE Macrophase, Phase, Activity or Deliverable is opened. It never advances Journey status and never fabricates institutional validation.';

comment on function public.skpe_auto_materialize_journey_artifacts_on_open() is
'Automatically makes the working artifact package available when an eligible Journey item transitions to in_progress.';
