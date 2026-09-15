const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true, args: ['--use-gl=angle', '--use-angle=swiftshader'] });
  const context = await browser.newContext({ viewport: { width: 932, height: 430 }, hasTouch: true, isMobile: true });
  const page = await context.newPage();
  const errors = [];
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  page.on('pageerror', e => errors.push(e.message));
  await page.goto('http://localhost:8080/', { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(5200);
  const cdp = await context.newCDPSession(page);
  const touch = (type, points) => cdp.send('Input.dispatchTouchEvent', { type, touchPoints: points });
  // The left joystick center and right-side action centers in the 932x430 layout.
  const joy = { x: 75, y: 352, id: 1 };
  const punch = { x: 802, y: 370, id: 2 };
  const kick = { x: 854, y: 334, id: 2 };
  const block = { x: 860, y: 386, id: 2 };
  // All eight directions, including a drag outside the visual radius, must release cleanly.
  const dirs = [[0,-62],[46,-46],[62,0],[46,46],[0,62],[-46,46],[-62,0],[-46,-46]];
  for (const [dx, dy] of dirs) {
    await touch('touchStart', [joy]);
    await touch('touchMove', [{ x: joy.x + dx * 1.45, y: joy.y + dy * 1.45, id: 1 }]);
    await page.waitForTimeout(90);
    await touch('touchEnd', []);
    await page.waitForTimeout(70);
  }
  // Multi-touch: begin joystick and action together, then drag the joystick
  // while the second touch remains on the action button.
  await touch('touchStart', [joy, punch]);
  await touch('touchMove', [{ x: 150, y: 352, id: 1 }, punch]);
  await page.waitForTimeout(140);
  await touch('touchEnd', [{ x: 150, y: 352, id: 1 }]);
  await touch('touchEnd', []);
  await touch('touchStart', [joy, kick]);
  await touch('touchMove', [{ x: 150, y: 352, id: 1 }, kick]);
  await page.waitForTimeout(140);
  await touch('touchEnd', []);
  await touch('touchStart', [joy, block]);
  await touch('touchMove', [{ x: 150, y: 290, id: 1 }, block]); // up-right + block
  await page.waitForTimeout(180);
  await page.screenshot({ path: path.join(__dirname, 'screenshots', 'joystick-multitouch-active.png') });
  await touch('touchEnd', []);
  await page.waitForTimeout(300);
  await page.screenshot({ path: path.join(__dirname, 'screenshots', 'joystick-recentered.png') });
  await context.close();
  await browser.close();
  console.log('8 direction, release/recenter, and multi-touch pointer automation complete. Errors:', errors.length);
  if (errors.length) { console.error(errors); process.exit(1); }
})();
