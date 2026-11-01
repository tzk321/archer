const puppeteer = require('/tmp/pptr/node_modules/puppeteer-core');

(async () => {
  const browser = await puppeteer.launch({
    executablePath: '/usr/bin/chromium',
    headless: 'new',
    args: ['--no-sandbox', '--disable-gpu', '--enable-unsafe-swiftshader']
  });
  const page = await browser.newPage();
  await page.setViewport({ width: 720, height: 1280, deviceScaleFactor: 1 });
  page.on('console', m => { const t = m.text(); if (/DBG|PAGEERROR|Uncaught|TypeError|ReferenceError/.test(t)) console.log('CONSOLE', m.type(), t); });
  page.on('pageerror', e => console.log('PAGEERROR', e.message));
  await page.goto('http://127.0.0.1:8124/index.html?autostart=1&autoplay=1&debug=1&fast=1', { waitUntil: 'domcontentloaded', timeout: 15000 });
  await new Promise(r => setTimeout(r, 1200));
  const snap = () => page.evaluate(() => {
    const s = window.__game.scene.scenes[0];
    return {
      state: s.state, elapsed: +s.elapsed.toFixed(1), hp: Math.round(s.stats.hp), maxHp: s.stats.maxHp,
      level: s.level, xp: +s.xp.toFixed(1), need: s.xpNeed, kills: s.kills,
      enemies: s.enemies.countActive(true), arrows: s.arrows.countActive(true),
      gems: s.gems.countActive(true), orbs: s.orbs.countActive(true),
      px: Math.round(s.player.x), py: Math.round(s.player.y),
      taken: s.taken, boss: !!s.boss
    };
  });
  for (let i = 0; i < 7; i++) {
    await new Promise(r => setTimeout(r, 2000));
    try { console.log('T' + (i + 1), JSON.stringify(await snap())); }
    catch (e) { console.log('SNAPERR', e.message); }
  }
  await page.screenshot({ path: '/tmp/game.png' });
  console.log('SCREENSHOT_OK');
  await browser.close();
  process.exit(0);
})();
