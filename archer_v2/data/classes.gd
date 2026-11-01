extends RefCounted

## 6 个职业：不同基础属性 + 初始武器 + 初始技能。
## weapon 会写进 meta.weapon 并解锁；start_skill 开局直接送 1 级。

const LIST := [
	{ "id": "ranger",    "n": "游侠",   "d": "均衡远程，移速快",          "weapon": "shortbow",  "hp": 150.0, "speed": 255.0, "dmg": 1.00, "crit": 0.05, "armor": 0.25, "start_skill": "rn_multi",     "color": "#2fb37a" },
	{ "id": "blade",     "n": "剑士",   "d": "近战高血，反伤",            "weapon": "ironsword", "hp": 190.0, "speed": 245.0, "dmg": 1.10, "crit": 0.05, "armor": 0.30, "start_skill": "bl_armor",     "color": "#9fd0ff" },
	{ "id": "mage",      "n": "法师",   "d": "远程爆炸，技能强",          "weapon": "firestaff", "hp": 130.0, "speed": 245.0, "dmg": 1.15, "crit": 0.05, "armor": 0.15, "start_skill": "mg_explode",   "color": "#b197fc" },
	{ "id": "assassin",  "n": "刺客",   "d": "双匕快攻，高暴击",          "weapon": "daggers",   "hp": 140.0, "speed": 275.0, "dmg": 0.95, "crit": 0.20, "armor": 0.18, "start_skill": "as_dash",      "color": "#ff7aa6" },
	{ "id": "berserker", "n": "狂战士", "d": "巨斧横扫，吸血",            "weapon": "greataxe",  "hp": 210.0, "speed": 235.0, "dmg": 1.20, "crit": 0.05, "armor": 0.25, "start_skill": "bs_lifesteal", "color": "#ff8a3a" },
	{ "id": "summoner",  "n": "召唤师", "d": "灵弓追踪，开局带狼",        "weapon": "spiritbow", "hp": 150.0, "speed": 245.0, "dmg": 0.90, "crit": 0.05, "armor": 0.25, "start_skill": "su_wolf",      "color": "#8ab86a" },
]

static func find(id: String) -> Dictionary:
	for c in LIST:
		if c.id == id:
			return c
	return LIST[0]
