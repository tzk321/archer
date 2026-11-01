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

rep('''var class_style := "ranger"
''','''var class_style := "ranger"
var blade_stack := 0
''')

rep('''	aim_hold = 0.0; charge = 0.0; aim_vec = Vector2.ZERO
''','''	aim_hold = 0.0; charge = 0.0; aim_vec = Vector2.ZERO
	blade_stack = 0
''')

rep('''func choose_card(i: int) -> void:
	if state != S.LEVELUP or i < 0 or i >= cards.size():
		return
	var u = cards[i]
	apply_skill(str(u.id))
''','''func _class_hex() -> String:
	return "#" + _class_color(class_style).to_html(false)

func _class_fx_style() -> String:
	match class_style:
		"blade": return "cross"
		"mage": return "rune"
		"assassin": return "star"
		"berserker": return "burst"
		"summoner": return "petal"
	return "ring"

func choose_card(i: int) -> void:
	if state != S.LEVELUP or i < 0 or i >= cards.size():
		return
	var u = cards[i]
	apply_skill(str(u.id))
	fx_at("level", _class_fx_style(), p.pos, _class_hex(), "#ffffff", 0.9)
''')

# 刺客破绽 / 暴击标记
rep('''	var d := maxf(0.0, dmg)
	if p.cull > 0 and e.hp / e.max_hp < 0.3: d *= 1.0 + 0.2 * p.cull
''','''	var d := maxf(0.0, dmg)
	if class_style == "assassin" and float(e.get("mark_t", 0.0)) > 0.0:
		d *= 1.15
	if class_style == "assassin" and crit:
		e.mark_t = 2.5
	if p.cull > 0 and e.hp / e.max_hp < 0.3: d *= 1.0 + 0.2 * p.cull
''')

rep('''	fx_at("hit", str(fx_hit_data.style), e.pos, str(fx_hit_data.c1), str(fx_hit_data.c2), 0.7)
	play_sfx("hit", rng.randf_range(0.9, 1.1))
''','''	fx_at("hit", str(fx_hit_data.style), e.pos, str(fx_hit_data.c1), str(fx_hit_data.c2), 0.7)
	if crit or rng.randf() < 0.35:
		emit_particles(e.pos, _class_color(class_style), 2 if crit else 1, 85.0)
	play_sfx("hit", rng.randf_range(0.9, 1.1))
''')

rep('''		if e.poison_t > 0.0:
			e.poison_t -= dt
''','''		if float(e.get("mark_t", 0.0)) > 0.0:
			e.mark_t = maxf(0.0, float(e.mark_t) - dt)
		if e.poison_t > 0.0:
			e.poison_t -= dt
''')

# 近战职业差异
rep('''			damage_enemy(e, dmg, crit)
		if special == "burn":
''','''			damage_enemy(e, dmg, crit)
			if class_style == "blade":
				blade_stack += 1
				if blade_stack >= 3:
					blade_stack = 0
					explode_at(e.pos, 95.0, _attack_damage() * 0.7)
					fx_at("level", "shockwave", e.pos, "#9fd0ff", "#ffffff", 1.1)
			elif class_style == "berserker":
				p.hp = minf(p.max_hp, p.hp + dmg * 0.03)
				emit_particles(e.pos, Color("#ff4d6d"), 2, 80.0)
		if special == "burn":
''')

rep('''	slashes.append({ "pos": p.pos, "aim": aim, "arc": arc, "range": reach, "t": 0.0, "dur": 0.28, "color": weapon_color, "special": special, "charged": charged })
''','''	slashes.append({ "pos": p.pos, "aim": aim, "arc": arc, "range": reach, "t": 0.0, "dur": 0.28, "color": weapon_color, "special": special, "charged": charged, "cls": class_style })
''')

# 箭矢职业 + 元素真实差异
rep('''				var dmg: float = a.dmg
				if p.farshot > 0: dmg *= 1.0 + 0.12 * p.farshot * minf(2.0, a.pos.distance_to(a.get("origin", p.pos)) / 300.0)
				damage_enemy(e, dmg, bool(a.crit))
''','''				var dmg: float = a.dmg
				if p.farshot > 0: dmg *= 1.0 + 0.12 * p.farshot * minf(2.0, a.pos.distance_to(a.get("origin", p.pos)) / 300.0)
				if class_style == "ranger" and a.pos.distance_to(a.get("origin", p.pos)) > 380.0:
					dmg *= 1.15
				if class_style == "summoner" and bool(a.get("homing", false)):
					dmg *= 1.10
				damage_enemy(e, dmg, bool(a.crit))
''')

rep('''					fx_at("hit", str(styles.get(str(a.get("element", "none")), "ring")), e.pos, "#" + a.color.to_html(), "#ffffff", 0.9)
''','''					fx_at("hit", str(styles.get(str(a.get("element", "none")), "ring")), e.pos, "#" + a.color.to_html(), "#ffffff", 0.9)
					if str(a.get("element", "")) == "burn" and str(current_weapon.get("id", "")) == "firestaff":
						explode_at(a.pos, 58.0, dmg * 0.30)
''')

# 拉弓/法杖视觉区分
rep('''		if bool(a.boomerang):
			draw_arc(pos, 10.0, float(a.spin), float(a.spin) + PI * 1.5, 12, Color("#f2c94c", 0.8), 2.0)
''','''		if bool(a.boomerang):
			draw_arc(pos, 10.0, float(a.spin), float(a.spin) + PI * 1.5, 12, Color("#f2c94c", 0.8), 2.0)
		var cls := str(a.get("cls", ""))
		if cls == "assassin":
			draw_line(pos - dir * 10.0, pos + dir * 10.0, Color("#f0a6ff", 0.9), 2.5)
			draw_circle(pos + dir * 11.0, 2.5, Color("#ffffff"))
		elif cls == "summoner":
			draw_circle(pos, 7.0, Color(0.45, 1.0, 0.65, 0.16))
			draw_circle(pos, 2.6, Color("#b6ffb0"))
		if bool(a.get("charged", false)):
			draw_arc(pos, 15.0, -PI * 0.5, PI * 1.3, 18, Color(1.0, 0.88, 0.4, 0.85), 2.5, true)
''')

# 斩击职业差异 + 蓄力
rep('''func draw_slashes(so: Vector2) -> void:
	for s in slashes:
''','''func draw_slashes(so: Vector2) -> void:
	for s in slashes:
''')
rep('''		if str(s.special) == "slam":
			draw_circle(pos + Vector2(cos(aim), sin(aim)) * reach * 0.6, 30.0 * (0.5 + k), Color("#ff8a3a", a * 0.25))
''','''		if str(s.special) == "slam":
			draw_circle(pos + Vector2(cos(aim), sin(aim)) * reach * 0.6, 30.0 * (0.5 + k), Color("#ff8a3a", a * 0.25))
		if bool(s.get("charged", false)):
			draw_arc(pos, reach * (0.7 + 0.35 * k), aim - arc * 0.5, aim + arc * 0.5, 40, Color(1.0, 0.88, 0.4, a * 0.55), 12.0 * a + 2.0, true)
		match str(s.get("cls", "")):
			"blade":
				draw_line(pos + Vector2(cos(aim), sin(aim)) * 18.0, pos + Vector2(cos(aim), sin(aim)) * reach, Color("#dbe9ff", a * 0.55), 2.0)
			"assassin":
				var off := Vector2(cos(aim + PI * 0.5), sin(aim + PI * 0.5)) * 10.0
				draw_arc(pos + off, reach * (0.5 + 0.4 * k), aim - arc * 0.42, aim + arc * 0.42, 24, Color("#ff9ac9", a * 0.7), 5.0 * a + 1.0, true)
				draw_arc(pos - off, reach * (0.5 + 0.4 * k), aim - arc * 0.42, aim + arc * 0.42, 24, Color("#c0a0ff", a * 0.6), 4.0 * a + 1.0, true)
			"berserker":
				draw_line(pos, pos + Vector2(cos(aim), sin(aim)) * reach * 0.9, Color("#ff5d73", a * 0.28), 10.0 * a + 2.0)
''')

# 职业光环
rep('''	if p.dash_t > 0.0:
		draw_circle(pos, 20, Color(0.5, 0.9, 0.78, 0.25))
''','''	if p.dash_t > 0.0:
		draw_circle(pos, 20, Color(0.5, 0.9, 0.78, 0.25))
	match class_style:
		"blade":
			draw_arc(pos, 27.0, aim - 1.2, aim + 1.2, 18, Color(0.62, 0.82, 1.0, 0.22), 2.0, true)
		"berserker":
			if p.hp / p.max_hp < 0.5:
				draw_arc(pos, 30.0, elapsed * 2.0, elapsed * 2.0 + TAU, 32, Color(1.0, 0.35, 0.45, 0.28), 3.0, true)
		"assassin":
			draw_arc(pos, 24.0, aim + PI * 0.7, aim + PI * 1.3, 16, Color(1.0, 0.6, 0.8, 0.20), 2.0, true)
		"summoner":
			draw_arc(pos, 26.0, -elapsed * 1.4, -elapsed * 1.4 + TAU, 26, Color(0.55, 0.95, 0.55, 0.22), 2.0, true)
''')

# 敌人破绽标记
rep('''		if e.flash > 0.0:
			draw_circle(pos, rr + 1.0, Color(1, 1, 1, 0.8))
''','''		if float(e.get("mark_t", 0.0)) > 0.0:
			draw_arc(pos, rr + 6.0, elapsed * 3.0, elapsed * 3.0 + TAU, 24, Color("#ff7aa6", 0.75), 2.0, true)
			draw_line(pos + Vector2(-5, -rr - 4), pos + Vector2(5, -rr + 4), Color("#ff7aa6", 0.8), 2.0)
			draw_line(pos + Vector2(5, -rr - 4), pos + Vector2(-5, -rr + 4), Color("#ff7aa6", 0.8), 2.0)
		if e.flash > 0.0:
			draw_circle(pos, rr + 1.0, Color(1, 1, 1, 0.8))
''')

io.open(P,'w',encoding='utf-8').write(s)
print('PATCH3 OK lines=%d'%s.count('\n'))
