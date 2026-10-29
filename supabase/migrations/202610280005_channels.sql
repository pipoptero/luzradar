-- Local candidate: notification channel registration and atomic price publication.
alter table public.push_subscriptions add column household_id uuid references public.households(id) on delete cascade;
alter table public.push_subscriptions add column endpoint text;
create unique index push_unique_endpoint on public.push_subscriptions(endpoint);
create function public.register_push_subscription(target uuid, subscription_data jsonb) returns void language plpgsql security definer set search_path=public,pg_temp as $$
declare endpoint_value text; begin
 endpoint_value:=subscription_data->>'endpoint';
 if auth.uid() is null or not public.is_household_member(target) or endpoint_value !~ '^https://' or length(endpoint_value)>2048 or coalesce(subscription_data->'keys'->>'p256dh','')='' or coalesce(subscription_data->'keys'->>'auth','')='' then raise exception 'invalid subscription';end if;
 insert into public.push_subscriptions(user_id,household_id,endpoint,subscription) values(auth.uid(),target,endpoint_value,subscription_data)
 on conflict(endpoint) do update set subscription=excluded.subscription,household_id=excluded.household_id where public.push_subscriptions.user_id=auth.uid();
 if not found then raise exception 'subscription already owned';end if;
end $$;
revoke all on function public.register_push_subscription(uuid,jsonb) from public,anon;grant execute on function public.register_push_subscription(uuid,jsonb) to authenticated;
create function public.remove_push_subscription(endpoint_value text) returns void language sql security definer set search_path=public,pg_temp as $$ delete from public.push_subscriptions where endpoint=endpoint_value and user_id=auth.uid() $$;
revoke all on function public.remove_push_subscription(text) from public,anon;grant execute on function public.remove_push_subscription(text) to authenticated;
create table public.telegram_link_nonces(id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id),household_id uuid not null references public.households(id) on delete cascade,token_hash bytea not null unique,expires_at timestamptz not null,consumed_at timestamptz);
alter table public.telegram_link_nonces enable row level security; revoke all on public.telegram_link_nonces from public,anon,authenticated;
alter table public.telegram_connections add column household_id uuid references public.households(id) on delete cascade;
create function public.issue_telegram_nonce(target uuid) returns text language plpgsql security definer set search_path=public,extensions,pg_temp as $$ declare token text; begin if auth.uid() is null or not public.is_household_member(target) then raise exception 'invalid request';end if;token:=encode(gen_random_bytes(24),'hex');insert into public.telegram_link_nonces(user_id,household_id,token_hash,expires_at) values(auth.uid(),target,digest(token,'sha256'),now()+interval '10 minutes');return token;end $$;
revoke all on function public.issue_telegram_nonce(uuid) from public,anon;grant execute on function public.issue_telegram_nonce(uuid) to authenticated;
create function public.consume_telegram_nonce(token text,chat text) returns boolean language plpgsql security definer set search_path=public,extensions,pg_temp as $$ declare n public.telegram_link_nonces%rowtype;begin if token !~ '^[0-9a-f]{48}$' or chat !~ '^-?[0-9]{1,24}$' then return false;end if;select * into n from public.telegram_link_nonces where token_hash=digest(token,'sha256') and consumed_at is null and expires_at>now() for update;if not found or not exists(select 1 from public.household_memberships where household_id=n.household_id and user_id=n.user_id and active) then return false;end if;insert into public.telegram_connections(user_id,household_id,chat_id) values(n.user_id,n.household_id,chat) on conflict(user_id) do update set household_id=excluded.household_id,chat_id=excluded.chat_id,created_at=now();update public.telegram_link_nonces set consumed_at=now() where id=n.id;return true;end $$;
revoke all on function public.consume_telegram_nonce(text,text) from public,anon,authenticated;grant execute on function public.consume_telegram_nonce(text,text) to service_role;
create function public.unlink_telegram(target uuid) returns void language plpgsql security definer set search_path=public,pg_temp as $$ begin if auth.uid() is null or not public.is_household_member(target) then raise exception 'invalid request';end if;delete from public.telegram_connections where user_id=auth.uid() and household_id=target;end $$;
revoke all on function public.unlink_telegram(uuid) from public,anon;grant execute on function public.unlink_telegram(uuid) to authenticated;
