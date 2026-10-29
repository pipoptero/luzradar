-- A user may request a fixed test only for their own linked channel and household.
create function public.request_notification_test(target uuid,channel_name text) returns uuid language plpgsql security definer set search_path=public,pg_temp as $$
declare prefs jsonb; event_id uuid; event_key text; user_id uuid:=auth.uid();today date:=(now() at time zone 'Europe/Madrid')::date;begin
 if user_id is null or channel_name not in ('push','telegram') or not public.is_household_member(target) then raise exception 'invalid request';end if;
 perform pg_advisory_xact_lock(hashtext('luzradar-notification-test'),hashtext(user_id::text));
 select preferences into prefs from public.notification_preferences where household_id=target and notification_preferences.user_id=user_id;
 if prefs is null or prefs->>'enabled' is distinct from 'true' or not (case when jsonb_typeof(prefs->'channels')='array' then (prefs->'channels') ? channel_name else prefs->>'channel'=channel_name end) then raise exception 'channel not enabled';end if;
 if channel_name='push' and not exists(select 1 from public.push_subscriptions s where s.user_id=user_id and s.household_id=target) then raise exception 'channel not linked';end if;
 if channel_name='telegram' and not exists(select 1 from public.telegram_connections t where t.user_id=user_id and t.household_id=target) then raise exception 'channel not linked';end if;
 if (select count(*) from public.notification_events e join public.notification_deliveries d on d.event_id=e.id where e.kind='test' and d.user_id=user_id and e.scheduled_at>now()-interval '1 hour')>=3 then raise exception 'test rate limit';end if;
 event_id:=gen_random_uuid();event_key:=target::text||':test:'||today::text||':'||gen_random_uuid()::text||':'||user_id::text;
 insert into public.notification_events(id,household_id,event_key,kind,scheduled_at,expires_at,payload) values(event_id,target,event_key,'test',now()+interval '15 seconds',now()+interval '10 minutes',jsonb_build_object('message','Este es un aviso de prueba de LuzRadar.'));
 insert into public.notification_deliveries(event_key,event_id,user_id,channel,state) values(event_key,event_id,user_id,channel_name,'pending');return event_id;
end $$;
revoke all on function public.request_notification_test(uuid,text) from public,anon;
grant execute on function public.request_notification_test(uuid,text) to authenticated;
