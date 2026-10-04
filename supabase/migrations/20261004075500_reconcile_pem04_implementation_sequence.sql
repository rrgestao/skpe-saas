-- Reconcile PEM-04 as implementation/mobilization of the approved strategic deployment.
-- This migration changes methodology contracts/dependencies only.
-- It does not start, complete, validate or approve any journey item.

update public.skpe_methodology_template_items
set
  name=case code
    when 'PEM-04' then 'Implementação e Mobilização'
    when 'PEM-04.01' then 'Ativação do Plano de Implementação'
    when 'PEM-04.02' then 'Comunicação e Mobilização'
    when 'PEM-04.03' then 'Capacidades e Gestão da Mudança'
    when 'PEM-04.04' then 'Gestão de Riscos da Implementação'
    when 'PEM-04.GATE' then 'Validação da Macrofase 4'
    else name
  end,
  metadata=jsonb_set(
    jsonb_set(
      coalesce(metadata,'{}'::jsonb),
      '{completion_criteria}',
      case code
        when 'PEM-04' then '["Portfólio estratégico aprovado ativado para execução","Comunicação e mobilização preparadas","Capacidades e mudanças críticas tratadas","Riscos de implementação sob gestão"]'::jsonb
        when 'PEM-04.01' then '["Iniciativas selecionadas do portfólio aprovado possuem condições de ativação para execução sem redefinir o portfólio"]'::jsonb
        when 'PEM-04.02' then '["Plano de comunicação e mobilização da implementação aprovado"]'::jsonb
        when 'PEM-04.03' then '["Lacunas de capacidade e necessidades de gestão da mudança avaliadas e tratadas"]'::jsonb
        when 'PEM-04.04' then '["Riscos de implementação avaliados, responsáveis definidos e respostas críticas estabelecidas"]'::jsonb
        when 'PEM-04.GATE' then '["Aceite executivo da Implementação e Mobilização registrado"]'::jsonb
      end,
      true
    ),
    '{unblock_dependencies}',
    case code
      when 'PEM-04' then '[{"code":"PEM-03.GATE","required_status":"completed"}]'::jsonb
      when 'PEM-04.01' then '[{"code":"PEM-03.GATE","required_status":"completed"}]'::jsonb
      when 'PEM-04.02' then '[{"code":"PEM-04.01","required_status":"completed"}]'::jsonb
      when 'PEM-04.03' then '[{"code":"PEM-04.02","required_status":"completed"}]'::jsonb
      when 'PEM-04.04' then '[{"code":"PEM-04.03","required_status":"completed"}]'::jsonb
      when 'PEM-04.GATE' then '[{"code":"PEM-04.04","required_status":"completed"}]'::jsonb
    end,
    true
  )
where code in ('PEM-04','PEM-04.01','PEM-04.02','PEM-04.03','PEM-04.04','PEM-04.GATE');

update public.skpe_journey_items
set
  name=case code
    when 'PEM-04' then 'Implementação e Mobilização'
    when 'PEM-04.01' then 'Ativação do Plano de Implementação'
    when 'PEM-04.02' then 'Comunicação e Mobilização'
    when 'PEM-04.03' then 'Capacidades e Gestão da Mudança'
    when 'PEM-04.04' then 'Gestão de Riscos da Implementação'
    when 'PEM-04.GATE' then 'Validação da Macrofase 4'
    else name
  end,
  metadata=jsonb_set(
    jsonb_set(
      coalesce(metadata,'{}'::jsonb),
      '{completion_criteria}',
      case code
        when 'PEM-04' then '["Portfólio estratégico aprovado ativado para execução","Comunicação e mobilização preparadas","Capacidades e mudanças críticas tratadas","Riscos de implementação sob gestão"]'::jsonb
        when 'PEM-04.01' then '["Iniciativas selecionadas do portfólio aprovado possuem condições de ativação para execução sem redefinir o portfólio"]'::jsonb
        when 'PEM-04.02' then '["Plano de comunicação e mobilização da implementação aprovado"]'::jsonb
        when 'PEM-04.03' then '["Lacunas de capacidade e necessidades de gestão da mudança avaliadas e tratadas"]'::jsonb
        when 'PEM-04.04' then '["Riscos de implementação avaliados, responsáveis definidos e respostas críticas estabelecidas"]'::jsonb
        when 'PEM-04.GATE' then '["Aceite executivo da Implementação e Mobilização registrado"]'::jsonb
      end,
      true
    ),
    '{unblock_dependencies}',
    case code
      when 'PEM-04' then '[{"code":"PEM-03.GATE","required_status":"completed"}]'::jsonb
      when 'PEM-04.01' then '[{"code":"PEM-03.GATE","required_status":"completed"}]'::jsonb
      when 'PEM-04.02' then '[{"code":"PEM-04.01","required_status":"completed"}]'::jsonb
      when 'PEM-04.03' then '[{"code":"PEM-04.02","required_status":"completed"}]'::jsonb
      when 'PEM-04.04' then '[{"code":"PEM-04.03","required_status":"completed"}]'::jsonb
      when 'PEM-04.GATE' then '[{"code":"PEM-04.04","required_status":"completed"}]'::jsonb
    end,
    true
  ),
  updated_at=timezone('utc',now())
where archived_at is null
  and code in ('PEM-04','PEM-04.01','PEM-04.02','PEM-04.03','PEM-04.04','PEM-04.GATE');

comment on function public.skpe_assert_journey_item_dependencies() is
'Fail-closed guard for SK-PE journey transitions. Dependencies are stored canonically in metadata.unblock_dependencies and apply across PEM-02, PEM-03, PEM-04 and future stages.';
