import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { VitePWA } from 'vite-plugin-pwa';
export default defineConfig({base: './', plugins:[react(),VitePWA({registerType:'autoUpdate',manifest:{name:'LuzRadar',short_name:'LuzRadar',description:'Planificación familiar de energía',theme_color:'#102b29',background_color:'#f5f6f0',display:'standalone',start_url:'./',icons:[{src:'icon-192.png',sizes:'192x192',type:'image/png',purpose:'any'},{src:'icon-512.png',sizes:'512x512',type:'image/png',purpose:'any'}]},workbox:{navigateFallback:'index.html',importScripts:['push-sw.js']}})]});
