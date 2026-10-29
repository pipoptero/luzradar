import {describe,it,expect,vi,afterEach} from 'vitest';
import {readFileSync} from 'node:fs';
import {RedataProvider} from '../src/data/source';
const raw=JSON.parse(readFileSync('tests/fixtures/redata-2026-10-27.json','utf8'));
afterEach(()=>vi.unstubAllGlobals());
describe('caché de datos oficiales',()=>{it('conserva jornada válida y la señala obsoleta cuando falla la red',async()=>{const store=new Map<string,string>();vi.stubGlobal('localStorage',{getItem:(k:string)=>store.get(k)??null,setItem:(k:string,v:string)=>store.set(k,v)});vi.stubGlobal('fetch',vi.fn().mockResolvedValueOnce({ok:true,json:async()=>raw}).mockRejectedValueOnce(new Error('sin red')));const p=new RedataProvider();expect((await p.getDay('2026-10-27')).kind).toBe('ready');const offline=await p.getDay('2026-10-27');expect(offline.kind).toBe('ready');if(offline.kind==='ready')expect(offline.day.stale).toBe(true)});it('sin copia nunca transforma un fallo en datos',async()=>{vi.stubGlobal('localStorage',{getItem:()=>null,setItem:()=>{}});vi.stubGlobal('fetch',vi.fn().mockRejectedValue(new Error('sin red')));expect((await new RedataProvider().getDay('2026-10-27')).kind).toBe('error')})});
