import {readdir,readFile} from 'node:fs/promises';
import {join} from 'node:path';
import {spawnSync} from 'node:child_process';
const bad=/SUPABASE_SERVICE_ROLE_KEY|TELEGRAM_BOT_TOKEN|VAPID_PRIVATE_KEY|LUZRADAR_CRON_SECRET|TELEGRAM_WEBHOOK_SECRET|-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/;
async function scan(dir){for(const e of await readdir(dir,{withFileTypes:true})){const p=join(dir,e.name);if(e.isDirectory())await scan(p);else if(e.isFile()&&/\.(?:ts|tsx|js|html|css|json|webmanifest)$/.test(p)){const content=await readFile(p,'utf8');if(bad.test(content))throw new Error(`Referencia a secreto de servidor en ${p}`)}}}
for(const dir of ['src','public','dist'])await scan(dir);
const check=spawnSync('git',['check-ignore','-q','.env.local']);if(check.status!==0)throw new Error('Los archivos de entorno deben estar ignorados');
const workflow=await readFile('.github/workflows/pages.yml','utf8');for(const x of ['contents: read','pages: write','id-token: write','npm run check'])if(!workflow.includes(x))throw new Error(`Falta control de workflow: ${x}`);
console.log('PASS_LOCAL: referencias a secretos en frontend/bundle, exclusión de .env y permisos básicos del workflow comprobados. No sustituye auditoría de historial ni búsqueda de valores reales.');
