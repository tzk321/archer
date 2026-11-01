# 交接：弓箭手大作战 · Godot v4.0（新会话接手包）

日期：2026-10-19
上一版：v3.1（职业武器/技能池分离）
本版：v4.0（职业独立技能组、法杖特效、2 分钟一关、20 关独立、二次元 UI/人物/怪物）

---

## 0. 先读这个

工程在 WSL：`/home/sbtzk/games/archer-godot`
v1 备份：`/home/sbtzk/games/archer-godot-v1`
手机已装：`top.tzk.archergodot`，versionCode=5 / 4.0.0
交付文件（/sdcard/Download/）：

```
ArcherGodot.apk                    # v4.0.0，已装手机
ArcherGodot-win64.exe              # 105MB
archer-godot-v4-src.zip
archer-godot-v4-handoff.zip
```

---

## 1. v4 按你的要求做了什么

### 1.1 每个职业独立技能组（已完成）

- `data/skills.gd` 现在 78 个技能：
  - 24 个基础技能（保留兼容）
  - **50 个职业专属技能**，每个职业 8–9 个，互不串池：
    - 游侠：精准射击/连射/箭雨/破甲箭/鹰眼/疾风步/猎手直觉/自然回复
    - 剑士：剑术精通/疾风斩/铁壁/剑棘/血刃/不屈剑心/踏前斩/破绽
    - 法师：奥术强化/咏唱加速/三连法球/穿透奥术/爆裂火球/冰霜附着/雷霆链/法力护盾/元素专注
    - 刺客：致命一击/背刺/影步/瞬影/嗜血/飞刃/弹刃/穿影
    - 狂战：狂怒/暴走/战吼/铁皮/嗜血/反伤甲/崩山击/血盾
    - 召唤：狼群/兽魂/灵速/共生/自然恢复/闪电链/毒雾/灵体护盾/收获
  - 4 个觉醒（力量/生命/疾速/暴击），全职业商店通用
- `apply_skill()` 通过 `base` 字段复用底层效果；名字/描述/图标/池子独立
- 技能图标：专属技能 = 底层图标 + 职业色环（`_draw_skill_icon`）
- 升级三选一、商店技能只出本职业池

### 1.2 法师法杖特效（已修）

- 法杖/法书（火焰/冰/雷/暗/秘法书/骨杖/兽杖/魂铃）不再射箭：
  - 弹道改为发光法术球 + 拖尾 + 命中爆点
  - 开火时脚下出现法阵（`fx_at("level","rune",...)`）
  - 玩家手持法杖会画法杖图标 + 环绕光环
- 箭矢与法术球在 `draw_arrows` 分支绘制

### 1.3 一关 2 分钟 / 20 关独立（已完成）

- 常量：`LEVEL_TIME=120.0`、`WAVE_TIME=20.0`、`LEVEL_WAVES=6`
- 每关 120 秒、6 波；每关 90 秒刷本关 BOSS
- 20 关全部独立数据（`data/levels.gd`）：
  - 固定障碍布局 `obs_layout`（不再是随机撒点）
  - 固定地形区 `zone_layout`（冰/岩浆/毒/加速/治疗/虚空）
  - 每关专属 BOSS 名、敌人构成 `mix`、天气、配色、mod
- 关卡切换：`level_idx = int(elapsed/120)%20`，HUD 显示「第 X 关 · 名字 · 第 N/6 波」
- 每 2 波商店，每 3 波词缀/精英/回血

### 1.4 二次元 UI / 人物 / 怪物（已完成一版）

- UI：渐变星空 + 樱花瓣、圆角发光卡片 `_card_bg`、描边标题 `_outline_text`、
  职业色、商店/升级/图鉴/职业页统一
- 人物：大头、大眼白+虹膜+高光、腮红、围巾、头发刘海、轮廓描边
- 怪物：
  - 史莱姆：轮廓、白色大眼、腮红、嘴
  - 蝙蝠：双层翅膀、白色眼、獠牙
  - 法师：深色帽、发光脸、白色大眼、法球
  - BOSS：原有多色 + 光环
- 所有 UI 仍是纯几何绘制，无外置图片

---

## 2. 测试与证据

```
CONTENT skills=78 weapons=45 levels=20 skins=20 effects=20 classes=6 ultimates=10

标准 200s（游侠，2 分钟关卡）:
TEST_SUMMARY t=196.1 hp=190 lv=21 kills=510 gold=987 best_combo=245 bosses=1
TEST_DONE

100s 法师（法杖特效版）:
TEST_SUMMARY t=98.0 hp=130 lv=13 kills=297 gold=865 best_combo=282 bosses=1
TEST_DONE

渲染：lobby / class / shop / levelup / game 共 700 帧，0 条 SCRIPT ERROR
手机：v4.0.0 已安装启动，HUD 显示「第1关 · 星野 · 第1/6波」，刺客 140 血正常
```

---

## 3. 构建 / 安装

```sh
export XDG_CONFIG_HOME=/home/sbtzk/jobs/godot-chair-riot/tools/config
export XDG_DATA_HOME=/home/sbtzk/jobs/godot-chair-riot/tools/data
export ANDROID_USER_HOME=/home/sbtzk/jobs/godot-chair-riot/tools/android-user
G=/home/sbtzk/jobs/godot-chair-riot/tools/godot/Godot_v4.7.2-stable_linux.x86_64
$G --headless --path . --editor --import --quit
$G --headless --path . --export-release Windows
$G --headless --path . --export-debug Android
```

安装：

```sh
su -c 'cp /sdcard/Download/ArcherGodot.apk /data/local/tmp/ArcherGodot.apk && chmod 644 /data/local/tmp/ArcherGodot.apk && pm install -r /data/local/tmp/ArcherGodot.apk'
su -c 'am start -n top.tzk.archergodot/com.godot.game.GodotApp'
```

---

## 4. 新会话下一步（按优先级）

1. **职业平衡**：6 个职业各 8–9 个技能，Lv20+ 仍会满；建议每职业再加 2–3 个专属技能，或把核心技能 max 提高。
2. **20 关逐关验收**：跑 `--test --long` 或写 `--demo=level=5` 看每关固定障碍/BOSS/敌人构成是否卡位、是否刷在玩家脸上。
3. **二次元 UI 精修**：目前是几何风二次元；可加对话框/立绘框/表情气泡，但不要引入外部素材（项目约束）。
4. **法杖特效**：已改法术球；可继续加元素差异（火球爆点、冰晶、雷链、暗球吞噬）。
5. **手机端**：v4 已装；新会话改完重装，`pm install -r` 保留存档。
6. **字体**：现在 697 字、272KB；新增中文后重新生成（NotoSansCJK TTC face 2）。
7. **旧包**：v3.1 的 zip/apk 还在 Download，别覆盖错。

---

## 5. 已知坑

- `LEVEL_TIME` 改动后，`--test` 200 秒只能看到第 2 关；要测第 20 关需要长时间或加 `--demo=level=N`。
- 关卡 `obs_layout` 的坐标是 0–1 归一化，y 映射 `TOP..BOTTOM`；加新关注意别压玩家出生点（0.5,0.58）。
- `zone_layout` 的 kind 是数字：0 冰 / 1 岩浆 / 2 毒 / 3 加速 / 4 治疗 / 5 虚空。
- 职业专属技能使用 `base` 字段映射；新增职业技能必须填 `base`，否则 `apply_skill` 不生效。
- 技能图标未单独绘制时，会回退到 `base` 图标 + 职业色环。
- 动画/UI 全部在 `_draw` 里，手机性能以 K70 实测为准；粒子多时注意上限。
- `pm install -r` 不清 `user://settings.cfg`；要重置用 `pm clear top.tzk.archergodot`。

---

## 6. 文件结构

```
project.godot            # v4.0，1280×720 横屏
game.gd                  # 主逻辑 + UI/二次元绘制 + 法杖弹道 + 关卡
data/skills.gd           # 78 技能 + CLASS_SKILLS
data/weapons.gd          # 45 武器 + CLASS_WEAPONS
data/levels.gd           # 20 独立关卡（固定布局/BOSS/mix/2min）
data/classes.gd          # 6 职业 + 初始技能
data/ultimates.gd        # 10 传说
data/skins.gd            # 20 皮肤
data/effects.gd          # 20 特效
font.ttf                 # 697 字子集，272KB
README.md
NEXT-交接.md             # 本文件
dist/windows/ArcherGodot.exe
dist/android/ArcherGodot.apk
```
