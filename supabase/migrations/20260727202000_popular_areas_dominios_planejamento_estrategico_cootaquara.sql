-- ============================================================
-- Plataforma SPARKs / COOTAQUARA
-- Catálogo inicial de áreas e domínios organizacionais
-- Planejamento Estratégico
-- Data: 2026-07-27
-- Idempotente: pode ser executado mais de uma vez.
-- ============================================================

begin;

do $$
declare
  v_org_id uuid;
  v_org_count integer;
  v_domain_id uuid;
begin
  select count(*)
    into v_org_count
  from public.organizations o
  where upper(coalesce(o.code, '')) = 'COOTAQUARA'
     or upper(coalesce(o.trade_name, '')) = 'COOTAQUARA'
     or upper(coalesce(o.legal_name, '')) like '%COOTAQUARA%';

  if v_org_count = 0 then
    raise exception 'Organização COOTAQUARA não encontrada.';
  end if;

  select o.id
    into v_org_id
  from public.organizations o
  where upper(coalesce(o.code, '')) = 'COOTAQUARA'
     or upper(coalesce(o.trade_name, '')) = 'COOTAQUARA'
     or upper(coalesce(o.legal_name, '')) like '%COOTAQUARA%'
  order by
    case
      when upper(coalesce(o.code, '')) = 'COOTAQUARA' then 1
      when upper(coalesce(o.trade_name, '')) = 'COOTAQUARA' then 2
      else 3
    end,
    o.created_at
  limit 1;

  insert into public.sparks_domains (
    code,
    name,
    description,
    scope_type,
    module_code,
    organization_id,
    allow_organization_extension,
    protected,
    active,
    metadata
  )
  values (
    'ORGANIZATIONAL_AREA',
    'Áreas e domínios organizacionais',
    'Estrutura inicial de áreas utilizada na governança e na gestão do Planejamento Estratégico da COOTAQUARA.',
    'organization',
    null,
    v_org_id,
    true,
    false,
    true,
    jsonb_build_object(
      'source', 'initial_strategic_planning_catalog',
      'organization', 'COOTAQUARA',
      'created_for', 'SK-PE'
    )
  )
  on conflict (organization_id, code)
    where scope_type = 'organization'
  do update set
    name = excluded.name,
    description = excluded.description,
    allow_organization_extension = true,
    active = true,
    metadata = public.sparks_domains.metadata || excluded.metadata,
    updated_at = timezone('utc', now());

  select d.id
    into v_domain_id
  from public.sparks_domains d
  where d.organization_id = v_org_id
    and d.scope_type = 'organization'
    and d.code = 'ORGANIZATIONAL_AREA'
  limit 1;

  insert into public.sparks_domain_values (
    domain_id, code, name, description, display_order,
    parent_value_id, protected, active, metadata
  )
  values
    (v_domain_id, 'GOVERNANCA_DIRECAO', 'Governança e Direção', 'Instâncias de patrocínio, orientação, deliberação, aprovação e validação estratégica.', 10, null, false, true, '{"area_type":"governance","planning_scope":true}'::jsonb),
    (v_domain_id, 'PLANEJAMENTO_ESTRATEGICO', 'Planejamento Estratégico', 'Coordenação do processo de formulação, desdobramento, monitoramento e revisão da estratégia.', 20, null, false, true, '{"area_type":"management","planning_scope":true}'::jsonb),
    (v_domain_id, 'PROJETOS_ESTRATEGICOS', 'Projetos Estratégicos', 'Gestão de iniciativas, projetos, entregas e ações vinculadas à execução da estratégia.', 30, null, false, true, '{"area_type":"project","planning_scope":true}'::jsonb),
    (v_domain_id, 'GESTAO_DOCUMENTAL', 'Gestão Documental', 'Gestão dos documentos, versões, registros e evidências da jornada estratégica.', 40, null, false, true, '{"area_type":"support","planning_scope":true}'::jsonb),
    (v_domain_id, 'COMUNICACAO', 'Comunicação', 'Comunicação institucional, mobilização, engajamento e disseminação da estratégia.', 50, null, false, true, '{"area_type":"support","planning_scope":true}'::jsonb),
    (v_domain_id, 'RISCOS_CONTROLES', 'Riscos e Controles', 'Identificação, avaliação, tratamento, controle e verificação dos riscos estratégicos.', 60, null, false, true, '{"area_type":"control","planning_scope":true}'::jsonb),
    (v_domain_id, 'ADMIN_FINANCEIRO', 'Administrativo-Financeiro', 'Orçamento, recursos, investimentos, custos e apoio administrativo à execução estratégica.', 70, null, false, true, '{"area_type":"support","planning_scope":true}'::jsonb),
    (v_domain_id, 'DADOS_INFORMACOES', 'Dados e Informações', 'Qualidade, disponibilidade, integração e rastreabilidade dos dados estratégicos.', 80, null, false, true, '{"area_type":"support","planning_scope":true}'::jsonb),
    (v_domain_id, 'COMERCIAL_MERCADO', 'Comercial e Mercado', 'Relacionamento com clientes, desenvolvimento de mercado, vendas e posicionamento comercial.', 90, null, false, true, '{"area_type":"business","planning_scope":true}'::jsonb),
    (v_domain_id, 'PRODUCAO_OPERACOES', 'Produção e Operações', 'Produção, beneficiamento, qualidade, capacidade operacional e execução do negócio.', 100, null, false, true, '{"area_type":"operations","planning_scope":true}'::jsonb),
    (v_domain_id, 'COOPERADOS', 'Relacionamento com Cooperados', 'Participação, relacionamento, comunicação e desenvolvimento dos cooperados.', 110, null, false, true, '{"area_type":"membership","planning_scope":true}'::jsonb),
    (v_domain_id, 'PESSOAS_DESENVOLVIMENTO', 'Pessoas e Desenvolvimento', 'Gestão de pessoas, competências, aprendizagem e desenvolvimento organizacional.', 120, null, false, true, '{"area_type":"people","planning_scope":true}'::jsonb),
    (v_domain_id, 'TECNOLOGIA_INOVACAO', 'Tecnologia e Inovação', 'Soluções digitais, tecnologia, inovação e melhoria de processos.', 130, null, false, true, '{"area_type":"technology","planning_scope":true}'::jsonb),
    (v_domain_id, 'SUSTENTABILIDADE_ESG', 'Sustentabilidade e ESG', 'Aspectos ambientais, sociais, de governança e desenvolvimento sustentável.', 140, null, false, true, '{"area_type":"sustainability","planning_scope":true}'::jsonb)
  on conflict (domain_id, code)
  do update set
    name = excluded.name,
    description = excluded.description,
    display_order = excluded.display_order,
    protected = false,
    active = true,
    metadata = public.sparks_domain_values.metadata || excluded.metadata,
    updated_at = timezone('utc', now());

  -- Registra relações hierárquicas iniciais sem impedir futuras alterações.
  update public.sparks_domain_values child
  set parent_value_id = parent.id,
      updated_at = timezone('utc', now())
  from public.sparks_domain_values parent
  where child.domain_id = v_domain_id
    and parent.domain_id = v_domain_id
    and child.code in (
      'PLANEJAMENTO_ESTRATEGICO',
      'RISCOS_CONTROLES',
      'SUSTENTABILIDADE_ESG'
    )
    and parent.code = 'GOVERNANCA_DIRECAO';

  update public.sparks_domain_values child
  set parent_value_id = parent.id,
      updated_at = timezone('utc', now())
  from public.sparks_domain_values parent
  where child.domain_id = v_domain_id
    and parent.domain_id = v_domain_id
    and child.code in (
      'PROJETOS_ESTRATEGICOS',
      'GESTAO_DOCUMENTAL',
      'COMUNICACAO',
      'DADOS_INFORMACOES'
    )
    and parent.code = 'PLANEJAMENTO_ESTRATEGICO';

  raise notice 'Catálogo de áreas da COOTAQUARA criado/atualizado com sucesso.';
end
$$;

commit;

-- ============================================================
-- CONFERÊNCIA
-- ============================================================
select
  dv.code,
  dv.name,
  parent.name as area_superior,
  dv.description,
  dv.active,
  dv.display_order
from public.sparks_domain_values dv
join public.sparks_domains d
  on d.id = dv.domain_id
left join public.sparks_domain_values parent
  on parent.id = dv.parent_value_id
where d.code = 'ORGANIZATIONAL_AREA'
  and d.scope_type = 'organization'
  and d.organization_id = (
    select o.id
    from public.organizations o
    where upper(coalesce(o.code, '')) = 'COOTAQUARA'
       or upper(coalesce(o.trade_name, '')) = 'COOTAQUARA'
       or upper(coalesce(o.legal_name, '')) like '%COOTAQUARA%'
    order by
      case
        when upper(coalesce(o.code, '')) = 'COOTAQUARA' then 1
        when upper(coalesce(o.trade_name, '')) = 'COOTAQUARA' then 2
        else 3
      end,
      o.created_at
    limit 1
  )
order by dv.display_order, dv.name;
