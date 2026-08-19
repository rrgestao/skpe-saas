-- ============================================================
-- Plataforma SPARKs / SK-PE-CONT-01
-- 17-B.5F.3A-FIX - Correção PT-BR e encoding canônico
-- ============================================================

begin;

update public.sparks_domains
set
  name = 'Categorias de iniciativas',
  description = 'Natureza gerencial da iniciativa, independente de sua classe metodológica.'
where code = 'INITIATIVE_CATEGORY'
  and scope_type = 'global'
  and organization_id is null
  and module_code is null;

with initiative_domain as (
  select id
  from public.sparks_domains
  where code = 'INITIATIVE_CATEGORY'
    and scope_type = 'global'
    and organization_id is null
    and module_code is null
)
update public.sparks_domain_values dv
set
  name = corrected.name,
  description = corrected.description
from initiative_domain d
join (values
  ('strategic', 'Estratégica', 'Iniciativa diretamente vinculada a escolhas e prioridades estratégicas da organização.'),
  ('operational', 'Operacional', 'Iniciativa de melhoria ou evolução da operação.'),
  ('process', 'Processo', 'Iniciativa associada a desenho, melhoria ou transformação de processos.'),
  ('transformation', 'Transformação', 'Iniciativa de transformação organizacional, digital ou institucional.'),
  ('sustainability_esg', 'Sustentabilidade / ESG', 'Iniciativa relacionada à sustentabilidade, ESG, impacto ou materialidade.'),
  ('communication_marketing', 'Comunicação / Marketing', 'Iniciativa de comunicação, posicionamento, relacionamento ou marketing.')
) as corrected(code, name, description)
  on true
where dv.domain_id = d.id
  and dv.code = corrected.code;

comment on table public.sparks_initiatives is
  'Núcleo organizacional transversal de Programas, Projetos, Iniciativas e Ações Estruturantes da Plataforma SPARKs.';

comment on column public.sparks_initiatives.initiative_class is
  'Classe canônica e estrutural: program, project, initiative ou structuring_action.';

comment on column public.sparks_initiatives.category_id is
  'Categoria/Natureza extensível pelo domínio global INITIATIVE_CATEGORY.';

comment on column public.sparks_initiatives.parent_initiative_id is
  'Hierarquia organizacional entre iniciativas; não representa vínculo com Formulação ou módulo especialista.';

comment on column public.sparks_initiatives.source_module_code is
  'Módulo que originou ou materializou a iniciativa; não define sua propriedade existencial.';

comment on column public.sparks_initiatives.responsible_area_id is
  'Área organizacional de referência. Responsabilidades pessoais usam sparks_responsibility_assignments.';

comment on column public.sparks_initiatives.start_date is
  'Início de alto nível da iniciativa. Cronogramas detalhados permanecem em capacidades especializadas.';

comment on column public.sparks_initiatives.target_end_date is
  'Término-alvo de alto nível. Não substitui baseline, rebaseline ou forecast de cronogramas especializados.';

create or replace function public.sparks_validate_initiative_domain_scope()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if not exists (
    select 1
    from public.sparks_domain_values category_value
    join public.sparks_domains category_domain
      on category_domain.id = category_value.domain_id
    where category_value.id = new.category_id
      and category_value.active
      and category_domain.active
      and category_domain.code = 'INITIATIVE_CATEGORY'
      and (
        (
          category_domain.scope_type = 'global'
          and category_domain.organization_id is null
          and category_domain.module_code is null
        )
        or (
          category_domain.scope_type = 'organization'
          and category_domain.organization_id = new.organization_id
        )
      )
  ) then
    raise exception
      'Categoria de iniciativa inválida ou inativa para esta organização.'
      using errcode = '22023';
  end if;

  if new.responsible_area_id is not null and not exists (
    select 1
    from public.sparks_domain_values area_value
    join public.sparks_domains area_domain
      on area_domain.id = area_value.domain_id
    where area_value.id = new.responsible_area_id
      and area_value.active
      and area_domain.active
      and area_domain.scope_type = 'organization'
      and area_domain.organization_id = new.organization_id
      and area_domain.code = 'ORGANIZATIONAL_AREA'
  ) then
    raise exception
      'Área responsável inválida ou inativa para esta organização.'
      using errcode = '22023';
  end if;

  return new;
end;
$$;

revoke all on function public.sparks_validate_initiative_domain_scope() from public;
revoke all on function public.sparks_validate_initiative_domain_scope() from anon;
revoke all on function public.sparks_validate_initiative_domain_scope() from authenticated;

commit;
