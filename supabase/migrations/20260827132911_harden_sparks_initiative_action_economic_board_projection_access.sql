revoke all on function public.get_sparks_initiative_action_board(uuid) from public, anon, authenticated;
grant execute on function public.get_sparks_initiative_action_board(uuid) to authenticated, service_role;
