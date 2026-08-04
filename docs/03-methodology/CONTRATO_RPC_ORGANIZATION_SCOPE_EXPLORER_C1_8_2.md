# FE-09.A.01-C1.8.2-A - Contract of get_organization_scope_explorer

## Purpose

Provide one read-only and reusable organizational scope envelope for users, areas, roles and responsibilities. The RPC does not replace write or administration RPCs.

## Signature

```sql
public.get_organization_scope_explorer(
  root_organization_id uuid,
  target_module_code text default 'SK-PE',
  target_domain text default 'users',
  include_inactive boolean default false
) returns jsonb
```

## Supported domains

- `users`
- `areas`
- `roles`
- `responsibilities`

## Security contract

- `STABLE`
- `SECURITY DEFINER`
- empty `search_path`
- execute permission only for `authenticated` and `service_role`
- no insert, update or delete
- each organization is filtered by `can_access_descendant_organization`
- read access is not confused with user-management permission

## Envelope

```json
{
  "contract_version": "1.0",
  "generated_at": "UTC timestamp",
  "root_organization_id": "uuid",
  "module_code": "SK-PE",
  "domain": "users",
  "include_inactive": false,
  "organization_count": 0,
  "organizations": [
    {
      "organization_id": "uuid",
      "organization_code": "CODE",
      "organization_name": "Name",
      "parent_organization_id": "uuid or null",
      "depth": 0,
      "path": ["uuid"],
      "organization_status": "active",
      "access_origin": "root | direct_membership | hierarchical_policy",
      "access_mode": "root | manage_users | read_only",
      "detail_available": true,
      "item_count": 0,
      "items": []
    }
  ]
}
```

## Frontend use

The frontend must render the organization tree using `parent_organization_id`, `depth` and `path`. Domain adapters must consume only `items`, without duplicating hierarchy or authorization logic.

## Controlled rollout

1. Apply the migration in Supabase Web SQL Editor.
2. Run the verification script.
3. Test the `users` domain with the selected root organization.
4. Test `areas`, `roles` and `responsibilities`.
5. Only then start FE-09.A.01-C1.8.2-B frontend integration.