-- Automatic corrections are system actions, not actions by the plan creator.
alter table public.plan_audit_events alter column actor_id drop not null;
create or replace function public.reconcile_official_plans(day_date date) returns integer language plpgsql security definer set search_path=public,pg_temp as $$
declare p public.plans%rowtype; s jsonb; next_cost numeric; baseline numeric; updated integer:=0; from_at timestamptz; until_at timestamptz;
begin
 if day_date is null then raise exception 'invalid date';end if;
 from_at:=day_date::timestamp at time zone 'Europe/Madrid';until_at:=(day_date+1)::timestamp at time zone 'Europe/Madrid';
 for p in select * from public.plans where snapshot->>'source'='REData' and snapshot->>'status'='planned' and (snapshot->>'start')::timestamptz>now() and (snapshot->>'start')::timestamptz<until_at and (snapshot->>'end')::timestamptz>from_at for update loop
  s:=p.snapshot;
  begin
   next_cost:=public.authoritative_cycle_cost((s->>'start')::timestamptz,(s->>'minutes')::integer,(s->>'energy')::numeric);
   baseline:=case when s->>'baselineStart' is null then null else public.authoritative_cycle_cost((s->>'baselineStart')::timestamptz,(s->>'minutes')::integer,(s->>'energy')::numeric) end;
  exception when raise_exception then continue; end;
  if (s->>'cost')::numeric is distinct from next_cost or (s->>'baseline')::numeric is distinct from baseline then
   s:=s||jsonb_build_object('cost',next_cost::text,'baseline',case when baseline is null then null else baseline::text end);
   update public.plans set snapshot=s where id=p.id;
   insert into public.plan_audit_events(household_id,plan_id,actor_id,action,snapshot) values(p.household_id,p.id,null,'reconciled',s);
   updated:=updated+1;
  end if;
 end loop;
 return updated;
end $$;
