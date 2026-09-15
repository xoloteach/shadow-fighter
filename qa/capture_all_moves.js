const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

(async () => {
  console.log('=== CAPTURING DEDICATED MOVE SCREENSHOTS ===');
  const browser = await chromium.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--enable-webgl', '--ignore-gpu-blocklist']
  });

  const page = await browser.newPage({ viewport: { width: 1280, height: 720 }, hasTouch: true });
  const outDir = path.join(__dirname, 'screenshots');
  if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });

  await page.goto('http://127.0.0.1:8080/');
  await page.waitForTimeout(3000);
  await page.click('canvas');
  await page.waitForTimeout(1500);

  // Helper to capture a move
  async function capture(name, setupFn, holdTime = 100) {
    await page.keyboard.press('KeyR'); // Reset match for clean spacing
    await page.waitForTimeout(2300);   // Wait for fight start & FIGHT! banner to clear
    await setupFn();
    await page.waitForTimeout(holdTime);
    await page.screenshot({ path: path.join(outDir, `${name}.png`) });
    console.log(`Captured ${name}.png`);
  }

  // 1. Walk Forward
  await capture('v2-walk-forward', async () => {
    await page.keyboard.down('KeyD');
  }, 180);
  await page.keyboard.up('KeyD');

  // 2. Jump
  await capture('v2-jump', async () => {
    await page.keyboard.press('KeyW');
  }, 160);

  // 3. Crouch
  await capture('v2-crouch', async () => {
    await page.keyboard.down('KeyS');
  }, 150);
  await page.keyboard.up('KeyS');

  // 4. Jab
  await capture('v2-jab', async () => {
    await page.keyboard.press('KeyJ');
  }, 70);

  // 5. Cross (Jab -> Cross combo)
  await capture('v2-cross', async () => {
    await page.keyboard.press('KeyJ');
    await page.waitForTimeout(80);
    await page.keyboard.press('KeyJ');
  }, 90);

  // 6. Hook (Jab -> Cross -> Hook combo)
  await capture('v2-hook', async () => {
    await page.keyboard.press('KeyJ');
    await page.waitForTimeout(75);
    await page.keyboard.press('KeyJ');
    await page.waitForTimeout(75);
    await page.keyboard.press('KeyJ');
  }, 110);

  // 7. Uppercut (Crouch + Punch)
  await capture('v2-uppercut', async () => {
    await page.keyboard.down('KeyS');
    await page.keyboard.press('KeyJ');
    await page.keyboard.up('KeyS');
  }, 120);

  // 8. Side Kick
  await capture('v2-side-kick', async () => {
    await page.keyboard.press('KeyK');
  }, 110);

  // 9. Roundhouse Kick (Jab -> Roundhouse cancel)
  await capture('v2-roundhouse', async () => {
    await page.keyboard.press('KeyJ');
    await page.waitForTimeout(75);
    await page.keyboard.press('KeyK');
  }, 120);

  // 10. Low Kick (Crouch + Kick)
  await capture('v2-low-kick', async () => {
    await page.keyboard.down('KeyS');
    await page.keyboard.press('KeyK');
    await page.keyboard.up('KeyS');
  }, 100);

  // 11. Block
  await capture('v2-block', async () => {
    await page.keyboard.down('KeyL');
  }, 150);
  await page.keyboard.up('KeyL');

  // 12. Mobile Landscape
  await page.setViewportSize({ width: 932, height: 430 });
  await page.waitForTimeout(300);
  await page.screenshot({ path: path.join(outDir, 'v2-mobile-landscape.png') });

  await browser.close();
  console.log('=== DEDICATED CAPTURE COMPLETE ===');
})();
