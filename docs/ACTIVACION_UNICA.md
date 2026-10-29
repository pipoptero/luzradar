# Activación única — estado vigente 29/10/2026

**NO COMPLETADO.** El gate local ha pasado y la aplicación está publicada en [GitHub Pages](https://pipoptero.github.io/luzradar/), con [código en GitHub](https://github.com/pipoptero/luzradar). Supabase Cloud tiene migraciones, funciones, claves de servidor y cron configurados; se han probado una ejecución programada, la ingesta y el recorrido API con cuentas sintéticas. OAuth llega a Google; faltan el acceso real de una persona, Telegram y Push en el iPhone. No se han enviado avisos reales.

## Uso local

Desde la raíz, con Node, Docker y Supabase Local disponibles:

```powershell
npm install
npx supabase start
npx supabase migration up --local
npm run check
npm run verify:all
npm run dev
```

`npm run verify:backup` crea dos bases temporales con nombres aleatorios dentro del PostgreSQL local, aplica las migraciones, copia y restaura únicamente datos sintéticos y elimina esas dos bases al acabar. No utiliza ni borra datos del hogar. Antes de operar el proyecto alojado se debe definir y ensayar una copia de sus datos y claves de recuperación en un destino protegido y una restauración en una base separada; el ensayo local no prueba la restauración de Supabase Cloud.

Abrir `http://127.0.0.1:5173/`. Sin configuración pública de Supabase, el modo real local consulta REData desde el navegador y guarda planes en ese navegador. Ajustes permite seleccionar una DEMO identificada. Para probar el hogar local se pueden configurar en `.env.local` únicamente `VITE_SUPABASE_URL` y `VITE_SUPABASE_PUBLISHABLE_KEY` del Supabase Local. Nunca introducir `service_role` en Vite ni publicar el archivo. Las pruebas de Edge requieren `supabase functions serve` con secretos de prueba locales antes de `verify:all`. No reiniciar la base si contiene datos que deban conservarse.

## Activación cuando se apruebe el gate

1. Resolver los requisitos `FAIL` en `acceptance/CONTRATO_ACEPTACION.json`, repetir las pruebas y auditar la privacidad del código y del historial que se publique.
2. Confirmar que la CLI apunta al proyecto dedicado, aplicar las migraciones probadas sin reiniciar la base alojada y desplegar las funciones. Ajustar las redirecciones OAuth exactas de Pages y probar acceso, salida y recuperación. Los secretos se guardan exclusivamente en el servidor o Vault.
3. Configurar la agenda protegida mediante `supabase/authorized_cron_setup.sql` y comprobar ejecuciones y errores. El plan Supabase Free puede pausarse por inactividad y no garantiza disponibilidad continua.
4. Preparar el bot exclusivo, webhook y VAPID; probar Telegram solo con el chat autorizado. Comprobar en el iPhone del propietario la PWA instalada y cerrada, la recepción real de Push y la importación del `.ics`.
5. Crear el repositorio público dedicado autorizado, publicar únicamente contenido auditado, configurar Pages y verificar en su URL HTTPS los recorridos A/B/C, precios, costes, OAuth, cron y canales. Registrar enlaces y resultados reales.

Para activar Telegram, el propietario debe crear un bot exclusivo y guardar `TELEGRAM_BOT_TOKEN` directamente en los secretos de Edge Functions del proyecto, sin pegarlo en conversaciones ni archivos versionados. Una vez instalado el token, ejecutar `$env:LUZRADAR_CONFIGURE_TELEGRAM='oldryfrsdxkgfrusyekz'; npm run configure:telegram` desde el repositorio enlazado registra el webhook fijo usando los secretos ya guardados en servidor. El nombre público del bot se configura en la variable de GitHub `VITE_TELEGRAM_BOT_NAME` y requiere un nuevo despliegue. Cada miembro enlaza su propio chat desde Ajustes y puede solicitar un aviso de prueba; no se envía nada antes de esa acción y consentimiento.

En iPhone, abrir la web en Safari, añadirla a la pantalla de inicio, abrirla desde el icono e iniciar sesión. En Ajustes hay que guardar la preferencia de Web Push, activar el dispositivo y pulsar **Probar Web Push**; cerrar la aplicación y comprobar la recepción. La prueba en navegador de escritorio no acredita recepción física. Un plan permite descargar un `.ics` para verificar la importación en Calendario.

El texto siguiente se conserva como evidencia histórica. Sus afirmaciones sobre la falta de Docker y el proceso Node como arquitectura productiva han sido superadas por esta sección.

