begin;

create or replace function public.skpe_assert_okr_semantic_quality_before_validation()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  invalid_count integer;
begin
  if new.status not in ('pending_validation', 'validated')
     or new.status is not distinct from old.status then
    return new;
  end if;

  select count(*) into invalid_count
  from public.skpe_okrs okr
  where okr.formulation_id = new.formulation_id
    and okr.status <> 'cancelled'
    and (
      length(trim(coalesce(okr.title, ''))) = 0
      or okr.title ~ '[0-9%]'
      or lower(trim(okr.title)) ~ '^(implantar|criar|realizar|desenvolver|contratar|executar|promover|cadastrar|registrar|aprovar|comunicar)([[:space:]]|$)'
    );

  if invalid_count > 0 then
    raise exception
      'OKRs não prontos: o Objetivo do OKR deve ser qualitativo, orientado a valor e não conter métricas, números ou redação típica de iniciativa.'
      using errcode = '55000';
  end if;

  select count(*) into invalid_count
  from public.skpe_okrs okr
  where okr.formulation_id = new.formulation_id
    and okr.status <> 'cancelled'
    and lower(trim(coalesce(okr.metadata ->> 'okrType', ''))) not in ('committed', 'aspirational');

  if invalid_count > 0 then
    raise exception
      'OKRs não prontos: classifique previamente cada OKR como comprometido ou aspiracional.'
      using errcode = '55000';
  end if;

  select count(*) into invalid_count
  from (
    select okr.id
    from public.skpe_okrs okr
    left join public.skpe_key_results kr
      on kr.okr_id = okr.id
     and kr.status <> 'cancelled'
    where okr.formulation_id = new.formulation_id
      and okr.status <> 'cancelled'
    group by okr.id
    having count(kr.id) < 3 or count(kr.id) > 5
  ) q;

  if invalid_count > 0 then
    raise exception
      'OKRs não prontos: cada OKR deve possuir entre 3 e 5 Resultados-Chave ativos.'
      using errcode = '55000';
  end if;

  select count(*) into invalid_count
  from public.skpe_key_results kr
  where kr.formulation_id = new.formulation_id
    and kr.status <> 'cancelled'
    and (
      kr.baseline_value is null
      or kr.target_value is null
      or length(trim(coalesce(kr.unit, ''))) = 0
      or kr.period_start is null
      or kr.period_end is null
      or length(trim(coalesce(kr.metadata ->> 'dataSource', ''))) = 0
    );

  if invalid_count > 0 then
    raise exception
      'KRs não prontos: todo Resultado-Chave deve possuir linha de base, meta, unidade, prazo e fonte de apuração.'
      using errcode = '55000';
  end if;

  select count(*) into invalid_count
  from public.skpe_key_results kr
  where kr.formulation_id = new.formulation_id
    and kr.status <> 'cancelled'
    and lower(trim(coalesce(kr.name, ''))) ~ '^(implantar|criar|realizar|desenvolver|contratar|executar|promover|cadastrar|registrar|aprovar|comunicar)([[:space:]]|$)';

  if invalid_count > 0 then
    raise exception
      'KRs não prontos: revise Resultados-Chave com redação típica de atividade ou entrega; KRs devem medir mudança de resultado.'
      using errcode = '55000';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_skpe_okr_packages_semantic_quality on public.skpe_okr_packages;
create trigger trg_skpe_okr_packages_semantic_quality
before update of status on public.skpe_okr_packages
for each row
execute function public.skpe_assert_okr_semantic_quality_before_validation();

comment on function public.skpe_assert_okr_semantic_quality_before_validation() is
  'Protege a submissão/validação de OKRs segundo disciplina SPARKs: Objetivo qualitativo e orientado a valor; classificação comprometido/aspiracional; 3-5 KRs; KRs com baseline, target, unidade, prazo, fonte e redação de outcome.';

commit;
