const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

(async () => {
  console.log('=== STARTING VERSION 2 FULL AUTOMATED TEST SUITE ===');
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
      console.log('  [BROWSER ERROR]', msg.text());
    }
  });
  page.on('pageerror', err => {
    errors.push(err.message);
    console.log('  [PAGE ERROR]', err.message);
  });

  console.log('Navigating to http://127.0.0.1:8080/...');
  await page.goto('http://127.0.0.1:8080/', { waitUntil: 'domcontentloaded' });

  // Canvas activation
  await page.waitForTimeout(3000);
  await page.click('canvas');
  console.log('Canvas focused. Waiting for round start chime...');
  await page.waitForTimeout(1600); // Wait for countdown to finish

  const qaDir = path.join(__dirname, 'screenshots');
  if (!fs.existsSync(qaDir)) {
    fs.mkdirSync(qaDir, { recursive: true });
  }

  // 1. Locomotion testing
  console.log('1. Testing locomotion & stances...');
  await page.keyboard.down('KeyD');
  await page.waitForTimeout(200);
  await page.screenshot({ path: path.join(qaDir, 'v2-walk-forward.png') });
  await page.keyboard.up('KeyD');

  await page.keyboard.down('KeyA');
  await page.waitForTimeout(200);
  await page.screenshot({ path: path.join(qaDir, 'v2-walk-backward.png') });
  await page.keyboard.up('KeyA');

  await page.keyboard.down('KeyS');
  await page.waitForTimeout(150);
  await page.screenshot({ path: path.join(qaDir, 'v2-crouch.png') });
  await page.keyboard.up('KeyS');

  await page.keyboard.press('KeyW');
  await page.waitForTimeout(180);
  await page.screenshot({ path: path.join(qaDir, 'v2-jump.png') });
  await page.waitForTimeout(350);

  // 2. Attacks & Combos testing
  console.log('2. Testing attack library and intentional combos...');
  
  // Jab
  await page.keyboard.press('KeyJ');
  await page.waitForTimeout(80);
  await page.screenshot({ path: path.join(qaDir, 'v2-jab.png') });
  await page.waitForTimeout(250);

  // Jab -> Cross combo
  await page.keyboard.press('KeyJ');
  await page.waitForTimeout(100);
  await page.keyboard.press('KeyJ');
  await page.waitForTimeout(100);
  await page.screenshot({ path: path.join(qaDir, 'v2-cross.png') });
  await page.waitForTimeout(250);

  // Jab -> Cross -> Hook combo
  await page.keyboard.press('KeyJ');
  await page.waitForTimeout(90);
  await page.keyboard.press('KeyJ');
  await page.waitForTimeout(90);
  await page.keyboard.press('KeyJ');
  await page.waitForTimeout(120);
  await page.screenshot({ path: path.join(qaDir, 'v2-hook.png') });
  await page.waitForTimeout(250);

  // Uppercut (Crouch + Punch)
  await page.keyboard.down('KeyS');
  await page.keyboard.press('KeyJ');
  await page.keyboard.up('KeyS');
  await page.waitForTimeout(120);
  await page.screenshot({ path: path.join(qaDir, 'v2-uppercut.png') });
  await page.waitForTimeout(250);

  // Side Kick
  await page.keyboard.press('KeyK');
  await page.waitForTimeout(110);
  await page.screenshot({ path: path.join(qaDir, 'v2-side-kick.png') });
  await page.waitForTimeout(250);

  // Roundhouse Kick (Jab -> Roundhouse cancel)
  await page.keyboard.press('KeyJ');
  await page.waitForTimeout(90);
  await page.keyboard.press('KeyK');
  await page.waitForTimeout(130);
  await page.screenshot({ path: path.join(qaDir, 'v2-roundhouse.png') });
  await page.waitForTimeout(250);

  // Low Kick (Crouch + Kick)
  await page.keyboard.down('KeyS');
  await page.keyboard.press('KeyK');
  await page.keyboard.up('KeyS');
  await page.waitForTimeout(110);
  await page.screenshot({ path: path.join(qaDir, 'v2-low-kick.png') });
  await page.waitForTimeout(250);

  // Block
  await page.keyboard.down('KeyL');
  await page.waitForTimeout(150);
  await page.screenshot({ path: path.join(qaDir, 'v2-block.png') });
  await page.keyboard.up('KeyL');

  // 3. Multi-round Combat Progression
  console.log('3. Fighting full rounds to trigger KO, knockdown, and victory modal...');
  for (let round = 0; round < 35; round++) {
    await page.keyboard.press('KeyD');
    await page.waitForTimeout(50);
    await page.keyboard.press('KeyJ');
    await page.waitForTimeout(80);
    await page.keyboard.press('KeyJ');
    await page.waitForTimeout(90);
    await page.keyboard.press('KeyK');
    await page.waitForTimeout(100);
  }
  await page.screenshot({ path: path.join(qaDir, 'v2-knockdown.png') });

  // Let match complete or trigger restart
  await page.waitForTimeout(1500);
  await page.screenshot({ path: path.join(qaDir, 'v2-match-resolution.png') });

  // 4. Test Rematch Restart Trigger
  console.log('4. Testing Rematch trigger (KeyR)...');
  await page.keyboard.press('KeyR');
  await page.waitForTimeout(800);

  // 5. Viewport / Responsive layouts
  console.log('5. Testing viewports & mobile touch controls...');
  
  // Desktop 1080p
  await page.setViewportSize({ width: 1920, height: 1080 });
  await page.waitForTimeout(300);
  await page.screenshot({ path: path.join(qaDir, 'v2-desktop-1080p.png') });

  // Laptop 1366x768
  await page.setViewportSize({ width: 1366, height: 768 });
  await page.waitForTimeout(300);
  await page.screenshot({ path: path.join(qaDir, 'v2-laptop.png') });

  // Tablet 1280x800
  await page.setViewportSize({ width: 1280, height: 800 });
  await page.waitForTimeout(300);
  await page.screenshot({ path: path.join(qaDir, 'v2-tablet.png') });

  // Mobile Landscape 932x430
  await page.setViewportSize({ width: 932, height: 430 });
  await page.waitForTimeout(300);
  // Tap virtual punch button
  await page.mouse.click(820, 360);
  await page.waitForTimeout(100);
  await page.screenshot({ path: path.join(qaDir, 'v2-mobile-landscape.png') });

  // Small Mobile 740x360
  await page.setViewportSize({ width: 740, height: 360 });
  await page.waitForTimeout(300);
  await page.screenshot({ path: path.join(qaDir, 'v2-mobile-small.png') });

  // 6. Torture / Stress test
  console.log('6. Running torture stress test (rapid key spam & resize)...');
  for (let i = 0; i < 20; i++) {
    await page.setViewportSize({ width: 800 + (i % 4) * 200, height: 450 + (i % 3) * 100 });
    await page.keyboard.down('KeyA');
    await page.keyboard.down('KeyD');
    await page.keyboard.down('KeyJ');
    await page.keyboard.down('KeyK');
    await page.keyboard.down('KeyL');
    await page.waitForTimeout(25);
    await page.keyboard.up('KeyA');
    await page.keyboard.up('KeyD');
    await page.keyboard.up('KeyJ');
    await page.keyboard.up('KeyK');
    await page.keyboard.up('KeyL');
    if (i % 5 === 0) {
      await page.keyboard.press('KeyR');
    }
  }

  await page.waitForTimeout(800);
  await browser.close();

  console.log('=== VERSION 2 AUTOMATED TEST COMPLETED ===');
  console.log('Total console errors encountered:', errors.length);
  if (errors.length > 0) {
    console.error('FAILED with console errors:');
    errors.forEach(e => console.error(' - ', e));
    process.exit(1);
  }
  console.log('ALL TESTS PASSED WITH 0 CONSOLE ERRORS!');
})();
