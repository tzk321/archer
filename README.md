# archer

弓箭手（Archero 类）小游戏的多个实验版本，从纯 Web 到 Godot 都有。

| 目录 | 形态 | 说明 |
|---|---|---|
| `archer-game/` | 纯 JS/HTML | 最早的可玩原型，`index.html` 直接开 |
| `archer-dev/` | GDScript | 调参、手感迭代的草稿区，附 `RESULT*.md` 结果记录 |
| `archer-godot/` | Godot 4 | 主工程：6 职业、78 技能、20 关 |
| `archer_v2/` | Godot 4 | 上一代工程，留作比对 |
| `archero-ref/` | 第三方 | 参考实现，**不是我的代码**，只用来对数值和手感 |

## 跑起来

- Web 版：浏览器打开 `archer-game/index.html`
- Godot 版：用 Godot 4.x 导入 `archer-godot/project.godot` 后运行，或导出 APK

## 主工程要点（archer-godot）

- 横屏 1280×720，纯几何绘制，无外部美术素材
- 6 职业 × 8–9 个专属技能，技能池不互通
- 20 关固定地形/BOSS，每关 2 分钟 6 波
- 武器 20+ 把：长剑、巨斧、镰刀、法杖、骨杖……近战远程各一套弹道
