const { chromium } = require('playwright');
const path = require('path');

(async () => {
  console.log('=== V3 SURVIVAL MODE SMOKE TEST ===');
  const browser = await chromium.launch({ headless: true, args: ['--no-sandbox', '--use-gl=angle', '--use-angle=swiftshader'] });
  const context = await browser.newContext({ viewport: { width: 1280, height: 720 }, hasTouch: true });
  const page = await context.newPage();
  const errors = [];
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  page.on('pageerror', e => errors.push(e.message));

  await page.goto('http://127.0.0.1:8080/', { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(4200);
  await page.click('canvas');
  // Dojo -> Battle Map -> Survival -> first card -> launch.
  await page.mouse.click(640, 655);
  await page.waitForTimeout(700);
  await page.mouse.click(890, 150);
  await page.waitForTimeout(500);
  await page.mouse.click(640, 225);
  await page.waitForTimeout(500);
  await page.screenshot({ path: path.join(__dirname, 'screenshots', 'v3-survival-preview.png') });
  await page.mouse.click(725, 505);
  await page.waitForTimeout(1600);
  await page.screenshot({ path: path.join(__dirname, 'screenshots', 'v3-survival-wave-1.png') });

  await context.close();
  await browser.close();
  if (errors.length) throw new Error(errors.join('\n'));
  console.log('Survival trial launched at wave 1/6 with zero console errors.');
})();
