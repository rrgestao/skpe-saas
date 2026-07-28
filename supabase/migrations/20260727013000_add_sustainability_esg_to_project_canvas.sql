-- ============================================================
-- SK-PE SaaS
-- Migration: Evolucao do Canvas do Projeto - Sustentabilidade e ESG
-- Versao do modelo: SKPE-PROJECT-BMC-2026.2
-- ============================================================

-- Atualiza canvases existentes para a nova versao do modelo.
update public.skpe_project_canvases
set
  template_code = 'SKPE-PROJECT-BMC-2026.2',
  configuration = coalesce(configuration, '{}'::jsonb) || jsonb_build_object(
    'sustainability_esg_enabled', true,
    'template_previous_code', template_code
  ),
  updated_at = timezone('utc', now())
where archived_at is null
  and template_code = 'SKPE-PROJECT-BMC-2026.1';

-- Reposiciona os blocos posteriores para preservar a ordem recomendada.
update public.skpe_project_canvas_blocks
set display_order = case code
  when 'SUCCESS_METRICS' then 120
  when 'COSTS' then 130
  when 'BENEFITS' then 140
  else display_order
end,
updated_at = timezone('utc', now())
where code in ('SUCCESS_METRICS', 'COSTS', 'BENEFITS');

-- Inclui o novo bloco em todos os canvases existentes, sem duplicacao.
insert into public.skpe_project_canvas_blocks (
  canvas_id,
  code,
  name,
  description,
  guidance,
  display_order,
  grid_area,
  is_mandatory,
  metadata,
  created_by,
  updated_by
)
select
  c.id,
  'SUSTAINABILITY_ESG',
  'Sustentabilidade e ESG',
  'Impactos, riscos, oportunidades, compromissos e resultados ambientais, sociais e de governanca associados ao projeto.',
  'Quais impactos ambientais, sociais e de governanca o projeto gera? Que riscos e oportunidades ESG devem ser tratados? Quais compromissos, indicadores e evidencias demonstrarao valor sustentavel?',
  110,
  'sustainability_esg',
  true,
  jsonb_build_object(
    'dimensions', jsonb_build_array('environmental', 'social', 'governance'),
    'recommended_topics', jsonb_build_array(
      'impactos ambientais',
      'impactos sociais',
      'governanca e integridade',
      'riscos e oportunidades ESG',
      'compromissos e metas',
      'indicadores e evidencias'
    )
  ),
  c.created_by,
  c.updated_by
from public.skpe_project_canvases c
where c.archived_at is null
  and not exists (
    select 1
    from public.skpe_project_canvas_blocks b
    where b.canvas_id = c.id
      and b.code = 'SUSTAINABILITY_ESG'
  );

-- Registra a evolucao do modelo quando houver um usuario de referencia.
insert into public.skpe_project_canvas_history (
  organization_id,
  project_id,
  canvas_id,
  actor_user_id,
  action_code,
  reason,
  previous_data,
  new_data
)
select
  c.organization_id,
  c.project_id,
  c.id,
  coalesce(c.updated_by, c.created_by),
  'project_canvas_template_upgraded',
  'Inclusao do bloco Sustentabilidade e ESG no modelo padrao do Canvas do Projeto.',
  jsonb_build_object('template_code', 'SKPE-PROJECT-BMC-2026.1'),
  jsonb_build_object(
    'template_code', 'SKPE-PROJECT-BMC-2026.2',
    'added_block_code', 'SUSTAINABILITY_ESG'
  )
from public.skpe_project_canvases c
where c.archived_at is null
  and coalesce(c.updated_by, c.created_by) is not null
  and not exists (
    select 1
    from public.skpe_project_canvas_history h
    where h.canvas_id = c.id
      and h.action_code = 'project_canvas_template_upgraded'
      and h.new_data ->> 'template_code' = 'SKPE-PROJECT-BMC-2026.2'
  );

-- Atualiza a funcao de criacao para que novos projetos ja nascam com 14 blocos.
create or replace function public.create_skpe_project_canvas(
  target_project_id uuid,
  canvas_name text default 'Business Model Canvas do Projeto'
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_project public.skpe_projects%rowtype;
  existing_canvas_id uuid;
  new_canvas_id uuid;
begin
  select *
    into target_project
  from public.skpe_projects
  where id = target_project_id
    and archived_at is null;

  if target_project.id is null then
    raise exception 'Projeto estrategico nao encontrado.';
  end if;

  if not public.can_manage_skpe_project_canvas(target_project.organization_id) then
    raise exception
      'Acesso negado: o usuario nao pode criar o Canvas deste projeto.'
      using errcode = '42501';
  end if;

  select id
    into existing_canvas_id
  from public.skpe_project_canvases
  where project_id = target_project_id
    and is_current = true
    and archived_at is null
  limit 1;

  if existing_canvas_id is not null then
    return existing_canvas_id;
  end if;

  insert into public.skpe_project_canvases (
    organization_id,
    project_id,
    code,
    name,
    description,
    status,
    version_number,
    is_current,
    template_code,
    created_by,
    updated_by
  )
  values (
    target_project.organization_id,
    target_project.id,
    'PROJECT-BMC',
    coalesce(nullif(trim(canvas_name), ''), 'Business Model Canvas do Projeto'),
    'Canvas complementar para concepcao, alinhamento, comunicacao e gestao do projeto estrategico.',
    'draft',
    1,
    true,
    'SKPE-PROJECT-BMC-2026.2',
    auth.uid(),
    auth.uid()
  )
  returning id into new_canvas_id;

  insert into public.skpe_project_canvas_blocks (
    canvas_id,
    code,
    name,
    description,
    guidance,
    display_order,
    grid_area,
    is_mandatory,
    created_by,
    updated_by
  )
  select
    new_canvas_id,
    block_data.code,
    block_data.name,
    block_data.description,
    block_data.guidance,
    block_data.display_order,
    block_data.grid_area,
    true,
    auth.uid(),
    auth.uid()
  from (
    values
      ('PURPOSE', 'Proposito e Problema', 'Razao de existir do projeto e problema ou oportunidade que motiva sua realizacao.', 'Que problema relevante sera resolvido? Por que este projeto deve existir agora?', 10, 'purpose'),
      ('STAKEHOLDERS', 'Partes Interessadas', 'Pessoas, grupos e organizacoes que influenciam ou sao impactados pelo projeto.', 'Quem decide, influencia, executa, financia, utiliza ou sera afetado?', 20, 'stakeholders'),
      ('BENEFICIARIES', 'Beneficiarios', 'Publicos que receberao diretamente os resultados e beneficios do projeto.', 'Quem percebe valor ao final? Quais necessidades devem ser atendidas?', 30, 'beneficiaries'),
      ('VALUE_PROPOSITION', 'Proposta de Valor do Projeto', 'Valor central que o projeto entregara aos beneficiarios e demais partes interessadas.', 'Que transformacao concreta sera entregue e por que ela e relevante?', 40, 'value'),
      ('DELIVERABLES', 'Entregas Principais', 'Produtos, resultados e capacidades que deverao ser produzidos.', 'Quais entregas comprovam que o projeto cumpriu seu proposito?', 50, 'deliverables'),
      ('KEY_ACTIVITIES', 'Atividades-Chave', 'Principais frentes de trabalho necessarias para produzir as entregas.', 'O que precisa ser feito para gerar os resultados esperados?', 60, 'activities'),
      ('KEY_RESOURCES', 'Recursos-Chave', 'Pessoas, competencias, tecnologia, informacoes, infraestrutura e recursos financeiros.', 'Quais recursos sao indispensaveis para executar o projeto?', 70, 'resources'),
      ('PARTNERS', 'Parceiros e Apoios', 'Organizacoes e atores externos que ampliam a capacidade de entrega.', 'Quem pode cooperar, fornecer, validar, financiar ou acelerar o projeto?', 80, 'partners'),
      ('GOVERNANCE', 'Governanca e Responsabilidades', 'Estrutura de patrocinio, decisao, coordenacao, validacao e prestacao de contas.', 'Quem patrocina, decide, coordena, executa e valida?', 90, 'governance'),
      ('RISKS', 'Riscos e Restricoes', 'Incertezas, premissas, dependencias e limitacoes relevantes.', 'O que pode impedir ou comprometer o sucesso do projeto?', 100, 'risks'),
      ('SUSTAINABILITY_ESG', 'Sustentabilidade e ESG', 'Impactos, riscos, oportunidades, compromissos e resultados ambientais, sociais e de governanca associados ao projeto.', 'Quais impactos ambientais, sociais e de governanca o projeto gera? Que riscos e oportunidades ESG devem ser tratados? Quais compromissos, indicadores e evidencias demonstrarao valor sustentavel?', 110, 'sustainability_esg'),
      ('SUCCESS_METRICS', 'Indicadores de Sucesso', 'Medidas de desempenho, resultado, impacto e valor gerado.', 'Como saberemos, com evidencias, que o projeto foi bem-sucedido?', 120, 'metrics'),
      ('COSTS', 'Custos e Investimentos', 'Recursos financeiros e esforcos necessarios para viabilizar o projeto.', 'Quanto custara e quais investimentos serao necessarios?', 130, 'costs'),
      ('BENEFITS', 'Beneficios Esperados', 'Ganhos financeiros, operacionais, sociais, institucionais e estrategicos.', 'Que beneficios mensuraveis e nao mensuraveis serao gerados?', 140, 'benefits')
  ) as block_data(
    code,
    name,
    description,
    guidance,
    display_order,
    grid_area
  );

  insert into public.skpe_project_canvas_history (
    organization_id,
    project_id,
    canvas_id,
    actor_user_id,
    action_code,
    reason,
    new_data
  )
  values (
    target_project.organization_id,
    target_project.id,
    new_canvas_id,
    auth.uid(),
    'project_canvas_created',
    'Criacao do Canvas padrao do projeto.',
    jsonb_build_object(
      'template_code', 'SKPE-PROJECT-BMC-2026.2',
      'name', coalesce(nullif(trim(canvas_name), ''), 'Business Model Canvas do Projeto')
    )
  );

  return new_canvas_id;
end;
$$;


-- Reforca as permissoes de execucao da funcao atualizada.
revoke all on function public.create_skpe_project_canvas(uuid, text)
from public, anon;

grant execute on function public.create_skpe_project_canvas(uuid, text)
to authenticated, service_role;

comment on function public.create_skpe_project_canvas(uuid, text) is
  'Cria o Canvas padrao do projeto com 14 blocos, incluindo Sustentabilidade e ESG.';
