import {spawn} from 'node:child_process';
let running=false;
function tick(){if(running)return;running=true;const child=spawn(process.execPath,['--import','tsx','server/worker.ts'],{stdio:'inherit',env:process.env});child.on('exit',()=>{running=false});child.on('error',()=>{running=false;console.error('No se pudo iniciar el trabajo.');});}
console.log('Programador de servidor iniciado; no garantiza puntualidad.');tick();const timer=setInterval(tick,5*60*1000);process.on('SIGTERM',()=>{clearInterval(timer);process.exit(0)});process.on('SIGINT',()=>{clearInterval(timer);process.exit(0)});
