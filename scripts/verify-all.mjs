import {spawnSync} from 'node:child_process';
import {existsSync,mkdirSync,readFileSync,writeFileSync} from 'node:fs';
import {resolve} from 'node:path';
const npm=process.platform==='win32'?'npm.cmd':'npm';
const browserPath=resolve('.playwright-browsers');
const env={...process.env};
if(!env.PLAYWRIGHT_BROWSERS_PATH&&existsSync(browserPath))env.PLAYWRIGHT_BROWSERS_PATH=browserPath;
const tasks=['check','verify:security','e2e','verify:pwa','verify:pg','verify:db','verify:backend','verify:vertical','verify:recovery','verify:ui-vertical','verify:concurrency','verify:corrections','verify:backup','verify:net-ingest','verify:edge','verify:jobs','verify:cron'];
const results=[];
for(const task of tasks){console.log(`\n--- ${task} ---`);const r=spawnSync(npm,['run',task],{stdio:'inherit',shell:process.platform==='win32',env,timeout:240000});const status=r.status===0?'PASS_LOCAL':r.status===2?'SKIPPED_ENV':'FAIL';results.push({task,status,exitCode:r.status});if(status!=='PASS_LOCAL')console.log(`${task}: ${status}`);}
const contract=JSON.parse(readFileSync('acceptance/CONTRATO_ACEPTACION.json','utf8'));
const externallyBlocked=new Set(['TG02','PUSH02','ICS01','DEPLOY01']);
const blockers=contract.requirements.filter(r=>!['PASS_REAL','PASS_LOCAL'].includes(r.status)&&!(r.status==='BLOCKED_EXTERNAL'&&externallyBlocked.has(r.id))).map(r=>({id:r.id,status:r.status,notes:r.notes}));
results.push({task:'contract:acceptance',status:blockers.length?'FAIL':'PASS_LOCAL',blockers});
mkdirSync('verification-results',{recursive:true});writeFileSync('verification-results/verify-all.json',JSON.stringify({timestamp:new Date().toISOString(),results},null,2));
writeFileSync('verification-results/verify-all.md',`# Resultado local\n\n${results.map(r=>`- ${r.task}: ${r.status}`).join('\n')}\n\nBloqueos de contrato: ${blockers.map(b=>`${b.id} (${b.status})`).join(', ')||'ninguno'}\n`);
if(blockers.length)console.error('El contrato local sigue incompleto:',blockers.map(b=>`${b.id} (${b.status})`).join(', '));
process.exitCode=results.some(r=>r.status!=='PASS_LOCAL')?1:0;
