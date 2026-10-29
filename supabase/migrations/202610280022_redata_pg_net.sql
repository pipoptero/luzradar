-- Fixed-origin fallback for REData when Edge egress fails. Only the server role can invoke it.
create extension if not exists pg_net with schema extensions;
create table public.redata_ingest_requests(request_id bigint primary key,date_local date not null,created_at timestamptz not null default now());
alter table public.redata_ingest_requests enable row level security;
revoke all on public.redata_ingest_requests from public,anon,authenticated;
grant all on public.redata_ingest_requests to service_role;
create function public.request_redata_day(day_date date) returns bigint language plpgsql security definer set search_path=public,extensions,pg_temp as $$
declare today date:=(now() at time zone 'Europe/Madrid')::date;request_id bigint;begin
 if day_date is null or day_date<today-1 or day_date>today+1 then raise exception 'invalid date';end if;
 perform pg_advisory_xact_lock(hashtext('luzradar-redata'),day_date-date '2000-01-01');
 delete from public.redata_ingest_requests where created_at<now()-interval '2 days';
 select r.request_id into request_id from public.redata_ingest_requests r where r.date_local=day_date and r.created_at>now()-interval '1 minute' order by r.created_at desc limit 1;
 if request_id is not null then return request_id;end if;
 select net.http_get(url:='https://apidatos.ree.es/es/datos/mercados/precios-mercados-tiempo-real',params:=jsonb_build_object('start_date',day_date::text||'T00:00','end_date',day_date::text||'T23:59','time_trunc','hour','geo_trunc','electric_system','geo_limit','peninsular','geo_ids','8741'),timeout_milliseconds:=15000) into request_id;
 insert into public.redata_ingest_requests(request_id,date_local) values(request_id,day_date);return request_id;
end $$;
create function public.read_redata_response(target bigint) returns jsonb language sql stable security definer set search_path=public,extensions,pg_temp as $$
 select jsonb_build_object('status',r.status_code,'body',case when octet_length(r.content)<=1048576 then r.content else null end,'timedOut',r.timed_out) from net._http_response r join public.redata_ingest_requests q on q.request_id=r.id where q.request_id=target and q.created_at>now()-interval '2 days'
$$;
revoke all on function public.request_redata_day(date),public.read_redata_response(bigint) from public,anon,authenticated;
grant execute on function public.request_redata_day(date),public.read_redata_response(bigint) to service_role;
