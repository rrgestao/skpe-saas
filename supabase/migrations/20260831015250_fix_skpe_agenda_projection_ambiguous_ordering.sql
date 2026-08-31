do $$
declare
  fn text;
  patched text;
  old_tail text := E'  select * from review_items\n  union all\n  select * from initiative_items\n  union all\n  select * from action_items\n  order by coalesce(starts_at, due_at), title, agenda_item_key;';
  new_tail text := E'  select *\n  from (\n    select * from review_items\n    union all\n    select * from initiative_items\n    union all\n    select * from action_items\n  ) composed\n  order by\n    coalesce(composed.starts_at, composed.due_at),\n    composed.title,\n    composed.agenda_item_key;';
begin
  fn := pg_get_functiondef(
    'public.get_my_skpe_agenda_projection(uuid,date,date,boolean,boolean)'::regprocedure
  );

  patched := replace(fn, old_tail, new_tail);

  if patched = fn then
    raise exception 'Anchor do ORDER BY ambiguo de get_my_skpe_agenda_projection nao encontrado.';
  end if;

  execute patched;
end;
$$;
