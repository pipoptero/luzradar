import {describe,it,expect} from 'vitest';
import {requiresIosInstallation} from '../src/push';
describe('requisito de instalación en iOS',()=>{it('exige pantalla de inicio en iPhone e iPad antes de solicitar permiso',()=>{expect(requiresIosInstallation('iPhone','iPhone',5,false)).toBe(true);expect(requiresIosInstallation('iPhone','iPhone',5,true)).toBe(false);expect(requiresIosInstallation('Macintosh','MacIntel',5,false)).toBe(true);expect(requiresIosInstallation('Macintosh','MacIntel',0,false)).toBe(false);expect(requiresIosInstallation('Android','Linux',5,false)).toBe(false)})});
