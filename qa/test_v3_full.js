const { chromium } = require('playwright');
const path = require('path');
const http = require('http');
const fs = require('fs');

(async () => {
  console.log('=== STARTING VERSION 3 COMPREHENSIVE AUTOMATED TEST SUITE ===');

  // Launch browser with WebGL support
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
    hasTouch: true,
    isMobile: false
  });

  const page = await context.newPage();
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
  await page.waitForTimeout(4500);

  // Focus canvas
  await page.click('canvas');
  await page.waitForTimeout(1500);

  // 1. DOJO INSPECTION
  console.log('1. Testing Dojo Home Hub...');
  await page.screenshot({ path: path.join(__dirname, 'screenshots', 'v3-dojo.png') });
  console.log('   Captured v3-dojo.png');

  // Helper function to click buttons via keyboard tab/enter or screen coordinates
  // Canvas UI: In Godot Web, canvas clicks at button locations trigger Control nodes!
  // In 1280x720:
  // BottomNav in Dojo:
  // BtnArmory: ~x=260, y=655
  // BtnShop: ~x=415, y=655
  // BtnFight: ~x=640, y=655
  // BtnTraining: ~x=865, y=655
  // BtnProfile: ~x=1020, y=655

  // 2. ARMORY TEST
  console.log('2. Testing Equipment Armory...');
  await page.mouse.click(260, 655);
  await page.waitForTimeout(800);
  await page.screenshot({ path: path.join(__dirname, 'screenshots', 'v3-armory.png') });
  console.log('   Captured v3-armory.png');
  // Click Back button at x=80, y=36
  await page.mouse.click(80, 36);
  await page.waitForTimeout(600);

  // 3. SHOP TEST
  console.log('3. Testing Merchant Shop...');
  await page.mouse.click(415, 655);
  await page.waitForTimeout(800);
  await page.screenshot({ path: path.join(__dirname, 'screenshots', 'v3-shop.png') });
  console.log('   Captured v3-shop.png');
  // Click Back button at x=80, y=36
  await page.mouse.click(80, 36);
  await page.waitForTimeout(600);

  // 4. TRAINING TEST
  console.log('4. Testing Training Dojo...');
  await page.mouse.click(865, 655);
  await page.waitForTimeout(800);
  // Perform some attacks on dummy
  await page.keyboard.press('KeyJ');
  await page.waitForTimeout(120);
  await page.keyboard.press('KeyJ');
  await page.waitForTimeout(120);
  await page.keyboard.press('KeyK');
  await page.waitForTimeout(400);
  await page.screenshot({ path: path.join(__dirname, 'screenshots', 'v3-training.png') });
  console.log('   Captured v3-training.png');
  // Click Back to dojo at x=80, y=36
  await page.mouse.click(80, 36);
  await page.waitForTimeout(600);

  // 5. PROFILE TEST
  console.log('5. Testing Warrior Profile...');
  await page.mouse.click(1020, 655);
  await page.waitForTimeout(600);
  await page.screenshot({ path: path.join(__dirname, 'screenshots', 'v3-profile.png') });
  console.log('   Captured v3-profile.png');
  // Click Close button at center modal bottom ~x=640, y=525
  await page.mouse.click(640, 525);
  await page.waitForTimeout(600);

  // 6. BATTLE MAP TEST
  console.log('6. Testing World / Campaign Map...');
  await page.mouse.click(640, 655);
  await page.waitForTimeout(800);
  await page.screenshot({ path: path.join(__dirname, 'screenshots', 'v3-map.png') });
  console.log('   Captured v3-map.png');

  // 7. PRE-FIGHT PREVIEW MODAL
  console.log('7. Opening Tournament Fight 1 Preview...');
  // Click first fight in list ~x=640, y=225
  await page.mouse.click(640, 225);
  await page.waitForTimeout(700);
  await page.screenshot({ path: path.join(__dirname, 'screenshots', 'v3-fight-preview.png') });
  console.log('   Captured v3-fight-preview.png');

  // 8. LAUNCH COMBAT
  console.log('8. Launching Combat with Novice Shinobi...');
  // Click "FIGHT!" button in preview modal ~x=725, y=505
  await page.mouse.click(725, 505);
  await page.waitForTimeout(1200);

  // In combat: test movement and combos with new 1.2x scale
  console.log('   In Arena! Testing 1.2x character scale combat...');
  await page.keyboard.down('KeyD');
  await page.waitForTimeout(300);
  await page.keyboard.up('KeyD');
  await page.keyboard.press('KeyJ');
  await page.waitForTimeout(150);
  await page.keyboard.press('KeyJ');
  await page.waitForTimeout(150);
  await page.keyboard.press('KeyK');
  await page.waitForTimeout(400);

  await page.screenshot({ path: path.join(__dirname, 'screenshots', 'v3-combat.png') });
  console.log('   Captured v3-combat.png');

  // Fight to completion
  console.log('9. Playing out the match...');
  for (let i = 0; i < 28; i++) {
    await page.keyboard.press('KeyJ');
    await page.waitForTimeout(140);
    await page.keyboard.press('KeyJ');
    await page.waitForTimeout(140);
    await page.keyboard.press('KeyK');
    await page.waitForTimeout(200);
  }

  await page.waitForTimeout(2000);
  await page.screenshot({ path: path.join(__dirname, 'screenshots', 'v3-rewards.png') });
  console.log('   Captured v3-rewards.png');

  // Click continue button ~x=640, y=490
  await page.mouse.click(640, 490);
  await page.waitForTimeout(1000);

  // Release the first WebGL context before creating the mobile renderer.
  // Chromium's software WebGL backend can otherwise stall a second capture.
  await context.close();

  // 10. MOBILE VIEWPORT TEST
  console.log('10. Testing mobile landscape viewport (932x430)...');
  const mobileCtx = await browser.newContext({
    viewport: { width: 932, height: 430 },
    hasTouch: true,
    isMobile: true
  });
  const mobilePage = await mobileCtx.newPage();
  mobilePage.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
  mobilePage.on('pageerror', err => errors.push(err.message));
  await mobilePage.goto('http://127.0.0.1:8080/', { waitUntil: 'domcontentloaded' });
  await mobilePage.waitForTimeout(3500);
  await mobilePage.screenshot({ path: path.join(__dirname, 'screenshots', 'v3-mobile-landscape.png'), animations: 'disabled', timeout: 10000 });
  console.log('   Captured v3-mobile-landscape.png');
  await mobileCtx.close();

  await browser.close();

  console.log('=== TEST FINISHED ===');
  console.log('Total console errors captured:', errors.length);
  if (errors.length > 0) {
    console.error('FAILED with errors:', errors);
    process.exit(1);
  }
  console.log('ALL VERSION 3 TESTS PASSED WITH 0 ERRORS!');
})();
