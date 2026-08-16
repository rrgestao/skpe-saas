-- Executar somente após migration aprovada. Não foi executado automaticamente.
begin;
do $$ declare r record; v_actor uuid; begin
  for r in select * from public.skpe_projects where archived_at is null loop
    select coalesce(r.updated_by,r.created_by,(select actor_user_id from public.skpe_journey_audit a where a.project_id=r.id order by occurred_at desc limit 1)) into v_actor;
    if v_actor is null then raise exception 'Projeto % sem ator auditável; backfill interrompido.',r.id; end if;
    perform public.skpe_recalculate_journey_project_internal(r.id,'Backfill governado do progresso físico hierárquico.',v_actor);
  end loop;
end $$;
select id,code,progress,current_phase_code from public.skpe_projects where archived_at is null order by code;
commit;