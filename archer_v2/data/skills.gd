extends RefCounted

## 24 个可购买/升级技能。apply 逻辑在 game.gd 的 apply_skill()。
## id, 名称, 描述, 最大等级, 基础价格, 分类

const LIST := [
	{ "id": "dmg",      "n": "强力箭",   "d": "攻击力 +25%",            "max": 9, "cost": 8,  "cat": "攻击" },
	{ "id": "rate",     "n": "疾风弓",   "d": "攻速 +15%",              "max": 8, "cost": 9,  "cat": "攻击" },
	{ "id": "multi",    "n": "多重箭",   "d": "每次多射 1 支箭",         "max": 4, "cost": 16, "cat": "攻击" },
	{ "id": "pierce",   "n": "穿透箭",   "d": "箭矢多穿透 1 个敌人",     "max": 3, "cost": 12, "cat": "攻击" },
	{ "id": "crit",     "n": "致命瞄准", "d": "暴击率 +10%",            "max": 5, "cost": 10, "cat": "攻击" },
	{ "id": "critdmg",  "n": "爆头",     "d": "暴击伤害 +40%",          "max": 5, "cost": 10, "cat": "攻击" },
	{ "id": "speed",    "n": "轻步",     "d": "移速 +10%",              "max": 6, "cost": 7,  "cat": "身法" },
	{ "id": "hp",       "n": "强健体魄", "d": "生命上限 +30 并回复",     "max": 9, "cost": 8,  "cat": "防御" },
	{ "id": "regen",    "n": "野性回复", "d": "每秒回复 +0.9 生命",      "max": 5, "cost": 9,  "cat": "防御" },
	{ "id": "magnet",   "n": "贪婪之手", "d": "经验拾取范围 +35%",       "max": 5, "cost": 6,  "cat": "功能" },
	{ "id": "bounce",   "n": "弹射箭",   "d": "箭矢命中后弹向敌人",      "max": 2, "cost": 18, "cat": "攻击" },
	{ "id": "armor",    "n": "铁皮",     "d": "受到伤害 -7%",           "max": 5, "cost": 10, "cat": "防御" },
	{ "id": "shield",   "n": "护盾",     "d": "获得 25 护盾，12 秒回充", "max": 5, "cost": 12, "cat": "防御" },
	{ "id": "thorn",    "n": "荆棘",     "d": "反伤 +15，碰你就掉血",    "max": 5, "cost": 9,  "cat": "防御" },
	{ "id": "greed",    "n": "财迷",     "d": "金币获取 +25%",          "max": 5, "cost": 8,  "cat": "功能" },
	{ "id": "wisdom",   "n": "悟性",     "d": "经验获取 +20%",          "max": 5, "cost": 8,  "cat": "功能" },
	{ "id": "explode",  "n": "爆炸箭",   "d": "命中产生爆炸",           "max": 3, "cost": 18, "cat": "元素" },
	{ "id": "frost",    "n": "冰箭",     "d": "命中减速 45%",           "max": 3, "cost": 16, "cat": "元素" },
	{ "id": "poison",   "n": "毒箭",     "d": "命中持续掉血",           "max": 3, "cost": 16, "cat": "元素" },
	{ "id": "chain",    "n": "闪电链",   "d": "命中后闪电连锁",         "max": 3, "cost": 20, "cat": "元素" },
	{ "id": "wolf",     "n": "战狼",     "d": "召唤一头战狼助战",        "max": 3, "cost": 22, "cat": "召唤" },
	{ "id": "lifesteal","n": "吸血",     "d": "造成伤害的 6% 回血",      "max": 4, "cost": 14, "cat": "特殊" },
	{ "id": "revive",   "n": "不屈",     "d": "死亡后原地复活一次",      "max": 2, "cost": 30, "cat": "特殊" },
	{ "id": "dash",     "n": "疾冲",     "d": "冲刺冷却 -0.7 秒",       "max": 3, "cost": 10, "cat": "身法" },
	{ "id": "awaken_dmg",  "n": "力量觉醒", "d": "攻击力 +15%（可叠 20 层）",   "max": 20, "cost": 30, "cat": "觉醒" },
	{ "id": "awaken_hp",   "n": "生命觉醒", "d": "生命上限 +40（可叠 20 层）",  "max": 20, "cost": 28, "cat": "觉醒" },
	{ "id": "awaken_rate", "n": "疾速觉醒", "d": "攻速 +8%（可叠 12 层）",      "max": 12, "cost": 32, "cat": "觉醒" },
	{ "id": "awaken_crit", "n": "暴击觉醒", "d": "暴击率 +5%（可叠 10 层）",    "max": 10, "cost": 30, "cat": "觉醒" },
	{ "id": "rn_dmg", "n": "精准射击", "d": "远程伤害 +22%", "max": 8, "cost": 8, "cat": "攻击", "base": "dmg", "icon": "dmg", "cls": "ranger" },
	{ "id": "rn_rate", "n": "连射", "d": "攻速 +15%", "max": 8, "cost": 9, "cat": "攻击", "base": "rate", "icon": "rate", "cls": "ranger" },
	{ "id": "rn_multi", "n": "箭雨", "d": "每次多射 1 支箭", "max": 4, "cost": 16, "cat": "攻击", "base": "multi", "icon": "multi", "cls": "ranger" },
	{ "id": "rn_pierce", "n": "破甲箭", "d": "穿透 +1", "max": 3, "cost": 12, "cat": "攻击", "base": "pierce", "icon": "pierce", "cls": "ranger" },
	{ "id": "rn_crit", "n": "鹰眼", "d": "暴击率 +10%", "max": 5, "cost": 10, "cat": "攻击", "base": "crit", "icon": "crit", "cls": "ranger" },
	{ "id": "rn_speed", "n": "疾风步", "d": "移速 +10%", "max": 6, "cost": 7, "cat": "身法", "base": "speed", "icon": "speed", "cls": "ranger" },
	{ "id": "rn_magnet", "n": "猎手直觉", "d": "拾取范围 +35%", "max": 5, "cost": 6, "cat": "功能", "base": "magnet", "icon": "magnet", "cls": "ranger" },
	{ "id": "rn_regen", "n": "自然回复", "d": "每秒回复 +0.9", "max": 5, "cost": 9, "cat": "防御", "base": "regen", "icon": "regen", "cls": "ranger" },
	{ "id": "bl_dmg", "n": "剑术精通", "d": "近战伤害 +25%", "max": 9, "cost": 8, "cat": "攻击", "base": "dmg", "icon": "dmg", "cls": "blade" },
	{ "id": "bl_rate", "n": "疾风斩", "d": "攻速 +15%", "max": 8, "cost": 9, "cat": "攻击", "base": "rate", "icon": "rate", "cls": "blade" },
	{ "id": "bl_armor", "n": "铁壁", "d": "受伤 -7%", "max": 5, "cost": 10, "cat": "防御", "base": "armor", "icon": "armor", "cls": "blade" },
	{ "id": "bl_thorn", "n": "剑棘", "d": "反伤 +15", "max": 5, "cost": 9, "cat": "防御", "base": "thorn", "icon": "thorn", "cls": "blade" },
	{ "id": "bl_lifesteal", "n": "血刃", "d": "伤害吸血 6%", "max": 4, "cost": 14, "cat": "特殊", "base": "lifesteal", "icon": "lifesteal", "cls": "blade" },
	{ "id": "bl_revive", "n": "不屈剑心", "d": "死亡复活一次", "max": 2, "cost": 30, "cat": "特殊", "base": "revive", "icon": "revive", "cls": "blade" },
	{ "id": "bl_dash", "n": "踏前斩", "d": "冲刺冷却 -0.7s", "max": 3, "cost": 10, "cat": "身法", "base": "dash", "icon": "dash", "cls": "blade" },
	{ "id": "bl_crit", "n": "破绽", "d": "暴击率 +10%", "max": 5, "cost": 10, "cat": "攻击", "base": "crit", "icon": "crit", "cls": "blade" },
	{ "id": "mg_dmg", "n": "奥术强化", "d": "法术伤害 +25%", "max": 9, "cost": 9, "cat": "攻击", "base": "dmg", "icon": "dmg", "cls": "mage" },
	{ "id": "mg_rate", "n": "咏唱加速", "d": "攻速 +15%", "max": 8, "cost": 10, "cat": "攻击", "base": "rate", "icon": "rate", "cls": "mage" },
	{ "id": "mg_multi", "n": "三连法球", "d": "每次多射 1 发", "max": 4, "cost": 18, "cat": "攻击", "base": "multi", "icon": "multi", "cls": "mage" },
	{ "id": "mg_pierce", "n": "穿透奥术", "d": "穿透 +1", "max": 3, "cost": 14, "cat": "攻击", "base": "pierce", "icon": "pierce", "cls": "mage" },
	{ "id": "mg_explode", "n": "爆裂火球", "d": "命中爆炸", "max": 3, "cost": 18, "cat": "元素", "base": "explode", "icon": "explode", "cls": "mage" },
	{ "id": "mg_frost", "n": "冰霜附着", "d": "命中减速 45%", "max": 3, "cost": 16, "cat": "元素", "base": "frost", "icon": "frost", "cls": "mage" },
	{ "id": "mg_chain", "n": "雷霆链", "d": "命中闪电连锁", "max": 3, "cost": 20, "cat": "元素", "base": "chain", "icon": "chain", "cls": "mage" },
	{ "id": "mg_shield", "n": "法力护盾", "d": "25 护盾，12 秒回充", "max": 5, "cost": 12, "cat": "防御", "base": "shield", "icon": "shield", "cls": "mage" },
	{ "id": "mg_crit", "n": "元素专注", "d": "暴击率 +10%", "max": 5, "cost": 11, "cat": "攻击", "base": "crit", "icon": "crit", "cls": "mage" },
	{ "id": "as_crit", "n": "致命一击", "d": "暴击率 +12%", "max": 6, "cost": 10, "cat": "攻击", "base": "crit", "icon": "crit", "cls": "assassin" },
	{ "id": "as_critdmg", "n": "背刺", "d": "暴击伤害 +50%", "max": 5, "cost": 11, "cat": "攻击", "base": "critdmg", "icon": "critdmg", "cls": "assassin" },
	{ "id": "as_speed", "n": "影步", "d": "移速 +12%", "max": 6, "cost": 8, "cat": "身法", "base": "speed", "icon": "speed", "cls": "assassin" },
	{ "id": "as_dash", "n": "瞬影", "d": "冲刺冷却 -0.8s", "max": 3, "cost": 12, "cat": "身法", "base": "dash", "icon": "dash", "cls": "assassin" },
	{ "id": "as_lifesteal", "n": "嗜血", "d": "伤害吸血 6%", "max": 4, "cost": 14, "cat": "特殊", "base": "lifesteal", "icon": "lifesteal", "cls": "assassin" },
	{ "id": "as_multi", "n": "飞刃", "d": "每次多射 1 支", "max": 3, "cost": 18, "cat": "攻击", "base": "multi", "icon": "multi", "cls": "assassin" },
	{ "id": "as_bounce", "n": "弹刃", "d": "命中弹射", "max": 2, "cost": 18, "cat": "攻击", "base": "bounce", "icon": "bounce", "cls": "assassin" },
	{ "id": "as_pierce", "n": "穿影", "d": "穿透 +1", "max": 3, "cost": 13, "cat": "攻击", "base": "pierce", "icon": "pierce", "cls": "assassin" },
	{ "id": "bs_dmg", "n": "狂怒", "d": "伤害 +30%", "max": 9, "cost": 9, "cat": "攻击", "base": "dmg", "icon": "dmg", "cls": "berserker" },
	{ "id": "bs_rate", "n": "暴走", "d": "攻速 +18%", "max": 8, "cost": 10, "cat": "攻击", "base": "rate", "icon": "rate", "cls": "berserker" },
	{ "id": "bs_hp", "n": "战吼", "d": "生命 +35", "max": 9, "cost": 9, "cat": "防御", "base": "hp", "icon": "hp", "cls": "berserker" },
	{ "id": "bs_armor", "n": "铁皮", "d": "受伤 -7%", "max": 5, "cost": 10, "cat": "防御", "base": "armor", "icon": "armor", "cls": "berserker" },
	{ "id": "bs_lifesteal", "n": "嗜血", "d": "伤害吸血 7%", "max": 5, "cost": 14, "cat": "特殊", "base": "lifesteal", "icon": "lifesteal", "cls": "berserker" },
	{ "id": "bs_thorn", "n": "反伤甲", "d": "反伤 +18", "max": 5, "cost": 10, "cat": "防御", "base": "thorn", "icon": "thorn", "cls": "berserker" },
	{ "id": "bs_explode", "n": "崩山击", "d": "命中爆炸", "max": 3, "cost": 20, "cat": "元素", "base": "explode", "icon": "explode", "cls": "berserker" },
	{ "id": "bs_shield", "n": "血盾", "d": "护盾 25", "max": 5, "cost": 12, "cat": "防御", "base": "shield", "icon": "shield", "cls": "berserker" },
	{ "id": "su_wolf", "n": "狼群", "d": "召唤一头战狼", "max": 3, "cost": 22, "cat": "召唤", "base": "wolf", "icon": "wolf", "cls": "summoner" },
	{ "id": "su_dmg", "n": "兽魂", "d": "伤害 +20%", "max": 8, "cost": 9, "cat": "攻击", "base": "dmg", "icon": "dmg", "cls": "summoner" },
	{ "id": "su_rate", "n": "灵速", "d": "攻速 +12%", "max": 8, "cost": 8, "cat": "攻击", "base": "rate", "icon": "rate", "cls": "summoner" },
	{ "id": "su_hp", "n": "共生", "d": "生命 +30", "max": 9, "cost": 8, "cat": "防御", "base": "hp", "icon": "hp", "cls": "summoner" },
	{ "id": "su_regen", "n": "自然恢复", "d": "每秒回复 +1.0", "max": 5, "cost": 9, "cat": "防御", "base": "regen", "icon": "regen", "cls": "summoner" },
	{ "id": "su_chain", "n": "闪电链", "d": "命中闪电连锁", "max": 3, "cost": 20, "cat": "元素", "base": "chain", "icon": "chain", "cls": "summoner" },
	{ "id": "su_poison", "n": "毒雾", "d": "命中中毒", "max": 3, "cost": 16, "cat": "元素", "base": "poison", "icon": "poison", "cls": "summoner" },
	{ "id": "su_shield", "n": "灵体护盾", "d": "护盾 25", "max": 5, "cost": 12, "cat": "防御", "base": "shield", "icon": "shield", "cls": "summoner" },
	{ "id": "su_greed", "n": "收获", "d": "金币 +25%", "max": 5, "cost": 8, "cat": "功能", "base": "greed", "icon": "greed", "cls": "summoner" },
]

static func find(id: String) -> Dictionary:
	for s in LIST:
		if s.id == id:
			return s
	return {}

const CLASS_SKILLS := {
	"ranger": ["rn_dmg", "rn_rate", "rn_multi", "rn_pierce", "rn_crit", "rn_speed", "rn_magnet", "rn_regen"],
	"blade": ["bl_dmg", "bl_rate", "bl_armor", "bl_thorn", "bl_lifesteal", "bl_revive", "bl_dash", "bl_crit"],
	"mage": ["mg_dmg", "mg_rate", "mg_multi", "mg_pierce", "mg_explode", "mg_frost", "mg_chain", "mg_shield", "mg_crit"],
	"assassin": ["as_crit", "as_critdmg", "as_speed", "as_dash", "as_lifesteal", "as_multi", "as_bounce", "as_pierce"],
	"berserker": ["bs_dmg", "bs_rate", "bs_hp", "bs_armor", "bs_lifesteal", "bs_thorn", "bs_explode", "bs_shield"],
	"summoner": ["su_wolf", "su_dmg", "su_rate", "su_hp", "su_regen", "su_chain", "su_poison", "su_shield", "su_greed"],
}

static func for_class(cls: String) -> Array:
	var out: Array = []
	for id in CLASS_SKILLS.get(cls, []):
		var s = find(str(id))
		if not s.is_empty():
			out.append(s)
	return out

static func allowed(cls: String, id: String) -> bool:
	var s = find(id)
	if s.is_empty():
		return false
	if str(s.get("cat", "")) == "觉醒":
		return true
	return id in CLASS_SKILLS.get(cls, [])
