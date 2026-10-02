-- M1 contract test - run only after the M1 migration is applied in a development gate.
begin;

do $$
begin
  if to_regclass('public.sparks_measure_bindings') is null then
    raise exception 'M1: sparks_measure_bindings ausente.';
  end if;
  if to_regclass('public.sparks_benchmark_comparability_assessments') is null then
    raise exception 'M1: sparks_benchmark_comparability_assessments ausente.';
  end if;

  if not exists (
    select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'sparks_measure_bindings' and c.relrowsecurity
  ) then
    raise exception 'M1: RLS ausente em sparks_measure_bindings.';
  end if;
  if not exists (
    select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'sparks_benchmark_comparability_assessments' and c.relrowsecurity
  ) then
    raise exception 'M1: RLS ausente em comparability assessments.';
  end if;
end $$;
do $$
begin
  if to_regclass('public.skpe_indicators') is null
     or to_regclass('public.skpe_indicator_targets') is null
     or to_regclass('public.skpe_indicator_measurements') is null
     or to_regclass('public.skpe_benchmark_references') is null
     or to_regclass('public.skpe_performance_snapshots') is null then
    raise exception 'M1: contrato fisico SK-PE foi removido.';
  end if;

  if to_regclass('public.sparks_measure_indicators') is null
     or to_regclass('public.sparks_measure_targets') is null
     or to_regclass('public.sparks_measure_measurements') is null
     or to_regclass('public.sparks_measure_benchmarks') is null
     or to_regclass('public.sparks_performance_snapshots') is null then
    raise exception 'M1: fachada transversal preexistente foi removida.';
  end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='skpe_indicator_measurements'
      and column_name='automatic_performance'
  ) or not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='skpe_indicator_measurements'
      and column_name='manual_performance_override'
  ) or not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='skpe_indicator_measurements'
      and column_name='effective_performance'
  ) then
    raise exception 'M1: tripla de performance vigente foi alterada.';
  end if;
end $$;
do $$
declare
  binding_count bigint;
  assessment_count bigint;
begin
  select count(*) into binding_count from public.sparks_measure_bindings;
  select count(*) into assessment_count from public.sparks_benchmark_comparability_assessments;
  if binding_count <> 0 or assessment_count <> 0 then
    raise exception 'M1: migration estrutural inseriu dados inesperadamente.';
  end if;

  if to_regprocedure('public.skpe_calculate_strategic_performance(text,numeric,numeric,numeric,numeric,numeric)') is null then
    raise exception 'M1: calculo atual de performance foi removido.';
  end if;
  if to_regprocedure('public.get_skpe_strategic_performance(uuid)') is null then
    raise exception 'M1: agregacao estrategica vigente foi removida.';
  end if;
  if to_regprocedure('public.create_sparks_measure_binding(uuid,uuid,text,text,uuid,text,uuid,text,date,date,text,jsonb,text)') is null then
    raise exception 'M1: API de binding ausente.';
  end if;
  if to_regprocedure('public.record_sparks_benchmark_comparability_assessment(uuid,uuid,uuid,text,text,uuid,text,text,text,text,text,text,text,text,text,jsonb,text)') is null then
    raise exception 'M1: API de comparabilidade ausente.';
  end if;
end $$;

rollback;