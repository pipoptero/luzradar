# Resultado de integración — actualización 28/10/2026

> **Actualización 29/10/2026:** [código público](https://github.com/pipoptero/luzradar) y [aplicación HTTPS](https://pipoptero.github.io/luzradar/) publicados. Chromium y WebKit mostraron el precio actual alojado y verificaron manifest, iconos y recarga; Actions pasó. Las migraciones 001–025 y las funciones están aplicadas; el catálogo muestra RLS y ausencia de acceso anónimo privado. Tras un fallo inicial de red desde Edge, `pg_net` permitió publicar 24 intervalos oficiales del 29/10. Auth/API alojadas superaron la prueba A/B/C con cuentas sintéticas, eliminadas después. Cron está configurado cada cinco minutos y ha ejecutado trabajos con éxito. Los controles para solicitar avisos de prueba se han verificado localmente; no se han enviado avisos reales. OAuth llega a Google, pero falta el inicio de sesión real; Telegram y Push físico siguen pendientes.

**NO COMPLETADO.** El gate local ha pasado y se han comprobado la web pública, el backend y el cron. El inicio de sesión de una persona con Google, la entrega Telegram y la recepción Push en iPhone siguen pendientes.

## Evidencia de esta ejecución

- `npm run check`: typecheck, lint, 42 unitarias y build aprobados. `npm run e2e`: diez recorridos Chromium/WebKit, incluido axe y teclado en cuatro pantallas, aprobados; no representa VoiceOver ni iPhone físico.
- `npm run verify:pg` y `npm run verify:db`: 105 aserciones pasan con PGlite/Auth simulado y PostgreSQL de Supabase Local real, respectivamente. Incluyen permisos, destinatario y límite de frecuencia de solicitudes de prueba. No equivalen a una auditoría exhaustiva de todas las políticas.
- `npm run verify:vertical`: Auth y API reales locales A/B/C, invitación, manipulación de costes, revocación, webhook Telegram y alta/baja Push simulados. `npm run verify:ui-vertical`: navegación y sincronización entre tres sesiones reales locales; A crea un plan familiar, B confirma y A ve el ahorro en la pantalla principal.
- `npm run verify:concurrency`: dos conexiones reales, claim con SKIP LOCKED, lease y revocación. `npm run verify:edge` y `npm run verify:jobs`: función Edge local, fuente REData real y deduplicación sin receptores vinculados. `npm run verify:cron`: cron y Vault locales invocan Edge sin envíos.
- `npm run verify:pwa`: build servido en `/luzradar/`, iconos, manifest, alcance SW y recarga offline en DEMO. También prueba caché obsoleta con fixture; no demuestra actualización de SW ni instalación física.
- `npm run verify:all` aprobó todos los gates locales, incluida la corrección con datos sintéticos, recuperación de cuenta y copia/restauración temporal. Las pruebas externas siguen pendientes. El archivo `acceptance/CONTRATO_ACEPTACION.json` mantiene los estados precisos; no se atribuyen pruebas reales a simulaciones.

## Matriz vigente

| ID | Estado | Comprobación / límite residual |
| --- | --- | --- |
| PVPC01 | PASS_REAL | REData real alojado el 29/10; 24 intervalos actuales y precio visible coincidente con la API; contraste ESIOS anterior documentado. |
| PVPC02 | PASS_LOCAL | D+1, caché y errores cubiertos con fixture y red simulada. |
| TIME01 | PASS_LOCAL | Fixtures oficiales 23/24/25 y doble 02:00. |
| CALC01 | PASS_LOCAL | Coste calculado en servidor con precios oficiales persistidos; solapes y manipulación probados localmente. |
| CALC02 | PASS_LOCAL | Optimización futura sin vetos, cruce de medianoche con cobertura y deduplicación del primer umbral cubiertos; avisos en vivo se evalúan en JOB03. |
| UI01 | PASS_LOCAL | axe WCAG 2 A/AA y 2.1 AA en cuatro pantallas, Chromium/WebKit 390 y escritorio, teclado básico; VoiceOver físico pendiente. |
| DATA01 | PASS_LOCAL | Tres modos separados: la importación explícita incorpora únicamente el plan real local, excluye DEMO y recalcula importes. |
| AUTH01 | PASS_REAL | Login Auth alojado con cuentas sintéticas y recuperación en Mailpit local; OAuth inicia redirección a Google, falta acceso de persona real. |
| HOME01 | PASS_REAL | A/B alojados comparten aparato y confirmación por API; sincronización de navegador verificada en Supabase Local. |
| HOME02 | PASS_REAL | Invitación de un uso y revocación en Auth/API alojados; caducidad y permisos adicionales en PostgreSQL local. |
| SEC01 | PASS_REAL | En proyecto alojado C no lee/escribe H1 y se rechazan RPC críticas; RLS de todas las tablas y permisos probados en local y catálogo alojado. |
| SEC02 | PASS_LOCAL | Grants de tablas y funciones privilegiadas revisados, anónimo bloqueado y escalada rechazada; no es auditoría exhaustiva de producción. |
| SYNC01 | PASS_LOCAL | A/B sincronizan confirmación y anulación; importación real repetida es idempotente y no migra DEMO. |
| SAV01 | PASS_LOCAL | Una confirmación de B aparece en el ahorro mensual compartido de A; el baseline y costes se calculan en servidor y se identifican como estimados. |
| JOB01 | PASS_LOCAL | Claim concurrente y lease reales; ventana de reintento y límite de cinco intentos tras caídas verificados en PostgreSQL, con cron/Edge local. |
| JOB02 | PASS_LOCAL | Dos ejecuciones Edge con fuente oficial crean un resumen D+1 único y respetan opt-out; sin destinatarios ni envíos reales. |
| JOB03 | PASS_LOCAL | Edge real local reprograma, evalúa umbral y revocación; serie sintética transaccional verifica corrección de costes y movimiento sin duplicar con el mismo programador. Sin entrega real. |
| TG01 | PASS_LOCAL | Webhook Edge local comprueba secreto y atribución por nonce; sin envío real. |
| TG02 | BLOCKED_EXTERNAL | Bot exclusivo y chat de prueba aún pendientes de confirmación; webhook desplegado, sin entrega real. |
| PUSH01 | PASS_LOCAL | Alta y baja desde navegador con PushManager simulado y API real, validación de claves y SW; entrega e iPhone no verificados. |
| PUSH02 | BLOCKED_EXTERNAL | VAPID configurado en servidor y clave pública en frontend; falta instalación y recepción física en iPhone. |
| ICS01 | BLOCKED_EXTERNAL | Generación UTC/VALARM unitaria; importación iPhone pendiente. |
| PWA01 | PASS_LOCAL | Manifest, iconos, alcance bajo /luzradar/, actualización del SW y recarga offline con DEMO y caché obsoleta (fixture) probados; falta instalación física. |
| DEPLOY01 | PASS_REAL | GitHub Actions y Pages publicados; Chromium/WebKit validan URL, precio alojado, manifest, iconos y recarga. |
| OPS01 | PASS_LOCAL | Doctor y auditoría estática; copia/restauración en bases PostgreSQL temporales con datos sintéticos, RLS y permisos; falta política y prueba de backup Cloud. |

