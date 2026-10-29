import {defineConfig,devices} from '@playwright/test';
export default defineConfig({testDir:'./e2e',timeout:30000,use:{baseURL:'http://127.0.0.1:5173'},webServer:{command:'npm run dev -- --port 5173 --strictPort',url:'http://127.0.0.1:5173',reuseExistingServer:true,timeout:90000},projects:[{name:'chromium',use:{...devices['Desktop Chrome']}},{name:'webkit',use:{...devices['Desktop Safari']}}]});
