import type {Plan} from '../domain/core';
/** Only the explicitly designated real-local store may be imported. DEMO has a different key. */
export function importableRealPlans(raw:string|null):Plan[]{if(!raw)return [];try{const data=JSON.parse(raw) as {plans?:unknown};if(!Array.isArray(data.plans))return [];return data.plans.filter((p):p is Plan=>typeof p==='object'&&p!==null&&typeof p.id==='string'&&/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(p.id)&&typeof p.name==='string'&&typeof p.start==='string'&&['planned','completed','cancelled'].includes(p.status));}catch{return []}}
export function realLocalPlans():Plan[]{return importableRealPlans(localStorage.getItem('luzradar-demo-v1-live'));}
