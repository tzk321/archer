# 瞎几把乱砍！ v4.4.1 · 按键失灵修复

日期：2026-10-19 14:32（CST）
候选：`candidate/ArcherGodot-v4.4.1.apk`
包名：`top.tzk.archergodot` · **4.4.1 / code14** · 旧证书 `8f43a812…fd15b`
APK SHA256：`20c270ce33e13b408a7370bd1cdd825f95ab3f6b1abeb13b0541f3eb5b1fa477`（29,374,770 B）
源码 ZIP SHA256：`9f62a0ad2d7b04bd9a2946c98ae596033bf5630adafb0c160130dcad7b841eb8`
状态：**已 pm install -r 上机，存档未动；等 tzk 实际手感确认**。

## 本轮修复

1. **按键失灵（根因）**：升级/商店/祭坛/暂停模块关闭时，旧代码调用 `_release_controls()`，把仍按住的移动/瞄准 owner 当成松手。无尽模式升级/商店频繁，所以“玩着玩着就失灵”。v4.4.1 不再在弹窗开关时清 owner；只要手指没松，弹窗关闭后摇杆/瞄准继续生效。
2. **owner 自愈**：新增 `active_touches` 记录活动手指。
   - 漏收 release：同 id 再按下时重新认领，不会被 `aim_active/stick_active` 卡死。
   - 同 id 新 press、owner 不在活动手指集合、非 owner 释放等情况会自动清理或重认。
   - 弹窗期间 DRAG 仍更新摇杆/瞄准向量，回来后方向是新的。
3. **删瞄准导线**：`draw_aim()` 里从角色到 250px 的长引导线已删除；保留准星、右侧瞄准环、蓄力环和“右侧按住瞄准”提示。

## 测试

| 项目 | 结果 |
|---|---|
| 原回归 | 697 项，0 失败 |
| 阻断 | 277 项，0 失败 |
| v4.3+控制 `tests/v43.gd` | 64 项，0 失败（新增弹窗保留双 owner、漏 release、同 id 重按、stale owner） |
| 摇杆 `tests/joystick.gd` | 57 项，0 失败（弹窗返回保留 owner，松手才清） |
| 无尽 | 14 项，0 失败 |
| 全近战 | 71 项，0 失败 |
| 20 关矩阵 | 48,234 项，0 失败（注入高属性，结构/时序） |
| 六职业 200 秒 | 6/6 通过 |
| 实渲染 | 46/46，含 melee/endless/aim |
| 绘制纯度 | 6 职业 × 12 页面 × 12 帧 + 无尽 HUD，0 失败 |
| 字体 | face2，791 字符 / 304,752 B / 缺字 0 |

## 手机

- 装机：`versionCode=14` / `versionName=4.4.1`；装机 APK 哈希 `20c270ce…a477`。
- 安装前快照：`/data/local/tmp/archer-v441/save-before-install`；安装前后 `settings.cfg` 均为 `68768137…095b`，没回写。
- 真实档已经验证到：永久强化 `atk10 / hp10 / speed7 / crit1 / greed7 / magnet4`；职业切到剑士，武器用过长剑、光剑——说明永久强化购买和近战切换在真机已实际使用。
- 之后正常游玩存档变为 `b7708fb6…da0a`，属于正常写档。
- 真机日志 `SCRIPT ERROR/FATAL/ERROR:` 计数 0。

## 未覆盖

- 修复后的“长按过弹窗不松手”最终手感需要 tzk 真机确认；headless 64+57 项覆盖了 owner 保持/自愈路径。
- 未做长时间真机 FPS/温升认证。
- 矩阵为注入属性结构测试，不是平衡结论。

## 文件

- `candidate/ArcherGodot-v4.4.1.apk`
- `archer-godot-v4.4.1-src.zip`
- `ready.json`、`SHA256SUMS`
- `review/` — 测试日志、46 张截图
- 手机：`Download/瞎几把乱砍！-v4.4.1.apk`；旧 4.4.0/4.3.0/4.2.1 包保留
