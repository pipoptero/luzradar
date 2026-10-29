import {spawnSync} from 'node:child_process';
const command=process.platform==='win32'?'where.exe':'which';
console.log('LuzRadar doctor (solo presencia; no se muestran valores)');console.log(`Node ${process.version}; plataforma ${process.platform}`);
for(const name of ['docker','podman','psql']){const r=spawnSync(command,[name],{stdio:'ignore'});console.log(`${name}: ${r.status===0?'disponible':'no disponible'}`)}
for(const name of ['VITE_SUPABASE_URL','VITE_SUPABASE_PUBLISHABLE_KEY','SUPABASE_URL','SUPABASE_SERVICE_ROLE_KEY','TELEGRAM_BOT_TOKEN','VAPID_PRIVATE_KEY'])console.log(`${name}: ${process.env[name]?'configurada':'no configurada'}`);
const today=new Intl.DateTimeFormat('en-CA',{timeZone:'Europe/Madrid',year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date());try{const r=await fetch(`https://apidatos.ree.es/es/datos/mercados/precios-mercados-tiempo-real?start_date=${today}T00:00&end_date=${today}T23:59&time_trunc=hour&geo_trunc=electric_system&geo_limit=peninsular&geo_ids=8741`,{signal:AbortSignal.timeout(7000)});console.log(`REData: HTTP ${r.status}`)}catch{console.log('REData: no accesible')}
