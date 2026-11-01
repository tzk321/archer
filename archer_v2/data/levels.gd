extends RefCounted

## 20 个独立关卡：固定障碍/地形/BOSS/敌人构成，每关 2 分钟。

## obs: none/trees/rocks/crystals/pillars；weather: none/rain/snow/sand/embers/fog

## mod: none/armored/swift/horde/spooky/void/elite；layout: [x,y,r] 0-1；zone_layout: [kind,x,y,r] kind 0冰1岩浆2毒3加速4治疗5虚空

const LIST := [
	{ "id":"starfield","n":"星野","bg":"#0b0e17","grid":"#141b2e","accent":"#54e6c0","obs":"none","zones":[],"weather":"none","mod":"none","dark":false,"obs_layout":[],"zone_layout":[],"boss_name":"星野守望者","mix":"mixed" },
	{ "id":"wasteland","n":"荒原","bg":"#171008","grid":"#2a1d0f","accent":"#d9a066","obs":"rocks","zones":[],"weather":"none","mod":"none","dark":false,"obs_layout":[[0.2, 0.28, 32], [0.8, 0.28, 32], [0.28, 0.72, 36], [0.72, 0.72, 36]],"zone_layout":[],"boss_name":"荒原巨兽","mix":"slime" },
	{ "id":"snowfield","n":"雪原","bg":"#0d1620","grid":"#1b2b3a","accent":"#9fd0ff","obs":"none","zones":[],"weather":"snow","mod":"swift","dark":false,"obs_layout":[[0.15, 0.48, 26], [0.85, 0.48, 26]],"zone_layout":[[0, 0.3, 0.4, 92], [0, 0.7, 0.62, 96], [0, 0.5, 0.22, 82]],"boss_name":"雪原巫妖","mix":"fast" },
	{ "id":"volcano","n":"熔岩","bg":"#170b0b","grid":"#2a1414","accent":"#ff6b35","obs":"rocks","zones":[],"weather":"embers","mod":"armored","dark":false,"obs_layout":[[0.22, 0.22, 34], [0.78, 0.22, 34], [0.22, 0.78, 34], [0.78, 0.78, 34], [0.5, 0.12, 28]],"zone_layout":[[1, 0.3, 0.5, 88], [1, 0.7, 0.5, 88], [1, 0.5, 0.78, 94]],"boss_name":"熔岩领主","mix":"slime" },
	{ "id":"swamp","n":"毒沼","bg":"#0d160f","grid":"#1a2a1c","accent":"#78d17a","obs":"trees","zones":[],"weather":"rain","mod":"none","dark":false,"obs_layout":[[0.18, 0.3, 36], [0.82, 0.3, 36], [0.18, 0.78, 36], [0.82, 0.78, 36], [0.5, 0.82, 30]],"zone_layout":[[2, 0.32, 0.48, 92], [2, 0.68, 0.62, 96]],"boss_name":"毒沼女巫","mix":"mage" },
	{ "id":"forest","n":"密林","bg":"#0a140d","grid":"#162a1a","accent":"#43a047","obs":"trees","zones":[],"weather":"none","mod":"horde","dark":false,"obs_layout":[[0.15, 0.2, 34], [0.38, 0.22, 34], [0.62, 0.22, 34], [0.85, 0.2, 34], [0.15, 0.78, 34], [0.38, 0.8, 34], [0.62, 0.8, 34], [0.85, 0.78, 34]],"zone_layout":[],"boss_name":"古树守卫","mix":"slime" },
	{ "id":"ruins","n":"废墟","bg":"#141210","grid":"#262220","accent":"#b0a090","obs":"rocks","zones":[],"weather":"fog","mod":"armored","dark":false,"obs_layout":[[0.12, 0.25, 30], [0.3, 0.38, 34], [0.7, 0.38, 34], [0.88, 0.25, 30], [0.12, 0.75, 30], [0.3, 0.62, 34], [0.7, 0.62, 34], [0.88, 0.75, 30]],"zone_layout":[],"boss_name":"废墟巨像","mix":"slime" },
	{ "id":"desert","n":"沙漠","bg":"#1a1408","grid":"#2c2410","accent":"#f2c94c","obs":"pillars","zones":[],"weather":"sand","mod":"swift","dark":false,"obs_layout":[[0.25, 0.3, 40], [0.75, 0.3, 40], [0.25, 0.7, 40], [0.75, 0.7, 40]],"zone_layout":[[3, 0.5, 0.5, 100]],"boss_name":"沙暴之主","mix":"fast" },
	{ "id":"icelake","n":"冰湖","bg":"#0a1520","grid":"#16283a","accent":"#cfeaff","obs":"none","zones":[],"weather":"snow","mod":"none","dark":false,"obs_layout":[[0.2, 0.5, 28], [0.8, 0.5, 28]],"zone_layout":[[0, 0.28, 0.32, 88], [0, 0.72, 0.32, 88], [0, 0.28, 0.68, 88], [0, 0.72, 0.68, 88]],"boss_name":"冰湖女王","mix":"mage" },
	{ "id":"thunder","n":"雷丘","bg":"#12101c","grid":"#221d33","accent":"#b197fc","obs":"pillars","zones":[],"weather":"rain","mod":"spooky","dark":false,"obs_layout":[[0.18, 0.24, 38], [0.82, 0.24, 38], [0.18, 0.76, 38], [0.82, 0.76, 38], [0.5, 0.5, 30]],"zone_layout":[],"boss_name":"雷鸣泰坦","mix":"fast" },
	{ "id":"dungeon","n":"地牢","bg":"#08080c","grid":"#15151d","accent":"#7f8fa6","obs":"rocks","zones":[],"weather":"fog","mod":"armored","dark":true,"obs_layout":[[0.14, 0.28, 28], [0.3, 0.28, 28], [0.7, 0.28, 28], [0.86, 0.28, 28], [0.14, 0.72, 28], [0.3, 0.72, 28], [0.7, 0.72, 28], [0.86, 0.72, 28]],"zone_layout":[[4, 0.5, 0.85, 70]],"boss_name":"地牢典狱长","mix":"slime" },
	{ "id":"sanctum","n":"圣坛","bg":"#0f1418","grid":"#1c262c","accent":"#ffe08a","obs":"pillars","zones":[],"weather":"none","mod":"none","dark":false,"obs_layout":[[0.2, 0.3, 38], [0.8, 0.3, 38], [0.2, 0.7, 38], [0.8, 0.7, 38]],"zone_layout":[[4, 0.5, 0.25, 80], [4, 0.5, 0.85, 80]],"boss_name":"圣坛守护者","mix":"mage" },
	{ "id":"caldera","n":"火山口","bg":"#1a0a06","grid":"#2c140c","accent":"#ff5d3a","obs":"rocks","zones":[],"weather":"embers","mod":"elite","dark":false,"obs_layout":[[0.16, 0.22, 30], [0.84, 0.22, 30], [0.16, 0.78, 30], [0.84, 0.78, 30], [0.5, 0.5, 34]],"zone_layout":[[1, 0.3, 0.4, 86], [1, 0.7, 0.4, 86], [1, 0.3, 0.65, 86], [1, 0.7, 0.65, 86]],"boss_name":"火山魔王","mix":"slime" },
	{ "id":"crystal","n":"水晶洞","bg":"#0b1418","grid":"#172a30","accent":"#6fe3ff","obs":"crystals","zones":[],"weather":"none","mod":"none","dark":false,"obs_layout":[[0.15, 0.25, 28], [0.38, 0.2, 28], [0.62, 0.2, 28], [0.85, 0.25, 28], [0.15, 0.75, 28], [0.38, 0.8, 28], [0.62, 0.8, 28], [0.85, 0.75, 28]],"zone_layout":[[3, 0.28, 0.5, 90], [3, 0.72, 0.5, 90]],"boss_name":"水晶龙","mix":"mage" },
	{ "id":"ghost","n":"幽灵领域","bg":"#0c0c14","grid":"#1a1a26","accent":"#c0a0ff","obs":"none","zones":[],"weather":"fog","mod":"spooky","dark":true,"obs_layout":[[0.22, 0.32, 30], [0.78, 0.32, 30], [0.22, 0.68, 30], [0.78, 0.68, 30]],"zone_layout":[],"boss_name":"幽灵王","mix":"fast" },
	{ "id":"mire","n":"腐沼","bg":"#0c120c","grid":"#182418","accent":"#8ab86a","obs":"trees","zones":[],"weather":"fog","mod":"horde","dark":false,"obs_layout":[[0.14, 0.28, 36], [0.32, 0.2, 34], [0.68, 0.2, 34], [0.86, 0.28, 36], [0.5, 0.82, 32]],"zone_layout":[[2, 0.3, 0.55, 94], [2, 0.7, 0.55, 94], [0, 0.5, 0.32, 78]],"boss_name":"腐沼吞噬者","mix":"slime" },
	{ "id":"fortress","n":"钢铁要塞","bg":"#101216","grid":"#20242c","accent":"#9aa7b8","obs":"pillars","zones":[],"weather":"none","mod":"armored","dark":false,"obs_layout":[[0.18, 0.22, 40], [0.5, 0.18, 40], [0.82, 0.22, 40], [0.18, 0.78, 40], [0.5, 0.82, 40], [0.82, 0.78, 40]],"zone_layout":[],"boss_name":"要塞机神","mix":"slime" },
	{ "id":"windway","n":"风道","bg":"#0a1218","grid":"#162430","accent":"#7ee0c0","obs":"crystals","zones":[],"weather":"sand","mod":"swift","dark":false,"obs_layout":[[0.2, 0.3, 28], [0.8, 0.3, 28], [0.2, 0.7, 28], [0.8, 0.7, 28]],"zone_layout":[[3, 0.3, 0.5, 100], [3, 0.7, 0.5, 100]],"boss_name":"风道猎手","mix":"fast" },
	{ "id":"void","n":"虚空","bg":"#0b0812","grid":"#1c1430","accent":"#b388ff","obs":"none","zones":[],"weather":"none","mod":"void","dark":true,"obs_layout":[[0.25, 0.25, 32], [0.75, 0.25, 32], [0.25, 0.75, 32], [0.75, 0.75, 32]],"zone_layout":[[5, 0.32, 0.48, 100], [5, 0.68, 0.52, 100]],"boss_name":"虚空之主","mix":"mage" },
	{ "id":"throne","n":"王座","bg":"#12080c","grid":"#260f16","accent":"#ff4d6d","obs":"pillars","zones":[],"weather":"embers","mod":"elite","dark":false,"obs_layout":[[0.2, 0.3, 40], [0.8, 0.3, 40], [0.2, 0.7, 40], [0.8, 0.7, 40]],"zone_layout":[[1, 0.5, 0.8, 90]],"boss_name":"王座终焉","mix":"mixed" },
]

static func find(id: String) -> Dictionary:
	for l in LIST:
		if l.id == id:
			return l
	return LIST[0]
