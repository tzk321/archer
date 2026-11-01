#!/usr/bin/env python3
p='/home/sbtzk/games/archer-godot/README.md'
s=open(p,encoding='utf-8').read()
s=s.replace('死亡结算金币，并持久化  与最高波次 。','死亡结算金币，并持久化 `best_endless` 与最高波次 `endless_wave`。')
s=s.replace('`--demo=level=20`/`elements`/`lobby`/`class`/`grid`/`skin`/`fx`/`shop`/`shop-owned`/`levelup`/`pause`/`over`/`ult`','`--demo=level=20`/`elements`/`melee`/`endless`/`lobby`/`class`/`grid`/`skin`/`fx`/`shop`/`shop-owned`/`levelup`/`pause`/`over`/`ult`')
s=s.replace('祭坛/悬赏/蓄力与永久强化在新 tests/v43.gd 中另有 55 项断言；','祭坛/悬赏/蓄力与永久强化在 tests/v43.gd 另有 55 项断言；无尽模式 tests/endless.gd 14 项、全近战 tests/melee_fx.gd 71 项；')
open(p,'w',encoding='utf-8').write(s)
print('readme fixed')
