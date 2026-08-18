-- GATE-17-B.4C.3 — Temporal Semantic Correction
--
-- Continuidade canônica:
-- SK-PE-CONT-01 — Continuidade Segura e Fechamento Controlado do SPARKs PE.
--
-- CONTRATO TEMPORAL CANÔNICO
--
-- 1. Strategic Period:
--    período coberto pela estratégia.
--
-- 2. Governance Effective Period:
--    vigência institucional da versão aprovada.
--
-- 3. Execution Period:
--    datas previstas e realizadas de execução.
--
-- 4. Measurement / Reference Period:
--    janela de apuração de KPI, meta, baseline ou resultado.
--
-- Esses conceitos não podem ser inferidos automaticamente uns dos outros.
--
-- valid_from / valid_until permanecem como atributos de vigência institucional.
-- Eles NÃO determinam o período do Horizonte Estratégico.


create or replace function public.get_skpe_strategic_horizon_period(
  target_project_id uuid
)
returns table (
  strategic_horizon_id uuid,
  period_start date,
  period_end date,
  resolution_source text
)
language plpgsql
stable
set search_path = ''
as $function$
declare
  v_project public.skpe_projects%rowtype;
  v_horizon public.skpe_strategic_horizons%rowtype;
begin

  select *
  into v_project
  from public.skpe_projects
  where id = target_project_id
    and archived_at is null;

  if v_project.id is null then
    raise exception
      'Projeto SK-PE não encontrado.'
      using errcode = '22023';
  end if;


  select *
  into v_horizon
  from public.skpe_strategic_horizons
  where project_id = target_project_id
    and is_current = true
    and governance_status in (
      'approved',
      'historical_recognized'
    )
  order by version_number desc
  limit 1;


  if v_horizon.id is null then

    strategic_horizon_id := null;
    period_start := null;
    period_end := null;
    resolution_source := 'strategic_horizon_not_decided';

    return next;
    return;

  end if;


  strategic_horizon_id := v_horizon.id;

  period_start :=
    make_date(
      v_horizon.horizon_start_year,
      1,
      1
    );

  period_end :=
    make_date(
      v_horizon.horizon_end_year,
      12,
      31
    );

  resolution_source :=
    case v_horizon.governance_status
      when 'historical_recognized'
        then 'historical_recognized_horizon'
      else
        'canonical_strategic_horizon'
    end;

  return next;

end;
$function$;


comment on function
  public.get_skpe_strategic_horizon_period(uuid)
is
'Retorna exclusivamente o período estratégico do Horizonte SK-PE. '
'Deriva início e fim de horizon_start_year e horizon_end_year. '
'Não utiliza valid_from, valid_until, vigência da Formulação, datas de execução '
'ou períodos de apuração como substitutos do Horizonte Estratégico.';


revoke all
on function public.get_skpe_strategic_horizon_period(uuid)
from public, anon;

grant execute
on function public.get_skpe_strategic_horizon_period(uuid)
to authenticated, service_role;


-- ============================================================
-- ADAPTADOR BROWNFIELD
-- ============================================================
--
-- A assinatura anterior é preservada para compatibilidade.
--
-- target_formulation_id continua sendo validado quando informado,
-- mas nenhuma data da Formulação participa da resolução temporal
-- do Horizonte Estratégico.


create or replace function public.get_skpe_effective_strategic_horizon_period(
  target_project_id uuid,
  target_formulation_id uuid default null
)
returns table (
  strategic_horizon_id uuid,
  period_start date,
  period_end date,
  resolution_source text
)
language plpgsql
stable
set search_path = ''
as $function$
declare
  v_formulation_id uuid;
begin

  if target_formulation_id is not null then

    select f.id
    into v_formulation_id
    from public.skpe_strategic_formulations f
    where f.id = target_formulation_id
      and f.project_id = target_project_id;

    if v_formulation_id is null then
      raise exception
        'Formulação Estratégica não encontrada neste projeto.'
        using errcode = '22023';
    end if;

  end if;


  return query
  select
    h.strategic_horizon_id,
    h.period_start,
    h.period_end,
    h.resolution_source
  from public.get_skpe_strategic_horizon_period(
    target_project_id
  ) h;

end;
$function$;


comment on function
  public.get_skpe_effective_strategic_horizon_period(uuid, uuid)
is
'Adaptador brownfield do contrato anterior. '
'O parâmetro target_formulation_id é preservado somente para compatibilidade e validação. '
'O período estratégico é delegado integralmente a '
'get_skpe_strategic_horizon_period(uuid). '
'valid_from e valid_until da Formulação ou do Horizonte não alteram o período estratégico.';


revoke all
on function
  public.get_skpe_effective_strategic_horizon_period(uuid, uuid)
from public, anon;

grant execute
on function
  public.get_skpe_effective_strategic_horizon_period(uuid, uuid)
to authenticated, service_role;
