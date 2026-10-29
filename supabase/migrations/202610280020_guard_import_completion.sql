-- Imported uses must have ended, just like direct confirmations.
create or replace function public.import_official_plan(target uuid,appliance uuid,requested_id uuid,planned_start timestamptz,actual_start timestamptz default null) returns uuid language plpgsql security definer set search_path=public,pg_temp as $$
declare a public.appliances%rowtype;p public.plans%rowtype;s jsonb;plan_cost numeric;actual_cost numeric;begin
 if auth.uid() is null or requested_id is null or not public.is_household_member(target) or planned_start is null or (actual_start is null and planned_start<now()) or (actual_start is not null and actual_start>now()) then raise exception 'invalid request';end if;
 select * into p from public.plans where id=requested_id;if found then if p.household_id=target and p.created_by=auth.uid() then return p.id;end if;raise exception 'invalid request';end if;
 select * into a from public.appliances where id=appliance and household_id=target;if not found then raise exception 'invalid appliance';end if;
 if actual_start is not null and actual_start+make_interval(mins=>a.duration_minutes)>now() then raise exception 'cycle not completed';end if;
 plan_cost:=public.authoritative_cycle_cost(planned_start,a.duration_minutes,a.energy_kwh);
 if actual_start is not null then actual_cost:=public.authoritative_cycle_cost(actual_start,a.duration_minutes,a.energy_kwh);end if;
 s:=jsonb_build_object('id',requested_id,'applianceId',a.id,'name',a.name,'start',planned_start,'end',planned_start+make_interval(mins=>a.duration_minutes),'minutes',a.duration_minutes,'energy',a.energy_kwh::text,'cost',plan_cost::text,'baseline',null,'baselineStart',null,'status',case when actual_start is null then 'planned' else 'completed' end,'createdAt',now(),'source','REData','imported',true,'actualStart',actual_start,'actualCost',case when actual_cost is null then null else actual_cost::text end);
 insert into public.plans(id,household_id,created_by,snapshot) values(requested_id,target,auth.uid(),s);insert into public.plan_audit_events(household_id,plan_id,actor_id,action,snapshot) values(target,requested_id,auth.uid(),'imported',s);return requested_id;
end $$;
