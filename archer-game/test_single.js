const puppeteer = require('/tmp/pptr/node_modules/puppeteer-core');
(async () => {
  const browser = await puppeteer.launch({ executablePath: '/usr/bin/chromium', headless: 'new', args: ['--no-sandbox','--disable-gpu','--enable-unsafe-swiftshader'] });
  const page = await browser.newPage();
  await page.setViewport({ width: 720, height: 1280 });
  page.on('pageerror', e => console.log('PAGEERROR', e.message));
  page.on('console', m => { const t = m.text(); if (/Uncaught|TypeError|ReferenceError/.test(t)) console.log('CONSOLE-ERR', t); });
  await page.goto('http://127.0.0.1:8124/single.html?autostart=1&autoplay=1&fast=1', { waitUntil: 'domcontentloaded', timeout: 15000 });
  await new Promise(r => setTimeout(r, 6000));
  const st = await page.evaluate(() => { const s = window.__game.scene.scenes[0]; return { state:s.state, elapsed:+s.elapsed.toFixed(1), hp:Math.round(s.stats.hp), lv:s.level, xp:+s.xp.toFixed(1), kills:s.kills, enemies:s.enemies.countActive(true), px:Math.round(s.player.x), py:Math.round(s.player.y), hpBarW:s.hpFill.displayWidth, xpBarW:s.xpFill.displayWidth }; });
  console.log('SINGLE', JSON.stringify(st));
  await page.screenshot({ path: '/tmp/single.png' });
  console.log('SHOT_OK');
  await browser.close();
  process.exit(0);
})();
