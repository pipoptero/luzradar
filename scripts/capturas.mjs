import {chromium} from '@playwright/test';
const browser=await chromium.launch();
for(const [name,width,height] of [['movil',390,844],['escritorio',1440,900]]){const page=await browser.newPage({viewport:{width,height}});await page.goto('http://127.0.0.1:5173/');await page.screenshot({path:`docs/capturas/${name}.png`,fullPage:true});await page.close();}
await browser.close();
