import {chromium} from '@playwright/test';
const browser=await chromium.launch();const page=await browser.newPage({viewport:{width:390,height:844}});
await page.goto('http://127.0.0.1:5173/');await page.evaluate(()=>localStorage.setItem('luzradar-source-mode','live'));await page.reload();await page.waitForTimeout(7000);console.log((await page.locator('main').innerText()).slice(0,1200));await page.screenshot({path:'docs/capturas/real-movil.png',fullPage:true});await browser.close();
