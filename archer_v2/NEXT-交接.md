# 交接：弓箭手大作战 · Godot v2

日期：2026-10-19
前一手：v1（720×1280 竖屏 demo）
本手：v2（1280×720 横屏，内容量达标，已导出/实机验收）

---

## 0. 交付物

```
WSL: /home/sbtzk/games/archer-godot          # v2 工程
WSL: /home/sbtzk/games/archer-godot-v1       # v1 备份（133MB）
手机: /sdcard/Download/ArcherGodot.apk       # v2 APK，包名 top.tzk.archergodot
手机: /sdcard/Download/ArcherGodot-win64.exe # v2 Windows 单文件
手机: /sdcard/Download/archer-godot-v2-src.zip
手机: /sdcard/Download/archer-godot-v2-handoff.zip
```

---

## 1. 硬指标完成情况

| 指标 | 结果 |
|---|---|
| 横屏 1280×720 | ✅ viewport 1280×720 + orientation=0，UI 全部重排 |
| 降难度 | ✅ 150 血 + 25% 减伤 + 0.8s 无敌 + 敌上限 32；自动测试 200s 存活（Lv.16，2 BOSS，minHP 97） |
| 技能商店 ≥20 | ✅ 24 技能，金币购买/升级/刷新（3 金），每 3 波自动开，也可按 B |
| 关卡 ≥20 | ✅ 20 关，数据驱动，6 类地形区 + 5 类天气 + 障碍 + 黑暗 |
| 皮肤 ≥20 | ✅ 20 套，12 种头饰，金币解锁，存 settings.cfg |
| 特效 ≥20 | ✅ 20 个，10 命中 / 5 击杀 / 3 升级 / 2 拖尾，可切换 |
| 武器 ≥20 | ✅ 20 把，10 把有独立机制（爆炸/冰冻/燃烧/毒/闪电链/追踪/回旋/霰弹/斩杀/荆棘） |
| 玩法机制 ≥4 | ✅ 5 波词缀、5 随机事件、5 精英词缀、连击倍率、冲刺、BOSS 轮换 |
| 计数可打印 | ✅ `--test` 日志 `CONTENT skills=24 weapons=20 levels=20 skins=20 effects=20` |
| APK + exe | ✅ 已重新导出；APK 已 `pm install -r` 实机启动、截图/OCR 验收 |

---

## 2. 工程结构

```
project.godot            # 1280×720 横屏，GL Compatibility，ETC2/ASTC
main.tscn                # 单 Node2D
game.gd                  # 状态机 / 战斗 / UI / 绘制 / 音效（约 2700 行）
data/skills.gd           # 24 技能
data/weapons.gd          # 20 武器
data/levels.gd           # 20 关卡
data/skins.gd            # 20 皮肤
data/effects.gd          # 20 特效
font.ttf                 # Noto Sans CJK SC 子集（549 字，218 KB）
export_presets.cfg       # Windows / Android，version 2.0.0 code 2
dist/windows/ArcherGodot.exe
dist/android/ArcherGodot.apk
dist/archer-godot-v2-src.zip
README.md
```

### 关键系统

- `meta`（ConfigFile `user://settings.cfg`）：局外金币、装备武器/皮肤、4 类特效、已解锁列表、最高分
- `start_run()`：按装备武器初始化弹道/伤害；技能在此之上叠乘
- 技能商店：每 3 波 `open_shop()`；5 个随机未满级技能；价格 = 基础价 + 已购等级×3
- 关卡：`setup_level(idx)` 按数据生成障碍/地形区/天气；每 2 波换关；20 关循环
- 事件：`next_event` 每 34–54 秒触发商队/血月/补给/精英狩猎/流星雨
- 词缀：每 5 波随机狂暴/分裂/护盾/毒雾/财宝，作用于刷怪与击杀
- 连击：2.2 秒窗口，金币倍率最高 +100%
- 测试：`--test` 100 秒、`--long` 200 秒，自动走位/选卡/购物，打印 `TEST_SUMMARY`/`TEST_DONE`

---

## 3. 构建 / 安装命令

```sh
K='sh /storage/emulated/0/Android/data/me.rerere.rikkahub/files/skills/kali/scripts/kk'
$K bg arc-test <<'EOF'
export HOME=/root
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ssh -o BatchMode=yes wsl "export XDG_CONFIG_HOME=/home/sbtzk/jobs/godot-chair-riot/tools/config; export XDG_DATA_HOME=/home/sbtzk/jobs/godot-chair-riot/tools/data; /home/sbtzk/jobs/godot-chair-riot/tools/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --fixed-fps 60 --path /home/sbtzk/games/archer-godot -- --test --long"
echo EXIT=$?
EOF
$K log arc-test
```

导出（同 v1，模板/keystore 路径不变）：

```sh
$K bg arc-export <<'EOF'
...
cd /home/sbtzk/games/archer-godot
G=/home/sbtzk/jobs/godot-chair-riot/tools/godot/Godot_v4.7.2-stable_linux.x86_64
$G --headless --path . --editor --import --quit
$G --headless --path . --export-release Windows
$G --headless --path . --export-debug Android
EOF
```

安装：

```sh
$K run 'scp -q wsl:~/games/archer-godot/dist/android/ArcherGodot.apk /sdcard/Download/ArcherGodot.apk'
su -c 'cp /sdcard/Download/ArcherGodot.apk /data/local/tmp/ArcherGodot.apk && chmod 644 /data/local/tmp/ArcherGodot.apk && pm install -r /data/local/tmp/ArcherGodot.apk'
su -c 'am start -n top.tzk.archergodot/com.godot.game.GodotApp'
```

---

## 4. 验收证据

- 最终构建 200 秒自动测试：`TEST_SUMMARY t=197.7 hp=141 lv=15 kills=310 gold=803 best_combo=238 bosses=2`、`TEST_DONE`，0 条 `SCRIPT ERROR|ERROR:`
- 横屏渲染帧 1280×720；OCR 识别到大厅、HUD、商店、升级、图鉴、结算文字
- boss 帧（12s，`--fast`）检测到 BOSS 血条红像素与「精英怪 Lv.1」

### 4.1 手机实机（2026-10-19 02:25–02:31）

- `pm install -r` 成功；启动后 Activity bounds `2400x1080`、`ROTATION_90`，横屏
- 触屏拖动摇杆正常：角色移动、自动射击、击杀、连击上涨
- 升级三选一：Lv.2 → Lv.17 多次弹卡，点选后技能生效、继续战斗
- 技能商店：第 3/6 波自动弹出，购买后卡池刷新、金币扣减
- BOSS：75 秒「精英怪 Lv.1」血条正常；第 5 波词缀「狂暴（敌人加速）」正常
- 4 分 33 秒时仍 420/420 血、Lv.36、778 杀、2700 金、连击 657（该局在上一构建；最终构建仅修复回旋镖回收，逻辑等价）
- 中文 OCR 全部可读，无方框；无崩溃/黑屏
- 结算（你死了）在桌面渲染与代码路径验证；手机这局被玩家打到 4 分+ 未自然死亡，未强行打断

---

## 5. 已知坑 / 待办

1. 字体子集：改中文文案后必须重新生成，否则方框。源 `~/.local/share/fonts/night-off-qa/NotoSansCJK-Regular.ttc` face 2，收集 `game.gd` + `data/*.gd` 全部字符。
2. `export_path` 相对项目根，不是相对 `dist`。
3. Android 需 `textures/vram_compression/import_etc2_astc=true`，别删。
4. 局外金币存档在 `user://settings.cfg`，`pm install -r` 不会清；要重置就 `pm clear top.tzk.archergodot`。
5. 手机侧装包要用 root 拷到 `/data/local/tmp`，app 读不了 Download 里别的 app 写的文件。
6. 关卡是程序化主题，不是手绘地图；要加新关只要往 `levels.gd` 追加，自动循环。
7. `--test` 的自动走位只躲敌人/弹幕/毒圈，不追求极限；人手有冲刺，容错更高。
