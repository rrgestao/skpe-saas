do $$
declare
  fn text;
  patched text;
begin
  fn := pg_get_functiondef('public.get_my_skpe_pending_items(uuid,uuid,uuid)'::regprocedure);

  patched := replace(
    fn,
    'checklist_public.skpe_work_scope_allows_user(target_organization_id, item.responsible_user_id)',
    'public.skpe_work_scope_allows_user(target_organization_id, checklist_item.responsible_user_id)'
  );

  if patched = fn then
    if position(
      'public.skpe_work_scope_allows_user(target_organization_id, checklist_item.responsible_user_id)'
      in fn
    ) > 0 then
      return;
    end if;

    raise exception 'Anchor corrompido de get_my_skpe_pending_items não encontrado.';
  end if;

  execute patched;
end;
$$;