-- Supabase can grant anon explicitly through default privileges; PUBLIC revocation alone is insufficient.
revoke all on function public.is_household_member(uuid),public.is_household_owner(uuid),public.create_household(text),public.revoke_household_member(uuid,uuid) from anon;
-- V1 uses the expiring opaque-code RPCs. Disable the obsolete email invitation path.
revoke all on function public.create_household_invitation(uuid,text),public.accept_household_invitation(text) from public,anon,authenticated;
