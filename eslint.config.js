import js from '@eslint/js';
import tseslint from 'typescript-eslint';
export default tseslint.config({ignores:['dist/**','node_modules/**','coverage/**','playwright-report/**','test-results/**','.playwright-browsers/**']}, js.configs.recommended, ...tseslint.configs.recommended, {languageOptions:{globals:{window:'readonly',document:'readonly',localStorage:'readonly',navigator:'readonly',URL:'readonly',Blob:'readonly',crypto:'readonly',fetch:'readonly',Response:'readonly',setTimeout:'readonly',console:'readonly',AbortSignal:'readonly',process:'readonly',self:'readonly',clients:'readonly'}}});

