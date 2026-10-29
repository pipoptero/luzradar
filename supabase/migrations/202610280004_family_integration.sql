-- Incremento local candidato: ejecutar únicamente en Supabase local antes de revisión de seguridad.
alter table public.household_invitations alter column email drop not null;
alter table public.household_invitations add column revoked_at timestamptz;
create function public.create_invite_code(target uuid) returns text language plpgsql security definer set search_path=public,extensions,pg_temp as $$
declare token text; begin
 if auth.uid() is null or not public.is_household_owner(target) then raise exception 'invalid request'; end if;
 token:=encode(gen_random_bytes(32),'hex');
 insert into public.household_invitations(household_id,token_hash,expires_at,created_by) values(target,digest(token,'sha256'),now()+interval '24 hours',auth.uid());
 return token;
end $$;
revoke all on function public.create_invite_code(uuid) from public,anon; grant execute on function public.create_invite_code(uuid) to authenticated;
create function public.accept_invite_code(token text) returns uuid language plpgsql security definer set search_path=public,extensions,pg_temp as $$
declare inv public.household_invitations%rowtype; begin
 if auth.uid() is null or token !~ '^[0-9a-f]{64}$' then raise exception 'invalid invitation'; end if;
 select * into inv from public.household_invitations where token_hash=digest(token,'sha256') and accepted_at is null and revoked_at is null and expires_at>now() for update;
 if not found then raise exception 'invalid invitation'; end if;
 insert into public.household_memberships(household_id,user_id,role,active) values(inv.household_id,auth.uid(),'member',true)
 on conflict(household_id,user_id) do update set active=true;
 update public.household_invitations set accepted_at=now() where id=inv.id;
 return inv.household_id;
end $$;
revoke all on function public.accept_invite_code(text) from public,anon; grant execute on function public.accept_invite_code(text) to authenticated;
-- Do not permit client-side reassignment of ownership, tenant or actor IDs.
create function public.prevent_plan_reassignment() returns trigger language plpgsql set search_path=public,pg_temp as $$ begin
 if new.household_id is distinct from old.household_id or new.created_by is distinct from old.created_by then raise exception 'immutable ownership'; end if;return new;end $$;
create trigger plan_immutable before update on public.plans for each row execute function public.prevent_plan_reassignment();
create function public.prevent_usage_reassignment() returns trigger language plpgsql set search_path=public,pg_temp as $$ begin
 if new.household_id is distinct from old.household_id or new.confirmed_by is distinct from old.confirmed_by or new.plan_id is distinct from old.plan_id then raise exception 'immutable ownership';end if;return new;end $$;
create trigger usage_immutable before update on public.usage_logs for each row execute function public.prevent_usage_reassignment();
create function public.prevent_appliance_reassignment() returns trigger language plpgsql set search_path=public,pg_temp as $$ begin if new.household_id is distinct from old.household_id then raise exception 'immutable ownership';end if;return new;end $$;
create trigger appliance_immutable before update on public.appliances for each row execute function public.prevent_appliance_reassignment();
revoke all on public.households,public.household_memberships,public.household_invitations,public.appliances,public.plans,public.usage_logs,public.notification_preferences,public.push_subscriptions,public.telegram_connections,public.notification_events,public.notification_deliveries from anon;
grant select on public.households,public.household_memberships to authenticated;
grant select,insert,update,delete on public.appliances to authenticated;
grant select,insert,update on public.plans,public.usage_logs to authenticated;
grant select,insert,update,delete on public.notification_preferences to authenticated;
revoke all on public.household_invitations,public.push_subscriptions,public.telegram_connections,public.notification_events,public.notification_deliveries from authenticated;
