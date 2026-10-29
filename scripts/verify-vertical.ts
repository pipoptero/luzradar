import {spawnSync} from 'node:child_process';
import {randomBytes,randomUUID} from 'node:crypto';
import assert from 'node:assert/strict';
import {createClient,type SupabaseClient} from '@supabase/supabase-js';
import {RedataProvider,madridDate} from '../src/data/source';
import {BackendPriceProvider} from '../src/data/backend-prices';
const binary=process.platform==='win32'?'node_modules\\.bin\\supabase.cmd':'node_modules/.bin/supabase';
const status=spawnSync(binary,['status','--output','json'],{encoding:'utf8',shell:process.platform==='win32',timeout:60000});
if(status.status!==0)throw new Error('Supabase Local no disponible');
const config=JSON.parse(status.stdout) as {API_URL:string;ANON_KEY:string;SERVICE_ROLE_KEY:string};
if(!/^http:\/\/(127\.0\.0\.1|localhost):\d+$/.test(config.API_URL))throw new Error('Solo se admite Supabase Local');
const admin=createClient(config.API_URL,config.SERVICE_ROLE_KEY,{auth:{persistSession:false,autoRefreshToken:false}});
const users:string[]=[],homes:string[]=[];let createdPrice:string|undefined;const suffix=randomUUID().slice(0,12);const password=randomBytes(24).toString('base64url');
async function user(label:string):Promise<SupabaseClient>{const client=createClient(config.API_URL,config.ANON_KEY,{auth:{persistSession:false,autoRefreshToken:false}});const r=await client.auth.signUp({email:`luzradar-test-${suffix}-${label}@example.com`,password});if(r.error||!r.data.user||!r.data.session)throw new Error('No se pudo crear sesión de prueba local');users.push(r.data.user.id);return client;}
async function requireOk<T>(r:{data:T;error:{message:string}|null}):Promise<T>{if(r.error)throw new Error('Operación local fallida: '+r.error.message);return r.data;}
try{
 const a=await user('a'),b=await user('b'),c=await user('c');
 const homeA=await requireOk(await a.rpc('create_household',{household_name:'Prueba A'}));homes.push(homeA);
 const homeC=await requireOk(await c.rpc('create_household',{household_name:'Prueba C'}));homes.push(homeC);
 const code=await requireOk(await a.rpc('create_invite_code',{target:homeA}));await requireOk(await b.rpc('accept_invite_code',{token:code}));
 assert((await b.rpc('accept_invite_code',{token:code})).error,'Un código no debe reutilizarse');
 const nonce=await requireOk(await b.rpc('issue_telegram_nonce',{target:homeA}));const testChat='987654321';
 const webhook=async(secret:string)=>fetch(`${config.API_URL}/functions/v1/telegram-webhook`,{method:'POST',headers:{'content-type':'application/json','x-telegram-bot-api-secret-token':secret},body:JSON.stringify({message:{text:`/start ${nonce}`,chat:{id:testChat,type:'private'}}})});
 assert.equal((await webhook('incorrect')).status,403);assert.equal((await webhook('luzradar-local-test-webhook-only')).status,200);assert.equal((await webhook('luzradar-local-test-webhook-only')).status,200);
 const telegram=await requireOk(await admin.from('telegram_connections').select('chat_id').eq('user_id',(await b.auth.getUser()).data.user!.id));assert(telegram);assert.equal(telegram.length,1);assert.equal(telegram[0].chat_id,testChat);
 const subscription={endpoint:'https://fcm.googleapis.com/luzradar-local-fixture',keys:{p256dh:'B'+'A'.repeat(86),auth:'A'.repeat(22)}};await requireOk(await b.rpc('register_push_subscription',{target:homeA,subscription_data:subscription}));await requireOk(await b.rpc('remove_push_subscription',{endpoint_value:subscription.endpoint}));

 const aSession=await a.auth.getUser();assert(aSession.data.user);const bSession=await b.auth.getUser();assert(bSession.data.user);const cSession=await c.auth.getUser();assert(cSession.data.user);
 const appliance=await requireOk(await a.from('appliances').insert({household_id:homeA,name:'Prueba local',duration_minutes:15,energy_kwh:1}).select('id').single());assert(appliance);
 assert.equal((await requireOk(await b.from('appliances').select('id').eq('household_id',homeA)))?.length,1);
 assert.equal((await requireOk(await c.from('appliances').select('id').eq('household_id',homeA)))?.length,0);
 assert((await c.from('appliances').insert({household_id:homeA,name:'No permitido',duration_minutes:15,energy_kwh:1})).error);
 const date=madridDate(Date.now()),existing=await requireOk(await admin.from('pvpc_days').select('id').eq('date_local',date).eq('source','REData').maybeSingle());
 if(!existing){const prices=await new RedataProvider().getDay(date);if(prices.kind!=='ready'||prices.day.stale)throw new Error('Precios oficiales actuales no disponibles');createdPrice=await requireOk(await admin.rpc('publish_pvpc_day',{day_date:date,source_revision:prices.day.revision,rows:prices.day.intervals}));}
 const backendPrice=await new BackendPriceProvider(config.API_URL,config.ANON_KEY).getDay(date);assert.equal(backendPrice.kind,'ready');
 const planId=randomUUID(),start=new Date(Date.now()+20*60000).toISOString();await requireOk(await a.rpc('create_official_plan',{target:homeA,appliance:appliance.id,start_at:start,requested_id:planId}));
 const planB=await requireOk(await b.from('plans').select('snapshot').eq('id',planId).single());assert(planB);assert.equal(planB.snapshot.status,'planned');
 assert((await b.from('plans').update({snapshot:{cost:'0'}}).eq('id',planId)).error,'No deben aceptarse importes del cliente');
 const actual=new Date(Date.now()-30*60000).toISOString();await requireOk(await b.rpc('confirm_official_plan',{plan_uuid:planId,actual_start:actual}));
 const planA=await requireOk(await a.from('plans').select('snapshot').eq('id',planId).single());assert(planA);assert.equal(planA.snapshot.status,'completed');assert(Number(planA.snapshot.actualCost)>=0||Number(planA.snapshot.actualCost)<0);
 assert.equal((await requireOk(await c.from('plans').select('id').eq('id',planId)))?.length,0);
 for(const [rpc,args] of [
  ['create_invite_code',{target:homeA}],['create_official_plan',{target:homeA,appliance:appliance.id,start_at:start,requested_id:randomUUID()}],
  ['confirm_official_plan',{plan_uuid:planId,actual_start:actual}],['cancel_official_plan',{plan_uuid:planId}],
  ['import_official_plan',{target:homeA,appliance:appliance.id,requested_id:randomUUID(),planned_start:start}],
  ['issue_telegram_nonce',{target:homeA}],['unlink_telegram',{target:homeA}],
  ['register_push_subscription',{target:homeA,subscription_data:subscription}],['revoke_household_member',{target:homeA,member_id:bSession.data.user.id}]
 ] as const){assert((await c.rpc(rpc,args)).error,`C no debe invocar ${rpc} sobre H1`)}
 assert((await c.from('household_memberships').insert({household_id:homeA,user_id:cSession.data.user.id,role:'owner'})).error,'C no se asigna como owner');
 assert((await c.from('usage_logs').insert({household_id:homeA,plan_id:planId,confirmed_by:cSession.data.user.id,snapshot:{}})).error,'C no inserta uso en H1');

 await requireOk(await a.rpc('revoke_household_member',{target:homeA,member_id:bSession.data.user.id}));assert.equal((await requireOk(await b.from('plans').select('id').eq('id',planId)))?.length,0);
 console.log('PASS_LOCAL: Auth A/B/C, invitación, aislamiento, economía, webhook Telegram y registro/revocación Push simulados, revocación.');
}finally{
 if(homes.length){await admin.from('plan_audit_events').delete().in('household_id',homes);await admin.from('households').delete().in('id',homes)}
 if(createdPrice)await admin.from('pvpc_days').delete().eq('id',createdPrice);
 for(const id of users)await admin.auth.admin.deleteUser(id);
}
