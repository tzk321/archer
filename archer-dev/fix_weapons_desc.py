#!/usr/bin/env python3
p='/home/sbtzk/games/archer-godot/data/weapons.gd'
s=open(p,encoding='utf-8').read()
reps=[
('"d": "近战挥砍，稳定输出"','"d": "近战挥砍，满血伤害 +12%"'),
('"d": "宽弧横扫，击退"','"d": "宽弧横扫，后续目标 +25%"'),
('"d": "剑士专属，均衡挥砍"','"d": "剑士专属，满血伤害 +12%"'),
('"d": "剑士专属，重剑横扫"','"d": "剑士专属，后续目标 +25%"'),
('"d": "狂战专属，快速双持"','"d": "狂战专属，第二击 +35%"'),
]
for a,b in reps:
    assert s.count(a)==1, (a,s.count(a))
    s=s.replace(a,b)
open(p,'w',encoding='utf-8').write(s)
print('weapon descriptions updated')
