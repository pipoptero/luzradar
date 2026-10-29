alter table public.plan_audit_events drop constraint plan_audit_events_action_check;
alter table public.plan_audit_events add constraint plan_audit_events_action_check check(action in ('created','confirmed','cancelled','imported','reconciled'));
