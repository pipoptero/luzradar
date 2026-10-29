import {describe,it,expect} from 'vitest';
import {importableRealPlans} from '../src/data/import-real';
describe('importación local explícita',()=>{it('filtra datos malformados antes de intentar la importación',()=>{const good={id:'291ff1e8-50f8-4418-acf4-0f516ef3a520',name:'Lavadora',start:'2026-10-28T08:00:00Z',status:'planned'};expect(importableRealPlans(JSON.stringify({plans:[good,{...good,id:'invalido'}]}))).toHaveLength(1);expect(importableRealPlans('no json')).toEqual([])});});
