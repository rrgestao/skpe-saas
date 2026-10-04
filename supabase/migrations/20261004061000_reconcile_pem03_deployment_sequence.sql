-- Reconcile PEM-03 with the approved SK-PE methodology.
-- PEM-02 owns the strategic map; PEM-03 owns tactical/strategic deployment.
-- This migration changes labels, criteria and dependencies only; it does not advance status.

update public.skpe_methodology_template_items
set
  name = case code
    when 'PEM-03' then 'Desdobramento Estratégico'
    when 'PEM-03.01' then 'Desdobramento em OKRs'
    when 'PEM-03.02' then 'Indicadores e Metas'
    when 'PEM-03.03' then 'Iniciativas e Projetos Estratégicos'
    when 'PEM-03.04' then 'Responsabilidades e Governança da Execução'
    when 'PEM-03.GATE' then 'Validação da Macrofase 3'
    else name
  end,
  completion_criteria = case code
    when 'PEM-03' then jsonb_build_array(
      'OKRs aprovados e vinculados aos Objetivos Estratégicos',
      'Indicadores e metas aprovados',
      'Portfólio de iniciativas priorizado',
      'Responsabilidades e governança da execução definidas'
    )
    when 'PEM-03.01' then jsonb_build_array(
      'OKRs aprovados e vinculados aos Objetivos Estratégicos'
    )
    when 'PEM-03.02' then jsonb_build_array(
      'Indicadores e metas aprovados com fonte, fórmula, linha de base e critério de apuração'
    )
    when 'PEM-03.03' then jsonb_build_array(
      'Portfólio de iniciativas e projetos estratégicos priorizado e vinculado aos Objetivos'
    )
    when 'PEM-03.04' then jsonb_build_array(
      'Responsáveis, papéis, fóruns e cadência de governança da execução aprovados'
    )
    when 'PEM-03.GATE' then jsonb_build_array(
      'Aceite executivo do Desdobramento Estratégico registrado'
    )
    else completion_criteria
  end,
  metadata = jsonb_set(
    coalesce(metadata,'{}'::jsonb),
    '{unblock_dependencies}',
    case code
      when 'PEM-03' then '[{"code":"PEM-02.GATE","required_status":"completed"}]'::jsonb
      when 'PEM-03.01' then '[{"code":"PEM-02.GATE","required_status":"completed"}]'::jsonb
      when 'PEM-03.02' then '[{"code":"PEM-03.01","required_status":"completed"}]'::jsonb
      when 'PEM-03.03' then '[{"code":"PEM-03.02","required_status":"completed"}]'::jsonb
      when 'PEM-03.04' then '[{"code":"PEM-03.03","required_status":"completed"}]'::jsonb
      when 'PEM-03.GATE' then '[{"code":"PEM-03.04","required_status":"completed"}]'::jsonb
      else coalesce(metadata->'unblock_dependencies','[]'::jsonb)
    end,
    true
  )
where code in ('PEM-03','PEM-03.01','PEM-03.02','PEM-03.03','PEM-03.04','PEM-03.GATE');

update public.skpe_journey_items
set
  name = case code
    when 'PEM-03' then 'Desdobramento Estratégico'
    when 'PEM-03.01' then 'Desdobramento em OKRs'
    when 'PEM-03.02' then 'Indicadores e Metas'
    when 'PEM-03.03' then 'Iniciativas e Projetos Estratégicos'
    when 'PEM-03.04' then 'Responsabilidades e Governança da Execução'
    when 'PEM-03.GATE' then 'Validação da Macrofase 3'
    else name
  end,
  metadata = jsonb_set(
    jsonb_set(
      coalesce(metadata,'{}'::jsonb),
      '{completion_criteria}',
      case code
        when 'PEM-03' then jsonb_build_array(
          'OKRs aprovados e vinculados aos Objetivos Estratégicos',
          'Indicadores e metas aprovados',
          'Portfólio de iniciativas priorizado',
          'Responsabilidades e governança da execução definidas'
        )
        when 'PEM-03.01' then jsonb_build_array(
          'OKRs aprovados e vinculados aos Objetivos Estratégicos'
        )
        when 'PEM-03.02' then jsonb_build_array(
          'Indicadores e metas aprovados com fonte, fórmula, linha de base e critério de apuração'
        )
        when 'PEM-03.03' then jsonb_build_array(
          'Portfólio de iniciativas e projetos estratégicos priorizado e vinculado aos Objetivos'
        )
        when 'PEM-03.04' then jsonb_build_array(
          'Responsáveis, papéis, fóruns e cadência de governança da execução aprovados'
        )
        when 'PEM-03.GATE' then jsonb_build_array(
          'Aceite executivo do Desdobramento Estratégico registrado'
        )
        else coalesce(metadata->'completion_criteria','[]'::jsonb)
      end,
      true
    ),
    '{unblock_dependencies}',
    case code
      when 'PEM-03' then '[{"code":"PEM-02.GATE","required_status":"completed"}]'::jsonb
      when 'PEM-03.01' then '[{"code":"PEM-02.GATE","required_status":"completed"}]'::jsonb
      when 'PEM-03.02' then '[{"code":"PEM-03.01","required_status":"completed"}]'::jsonb
      when 'PEM-03.03' then '[{"code":"PEM-03.02","required_status":"completed"}]'::jsonb
      when 'PEM-03.04' then '[{"code":"PEM-03.03","required_status":"completed"}]'::jsonb
      when 'PEM-03.GATE' then '[{"code":"PEM-03.04","required_status":"completed"}]'::jsonb
      else coalesce(metadata->'unblock_dependencies','[]'::jsonb)
    end,
    true
  ),
  updated_at = timezone('utc',now())
where archived_at is null
  and code in ('PEM-03','PEM-03.01','PEM-03.02','PEM-03.03','PEM-03.04','PEM-03.GATE');

comment on function public.skpe_assert_journey_item_dependencies() is
'Fail-closed guard for sequential SK-PE journey transitions. PEM-03 is unlocked only after PEM-02.GATE and then follows OKRs -> Indicators/Targets -> Initiatives -> Execution Governance -> Gate.';
