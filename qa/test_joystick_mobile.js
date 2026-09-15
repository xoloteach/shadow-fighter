const { chromium } = require('playwright');
const path = require('path');

const viewports = [
  { name: 'joystick-tablet', width: 1280, height: 800 },
  { name: 'joystick-mobile', width: 932, height: 430 },
  { name: 'joystick-small', width: 740, height: 360 },
];

(async () => {
  const browser = await chromium.launch({ headless: true, args: ['--use-gl=angle', '--use-angle=swiftshader'] });
  const errors = [];
  for (const vp of viewports) {
    const context = await browser.newContext({ viewport: vp, hasTouch: true, isMobile: true, deviceScaleFactor: 1 });
    const page = await context.newPage();
    page.on('console', m => { if (m.type() === 'error') errors.push(`${vp.name}: ${m.text()}`); });
    page.on('pageerror', e => errors.push(`${vp.name}: ${e.message}`));
    await page.goto('http://localhost:8080/', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(5000);
    await page.screenshot({ path: path.join(__dirname, 'screenshots', `${vp.name}.png`) });
    await context.close();
  }
  await browser.close();
  console.log('Mobile visual checks complete. Errors:', errors.length);
  if (errors.length) { console.error(errors); process.exit(1); }
})();
