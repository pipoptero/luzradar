-- Disambiguate local identifiers from similarly named table columns.
create or replace function public.request_notification_test(target uuid,channel_name text) returns uuid language plpgsql security definer set search_path=public,pg_temp as $$
declare v_prefs jsonb; v_event uuid; v_key text; v_actor uuid:=auth.uid();v_day date:=(now() at time zone 'Europe/Madrid')::date;begin
 if v_actor is null or channel_name not in ('push','telegram') or not public.is_household_member(target) then raise exception 'invalid request';end if;
 perform pg_advisory_xact_lock(hashtext('luzradar-notification-test'),hashtext(v_actor::text));
 select preferences into v_prefs from public.notification_preferences where household_id=target and user_id=v_actor;
 if v_prefs is null or v_prefs->>'enabled' is distinct from 'true' or not (case when jsonb_typeof(v_prefs->'channels')='array' then (v_prefs->'channels') ? channel_name else v_prefs->>'channel'=channel_name end) then raise exception 'channel not enabled';end if;
 if channel_name='push' and not exists(select 1 from public.push_subscriptions s where s.user_id=v_actor and s.household_id=target) then raise exception 'channel not linked';end if;
 if channel_name='telegram' and not exists(select 1 from public.telegram_connections t where t.user_id=v_actor and t.household_id=target) then raise exception 'channel not linked';end if;
 if (select count(*) from public.notification_events e join public.notification_deliveries d on d.event_id=e.id where e.kind='test' and d.user_id=v_actor and e.scheduled_at>now()-interval '1 hour')>=3 then raise exception 'test rate limit';end if;
 v_event:=gen_random_uuid();v_key:=target::text||':test:'||v_day::text||':'||gen_random_uuid()::text||':'||v_actor::text;
 insert into public.notification_events(id,household_id,event_key,kind,scheduled_at,expires_at,payload) values(v_event,target,v_key,'test',now()+interval '15 seconds',now()+interval '10 minutes',jsonb_build_object('message','Este es un aviso de prueba de LuzRadar.'));
 insert into public.notification_deliveries(event_key,event_id,user_id,channel,state) values(v_key,v_event,v_actor,channel_name,'pending');return v_event;
end $$;
