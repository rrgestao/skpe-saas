-- Allow conceptual Evolution Scenario cycles with no dates.
-- Temporal overlap and horizon guards apply as soon as dates are defined.

create or replace function public.skpe_validate_evolution_scenario_cycle_temporality()
returns trigger
language plpgsql
set search_path=''
as $function$
declare
  v_start date;
  v_end date;
begin
  if new.period_start is null and new.period_end is null then
    return new;
  end if;

  if new.period_start is null or new.period_end is null then
    raise exception using
      errcode='23514',
      message='Início e fim do Ciclo devem ser informados juntos quando houver temporalização.';
  end if;

  select
    coalesce(h.valid_from,make_date(h.horizon_start_year,1,1)),
    coalesce(h.valid_until,make_date(h.horizon_end_year,12,31))
  into v_start,v_end
  from public.skpe_strategic_horizons h
  where h.id=new.strategic_horizon_id;

  if v_start is null then
    raise exception using errcode='23503', message='Horizonte Estratégico não encontrado.';
  end if;

  if new.period_start<v_start or new.period_end>v_end then
    raise exception using
      errcode='23514',
      message='Ciclo de Evolução temporalizado deve permanecer dentro do período estratégico do Horizonte.';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(new.scenario_id::text,0));

  if exists (
    select 1
    from public.skpe_evolution_scenario_cycles c
    where c.scenario_id=new.scenario_id
      and c.id<>new.id
      and c.period_start is not null
      and c.period_end is not null
      and daterange(c.period_start,c.period_end,'[]')
          && daterange(new.period_start,new.period_end,'[]')
  ) then
    raise exception using
      errcode='23P01',
      message='Ciclos de Evolução temporalizados não podem se sobrepor no mesmo cenário.';
  end if;

  return new;
end;
$function$;

comment on function public.skpe_validate_evolution_scenario_cycle_temporality() is
'Allows conceptual cycles without dates; enforces horizon and non-overlap rules once temporalized.';
