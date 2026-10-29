-- Server-authoritative economic calculations; apply only after local security tests.
create table public.plan_audit_events(id uuid primary key default gen_random_uuid(),household_id uuid not null references public.households(id),plan_id uuid not null references public.plans(id),actor_id uuid not null references auth.users(id),action text not null check(action in ('created','confirmed','cancelled')),occurred_at timestamptz not null default now(),snapshot jsonb not null);
alter table public.plan_audit_events enable row level security;
revoke all on public.plan_audit_events from public,anon,authenticated;
grant all on public.plan_audit_events to service_role;
create function public.authoritative_cycle_cost(start_at timestamptz, minutes integer, energy numeric) returns numeric language plpgsql stable security definer set search_path=public,pg_temp as $$
declare result numeric; covered tstzmultirange; expected tstzrange; begin
 if start_at is null or minutes is null or minutes not between 15 and 1440 or energy is null or energy<=0 or energy>10000 then raise exception 'invalid cycle';end if;
 expected:=tstzrange(start_at,start_at+make_interval(mins=>minutes),'[)');
 select range_agg(tstzrange(greatest(i.start_utc,start_at),least(i.end_utc,start_at+make_interval(mins=>minutes)),'[)')),sum(extract(epoch from least(i.end_utc,start_at+make_interval(mins=>minutes))-greatest(i.start_utc,start_at))*i.price_eur_kwh)*energy/(minutes*60)
 into covered,result from public.pvpc_intervals i join public.pvpc_days d on d.id=i.day_id where d.source='REData' and i.start_utc<upper(expected) and i.end_utc>lower(expected);
 if covered is distinct from tstzmultirange(expected) or result is null then raise exception 'missing official prices';end if;return result;
end $$;
revoke all on function public.authoritative_cycle_cost(timestamptz,integer,numeric) from public,anon,authenticated;
create function public.create_official_plan(target uuid, appliance uuid, start_at timestamptz, requested_id uuid default null) returns uuid language plpgsql security definer set search_path=public,pg_temp as $$
declare a public.appliances%rowtype; result uuid; actual_cost numeric; baseline_cost numeric; baseline_at timestamptz:=now(); snapshot jsonb; existing public.plans%rowtype;begin
 if auth.uid() is null or not public.is_household_member(target) or start_at is null or start_at<now() then raise exception 'invalid request';end if;
 select * into a from public.appliances where id=appliance and household_id=target;
 if not found then raise exception 'invalid appliance';end if;
 if requested_id is not null then select * into existing from public.plans where id=requested_id;if found then if existing.household_id=target and existing.created_by=auth.uid() then return existing.id;end if;raise exception 'invalid request';end if;end if;
 actual_cost:=public.authoritative_cycle_cost(start_at,a.duration_minutes,a.energy_kwh);
 begin baseline_cost:=public.authoritative_cycle_cost(baseline_at,a.duration_minutes,a.energy_kwh);exception when raise_exception then baseline_cost:=null;end;
 result:=coalesce(requested_id,gen_random_uuid());snapshot:=jsonb_build_object('id',result,'applianceId',a.id,'name',a.name,'start',start_at,'end',start_at+make_interval(mins=>a.duration_minutes),'minutes',a.duration_minutes,'energy',a.energy_kwh::text,'cost',actual_cost::text,'baseline',case when baseline_cost is null then null else baseline_cost::text end,'baselineStart',case when baseline_cost is null then null else baseline_at end,'status','planned','createdAt',now(),'source','REData');
 insert into public.plans(id,household_id,created_by,snapshot) values(result,target,auth.uid(),snapshot);
 insert into public.plan_audit_events(household_id,plan_id,actor_id,action,snapshot) values(target,result,auth.uid(),'created',snapshot);return result;
end $$;
revoke all on function public.create_official_plan(uuid,uuid,timestamptz,uuid) from public,anon;grant execute on function public.create_official_plan(uuid,uuid,timestamptz,uuid) to authenticated;
create function public.confirm_official_plan(plan_uuid uuid, actual_start timestamptz) returns void language plpgsql security definer set search_path=public,pg_temp as $$
declare p public.plans%rowtype; s jsonb; cost numeric; begin
 if auth.uid() is null or actual_start is null or actual_start>now() then raise exception 'invalid request';end if;
 select * into p from public.plans where id=plan_uuid for update;
 if not found or not public.is_household_member(p.household_id) then raise exception 'invalid request';end if;
 s:=p.snapshot;if s->>'status'='completed' and (s->>'actualStart')::timestamptz=actual_start then return;end if;
 if s->>'status' not in ('planned','completed') then raise exception 'invalid state';end if;
 cost:=public.authoritative_cycle_cost(actual_start,(s->>'minutes')::integer,(s->>'energy')::numeric);
 s:=s||jsonb_build_object('status','completed','actualStart',actual_start,'actualCost',cost::text,'confirmedBy',auth.uid());
 update public.plans set snapshot=s where id=p.id;
 insert into public.plan_audit_events(household_id,plan_id,actor_id,action,snapshot) values(p.household_id,p.id,auth.uid(),'confirmed',s);
end $$;
revoke all on function public.confirm_official_plan(uuid,timestamptz) from public,anon;grant execute on function public.confirm_official_plan(uuid,timestamptz) to authenticated;
create function public.cancel_official_plan(plan_uuid uuid) returns void language plpgsql security definer set search_path=public,pg_temp as $$
declare p public.plans%rowtype;s jsonb;begin
 if auth.uid() is null then raise exception 'invalid request';end if;select * into p from public.plans where id=plan_uuid for update;
 if not found or not public.is_household_member(p.household_id) then raise exception 'invalid request';end if;
 if p.snapshot->>'status'='cancelled' then return;end if;s:=p.snapshot||jsonb_build_object('status','cancelled');update public.plans set snapshot=s where id=p.id;
 insert into public.plan_audit_events(household_id,plan_id,actor_id,action,snapshot) values(p.household_id,p.id,auth.uid(),'cancelled',s);
end $$;
revoke all on function public.cancel_official_plan(uuid) from public,anon;grant execute on function public.cancel_official_plan(uuid) to authenticated;
revoke insert,update,delete on public.plans,public.usage_logs from authenticated;
