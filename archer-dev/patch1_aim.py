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

rep('## 瞎几把乱砍！ · Godot v4.2.1','## 瞎几把乱砍！ · Godot v4.3.0')
rep('## 自动瞄准 + 移动走位 + 冲刺 + 词缀/事件/精英/连击','## 手动瞄准 + 移动走位 + 冲刺 + 词缀/事件/精英/连击')

rep('''const MOVE_RECT := Rect2(0, TOP, W * 0.5, H - TOP - 18)
''','''const MOVE_RECT := Rect2(0, TOP, W * 0.5, H - TOP - 18)
# 右半屏手动瞄准：独立 owner，不和移动摇杆互抢。
const AIM_RECT := Rect2(W * 0.5, TOP, W * 0.5, H - TOP - 18)
const AIM_DEADZONE := 8.0
const AIM_RANGE := 150.0
const AIM_CHARGE_TIME := 1.15
''')

rep('''var last_aim := -PI * 0.5
''','''var last_aim := -PI * 0.5
var aim_active := false
var aim_id := -2
var aim_origin := Vector2.ZERO
var aim_cur := Vector2.ZERO
var aim_vec := Vector2.ZERO
var aim_hold := 0.0
var charge := 0.0
''')

rep('''		_handle_release(event.index)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if stick_active and event.index == stick_id:
			_update_stick(event.position)
''','''		_handle_release(event.index)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if stick_active and event.index == stick_id:
			_update_stick(event.position)
		elif aim_active and event.index == aim_id:
			_update_aim(event.position)
''')

rep('''	elif event is InputEventMouseMotion:
		if stick_active and stick_id == -1:
			_update_stick(event.position)
''','''	elif event is InputEventMouseMotion:
		if stick_active and stick_id == -1:
			_update_stick(event.position)
		elif aim_active and aim_id == -1:
			_update_aim(event.position)
''')

rep('''		S.PLAYING:
			if PAUSE_RECT.has_point(pos):
				toggle_pause()
				return
			if SHOP_BTN.has_point(pos):
				open_shop()
				return
			if DASH_RECT.has_point(pos):
				try_dash()
				return
			if stick_active or not MOVE_RECT.has_point(pos): return
			stick_active = true
			stick_id = id
			touch_origin = pos
			stick_base = STICK_HOME
			stick_cur = STICK_HOME
			stick_vec = Vector2.ZERO
			_trace_stick("press", id)
''','''		S.PLAYING:
			if PAUSE_RECT.has_point(pos):
				toggle_pause()
				return
			if SHOP_BTN.has_point(pos):
				open_shop()
				return
			if DASH_RECT.has_point(pos):
				try_dash()
				return
			# 左半屏：移动摇杆。右半屏：瞄准摇杆。两个 owner 完全独立。
			if MOVE_RECT.has_point(pos):
				if stick_active:
					return
				stick_active = true
				stick_id = id
				touch_origin = pos
				stick_base = STICK_HOME
				stick_cur = STICK_HOME
				stick_vec = Vector2.ZERO
				_trace_stick("press", id)
				return
			if AIM_RECT.has_point(pos):
				if aim_active:
					return
				aim_active = true
				aim_id = id
				aim_origin = pos
				aim_cur = pos
				aim_vec = Vector2.ZERO
				aim_hold = 0.0
				charge = 0.0
				last_aim = (pos - p.pos).angle()
				return
''')

rep('''func _handle_release(id: int, reason: String = "release") -> void:
	if stick_active and id == stick_id:
		_release_controls(reason)
''','''func _handle_release(id: int, reason: String = "release") -> void:
	if stick_active and id == stick_id:
		_release_stick(reason)
	elif aim_active and id == aim_id:
		_release_aim(reason)
''')

rep('''func _stick_visible() -> bool:
	return state == S.PLAYING
''','''func _update_aim(pos: Vector2) -> void:
	if not aim_active: return
	if state != S.PLAYING or backgrounded:
		_release_aim("inactive")
		return
	aim_cur = pos
	var offset := pos - aim_origin
	var distance := offset.length()
	if distance > AIM_DEADZONE:
		aim_vec = offset / distance * clampf((distance - AIM_DEADZONE) / AIM_RANGE, 0.0, 1.0)
		last_aim = offset.angle()
	else:
		aim_vec = Vector2.ZERO
		# 轻点也要有方向：朝点击处。
		last_aim = (pos - p.pos).angle()

func _update_aim_charge(dt: float) -> void:
	if not aim_active:
		aim_hold = 0.0
		charge = maxf(0.0, charge - dt * 2.5)
		return
	aim_hold += dt
	charge = minf(1.0, aim_hold / AIM_CHARGE_TIME)

func _release_aim(reason: String = "release") -> void:
	if aim_active and OS.is_debug_build():
		print("AIM_RELEASE reason=", reason, " id=", aim_id)
	aim_active = false
	aim_id = -2
	aim_vec = Vector2.ZERO
	aim_hold = 0.0
	charge = 0.0

func _stick_visible() -> bool:
	return state == S.PLAYING
''')

rep('''func _release_controls(reason: String = "state_change") -> void:
	var old_id := stick_id
	var had_owner := stick_active or stick_id != -1
	stick_active = false
	stick_id = -1
	touch_origin = Vector2.ZERO
	stick_vec = Vector2.ZERO
	stick_base = STICK_HOME
	stick_cur = STICK_HOME
	if not p.is_empty():
		p.vel = Vector2.ZERO
		p.dash_t = 0.0
	if had_owner: _trace_stick(reason, old_id)
''','''func _release_stick(reason: String = "state_change") -> void:
	var old_id := stick_id
	var had_owner := stick_active or stick_id != -1
	stick_active = false
	stick_id = -1
	touch_origin = Vector2.ZERO
	stick_vec = Vector2.ZERO
	stick_base = STICK_HOME
	stick_cur = STICK_HOME
	if not p.is_empty():
		p.vel = Vector2.ZERO
		p.dash_t = 0.0
	if had_owner: _trace_stick(reason, old_id)

func _release_controls(reason: String = "state_change") -> void:
	_release_stick(reason)
	_release_aim(reason)
''')

rep('''	_move_player(dt)
	_shoot(dt)
''','''	_move_player(dt)
	_update_aim_charge(dt)
	_shoot(dt)
''')

rep('''func _shoot(dt: float) -> void:
	fire_cd -= dt
	var melee := str(current_weapon.get("kind", "ranged")) == "melee"
	var wid := str(current_weapon.get("id", ""))
	var spell := wid in ["firestaff", "froststaff", "stormstaff", "voidstaff", "tome", "bonestaff", "beaststaff", "soulbell"]
	var reach: float = (float(current_weapon.get("range", 100.0)) + p.melee_range + 80.0) if melee else 1150.0
	var target = nearest_enemy(p.pos, reach, null)
	if target == null:
		return
	last_aim = (target.pos - p.pos).angle()
	if fire_cd <= 0.0:
		fire_cd = p.fire_cd
		if melee:
			_melee_attack()
		else:
			if spell:
				fx_at("level", "rune", p.pos, str(current_weapon.color), "#ffffff", 0.55)
				emit_particles(p.pos + Vector2(cos(last_aim), sin(last_aim)) * 22.0, weapon_color, 5, 70.0)
			fire_arrows(target)
''','''func _shoot(dt: float) -> void:
	fire_cd -= dt
	var melee := str(current_weapon.get("kind", "ranged")) == "melee"
	var wid := str(current_weapon.get("id", ""))
	var spell := wid in ["firestaff", "froststaff", "stormstaff", "voidstaff", "tome", "bonestaff", "beaststaff", "soulbell"]
	# 回归/测试模式保留自动索敌，保证既有战斗测试可推进；真实游戏只认手动瞄准。
	if test_mode:
		var reach: float = (float(current_weapon.get("range", 100.0)) + p.melee_range + 80.0) if melee else 1150.0
		var target = nearest_enemy(p.pos, reach, null)
		if target == null:
			return
		last_aim = (target.pos - p.pos).angle()
		if fire_cd <= 0.0:
			fire_cd = p.fire_cd
			if melee:
				_melee_attack(false)
			else:
				if spell:
					fx_at("level", "rune", p.pos, str(current_weapon.color), "#ffffff", 0.55)
					emit_particles(p.pos + Vector2(cos(last_aim), sin(last_aim)) * 22.0, weapon_color, 5, 70.0)
				fire_arrows_dir(last_aim, false)
		return
	if not aim_active:
		return
	if fire_cd > 0.0:
		return
	fire_cd = p.fire_cd
	var charged := charge >= 1.0
	if charged:
		charge = 0.0
		aim_hold = 0.0
		fx_at("level", "ring", p.pos, str(current_weapon.color), "#ffffff", 1.1)
		announce("蓄力射击！")
	if melee:
		_melee_attack(charged)
	else:
		if spell:
			fx_at("level", "rune", p.pos, str(current_weapon.color), "#ffffff", 0.55)
			emit_particles(p.pos + Vector2(cos(last_aim), sin(last_aim)) * 22.0, weapon_color, 5, 70.0)
		fire_arrows_dir(last_aim, charged)
''')

rep('''func _melee_attack() -> void:
	var w: Dictionary = current_weapon
	var aim := last_aim
	var reach := (float(w.get("range", 100.0)) + float(p.melee_range))
	var arc := (float(w.get("arc", 1.5)) + float(p.melee_arc))
''','''func _melee_attack(charged: bool = false) -> void:
	var w: Dictionary = current_weapon
	var aim := last_aim
	var reach := (float(w.get("range", 100.0)) + float(p.melee_range))
	var arc := (float(w.get("arc", 1.5)) + float(p.melee_arc))
	if charged:
		reach *= 1.2
		arc = minf(TAU, arc * 1.25)
''')

rep('''			var dmg: float = _attack_damage() * (p.crit_mult if crit else 1.0)
			if times > 1:
''','''			var dmg: float = _attack_damage() * (p.crit_mult if crit else 1.0)
			if charged:
				dmg *= 1.9
			if times > 1:
''')

rep('''	slashes.append({ "pos": p.pos, "aim": aim, "arc": arc, "range": reach, "t": 0.0, "dur": 0.28, "color": weapon_color, "special": special })
''','''	slashes.append({ "pos": p.pos, "aim": aim, "arc": arc, "range": reach, "t": 0.0, "dur": 0.28, "color": weapon_color, "special": special, "charged": charged })
''')

rep('''func fire_arrows(target) -> void:
	var aim: float = (target.pos - p.pos).angle()
	last_aim = aim
''','''func fire_arrows(target) -> void:
	fire_arrows_dir((target.pos - p.pos).angle(), false)

func fire_arrows_dir(aim: float, charged: bool = false) -> void:
	last_aim = aim
''')

rep('''		var dmg: float = _attack_damage() * (p.crit_mult if crit else 1.0)
		if spell: dmg *= 1.0 + p.element_power * (3.0 / 7.0)
		arrows.append({
''','''		var dmg: float = _attack_damage() * (p.crit_mult if crit else 1.0)
		if spell: dmg *= 1.0 + p.element_power * (3.0 / 7.0)
		if charged: dmg *= 1.9
		arrows.append({
''')

rep('''			"pierce": p.pierce, "bounce": p.bounce,
''','''			"pierce": p.pierce + (2 if charged else 0), "bounce": p.bounce,
''')

rep('''			"spell": spell, "element": ws if spell else "none", "origin": p.pos
''','''			"spell": spell, "element": ws if spell else "none", "origin": p.pos,
			"charged": charged, "cls": class_style
''')

rep('''	meta.cls = str(current_class.id)
''','''	meta.cls = str(current_class.id)
	class_style = str(current_class.id)
''')

rep('''var weapon_color := Color("#d9a066")
''','''var weapon_color := Color("#d9a066")
var class_style := "ranger"
''')

# 绘制瞄准辅助
rep('''	if not "--demo=elements" in OS.get_cmdline_user_args(): draw_player(so)
	draw_slashes(so)
''','''	if not "--demo=elements" in OS.get_cmdline_user_args(): draw_player(so)
	if not "--demo=elements" in OS.get_cmdline_user_args(): draw_aim(so)
	draw_slashes(so)
''')

rep('''func draw_stick() -> void:
''','''func draw_aim(so: Vector2) -> void:
	var pos: Vector2 = p.pos + so
	var dir := Vector2(cos(last_aim), sin(last_aim))
	var tip: Vector2 = pos + dir * 250.0
	draw_line(pos + dir * 26.0, tip, Color(weapon_color, 0.20), 2.0)
	draw_line(tip - dir * 14.0, tip, Color(weapon_color, 0.65), 3.0)
	draw_arc(tip, 9.0, 0, TAU, 20, Color(weapon_color, 0.55), 2.0, true)
	if aim_active:
		draw_circle(aim_origin, 9.0, Color(0.5, 0.9, 0.78, 0.18))
		draw_arc(aim_origin, 16.0, 0, TAU, 28, Color(0.5, 0.9, 0.78, 0.55), 2.0, true)
		draw_line(aim_origin, aim_cur, Color(0.8, 1.0, 0.95, 0.45), 2.0)
		draw_circle(aim_cur, 10.0, Color(0.85, 1.0, 0.95, 0.55))
	if charge > 0.0:
		draw_arc(pos, 36.0, -PI * 0.5, -PI * 0.5 + TAU * charge, 40,
			Color(1.0, 0.85, 0.35, 0.85) if charge >= 1.0 else Color(0.5, 0.9, 0.78, 0.65), 4.0, true)
	if charge >= 1.0:
		draw_string(font, pos + Vector2(-26, -46), "满蓄力", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#ffe08a"))
	if not aim_active:
		draw_string(font, Vector2(W - 236, BOTTOM - 12), "右侧按住瞄准 · 松手停火", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.6, 0.8, 0.75, 0.45))

func draw_stick() -> void:
''')

rep('''	draw_string(font, Vector2(80, 608), "拖动移动 · 冲刺躲避 · 自动瞄准", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#b4c3dd"))
''','''	draw_string(font, Vector2(80, 608), "左侧移动 · 右半屏按住瞄准开火 · 松手停火", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#b4c3dd"))
''')

# 冲刺无方向时用最后瞄准方向，已经如此。start_run 清空蓄力
rep('''	_release_controls("start_run"); dash_dir = Vector2.RIGHT; trail_acc = 0.0
''','''	_release_controls("start_run"); dash_dir = Vector2.RIGHT; trail_acc = 0.0
	aim_hold = 0.0; charge = 0.0; aim_vec = Vector2.ZERO
''')

io.open(P,'w',encoding='utf-8').write(s)
print('PATCH1 OK lines=%d'%s.count('\n'))
