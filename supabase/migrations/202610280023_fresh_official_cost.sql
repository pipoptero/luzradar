-- Current and future cycles require recently validated official prices.
create or replace function public.authoritative_cycle_cost(start_at timestamptz, minutes integer, energy numeric) returns numeric language plpgsql stable security definer set search_path=public,pg_temp as $$
declare result numeric; covered tstzmultirange;expected tstzrange;covered_seconds numeric;begin
 if start_at is null or minutes is null or minutes not between 15 and 1440 or energy is null or energy<=0 or energy>10000 then raise exception 'invalid cycle';end if;
 expected:=tstzrange(start_at,start_at+make_interval(mins=>minutes),'[)');
 select range_agg(tstzrange(greatest(i.start_utc,start_at),least(i.end_utc,start_at+make_interval(mins=>minutes)),'[)')),sum(extract(epoch from least(i.end_utc,start_at+make_interval(mins=>minutes))-greatest(i.start_utc,start_at))),sum(extract(epoch from least(i.end_utc,start_at+make_interval(mins=>minutes))-greatest(i.start_utc,start_at))*i.price_eur_kwh)*energy/(minutes*60)
 into covered,covered_seconds,result from public.pvpc_intervals i join public.pvpc_days d on d.id=i.day_id where d.source='REData' and i.start_utc<upper(expected) and i.end_utc>lower(expected) and ((i.start_utc at time zone 'Europe/Madrid')::date<(now() at time zone 'Europe/Madrid')::date or d.validated_at>=now()-interval '6 hours');
 if covered is distinct from tstzmultirange(expected) or covered_seconds<>minutes*60 or result is null then raise exception 'missing or overlapping official prices';end if;return result;
end $$;
