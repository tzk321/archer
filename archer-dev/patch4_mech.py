#!/usr/bin/env python3
import io,sys
P='/home/sbtzk/games/archer-godot/game.gd'
s=io.open(P,encoding='utf-8').read()
def rep(old,new,count=1):
    global s
    if s.count(old)!=count:
        print('ANCHOR_FAIL count=%d expected=%d: %r'%(s.count(old),count,old[:140]))
        sys.exit(1)
    s=s.replace(old,new,count)

rep('enum S { TITLE, WEAPONS, SKINS, EFFECTS, PLAYING, LEVELUP, SHOP, PAUSED, OVER, CLASSES, LEVELS, UPGRADES }',
    'enum S { TITLE, WEAPONS, SKINS, EFFECTS, PLAYING, LEVELUP, SHOP, PAUSED, OVER, CLASSES, LEVELS, UPGRADES, ALTAR }')

rep('''const PERM_BACK := Rect2(W - 168, 24, 140, 52)
''','''const PERM_BACK := Rect2(W - 168, 24, 140, 52)
## 祭坛二选一：有增益也有代价，影响局内决策。
const ALTAR_R1 := Rect2(200, 210, 400, 330)
const ALTAR_R2 := Rect2(680, 210, 400, 330)
const ALTAR_SKIP := Rect2(500, 580, 280, 64)
const ALTAR_POOL := [
	{ "id": "fury",   "n": "狂怒", "d": "伤害 +30%", "c": "最大生命 -15%", "cc": "#ff8a3a" },
	{ "id": "wind",   "n": "疾风", "d": "移速 +15%", "c": "攻击间隔 +18%", "cc": "#7ee0c0" },
	{ "id": "blood",  "n": "血契", "d": "每秒回复 +1.5", "c": "金币获取 -20%", "cc": "#ff5d73" },
	{ "id": "volley", "n": "弹幕", "d": "箭矢 +1", "c": "伤害 -12%", "cc": "#9fd0ff" },
	{ "id": "greed",  "n": "贪婪", "d": "金币 +50%", "c": "敌人移速 +10%", "cc": "#ffd166" },
	{ "id": "bulwark","n": "坚壁", "d": "护甲 +12%", "c": "移速 -8%", "cc": "#6fb6ff" },
	{ "id": "arcane", "n": "秘能", "d": "元素强度 +25%", "c": "最大生命 -10%", "cc": "#b197fc" },
	{ "id": "hunter", "n": "猎手", "d": "暴击 +10%", "c": "最大生命 -10%", "cc": "#ff7aa6" },
	{ "id": "titan",  "n": "泰坦", "d": "最大生命 +60", "c": "移速 -10%", "cc": "#8ab86a" },
	{ "id": "echo",   "n": "回响", "d": "闪电链 +1", "c": "伤害 -10%", "cc": "#c0a0ff" },
]
''')

rep('''var perm_rects: Array = []
var upgrade_return: int = S.TITLE
''','''var perm_rects: Array = []
var upgrade_return: int = S.TITLE
var altars: Array = []
var altar_choices: Array = []
var altar_rects: Array = []
var bounty: Dictionary = {}
var enemy_boost := 0.0
''')

rep('''	next_event = 34.0; storm_cd = 2.0
	_release_controls("start_run"); dash_dir = Vector2.RIGHT; trail_acc = 0.0
''','''	next_event = 34.0; storm_cd = 2.0
	altars.clear(); altar_choices.clear(); altar_rects.clear()
	bounty = {}; enemy_boost = 0.0
	_release_controls("start_run"); dash_dir = Vector2.RIGHT; trail_acc = 0.0
''')

# 世界更新
rep('''	elapsed += dt
	_update_wave()
	if state != S.PLAYING: return
	_update_zones(dt)
''','''	elapsed += dt
	_update_wave()
	if state != S.PLAYING: return
	_update_altars(dt)
	_update_bounty(dt)
	if state != S.PLAYING: return
	_update_zones(dt)
''')

# 祭坛生成
rep('''	p.pos = _safe_position(p.pos, 16.0)
	level_banner = 2.4
	announce("第 %d 关 · %s" % [level_idx + 1, str(level_data.n)])
''','''	p.pos = _safe_position(p.pos, 16.0)
	altars.clear()
	var ax := W * 0.26 if level_idx % 2 == 0 else W * 0.74
	var ap := _safe_position(Vector2(ax, TOP + 150.0), 30.0)
	altars.append({ "pos": ap, "t": 0.0, "life": 70.0 })
	level_banner = 2.4
	announce("第 %d 关 · %s" % [level_idx + 1, str(level_data.n)])
''')

# 悬赏挂到第3波精英
rep('''	if wave_in_level % 3 == 0:
		spawn_elite(false)
		_spawn_heart_pickup()
''','''	if wave_in_level % 3 == 0:
		var be = spawn_elite(false)
		if be != null and bounty.is_empty():
			be["bounty"] = true
			bounty = { "e": be, "t": 22.0, "total": 22.0, "done": false }
			announce("悬赏 · 22 秒内击杀精英")
		_spawn_heart_pickup()
''')

# spawn_elite 返回
rep('''func spawn_elite(bonus: bool) -> void:
	if enemies.size() >= 30:
		return
''','''func spawn_elite(bonus: bool) -> Variant:
	if enemies.size() >= 30:
		return null
''')

rep('''	enemies.append(e)
	announce("精英出现 · " + _affix_name(affix))
	play_sfx("level")
''','''	enemies.append(e)
	announce("精英出现 · " + _affix_name(affix))
	play_sfx("level")
	return e
''')

# 敌人速度受贪婪代价影响
rep('''		var slow_f := 0.0 if freeze_t > 0.0 else (0.55 if e.slow_t > 0.0 else 1.0)
''','''		var slow_f := 0.0 if freeze_t > 0.0 else (0.55 if e.slow_t > 0.0 else 1.0)
		slow_f *= 1.0 + enemy_boost
''')

# 悬赏击杀奖励
rep('''	var g: float = float(base) * float(e.get("gold_m", 1.0)) * gold_mult * (1.0 + float(mini(combo, 50)) * 0.02) * (1.0 + p.greed) * _diff_gold()
	gold += int(ceil(g))
''','''	var g: float = float(base) * float(e.get("gold_m", 1.0)) * gold_mult * (1.0 + float(mini(combo, 50)) * 0.02) * (1.0 + p.greed) * _diff_gold()
	gold += int(ceil(g))
	if not bounty.is_empty() and bounty.get("e") == e and not bool(bounty.get("done", false)):
		bounty.done = true
		bounty.t = 2.0
		var bonus := 45 + level * 6
		gold += bonus
		p.hp = minf(p.max_hp, p.hp + p.max_hp * 0.2)
		announce("悬赏完成 · +" + str(bonus) + " 金")
		fx_at("kill", "halo", e.pos, "#ffd166", "#ffffff", 1.6)
''')

# 祭坛/悬赏逻辑函数
rep('''# ============================================================ 刷怪
func _spawn_logic(dt: float) -> void:
''','''# ============================================================ 祭坛 / 悬赏
func _update_altars(dt: float) -> void:
	for i in range(altars.size() - 1, -1, -1):
		var a = altars[i]
		a.t += dt
		if a.t >= a.life:
			altars.remove_at(i)
			continue
		if p.pos.distance_to(a.pos) < 44.0:
			open_altar()
			return

func open_altar() -> void:
	if state != S.PLAYING:
		return
	state = S.ALTAR
	_release_controls("altar")
	play_sfx("level")
	altar_choices.clear()
	var pool: Array = ALTAR_POOL.duplicate(true)
	while altar_choices.size() < 2 and pool.size() > 0:
		var idx := rng.randi_range(0, pool.size() - 1)
		altar_choices.append(pool[idx])
		pool.remove_at(idx)
	altar_rects = [ALTAR_R1, ALTAR_R2]

func apply_altar(i: int) -> void:
	if state != S.ALTAR or i < 0 or i >= altar_choices.size():
		return
	var c: Dictionary = altar_choices[i]
	match str(c.id):
		"fury":
			p.dmg *= 1.30
			p.max_hp = maxf(30.0, p.max_hp * 0.85)
		"wind":
			p.speed *= 1.15
			p.fire_cd *= 1.18
		"blood":
			p.regen += 1.5
			p.greed = maxf(0.0, p.greed - 0.20)
		"volley":
			p.arrows += 1
			p.dmg *= 0.88
		"greed":
			p.greed += 0.50
			enemy_boost += 0.10
		"bulwark":
			p.armor = minf(0.70, p.armor + 0.12)
			p.speed *= 0.92
		"arcane":
			p.element_power += 0.25
			p.max_hp = maxf(30.0, p.max_hp * 0.90)
		"hunter":
			p.crit = minf(0.90, p.crit + 0.10)
			p.max_hp = maxf(30.0, p.max_hp * 0.90)
		"titan":
			p.max_hp += 60.0
			p.speed *= 0.90
		"echo":
			p.chain += 1
			p.dmg *= 0.90
	p.hp = minf(p.hp, p.max_hp)
	altars.clear()
	altar_choices.clear()
	announce("祭坛 · " + str(c.n))
	toast_text = str(c.d) + "　代价：" + str(c.c)
	toast_t = 2.2
	fx_at("level", _class_fx_style(), p.pos, str(c.cc), "#ffffff", 1.4)
	state = S.PLAYING
	_release_controls("altar_done")

func skip_altar() -> void:
	if state != S.ALTAR:
		return
	gold += 20
	altars.clear()
	altar_choices.clear()
	toast_text = "放弃祭坛 · +20 金"
	toast_t = 1.6
	state = S.PLAYING
	_release_controls("altar_skip")

func _update_bounty(dt: float) -> void:
	if bounty.is_empty():
		return
	if bool(bounty.get("done", false)):
		bounty.t = float(bounty.t) - dt
		if bounty.t <= 0.0:
			bounty = {}
		return
	bounty.t = float(bounty.t) - dt
	var e = bounty.get("e", null)
	if e == null or bool(e.get("dead", true)):
		bounty.done = true
		bounty.t = 0.4
		return
	if float(bounty.t) <= 0.0:
		e.speed = float(e.speed) * 1.5
		e.dmg = float(e.dmg) * 1.5
		e.r = float(e.r) * 1.08
		e["enraged"] = true
		bounty.done = true
		bounty.t = 3.0
		announce("悬赏超时 · 精英狂暴")
		play_sfx("hurt")

# ============================================================ 刷怪
func _spawn_logic(dt: float) -> void:
''')

# 点击 / 键盘 / 绘制
rep('''		S.LEVELUP:
			for i in range(card_rects.size()):
''','''		S.ALTAR:
			for i in range(altar_rects.size()):
				if altar_rects[i].has_point(pos):
					apply_altar(i)
					return
			if ALTAR_SKIP.has_point(pos):
				skip_altar()
			return
		S.LEVELUP:
			for i in range(card_rects.size()):
''')

rep('''		KEY_1:
			if state == S.LEVELUP:
				choose_card(0)
		KEY_2:
			if state == S.LEVELUP:
				choose_card(1)
		KEY_3:
			if state == S.LEVELUP:
				choose_card(2)
''','''		KEY_1:
			if state == S.LEVELUP:
				choose_card(0)
			elif state == S.ALTAR:
				apply_altar(0)
		KEY_2:
			if state == S.LEVELUP:
				choose_card(1)
			elif state == S.ALTAR:
				apply_altar(1)
		KEY_3:
			if state == S.LEVELUP:
				choose_card(2)
			elif state == S.ALTAR:
				skip_altar()
''')

rep('''	if state == S.PLAYING: draw_banner()
	if _stick_visible():
''','''	if state == S.PLAYING: draw_banner()
	if not altars.is_empty():
		draw_altars(so)
	if _stick_visible():
''')

rep('''	elif state == S.PAUSED:
		draw_pause()
''','''	elif state == S.PAUSED:
		draw_pause()
	elif state == S.ALTAR:
		draw_altar_overlay()
''')

# HUD 悬赏
rep('''	if wave_affix != "":
		draw_string(font, Vector2(W * 0.5 - 200, 96), "词缀 · " + _affix_name(wave_affix), HORIZONTAL_ALIGNMENT_CENTER, 400, 14, Color("#ff9a3a"))
''','''	if wave_affix != "":
		draw_string(font, Vector2(W * 0.5 - 200, 96), "词缀 · " + _affix_name(wave_affix), HORIZONTAL_ALIGNMENT_CENTER, 400, 14, Color("#ff9a3a"))
	if not bounty.is_empty() and not bool(bounty.get("done", false)):
		var bt := maxf(0.0, float(bounty.get("t", 0.0)))
		draw_string(font, Vector2(W * 0.5 - 160, 118), "悬赏 %.1fs · 击杀金圈精英" % bt, HORIZONTAL_ALIGNMENT_CENTER, 320, 15, Color("#ffd166"))
''')

# 祭坛世界/覆盖层绘制
rep('''func draw_stick() -> void:
''','''func draw_altars(so: Vector2) -> void:
	for a in altars:
		var pos: Vector2 = a.pos + so
		var k: float = clampf(float(a.t) / float(a.life), 0.0, 1.0)
		draw_circle(pos, 30.0, Color(0.7, 0.45, 1.0, 0.12))
		draw_arc(pos, 34.0, elapsed * 1.6, elapsed * 1.6 + TAU, 32, Color(0.75, 0.55, 1.0, 0.65), 3.0, true)
		draw_arc(pos, 25.0, -elapsed * 2.1, -elapsed * 2.1 + TAU * 0.8, 24, Color(1.0, 0.85, 0.5, 0.55), 2.0, true)
		var d := 16.0 + sin(elapsed * 3.0) * 3.0
		draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -d), pos + Vector2(d, 0), pos + Vector2(0, d), pos + Vector2(-d, 0)]), Color(0.9, 0.7, 1.0, 0.8))
		draw_string(font, pos + Vector2(-24, 62), "祭坛", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#e6d4ff"))
		draw_arc(pos, 40.0, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - k), 30, Color(1.0, 0.6, 0.8, 0.5), 2.0, true)

func draw_altar_overlay() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.03, 0.02, 0.06, 0.86))
	_outline_text("祭坛 · 二选一", W * 0.5, 130, 42, Color("#e6d4ff"))
	tc("增益与代价同时生效 · 点卡牌 / 按 1 2 · 按 3 放弃", 168, 18, Color("#9fb3c8"))
	for i in range(altar_choices.size()):
		var c: Dictionary = altar_choices[i]
		var r: Rect2 = altar_rects[i]
		var cc := Color(str(c.cc))
		_card_bg(r, cc, true)
		draw_circle(r.get_center() + Vector2(0, -78), 44, Color(cc, 0.12))
		draw_colored_polygon(PackedVector2Array([
			r.get_center() + Vector2(0, -102), r.get_center() + Vector2(34, -78),
			r.get_center() + Vector2(0, -54), r.get_center() + Vector2(-34, -78)
		]), Color(cc, 0.85))
		tc_at(str(c.n), r.get_center().x, r.position.y + 150, 34, Color("#f0f8ff"))
		tc_at("增益 · " + str(c.d), r.get_center().x, r.position.y + 214, 22, Color("#7ee0c0"))
		tc_at("代价 · " + str(c.c), r.get_center().x, r.position.y + 254, 20, Color("#ff8fa3"))
		tc_at("点击选择", r.get_center().x, r.position.y + 300, 18, Color("#ffe08a"))
	_card_bg(ALTAR_SKIP, Color("#7f8fa6"), false)
	tc_at("放弃祭坛（+20 金）", ALTAR_SKIP.get_center().x, ALTAR_SKIP.position.y + 42, 22, Color("#dbe9ff"))

func draw_stick() -> void:
''')

io.open(P,'w',encoding='utf-8').write(s)
print('PATCH4 OK lines=%d'%s.count('\n'))
