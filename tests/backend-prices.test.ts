import {describe,it,expect} from 'vitest';
import {validateServerDay} from '../src/data/backend-prices';
import {normalizeRedata} from '../src/data/source';
import {readFileSync} from 'node:fs';
describe('contrato de precios de backend',()=>{it('acepta jornada oficial normalizada y rechaza huecos',()=>{const raw=JSON.parse(readFileSync('tests/fixtures/redata-2026-10-25.json','utf8'));const r=normalizeRedata(raw,'2026-10-25');if(r.kind!=='ready')throw new Error(r.reason);expect(validateServerDay(r.day.date,r.day.intervals)).toBe(true);expect(validateServerDay(r.day.date,r.day.intervals.slice(1))).toBe(false)})});

describe('clave pública',()=>{it('rechaza clave secreta y JWT con rol de servicio',async()=>{const {isPublicKey}=await import('../src/data/backend-prices');expect(isPublicKey('sb_secret_example')).toBe(false);const token='a.'+btoa(JSON.stringify({role:'service_role'}))+'.b';expect(isPublicKey(token)).toBe(false);expect(isPublicKey('sb_publishable_example')).toBe(true)})});
