begin;

alter table public.organizations
  add column if not exists organization_type text,
  add column if not exists primary_activity_description text;

create table if not exists public.organization_economic_activities (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  cnae_code text not null,
  description text,
  is_primary boolean not null default false,
  status text not null default 'active',
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid default auth.uid(),
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid default auth.uid(),
  unique (organization_id, cnae_code)
);

create index if not exists idx_org_economic_activities_org
  on public.organization_economic_activities (organization_id, status, is_primary desc);

alter table public.organization_economic_activities enable row level security;

drop policy if exists organization_economic_activities_select on public.organization_economic_activities;
create policy organization_economic_activities_select
on public.organization_economic_activities for select to authenticated
using (
  public.is_platform_super_admin()
  or exists (
    select 1 from public.organization_memberships m
    where m.organization_id = organization_economic_activities.organization_id
      and m.user_id = auth.uid() and m.status = 'active'
  )
);

drop policy if exists organization_economic_activities_manage on public.organization_economic_activities;
create policy organization_economic_activities_manage
on public.organization_economic_activities for all to authenticated
using (
  public.is_platform_super_admin()
  or public.is_organization_admin(organization_economic_activities.organization_id)
)
with check (
  public.is_platform_super_admin()
  or public.is_organization_admin(organization_economic_activities.organization_id)
);

create or replace function public.get_sparks_organization_profile_v2(target_organization_id uuid)
returns table (
  organization_id uuid, organization_code text, legal_name text, trade_name text,
  formatted_cnpj text, cnpj_digits text, organization_type text,
  primary_activity_description text, economic_activities jsonb,
  institutional_email text, phone text, website text, postal_code text,
  street text, address_number text, address_complement text, district text,
  city text, state_code text, country_code text, logo_url text,
  logo_storage_path text, logo_version integer, cooperative_branch text,
  organization_size text, institutional_profile_updated_at timestamptz
)
language plpgsql stable security definer set search_path = '' as $$
begin
  if not (
    public.is_platform_super_admin()
    or exists (
      select 1 from public.organization_memberships m
      where m.organization_id = target_organization_id
        and m.user_id = auth.uid() and m.status = 'active'
    )
  ) then
    raise exception 'Acesso negado: o usuário não pode consultar o cadastro institucional desta organização.' using errcode = '42501';
  end if;

  return query
  select o.id::uuid, o.code::text, o.legal_name::text, o.trade_name::text,
    public.sparks_format_cnpj(o.cnpj)::text, o.cnpj::text,
    o.organization_type::text, o.primary_activity_description::text,
    coalesce((select jsonb_agg(jsonb_build_object(
      'id', a.id, 'code', a.cnae_code, 'description', a.description,
      'is_primary', a.is_primary, 'status', a.status
    ) order by a.is_primary desc, a.cnae_code)
    from public.organization_economic_activities a
    where a.organization_id = o.id and a.status = 'active'), '[]'::jsonb),
    o.institutional_email::text, o.phone::text, o.website::text,
    o.postal_code::text, o.street::text, o.address_number::text,
    o.address_complement::text, o.district::text, o.city::text,
    o.state_code::text, o.country_code::text, o.logo_url::text,
    o.logo_storage_path::text, coalesce(o.logo_version,0)::integer,
    o.cooperative_branch::text, o.organization_size::text,
    o.institutional_profile_updated_at::timestamptz
  from public.organizations o where o.id = target_organization_id;
end; $$;

create or replace function public.update_sparks_organization_profile_v2(
  target_organization_id uuid, target_legal_name text, target_trade_name text,
  target_cnpj text, target_organization_type text,
  target_primary_activity_description text, target_economic_activities jsonb,
  target_institutional_email text, target_phone text, target_website text,
  target_postal_code text, target_street text, target_address_number text,
  target_address_complement text, target_district text, target_city text,
  target_state_code text, target_logo_url text, target_logo_storage_path text,
  target_cooperative_branch text, target_organization_size text, change_reason text
) returns uuid
language plpgsql security definer set search_path = '' as $$
declare normalized_cnpj text; activity jsonb; normalized_type text;
begin
  if not (public.is_platform_super_admin() or public.is_organization_admin(target_organization_id)
    or public.has_module_permission(target_organization_id,'SK-ASM','organization_profile.manage')) then
    raise exception 'Acesso negado: o usuário não pode alterar o cadastro institucional desta organização.' using errcode='42501';
  end if;
  if length(trim(coalesce(change_reason,''))) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.';
  end if;
  normalized_type := lower(trim(coalesce(target_organization_type,'')));
  if normalized_type not in ('cooperative','industry','commerce','services','association','foundation','public_body','rural_producer','other') then
    raise exception 'Tipo de organização inválido.';
  end if;
  normalized_cnpj := nullif(public.sparks_normalize_cnpj(target_cnpj),'');
  if normalized_cnpj is not null and not public.sparks_is_valid_cnpj(normalized_cnpj) then
    raise exception 'O CNPJ informado é inválido.';
  end if;
  update public.organizations set
    legal_name=nullif(trim(target_legal_name),''), trade_name=nullif(trim(target_trade_name),''),
    cnpj=normalized_cnpj, organization_type=normalized_type,
    primary_activity_description=nullif(trim(target_primary_activity_description),''),
    institutional_email=nullif(trim(target_institutional_email),''), phone=nullif(trim(target_phone),''),
    website=nullif(trim(target_website),''), postal_code=nullif(regexp_replace(coalesce(target_postal_code,''),'[^0-9]','','g'),''),
    street=nullif(trim(target_street),''), address_number=nullif(trim(target_address_number),''),
    address_complement=nullif(trim(target_address_complement),''), district=nullif(trim(target_district),''),
    city=nullif(trim(target_city),''), state_code=nullif(upper(trim(target_state_code)),''),
    logo_url=nullif(trim(target_logo_url),''), logo_storage_path=nullif(trim(target_logo_storage_path),''),
    logo_version=case when coalesce(logo_storage_path,'') is distinct from coalesce(nullif(trim(target_logo_storage_path),''),'') then coalesce(logo_version,0)+1 else coalesce(logo_version,0) end,
    cooperative_branch=case when normalized_type='cooperative' then nullif(trim(target_cooperative_branch),'') else null end,
    organization_size=nullif(trim(target_organization_size),''),
    institutional_profile_updated_at=timezone('utc',now()), institutional_profile_updated_by=auth.uid(), updated_at=timezone('utc',now())
  where id=target_organization_id;
  if not found then raise exception 'Organização não encontrada.'; end if;

  update public.organization_economic_activities set status='inactive', updated_at=timezone('utc',now()), updated_by=auth.uid()
  where organization_id=target_organization_id;
  for activity in select value from jsonb_array_elements(coalesce(target_economic_activities,'[]'::jsonb)) loop
    if length(regexp_replace(coalesce(activity->>'code',''),'[^0-9]','','g')) < 7 then
      raise exception 'Informe um CNAE válido com 7 dígitos.';
    end if;
    insert into public.organization_economic_activities(organization_id,cnae_code,description,is_primary,status,created_by,updated_by)
    values(target_organization_id, regexp_replace(activity->>'code','[^0-9]','','g'), nullif(trim(activity->>'description'),''), coalesce((activity->>'is_primary')::boolean,false),'active',auth.uid(),auth.uid())
    on conflict (organization_id,cnae_code) do update set description=excluded.description,is_primary=excluded.is_primary,status='active',updated_at=timezone('utc',now()),updated_by=auth.uid();
  end loop;
  return target_organization_id;
end; $$;

revoke all on function public.get_sparks_organization_profile_v2(uuid) from public;
grant execute on function public.get_sparks_organization_profile_v2(uuid) to authenticated;
revoke all on function public.update_sparks_organization_profile_v2(uuid,text,text,text,text,text,jsonb,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text) from public;
grant execute on function public.update_sparks_organization_profile_v2(uuid,text,text,text,text,text,jsonb,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text) to authenticated;

commit;
