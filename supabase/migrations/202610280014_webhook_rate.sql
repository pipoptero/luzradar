-- Límite global por minuto para el webhook autenticado; no almacena IP ni contenido.
create table public.telegram_webhook_rate(bucket timestamptz primary key,attempts integer not null check(attempts>0));
alter table public.telegram_webhook_rate enable row level security;
revoke all on public.telegram_webhook_rate from public,anon,authenticated;grant all on public.telegram_webhook_rate to service_role;
create function public.allow_telegram_webhook() returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
declare total integer;begin
delete from public.telegram_webhook_rate where bucket<date_trunc('minute',now())-interval '10 minutes';
insert into public.telegram_webhook_rate(bucket,attempts) values(date_trunc('minute',now()),1) on conflict(bucket) do update set attempts=public.telegram_webhook_rate.attempts+1 returning attempts into total;
return total<=120;end $$;
revoke all on function public.allow_telegram_webhook() from public,anon,authenticated;grant execute on function public.allow_telegram_webhook() to service_role;
