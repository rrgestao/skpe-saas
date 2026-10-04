-- Reconcile PEM-05 as operation, review, learning and governed strategic update.
-- This migration changes methodology contracts/dependencies only.
-- It does not start, complete, validate or approve any journey item.

update public.skpe_methodology_template_items
set
  name=case code
    when 'PEM-05' then 'Monitoramento e Aprendizado'
    when 'PEM-05.01' then 'Operação da Rotina de Monitoramento'
    when 'PEM-05.02' then 'Análise Crítica de Desempenho'
    when 'PEM-05.03' then 'Aprendizado e Melhoria'
    when 'PEM-05.04' then 'Atualização Estratégica Governada'
    when 'PEM-05.GATE' then 'Ciclo de Revisão Estratégica'
    else name
  end,
  metadata=jsonb_set(
    jsonb_set(
      coalesce(metadata,'{}'::jsonb),
      '{completion_criteria}',
      case code
        when 'PEM-05' then '["Rotina de monitoramento operada","Análise crítica realizada","Aprendizados e melhorias registrados","Atualizações estratégicas governadas quando aplicáveis"]'::jsonb
        when 'PEM-05.01' then '["Ao menos um ciclo governado de monitoramento operado conforme o pacote FE-08 validado, com dados e evidências suficientes para revisão"]'::jsonb
        when 'PEM-05.02' then '["Análise crítica de desempenho realizada sobre ciclo de monitoramento governado, com conclusões e decisões rastreáveis"]'::jsonb
        when 'PEM-05.03' then '["Aprendizados, causas, melhorias e ações decorrentes da análise crítica registrados e responsabilizados"]'::jsonb
        when 'PEM-05.04' then '["Necessidade de atualização estratégica avaliada; alterações, quando necessárias, formalizadas por mecanismo governado e sem edição silenciosa da estratégia aprovada"]'::jsonb
        when 'PEM-05.GATE' then '["Ciclo de Revisão Estratégica ratificado institucionalmente"]'::jsonb
      end,
      true
    ),
    '{unblock_dependencies}',
    case code
      when 'PEM-05' then '[{"code":"PEM-04.GATE","required_status":"completed"}]'::jsonb
      when 'PEM-05.01' then '[{"code":"PEM-04.GATE","required_status":"completed"}]'::jsonb
      when 'PEM-05.02' then '[{"code":"PEM-05.01","required_status":"completed"}]'::jsonb
      when 'PEM-05.03' then '[{"code":"PEM-05.02","required_status":"completed"}]'::jsonb
      when 'PEM-05.04' then '[{"code":"PEM-05.03","required_status":"completed"}]'::jsonb
      when 'PEM-05.GATE' then '[{"code":"PEM-05.04","required_status":"completed"}]'::jsonb
    end,
    true
  )
where code in ('PEM-05','PEM-05.01','PEM-05.02','PEM-05.03','PEM-05.04','PEM-05.GATE');

update public.skpe_journey_items
set
  name=case code
    when 'PEM-05' then 'Monitoramento e Aprendizado'
    when 'PEM-05.01' then 'Operação da Rotina de Monitoramento'
    when 'PEM-05.02' then 'Análise Crítica de Desempenho'
    when 'PEM-05.03' then 'Aprendizado e Melhoria'
    when 'PEM-05.04' then 'Atualização Estratégica Governada'
    when 'PEM-05.GATE' then 'Ciclo de Revisão Estratégica'
    else name
  end,
  metadata=jsonb_set(
    jsonb_set(
      coalesce(metadata,'{}'::jsonb),
      '{completion_criteria}',
      case code
        when 'PEM-05' then '["Rotina de monitoramento operada","Análise crítica realizada","Aprendizados e melhorias registrados","Atualizações estratégicas governadas quando aplicáveis"]'::jsonb
        when 'PEM-05.01' then '["Ao menos um ciclo governado de monitoramento operado conforme o pacote FE-08 validado, com dados e evidências suficientes para revisão"]'::jsonb
        when 'PEM-05.02' then '["Análise crítica de desempenho realizada sobre ciclo de monitoramento governado, com conclusões e decisões rastreáveis"]'::jsonb
        when 'PEM-05.03' then '["Aprendizados, causas, melhorias e ações decorrentes da análise crítica registrados e responsabilizados"]'::jsonb
        when 'PEM-05.04' then '["Necessidade de atualização estratégica avaliada; alterações, quando necessárias, formalizadas por mecanismo governado e sem edição silenciosa da estratégia aprovada"]'::jsonb
        when 'PEM-05.GATE' then '["Ciclo de Revisão Estratégica ratificado institucionalmente"]'::jsonb
      end,
      true
    ),
    '{unblock_dependencies}',
    case code
      when 'PEM-05' then '[{"code":"PEM-04.GATE","required_status":"completed"}]'::jsonb
      when 'PEM-05.01' then '[{"code":"PEM-04.GATE","required_status":"completed"}]'::jsonb
      when 'PEM-05.02' then '[{"code":"PEM-05.01","required_status":"completed"}]'::jsonb
      when 'PEM-05.03' then '[{"code":"PEM-05.02","required_status":"completed"}]'::jsonb
      when 'PEM-05.04' then '[{"code":"PEM-05.03","required_status":"completed"}]'::jsonb
      when 'PEM-05.GATE' then '[{"code":"PEM-05.04","required_status":"completed"}]'::jsonb
    end,
    true
  ),
  updated_at=timezone('utc',now())
where archived_at is null
  and code in ('PEM-05','PEM-05.01','PEM-05.02','PEM-05.03','PEM-05.04','PEM-05.GATE');

comment on function public.skpe_assert_journey_item_dependencies() is
'Fail-closed guard for SK-PE journey transitions. Dependencies are stored canonically in metadata.unblock_dependencies and apply across PEM-02 through PEM-05 and future stages.';
