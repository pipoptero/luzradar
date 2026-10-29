import {PGlite} from '@electric-sql/pglite';
import {pgcrypto} from '@electric-sql/pglite/contrib/pgcrypto';
import {pgtap} from '@electric-sql/pglite-pgtap';
import {readFile,readdir} from 'node:fs/promises';
const db=await PGlite.create({extensions:{pgcrypto,pgtap}});
try{
 await db.exec(`create role anon nologin;create role authenticated nologin;create role service_role nologin bypassrls;create schema auth;create schema extensions;grant usage on schema extensions to anon,authenticated,service_role;create table auth.users(id uuid primary key,email text,email_confirmed_at timestamptz);create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema auth to anon,authenticated,service_role;grant execute on function auth.uid() to anon,authenticated,service_role;`);
 for(const file of (await readdir('supabase/migrations')).filter(x=>x.endsWith('.sql')).sort()){console.log(`Aplicando ${file}`);let sql=await readFile('supabase/migrations/'+file,'utf8');if(file==='202610280022_redata_pg_net.sql'){await db.exec(`create schema net;create table net._http_response(id bigint,status_code integer,content text,timed_out boolean);create function net.http_get(url text,params jsonb,timeout_milliseconds integer) returns bigint language sql as $$select 1::bigint$$;`);sql=sql.replace('create extension if not exists pg_net with schema extensions;','');console.log('pg_net sustituido por stub solo en PGlite; red real se prueba en Supabase Local.')}await db.exec(sql);}
 await db.exec('create extension if not exists pgtap with schema extensions');
 let total=0,failures=0;
 for(const suite of ['family_rls.sql','access_rls.sql','queue_prices.sql','channels_rls.sql','economy_rpc.sql','import_rpc.sql','webhook_throttle.sql','reconcile.sql','security_rpc.sql','security_surface.sql','redata_fallback.sql']){const sql=await readFile('supabase/tests/'+suite,'utf8');const results=await db.exec(sql);let checks=0;for(const result of results)for(const row of result.rows??[]){const text=Object.values(row).map(String).join(' ');if(/^not ok/.test(text))failures++;if(/^ok\s/.test(text))checks++;if(/^not ok|^ok\s|^1\.\./.test(text))console.log(text)}total+=checks;}
 console.log(`PGlite PostgreSQL+Auth simulado: ${total} aserciones, ${failures} fallos.`);if(failures||total!==95)process.exitCode=1;
}catch(error){console.error('FAIL migraciones o suite PGlite:',error instanceof Error?error.message:'error desconocido');process.exitCode=1}finally{await db.close()}
