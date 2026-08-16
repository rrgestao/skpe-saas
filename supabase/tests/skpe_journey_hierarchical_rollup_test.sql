-- Teste transacional pós-migration; sempre termina em rollback.
begin;
do $$ declare p uuid; actor uuid; org uuid; actual numeric; begin
  select id into org from public.organizations order by created_at limit 1;
  select id into actor from public.profiles order by created_at limit 1;
  if org is null or actor is null then raise exception 'Fixture básica ausente.'; end if;
  insert into public.skpe_projects(organization_id,code,name,status,progress,created_by,updated_by)
    values(org,'TEST-ROLLUP-'||gen_random_uuid(),'Teste rollup','active',29,actor,actor) returning id into p;
  insert into public.skpe_journey_items(project_id,item_type,code,name,status,progress,display_order,is_mandatory,created_by,updated_by) values
    (p,'macrophase','T-00','M0','completed',100,1,true,actor,actor),
    (p,'macrophase','T-01','M1','completed',100,2,true,actor,actor),
    (p,'macrophase','T-02','M2','in_progress',45,3,true,actor,actor),
    (p,'macrophase','T-03','M3','in_progress',1,4,true,actor,actor),
    (p,'macrophase','T-04','M4','not_started',0,5,true,actor,actor),
    (p,'macrophase','T-05','M5','not_started',0,6,true,actor,actor);
  insert into public.skpe_journey_items(project_id,parent_item_id,item_type,code,name,status,progress,display_order,is_mandatory,created_by,updated_by)
  select p,id,'phase','T-02.'||n,'F'||n,case when n<=2 then 'completed' else 'not_started' end,case when n<=2 then 100 else 0 end,n,true,actor,actor
  from public.skpe_journey_items cross join generate_series(1,5)n where project_id=p and code='T-02';
  insert into public.skpe_journey_items(project_id,parent_item_id,item_type,code,name,status,progress,display_order,is_mandatory,created_by,updated_by)
  select p,id,'phase','T-03.'||n,'F'||n,'not_started',0,n,true,actor,actor
  from public.skpe_journey_items cross join generate_series(1,4)n where project_id=p and code='T-03';
  perform public.skpe_recalculate_journey_project_internal(p,'Teste transacional do rollup hierárquico.',actor);
  select progress into actual from public.skpe_journey_items where project_id=p and code='T-02';
  if actual<>40 then raise exception 'T-02 esperado 40, obtido %',actual; end if;
  select progress into actual from public.skpe_journey_items where project_id=p and code='T-03';
  if actual<>0 then raise exception 'T-03 esperado 0, obtido %',actual; end if;
  select progress into actual from public.skpe_projects where id=p;
  if actual<>40 then raise exception 'Projeto esperado 40, obtido %',actual; end if;
end $$;
rollback;