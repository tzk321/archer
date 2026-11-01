#!/usr/bin/env python3
import io,sys
P='/home/sbtzk/games/archer-godot/game.gd'
s=io.open(P,encoding='utf-8').read()
def rep(old,new,count=1):
    global s
    if s.count(old)!=count:
        print('ANCHOR_FAIL count=%d expected=%d: %r'%(s.count(old),count,old[:120]))
        sys.exit(1)
    s=s.replace(old,new,count)

rep('enum S { TITLE, WEAPONS, SKINS, EFFECTS, PLAYING, LEVELUP, SHOP, PAUSED, OVER, CLASSES, LEVELS }',
    'enum S { TITLE, WEAPONS, SKINS, EFFECTS, PLAYING, LEVELUP, SHOP, PAUSED, OVER, CLASSES, LEVELS, UPGRADES }')

rep('''const OVER_LOBBY := Rect2(650, 520, 240, 72)
''','''const OVER_LOBBY := Rect2(650, 520, 240, 72)
const PERM_RECT := Rect2(400, 454, 220, 48)
const PERM_SHOP_BTN := Rect2(500, 620, 200, 62)
const PERM_BACK := Rect2(W - 168, 24, 140, 52)

## 局外永久强化：用 meta.coins 购买，跨局生效，旧档缺省 0 级。
const PERM_LIST := [
	{ "id": "atk",    "n": "锋锐", "d": "每级 +8% 伤害",      "max": 10, "cost": 60, "step": 40, "color": "#ff8a3a" },
	{ "id": "hp",     "n": "体魄", "d": "每级 +18 生命",      "max": 10, "cost": 55, "step": 35, "color": "#6fb6ff" },
	{ "id": "speed",  "n": "疾行", "d": "每级 +4% 移速",      "max": 8,  "cost": 50, "step": 35, "color": "#7ee0c0" },
	{ "id": "crit",   "n": "锐眼", "d": "每级 +2% 暴击",      "max": 8,  "cost": 70, "step": 50, "color": "#ff7aa6" },
	{ "id": "magnet", "n": "引力", "d": "每级 +18% 拾取范围", "max": 6,  "cost": 45, "step": 30, "color": "#ffd166" },
	{ "id": "greed",  "n": "贪欲", "d": "每级 +6% 金币",      "max": 8,  "cost": 65, "step": 40, "color": "#b197fc" },
]
''')

rep('''	"uf": ["spark", "burst", "pillar", "rainbow"],
	"best": 0, "bgm": 0.65, "sfx": 0.65
}''','''	"uf": ["spark", "burst", "pillar", "rainbow"],
	"perm": {},
	"best": 0, "bgm": 0.65, "sfx": 0.65
}''')

rep('''var shop_auto_t := 0.0
var enemy_id := 0
''','''var shop_auto_t := 0.0
var enemy_id := 0
var perm_rects: Array = []
var upgrade_return: int = S.TITLE
''')

# 存档读取
rep('''	meta.cls = str(ClassesData.find(str(meta.cls)).id)
''','''	var pv = cfg.get_value("meta", "perm", {})
	if pv is Dictionary:
		meta.perm = {}
		for item in PERM_LIST:
			var raw = pv.get(str(item.id), 0)
			if (raw is int or raw is float) and is_finite(float(raw)):
				meta.perm[str(item.id)] = clampi(int(raw), 0, int(item.max))
	meta.cls = str(ClassesData.find(str(meta.cls)).id)
''')

# 属性应用
rep('''	if str(w.special) == "thorn":
		p.thorn += 8.0
''','''	if str(w.special) == "thorn":
		p.thorn += 8.0
	# 永久强化（局外金币），只在这里叠一次，不进局内临时 p 商店。
	var perm: Dictionary = meta.get("perm", {})
	var lv_atk := int(perm.get("atk", 0))
	var lv_hp := int(perm.get("hp", 0))
	var lv_speed := int(perm.get("speed", 0))
	var lv_crit := int(perm.get("crit", 0))
	var lv_magnet := int(perm.get("magnet", 0))
	var lv_greed := int(perm.get("greed", 0))
	p.dmg *= 1.0 + 0.08 * float(lv_atk)
	p.max_hp += 18.0 * float(lv_hp)
	p.hp = p.max_hp
	p.speed *= 1.0 + 0.04 * float(lv_speed)
	p.crit = minf(0.95, p.crit + 0.02 * float(lv_crit))
	p.magnet *= 1.0 + 0.18 * float(lv_magnet)
	p.greed += 0.06 * float(lv_greed)
''')

# 点击入口
rep('''			elif DIFF_RECT.has_point(pos):
				var before := meta.duplicate(true)
				meta.diff = (int(meta.diff) + 1) % 3
				if not _commit_meta(before): return
				toast_text = "难度：" + _diff_name()
				toast_t = 1.4
''','''			elif DIFF_RECT.has_point(pos):
				var before := meta.duplicate(true)
				meta.diff = (int(meta.diff) + 1) % 3
				if not _commit_meta(before): return
				toast_text = "难度：" + _diff_name()
				toast_t = 1.4
			elif PERM_RECT.has_point(pos):
				upgrade_return = S.TITLE
				state = S.UPGRADES
				_build_perm_grid()
''')

rep('''			if Rect2(W - 242, 620, 190, 62).has_point(pos):
				_resume_play()
				return
''','''			if Rect2(W - 242, 620, 190, 62).has_point(pos):
				_resume_play()
				return
			if PERM_SHOP_BTN.has_point(pos):
				upgrade_return = S.SHOP
				state = S.UPGRADES
				_build_perm_grid()
				return
''')

rep('''		S.PAUSED:
			if PAUSE_RESUME.has_point(pos):
''','''		S.UPGRADES:
			if PERM_BACK.has_point(pos):
				state = upgrade_return
				return
			for i in range(perm_rects.size()):
				if perm_rects[i].has_point(pos):
					perm_buy(i)
					return
		S.PAUSED:
			if PAUSE_RESUME.has_point(pos):
''')

# 绘制入口
rep('''	if state == S.LEVELS:
		draw_levels_screen()
		_draw_toast()
		return
''','''	if state == S.LEVELS:
		draw_levels_screen()
		_draw_toast()
		return
	if state == S.UPGRADES:
		draw_upgrades()
		_draw_toast()
		return
''')

# 大厅按钮
rep('''	_card_bg(DIFF_RECT, Color("#ffd166"))
	draw_string(font, Vector2(DIFF_RECT.position.x + 16, DIFF_RECT.position.y + 32), "难度：" + _diff_name() + "（点击切换）", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#ffe9a8"))
''','''	_card_bg(DIFF_RECT, Color("#ffd166"))
	draw_string(font, Vector2(DIFF_RECT.position.x + 16, DIFF_RECT.position.y + 32), "难度：" + _diff_name() + "（点击切换）", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#ffe9a8"))
	_card_bg(PERM_RECT, Color("#ff9ac9"))
	draw_string(font, Vector2(PERM_RECT.position.x + 18, PERM_RECT.position.y + 31), "永久强化 →", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("#ffe6ff"))
''')

# 商店按钮
rep('''	draw_string(font, Vector2(W - 212, 659), "继续战斗", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#eafff6"))
''','''	draw_string(font, Vector2(W - 212, 659), "继续战斗", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#eafff6"))
	draw_rect(PERM_SHOP_BTN, Color("#3a2a4a"))
	draw_rect(PERM_SHOP_BTN, Color("#ff9ac9"), false, 2.0)
	draw_string(font, PERM_SHOP_BTN.position + Vector2(20, 38), "永久强化", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#ffe6ff"))
''')

# 新函数附加在 _draw 前
rep('''# ============================================================ 绘制入口
func _draw() -> void:
''','''# ============================================================ 永久强化
func _build_perm_grid() -> void:
	perm_rects.clear()
	for i in range(PERM_LIST.size()):
		var col := i % 3
		var row := int(i / 3)
		perm_rects.append(Rect2(60.0 + col * 400.0, 150.0 + row * 220.0, 380.0, 196.0))

func _perm_cost(item: Dictionary, lv: int) -> int:
	return int(item.cost) + int(item.step) * lv

func perm_buy(i: int) -> void:
	if state != S.UPGRADES or i < 0 or i >= PERM_LIST.size():
		return
	var item: Dictionary = PERM_LIST[i]
	var id := str(item.id)
	var lv := int(meta.get("perm", {}).get(id, 0))
	if lv >= int(item.max):
		toast_text = str(item.n) + " 已满级"
		toast_t = 1.2
		return
	var price := _perm_cost(item, lv)
	if int(meta.coins) < price:
		toast_text = "金币不够"
		toast_t = 1.2
		play_sfx("hurt", 1.4)
		return
	var before := meta.duplicate(true)
	if not (meta.get("perm", {}) is Dictionary):
		meta.perm = {}
	meta.coins -= price
	meta.perm[id] = lv + 1
	if not _commit_meta(before):
		toast_text = "存档失败，已回滚"
		toast_t = 2.0
		play_sfx("hurt", 1.4)
		return
	toast_text = str(item.n) + " 强化到 Lv." + str(lv + 1)
	toast_t = 1.4
	play_sfx("buy")

func draw_upgrades() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.03, 0.06, 0.88))
	draw_string(font, Vector2(36, 60), "永久强化", HORIZONTAL_ALIGNMENT_LEFT, -1, 38, Color("#ffe6ff"))
	draw_string(font, Vector2(36, 90), "局外金币购买 · 所有职业跨局生效 · 存档即时写入，失败回滚", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#8fb0d8"))
	draw_string(font, Vector2(W - 320, 58), "金币 " + str(int(meta.coins)), HORIZONTAL_ALIGNMENT_RIGHT, 250, 26, Color("#ffd166"))
	_card_bg(PERM_BACK, Color("#7ee0c0"), true)
	draw_string(font, PERM_BACK.position + Vector2(34, 35), "返回", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#dbe9ff"))
	for i in range(PERM_LIST.size()):
		var item: Dictionary = PERM_LIST[i]
		var r: Rect2 = perm_rects[i]
		var id := str(item.id)
		var lv := int(meta.get("perm", {}).get(id, 0))
		var mx := int(item.max)
		var maxed := lv >= mx
		var price := _perm_cost(item, lv)
		var afford := int(meta.coins) >= price
		var cc := Color(str(item.color))
		_card_bg(r, cc, lv > 0)
		draw_circle(r.position + Vector2(50, 62), 26, Color(cc, 0.15))
		draw_circle(r.position + Vector2(50, 62), 18, cc)
		draw_string(font, Vector2(r.position.x + 92, r.position.y + 46), str(item.n), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#f0f8ff"))
		draw_string(font, Vector2(r.position.x + 92, r.position.y + 72), str(item.d), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#8fb0d8"))
		draw_string(font, Vector2(r.position.x + 24, r.position.y + 114), "等级 " + str(lv) + " / " + str(mx), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#dbe9ff"))
		draw_rect(Rect2(r.position.x + 24, r.position.y + 124, 232, 8), Color("#26344d"))
		draw_rect(Rect2(r.position.x + 24, r.position.y + 124, 232 * clampf(float(lv) / float(mx), 0.0, 1.0), 8), cc)
		var tag := "已满级" if maxed else (str(price) + " 金")
		var tcol := Color("#62f0b6") if maxed else (Color("#ffd166") if afford else Color("#ff5d73"))
		draw_string(font, Vector2(r.position.x + 24, r.position.y + 174), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, tcol)
		draw_string(font, Vector2(r.position.x + r.size.x - 118, r.position.y + 174), "点击强化" if (afford and not maxed) else ("已满" if maxed else "金币不够"), HORIZONTAL_ALIGNMENT_RIGHT, 94, 14, Color("#a7b5cf"))

# ============================================================ 绘制入口
func _draw() -> void:
''')

# 拾取金币也吃贪欲
rep('''					gold += int(q.value)
''','''					gold += int(round(float(q.value) * (1.0 + p.greed)))
''',2)

io.open(P,'w',encoding='utf-8').write(s)
print('PATCH2 OK lines=%d'%s.count('\n'))
