begin;

-- ============================================================
-- SPARKs PaaS / SK-PE
-- Hardening pré-C9-E
--
-- Objetivos:
-- 1. Restringir handlers internos de resolução exclusivamente
--    ao service_role.
-- 2. Remover exposição anônima indevida da preferência pessoal.
-- ============================================================


-- ============================================================
-- 1. Handler interno: cross_sheet_positional_create_n
-- ============================================================

revoke all on function
  public.skpe_execute_resolution_handler_cross_sheet_positional_create_n(
    text,
    uuid,
    jsonb
  )
from public, anon, authenticated;

grant execute on function
  public.skpe_execute_resolution_handler_cross_sheet_positional_create_n(
    text,
    uuid,
    jsonb
  )
to service_role;


-- ============================================================
-- 2. Handler interno C9-C:
--    key_result_parent_okr_candidate
-- ============================================================

revoke all on function
  public.skpe_execute_resolution_handler_key_result_parent_okr_candidate(
    text,
    uuid,
    jsonb
  )
from public, anon, authenticated;

grant execute on function
  public.skpe_execute_resolution_handler_key_result_parent_okr_candidate(
    text,
    uuid,
    jsonb
  )
to service_role;


-- ============================================================
-- 3. Preferências pessoais
--
-- Deve permanecer acessível ao usuário autenticado e ao
-- service_role, mas não ao anon/PUBLIC.
-- ============================================================

revoke all on function
  public.set_my_module_preference(
    uuid,
    text,
    text,
    jsonb,
    text
  )
from public, anon;

grant execute on function
  public.set_my_module_preference(
    uuid,
    text,
    text,
    jsonb,
    text
  )
to authenticated, service_role;


commit;
