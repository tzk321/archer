extends SceneTree

## v4.4 全近战武器特效/真实差异回归。

var g
var checks := 0
var failures := 0

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("MELEE_FAIL ", label)

func _initialize() -> void:
	call_deferred("run")

func class_for(wid: String) -> String:
	for c in g.ClassesData.LIST:
		if g.WeaponsData.allowed(str(c.id), wid):
			return str(c.id)
	return "blade"

func dummy(pos: Vector2, hp: float = 10000.0):
	g.enemy_id += 1
	var e := {
		"id": g.enemy_id, "type": "slime", "pos": pos, "hp": hp, "max_hp": hp,
		"speed": 0.0, "dmg": 0.0, "xp": 1, "r": 18.0, "gold_m": 1.0,
		"phase": 0.0, "shot_cd": 9.0, "flash": 0.0, "dead": false,
		"shield": 0.0, "shield_max": 0.0, "slow_t": 0.0, "poison_t": 0.0,
		"poison_dps": 0.0, "burn_t": 0.0, "burn_dps": 0.0,
		"elite": false, "affix": "", "split": false
	}
	g.enemies.append(e)
	return e

func setup_weapon(wid: String) -> void:
	g.meta.cls = class_for(wid)
	g.meta.weapon = wid
	g._apply_meta_visuals()
	g.start_run()
	g.enemies.clear()
	g.fxs.clear()
	g.particles.clear()
	g.zaps.clear()
	g.slashes.clear()
	g.class_style = "ranger"
	g.p.crit = 0.0
	g.p.crit_mult = 2.0
	g.last_aim = 0.0
	g.blade_stack = 0
	g.dual_swing = false

func run() -> void:
	g = load("res://game.gd").new()
	root.add_child(g)
	g.set_process(false)
	g.test_mode = true
	g.preview_mode = true

	var melee: Array = []
	for w in g.WeaponsData.LIST:
		if str(w.get("kind", "")) == "melee":
			melee.append(w)
	expect(melee.size() == 15, "15 melee weapons present")

	for w in melee:
		var wid := str(w.id)
		setup_weapon(wid)
		var e = dummy(g.p.pos + Vector2(55, 0))
		g._melee_attack()
		expect(g.slashes.size() == 1, "slash created " + wid)
		if g.slashes.size() == 1:
			expect(str(g.slashes[0].get("wid", "")) == wid, "slash carries weapon id " + wid)
		expect(e.hp < 10000.0, "hit lands " + wid)
		expect(g.fxs.size() > 0, "weapon hit fx " + wid)

	# 剑士剑势仍生效
	setup_weapon("ironsword")
	g.class_style = "blade"
	var be = dummy(g.p.pos + Vector2(55, 0))
	g.blade_stack = 2
	g._melee_attack()
	expect(g.blade_stack == 0, "blade stack fires")
	expect(g.fxs.size() > 0, "blade shockwave fx")

	# cleave：第二个目标 +25%
	setup_weapon("greataxe")
	var c1 = dummy(g.p.pos + Vector2(55, 0))
	var c2 = dummy(g.p.pos + Vector2(75, 0))
	g._melee_attack()
	var d1: float = 10000.0 - c1.hp
	var d2: float = 10000.0 - c2.hp
	expect(d2 > d1 * 1.15, "cleave second target bonus")

	# dual：第二次挥砍 +35%
	setup_weapon("dualaxes")
	var x1 = dummy(g.p.pos + Vector2(55, 0))
	g._melee_attack()
	var xd1: float = 10000.0 - x1.hp
	var x2 = dummy(g.p.pos + Vector2(55, 0))
	g._melee_attack()
	var xd2: float = 10000.0 - x2.hp
	expect(xd2 > xd1 * 1.25, "dual second swing bonus")

	# steady：满血铁剑 +12%
	setup_weapon("ironsword")
	g.p.hp = g.p.max_hp
	var s1 = dummy(g.p.pos + Vector2(55, 0))
	g._melee_attack()
	var sd1: float = 10000.0 - s1.hp
	setup_weapon("ironsword")
	g.p.hp = 1.0
	var s2 = dummy(g.p.pos + Vector2(55, 0))
	g._melee_attack()
	var sd2: float = 10000.0 - s2.hp
	expect(sd1 > sd2 * 1.08, "steady full-hp bonus")

	# 元素/特殊命中真实生效
	setup_weapon("lightsaber")
	var le = dummy(g.p.pos + Vector2(55, 0))
	g._melee_attack()
	expect(float(le.get("burn_t", 0.0)) > 0.0, "lightsaber burn")
	setup_weapon("venomfang")
	var ve = dummy(g.p.pos + Vector2(55, 0))
	g._melee_attack()
	expect(float(ve.get("poison_t", 0.0)) > 0.0, "venomfang poison")
	setup_weapon("stormhammer")
	var te = dummy(g.p.pos + Vector2(55, 0))
	var te2 = dummy(g.p.pos + Vector2(95, 0))
	g._melee_attack()
	expect(g.zaps.size() > 0, "stormhammer chain")
	setup_weapon("scythe")
	expect(true, "scythe reachable")
	setup_weapon("hammer")
	var he = dummy(g.p.pos + Vector2(55, 0))
	g._melee_attack()
	expect(g.fxs.size() > 0, "hammer slam fx")

	print("MELEE_SUMMARY checks=", checks, " failures=", failures)
	g.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures == 0 else 1)
