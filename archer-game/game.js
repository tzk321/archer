/* 弓箭手大作战 · 野狗复刻版
 * Phaser 3.80.1 / 单文件逻辑
 * 玩法：俯视竞技场，自动瞄准射箭，移动躲避，吃经验升级，三选一强化，活得越久越强
 */
(function () {
  'use strict';

  const W = 720;
  const H = 1280;
  const FONT = '"PingFang SC","Hiragino Sans GB","Microsoft YaHei",sans-serif';

  const rnd = (a, b) => a + Math.random() * (b - a);
  const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
  const dist2 = (a, b) => (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y);

  /* ---------------- 强化池 ---------------- */
  const UPGRADES = [
    { id: 'dmg',     n: '强力箭',   d: '攻击力 +25%',              max: 9, apply: p => { p.dmg *= 1.25; } },
    { id: 'rate',    n: '疾风弓',   d: '攻速 +18%',                max: 8, apply: p => { p.fireMs = Math.max(105, p.fireMs * 0.82); } },
    { id: 'multi',   n: '多重箭',   d: '每次多射一支箭',            max: 4, apply: p => { p.arrows += 1; } },
    { id: 'pierce',  n: '穿透箭',   d: '箭矢可多穿一个敌人',        max: 3, apply: p => { p.pierce += 1; } },
    { id: 'crit',    n: '致命瞄准', d: '暴击率 +12%',               max: 5, apply: p => { p.crit = Math.min(0.75, p.crit + 0.12); } },
    { id: 'critdmg', n: '爆头',     d: '暴击伤害 +40%',             max: 5, apply: p => { p.critMult += 0.4; } },
    { id: 'speed',   n: '轻步',     d: '移速 +12%',                 max: 6, apply: p => { p.speed *= 1.12; } },
    { id: 'hp',      n: '强健体魄', d: '生命上限 +25，并回复 25',    max: 9, apply: p => { p.maxHp += 25; p.hp = Math.min(p.maxHp, p.hp + 25); } },
    { id: 'regen',   n: '野性回复', d: '每秒回复 +0.8 生命',        max: 5, apply: p => { p.regen += 0.8; } },
    { id: 'magnet',  n: '贪婪之手', d: '经验拾取范围 +40%',         max: 5, apply: p => { p.magnet *= 1.4; } },
    { id: 'bounce',  n: '弹射箭',   d: '箭矢命中后弹向附近敌人',     max: 2, apply: p => { p.bounce += 1; } }
  ];

  class MainScene extends Phaser.Scene {
    constructor() {
      super('main');
    }

    /* ============ 贴图生成 ============ */
    makeTextures() {
      const mk = (key, w, h, draw) => {
        const g = this.make.graphics({ x: 0, y: 0, add: false });
        draw(g);
        g.generateTexture(key, w, h);
        g.destroy();
      };

      // 背景砖块
      mk('bg', 256, 256, g => {
        g.fillStyle(0x0c1020, 1);
        g.fillRect(0, 0, 256, 256);
        g.lineStyle(1, 0x18203a, 1);
        for (let i = 0; i <= 256; i += 64) {
          g.lineBetween(i, 0, i, 256);
          g.lineBetween(0, i, 256, i);
        }
        g.fillStyle(0x1b2440, 0.9);
        [[32, 96], [160, 32], [224, 192], [96, 224]].forEach(p => g.fillCircle(p[0], p[1], 2));
        g.fillStyle(0x141b30, 1);
        g.fillCircle(192, 96, 18);
        g.lineStyle(2, 0x1d2742, 1);
        g.strokeCircle(192, 96, 18);
      });

      // 玩家：兜帽弓手
      mk('player', 56, 56, g => {
        g.fillStyle(0x000000, 0.25);
        g.fillEllipse(28, 46, 34, 12);
        g.fillStyle(0x1d6b4a, 1);
        g.fillCircle(28, 28, 18);
        g.fillStyle(0x2fb37a, 1);
        g.fillCircle(28, 26, 15);
        g.fillStyle(0x0b3b2a, 1);
        g.beginPath();
        g.arc(28, 26, 15, Math.PI * 0.05, Math.PI * 0.95, false);
        g.fillPath();
        g.fillStyle(0xf2d5b3, 1);
        g.fillCircle(28, 28, 9);
        g.fillStyle(0x10231c, 1);
        g.fillCircle(24, 27, 2.2);
        g.fillCircle(32, 27, 2.2);
        g.lineStyle(2, 0x10231c, 1);
        g.lineBetween(25, 33, 31, 33);
      });

      // 弓
      mk('bow', 64, 64, g => {
        g.lineStyle(4, 0xd9a066, 1);
        g.beginPath();
        g.arc(32, 32, 22, -Math.PI * 0.42, Math.PI * 0.42, false);
        g.strokePath();
        g.lineStyle(1.5, 0xf5f0e6, 0.9);
        g.lineBetween(32 + Math.cos(-Math.PI * 0.42) * 22, 32 + Math.sin(-Math.PI * 0.42) * 22,
                      32 + Math.cos(Math.PI * 0.42) * 22, 32 + Math.sin(Math.PI * 0.42) * 22);
      });

      // 箭
      mk('arrow', 30, 10, g => {
        g.fillStyle(0xc98b4b, 1);
        g.fillRect(2, 4, 20, 2.5);
        g.fillStyle(0xf5f0e6, 1);
        g.fillTriangle(22, 1, 30, 5, 22, 9);
        g.fillStyle(0x8a5a2e, 1);
        g.fillTriangle(0, 2, 7, 5, 0, 8);
      });

      // 经验宝石
      mk('gem', 18, 18, g => {
        g.fillStyle(0x1a3d33, 0.6);
        g.fillCircle(9, 9, 9);
        g.fillStyle(0x54e6c0, 1);
        g.fillTriangle(9, 1, 17, 9, 9, 17);
        g.fillTriangle(9, 1, 1, 9, 9, 17);
        g.fillStyle(0xc8fff0, 0.9);
        g.fillTriangle(9, 3, 14, 8, 9, 9);
      });

      // 史莱姆
      mk('slime', 44, 40, g => {
        g.fillStyle(0x000000, 0.25);
        g.fillEllipse(22, 35, 30, 8);
        g.fillStyle(0x43a047, 1);
        g.fillEllipse(22, 24, 36, 30);
        g.fillStyle(0x76d275, 1);
        g.fillEllipse(18, 18, 16, 12);
        g.fillStyle(0x0d2410, 1);
        g.fillCircle(15, 24, 2.6);
        g.fillCircle(29, 24, 2.6);
        g.lineStyle(2, 0x0d2410, 1);
        g.lineBetween(18, 31, 26, 31);
      });

      // 蝙蝠
      mk('bat', 52, 34, g => {
        g.fillStyle(0x6a3fa0, 1);
        g.fillTriangle(26, 16, 2, 2, 10, 26);
        g.fillTriangle(26, 16, 50, 2, 42, 26);
        g.fillStyle(0x8e5bd0, 1);
        g.fillCircle(26, 17, 10);
        g.fillTriangle(18, 9, 22, 0, 26, 9);
        g.fillTriangle(34, 9, 30, 0, 26, 9);
        g.fillStyle(0xff5d73, 1);
        g.fillCircle(22, 16, 2);
        g.fillCircle(30, 16, 2);
      });

      // 法师
      mk('mage', 44, 52, g => {
        g.fillStyle(0x000000, 0.25);
        g.fillEllipse(22, 47, 28, 8);
        g.fillStyle(0x2d4fa8, 1);
        g.fillTriangle(22, 16, 6, 46, 38, 46);
        g.fillStyle(0x1a2f68, 1);
        g.fillTriangle(22, 8, 4, 20, 40, 20);
        g.fillCircle(22, 26, 8);
        g.fillStyle(0x9fd0ff, 1);
        g.fillCircle(22, 26, 5);
        g.fillStyle(0x08203f, 1);
        g.fillCircle(20, 26, 1.6);
        g.fillCircle(25, 26, 1.6);
      });

      // 法师弹
      mk('orb', 22, 22, g => {
        g.fillStyle(0x2a6cff, 0.25);
        g.fillCircle(11, 11, 11);
        g.fillStyle(0x5b9bff, 0.85);
        g.fillCircle(11, 11, 7);
        g.fillStyle(0xdbeaff, 1);
        g.fillCircle(11, 11, 3.4);
      });

      // Boss
      mk('boss', 130, 130, g => {
        g.fillStyle(0x000000, 0.3);
        g.fillEllipse(65, 116, 84, 20);
        g.fillStyle(0x7c1d1d, 1);
        g.fillCircle(65, 62, 52);
        g.fillStyle(0xb02b2b, 1);
        g.fillCircle(65, 58, 42);
        g.fillStyle(0x3a0b0b, 1);
        g.fillTriangle(30, 24, 18, 0, 44, 16);
        g.fillTriangle(100, 24, 112, 0, 86, 16);
        g.fillStyle(0xffca3a, 1);
        g.fillCircle(48, 54, 8);
        g.fillCircle(82, 54, 8);
        g.fillStyle(0x220505, 1);
        g.fillCircle(48, 54, 4);
        g.fillCircle(82, 54, 4);
        g.lineStyle(5, 0x2a0606, 1);
        g.beginPath();
        g.arc(65, 78, 22, 0.15 * Math.PI, 0.85 * Math.PI, false);
        g.strokePath();
        g.fillStyle(0xf5f0e6, 1);
        g.fillTriangle(52, 84, 56, 96, 60, 84);
        g.fillTriangle(70, 84, 74, 96, 78, 84);
      });

      // 血粒子 / 光环
      mk('spark', 12, 12, g => {
        g.fillStyle(0xffffff, 1);
        g.fillCircle(6, 6, 5);
      });
    }

    /* ============ 初始化 ============ */
    create() {
      this.makeTextures();

      this.bg = this.add.tileSprite(0, 0, W, H, 'bg').setOrigin(0).setDepth(-10);
      this.vignette = this.add.rectangle(W / 2, H / 2, W, H, 0x000000, 0).setDepth(50).setScrollFactor(0);

      this.physics.world.setBounds(-80, -80, W + 160, H + 160);

      // 玩家
      this.player = this.physics.add.image(W / 2, H * 0.62, 'player').setDepth(6);
      this.player.body.setCircle(16, 12, 12);
      this.player.setCollideWorldBounds(false);

      this.bow = this.add.image(this.player.x, this.player.y, 'bow').setDepth(7).setOrigin(0.5);

      // 组
      this.arrows = this.physics.add.group();
      this.enemies = this.physics.add.group();
      this.orbs = this.physics.add.group();
      this.gems = this.physics.add.group();

      // 碰撞
      this.physics.add.overlap(this.arrows, this.enemies, this.onArrowHitEnemy, null, this);
      this.physics.add.overlap(this.player, this.enemies, this.onTouchEnemy, null, this);
      this.physics.add.overlap(this.player, this.orbs, this.onTouchOrb, null, this);

      // 输入
      this.cursors = this.input.keyboard.createCursorKeys();
      this.keyW = this.input.keyboard.addKey('W');
      this.keyA = this.input.keyboard.addKey('A');
      this.keyS = this.input.keyboard.addKey('S');
      this.keyD = this.input.keyboard.addKey('D');
      this.keyP = this.input.keyboard.addKey('P');
      this.keySpace = this.input.keyboard.addKey('SPACE');
      this.key1 = this.input.keyboard.addKey('ONE');
      this.key2 = this.input.keyboard.addKey('TWO');
      this.key3 = this.input.keyboard.addKey('THREE');

      this.stick = { active: false, id: -1, bx: 0, by: 0, dx: 0, dy: 0, len: 0 };
      this.stickG = this.add.graphics().setDepth(40).setVisible(false);

      this.input.addPointer(2);
      this.input.on('pointerdown', this.onPointerDown, this);
      this.input.on('pointermove', this.onPointerMove, this);
      this.input.on('pointerup', this.onPointerUp, this);
      this.input.on('pointerupoutside', this.onPointerUp, this);

      this.keyP.on('down', () => this.togglePause());
      this.keySpace.on('down', () => { if (this.state === 'title' || this.state === 'over') this.startRun(); });
      this.key1.on('down', () => this.chooseCard(0));
      this.key2.on('down', () => this.chooseCard(1));
      this.key3.on('down', () => this.chooseCard(2));

      this.makeUI();
      this.makeTitle();
      this.state = 'title';

      // 调试/自动演示：index.html?autostart=1&autoplay=1&debug=1
      const q = new URLSearchParams(location.search);
      this.autoplay = q.get('autoplay') === '1';
      this.debug = q.get('debug') === '1';
      if (this.debug) {
        this.time.addEvent({
          delay: 1000, loop: true, callback: () => {
            console.log('DBG state=' + this.state + ' t=' + this.elapsed.toFixed(1) +
              ' hp=' + Math.round(this.stats.hp) + '/' + this.stats.maxHp +
              ' lv=' + this.level + ' xp=' + Math.floor(this.xp) + '/' + this.xpNeed +
              ' kills=' + this.kills + ' enemies=' + this.enemies.countActive(true) +
              ' arrows=' + this.arrows.countActive(true) + ' gems=' + this.gems.countActive(true));
          }
        });
      }
      if (q.get('autostart')) this.startRun();
    }

    /* ============ UI ============ */
    makeUI() {
      this.ui = this.add.container(0, 0).setDepth(30);

      this.lvText = this.add.text(24, 16, 'Lv.1', { fontFamily: FONT, fontSize: '30px', color: '#e8f6ff', fontStyle: 'bold' });
      this.hpBg = this.add.rectangle(24, 58, 264, 18, 0x141b2c, 1).setOrigin(0, 0.5).setStrokeStyle(2, 0x2a3552);
      this.hpFill = this.add.rectangle(26, 58, 260, 12, 0x39d98a, 1).setOrigin(0, 0.5);
      this.hpText = this.add.text(296, 58, '100/100', { fontFamily: FONT, fontSize: '17px', color: '#9fb3c8' }).setOrigin(0, 0.5);

      this.timeText = this.add.text(W / 2, 18, '00:00', { fontFamily: FONT, fontSize: '30px', color: '#dbe9ff', fontStyle: 'bold' }).setOrigin(0.5, 0);
      this.waveText = this.add.text(W / 2, 56, '第 1 波', { fontFamily: FONT, fontSize: '18px', color: '#7f93b3' }).setOrigin(0.5, 0);

      this.killText = this.add.text(W - 24, 18, '击杀 0', { fontFamily: FONT, fontSize: '20px', color: '#ffd166' }).setOrigin(1, 0);
      this.pauseBtn = this.add.text(W - 24, 52, '❚❚', { fontFamily: FONT, fontSize: '22px', color: '#8fa3c4' }).setOrigin(1, 0).setInteractive({ useHandCursor: true });
      this.pauseBtn.on('pointerdown', () => this.togglePause());

      this.xpBg = this.add.rectangle(0, H - 16, W, 16, 0x101627, 1).setOrigin(0, 0);
      this.xpFill = this.add.rectangle(0, H - 16, 0, 16, 0x3b82f6, 1).setOrigin(0, 0);
      this.xpText = this.add.text(W - 12, H - 34, 'EXP 0/8', { fontFamily: FONT, fontSize: '14px', color: '#7ea4d8' }).setOrigin(1, 1);

      this.bossBarBg = this.add.rectangle(W / 2, 104, W - 140, 14, 0x241016, 0.95).setOrigin(0.5).setStrokeStyle(2, 0x5c2430).setVisible(false);
      this.bossBar = this.add.rectangle(W / 2 - (W - 144) / 2, 104, W - 144, 8, 0xff4d6d, 1).setOrigin(0, 0.5).setVisible(false);
      this.bossName = this.add.text(W / 2, 80, '精英怪', { fontFamily: FONT, fontSize: '16px', color: '#ff8fa3' }).setOrigin(0.5).setVisible(false);

      this.ui.add([this.lvText, this.hpBg, this.hpFill, this.hpText, this.timeText, this.waveText,
        this.killText, this.pauseBtn, this.xpBg, this.xpFill, this.xpText,
        this.bossBarBg, this.bossBar, this.bossName]);
      this.ui.setVisible(false);
    }

    makeTitle() {
      this.title = this.add.container(0, 0).setDepth(45);
      const dim = this.add.rectangle(W / 2, H / 2, W, H, 0x060912, 0.86);
      const t1 = this.add.text(W / 2, H * 0.27, '弓箭手大作战', { fontFamily: FONT, fontSize: '66px', color: '#eaf7ff', fontStyle: 'bold' }).setOrigin(0.5);
      const t2 = this.add.text(W / 2, H * 0.34, '野狗复刻版 · 五成像', { fontFamily: FONT, fontSize: '24px', color: '#54e6c0' }).setOrigin(0.5);
      const t3 = this.add.text(W / 2, H * 0.47,
        '自动瞄准 · 移动走位 · 吃经验升级\n每升一级三选一，活到后面全是爹',
        { fontFamily: FONT, fontSize: '21px', color: '#9fb3c8', align: 'center', lineSpacing: 10 }).setOrigin(0.5);
      const t4 = this.add.text(W / 2, H * 0.585,
        '手机：按住屏幕任意处拖动\n电脑：WASD / 方向键',
        { fontFamily: FONT, fontSize: '18px', color: '#6d7f9c', align: 'center', lineSpacing: 8 }).setOrigin(0.5);

      const btn = this.add.rectangle(W / 2, H * 0.72, 320, 92, 0x1f8f62, 1).setStrokeStyle(3, 0x62f0b6);
      const btnT = this.add.text(W / 2, H * 0.72, '开始狩猎', { fontFamily: FONT, fontSize: '34px', color: '#eafff6', fontStyle: 'bold' }).setOrigin(0.5);
      btn.setInteractive({ useHandCursor: true });
      btn.on('pointerdown', () => { if (this.state === 'title' || this.state === 'over') this.startRun(); });

      const foot = this.add.text(W / 2, H * 0.88, 'REA 拆玩法 · Phaser 手搓 · 无素材纯几何', { fontFamily: FONT, fontSize: '15px', color: '#43516b' }).setOrigin(0.5);
      this.title.add([dim, t1, t2, t3, t4, btn, btnT, foot]);
    }

    /* ============ 开局 ============ */
    startRun() {
      // 清场
      this.title.setVisible(false);
      this.ui.setVisible(true);
      this.overlay && this.overlay.destroy();
      this.overlay = null;
      this.cards = null;

      [this.arrows, this.enemies, this.orbs, this.gems].forEach(g => g.clear(true, true));
      this.floaters && this.floaters.remove(true);
      this.floaters = [];

      this.stats = {
        hp: 100, maxHp: 100, speed: 260, dmg: 10, fireMs: 380,
        arrows: 1, pierce: 0, crit: 0.05, critMult: 2, regen: 0, magnet: 100, bounce: 0
      };
      this.taken = {};
      this.level = 1;
      this.xp = 0;
      this.xpNeed = 8;
      this.kills = 0;
      this.elapsed = 0;
      this.fireCd = 0;
      this.spawnCd = 600;
      this.nextBoss = (new URLSearchParams(location.search).get('fast') === '1') ? 14 : 50;
      this.invuln = 0;
      this.regenAcc = 0;
      this.boss = null;
      this.bossMaxHp = 0;
      this.shakeCd = 0;

      this.player.setPosition(W / 2, H * 0.62);
      this.player.setAlpha(1);
      this.player.body.reset(W / 2, H * 0.62);
      this.player.setVisible(true);
      this.bow.setVisible(true);

      this.state = 'playing';
      this.stick.active = false;
      this.stickG.setVisible(false);
      this.hint = this.add.text(W / 2, H * 0.82, '拖动屏幕移动 · 自动射击', {
        fontFamily: FONT, fontSize: '20px', color: '#5d7092'
      }).setOrigin(0.5).setDepth(35);
      this.tweens.add({ targets: this.hint, alpha: 0, delay: 2200, duration: 800, onComplete: () => this.hint.destroy() });

      if (this.audio) this.audio.resume();
      this.updUI();
    }

    /* ============ 输入 ============ */
    onPointerDown(p) {
      this.initAudio();
      if (this.state !== 'playing') return;
      if (p.y < 110) return; // 顶部 UI 区
      this.stick.active = true;
      this.stick.id = p.id;
      this.stick.bx = p.x;
      this.stick.by = p.y;
      this.stick.dx = 0;
      this.stick.dy = 0;
      this.stick.len = 0;
      this.stickG.setVisible(true);
    }

    onPointerMove(p) {
      if (!this.stick.active || p.id !== this.stick.id) return;
      let dx = p.x - this.stick.bx;
      let dy = p.y - this.stick.by;
      const len = Math.hypot(dx, dy);
      const max = 90;
      if (len > max) {
        dx = dx / len * max;
        dy = dy / len * max;
      }
      this.stick.dx = dx / max;
      this.stick.dy = dy / max;
      this.stick.kx = this.stick.bx + dx;
      this.stick.ky = this.stick.by + dy;
    }

    onPointerUp(p) {
      if (this.stick.active && p.id === this.stick.id) {
        this.stick.active = false;
        this.stick.dx = 0;
        this.stick.dy = 0;
        this.stickG.setVisible(false);
      }
    }

    /* ============ 音效 ============ */
    initAudio() {
      if (this.audio) return;
      try {
        const AC = window.AudioContext || window.webkitAudioContext;
        if (!AC) return;
        this.audio = new AC();
      } catch (e) { /* 静音也能玩 */ }
    }

    sfx(freq, dur, type, vol) {
      if (!this.audio) return;
      try {
        const t = this.audio.currentTime;
        const o = this.audio.createOscillator();
        const g = this.audio.createGain();
        o.type = type || 'square';
        o.frequency.setValueAtTime(freq, t);
        o.frequency.exponentialRampToValueAtTime(Math.max(40, freq * 0.6), t + dur);
        g.gain.setValueAtTime(vol == null ? 0.05 : vol, t);
        g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
        o.connect(g).connect(this.audio.destination);
        o.start(t);
        o.stop(t + dur + 0.02);
      } catch (e) { /* ignore */ }
    }

    /* ============ 主循环 ============ */
    update(time, delta) {
      const dt = Math.min(delta, 50) / 1000;
      if (this.state === 'playing') this.stepGame(dt, delta);
      else if (this.state === 'levelup' || this.state === 'paused') this.stickG.setVisible(false);
    }

    stepGame(dt, delta) {
      this.elapsed += dt;

      /* --- 移动 --- */
      let mx = 0, my = 0;
      if (this.cursors.left.isDown || this.keyA.isDown) mx -= 1;
      if (this.cursors.right.isDown || this.keyD.isDown) mx += 1;
      if (this.cursors.up.isDown || this.keyW.isDown) my -= 1;
      if (this.cursors.down.isDown || this.keyS.isDown) my += 1;
      if (this.stick.active) { mx += this.stick.dx; my += this.stick.dy; }
      if (this.autoplay) {
        const gs = this.gems.getChildren();
        let g = null;
        for (let i = 0; i < gs.length; i++) { if (gs[i].active) { g = gs[i]; break; } }
        if (g) {
          const a = Math.atan2(g.y - this.player.y, g.x - this.player.x);
          mx = Math.cos(a); my = Math.sin(a);
        } else {
          const a = this.elapsed * 1.35;
          mx = Math.cos(a); my = Math.sin(a * 1.13 + 0.7);
        }
      }
      const ml = Math.hypot(mx, my);
      if (ml > 1) { mx /= ml; my /= ml; }
      this.player.setVelocity(mx * this.stats.speed, my * this.stats.speed);
      this.player.setPosition(
        clamp(this.player.x, 24, W - 24),
        clamp(this.player.y, 120, H - 40)
      );

      /* --- 摇杆绘制 --- */
      if (this.stick.active) {
        this.stickG.clear();
        this.stickG.lineStyle(3, 0x7fe9c6, 0.55);
        this.stickG.strokeCircle(this.stick.bx, this.stick.by, 86);
        this.stickG.fillStyle(0x7fe9c6, 0.16);
        this.stickG.fillCircle(this.stick.bx, this.stick.by, 86);
        const kx = this.stick.kx == null ? this.stick.bx : this.stick.kx;
        const ky = this.stick.ky == null ? this.stick.by : this.stick.ky;
        this.stickG.fillStyle(0xd8fff1, 0.85);
        this.stickG.fillCircle(kx, ky, 30);
        this.stick.kx = null; this.stick.ky = null;
      }

      /* --- 目标与射击 --- */
      const target = this.nearestEnemy(this.player.x, this.player.y, 900);
      const aim = target ? Math.atan2(target.y - this.player.y, target.x - this.player.x) : -Math.PI / 2;
      this.bow.setPosition(this.player.x + Math.cos(aim) * 10, this.player.y + Math.sin(aim) * 10);
      this.bow.setRotation(aim);
      this.player.setFlipX(Math.cos(aim) < 0);

      this.fireCd -= delta;
      if (target && this.fireCd <= 0) {
        this.fireCd = this.stats.fireMs;
        this.fireArrows(aim, target);
      }

      /* --- 敌方 --- */
      this.updateEnemies(dt, delta);
      this.updateOrbs(dt);
      this.updateGems(dt);

      /* --- 回复 / 无敌 --- */
      if (this.stats.regen > 0 && this.stats.hp < this.stats.maxHp) {
        this.stats.hp = Math.min(this.stats.maxHp, this.stats.hp + this.stats.regen * dt);
      }
      if (this.invuln > 0) {
        this.invuln -= delta;
        this.player.setAlpha(0.5 + 0.5 * Math.abs(Math.sin(this.elapsed * 30)));
      } else {
        this.player.setAlpha(1);
      }

      /* --- 刷怪 --- */
      this.spawnCd -= delta;
      if (this.spawnCd <= 0) {
        const wave = 1 + Math.floor(this.elapsed / 30);
        this.spawnCd = clamp(1500 - this.elapsed * 14, 360, 1500);
        const n = wave >= 4 ? 2 : 1;
        for (let i = 0; i < n; i++) this.spawnEnemy(wave);
      }
      if (!this.boss && this.elapsed >= this.nextBoss) {
        this.spawnBoss(1 + Math.floor(this.elapsed / 50));
        this.nextBoss += 50;
      }

      /* --- 计时 / UI --- */
      this.updUI();

      /* --- 死没死 --- */
      if (this.stats.hp <= 0) this.gameOver();
    }

    /* ============ 射击 ============ */
    fireArrows(aim, target) {
      const n = this.stats.arrows;
      const spread = 0.13;
      for (let i = 0; i < n; i++) {
        const a = aim + (i - (n - 1) / 2) * spread;
        const arrow = this.arrows.create(
          this.player.x + Math.cos(a) * 22,
          this.player.y + Math.sin(a) * 22,
          'arrow'
        );
        arrow.setDepth(8);
        arrow.setRotation(a);
        arrow.body.setSize(20, 8);
        arrow.setData('dmg', this.stats.dmg);
        arrow.setData('crit', Math.random() < this.stats.crit);
        arrow.setData('pierce', this.stats.pierce);
        arrow.setData('bounce', this.stats.bounce);
        arrow.setData('hitIds', {});
        arrow.setData('life', 1.15);
        this.physics.velocityFromRotation(a, 820, arrow.body.velocity);
        // 命中时按暴击算伤害
        if (arrow.getData('crit')) arrow.setTint(0xffe066);
        else arrow.setTint(0xffffff);
      }
      this.sfx(720, 0.06, 'square', 0.025);
    }

    onArrowHitEnemy(arrow, enemy) {
      if (!arrow.active || !enemy.active) return;
      const hitIds = arrow.getData('hitIds');
      if (hitIds[enemy.name]) return;
      hitIds[enemy.name] = true;

      let dmg = arrow.getData('dmg');
      if (arrow.getData('crit')) dmg *= this.stats.critMult;
      dmg = Math.round(dmg);
      this.damageEnemy(enemy, dmg);
      this.spark(enemy.x, enemy.y, arrow.getData('crit') ? 0xffe066 : 0xffb3c1, 7);

      const pierce = arrow.getData('pierce');
      if (pierce > 0) {
        arrow.setData('pierce', pierce - 1);
      } else {
        const bounce = arrow.getData('bounce');
        if (bounce > 0) {
          const next = this.nearestEnemy(enemy.x, enemy.y, 260, enemy);
          if (next) {
            arrow.setData('bounce', bounce - 1);
            const a = Math.atan2(next.y - arrow.y, next.x - arrow.x);
            arrow.setRotation(a);
            this.physics.velocityFromRotation(a, 820, arrow.body.velocity);
            arrow.setData('life', 0.8);
            return;
          }
        }
        arrow.destroy();
      }
    }

    damageEnemy(enemy, dmg) {
      const hp = enemy.getData('hp') - dmg;
      enemy.setData('hp', hp);
      this.floatText(enemy.x, enemy.y - 24, String(dmg), dmg >= 30 ? '#ffd166' : '#ffffff');

      enemy.setTintFill(0xffffff);
      this.time.delayedCall(45, () => { if (enemy.active) enemy.clearTint(); });
      this.sfx(180, 0.05, 'sawtooth', 0.02);

      if (hp <= 0) this.killEnemy(enemy);
    }

    killEnemy(enemy) {
      const type = enemy.getData('type');
      const value = enemy.getData('xp') || 1;
      this.kills++;
      this.spark(enemy.x, enemy.y, type === 'boss' ? 0xff5d73 : 0x9ef0c9, type === 'boss' ? 34 : 10);
      if (type === 'boss') {
        this.boss = null;
        this.bossBarBg.setVisible(false); this.bossBar.setVisible(false); this.bossName.setVisible(false);
        this.cameras.main.shake(260, 0.012);
        for (let i = 0; i < 6; i++) this.dropGem(enemy.x + rnd(-50, 50), enemy.y + rnd(-50, 50), 3);
        this.sfx(90, 0.35, 'sawtooth', 0.08);
      } else {
        this.dropGem(enemy.x, enemy.y, value);
        this.sfx(300, 0.08, 'triangle', 0.02);
      }
      enemy.destroy();
    }

    dropGem(x, y, value) {
      const gem = this.gems.create(x, y, 'gem');
      gem.setDepth(3);
      gem.body.setCircle(8);
      gem.setData('value', value);
      gem.setScale(0.9);
      this.tweens.add({ targets: gem, scale: 1.15, duration: 160, yoyo: true });
    }

    /* ============ 敌人 ============ */
    spawnEnemy(wave) {
      if (this.enemies.countActive(true) > 55) return;
      const type = this.pickEnemyType(wave);
      const side = Math.floor(rnd(0, 4));
      let x, y;
      if (side === 0) { x = -34; y = rnd(140, H - 60); }
      else if (side === 1) { x = W + 34; y = rnd(140, H - 60); }
      else if (side === 2) { x = rnd(40, W - 40); y = 120 - 34; }
      else { x = rnd(40, W - 40); y = H + 34; }

      const base = 1 + wave * 0.55;
      let hp, speed, dmg, xp, tex, radius;

      if (type === 'slime') {
        hp = 20 * base; speed = rnd(58, 78); dmg = 8 + wave * 1.2; xp = 1; tex = 'slime'; radius = 15;
      } else if (type === 'bat') {
        hp = 13 * base; speed = rnd(120, 155); dmg = 6 + wave; xp = 1; tex = 'bat'; radius = 13;
      } else {
        hp = 30 * base; speed = 62; dmg = 10 + wave * 1.5; xp = 2; tex = 'mage'; radius = 14;
      }

      const e = this.enemies.create(x, y, tex);
      e.setDepth(5);
      e.setData('type', type);
      e.setData('hp', Math.round(hp));
      e.setData('maxHp', Math.round(hp));
      e.setData('speed', speed);
      e.setData('dmg', dmg);
      e.setData('xp', xp);
      e.setData('phase', rnd(0, Math.PI * 2));
      e.setData('shotCd', rnd(900, 1800));
      e.body.setCircle(radius, e.width / 2 - radius, e.height / 2 - radius);
      e.name = 'e' + (this.enemyId = (this.enemyId || 0) + 1);

      if (type === 'slime') {
        this.tweens.add({ targets: e, scaleY: 0.86, scaleX: 1.1, duration: 420, yoyo: true, repeat: -1, ease: 'Sine.inOut' });
      }
      return e;
    }

    pickEnemyType(wave) {
      const r = Math.random();
      if (wave < 2) return r < 0.8 ? 'slime' : 'bat';
      if (wave < 5) return r < 0.55 ? 'slime' : (r < 0.85 ? 'bat' : 'mage');
      return r < 0.38 ? 'slime' : (r < 0.7 ? 'bat' : 'mage');
    }

    spawnBoss(level) {
      const side = Math.floor(rnd(0, 4));
      let x, y;
      if (side === 0) { x = -70; y = H * 0.4; }
      else if (side === 1) { x = W + 70; y = H * 0.4; }
      else if (side === 2) { x = W / 2; y = 60; }
      else { x = W / 2; y = H + 70; }

      const hp = Math.round(420 * (1 + level * 0.85));
      const e = this.enemies.create(x, y, 'boss');
      e.setDepth(5);
      e.setData('type', 'boss');
      e.setData('hp', hp);
      e.setData('maxHp', hp);
      e.setData('speed', 58);
      e.setData('dmg', 18 + level * 2);
      e.setData('xp', 15);
      e.setData('shotCd', 1600);
      e.setData('phase', 0);
      e.body.setCircle(48, 17, 17);
      e.name = 'boss' + level;
      this.boss = e;
      this.bossMaxHp = hp;
      this.bossBarBg.setVisible(true); this.bossBar.setVisible(true); this.bossName.setVisible(true);
      this.bossName.setText('精英怪 Lv.' + level);
      this.bossBar.setDisplaySize(W - 144, 8);
      this.cameras.main.flash(260, 120, 10, 20);
      this.sfx(70, 0.4, 'sawtooth', 0.09);
    }

    updateEnemies(dt, delta) {
      const list = this.enemies.getChildren();
      for (let i = list.length - 1; i >= 0; i--) {
        const e = list[i];
        if (!e.active) continue;
        const type = e.getData('type');
        const speed = e.getData('speed');
        const dx = this.player.x - e.x;
        const dy = this.player.y - e.y;
        const d = Math.hypot(dx, dy) || 1;

        if (type === 'slime') {
          e.setVelocity(dx / d * speed, dy / d * speed);
        } else if (type === 'bat') {
          const ph = e.getData('phase');
          const wobble = Math.sin(this.elapsed * 6 + ph) * 90;
          const px = -dy / d, py = dx / d;
          e.setVelocity(dx / d * speed + px * wobble, dy / d * speed + py * wobble);
        } else if (type === 'mage') {
          if (d > 330) e.setVelocity(dx / d * speed, dy / d * speed);
          else if (d < 230) e.setVelocity(-dx / d * speed, -dy / d * speed);
          else e.setVelocity(-dy / d * speed * 0.7, dx / d * speed * 0.7);

          let cd = e.getData('shotCd') - delta;
          if (cd <= 0 && d < 620) {
            cd = 1900 + Math.random() * 500;
            const a = Math.atan2(dy, dx);
            this.fireOrb(e.x, e.y, a, 220, e.getData('dmg'));
          }
          e.setData('shotCd', cd);
        } else if (type === 'boss') {
          e.setVelocity(dx / d * speed, dy / d * speed);
          let cd = e.getData('shotCd') - delta;
          if (cd <= 0) {
            cd = 2400;
            const n = 12;
            const base = Math.atan2(dy, dx);
            for (let k = 0; k < n; k++) {
              this.fireOrb(e.x, e.y, base + k * Math.PI * 2 / n, 190, e.getData('dmg') * 0.7);
            }
            this.sfx(140, 0.2, 'sawtooth', 0.05);
            this.cameras.main.shake(90, 0.004);
          }
          e.setData('shotCd', cd);
          // 血条
          if (this.boss === e) {
            const r = clamp(e.getData('hp') / this.bossMaxHp, 0, 1);
            this.bossBar.setDisplaySize((W - 144) * r, 8);
          }
        }

        // 出界太久回收
        if (type !== 'boss' && (e.x < -140 || e.x > W + 140 || e.y < -140 || e.y > H + 140)) {
          e.destroy();
        }
      }
    }

    fireOrb(x, y, angle, speed, dmg) {
      const o = this.orbs.create(x, y, 'orb');
      o.setDepth(7);
      o.body.setCircle(8);
      o.setData('dmg', dmg);
      o.setData('life', 4);
      this.physics.velocityFromRotation(angle, speed, o.body.velocity);
    }

    updateOrbs(dt) {
      const list = this.orbs.getChildren();
      for (let i = list.length - 1; i >= 0; i--) {
        const o = list[i];
        if (!o.active) continue;
        const life = o.getData('life') - dt;
        o.setData('life', life);
        if (life <= 0 || o.x < -60 || o.x > W + 60 || o.y < -60 || o.y > H + 60) o.destroy();
      }
    }

    nearestEnemy(x, y, maxDist, except) {
      let best = null, bd = maxDist * maxDist;
      const list = this.enemies.getChildren();
      for (let i = 0; i < list.length; i++) {
        const e = list[i];
        if (!e.active || e === except) continue;
        const d = dist2({ x, y }, e);
        if (d < bd) { bd = d; best = e; }
      }
      return best;
    }

    /* ============ 拾取 ============ */
    updateGems(dt) {
      const list = this.gems.getChildren();
      const magnet = this.stats.magnet;
      for (let i = list.length - 1; i >= 0; i--) {
        const g = list[i];
        if (!g.active) continue;
        const dx = this.player.x - g.x;
        const dy = this.player.y - g.y;
        const d = Math.hypot(dx, dy) || 1;
        if (d < magnet) {
          const sp = clamp(700 - d * 2, 180, 900);
          g.setVelocity(dx / d * sp, dy / d * sp);
        } else {
          g.setVelocity(0, 0);
        }
        if (d < 30) {
          this.gainXp(g.getData('value') || 1);
          g.destroy();
        }
      }
    }

    gainXp(v) {
      this.xp += v;
      while (this.xp >= this.xpNeed) {
        this.xp -= this.xpNeed;
        this.level++;
        this.xpNeed = Math.round(8 + this.level * 4.2);
        this.stats.hp = Math.min(this.stats.maxHp, this.stats.hp + 8);
        this.levelUp();
      }
    }

    /* ============ 升级三选一 ============ */
    levelUp() {
      if (this.state === 'levelup') { this.pendingLevel = (this.pendingLevel || 0) + 1; return; }
      this.state = 'levelup';
      this.player.setVelocity(0, 0);
      this.stickG.setVisible(false);
      this.sfx(880, 0.12, 'triangle', 0.05);

      const pool = UPGRADES.filter(u => (this.taken[u.id] || 0) < u.max);
      const hand = [];
      while (hand.length < 3 && pool.length) {
        const idx = Math.floor(Math.random() * pool.length);
        hand.push(pool.splice(idx, 1)[0]);
      }

      const c = this.add.container(0, 0).setDepth(60);
      const dim = this.add.rectangle(W / 2, H / 2, W, H, 0x05070f, 0.78).setInteractive();
      const title = this.add.text(W / 2, 210, '升级 · 选一个', { fontFamily: FONT, fontSize: '28px', color: '#8ff0c8' }).setOrigin(0.5);
      const sub = this.add.text(W / 2, 254, 'Lv.' + this.level + '　点卡牌 / 按 1 2 3', { fontFamily: FONT, fontSize: '18px', color: '#6f86a8' }).setOrigin(0.5);
      c.add([dim, title, sub]);

      this.cards = [];
      hand.forEach((u, i) => {
        const y = 400 + i * 246;
        const rect = this.add.rectangle(W / 2, y, 560, 200, 0x121a2e, 0.98).setStrokeStyle(3, 0x2f4468);
        const tag = this.add.text(W / 2, y - 58, String(i + 1), { fontFamily: FONT, fontSize: '18px', color: '#3c5276' }).setOrigin(0.5);
        const name = this.add.text(W / 2, y - 16, u.n, { fontFamily: FONT, fontSize: '38px', color: '#f0f8ff', fontStyle: 'bold' }).setOrigin(0.5);
        const desc = this.add.text(W / 2, y + 42, u.d, { fontFamily: FONT, fontSize: '22px', color: '#8fb0d8' }).setOrigin(0.5);
        const lv = this.add.text(W / 2, y + 76, '已选 ' + (this.taken[u.id] || 0) + ' / ' + u.max, { fontFamily: FONT, fontSize: '15px', color: '#4c6183' }).setOrigin(0.5);
        rect.setInteractive({ useHandCursor: true });
        rect.on('pointerover', () => rect.setStrokeStyle(3, 0x62f0b6));
        rect.on('pointerout', () => rect.setStrokeStyle(3, 0x2f4468));
        rect.on('pointerdown', () => this.chooseCard(i));
        c.add([rect, tag, name, desc, lv]);
        this.cards.push({ u, rect, texts: [tag, name, desc, lv] });
      });

      this.overlay = c;
      if (this.autoplay) {
        this.time.delayedCall(220, () => this.chooseCard(Math.floor(Math.random() * 3)));
      }
    }

    chooseCard(i) {
      if (this.state !== 'levelup' || !this.cards || !this.cards[i]) return;
      const card = this.cards[i];
      card.u.apply(this.stats);
      this.taken[card.u.id] = (this.taken[card.u.id] || 0) + 1;
      this.sfx(1040, 0.1, 'sine', 0.05);

      this.overlay.destroy();
      this.overlay = null;
      this.cards = null;
      this.state = 'playing';
      if (this.pendingLevel) {
        const n = this.pendingLevel;
        this.pendingLevel = 0;
        for (let k = 0; k < n; k++) this.levelUp();
      }
    }

    /* ============ 暂停 ============ */
    togglePause() {
      if (this.state === 'playing') {
        this.state = 'paused';
        this.player.setVelocity(0, 0);
        this.stick.active = false;
        this.stickG.setVisible(false);
        this.overlay = this.add.container(0, 0).setDepth(58);
        const dim = this.add.rectangle(W / 2, H / 2, W, H, 0x05070f, 0.7).setInteractive();
        const t = this.add.text(W / 2, H / 2 - 40, '暂停', { fontFamily: FONT, fontSize: '52px', color: '#eaf7ff', fontStyle: 'bold' }).setOrigin(0.5);
        const t2 = this.add.text(W / 2, H / 2 + 40, '点屏幕 / P 继续', { fontFamily: FONT, fontSize: '20px', color: '#7d92b3' }).setOrigin(0.5);
        dim.on('pointerdown', () => this.togglePause());
        this.overlay.add([dim, t, t2]);
      } else if (this.state === 'paused') {
        this.overlay.destroy();
        this.overlay = null;
        this.state = 'playing';
      }
    }

    /* ============ 受伤 ============ */
    onTouchEnemy(player, enemy) {
      if (this.state !== 'playing' || !enemy.active) return;
      this.hurt(enemy.getData('dmg') || 8, enemy.x, enemy.y);
      // 击退敌人一点
      const a = Math.atan2(enemy.y - player.y, enemy.x - player.x);
      enemy.x += Math.cos(a) * 14;
      enemy.y += Math.sin(a) * 14;
    }

    onTouchOrb(player, orb) {
      if (this.state !== 'playing' || !orb.active) return;
      this.hurt(orb.getData('dmg') || 8, orb.x, orb.y);
      orb.destroy();
    }

    hurt(dmg, sx, sy) {
      if (this.invuln > 0) return;
      dmg = Math.round(dmg);
      this.stats.hp -= dmg;
      this.invuln = 620;
      this.floatText(this.player.x, this.player.y - 34, '-' + dmg, '#ff6b81');
      this.spark(this.player.x, this.player.y, 0xff6b81, 16);
      this.cameras.main.shake(140, 0.008);
      this.cameras.main.flash(90, 120, 0, 20);
      this.sfx(120, 0.18, 'sawtooth', 0.06);
      if (this.stats.hp <= 0) this.stats.hp = 0;
    }

    /* ============ 视觉 ============ */
    spark(x, y, color, n) {
      n = Math.min(n, 26);
      for (let i = 0; i < n; i++) {
        const p = this.add.circle(x, y, rnd(2, 5), color, 1).setDepth(9);
        const a = rnd(0, Math.PI * 2);
        const d = rnd(20, 90);
        this.tweens.add({
          targets: p, x: x + Math.cos(a) * d, y: y + Math.sin(a) * d,
          alpha: 0, scale: 0.2, duration: rnd(220, 480), ease: 'Cubic.out',
          onComplete: () => p.destroy()
        });
      }
    }

    floatText(x, y, txt, color) {
      const t = this.add.text(x, y, txt, {
        fontFamily: FONT, fontSize: '25px', color: color || '#ffffff', fontStyle: 'bold',
        stroke: '#000000', strokeThickness: 4
      }).setOrigin(0.5).setDepth(20);
      this.tweens.add({ targets: t, y: y - 52, alpha: 0, duration: 620, ease: 'Cubic.out', onComplete: () => t.destroy() });
    }

    /* ============ UI 更新 ============ */
    updUI() {
      const s = this.stats;
      const r = clamp(s.hp / s.maxHp, 0, 1);
      this.hpFill.setDisplaySize(260 * r, 12);
      this.hpFill.setFillStyle(r > 0.5 ? 0x39d98a : (r > 0.25 ? 0xf5b942 : 0xff5d73), 1);
      this.hpText.setText(Math.ceil(s.hp) + '/' + s.maxHp);
      this.lvText.setText('Lv.' + this.level);
      this.killText.setText('击杀 ' + this.kills);

      const m = Math.floor(this.elapsed / 60);
      const sec = Math.floor(this.elapsed % 60);
      this.timeText.setText((m < 10 ? '0' : '') + m + ':' + (sec < 10 ? '0' : '') + sec);
      this.waveText.setText('第 ' + (1 + Math.floor(this.elapsed / 30)) + ' 波');

      this.xpFill.setDisplaySize(W * clamp(this.xp / this.xpNeed, 0, 1), 16);
      this.xpText.setText('EXP ' + Math.floor(this.xp) + '/' + this.xpNeed + '　·　最强搭配自己凑');
    }

    /* ============ 结束 ============ */
    gameOver() {
      if (this.state === 'over') return;
      this.state = 'over';
      this.player.setVelocity(0, 0);
      this.stickG.setVisible(false);
      this.cameras.main.shake(380, 0.02);
      this.sfx(70, 0.6, 'sawtooth', 0.08);

      const c = this.add.container(0, 0).setDepth(70);
      const dim = this.add.rectangle(W / 2, H / 2, W, H, 0x03050b, 0.84).setInteractive();
      const t1 = this.add.text(W / 2, H * 0.26, '你死了', { fontFamily: FONT, fontSize: '72px', color: '#ff5d73', fontStyle: 'bold' }).setOrigin(0.5);
      const mm = Math.floor(this.elapsed / 60), ss = Math.floor(this.elapsed % 60);
      const t2 = this.add.text(W / 2, H * 0.38,
        '存活 ' + (mm < 10 ? '0' : '') + mm + ':' + (ss < 10 ? '0' : '') + ss +
        '\n等级 ' + this.level + '　击杀 ' + this.kills +
        '\n得分 ' + (this.kills * 10 + this.level * 50 + Math.floor(this.elapsed)),
        { fontFamily: FONT, fontSize: '27px', color: '#c9d8ee', align: 'center', lineSpacing: 14 }).setOrigin(0.5);

      const btn = this.add.rectangle(W / 2, H * 0.62, 330, 96, 0x1f8f62, 1).setStrokeStyle(3, 0x62f0b6);
      const bt = this.add.text(W / 2, H * 0.62, '再来一局', { fontFamily: FONT, fontSize: '34px', color: '#eafff6', fontStyle: 'bold' }).setOrigin(0.5);
      btn.setInteractive({ useHandCursor: true });
      btn.on('pointerdown', () => { c.destroy(); this.startRun(); });

      const tip = this.add.text(W / 2, H * 0.73, '空格 / 点按钮重开', { fontFamily: FONT, fontSize: '17px', color: '#5f7394' }).setOrigin(0.5);
      c.add([dim, t1, t2, btn, bt, tip]);
      this.overlay = c;
    }
  }

  const game = new Phaser.Game({
    type: Phaser.AUTO,
    parent: 'game',
    width: W,
    height: H,
    backgroundColor: '#0b0e17',
    physics: {
      default: 'arcade',
      arcade: { gravity: { y: 0 }, debug: false }
    },
    scale: {
      mode: Phaser.Scale.FIT,
      autoCenter: Phaser.Scale.CENTER_BOTH,
      width: W,
      height: H
    },
    render: { antialias: true, roundPixels: false },
    scene: [MainScene]
  });

  window.__game = game;
})();
