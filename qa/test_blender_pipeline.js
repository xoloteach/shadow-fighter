const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

(async () => {
  console.log('=== TESTING BLENDER PIPELINE IN BROWSER ===');
  const browser = await chromium.launch({
    headless: true,
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--enable-webgl',
      '--ignore-gpu-blocklist',
      '--use-gl=angle',
      '--use-angle=swiftshader'
    ]
  });

  const page = await browser.newPage({
    viewport: { width: 1280, height: 720 },
    deviceScaleFactor: 1
  });

  const errors = [];
  page.on('console', msg => {
    if (msg.type() === 'error') {
      errors.push(msg.text());
      console.log('  [BROWSER ERROR]', msg.text());
    }
  });
  page.on('pageerror', err => {
    errors.push(err.message);
    console.log('  [PAGE ERROR]', err.message);
  });

  console.log('Navigating to http://127.0.0.1:8080/...');
  await page.goto('http://127.0.0.1:8080/', { waitUntil: 'domcontentloaded' });

  // Click canvas for focus and audio
  await page.waitForTimeout(3000);
  await page.click('canvas');
  console.log('Canvas focused. Waiting for match start...');
  await page.waitForTimeout(1500); // Wait for countdown to finish

  const qaDir = path.join(__dirname, 'blender');
  if (!fs.existsSync(qaDir)) {
    fs.mkdirSync(qaDir, { recursive: true });
  }

  // 1. Capture Idle
  console.log('Capturing in-game Blender Idle...');
  await page.screenshot({ path: path.join(qaDir, 'gameplay-blender-idle.png') });

  // 2. Capture Jab
  console.log('Triggering Jab (KeyJ) and capturing active strike...');
  await page.keyboard.press('KeyJ');
  // Capture active strike window (~80ms after keypress)
  await page.waitForTimeout(80);
  await page.screenshot({ path: path.join(qaDir, 'gameplay-blender-jab-active.png') });

  await page.waitForTimeout(200);
  await page.screenshot({ path: path.join(qaDir, 'gameplay-blender-jab-recovery.png') });

  console.log('Executing a series of strikes to test combat impact & AI reaction...');
  for (let i = 0; i < 15; i++) {
    await page.keyboard.press('KeyD');
    await page.waitForTimeout(60);
    await page.keyboard.press('KeyJ');
    await page.waitForTimeout(100);
    await page.keyboard.press('KeyK');
    await page.waitForTimeout(100);
  }
  await page.screenshot({ path: path.join(qaDir, 'gameplay-blender-combat.png') });

  await browser.close();
  console.log('=== TEST COMPLETED ===');
  console.log('Errors encountered:', errors.length);
  if (errors.length > 0) {
    process.exit(1);
  }
})();
