# LuzRadar

LuzRadar es una aplicación web progresiva para consultar el término de energía PVPC de Red Eléctrica, planificar ciclos y compartir planes y ahorro estimado en un hogar. Los precios no incluyen impuestos ni costes fijos; el ahorro se muestra como estimación, no como una medición de factura.

## Estado

La integración local incluye PostgreSQL y Auth de Supabase, ingestión REData, planificación y ahorro compartidos, cola de avisos, funciones Edge y PWA. La publicación y las integraciones alojadas requieren superar el contrato de aceptación y verificarse en servicios reales. El modo DEMO está identificado y separado de los datos reales.

## Desarrollo local

Se necesitan Node.js, Docker y Supabase Local. Desde la raíz:

```powershell
npm install
npx supabase start
npx supabase migration up --local
npm run dev
```

Abrir `http://127.0.0.1:5173/`. Sin variables públicas de Supabase, el modo PVPC real consulta REData directamente y guarda datos en el navegador. Para probar el hogar local, crear `.env.local` con `VITE_SUPABASE_URL` y `VITE_SUPABASE_PUBLISHABLE_KEY` del entorno local. Las claves de servidor, Telegram y VAPID privado nunca pertenecen al frontend ni al repositorio.

## Comprobaciones

```powershell
npm run check
npm run e2e
npm run verify:pg
npm run verify:db
npm run verify:all
```

`verify:all` devuelve error si una prueba falla o si falta un criterio local crítico. Las pruebas de Edge y cron necesitan las funciones locales y sus secretos de prueba configurados; la guía de activación detalla el procedimiento. Las pruebas de correo utilizan Mailpit local y la copia de seguridad se ensaya en bases temporales con datos sintéticos. Las simulaciones no prueban recepción de Telegram ni Push en un iPhone real.

Consultar [activación y operaciones](docs/ACTIVACION_UNICA.md), [resultado de integración](docs/RESULTADO_FINAL_INTEGRACION.md) y [contrato de aceptación](acceptance/CONTRATO_ACEPTACION.json) para conocer el estado y los pasos pendientes. No publicar secretos, datos personales ni resultados que atribuyan a producción pruebas realizadas solo en local.
