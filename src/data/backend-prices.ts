import {createClient} from '@supabase/supabase-js';
import {addDays,madridDate,madridMidnight,type PvpcProvider,type SourceResult} from './source';
import type {Interval} from '../domain/core';
export function isPublicKey(value:string):boolean{if(value.startsWith('sb_secret_'))return false;try{const payload=JSON.parse(atob(value.split('.')[1].replace(/-/g,'+').replace(/_/g,'/'))) as {role?:string};return payload.role==='anon';}catch{return value.startsWith('sb_publishable_');}}
export function validateServerDay(date:string,items:Interval[]):boolean{try{const start=madridMidnight(date),end=madridMidnight(addDays(date,1)),n=(end-start)/3600000;if(![23,24,25].includes(n)||items.length!==n)return false;return items.every((i,index)=>Date.parse(i.start)===start+index*3600000&&Date.parse(i.end)===start+(index+1)*3600000&&/^-?\d+(?:\.\d+)?$/.test(i.price)&&madridDate(Date.parse(i.start))===date)}catch{return false}}
export class BackendPriceProvider implements PvpcProvider {
 private client;
 constructor(url:string,key:string){if(!url||!isPublicKey(key))throw new Error('Configuración pública inválida');this.client=createClient(url,key);}
 async getDay(date:string):Promise<SourceResult>{
  const cacheKey='luzradar-backend-price-v1:'+date;let unavailable=false;
  try{const day=await this.client.from('pvpc_days').select('id,revision,validated_at').eq('date_local',date).eq('source','REData').maybeSingle();if(!day.error&&!day.data)unavailable=true;
   if(!day.error&&day.data){const rows=await this.client.from('pvpc_intervals').select('start_utc,end_utc,price_eur_kwh').eq('day_id',day.data.id).order('start_utc');if(!rows.error&&rows.data){const intervals=rows.data.map(r=>({start:r.start_utc as string,end:r.end_utc as string,price:String(r.price_eur_kwh)}));if(validateServerDay(date,intervals)&&Number.isFinite(Date.parse(day.data.validated_at))){const result={date,source:'REData' as const,intervals,revision:day.data.revision,fetchedAt:day.data.validated_at,stale:Date.now()-Date.parse(day.data.validated_at)>6*3600000};try{localStorage.setItem(cacheKey,JSON.stringify(result))}catch{/* no cache */}return {kind:'ready',day:result}}}}
  }catch{/* cache may be available */}
  try{const cache=JSON.parse(localStorage.getItem(cacheKey)??'null');if(cache?.date===date&&cache?.source==='REData'&&Array.isArray(cache.intervals)&&validateServerDay(date,cache.intervals)&&typeof cache.fetchedAt==='string'&&Number.isFinite(Date.parse(cache.fetchedAt)))return {kind:'ready',day:{...cache,stale:true}}}catch{/* invalid cache */}
  return unavailable?{kind:'unavailable',reason:'Jornada no publicada'}:{kind:'error',reason:'Backend de precios no disponible o serie inválida'};
 }
}
