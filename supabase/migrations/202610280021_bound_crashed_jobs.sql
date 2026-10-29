-- Expired leases and retries stop after five claims, including worker crashes.
create or replace function public.claim_notification_deliveries(batch_size integer default 20) returns setof public.notification_deliveries language sql security definer set search_path=public,pg_temp as $$
  with exhausted as (
    update public.notification_deliveries set state='failed',lease_until=null,next_retry_at=null,last_error_code='attempts_exhausted'
    where state in ('pending','retry','processing') and attempt_count>=5 and (lease_until is null or lease_until<now()) returning id
  ), picked as (
    select d.id from public.notification_deliveries d join public.notification_events e on e.id=d.event_id
    join public.household_memberships m on m.household_id=e.household_id and m.user_id=d.user_id and m.active
    where d.state in ('pending','retry','processing') and d.attempt_count<5 and e.scheduled_at<=now() and e.expires_at>now()
      and coalesce(d.next_retry_at,'-infinity'::timestamptz)<=now() and (d.lease_until is null or d.lease_until<now())
    order by e.scheduled_at for update of d skip locked limit greatest(1,least(batch_size,100))
  ) update public.notification_deliveries d set state='processing',lease_until=now()+interval '2 minutes',attempt_count=attempt_count+1
  from picked where d.id=picked.id returning d.*
$$;
