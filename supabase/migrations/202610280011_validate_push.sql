-- Limit push subscriptions to supported providers and correctly sized Web Push keys.
create or replace function public.register_push_subscription(target uuid,subscription_data jsonb) returns void language plpgsql security definer set search_path=public,pg_temp as $$
declare endpoint_value text;public_key text;auth_key text;begin
 endpoint_value:=subscription_data->>'endpoint';public_key:=subscription_data->'keys'->>'p256dh';auth_key:=subscription_data->'keys'->>'auth';
 if auth.uid() is null or not public.is_household_member(target) or endpoint_value is null or length(endpoint_value)>2048 or endpoint_value !~ '^https://(fcm\.googleapis\.com|updates\.push\.services\.mozilla\.com|[a-z0-9.-]+\.push\.apple\.com)(/|$)' or coalesce(public_key,'') !~ '^B[A-Za-z0-9_-]{86}$' or coalesce(auth_key,'') !~ '^[A-Za-z0-9_-]{22}$' then raise exception 'invalid subscription';end if;
 insert into public.push_subscriptions(user_id,household_id,endpoint,subscription) values(auth.uid(),target,endpoint_value,subscription_data)
 on conflict(endpoint) do update set subscription=excluded.subscription,household_id=excluded.household_id where public.push_subscriptions.user_id=auth.uid();
 if not found then raise exception 'subscription already owned';end if;
end $$;
revoke all on function public.register_push_subscription(uuid,jsonb) from public,anon;grant execute on function public.register_push_subscription(uuid,jsonb) to authenticated;
