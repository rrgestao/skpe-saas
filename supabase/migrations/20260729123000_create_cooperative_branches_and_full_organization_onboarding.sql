begin;

-- ============================================================
-- Plataforma SPARKs
-- Cadastro mestre dos Ramos Cooperativistas
-- e onboarding institucional completo de organizações.
--
-- Objetivos:
-- 1. Registrar os oito ramos oficiais do cooperativismo.
-- 2. Preservar compatibilidade com organizations.cooperative_branch.
-- 3. Expor APIs globais para seleção e manutenção dos ramos.
-- 4. Criar uma operação transacional para salvar:
--    organização + ramo + endereço + contatos + CNAEs oficiais.
-- 5. Permitir rascunho incompleto e exigir completude para ativação.
-- ============================================================

-- ============================================================
-- 1. CADASTRO MESTRE GLOBAL DE RAMOS COOPERATIVISTAS
-- ============================================================

create table if not exists public.cooperative_branches (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  name text not null,
  short_name text,
  description text,
  display_order integer not null default 100,
  status text not null default 'active'
    check (status in ('active', 'inactive', 'deprecated')),
  effective_from date,
  effective_until date,
  official_source_name text,
  official_source_url text,
  official_reference text,
  official_published_at date,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references auth.users(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references auth.users(id) on delete set null,
  constraint cooperative_branches_code_not_blank
    check (length(trim(code)) > 0),
  constraint cooperative_branches_name_not_blank
    check (length(trim(name)) > 0),
  constraint cooperative_branches_validity_check
    check (effective_until is null or effective_from is null or effective_until >= effective_from)
);

create unique index if not exists uq_cooperative_branches_code
  on public.cooperative_branches (upper(code));

create unique index if not exists uq_cooperative_branches_name
  on public.cooperative_branches (lower(name));

create index if not exists idx_cooperative_branches_status_order
  on public.cooperative_branches (status, display_order, name);

insert into public.cooperative_branches (
  code,
  name,
  short_name,
  description,
  display_order,
  status,
  effective_from,
  official_source_name,
  official_source_url,
  official_reference,
  official_published_at,
  metadata
)
values
  (
    'AGROPECUARIO',
    'Agropecuário',
    'Agropecuário',
    'Cooperativas relacionadas à produção, industrialização e comercialização agropecuária.',
    10,
    'active',
    null,
    'Sistema OCB',
    'https://somoscooperativismo.coop.br/conteudos/publicacoes-representacao',
    'Ramos do cooperativismo - classificação oficial vigente',
    date '2026-07-08',
    jsonb_build_object('classification', 'official_ocb', 'catalog_version', '2026.1')
  ),
  (
    'CONSUMO',
    'Consumo',
    'Consumo',
    'Cooperativas constituídas para aquisição coletiva de produtos e serviços pelos cooperados.',
    20,
    'active',
    null,
    'Sistema OCB',
    'https://somoscooperativismo.coop.br/conteudos/publicacoes-representacao',
    'Ramos do cooperativismo - classificação oficial vigente',
    date '2026-07-08',
    jsonb_build_object('classification', 'official_ocb', 'catalog_version', '2026.1')
  ),
  (
    'CREDITO',
    'Crédito',
    'Crédito',
    'Cooperativas que oferecem soluções financeiras aos cooperados.',
    30,
    'active',
    null,
    'Sistema OCB',
    'https://somoscooperativismo.coop.br/conteudos/publicacoes-representacao',
    'Ramos do cooperativismo - classificação oficial vigente',
    date '2026-07-08',
    jsonb_build_object('classification', 'official_ocb', 'catalog_version', '2026.1')
  ),
  (
    'INFRAESTRUTURA',
    'Infraestrutura',
    'Infraestrutura',
    'Cooperativas que prestam serviços essenciais de infraestrutura aos cooperados e às comunidades.',
    40,
    'active',
    null,
    'Sistema OCB',
    'https://somoscooperativismo.coop.br/conteudos/publicacoes-representacao',
    'Ramos do cooperativismo - classificação oficial vigente',
    date '2026-07-08',
    jsonb_build_object('classification', 'official_ocb', 'catalog_version', '2026.1')
  ),
  (
    'SAUDE',
    'Saúde',
    'Saúde',
    'Cooperativas formadas por profissionais e organizações que atuam na promoção e prestação de serviços de saúde.',
    50,
    'active',
    null,
    'Sistema OCB',
    'https://somoscooperativismo.coop.br/conteudos/publicacoes-representacao',
    'Ramos do cooperativismo - classificação oficial vigente',
    date '2026-07-08',
    jsonb_build_object('classification', 'official_ocb', 'catalog_version', '2026.1')
  ),
  (
    'SEGUROS',
    'Seguros',
    'Seguros',
    'Cooperativas seguradoras organizadas para proteção coletiva e compartilhamento de riscos.',
    60,
    'active',
    null,
    'Sistema OCB',
    'https://somoscooperativismo.coop.br/anuario-ramos/seguros',
    'Oitavo ramo do cooperativismo brasileiro, instituído após a Lei Complementar nº 213/2025',
    date '2026-07-08',
    jsonb_build_object('classification', 'official_ocb', 'catalog_version', '2026.1', 'is_eighth_branch', true)
  ),
  (
    'TRABALHO_PRODUCAO_BENS_SERVICOS',
    'Trabalho, Produção de Bens e Serviços',
    'Trabalho, Produção de Bens e Serviços',
    'Cooperativas de profissionais, trabalhadores e produtores organizados para prestar serviços ou produzir bens.',
    70,
    'active',
    null,
    'Sistema OCB',
    'https://somoscooperativismo.coop.br/conteudos/publicacoes-representacao',
    'Ramos do cooperativismo - classificação oficial vigente',
    date '2026-07-08',
    jsonb_build_object('classification', 'official_ocb', 'catalog_version', '2026.1')
  ),
  (
    'TRANSPORTE',
    'Transporte',
    'Transporte',
    'Cooperativas dedicadas ao transporte de cargas ou passageiros.',
    80,
    'active',
    null,
    'Sistema OCB',
    'https://somoscooperativismo.coop.br/conteudos/publicacoes-representacao',
    'Ramos do cooperativismo - classificação oficial vigente',
    date '2026-07-08',
    jsonb_build_object('classification', 'official_ocb', 'catalog_version', '2026.1')
  )
on conflict (upper(code)) do update set
  name = excluded.name,
  short_name = excluded.short_name,
  description = excluded.description,
  display_order = excluded.display_order,
  status = excluded.status,
  effective_from = excluded.effective_from,
  official_source_name = excluded.official_source_name,
  official_source_url = excluded.official_source_url,
  official_reference = excluded.official_reference,
  official_published_at = excluded.official_published_at,
  metadata = excluded.metadata,
  updated_at = timezone('utc', now()),
  updated_by = auth.uid();

alter table public.cooperative_branches enable row level security;

drop policy if exists cooperative_branches_select on public.cooperative_branches;
create policy cooperative_branches_select
on public.cooperative_branches
for select
to authenticated
using (
  status = 'active'
  or public.is_platform_super_admin()
);

drop policy if exists cooperative_branches_manage on public.cooperative_branches;
create policy cooperative_branches_manage
on public.cooperative_branches
for all
to authenticated
using (public.is_platform_super_admin())
with check (public.is_platform_super_admin());

grant select on table public.cooperative_branches to authenticated, service_role;
grant insert, update, delete on table public.cooperative_branches to authenticated, service_role;

comment on table public.cooperative_branches is
  'Cadastro mestre global e versionável dos ramos oficiais do cooperativismo brasileiro.';

-- ============================================================
-- 2. VÍNCULO ESTRUTURADO DA ORGANIZAÇÃO AO RAMO
-- ============================================================

alter table public.organizations
  add column if not exists cooperative_branch_id uuid;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'organizations_cooperative_branch_id_fkey'
      and conrelid = 'public.organizations'::regclass
  ) then
    alter table public.organizations
      add constraint organizations_cooperative_branch_id_fkey
      foreign key (cooperative_branch_id)
      references public.cooperative_branches(id)
      on delete restrict;
  end if;
end
$$;

create index if not exists idx_organizations_cooperative_branch
  on public.organizations (cooperative_branch_id, status);

-- Saneamento de valores textuais já existentes, sem apagar o campo legado.
with inferred_branch as (
  select
    organization.id,
    case
      when lower(coalesce(organization.cooperative_branch, '')) like '%agro%' then 'AGROPECUARIO'
      when lower(coalesce(organization.cooperative_branch, '')) like '%consumo%' then 'CONSUMO'
      when lower(coalesce(organization.cooperative_branch, '')) like '%crédito%'
        or lower(coalesce(organization.cooperative_branch, '')) like '%credito%' then 'CREDITO'
      when lower(coalesce(organization.cooperative_branch, '')) like '%infra%' then 'INFRAESTRUTURA'
      when lower(coalesce(organization.cooperative_branch, '')) like '%saúde%'
        or lower(coalesce(organization.cooperative_branch, '')) like '%saude%' then 'SAUDE'
      when lower(coalesce(organization.cooperative_branch, '')) like '%seguro%' then 'SEGUROS'
      when lower(coalesce(organization.cooperative_branch, '')) like '%transporte%' then 'TRANSPORTE'
      when lower(coalesce(organization.cooperative_branch, '')) like '%trabalho%'
        or lower(coalesce(organization.cooperative_branch, '')) like '%produção de bens%'
        or lower(coalesce(organization.cooperative_branch, '')) like '%producao de bens%'
        or upper(coalesce(organization.cooperative_branch, '')) = 'TPBS'
        then 'TRABALHO_PRODUCAO_BENS_SERVICOS'
      else null
    end as branch_code
  from public.organizations organization
  where organization.organization_type = 'cooperative'
)
update public.organizations organization
set
  cooperative_branch_id = branch.id,
  cooperative_branch = branch.name,
  updated_at = timezone('utc', now())
from inferred_branch inferred
join public.cooperative_branches branch
  on branch.code = inferred.branch_code
where organization.id = inferred.id
  and inferred.branch_code is not null
  and (
    organization.cooperative_branch_id is distinct from branch.id
    or organization.cooperative_branch is distinct from branch.name
  );

comment on column public.organizations.cooperative_branch_id is
  'Referência estruturada ao cadastro mestre global de Ramos Cooperativistas.';

-- ============================================================
-- 3. API DE CONSULTA E MANUTENÇÃO DOS RAMOS
-- ============================================================

create or replace function public.get_cooperative_branches(
  include_inactive boolean default false
)
returns table (
  branch_id uuid,
  branch_code text,
  branch_name text,
  short_name text,
  description text,
  display_order integer,
  status text,
  effective_from date,
  effective_until date,
  official_source_name text,
  official_source_url text,
  official_reference text,
  official_published_at date
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  return query
  select
    branch.id,
    branch.code,
    branch.name,
    branch.short_name,
    branch.description,
    branch.display_order,
    branch.status,
    branch.effective_from,
    branch.effective_until,
    branch.official_source_name,
    branch.official_source_url,
    branch.official_reference,
    branch.official_published_at
  from public.cooperative_branches branch
  where branch.status = 'active'
     or (
       coalesce(include_inactive, false)
       and public.is_platform_super_admin()
     )
  order by branch.display_order, branch.name;
end;
$$;

create or replace function public.upsert_platform_admin_cooperative_branch(
  target_branch_id uuid,
  payload jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  result_id uuid;
  normalized_code text;
  normalized_name text;
  normalized_status text;
  reason text;
begin
  perform public.require_platform_super_admin();

  normalized_code := upper(trim(coalesce(payload ->> 'code', '')));
  normalized_name := trim(coalesce(payload ->> 'name', ''));
  normalized_status := lower(trim(coalesce(payload ->> 'status', 'active')));
  reason := trim(coalesce(payload ->> 'change_reason', ''));

  if normalized_code = '' then
    raise exception 'Informe o código do ramo cooperativista.';
  end if;

  if normalized_name = '' then
    raise exception 'Informe o nome do ramo cooperativista.';
  end if;

  if normalized_status not in ('active', 'inactive', 'deprecated') then
    raise exception 'Situação inválida para o ramo cooperativista.';
  end if;

  if length(reason) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.';
  end if;

  if target_branch_id is null then
    insert into public.cooperative_branches (
      code,
      name,
      short_name,
      description,
      display_order,
      status,
      effective_from,
      effective_until,
      official_source_name,
      official_source_url,
      official_reference,
      official_published_at,
      metadata,
      created_by,
      updated_by
    )
    values (
      normalized_code,
      normalized_name,
      nullif(trim(payload ->> 'short_name'), ''),
      nullif(trim(payload ->> 'description'), ''),
      coalesce(nullif(payload ->> 'display_order', '')::integer, 100),
      normalized_status,
      nullif(payload ->> 'effective_from', '')::date,
      nullif(payload ->> 'effective_until', '')::date,
      nullif(trim(payload ->> 'official_source_name'), ''),
      nullif(trim(payload ->> 'official_source_url'), ''),
      nullif(trim(payload ->> 'official_reference'), ''),
      nullif(payload ->> 'official_published_at', '')::date,
      coalesce(payload -> 'metadata', '{}'::jsonb),
      auth.uid(),
      auth.uid()
    )
    returning id into result_id;
  else
    update public.cooperative_branches
    set
      code = normalized_code,
      name = normalized_name,
      short_name = nullif(trim(payload ->> 'short_name'), ''),
      description = nullif(trim(payload ->> 'description'), ''),
      display_order = coalesce(nullif(payload ->> 'display_order', '')::integer, display_order),
      status = normalized_status,
      effective_from = nullif(payload ->> 'effective_from', '')::date,
      effective_until = nullif(payload ->> 'effective_until', '')::date,
      official_source_name = nullif(trim(payload ->> 'official_source_name'), ''),
      official_source_url = nullif(trim(payload ->> 'official_source_url'), ''),
      official_reference = nullif(trim(payload ->> 'official_reference'), ''),
      official_published_at = nullif(payload ->> 'official_published_at', '')::date,
      metadata = coalesce(payload -> 'metadata', metadata),
      updated_at = timezone('utc', now()),
      updated_by = auth.uid()
    where id = target_branch_id
    returning id into result_id;

    if result_id is null then
      raise exception 'Ramo cooperativista não encontrado.';
    end if;
  end if;

  insert into public.privileged_access_audit (
    actor_user_id,
    event_type,
    event_description,
    entity_schema,
    entity_table,
    entity_id,
    new_data,
    metadata
  )
  values (
    auth.uid(),
    case when target_branch_id is null then 'data_created' else 'data_updated' end,
    reason,
    'public',
    'cooperative_branches',
    result_id::text,
    jsonb_build_object(
      'code', normalized_code,
      'name', normalized_name,
      'status', normalized_status
    ),
    jsonb_build_object('source', 'platform_admin')
  );

  return result_id;
end;
$$;

revoke all on function public.get_cooperative_branches(boolean) from public;
revoke all on function public.upsert_platform_admin_cooperative_branch(uuid, jsonb) from public;

grant execute on function public.get_cooperative_branches(boolean)
  to authenticated, service_role;
grant execute on function public.upsert_platform_admin_cooperative_branch(uuid, jsonb)
  to authenticated, service_role;

comment on function public.get_cooperative_branches(boolean) is
  'Retorna o catálogo oficial de Ramos Cooperativistas; itens inativos somente são expostos ao SUPER-ADMIN.';

comment on function public.upsert_platform_admin_cooperative_branch(uuid, jsonb) is
  'Cria ou atualiza um Ramo Cooperativista pelo SUPER-ADMIN, com auditoria.';

-- ============================================================
-- 4. DETALHE INSTITUCIONAL COMPLETO PARA A ADMINISTRAÇÃO GLOBAL
-- ============================================================

create or replace function public.get_platform_admin_organization_detail_v2(
  target_organization_id uuid
)
returns table (
  organization_id uuid,
  organization_code text,
  legal_name text,
  trade_name text,
  organization_level text,
  organization_type text,
  status text,
  parent_organization_id uuid,
  parent_organization_name text,
  cnpj text,
  cooperative_branch_id uuid,
  cooperative_branch_code text,
  cooperative_branch_name text,
  primary_activity_description text,
  economic_activities jsonb,
  institutional_email text,
  phone text,
  website text,
  postal_code text,
  street text,
  address_number text,
  address_complement text,
  district text,
  city text,
  state_code text,
  country_code text,
  description text,
  memberships_count bigint,
  enabled_modules_count bigint,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public.require_platform_super_admin();

  return query
  select
    organization.id::uuid,
    organization.code::text,
    organization.legal_name::text,
    organization.trade_name::text,
    organization.organization_level::text,
    organization.organization_type::text,
    organization.status::text,
    organization.parent_organization_id::uuid,
    coalesce(parent.trade_name, parent.legal_name, parent.code)::text,
    coalesce(organization.cnpj, organization.tax_identifier)::text,
    branch.id::uuid,
    branch.code::text,
    coalesce(branch.name, organization.cooperative_branch)::text,
    organization.primary_activity_description::text,
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'organization_activity_id', activity.id,
            'cnae_catalog_id', activity.cnae_catalog_id,
            'version_code', catalog.version_code,
            'subclass_code', activity.cnae_code,
            'formatted_code', coalesce(
              catalog.formatted_code,
              substr(activity.cnae_code, 1, 2)
              || '.' || substr(activity.cnae_code, 3, 2)
              || '-' || substr(activity.cnae_code, 5, 1)
              || '/' || substr(activity.cnae_code, 6, 2)
            ),
            'description', coalesce(catalog.description, activity.description),
            'is_primary', activity.is_primary,
            'verification_status', activity.verification_status,
            'source_type', activity.source_type,
            'source_reference', activity.source_reference
          )
          order by activity.is_primary desc, activity.cnae_code
        )
        from public.organization_economic_activities activity
        left join public.cnae_catalog catalog
          on catalog.id = activity.cnae_catalog_id
        where activity.organization_id = organization.id
          and activity.status = 'active'
      ),
      '[]'::jsonb
    ),
    coalesce(organization.institutional_email, organization.email)::text,
    organization.phone::text,
    organization.website::text,
    organization.postal_code::text,
    organization.street::text,
    organization.address_number::text,
    organization.address_complement::text,
    organization.district::text,
    organization.city::text,
    organization.state_code::text,
    coalesce(organization.country_code, 'BR')::text,
    organization.description::text,
    (
      select count(*)
      from public.organization_memberships membership
      where membership.organization_id = organization.id
        and membership.status::text <> 'revoked'
    )::bigint,
    (
      select count(*)
      from public.organization_modules organization_module
      where organization_module.organization_id = organization.id
        and organization_module.enabled = true
        and organization_module.status = 'active'
    )::bigint,
    organization.created_at::timestamptz,
    organization.updated_at::timestamptz
  from public.organizations organization
  left join public.organizations parent
    on parent.id = organization.parent_organization_id
  left join public.cooperative_branches branch
    on branch.id = organization.cooperative_branch_id
  where organization.id = target_organization_id;
end;
$$;

revoke all on function public.get_platform_admin_organization_detail_v2(uuid) from public;
grant execute on function public.get_platform_admin_organization_detail_v2(uuid)
  to authenticated, service_role;

comment on function public.get_platform_admin_organization_detail_v2(uuid) is
  'Retorna o cadastro institucional completo, o Ramo Cooperativista estruturado e os CNAEs oficiais para manutenção pelo SUPER-ADMIN.';

-- ============================================================
-- 5. ONBOARDING TRANSACIONAL COMPLETO
-- ============================================================

create or replace function public.upsert_platform_admin_organization_v2(
  target_organization_id uuid,
  payload jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  result_id uuid;
  normalized_code text;
  normalized_legal_name text;
  normalized_trade_name text;
  normalized_level text;
  normalized_type text;
  normalized_status text;
  normalized_cnpj text;
  normalized_email text;
  normalized_postal_code text;
  normalized_state_code text;
  normalized_country_code text;
  normalized_branch_code text;
  selected_branch_id uuid;
  selected_branch_name text;
  selected_cnaes jsonb;
  selected_count integer;
  primary_count integer;
  reason text;
  parent_id uuid;
begin
  perform public.require_platform_super_admin();

  if jsonb_typeof(coalesce(payload, '{}'::jsonb)) <> 'object' then
    raise exception 'Os dados da organização devem ser enviados como um objeto.';
  end if;

  normalized_code := upper(trim(coalesce(payload ->> 'code', '')));
  normalized_legal_name := trim(coalesce(payload ->> 'legal_name', ''));
  normalized_trade_name := trim(coalesce(payload ->> 'trade_name', ''));
  normalized_level := lower(trim(coalesce(payload ->> 'organization_level', 'singular')));
  normalized_type := lower(trim(coalesce(payload ->> 'organization_type', 'cooperative')));
  normalized_status := lower(trim(coalesce(payload ->> 'status', 'draft')));
  normalized_cnpj := nullif(
    regexp_replace(coalesce(payload ->> 'cnpj', ''), '[^0-9]', '', 'g'),
    ''
  );
  normalized_email := nullif(lower(trim(payload ->> 'institutional_email')), '');
  normalized_postal_code := nullif(
    regexp_replace(coalesce(payload ->> 'postal_code', ''), '[^0-9]', '', 'g'),
    ''
  );
  normalized_state_code := nullif(upper(trim(payload ->> 'state_code')), '');
  normalized_country_code := coalesce(
    nullif(upper(trim(payload ->> 'country_code')), ''),
    'BR'
  );
  normalized_branch_code := nullif(
    upper(trim(payload ->> 'cooperative_branch_code')),
    ''
  );
  selected_cnaes := coalesce(payload -> 'selected_cnaes', '[]'::jsonb);
  reason := trim(coalesce(payload ->> 'change_reason', ''));
  parent_id := nullif(payload ->> 'parent_organization_id', '')::uuid;

  if normalized_code = '' then
    raise exception 'Informe o código da organização.';
  end if;

  if normalized_legal_name = '' then
    raise exception 'Informe a razão social da organização.';
  end if;

  if normalized_type not in (
    'cooperative',
    'system',
    'company',
    'industry',
    'commerce',
    'services',
    'association',
    'institute',
    'foundation',
    'public_body',
    'rural_producer',
    'other'
  ) then
    raise exception 'Tipo de organização inválido.';
  end if;

  if normalized_status not in (
    'draft',
    'active',
    'inactive',
    'suspended',
    'archived'
  ) then
    raise exception 'Situação inválida para a organização.';
  end if;

  if length(reason) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.';
  end if;

  if parent_id = target_organization_id and target_organization_id is not null then
    raise exception 'A organização não pode ser superior a si mesma.';
  end if;

  if normalized_cnpj is not null
     and not public.sparks_is_valid_cnpj(normalized_cnpj) then
    raise exception 'O CNPJ informado é inválido.';
  end if;

  if jsonb_typeof(selected_cnaes) <> 'array' then
    raise exception 'A seleção de CNAEs deve ser enviada como uma lista.';
  end if;

  selected_count := jsonb_array_length(selected_cnaes);

  select count(*)
  into primary_count
  from jsonb_array_elements(selected_cnaes) item
  where lower(coalesce(item ->> 'is_primary', 'false'))
    in ('true', '1', 'yes', 'sim');

  if selected_count > 0 and primary_count <> 1 then
    raise exception 'Selecione exatamente um CNAE principal.';
  end if;

  if normalized_type = 'cooperative' then
    if normalized_branch_code is not null then
      select branch.id, branch.name
      into selected_branch_id, selected_branch_name
      from public.cooperative_branches branch
      where upper(branch.code) = normalized_branch_code
        and branch.status = 'active';

      if selected_branch_id is null then
        raise exception 'O Ramo Cooperativista informado não existe ou está inativo.';
      end if;
    end if;
  else
    selected_branch_id := null;
    selected_branch_name := null;
  end if;

  -- Rascunhos podem permanecer incompletos.
  -- A ativação exige o conjunto institucional mínimo.
  if normalized_status = 'active' then
    if normalized_trade_name = '' then
      raise exception 'Informe o nome fantasia antes de ativar a organização.';
    end if;

    if normalized_email is null then
      raise exception 'Informe o e-mail institucional antes de ativar a organização.';
    end if;

    if normalized_type = 'cooperative' and selected_branch_id is null then
      raise exception 'Selecione o Ramo Cooperativista antes de ativar a cooperativa.';
    end if;

    if normalized_country_code = 'BR' then
      if normalized_cnpj is null then
        raise exception 'Informe o CNPJ antes de ativar a organização brasileira.';
      end if;

      if normalized_postal_code is null or length(normalized_postal_code) <> 8 then
        raise exception 'Informe um CEP válido com oito dígitos antes de ativar a organização.';
      end if;

      if nullif(trim(payload ->> 'street'), '') is null then
        raise exception 'Informe o logradouro antes de ativar a organização.';
      end if;

      if nullif(trim(payload ->> 'address_number'), '') is null then
        raise exception 'Informe o número do endereço antes de ativar a organização.';
      end if;

      if nullif(trim(payload ->> 'district'), '') is null then
        raise exception 'Informe o bairro antes de ativar a organização.';
      end if;

      if nullif(trim(payload ->> 'city'), '') is null then
        raise exception 'Informe o município antes de ativar a organização.';
      end if;

      if normalized_state_code is null or length(normalized_state_code) <> 2 then
        raise exception 'Informe a UF antes de ativar a organização.';
      end if;

      if selected_count = 0 or primary_count <> 1 then
        raise exception 'Selecione ao menos um CNAE oficial e defina exatamente um como principal antes de ativar a organização.';
      end if;
    end if;
  end if;

  if target_organization_id is null then
    insert into public.organizations (
      code,
      legal_name,
      trade_name,
      organization_level,
      organization_type,
      status,
      parent_organization_id,
      cnpj,
      tax_identifier,
      cooperative_branch_id,
      cooperative_branch,
      institutional_email,
      email,
      phone,
      website,
      postal_code,
      street,
      address_number,
      address_complement,
      district,
      city,
      state_code,
      country_code,
      description,
      institutional_profile_updated_at,
      institutional_profile_updated_by,
      created_by,
      updated_by
    )
    values (
      normalized_code,
      normalized_legal_name,
      nullif(normalized_trade_name, ''),
      normalized_level::public.organization_level,
      normalized_type,
      normalized_status::public.organization_status,
      parent_id,
      normalized_cnpj,
      normalized_cnpj,
      selected_branch_id,
      selected_branch_name,
      normalized_email,
      normalized_email,
      nullif(trim(payload ->> 'phone'), ''),
      nullif(trim(payload ->> 'website'), ''),
      normalized_postal_code,
      nullif(trim(payload ->> 'street'), ''),
      nullif(trim(payload ->> 'address_number'), ''),
      nullif(trim(payload ->> 'address_complement'), ''),
      nullif(trim(payload ->> 'district'), ''),
      nullif(trim(payload ->> 'city'), ''),
      normalized_state_code,
      normalized_country_code,
      nullif(trim(payload ->> 'description'), ''),
      timezone('utc', now()),
      auth.uid(),
      auth.uid(),
      auth.uid()
    )
    returning id into result_id;
  else
    update public.organizations
    set
      code = normalized_code,
      legal_name = normalized_legal_name,
      trade_name = nullif(normalized_trade_name, ''),
      organization_level = normalized_level::public.organization_level,
      organization_type = normalized_type,
      status = normalized_status::public.organization_status,
      parent_organization_id = parent_id,
      cnpj = normalized_cnpj,
      tax_identifier = normalized_cnpj,
      cooperative_branch_id = selected_branch_id,
      cooperative_branch = selected_branch_name,
      institutional_email = normalized_email,
      email = normalized_email,
      phone = nullif(trim(payload ->> 'phone'), ''),
      website = nullif(trim(payload ->> 'website'), ''),
      postal_code = normalized_postal_code,
      street = nullif(trim(payload ->> 'street'), ''),
      address_number = nullif(trim(payload ->> 'address_number'), ''),
      address_complement = nullif(trim(payload ->> 'address_complement'), ''),
      district = nullif(trim(payload ->> 'district'), ''),
      city = nullif(trim(payload ->> 'city'), ''),
      state_code = normalized_state_code,
      country_code = normalized_country_code,
      description = nullif(trim(payload ->> 'description'), ''),
      archived_at = case
        when normalized_status = 'archived'
          then coalesce(archived_at, timezone('utc', now()))
        else null
      end,
      institutional_profile_updated_at = timezone('utc', now()),
      institutional_profile_updated_by = auth.uid(),
      updated_at = timezone('utc', now()),
      updated_by = auth.uid()
    where id = target_organization_id
    returning id into result_id;

    if result_id is null then
      raise exception 'Organização não encontrada.';
    end if;
  end if;

  -- A função existente valida o catálogo vigente, mantém histórico
  -- e audita a substituição. Se falhar, toda esta operação é revertida.
  perform public.replace_organization_cnaes_v3(
    result_id,
    selected_cnaes,
    coalesce(
      nullif(lower(trim(payload ->> 'cnae_source_type')), ''),
      'manual_confirmed'
    ),
    nullif(trim(payload ->> 'cnae_source_reference'), ''),
    reason
  );

  insert into public.privileged_access_audit (
    actor_user_id,
    organization_id,
    event_type,
    event_description,
    entity_schema,
    entity_table,
    entity_id,
    new_data,
    metadata
  )
  values (
    auth.uid(),
    result_id,
    case when target_organization_id is null then 'data_created' else 'data_updated' end,
    reason,
    'public',
    'organizations',
    result_id::text,
    jsonb_build_object(
      'code', normalized_code,
      'legal_name', normalized_legal_name,
      'trade_name', nullif(normalized_trade_name, ''),
      'organization_type', normalized_type,
      'organization_level', normalized_level,
      'status', normalized_status,
      'cooperative_branch_code', normalized_branch_code,
      'country_code', normalized_country_code,
      'state_code', normalized_state_code,
      'city', nullif(trim(payload ->> 'city'), ''),
      'cnae_count', selected_count
    ),
    jsonb_build_object(
      'source', 'platform_admin',
      'operation', 'full_organization_onboarding_v2'
    )
  );

  return result_id;
end;
$$;

revoke all on function public.upsert_platform_admin_organization_v2(uuid, jsonb)
  from public;

grant execute on function public.upsert_platform_admin_organization_v2(uuid, jsonb)
  to authenticated, service_role;

comment on function public.upsert_platform_admin_organization_v2(uuid, jsonb) is
  'Cria ou atualiza atomicamente o cadastro institucional completo da organização, incluindo Ramo Cooperativista, endereço e CNAEs oficiais.';

commit;

-- ============================================================
-- VERIFICAÇÃO SOMENTE DE LEITURA
-- ============================================================

select
  code,
  name,
  display_order,
  status,
  official_source_name,
  official_published_at
from public.cooperative_branches
order by display_order;

select
  count(*) as total_ramos_ativos
from public.cooperative_branches
where status = 'active';

select
  column_name,
  data_type
from information_schema.columns
where table_schema = 'public'
  and table_name = 'organizations'
  and column_name in (
    'cooperative_branch_id',
    'cooperative_branch',
    'postal_code',
    'street',
    'address_number',
    'address_complement',
    'district',
    'city',
    'state_code',
    'country_code'
  )
order by column_name;

select
  routine_name
from information_schema.routines
where routine_schema = 'public'
  and routine_name in (
    'get_cooperative_branches',
    'upsert_platform_admin_cooperative_branch',
    'get_platform_admin_organization_detail_v2',
    'upsert_platform_admin_organization_v2'
  )
order by routine_name;
