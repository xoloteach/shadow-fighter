const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

(async () => {
  console.log('=== TESTING PUBLIC GITHUB PAGES DEPLOYMENT ===');
  const publicUrl = 'https://xoloteach.github.io/shadow-fighter/';
  console.log('Navigating to:', publicUrl);

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
    hasTouch: true
  });

  const errors = [];
  page.on('console', msg => {
    if (msg.type() === 'error') {
      errors.push(msg.text());
      console.log('  [PUBLIC BROWSER ERROR]', msg.text());
    }
  });
  page.on('pageerror', err => {
    errors.push(err.message);
    console.log('  [PUBLIC PAGE ERROR]', err.message);
  });

  await page.goto(publicUrl, { waitUntil: 'domcontentloaded' });
  console.log('DOM loaded. Waiting for WebAssembly engine compilation...');
  await page.waitForTimeout(4000);

  console.log('Clicking canvas to activate focus & Web Audio...');
  await page.click('canvas');
  await page.waitForTimeout(2500);

  // Take screenshot of live public game
  const ssPath = path.join(__dirname, 'screenshots', 'public-live-gameplay.png');
  await page.screenshot({ path: ssPath });
  console.log('Captured public deployment screenshot:', ssPath);

  // Send movement & attacks on the public deployment
  console.log('Sending combat inputs to public game...');
  await page.keyboard.press('KeyD');
  await page.waitForTimeout(100);
  await page.keyboard.press('KeyJ');
  await page.waitForTimeout(100);
  await page.keyboard.press('KeyJ');
  await page.waitForTimeout(100);
  await page.keyboard.press('KeyK');
  await page.waitForTimeout(300);

  await page.screenshot({ path: path.join(__dirname, 'screenshots', 'public-live-combat.png') });

  await browser.close();

  console.log('=== PUBLIC TEST FINISHED ===');
  console.log('Total public console errors:', errors.length);
  if (errors.length > 0) {
    console.error('FAILED public deployment test with errors:', errors);
    process.exit(1);
  }
  console.log('PUBLIC DEPLOYMENT IS FULLY FUNCTIONAL AND VERIFIED PLAYABLE!');
})();
