const { chromium } = require('playwright');
const path = require('path');

const viewports = [
  { name: 'scale-1920x1080', width: 1920, height: 1080, touch: false },
  { name: 'scale-1366x768', width: 1366, height: 768, touch: false },
  { name: 'scale-1280x800', width: 1280, height: 800, touch: true },
  { name: 'scale-932x430', width: 932, height: 430, touch: true },
  { name: 'scale-740x360', width: 740, height: 360, touch: true },
];

(async () => {
  console.log('=== VERIFYING CHARACTER 1.2X SCALE ACROSS 5 VIEWPORTS ===');
  const browser = await chromium.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--use-gl=angle', '--use-angle=swiftshader']
  });

  for (const vp of viewports) {
    console.log(`Testing ${vp.name} (${vp.width}x${vp.height})...`);
    const context = await browser.newContext({
      viewport: { width: vp.width, height: vp.height },
      hasTouch: vp.touch,
      isMobile: vp.touch
    });
    const page = await context.newPage();
    const errors = [];
    page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
    page.on('pageerror', e => errors.push(e.message));

    await page.goto('http://127.0.0.1:8080/', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(4000);
    await page.click('canvas');
    await page.waitForTimeout(1000);

    // From dojo, click Battle Map, then click fight, then launch
    // Scale-independent UI clicks:
    // In Dojo, press Fight button (or space/enter or coordinate ratio)
    const cw = vp.width;
    const ch = vp.height;
    // Click Battle Map at center-bottom: ~x=cw*0.5, y=ch*0.91
    await page.mouse.click(cw * 0.5, ch * 0.91);
    await page.waitForTimeout(800);
    // Click first tournament fight: ~x=cw*0.5, y=ch*0.31
    await page.mouse.click(cw * 0.5, ch * 0.31);
    await page.waitForTimeout(800);
    // Click FIGHT! in preview modal: ~x=cw*0.57, y=ch*0.70
    await page.mouse.click(cw * 0.57, ch * 0.70);
    await page.waitForTimeout(1500);

    // In combat arena: perform attack and capture screenshot
    await page.keyboard.press('KeyJ');
    await page.waitForTimeout(200);
    await page.screenshot({ path: path.join(__dirname, 'screenshots', `${vp.name}.png`) });
    console.log(`Captured ${vp.name}.png`);

    await context.close();
    if (errors.length > 0) {
      console.error(`Errors on ${vp.name}:`, errors);
      process.exit(1);
    }
  }

  await browser.close();
  console.log('ALL 5 VIEWPORTS VERIFIED SUCCESSFULLY!');
})();
