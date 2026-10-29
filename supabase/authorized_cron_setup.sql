-- Run only in an authorized project after setting Vault secrets explicitly.
-- Required Vault names: luzradar_project_url, luzradar_service_jwt, luzradar_cron_secret.
-- luzradar_service_jwt may hold the public anon JWT for the gateway; the separate
-- cron secret authenticates the caller and the Edge runtime uses its own server key.
-- pg_net temporarily stores request headers in its queue: restrict DB login and review provider guidance.
create extension if not exists pg_cron;
create extension if not exists pg_net with schema extensions;
do $$begin
 if not exists(select 1 from vault.decrypted_secrets where name='luzradar_project_url') or not exists(select 1 from vault.decrypted_secrets where name='luzradar_service_jwt') or not exists(select 1 from vault.decrypted_secrets where name='luzradar_cron_secret') then raise exception 'Required Vault secrets not configured';end if;
 perform cron.schedule('luzradar-jobs','*/5 * * * *',$cron$select net.http_post(url:=(select decrypted_secret from vault.decrypted_secrets where name='luzradar_project_url')||'/functions/v1/luzradar-jobs',headers:=jsonb_build_object('Content-Type','application/json','Authorization','Bearer '||(select decrypted_secret from vault.decrypted_secrets where name='luzradar_service_jwt'),'x-luzradar-secret',(select decrypted_secret from vault.decrypted_secrets where name='luzradar_cron_secret')),body:='{}'::jsonb);$cron$);
end$$;
