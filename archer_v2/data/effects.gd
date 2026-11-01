extends RefCounted

## 20 个特效：命中 10、击杀 5、升级 3、弹道拖尾 2。
## cat: hit/kill/level/trail  style 决定绘制方式。

const LIST := [
	{ "id": "spark",     "n": "火花",     "cat": "hit",   "style": "spark",     "c1": "#ffd166", "c2": "#ffffff", "cost": 0 },
	{ "id": "star",      "n": "星形",     "cat": "hit",   "style": "star",      "c1": "#ffe08a", "c2": "#ff9a3a", "cost": 20 },
	{ "id": "ring",      "n": "环形",     "cat": "hit",   "style": "ring",      "c1": "#7ee0c0", "c2": "#ffffff", "cost": 20 },
	{ "id": "cross",     "n": "十字",     "cat": "hit",   "style": "cross",     "c1": "#ffffff", "c2": "#9fd0ff", "cost": 20 },
	{ "id": "bolt",      "n": "闪电",     "cat": "hit",   "style": "bolt",      "c1": "#b197fc", "c2": "#ffffff", "cost": 30 },
	{ "id": "petal",     "n": "花瓣",     "cat": "hit",   "style": "petal",     "c1": "#ffa6c9", "c2": "#ffd166", "cost": 30 },
	{ "id": "pixel",     "n": "像素",     "cat": "hit",   "style": "pixel",     "c1": "#54e6c0", "c2": "#ff5d73", "cost": 30 },
	{ "id": "blood",     "n": "血滴",     "cat": "hit",   "style": "blood",     "c1": "#ff4d6d", "c2": "#8f0f20", "cost": 20 },
	{ "id": "ice",       "n": "冰晶",     "cat": "hit",   "style": "ice",       "c1": "#cfeaff", "c2": "#6fe3ff", "cost": 30 },
	{ "id": "flame",     "n": "火焰",     "cat": "hit",   "style": "flame",     "c1": "#ff8a3a", "c2": "#ffd166", "cost": 30 },
	{ "id": "burst",     "n": "爆裂",     "cat": "kill",  "style": "burst",     "c1": "#ffb3c1", "c2": "#ff5d73", "cost": 0 },
	{ "id": "smoke",     "n": "烟雾",     "cat": "kill",  "style": "smoke",     "c1": "#8f8fa8", "c2": "#3a3a4a", "cost": 20 },
	{ "id": "shard",     "n": "碎片",     "cat": "kill",  "style": "shard",     "c1": "#c9d8ee", "c2": "#7f8fa6", "cost": 30 },
	{ "id": "halo",      "n": "光环",     "cat": "kill",  "style": "halo",      "c1": "#ffe08a", "c2": "#ffffff", "cost": 30 },
	{ "id": "skull",     "n": "骷髅",     "cat": "kill",  "style": "skull",     "c1": "#e8e8f0", "c2": "#7f8fa6", "cost": 40 },
	{ "id": "pillar",    "n": "光柱",     "cat": "level", "style": "pillar",    "c1": "#8ff0c8", "c2": "#ffffff", "cost": 0 },
	{ "id": "rune",      "n": "符文",     "cat": "level", "style": "rune",      "c1": "#b197fc", "c2": "#ffffff", "cost": 40 },
	{ "id": "shockwave", "n": "冲击波",   "cat": "level", "style": "shockwave", "c1": "#7ee0c0", "c2": "#9fd0ff", "cost": 40 },
	{ "id": "rainbow",   "n": "彩虹拖尾", "cat": "trail", "style": "rainbow",   "c1": "#ff7aa6", "c2": "#6fe3ff", "cost": 0 },
	{ "id": "ghosttrail","n": "幽灵拖尾", "cat": "trail", "style": "ghost",     "c1": "#c9d8ee", "c2": "#7b5cff", "cost": 40 },
]

static func find(id: String) -> Dictionary:
	for e in LIST:
		if e.id == id:
			return e
	return LIST[0]

static func by_cat(cat: String) -> Array:
	var out: Array = []
	for e in LIST:
		if e.cat == cat:
			out.append(e)
	return out
