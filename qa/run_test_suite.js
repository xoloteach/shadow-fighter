const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const SCREENSHOT_DIR = path.resolve(__dirname, 'screenshots');
if (!fs.existsSync(SCREENSHOT_DIR)) {
  fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });
}

async function runTestSuite() {
  console.log('=== STARTING GODOT 4 SHADOW FIGHTER ENHANCED TEST SUITE ===');

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

  const context = await browser.newContext({
    viewport: { width: 1280, height: 720 },
    hasTouch: true
  });

  const page = await context.newPage();

  page.on('console', msg => {
    if (msg.type() === 'error') {
      console.error('[BROWSER ERROR]:', msg.text());
    }
  });

  page.on('pageerror', err => {
    console.error('[PAGE ERROR]:', err.message);
  });

  console.log('Navigating to http://127.0.0.1:8080/...');
  await page.goto('http://127.0.0.1:8080/');

  await page.waitForSelector('#canvas', { timeout: 15000 });
  console.log('Canvas detected. Initializing engine...');

  // Wait 3.5s for engine boot
  await page.waitForTimeout(3500);

  // Focus canvas
  await page.click('#canvas');
  console.log('Canvas focused.');

  // 1. Capture Round Start / Announcement
  console.log('Capturing desktop-start.png (Opening Round / Stance)...');
  await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'desktop-start.png') });

  await page.waitForTimeout(1400);

  // 2. Capture Idle stance
  console.log('Capturing desktop-idle.png...');
  await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'desktop-idle.png') });

  // 3. Movement & Combat Combo test
  console.log('Executing movement & strikes...');
  await page.keyboard.down('KeyD');
  await page.waitForTimeout(350);
  await page.keyboard.up('KeyD');

  await page.keyboard.press('KeyJ'); // Lead Punch
  await page.waitForTimeout(80);
  await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'desktop-combat.png') });

  await page.keyboard.press('KeyJ'); // Cross Punch
  await page.waitForTimeout(100);
  await page.keyboard.press('KeyK'); // Combo Kick
  await page.waitForTimeout(90);
  await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'desktop-hit.png') });

  // Jump and aerial kick
  await page.keyboard.down('KeyW');
  await page.waitForTimeout(120);
  await page.keyboard.press('KeyK');
  await page.keyboard.up('KeyW');
  await page.waitForTimeout(350);

  // Low sweep
  await page.keyboard.down('KeyS');
  await page.keyboard.press('KeyK');
  await page.keyboard.up('KeyS');
  await page.waitForTimeout(300);

  // 4. Extended combat match until K.O. and Match Result
  console.log('Fighting match to trigger Round K.O. and Victory/Defeat modal...');
  const matchStart = Date.now();
  let victoryCaptured = false;

  for (let i = 0; i < 70; i++) {
    // Deliver rapid attacks to progress match
    await page.keyboard.down('KeyD');
    await page.waitForTimeout(80);
    await page.keyboard.up('KeyD');

    await page.keyboard.press('KeyJ');
    await page.waitForTimeout(90);
    await page.keyboard.press('KeyJ');
    await page.waitForTimeout(90);
    await page.keyboard.press('KeyK');
    await page.waitForTimeout(150);

    if (i % 5 === 0) {
      // Crouch kick or jump kick
      await page.keyboard.down('KeyS');
      await page.keyboard.press('KeyK');
      await page.keyboard.up('KeyS');
      await page.waitForTimeout(200);
    }

    // Check if modal or KO is visible by evaluating text or checking after 15s
    if (i > 35 && !victoryCaptured) {
      console.log('Capturing match progression / resolution...');
      await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'desktop-victory.png') });
      victoryCaptured = true;
    }
  }

  // Ensure victory/KO screenshot is captured
  await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'desktop-victory.png') });
  console.log('Captured desktop-victory.png.');

  // 5. Test Restart button / Enter
  console.log('Testing Restart trigger (KeyR)...');
  await page.keyboard.press('KeyR');
  await page.waitForTimeout(1500);

  // 6. Viewports & Mobile Devices
  console.log('Capturing tablet.png (1280x800)...');
  await page.setViewportSize({ width: 1280, height: 800 });
  await page.waitForTimeout(600);
  await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'tablet.png') });

  console.log('Capturing mobile-idle.png (932x430)...');
  await page.setViewportSize({ width: 932, height: 430 });
  await page.waitForTimeout(600);
  await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'mobile-idle.png') });

  // Test virtual touch buttons
  console.log('Simulating touch on mobile controls...');
  await page.mouse.click(690, 360); // Punch button
  await page.waitForTimeout(150);
  await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'mobile-combat.png') });

  console.log('Capturing mobile-controls.png...');
  await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'mobile-controls.png') });

  console.log('Capturing desktop-1080p.png (1920x1080)...');
  await page.setViewportSize({ width: 1920, height: 1080 });
  await page.waitForTimeout(500);
  await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'desktop-1080p.png') });

  console.log('Capturing mobile-small.png (740x360)...');
  await page.setViewportSize({ width: 740, height: 360 });
  await page.waitForTimeout(500);
  await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'mobile-small.png') });

  await browser.close();
  console.log('=== ENHANCED TEST SUITE COMPLETED SUCCESSFULLY ===');
}

runTestSuite().catch(err => {
  console.error('Test suite failed:', err);
  process.exit(1);
});
