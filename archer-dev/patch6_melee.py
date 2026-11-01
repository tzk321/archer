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

rep('''	var special := str(w.get("special", "none"))
	var knock := float(w.get("knock", 30.0))
	if special == "spin":
		arc = TAU
''','''	var special := str(w.get("special", "none"))
	var wid := str(w.get("id", "ironsword"))
	var knock := float(w.get("knock", 30.0))
	var dual_now := false
	if special == "dual":
		dual_now = dual_swing
		dual_swing = not dual_swing
	if special == "spin":
		arc = TAU
''')

rep('''			if times > 1:
				dmg *= 0.6
			damage_enemy(e, dmg, crit)
''','''			if times > 1:
				dmg *= 0.6
			if special == "cleave" and hit_count > 0:
				dmg *= 1.25
			if dual_now:
				dmg *= 1.35
			if special == "none" and wid in ["ironsword", "longsword"] and p.hp / p.max_hp >= 0.8:
				dmg *= 1.12
			damage_enemy(e, dmg, crit)
			_melee_hit_fx(wid, e.pos, crit)
''')

rep('''	slashes.append({ "pos": p.pos, "aim": aim, "arc": arc, "range": reach, "t": 0.0, "dur": 0.28, "color": weapon_color, "special": special, "charged": charged, "cls": class_style })
''','''	slashes.append({ "pos": p.pos, "aim": aim, "arc": arc, "range": reach, "t": 0.0, "dur": 0.28, "color": weapon_color, "special": special, "charged": charged, "cls": class_style, "wid": wid, "dual": dual_now })
''')

rep('''func _update_slashes(dt: float) -> void:
''','''func _melee_hit_fx(wid: String, at: Vector2, crit: bool) -> void:
	var style := "cross"
	match wid:
		"greataxe", "greatsword": style = "blood"
		"hammer", "greatmaul": style = "ring"
		"spear": style = "bolt"
		"daggers", "shadowblade": style = "star"
		"fists": style = "spark"
		"scythe": style = "halo"
		"lightsaber": style = "flame"
		"venomfang": style = "smoke"
		"stormhammer": style = "bolt"
		"dualaxes": style = "burst"
	fx_at("hit", style, at, "#" + weapon_color.to_html(false), "#ffffff", 0.85 if crit else 0.68)

func _update_slashes(dt: float) -> void:
''')

# 近战武器逐把特效
rep('''		var col: Color = s.color
		if str(s.special) == "spear":
''','''		var col: Color = s.color
		var wid := str(s.get("wid", ""))
		var r2 := reach * (0.55 + 0.45 * k)
		match wid:
			"spear":
				var sd := Vector2(cos(aim), sin(aim))
				for q in range(3):
					var off := Vector2(cos(aim + PI * 0.5), sin(aim + PI * 0.5)) * (float(q) - 1.0) * 14.0
					draw_line(pos + off + sd * 26.0, pos + off + sd * reach * 0.85, Color(1, 1, 1, a * 0.35), 1.5)
				var tip := pos + sd * reach
				draw_colored_polygon(PackedVector2Array([tip + sd * 12.0, tip + sd.orthogonal() * 7.0, tip - sd.orthogonal() * 7.0]), Color(1, 0.95, 0.7, a))
			"ironsword", "longsword":
				var idir := Vector2(cos(aim), sin(aim))
				draw_line(pos + idir * 20.0, pos + idir * reach, Color(1, 1, 1, a * 0.55), 2.0)
				draw_arc(pos, r2, aim - arc * 0.5, aim + arc * 0.5, 24, Color(0.85, 0.95, 1.0, a * 0.45), 2.0, true)
			"greataxe":
				var gdir := Vector2(cos(aim), sin(aim))
				draw_line(pos, pos + gdir * reach * 0.9, Color(1.0, 0.3, 0.35, a * 0.28), 8.0 * a + 2.0)
				for q in range(3):
					var gp := pos + gdir * reach * (0.55 + q * 0.15)
					draw_circle(gp, 5.0 + q * 2.0, Color(0.9, 0.35, 0.3, a * 0.18))
			"greatsword":
				draw_arc(pos, r2 * 1.08, aim - arc * 0.5, aim + arc * 0.5, 28, Color(0.7, 0.9, 1.0, a * 0.65), 3.0, true)
				var gd2 := Vector2(cos(aim), sin(aim))
				draw_line(pos + gd2 * 18.0, pos + gd2 * reach, Color(0.9, 0.97, 1.0, a * 0.5), 3.0)
			"hammer", "greatmaul":
				var hd := Vector2(cos(aim), sin(aim))
				var hp2 := pos + hd * reach * 0.62
				draw_arc(hp2, 20.0 + 34.0 * k, 0, TAU, 28, Color(1.0, 0.82, 0.45, a * 0.7), 3.0, true)
				draw_circle(hp2, 16.0 + 20.0 * k, Color(1.0, 0.7, 0.3, a * 0.12))
				for q in range(4):
					var qa := float(q) * TAU / 4.0 + 0.4
					draw_circle(hp2 + Vector2(cos(qa), sin(qa)) * (18.0 + 40.0 * k), 3.0, Color(0.9, 0.75, 0.55, a * 0.5))
			"scythe":
				draw_arc(pos, r2 * 1.03, 0, TAU, 40, Color(0.55, 0.95, 0.55, a * 0.55), 5.0 * a + 1.5, true)
				for q in range(3):
					var ca := aim + float(q) * TAU / 3.0 + elapsed * 1.5
					draw_arc(pos, r2 * (0.7 + q * 0.1), ca, ca + 1.4, 12, Color(0.75, 1.0, 0.7, a * 0.5), 2.0, true)
					draw_circle(pos + Vector2(cos(ca), sin(ca)) * r2, 3.0, Color(0.85, 1.0, 0.8, a * 0.7))
			"daggers", "shadowblade":
				var doff := Vector2(cos(aim + PI * 0.5), sin(aim + PI * 0.5)) * 9.0
				draw_arc(pos + doff, r2 * 0.92, aim - arc * 0.42, aim + arc * 0.42, 20, Color(1.0, 0.6, 0.82, a * 0.75), 4.0 * a + 1.0, true)
				draw_arc(pos - doff, r2 * 0.92, aim - arc * 0.42, aim + arc * 0.42, 20, Color(0.75, 0.62, 1.0, a * 0.6), 3.0 * a + 1.0, true)
				for q in range(2):
					var da := aim + (float(q) - 0.5) * 0.35
					draw_line(pos + Vector2(cos(da), sin(da)) * 12.0, pos + Vector2(cos(da), sin(da)) * reach * 0.72, Color(0.8, 0.65, 1.0, a * 0.28), 2.0)
			"fists":
				for q in range(3):
					var fa := aim + (float(q) - 1.0) * 0.22
					var fp := pos + Vector2(cos(fa), sin(fa)) * reach * (0.55 + q * 0.12)
					for j in range(4):
						var ja := float(j) * TAU / 4.0
						draw_line(fp, fp + Vector2(cos(ja), sin(ja)) * 10.0 * a, Color(1.0, 0.88, 0.45, a * 0.7), 2.0)
			"lightsaber":
				draw_arc(pos, r2, aim - arc * 0.5, aim + arc * 0.5, 30, Color(0.4, 1.0, 1.0, a * 0.4), 14.0 * a + 4.0, true)
				draw_arc(pos, r2, aim - arc * 0.5, aim + arc * 0.5, 30, Color(0.95, 1.0, 1.0, a * 0.9), 4.0, true)
				for q in range(2):
					var la := aim + (0.3 if q == 0 else -0.3)
					draw_circle(pos + Vector2(cos(la), sin(la)) * r2, 4.0, Color(0.7, 1.0, 1.0, a * 0.7))
			"venomfang":
				for q in range(3):
					var va := aim + (float(q) - 1.0) * arc * 0.3
					var vp := pos + Vector2(cos(va), sin(va)) * reach * (0.45 + q * 0.12)
					draw_circle(vp, 5.0, Color(0.45, 0.9, 0.4, a * 0.65))
					draw_circle(vp + Vector2(0, 8.0 + 8.0 * k), 3.0, Color(0.55, 1.0, 0.5, a * 0.45))
			"stormhammer":
				var sdir := Vector2(cos(aim), sin(aim))
				var sp := pos + sdir * reach * 0.55
				var pts := PackedVector2Array([sp + Vector2(-26, -18) * a, sp + Vector2(-6, -3), sp + Vector2(-14, 7), sp + Vector2(12, 20) * a])
				draw_polyline(pts, Color(0.85, 0.75, 1.0, a * 0.9), 3.0)
				draw_arc(sp, 22.0 + 26.0 * k, 0, TAU, 24, Color(0.75, 0.65, 1.0, a * 0.6), 2.0, true)
			"dualaxes":
				var xdir := Vector2(cos(aim), sin(aim))
				draw_line(pos - xdir.orthogonal() * 18.0, pos + xdir.orthogonal() * 18.0 + xdir * reach * 0.7, Color(1.0, 0.55, 0.2, a * 0.45), 3.0)
				draw_line(pos + xdir.orthogonal() * 18.0, pos - xdir.orthogonal() * 18.0 + xdir * reach * 0.7, Color(1.0, 0.75, 0.3, a * 0.45), 3.0)
				draw_arc(pos, r2 * 0.9, aim - arc * 0.5, aim + arc * 0.5, 24, Color(1.0, 0.65, 0.25, a * 0.7), 4.0, true)
		if str(s.special) == "spear":
''')

# 近战演示模式
rep('''			"endless":
				start_endless()
				elapsed = 145.0
				cur_wave = 8
				wave_in_level = 2
''','''			"endless":
				start_endless()
				elapsed = 145.0
				cur_wave = 8
				wave_in_level = 2
			"melee":
				start_run()
				class_style = "blade"
				slashes.clear()
				var mw: Array = []
				for ww in WeaponsData.LIST:
					if str(ww.get("kind", "")) == "melee":
						mw.append(ww)
				for i in range(mw.size()):
					var ww = mw[i]
					var px := 150.0 + float(i % 5) * 245.0
					var py := 190.0 + float(int(i / 5)) * 185.0
					slashes.append({
						"pos": Vector2(px, py), "aim": -PI * 0.5 + (0.55 if i % 2 == 0 else -0.55),
						"arc": float(ww.get("arc", 1.5)), "range": float(ww.get("range", 100.0)),
						"t": 0.08, "dur": 0.28, "color": Color(str(ww.color)),
						"special": str(ww.get("special", "none")), "charged": i % 3 == 0,
						"cls": "blade", "wid": str(ww.id), "dual": false
					})
				state = S.PLAYING
''')

# demo 绘制：跳过玩家与 HUD，显示 15 把武器名
rep('''	if not "--demo=elements" in OS.get_cmdline_user_args(): draw_player(so)
	if not "--demo=elements" in OS.get_cmdline_user_args(): draw_aim(so)
''','''	if not "--demo=elements" in OS.get_cmdline_user_args() and not "--demo=melee" in OS.get_cmdline_user_args(): draw_player(so)
	if not "--demo=elements" in OS.get_cmdline_user_args() and not "--demo=melee" in OS.get_cmdline_user_args(): draw_aim(so)
''')
rep('''	if darkness:
		draw_darkness()
	draw_hud()
''','''	if darkness:
		draw_darkness()
	if "--demo=melee" in OS.get_cmdline_user_args():
		var mw2: Array = []
		for ww in WeaponsData.LIST:
			if str(ww.get("kind", "")) == "melee":
				mw2.append(ww)
		for i in range(mw2.size()):
			var ww = mw2[i]
			tc_at(str(ww.n), 150.0 + float(i % 5) * 245.0, 360.0 + float(int(i / 5)) * 185.0, 18, Color(str(ww.color)))
		return
	draw_hud()
''')

io.open(P,'w',encoding='utf-8').write(s)
print('PATCH6 OK lines=%d'%s.count('\n'))
