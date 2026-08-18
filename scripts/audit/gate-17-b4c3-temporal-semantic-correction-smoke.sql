-- GATE-17-B.4C.3 — Temporal Semantic Correction Smoke

do $smoke$
declare
  v_project_id uuid;

  v_horizon_start_year integer;
  v_horizon_end_year integer;
  v_governance_valid_from date;

  v_period_start date;
  v_period_end date;
  v_resolution_source text;

  v_legacy_period_start date;
  v_legacy_period_end date;
  v_legacy_resolution_source text;

  v_formulation_id uuid;

  v_canonical_definition text;
  v_legacy_definition text;

begin

  -- ==========================================================
  -- 1. CONTROLE POSITIVO — COOTAQUARA
  -- ==========================================================

  select p.id
  into v_project_id
  from public.skpe_projects p
  where p.code = 'PE-COOTAQUARA-2026'
    and p.archived_at is null
  order by p.created_at desc
  limit 1;

  if v_project_id is null then
    raise exception
      'SMOKE FAIL: projeto PE-COOTAQUARA-2026 não encontrado.';
  end if;


  -- ==========================================================
  -- 2. HORIZONTE CANÔNICO
  -- ==========================================================

  select
    h.horizon_start_year,
    h.horizon_end_year,
    h.valid_from
  into
    v_horizon_start_year,
    v_horizon_end_year,
    v_governance_valid_from
  from public.skpe_strategic_horizons h
  where h.project_id = v_project_id
    and h.is_current = true
    and h.governance_status in (
      'approved',
      'historical_recognized'
    )
  order by h.version_number desc
  limit 1;

  if v_horizon_start_year is null
     or v_horizon_end_year is null then
    raise exception
      'SMOKE FAIL: Horizonte Estratégico canônico não encontrado.';
  end if;


  -- ==========================================================
  -- 3. FUNÇÃO CANÔNICA
  -- ==========================================================

  select
    x.period_start,
    x.period_end,
    x.resolution_source
  into
    v_period_start,
    v_period_end,
    v_resolution_source
  from public.get_skpe_strategic_horizon_period(
    v_project_id
  ) x;


  if v_period_start
       is distinct from
       make_date(v_horizon_start_year, 1, 1) then

    raise exception
      'SMOKE FAIL: início estratégico incorreto. Obtido %, esperado %.',
      v_period_start,
      make_date(v_horizon_start_year, 1, 1);

  end if;


  if v_period_end
       is distinct from
       make_date(v_horizon_end_year, 12, 31) then

    raise exception
      'SMOKE FAIL: fim estratégico incorreto. Obtido %, esperado %.',
      v_period_end,
      make_date(v_horizon_end_year, 12, 31);

  end if;


  -- ==========================================================
  -- 4. ESTRATÉGIA != VIGÊNCIA
  -- ==========================================================

  if v_governance_valid_from is not null
     and v_governance_valid_from
         <> make_date(v_horizon_start_year, 1, 1)
     and v_period_start = v_governance_valid_from then

    raise exception
      'SMOKE FAIL: vigência institucional redefiniu o início do Horizonte.';

  end if;


  -- ==========================================================
  -- 5. FORMULAÇÃO PARA TESTE BROWNFIELD
  -- ==========================================================

  select f.id
  into v_formulation_id
  from public.skpe_strategic_formulations f
  where f.project_id = v_project_id
  order by f.version_number desc, f.created_at desc
  limit 1;


  -- ==========================================================
  -- 6. ADAPTADOR DEVE DEVOLVER O MESMO HORIZONTE
  -- ==========================================================

  select
    x.period_start,
    x.period_end,
    x.resolution_source
  into
    v_legacy_period_start,
    v_legacy_period_end,
    v_legacy_resolution_source
  from public.get_skpe_effective_strategic_horizon_period(
    v_project_id,
    v_formulation_id
  ) x;


  if v_legacy_period_start
       is distinct from v_period_start
     or v_legacy_period_end
       is distinct from v_period_end
     or v_legacy_resolution_source
       is distinct from v_resolution_source then

    raise exception
      'SMOKE FAIL: adaptador brownfield divergiu da função canônica.';

  end if;


  -- ==========================================================
  -- 7. INSPEÇÃO DA DEFINIÇÃO CANÔNICA
  -- ==========================================================

  select pg_get_functiondef(
    'public.get_skpe_strategic_horizon_period(uuid)'::regprocedure
  )
  into v_canonical_definition;


  if v_canonical_definition ilike '%valid_from%'
     or v_canonical_definition ilike '%valid_until%'
     or v_canonical_definition ilike '%skpe_strategic_formulations%' then

    raise exception
      'SMOKE FAIL: função canônica possui dependência temporal proibida.';

  end if;


  if v_canonical_definition
       not ilike '%horizon_start_year%'
     or v_canonical_definition
       not ilike '%horizon_end_year%' then

    raise exception
      'SMOKE FAIL: função canônica não utiliza os anos do Horizonte.';

  end if;


  -- ==========================================================
  -- 8. INSPEÇÃO DO ADAPTADOR
  -- ==========================================================

  select pg_get_functiondef(
    'public.get_skpe_effective_strategic_horizon_period(uuid,uuid)'::regprocedure
  )
  into v_legacy_definition;


  if v_legacy_definition
       ilike '%formulation_without_approved_horizon%'
     or v_legacy_definition
       ilike '%formulation_with_canonical_horizon%' then

    raise exception
      'SMOKE FAIL: semântica temporal anterior ainda está presente.';

  end if;


  if v_legacy_definition
       not ilike '%get_skpe_strategic_horizon_period%' then

    raise exception
      'SMOKE FAIL: adaptador não delega à função canônica.';

  end if;


  raise notice
    'GATE-17-B.4C.3 SMOKE PASS - project=%, strategic_period=%..%, governance_effective_from=%, source=%',
    v_project_id,
    v_period_start,
    v_period_end,
    v_governance_valid_from,
    v_resolution_source;

end;
$smoke$;


-- ============================================================
-- EVIDÊNCIA TABULAR
-- ============================================================

select
  p.code as project_code,

  h.horizon_start_year,
  h.horizon_end_year,

  h.valid_from
    as governance_effective_from,

  h.valid_until
    as governance_effective_until,

  c.period_start
    as strategic_period_start,

  c.period_end
    as strategic_period_end,

  c.resolution_source,

  case
    when c.period_start =
         make_date(h.horizon_start_year, 1, 1)
     and c.period_end =
         make_date(h.horizon_end_year, 12, 31)
      then 'PASS'
    else 'FAIL'
  end as temporal_semantic_contract

from public.skpe_projects p

join public.skpe_strategic_horizons h
  on h.project_id = p.id
 and h.is_current = true
 and h.governance_status in (
   'approved',
   'historical_recognized'
 )

cross join lateral
  public.get_skpe_strategic_horizon_period(p.id) c

where p.code = 'PE-COOTAQUARA-2026'
  and p.archived_at is null;
