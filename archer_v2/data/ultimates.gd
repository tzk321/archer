extends RefCounted

## 10 个商店传说技能：买了自动施放，特效拉满。
## cd 秒；被动类 cd=0。

const LIST := [
	{ "id": "meteor",     "n": "陨石术",   "d": "每 6 秒砸下陨石，范围爆炸+燃烧",     "cost": 70,  "cd": 6.0,  "color": "#ff6b35", "icon": "meteor" },
	{ "id": "storm",      "n": "雷霆风暴", "d": "每 5 秒连锁闪电 8 个敌人",          "cost": 70,  "cd": 5.0,  "color": "#b197fc", "icon": "storm" },
	{ "id": "blackhole",  "n": "黑洞",     "d": "每 9 秒生成黑洞，吸附并绞杀",        "cost": 80,  "cd": 9.0,  "color": "#b388ff", "icon": "void" },
	{ "id": "timefreeze", "n": "时间暂停", "d": "每 14 秒冻结全场 2.5 秒",            "cost": 90,  "cd": 14.0, "color": "#8fd8ff", "icon": "ice" },
	{ "id": "dragon",     "n": "巨龙",     "d": "召唤巨龙，每 4 秒喷火",              "cost": 100, "cd": 4.0,  "color": "#ff5d3a", "icon": "flame" },
	{ "id": "clones",     "n": "分身",     "d": "召唤 2 个分身，持续 8 秒",           "cost": 80,  "cd": 14.0, "color": "#7ee0c0", "icon": "ghost" },
	{ "id": "frostnova",  "n": "冰霜新星", "d": "每 5 秒全屏冰爆，减速+伤害",          "cost": 70,  "cd": 5.0,  "color": "#cfeaff", "icon": "ice" },
	{ "id": "firestorm",  "n": "火焰风暴", "d": "每 8 秒降下 3 秒火雨",                "cost": 80,  "cd": 8.0,  "color": "#ff8a3a", "icon": "flame" },
	{ "id": "guardian",   "n": "守护天使", "d": "被动：+1 复活，+30 护盾",             "cost": 90,  "cd": 0.0,  "color": "#ffe08a", "icon": "holy" },
	{ "id": "bloodmoon",  "n": "血月",     "d": "被动：金币翻倍，伤害吸血",            "cost": 60,  "cd": 0.0,  "color": "#ff4d6d", "icon": "blood" },
]

static func find(id: String) -> Dictionary:
	for e in LIST:
		if e.id == id:
			return e
	return {}
