-- ============================================================
-- Plataforma SPARKs
-- Cadastro Institucional, Pessoas, Vínculos e Responsabilidades
-- Fonte oficial: SK-ASM / Núcleo compartilhado da plataforma
-- Conteúdos funcionais em Português do Brasil
-- ============================================================

begin;

-- ============================================================
-- 1. FUNÇÕES DE CNPJ
-- ============================================================

create or replace function public.sparks_normalize_cnpj(value text)
returns text
language sql
immutable
set search_path = ''
as $$
  select regexp_replace(coalesce(value, ''), '[^0-9]', '', 'g');
$$;

create or replace function public.sparks_format_cnpj(value text)
returns text
language plpgsql
immutable
set search_path = ''
as $$
declare
  normalized text;
begin
  normalized := public.sparks_normalize_cnpj(value);

  if length(normalized) <> 14 then
    return value;
  end if;

  return substr(normalized, 1, 2) || '.' ||
         substr(normalized, 3, 3) || '.' ||
         substr(normalized, 6, 3) || '/' ||
         substr(normalized, 9, 4) || '-' ||
         substr(normalized, 13, 2);
end;
$$;

create or replace function public.sparks_is_valid_cnpj(value text)
returns boolean
language plpgsql
immutable
set search_path = ''
as $$
declare
  cnpj text;
  total integer;
  remainder integer;
  digit1 integer;
  digit2 integer;
  i integer;
  weights1 integer[] := array[5,4,3,2,9,8,7,6,5,4,3,2];
  weights2 integer[] := array[6,5,4,3,2,9,8,7,6,5,4,3,2];
begin
  cnpj := public.sparks_normalize_cnpj(value);

  if length(cnpj) <> 14 then
    return false;
  end if;

  if cnpj ~ '^([0-9])\1{13}$' then
    return false;
  end if;

  total := 0;
  for i in 1..12 loop
    total := total + substr(cnpj, i, 1)::integer * weights1[i];
  end loop;

  remainder := total % 11;
  digit1 := case when remainder < 2 then 0 else 11 - remainder end;

  if digit1 <> substr(cnpj, 13, 1)::integer then
    return false;
  end if;

  total := 0;
  for i in 1..13 loop
    total := total + substr(cnpj, i, 1)::integer * weights2[i];
  end loop;

  remainder := total % 11;
  digit2 := case when remainder < 2 then 0 else 11 - remainder end;

  return digit2 = substr(cnpj, 14, 1)::integer;
end;
$$;

-- ============================================================
-- 2. CADASTRO INSTITUCIONAL DA ORGANIZAÇÃO
-- ============================================================

alter table public.organizations
  add column if not exists legal_name text,
  add column if not exists trade_name text,
  add column if not exists cnpj text,
  add column if not exists state_registration text,
  add column if not exists municipal_registration text,
  add column if not exists legal_nature text,
  add column if not exists organization_size text,
  add column if not exists founded_on date,
  add column if not exists website text,
  add column if not exists institutional_email text,
  add column if not exists phone text,
  add column if not exists postal_code text,
  add column if not exists street text,
  add column if not exists address_number text,
  add column if not exists address_complement text,
  add column if not exists district text,
  add column if not exists city text,
  add column if not exists state_code text,
  add column if not exists country_code text default 'BR',
  add column if not exists logo_url text,
  add column if not exists logo_storage_path text,
  add column if not exists logo_version integer not null default 1,
  add column if not exists visual_identity_metadata jsonb not null default '{}'::jsonb,
  add column if not exists cooperative_branch text,
  add column if not exists ocb_registration text,
  add column if not exists commercial_registry_number text,
  add column if not exists territorial_scope text,
  add column if not exists units_count integer,
  add column if not exists members_count integer,
  add column if not exists employees_count integer,
  add column if not exists directors_count integer,
  add column if not exists board_members_count integer,
  add column if not exists institutional_profile_updated_at timestamptz,
  add column if not exists institutional_profile_updated_by uuid references public.profiles(id) on delete set null;

update public.organizations
set
  trade_name = coalesce(
    nullif(trim(trade_name), ''),
    legal_name,
    code
  )
where trade_name is null
   or length(trim(trade_name)) = 0;

alter table public.organizations
  drop constraint if exists organizations_cnpj_format_check;

alter table public.organizations
  add constraint organizations_cnpj_format_check
  check (
    cnpj is null
    or (
      cnpj ~ '^[0-9]{14}$'
      and public.sparks_is_valid_cnpj(cnpj)
    )
  );

alter table public.organizations
  drop constraint if exists organizations_state_code_check;

alter table public.organizations
  add constraint organizations_state_code_check
  check (
    state_code is null
    or state_code ~ '^[A-Z]{2}$'
  );

alter table public.organizations
  drop constraint if exists organizations_postal_code_check;

alter table public.organizations
  add constraint organizations_postal_code_check
  check (
    postal_code is null
    or postal_code ~ '^[0-9]{8}$'
  );

create unique index if not exists idx_organizations_unique_cnpj
  on public.organizations(cnpj)
  where cnpj is not null;

comment on column public.organizations.cnpj is
  'CNPJ armazenado somente com 14 dígitos. A máscara 99.999.999/9999-99 deve ser aplicada na interface e nas saídas.';

comment on column public.organizations.logo_url is
  'URL pública ou assinada da logomarca institucional utilizada no cabeçalho, relatórios e exportações.';

-- ============================================================
-- 3. PESSOAS — CADASTRO ÚNICO DA PLATAFORMA
-- ============================================================

create table if not exists public.sparks_people (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  preferred_name text,
  cpf text,
  birth_date date,
  primary_email text,
  primary_phone text,
  profile_user_id uuid references public.profiles(id) on delete set null,
  person_status text not null default 'active',
  data_source text not null default 'sk_asm',
  lgpd_legal_basis text,
  sensitive_data_metadata jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,
  archived_at timestamptz,

  constraint sparks_people_full_name_not_blank
    check (length(trim(full_name)) > 0),
  constraint sparks_people_cpf_format_check
    check (cpf is null or cpf ~ '^[0-9]{11}$'),
  constraint sparks_people_status_check
    check (person_status in ('active', 'inactive', 'deceased', 'blocked', 'archived')),
  constraint sparks_people_source_check
    check (data_source in ('sk_asm', 'import', 'integration', 'manual', 'legacy'))
);

create unique index if not exists idx_sparks_people_unique_cpf
  on public.sparks_people(cpf)
  where cpf is not null and archived_at is null;

create unique index if not exists idx_sparks_people_unique_profile
  on public.sparks_people(profile_user_id)
  where profile_user_id is not null and archived_at is null;

create index if not exists idx_sparks_people_name
  on public.sparks_people(lower(full_name))
  where archived_at is null;

create trigger sparks_people_set_updated_at
before update on public.sparks_people
for each row
execute function public.set_updated_at();

-- ============================================================
-- 4. VÍNCULOS DA PESSOA COM A ORGANIZAÇÃO
-- ============================================================

create table if not exists public.sparks_organization_people (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  person_id uuid not null references public.sparks_people(id) on delete cascade,
  relationship_type text not null,
  registration_number text,
  job_title text,
  organizational_area text,
  organizational_unit text,
  start_date date,
  end_date date,
  status text not null default 'active',
  is_primary_relationship boolean not null default false,
  is_cooperative_member boolean not null default false,
  is_employee boolean not null default false,
  is_director boolean not null default false,
  is_board_member boolean not null default false,
  is_committee_member boolean not null default false,
  workload_hours numeric(8,2),
  availability_percentage numeric(5,2),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint sparks_organization_people_relationship_check
    check (relationship_type in (
      'cooperative_member',
      'employee',
      'director',
      'board_member',
      'fiscal_council_member',
      'committee_member',
      'service_provider',
      'representative',
      'volunteer',
      'partner',
      'other'
    )),
  constraint sparks_organization_people_status_check
    check (status in ('active', 'inactive', 'suspended', 'ended')),
  constraint sparks_organization_people_dates_check
    check (end_date is null or start_date is null or end_date >= start_date),
  constraint sparks_organization_people_availability_check
    check (availability_percentage is null or availability_percentage between 0 and 100),
  constraint sparks_organization_people_unique_relationship
    unique (organization_id, person_id, relationship_type, start_date)
);

create index if not exists idx_sparks_organization_people_active
  on public.sparks_organization_people(organization_id, status, relationship_type);

create index if not exists idx_sparks_organization_people_area
  on public.sparks_organization_people(organization_id, organizational_area)
  where status = 'active';

create trigger sparks_organization_people_set_updated_at
before update on public.sparks_organization_people
for each row
execute function public.set_updated_at();

-- ============================================================
-- 5. PAPÉIS, MANDATOS E DESIGNAÇÕES ORGANIZACIONAIS
-- ============================================================

create table if not exists public.sparks_organizational_roles (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  code text not null,
  name text not null,
  role_type text not null,
  description text,
  organizational_area text,
  is_governance_role boolean not null default false,
  requires_mandate boolean not null default false,
  active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint sparks_organizational_roles_code_not_blank
    check (length(trim(code)) > 0),
  constraint sparks_organizational_roles_name_not_blank
    check (length(trim(name)) > 0),
  constraint sparks_organizational_roles_type_check
    check (role_type in (
      'job',
      'function',
      'governance',
      'committee',
      'project',
      'process',
      'temporary'
    )),
  constraint sparks_organizational_roles_unique_code
    unique (organization_id, code)
);

create trigger sparks_organizational_roles_set_updated_at
before update on public.sparks_organizational_roles
for each row
execute function public.set_updated_at();

create table if not exists public.sparks_person_role_assignments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  organization_person_id uuid not null references public.sparks_organization_people(id) on delete cascade,
  organizational_role_id uuid not null references public.sparks_organizational_roles(id) on delete cascade,
  mandate_start_date date,
  mandate_end_date date,
  assignment_status text not null default 'active',
  appointment_document_reference text,
  appointment_evidence_id uuid,
  notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint sparks_person_role_assignments_status_check
    check (assignment_status in ('planned', 'active', 'suspended', 'ended', 'revoked')),
  constraint sparks_person_role_assignments_dates_check
    check (
      mandate_end_date is null
      or mandate_start_date is null
      or mandate_end_date >= mandate_start_date
    )
);

create index if not exists idx_sparks_person_role_assignments_active
  on public.sparks_person_role_assignments(organization_id, assignment_status, organizational_role_id);

create trigger sparks_person_role_assignments_set_updated_at
before update on public.sparks_person_role_assignments
for each row
execute function public.set_updated_at();

-- ============================================================
-- 6. MATRIZ TRANSVERSAL DE RESPONSABILIDADES
-- ============================================================

create table if not exists public.sparks_responsibility_assignments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  module_code text not null,
  object_type text not null,
  object_id uuid not null,
  organization_person_id uuid not null references public.sparks_organization_people(id) on delete cascade,
  responsibility_type text not null,
  allocation_percentage numeric(5,2),
  valid_from date,
  valid_until date,
  status text not null default 'active',
  assignment_reason text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint sparks_responsibility_assignments_module_not_blank
    check (length(trim(module_code)) > 0),
  constraint sparks_responsibility_assignments_object_not_blank
    check (length(trim(object_type)) > 0),
  constraint sparks_responsibility_assignments_type_check
    check (responsibility_type in (
      'owner',
      'sponsor',
      'approver',
      'executor',
      'consulted',
      'informed',
      'custodian',
      'reviewer',
      'facilitator',
      'team_member'
    )),
  constraint sparks_responsibility_assignments_allocation_check
    check (allocation_percentage is null or allocation_percentage between 0 and 100),
  constraint sparks_responsibility_assignments_status_check
    check (status in ('planned', 'active', 'suspended', 'ended', 'revoked')),
  constraint sparks_responsibility_assignments_dates_check
    check (valid_until is null or valid_from is null or valid_until >= valid_from)
);

create unique index if not exists idx_sparks_responsibility_unique_active
  on public.sparks_responsibility_assignments(
    organization_id,
    module_code,
    object_type,
    object_id,
    organization_person_id,
    responsibility_type
  )
  where status = 'active';

create index if not exists idx_sparks_responsibility_by_object
  on public.sparks_responsibility_assignments(organization_id, module_code, object_type, object_id)
  where status = 'active';

create index if not exists idx_sparks_responsibility_by_person
  on public.sparks_responsibility_assignments(organization_person_id, status);

create trigger sparks_responsibility_assignments_set_updated_at
before update on public.sparks_responsibility_assignments
for each row
execute function public.set_updated_at();

-- ============================================================
-- 7. PERMISSÕES DO SK-ASM
-- ============================================================

insert into public.module_permissions (
  module_id,
  code,
  name,
  description,
  permission_group,
  active
)
select
  module.id,
  permission_data.code,
  permission_data.name,
  permission_data.description,
  permission_data.permission_group,
  true
from public.modules module
cross join (
  values
    (
      'organization_profile.view',
      'Consultar cadastro institucional',
      'Permite consultar os dados institucionais e a identidade visual da organização.',
      'organization_registry'
    ),
    (
      'organization_profile.manage',
      'Gerenciar cadastro institucional',
      'Permite alterar os dados institucionais, endereço, contatos e logomarca da organização.',
      'organization_registry'
    ),
    (
      'people.view',
      'Consultar pessoas e vínculos',
      'Permite consultar pessoas, vínculos, papéis, mandatos e responsabilidades da organização.',
      'people'
    ),
    (
      'people.manage',
      'Gerenciar pessoas e vínculos',
      'Permite cadastrar e manter pessoas, vínculos, papéis, mandatos e responsabilidades.',
      'people'
    )
) as permission_data(code, name, description, permission_group)
where module.code = 'SK-ASM'
on conflict (module_id, code) do update
set
  name = excluded.name,
  description = excluded.description,
  permission_group = excluded.permission_group,
  active = true;

insert into public.role_permissions (
  module_role_id,
  module_permission_id
)
select
  role.id,
  permission.id
from public.module_roles role
join public.modules module
  on module.id = role.module_id
join public.module_permissions permission
  on permission.module_id = module.id
where module.code = 'SK-ASM'
  and (
    (
      role.code in ('administrator', 'manager', 'editor')
      and permission.code in (
        'organization_profile.view',
        'organization_profile.manage',
        'people.view',
        'people.manage'
      )
    )
    or
    (
      role.code in ('approver', 'viewer')
      and permission.code in (
        'organization_profile.view',
        'people.view'
      )
    )
  )
on conflict do nothing;

-- ============================================================
-- 8. FUNÇÕES DE AUTORIZAÇÃO
-- ============================================================

create or replace function public.can_view_sparks_people(
  target_organization_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    public.is_platform_super_admin()
    or public.is_organization_admin(target_organization_id)
    or exists (
      select 1
      from public.organization_memberships membership
      where membership.organization_id = target_organization_id
        and membership.user_id = auth.uid()
        and membership.status = 'active'
        and (
          membership.valid_from is null
          or membership.valid_from <= current_date
        )
        and (
          membership.valid_until is null
          or membership.valid_until >= current_date
        )
    );
$$;

create or replace function public.can_manage_sparks_people(
  target_organization_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    public.is_platform_super_admin()
    or public.is_organization_admin(target_organization_id)
    or public.has_module_permission(
      target_organization_id,
      'SK-ASM',
      'people.manage'
    );
$$;

-- ============================================================
-- 9. FUNÇÕES OPERACIONAIS
-- ============================================================

create or replace function public.update_sparks_organization_profile(
  target_organization_id uuid,
  target_legal_name text,
  target_trade_name text,
  target_cnpj text,
  target_institutional_email text,
  target_phone text,
  target_website text,
  target_postal_code text,
  target_street text,
  target_address_number text,
  target_address_complement text,
  target_district text,
  target_city text,
  target_state_code text,
  target_logo_url text,
  target_logo_storage_path text,
  target_cooperative_branch text,
  target_organization_size text,
  change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  normalized_cnpj text;
begin
  if not (
    public.is_platform_super_admin()
    or public.is_organization_admin(target_organization_id)
    or public.has_module_permission(
      target_organization_id,
      'SK-ASM',
      'organization_profile.manage'
    )
  ) then
    raise exception
      'Acesso negado: o usuário não pode alterar o cadastro institucional desta organização.'
      using errcode = '42501';
  end if;

  if length(trim(coalesce(change_reason, ''))) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.';
  end if;

  normalized_cnpj := nullif(public.sparks_normalize_cnpj(target_cnpj), '');

  if normalized_cnpj is not null
     and not public.sparks_is_valid_cnpj(normalized_cnpj) then
    raise exception 'O CNPJ informado é inválido.';
  end if;

  update public.organizations
  set
    legal_name = nullif(trim(target_legal_name), ''),
    trade_name = nullif(trim(target_trade_name), ''),
    cnpj = normalized_cnpj,
    institutional_email = nullif(trim(target_institutional_email), ''),
    phone = nullif(trim(target_phone), ''),
    website = nullif(trim(target_website), ''),
    postal_code = nullif(regexp_replace(coalesce(target_postal_code, ''), '[^0-9]', '', 'g'), ''),
    street = nullif(trim(target_street), ''),
    address_number = nullif(trim(target_address_number), ''),
    address_complement = nullif(trim(target_address_complement), ''),
    district = nullif(trim(target_district), ''),
    city = nullif(trim(target_city), ''),
    state_code = nullif(upper(trim(target_state_code)), ''),
    logo_url = nullif(trim(target_logo_url), ''),
    logo_storage_path = nullif(trim(target_logo_storage_path), ''),
    logo_version = case
      when coalesce(logo_url, '') is distinct from coalesce(nullif(trim(target_logo_url), ''), '')
        then logo_version + 1
      else logo_version
    end,
    cooperative_branch = nullif(trim(target_cooperative_branch), ''),
    organization_size = nullif(trim(target_organization_size), ''),
    institutional_profile_updated_at = timezone('utc', now()),
    institutional_profile_updated_by = auth.uid(),
    updated_at = timezone('utc', now())
  where id = target_organization_id;

  if not found then
    raise exception 'Organização não encontrada.';
  end if;

  return target_organization_id;
end;
$$;

create or replace function public.get_sparks_people_for_responsibility(
  target_organization_id uuid,
  target_search text default null,
  target_relationship_type text default null,
  target_only_active boolean default true
)
returns table (
  organization_person_id uuid,
  person_id uuid,
  full_name text,
  preferred_name text,
  primary_email text,
  primary_phone text,
  relationship_type text,
  job_title text,
  organizational_area text,
  organizational_unit text,
  relationship_status text,
  start_date date,
  end_date date,
  availability_percentage numeric,
  profile_user_id uuid
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.can_view_sparks_people(target_organization_id) then
    raise exception
      'Acesso negado: o usuário não pode consultar as pessoas desta organização.'
      using errcode = '42501';
  end if;

  return query
  select
    relationship.id,
    person.id,
    person.full_name,
    person.preferred_name,
    person.primary_email,
    person.primary_phone,
    relationship.relationship_type,
    relationship.job_title,
    relationship.organizational_area,
    relationship.organizational_unit,
    relationship.status,
    relationship.start_date,
    relationship.end_date,
    relationship.availability_percentage,
    person.profile_user_id
  from public.sparks_organization_people relationship
  join public.sparks_people person
    on person.id = relationship.person_id
  where relationship.organization_id = target_organization_id
    and person.archived_at is null
    and (
      not target_only_active
      or (
        person.person_status = 'active'
        and relationship.status = 'active'
        and (relationship.start_date is null or relationship.start_date <= current_date)
        and (relationship.end_date is null or relationship.end_date >= current_date)
      )
    )
    and (
      target_relationship_type is null
      or relationship.relationship_type = target_relationship_type
    )
    and (
      target_search is null
      or trim(target_search) = ''
      or person.full_name ilike '%' || trim(target_search) || '%'
      or coalesce(person.preferred_name, '') ilike '%' || trim(target_search) || '%'
      or coalesce(person.primary_email, '') ilike '%' || trim(target_search) || '%'
      or coalesce(relationship.job_title, '') ilike '%' || trim(target_search) || '%'
      or coalesce(relationship.organizational_area, '') ilike '%' || trim(target_search) || '%'
    )
  order by coalesce(person.preferred_name, person.full_name), relationship.relationship_type;
end;
$$;

create or replace function public.assign_sparks_responsibility(
  target_organization_id uuid,
  target_module_code text,
  target_object_type text,
  target_object_id uuid,
  target_organization_person_id uuid,
  target_responsibility_type text,
  target_allocation_percentage numeric default null,
  target_valid_from date default null,
  target_valid_until date default null,
  target_assignment_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  assignment_id uuid;
begin
  if not public.can_manage_sparks_people(target_organization_id) then
    raise exception
      'Acesso negado: o usuário não pode atribuir responsabilidades nesta organização.'
      using errcode = '42501';
  end if;

  if length(trim(coalesce(target_assignment_reason, ''))) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.';
  end if;

  if not exists (
    select 1
    from public.sparks_organization_people relationship
    where relationship.id = target_organization_person_id
      and relationship.organization_id = target_organization_id
      and relationship.status = 'active'
      and (relationship.end_date is null or relationship.end_date >= current_date)
  ) then
    raise exception 'A pessoa selecionada não possui vínculo ativo com a organização.';
  end if;

  insert into public.sparks_responsibility_assignments (
    organization_id,
    module_code,
    object_type,
    object_id,
    organization_person_id,
    responsibility_type,
    allocation_percentage,
    valid_from,
    valid_until,
    status,
    assignment_reason,
    created_by,
    updated_by
  ) values (
    target_organization_id,
    upper(trim(target_module_code)),
    trim(target_object_type),
    target_object_id,
    target_organization_person_id,
    target_responsibility_type,
    target_allocation_percentage,
    target_valid_from,
    target_valid_until,
    'active',
    trim(target_assignment_reason),
    auth.uid(),
    auth.uid()
  )
  returning id into assignment_id;

  return assignment_id;
end;
$$;

-- ============================================================
-- 10. RLS
-- ============================================================

alter table public.sparks_people enable row level security;
alter table public.sparks_organization_people enable row level security;
alter table public.sparks_organizational_roles enable row level security;
alter table public.sparks_person_role_assignments enable row level security;
alter table public.sparks_responsibility_assignments enable row level security;

drop policy if exists sparks_people_select_policy on public.sparks_people;
create policy sparks_people_select_policy
on public.sparks_people
for select
to authenticated
using (
  exists (
    select 1
    from public.sparks_organization_people relationship
    where relationship.person_id = sparks_people.id
      and public.can_view_sparks_people(relationship.organization_id)
  )
);

drop policy if exists sparks_people_manage_policy on public.sparks_people;
create policy sparks_people_manage_policy
on public.sparks_people
for all
to authenticated
using (
  exists (
    select 1
    from public.sparks_organization_people relationship
    where relationship.person_id = sparks_people.id
      and public.can_manage_sparks_people(relationship.organization_id)
  )
)
with check (true);

drop policy if exists sparks_organization_people_select_policy on public.sparks_organization_people;
create policy sparks_organization_people_select_policy
on public.sparks_organization_people
for select
to authenticated
using (public.can_view_sparks_people(organization_id));

drop policy if exists sparks_organization_people_manage_policy on public.sparks_organization_people;
create policy sparks_organization_people_manage_policy
on public.sparks_organization_people
for all
to authenticated
using (public.can_manage_sparks_people(organization_id))
with check (public.can_manage_sparks_people(organization_id));

drop policy if exists sparks_organizational_roles_select_policy on public.sparks_organizational_roles;
create policy sparks_organizational_roles_select_policy
on public.sparks_organizational_roles
for select
to authenticated
using (public.can_view_sparks_people(organization_id));

drop policy if exists sparks_organizational_roles_manage_policy on public.sparks_organizational_roles;
create policy sparks_organizational_roles_manage_policy
on public.sparks_organizational_roles
for all
to authenticated
using (public.can_manage_sparks_people(organization_id))
with check (public.can_manage_sparks_people(organization_id));

drop policy if exists sparks_person_role_assignments_select_policy on public.sparks_person_role_assignments;
create policy sparks_person_role_assignments_select_policy
on public.sparks_person_role_assignments
for select
to authenticated
using (public.can_view_sparks_people(organization_id));

drop policy if exists sparks_person_role_assignments_manage_policy on public.sparks_person_role_assignments;
create policy sparks_person_role_assignments_manage_policy
on public.sparks_person_role_assignments
for all
to authenticated
using (public.can_manage_sparks_people(organization_id))
with check (public.can_manage_sparks_people(organization_id));

drop policy if exists sparks_responsibility_assignments_select_policy on public.sparks_responsibility_assignments;
create policy sparks_responsibility_assignments_select_policy
on public.sparks_responsibility_assignments
for select
to authenticated
using (public.can_view_sparks_people(organization_id));

drop policy if exists sparks_responsibility_assignments_manage_policy on public.sparks_responsibility_assignments;
create policy sparks_responsibility_assignments_manage_policy
on public.sparks_responsibility_assignments
for all
to authenticated
using (public.can_manage_sparks_people(organization_id))
with check (public.can_manage_sparks_people(organization_id));

-- ============================================================
-- 11. GRANTS
-- ============================================================

revoke all on public.sparks_people from anon;
revoke all on public.sparks_organization_people from anon;
revoke all on public.sparks_organizational_roles from anon;
revoke all on public.sparks_person_role_assignments from anon;
revoke all on public.sparks_responsibility_assignments from anon;

grant select, insert, update on public.sparks_people to authenticated, service_role;
grant select, insert, update on public.sparks_organization_people to authenticated, service_role;
grant select, insert, update on public.sparks_organizational_roles to authenticated, service_role;
grant select, insert, update on public.sparks_person_role_assignments to authenticated, service_role;
grant select, insert, update on public.sparks_responsibility_assignments to authenticated, service_role;

revoke all on function public.sparks_normalize_cnpj(text) from public, anon;
revoke all on function public.sparks_format_cnpj(text) from public, anon;
revoke all on function public.sparks_is_valid_cnpj(text) from public, anon;
revoke all on function public.can_view_sparks_people(uuid) from public, anon;
revoke all on function public.can_manage_sparks_people(uuid) from public, anon;
revoke all on function public.update_sparks_organization_profile(uuid,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text) from public, anon;
revoke all on function public.get_sparks_people_for_responsibility(uuid,text,text,boolean) from public, anon;
revoke all on function public.assign_sparks_responsibility(uuid,text,text,uuid,uuid,text,numeric,date,date,text) from public, anon;

grant execute on function public.sparks_normalize_cnpj(text) to authenticated, service_role;
grant execute on function public.sparks_format_cnpj(text) to authenticated, service_role;
grant execute on function public.sparks_is_valid_cnpj(text) to authenticated, service_role;
grant execute on function public.can_view_sparks_people(uuid) to authenticated, service_role;
grant execute on function public.can_manage_sparks_people(uuid) to authenticated, service_role;
grant execute on function public.update_sparks_organization_profile(uuid,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text) to authenticated, service_role;
grant execute on function public.get_sparks_people_for_responsibility(uuid,text,text,boolean) to authenticated, service_role;
grant execute on function public.assign_sparks_responsibility(uuid,text,text,uuid,uuid,text,numeric,date,date,text) to authenticated, service_role;

commit;
