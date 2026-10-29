import {describe,it,expect} from 'vitest';
import {readSharedPlan} from '../src/data/shared-plan';
describe('entrada compartida no confiable',()=>{it('rechaza snapshots inválidos',()=>{expect(readSharedPlan({status:'completed',actualCost:'<script>'})).toBeNull();expect(readSharedPlan(null)).toBeNull()})});
