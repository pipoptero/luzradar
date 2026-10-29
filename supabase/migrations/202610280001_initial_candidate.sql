-- Candidate schema only. Requires authenticated Supabase runtime and RLS tests before use.
create extension if not exists pgcrypto;
create table public.households(id uuid primary key default gen_random_uuid(), name text not null, owner_id uuid not null references auth.users(id), created_at timestamptz not null default now());
create table public.household_memberships(household_id uuid not null references public.households(id) on delete cascade, user_id uuid not null references auth.users(id), role text not null check(role in ('owner','member')), active boolean not null default true, primary key(household_id,user_id));
create function public.is_household_member(target uuid) returns boolean language sql stable security definer set search_path = public, pg_temp as $$ select exists(select 1 from public.household_memberships where household_id=target and user_id=auth.uid() and active) $$;
revoke all on function public.is_household_member(uuid) from public;
grant execute on function public.is_household_member(uuid) to authenticated;
create table public.appliances(id uuid primary key default gen_random_uuid(),household_id uuid not null references public.households(id) on delete cascade,name text not null,duration_minutes integer not null check(duration_minutes between 15 and 1440),energy_kwh numeric not null check(energy_kwh>0));
create table public.plans(id uuid primary key default gen_random_uuid(),household_id uuid not null references public.households(id) on delete cascade,created_by uuid not null references auth.users(id),snapshot jsonb not null,created_at timestamptz not null default now());
create table public.usage_logs(id uuid primary key default gen_random_uuid(),household_id uuid not null references public.households(id) on delete cascade,plan_id uuid unique references public.plans(id),confirmed_by uuid not null references auth.users(id),snapshot jsonb not null,created_at timestamptz not null default now());
create table public.notification_preferences(id uuid primary key default gen_random_uuid(),household_id uuid not null references public.households(id) on delete cascade,user_id uuid not null references auth.users(id),preferences jsonb not null default '{}'::jsonb);
create table public.push_subscriptions(id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id),subscription jsonb not null);
create table public.telegram_connections(user_id uuid primary key references auth.users(id),chat_id text not null,created_at timestamptz not null default now());
create table public.notification_deliveries(id uuid primary key default gen_random_uuid(),event_key text not null,user_id uuid not null references auth.users(id),channel text not null,state text not null,unique(event_key,user_id,channel));
alter table public.households enable row level security; alter table public.household_memberships enable row level security; alter table public.appliances enable row level security; alter table public.plans enable row level security; alter table public.usage_logs enable row level security; alter table public.notification_preferences enable row level security; alter table public.push_subscriptions enable row level security; alter table public.telegram_connections enable row level security; alter table public.notification_deliveries enable row level security;
create policy household_read on public.households for select to authenticated using (public.is_household_member(id));
create policy memberships_read on public.household_memberships for select to authenticated using (public.is_household_member(household_id));
create policy appliances_member on public.appliances for all to authenticated using (public.is_household_member(household_id)) with check (public.is_household_member(household_id));
create policy plans_read on public.plans for select to authenticated using (public.is_household_member(household_id));
create policy plans_insert on public.plans for insert to authenticated with check (created_by=auth.uid() and public.is_household_member(household_id));
create policy usage_read on public.usage_logs for select to authenticated using (public.is_household_member(household_id));
create policy usage_insert on public.usage_logs for insert to authenticated with check (confirmed_by=auth.uid() and public.is_household_member(household_id));
create policy preferences_self on public.notification_preferences for all to authenticated using (user_id=auth.uid() and public.is_household_member(household_id)) with check (user_id=auth.uid() and public.is_household_member(household_id));
-- No client policies on subscriptions, Telegram, deliveries or membership administration: deny by default until privileged workflows are built and tested.
