extends RefCounted

## 20 把武器：决定基础伤害/攻速/箭数/弹道，技能在其上叠乘。
## special: none / explode / frost / poison / chain / burn / homing / boomerang / execute / thorn / moon

const LIST := [
	{ "id": "shortbow", "n": "短弓",     "d": "最顺手的基础弓",            "dmg": 1.00, "rate": 0.40, "arrows": 1, "spread": 0.10, "speed": 820,  "pierce": 0, "bounce": 0, "life": 1.15, "color": "#d9a066", "special": "none",      "cost": 0 },
	{ "id": "longbow",  "n": "长弓",     "d": "高伤慢射，穿透 1",          "dmg": 1.55, "rate": 0.62, "arrows": 1, "spread": 0.08, "speed": 1050, "pierce": 1, "bounce": 0, "life": 1.20, "color": "#e6c288", "special": "none",      "cost": 40 },
	{ "id": "repeater", "n": "连弩",     "d": "低伤高频，泼水一样",        "dmg": 0.55, "rate": 0.19, "arrows": 1, "spread": 0.09, "speed": 900,  "pierce": 0, "bounce": 0, "life": 1.00, "color": "#9fd0ff", "special": "none",      "cost": 60 },
	{ "id": "triple",   "n": "三叉弓",   "d": "一次三箭扇形",             "dmg": 0.80, "rate": 0.48, "arrows": 3, "spread": 0.26, "speed": 850,  "pierce": 0, "bounce": 0, "life": 1.05, "color": "#7ee0c0", "special": "none",      "cost": 80 },
	{ "id": "piercer",  "n": "穿云弓",   "d": "高速穿透 4 个",            "dmg": 1.10, "rate": 0.55, "arrows": 1, "spread": 0.05, "speed": 1500, "pierce": 4, "bounce": 0, "life": 1.10, "color": "#ffe08a", "special": "none",      "cost": 90 },
	{ "id": "ricochet", "n": "弹射弓",   "d": "命中后弹 3 次",            "dmg": 0.90, "rate": 0.45, "arrows": 1, "spread": 0.08, "speed": 880,  "pierce": 0, "bounce": 3, "life": 1.30, "color": "#ffb3c1", "special": "none",      "cost": 90 },
	{ "id": "bomber",   "n": "爆炸弓",   "d": "命中炸开一片",             "dmg": 1.15, "rate": 0.62, "arrows": 1, "spread": 0.10, "speed": 760,  "pierce": 0, "bounce": 0, "life": 1.15, "color": "#ff8a5c", "special": "explode",   "cost": 120 },
	{ "id": "frostbow", "n": "冰弓",     "d": "命中减速 45%",             "dmg": 0.95, "rate": 0.45, "arrows": 1, "spread": 0.10, "speed": 860,  "pierce": 0, "bounce": 0, "life": 1.15, "color": "#8fd8ff", "special": "frost",     "cost": 110 },
	{ "id": "flamebow", "n": "火弓",     "d": "命中点燃持续掉血",          "dmg": 0.90, "rate": 0.38, "arrows": 1, "spread": 0.10, "speed": 900,  "pierce": 0, "bounce": 0, "life": 1.10, "color": "#ff6b35", "special": "burn",      "cost": 110 },
	{ "id": "venom",    "n": "毒弓",     "d": "命中叠毒",                "dmg": 0.80, "rate": 0.42, "arrows": 1, "spread": 0.10, "speed": 840,  "pierce": 0, "bounce": 0, "life": 1.15, "color": "#78d17a", "special": "poison",    "cost": 100 },
	{ "id": "storm",    "n": "闪电弓",   "d": "命中后闪电连锁 2 次",      "dmg": 0.85, "rate": 0.42, "arrows": 1, "spread": 0.10, "speed": 980,  "pierce": 0, "bounce": 0, "life": 1.05, "color": "#b197fc", "special": "chain",     "cost": 130 },
	{ "id": "seeker",   "n": "追踪弓",   "d": "箭矢会拐弯追人",           "dmg": 0.80, "rate": 0.48, "arrows": 1, "spread": 0.12, "speed": 700,  "pierce": 0, "bounce": 0, "life": 1.60, "color": "#6fe3ff", "special": "homing",    "cost": 140 },
	{ "id": "boomer",   "n": "回旋镖",   "d": "飞出去还会飞回来",          "dmg": 0.90, "rate": 0.55, "arrows": 1, "spread": 0.06, "speed": 900,  "pierce": 0, "bounce": 0, "life": 1.40, "color": "#f2c94c", "special": "boomerang", "cost": 120 },
	{ "id": "shotgun",  "n": "霰弹弓",   "d": "五箭贴脸爆发",             "dmg": 0.38, "rate": 0.60, "arrows": 5, "spread": 0.18, "speed": 980,  "pierce": 0, "bounce": 0, "life": 0.38, "color": "#ffd166", "special": "none",      "cost": 110 },
	{ "id": "sniper",   "n": "狙击弓",   "d": "超远单发重箭",             "dmg": 2.60, "rate": 0.95, "arrows": 1, "spread": 0.02, "speed": 1900, "pierce": 2, "bounce": 0, "life": 1.40, "color": "#c9d8ee", "special": "none",      "cost": 150 },
	{ "id": "dual",     "n": "双持弓",   "d": "一次两箭平行",             "dmg": 0.70, "rate": 0.30, "arrows": 2, "spread": 0.10, "speed": 900,  "pierce": 0, "bounce": 0, "life": 1.05, "color": "#f0a6ff", "special": "none",      "cost": 100 },
	{ "id": "moonbow",  "n": "月光弓",   "d": "暴击 +15%，银色箭",        "dmg": 1.00, "rate": 0.42, "arrows": 1, "spread": 0.08, "speed": 900,  "pierce": 0, "bounce": 0, "life": 1.20, "color": "#dbeaff", "special": "moon",      "cost": 160 },
	{ "id": "sunbow",   "n": "太阳弓",   "d": "小爆炸 + 点燃",            "dmg": 1.25, "rate": 0.55, "arrows": 1, "spread": 0.10, "speed": 860,  "pierce": 0, "bounce": 0, "life": 1.15, "color": "#ffca3a", "special": "explode",   "cost": 160 },
	{ "id": "voidbow",  "n": "虚空弓",   "d": "穿透 3，残血直接抹除",      "dmg": 1.00, "rate": 0.46, "arrows": 1, "spread": 0.08, "speed": 950,  "pierce": 3, "bounce": 0, "life": 1.20, "color": "#b388ff", "special": "execute",   "cost": 180 },
	{ "id": "thornbow", "n": "荆棘弓",   "d": "小爆炸，反弹近身伤害",      "dmg": 0.85, "rate": 0.40, "arrows": 1, "spread": 0.10, "speed": 880,  "pierce": 0, "bounce": 0, "life": 1.10, "color": "#8ab86a", "special": "thorn",     "cost": 140 },
	{ "id": "ironsword",  "n": "铁剑",     "d": "近战挥砍，稳定输出",        "kind": "melee", "dmg": 1.25, "rate": 0.45, "range": 105.0, "arc": 1.60, "knock": 40.0,  "color": "#c9d8ee", "special": "none",    "cost": 80 },
	{ "id": "greataxe",   "n": "巨斧",     "d": "宽弧横扫，击退",            "kind": "melee", "dmg": 1.65, "rate": 0.75, "range": 118.0, "arc": 2.40, "knock": 130.0, "color": "#ffb3c1", "special": "cleave",  "cost": 120 },
	{ "id": "spear",      "n": "长枪",     "d": "直线突刺，超长距离",        "kind": "melee", "dmg": 1.35, "rate": 0.55, "range": 165.0, "arc": 0.55, "knock": 30.0,  "color": "#ffe08a", "special": "spear",   "cost": 100 },
	{ "id": "daggers",    "n": "双匕",     "d": "极快短刺，暴击+10%",        "kind": "melee", "dmg": 0.55, "rate": 0.22, "range": 78.0,  "arc": 0.95, "knock": 10.0,  "color": "#f0a6ff", "special": "fast",    "cost": 100 },
	{ "id": "hammer",     "n": "战锤",     "d": "砸地，范围爆炸",            "kind": "melee", "dmg": 1.50, "rate": 0.82, "range": 112.0, "arc": 1.80, "knock": 150.0, "color": "#d9a066", "special": "slam",    "cost": 130 },
	{ "id": "scythe",     "n": "镰刀",     "d": "360 度回旋斩",              "kind": "melee", "dmg": 1.20, "rate": 0.62, "range": 125.0, "arc": 3.20, "knock": 40.0,  "color": "#8ab86a", "special": "spin",    "cost": 140 },
	{ "id": "fists",      "n": "拳套",     "d": "三连快拳",                  "kind": "melee", "dmg": 0.70, "rate": 0.24, "range": 72.0,  "arc": 1.10, "knock": 20.0,  "color": "#ffd166", "special": "combo",   "cost": 90 },
	{ "id": "lightsaber", "n": "光剑",     "d": "光弧斩，命中点燃",          "kind": "melee", "dmg": 1.30, "rate": 0.50, "range": 112.0, "arc": 2.00, "knock": 50.0,  "color": "#6fe3ff", "special": "burn",    "cost": 160 },
	{ "id": "venomfang",  "n": "毒牙",     "d": "淬毒短刃",                  "kind": "melee", "dmg": 0.85, "rate": 0.35, "range": 85.0,  "arc": 1.05, "knock": 15.0,  "color": "#78d17a", "special": "poison",  "cost": 120 },
	{ "id": "stormhammer","n": "雷锤",     "d": "锤击带闪电链",              "kind": "melee", "dmg": 1.45, "rate": 0.80, "range": 118.0, "arc": 2.00, "knock": 130.0, "color": "#b197fc", "special": "chain",   "cost": 170 },
	{ "id": "firestaff",  "n": "火焰法杖", "d": "发射爆裂火球",              "kind": "ranged", "dmg": 0.95, "rate": 0.50, "arrows": 1, "spread": 0.08, "speed": 780, "pierce": 0, "bounce": 0, "life": 1.10, "color": "#ff8a3a", "special": "burn",   "cost": 150 },
	{ "id": "spiritbow",  "n": "灵弓",     "d": "追踪灵箭",                  "kind": "ranged", "dmg": 0.90, "rate": 0.40, "arrows": 1, "spread": 0.10, "speed": 850, "pierce": 0, "bounce": 0, "life": 1.30, "color": "#8ab86a", "special": "homing", "cost": 150 },
	{ "id": "longsword",  "n": "长剑",     "d": "剑士专属，均衡挥砍",        "kind": "melee", "dmg": 1.35, "rate": 0.50, "range": 115.0, "arc": 1.80, "knock": 50.0,  "color": "#dbe9ff", "special": "none",   "cost": 100 },
	{ "id": "greatsword", "n": "巨剑",     "d": "剑士专属，重剑横扫",        "kind": "melee", "dmg": 1.85, "rate": 0.85, "range": 132.0, "arc": 2.20, "knock": 90.0,  "color": "#9fd0ff", "special": "cleave", "cost": 160 },
	{ "id": "shadowblade","n": "影刃",     "d": "刺客专属，暴击短刃",        "kind": "melee", "dmg": 0.75, "rate": 0.28, "range": 84.0,  "arc": 1.00, "knock": 15.0,  "color": "#c0a0ff", "special": "fast",   "cost": 120 },
	{ "id": "throwknives","n": "飞刀",     "d": "刺客专属，高速投掷",        "kind": "ranged", "dmg": 0.55, "rate": 0.24, "arrows": 1, "spread": 0.06, "speed": 1100, "pierce": 0, "bounce": 1, "life": 0.70, "color": "#c0a0ff", "special": "none", "cost": 110 },
	{ "id": "dualaxes",   "n": "双斧",     "d": "狂战专属，快速双持",        "kind": "melee", "dmg": 0.95, "rate": 0.35, "range": 98.0,  "arc": 2.00, "knock": 60.0,  "color": "#ff8a3a", "special": "none",   "cost": 120 },
	{ "id": "greatmaul",  "n": "巨锤",     "d": "狂战专属，砸地巨震",        "kind": "melee", "dmg": 2.00, "rate": 1.00, "range": 126.0, "arc": 2.20, "knock": 200.0, "color": "#d9a066", "special": "slam",   "cost": 170 },
	{ "id": "froststaff", "n": "冰法杖",   "d": "法师专属，冰霜法球",        "kind": "ranged", "dmg": 1.00, "rate": 0.52, "arrows": 1, "spread": 0.08, "speed": 820, "pierce": 0, "bounce": 0, "life": 1.15, "color": "#8fd8ff", "special": "frost",  "cost": 150 },
	{ "id": "stormstaff", "n": "雷法杖",   "d": "法师专属，闪电链",          "kind": "ranged", "dmg": 0.90, "rate": 0.46, "arrows": 1, "spread": 0.08, "speed": 900, "pierce": 0, "bounce": 0, "life": 1.05, "color": "#b197fc", "special": "chain",  "cost": 160 },
	{ "id": "voidstaff",  "n": "暗法杖",   "d": "法师专属，残血抹除",        "kind": "ranged", "dmg": 1.05, "rate": 0.55, "arrows": 1, "spread": 0.08, "speed": 880, "pierce": 1, "bounce": 0, "life": 1.20, "color": "#b388ff", "special": "execute","cost": 180 },
	{ "id": "tome",       "n": "秘法书",   "d": "法师专属，三发奥术弹",      "kind": "ranged", "dmg": 0.70, "rate": 0.38, "arrows": 3, "spread": 0.20, "speed": 800, "pierce": 0, "bounce": 0, "life": 1.05, "color": "#ffe08a", "special": "none",   "cost": 170 },
	{ "id": "bonestaff",  "n": "骨杖",     "d": "召唤专属，剧毒骨弹",        "kind": "ranged", "dmg": 0.80, "rate": 0.50, "arrows": 1, "spread": 0.09, "speed": 760, "pierce": 0, "bounce": 0, "life": 1.15, "color": "#d8e0c0", "special": "poison", "cost": 120 },
	{ "id": "beaststaff", "n": "兽杖",     "d": "召唤专属，追踪兽魂",        "kind": "ranged", "dmg": 0.90, "rate": 0.45, "arrows": 1, "spread": 0.10, "speed": 820, "pierce": 0, "bounce": 0, "life": 1.30, "color": "#8ab86a", "special": "homing", "cost": 140 },
	{ "id": "soulbell",  "n": "魂铃",     "d": "召唤专属，双魂弹",          "kind": "ranged", "dmg": 0.60, "rate": 0.35, "arrows": 2, "spread": 0.14, "speed": 800, "pierce": 0, "bounce": 0, "life": 1.10, "color": "#cfeaff", "special": "none",   "cost": 130 },
]

static func find(id: String) -> Dictionary:
	for w in LIST:
		if w.id == id:
			return w
	return LIST[0]

const CLASS_WEAPONS := {
	"ranger": ["shortbow", "longbow", "repeater", "triple", "piercer", "ricochet", "boomer", "shotgun", "sniper", "dual", "moonbow", "sunbow", "voidbow", "thornbow"],
	"blade": ["ironsword", "longsword", "greatsword", "lightsaber", "spear"],
	"mage": ["firestaff", "froststaff", "stormstaff", "voidstaff", "tome"],
	"assassin": ["daggers", "shadowblade", "venomfang", "fists", "throwknives"],
	"berserker": ["greataxe", "dualaxes", "greatmaul", "hammer", "stormhammer", "scythe"],
	"summoner": ["spiritbow", "bonestaff", "beaststaff", "soulbell"],
}

static func for_class(cls: String) -> Array:
	var out: Array = []
	for id in CLASS_WEAPONS.get(cls, []):
		out.append(find(str(id)))
	return out

static func allowed(cls: String, id: String) -> bool:
	return id in CLASS_WEAPONS.get(cls, [])
