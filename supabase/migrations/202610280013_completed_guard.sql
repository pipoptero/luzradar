-- A completed cycle must have ended, including imported histories.
create function public.enforce_completed_cycle() returns trigger language plpgsql set search_path=public,pg_temp as $$
begin
 if new.snapshot->>'status'='completed' and ((new.snapshot->>'actualStart') is null or (new.snapshot->>'minutes') is null or (new.snapshot->>'actualStart')::timestamptz + make_interval(mins=>(new.snapshot->>'minutes')::integer)>now()) then raise exception 'cycle has not completed';end if;return new;
end $$;
create trigger completed_cycle_guard before insert or update on public.plans for each row execute function public.enforce_completed_cycle();
