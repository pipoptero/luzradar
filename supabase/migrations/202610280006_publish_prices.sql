-- Atomic price publication; this RPC is callable only by the service role.
create function public.publish_pvpc_day(day_date date, source_revision text, rows jsonb) returns uuid language plpgsql security definer set search_path=public,pg_temp as $$
declare begin_at timestamptz;end_at timestamptz; expected integer;result uuid;bad integer;begin
 begin_at:=day_date::timestamp at time zone 'Europe/Madrid';end_at:=(day_date+1)::timestamp at time zone 'Europe/Madrid';expected:=extract(epoch from end_at-begin_at)/3600;
 if jsonb_typeof(rows)<>'array' or jsonb_array_length(rows)<>expected or expected not in (23,24,25) then raise exception 'invalid price day';end if;
 select count(*) into bad from jsonb_array_elements(rows) with ordinality x(item,n) where (item->>'start')::timestamptz<>begin_at+(n-1)*interval '1 hour' or (item->>'end')::timestamptz<>begin_at+n*interval '1 hour' or (item->>'price') !~ '^-?[0-9]+(\.[0-9]+)?$';
 if bad<>0 then raise exception 'invalid price intervals';end if;
 insert into public.pvpc_days(date_local,source,revision,validated_at) values(day_date,'REData',source_revision,now()) on conflict(date_local,source) do update set revision=excluded.revision,validated_at=excluded.validated_at returning id into result;
 delete from public.pvpc_intervals where day_id=result;
 insert into public.pvpc_intervals(day_id,start_utc,end_utc,price_eur_kwh) select result,(item->>'start')::timestamptz,(item->>'end')::timestamptz,(item->>'price')::numeric from jsonb_array_elements(rows) x(item);
 return result;
end $$;
revoke all on function public.publish_pvpc_day(date,text,jsonb) from public,anon,authenticated;grant execute on function public.publish_pvpc_day(date,text,jsonb) to service_role;
