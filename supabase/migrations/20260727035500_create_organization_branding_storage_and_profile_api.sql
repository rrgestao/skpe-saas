begin;

-- ============================================================
-- Plataforma SPARKs
-- Cadastro Institucional e Identidade Visual da Organização
-- Migration incremental: storage da logomarca + API de consulta
-- ============================================================

-- 1. Bucket privado para identidade visual institucional.
insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'organization-branding',
  'organization-branding',
  false,
  5242880,
  array[
    'image/png',
    'image/jpeg',
    'image/webp',
    'image/svg+xml'
  ]
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- 2. Consulta segura e consolidada do cadastro institucional.
create or replace function public.get_sparks_organization_profile(
  target_organization_id uuid
)
returns table (
  organization_id uuid,
  organization_code text,
  legal_name text,
  trade_name text,
  formatted_cnpj text,
  cnpj_digits text,
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
  logo_url text,
  logo_storage_path text,
  logo_version integer,
  cooperative_branch text,
  organization_size text,
  institutional_profile_updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not (
    public.is_platform_super_admin()
    or exists (
      select 1
      from public.organization_memberships membership
      where membership.organization_id = target_organization_id
        and membership.user_id = auth.uid()
        and membership.status = 'active'
    )
  ) then
    raise exception
      'Acesso negado: o usuário não pode consultar o cadastro institucional desta organização.'
      using errcode = '42501';
  end if;

  return query
  select
    organization.id,
    organization.code,
    organization.legal_name,
    organization.trade_name,
    public.sparks_format_cnpj(organization.cnpj),
    organization.cnpj,
    organization.institutional_email,
    organization.phone,
    organization.website,
    organization.postal_code,
    organization.street,
    organization.address_number,
    organization.address_complement,
    organization.district,
    organization.city,
    organization.state_code,
    organization.country_code,
    organization.logo_url,
    organization.logo_storage_path,
    organization.logo_version,
    organization.cooperative_branch,
    organization.organization_size,
    organization.institutional_profile_updated_at
  from public.organizations organization
  where organization.id = target_organization_id;
end;
$$;

comment on function public.get_sparks_organization_profile(uuid) is
  'Retorna o cadastro institucional consolidado da organização para uso compartilhado nos módulos da Plataforma SPARKs.';

-- 3. Políticas de acesso ao Storage.
-- O primeiro segmento do caminho deve ser o UUID da organização.

drop policy if exists organization_branding_select on storage.objects;
create policy organization_branding_select
on storage.objects
for select
to authenticated
using (
  bucket_id = 'organization-branding'
  and (
    public.is_platform_super_admin()
    or exists (
      select 1
      from public.organization_memberships membership
      where membership.organization_id = ((storage.foldername(name))[1])::uuid
        and membership.user_id = auth.uid()
        and membership.status = 'active'
    )
  )
);

drop policy if exists organization_branding_insert on storage.objects;
create policy organization_branding_insert
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'organization-branding'
  and (
    public.is_platform_super_admin()
    or public.is_organization_admin(
      ((storage.foldername(name))[1])::uuid
    )
    or public.has_module_permission(
      ((storage.foldername(name))[1])::uuid,
      'SK-ASM',
      'organization_profile.manage'
    )
  )
);

drop policy if exists organization_branding_update on storage.objects;
create policy organization_branding_update
on storage.objects
for update
to authenticated
using (
  bucket_id = 'organization-branding'
  and (
    public.is_platform_super_admin()
    or public.is_organization_admin(
      ((storage.foldername(name))[1])::uuid
    )
    or public.has_module_permission(
      ((storage.foldername(name))[1])::uuid,
      'SK-ASM',
      'organization_profile.manage'
    )
  )
)
with check (
  bucket_id = 'organization-branding'
  and (
    public.is_platform_super_admin()
    or public.is_organization_admin(
      ((storage.foldername(name))[1])::uuid
    )
    or public.has_module_permission(
      ((storage.foldername(name))[1])::uuid,
      'SK-ASM',
      'organization_profile.manage'
    )
  )
);

drop policy if exists organization_branding_delete on storage.objects;
create policy organization_branding_delete
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'organization-branding'
  and (
    public.is_platform_super_admin()
    or public.is_organization_admin(
      ((storage.foldername(name))[1])::uuid
    )
    or public.has_module_permission(
      ((storage.foldername(name))[1])::uuid,
      'SK-ASM',
      'organization_profile.manage'
    )
  )
);

-- 4. Permissões explícitas das funções.
revoke all on function public.get_sparks_organization_profile(uuid) from public;
grant execute on function public.get_sparks_organization_profile(uuid) to authenticated;

commit;
