import type {Appliance,Interval,Plan} from '../domain/core';
export const defaults:Appliance[]=[{id:'washer',name:'Lavadora',minutes:120,energy:'1.2'},{id:'dishwasher',name:'Lavavajillas',minutes:120,energy:'1.1'},{id:'climate',name:'Climatización',minutes:120,energy:'2',threshold:'0.15'}];
const prices=['0.128','0.104','0.088','0.079','0.082','0.095','0.121','0.165','0.191','0.205','0.232','0.214','0.175','0.142','0.112','0.098','0.106','0.145','0.198','0.225','0.207','0.181','0.151','0.136'];
export function demoIntervals(now=Date.now()):Interval[]{const start=Math.floor(now/86400000)*86400000-24*3600000;return Array.from({length:120},(_,i)=>({start:new Date(start+i*3600000).toISOString(),end:new Date(start+(i+1)*3600000).toISOString(),price:prices[i%24]}));}
export type DemoState={appliances:Appliance[];plans:Plan[]};const key='luzradar-demo-v1';
export function loadDemo(mode='demo'):DemoState{try{const raw=localStorage.getItem(mode==='demo'?key:key+'-live');if(raw){const data=JSON.parse(raw) as DemoState;if(Array.isArray(data.appliances)&&Array.isArray(data.plans))return data;}}catch{/* recupera datos locales corruptos */}return {appliances:defaults,plans:[]};}
export function saveDemo(s:DemoState,mode='demo'){localStorage.setItem(mode==='demo'?key:key+'-live',JSON.stringify(s));}
export function resetDemo():DemoState{localStorage.removeItem(key);return {appliances:defaults,plans:[]};}

