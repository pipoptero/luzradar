-- Explicit grants: private records have no anonymous or PUBLIC access.
revoke all on public.households,public.household_memberships,public.household_invitations,public.appliances,public.plans,public.usage_logs,public.notification_preferences,public.push_subscriptions,public.telegram_connections,public.telegram_link_nonces,public.notification_events,public.notification_deliveries from public,anon;
revoke insert,update,delete on public.pvpc_days,public.pvpc_intervals from public,anon,authenticated;
grant select on public.pvpc_days,public.pvpc_intervals to anon,authenticated;
grant all on public.households,public.household_memberships,public.household_invitations,public.appliances,public.plans,public.usage_logs,public.notification_preferences,public.push_subscriptions,public.telegram_connections,public.telegram_link_nonces,public.notification_events,public.notification_deliveries,public.pvpc_days,public.pvpc_intervals to service_role;
