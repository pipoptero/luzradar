-- Supabase puede conceder privilegios por defecto; las membresías solo cambian por RPC.
revoke insert,update,delete,truncate,references,trigger on public.households,public.household_memberships from authenticated;
grant select on public.households,public.household_memberships to authenticated;
