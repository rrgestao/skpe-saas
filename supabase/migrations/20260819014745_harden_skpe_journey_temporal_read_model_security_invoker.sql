-- ============================================================
-- SK-PE-CONT-01
-- 17-B.5C - Hardening do contrato de leitura temporal governada
-- Correcao validada transacionalmente: SECURITY INVOKER
-- ============================================================

alter function public.get_skpe_journey_temporal_read_model(uuid, uuid, date)
  security invoker;

revoke all on function public.get_skpe_journey_temporal_read_model(uuid, uuid, date) from public;
revoke all on function public.get_skpe_journey_temporal_read_model(uuid, uuid, date) from anon;
grant execute on function public.get_skpe_journey_temporal_read_model(uuid, uuid, date) to authenticated;
grant execute on function public.get_skpe_journey_temporal_read_model(uuid, uuid, date) to service_role;