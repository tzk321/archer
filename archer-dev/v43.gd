extends SceneTree

## v4.3 新功能回归：手动瞄准 owner、蓄力、永久强化、祭坛、悬赏、职业差异。

var g
var checks := 0
var failures := 0

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("V43_FAIL ", label)

func approx(a: float, b: float, eps: float = 0.01) -> bool:
	return absf(a - b) <= eps

func _initialize() -> void:
	call_deferred("run")

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

func arrow_at(pos: Vector2, dmg: float, origin: Vector2, extra: Dictionary = {}) -> Dictionary:
	var a := {
		"pos": pos, "prev": pos, "vel": Vector2(0.001, 0.0), "dmg": dmg, "crit": false,
		"pierce": 0, "bounce": 0, "life": 1.0, "hit": {}, "color": Color("#ffffff"),
		"explode_r": 0.0, "frost": false, "poison": false, "burn": false,
		"chain": 0, "lifesteal": 0.0, "homing": false, "boomerang": false,
		"execute": false, "spin": 0.0, "reversed": false, "spell": false,
		"element": "none", "origin": origin, "charged": false, "cls": ""
	}
	for k in extra:
		a[k] = extra[k]
	return a

func run() -> void:
	g = load("res://game.gd").new()
	root.add_child(g)
	g.set_process(false)
	g.test_mode = true
	g.preview_mode = true
	g.start_run()
	g.state = g.S.PLAYING

	# ---- 1. 手动瞄准：不按右半屏就不开火 ----
	g.test_mode = false
	g.arrows.clear()
	g.fire_cd = 0.0
	var e1 = dummy(g.p.pos + Vector2(140, 0))
	g._shoot(0.016)
	expect(g.arrows.is_empty(), "manual aim: no auto fire without aim")
	e1.dead = true
	g.enemies.clear()

	g._handle_press(Vector2(1000, 500), 7)
	expect(g.aim_active and g.aim_id == 7, "manual aim: right half claims aim owner")
	expect(not g.stick_active, "manual aim: aim does not claim stick")
	g._update_aim(Vector2(1080, 500))
	expect(absf(g.last_aim) < 0.05, "manual aim: drag sets direction")
	g.p.crit = 0.0
	g.fire_cd = 0.0
	g._shoot(0.016)
	expect(g.arrows.size() >= 1, "manual aim: fires while held")
	if g.arrows.size() >= 1:
		expect(g.arrows[0].vel.x > 0.0, "manual aim: arrow follows aim")
	g._handle_release(7)
	expect(not g.aim_active and g.aim_id == -2, "manual aim: release stops fire")
	g.arrows.clear()
	g.fire_cd = 0.0
	g._shoot(0.016)
	expect(g.arrows.is_empty(), "manual aim: released does not fire")

	# ---- 2. 左右 owner 互不抢占 ----
	g._handle_press(Vector2(600, 550), 8)
	g._handle_press(Vector2(1000, 550), 9)
	expect(g.stick_active and g.stick_id == 8, "owner: left stick")
	expect(g.aim_active and g.aim_id == 9, "owner: right aim")
	g._handle_press(Vector2(1100, 500), 10)
	expect(g.aim_id == 9, "owner: second right pointer cannot steal aim")
	g._handle_release(10)
	expect(g.aim_active and g.aim_id == 9, "owner: non-owner release keeps aim")
	g._handle_release(8)
	expect(not g.stick_active and g.aim_active, "owner: stick release keeps aim")
	g._handle_release(9)
	expect(not g.aim_active and not g.stick_active, "owner: both released")

	# ---- 3. 测试模式仍自动索敌（回归兼容） ----
	g.test_mode = true
	g.arrows.clear()
	g.fire_cd = 0.0
	var e2 = dummy(g.p.pos + Vector2(120, 0))
	g._shoot(0.016)
	expect(g.arrows.size() >= 1, "test mode: auto aim preserved")
	e2.dead = true
	g.enemies.clear()
	g.test_mode = false

	# ---- 4. 蓄力射击 ----
	g._handle_press(Vector2(1000, 500), 11)
	g._update_aim(Vector2(1080, 500))
	for i in range(12):
		g._update_aim_charge(0.1)
	expect(g.charge >= 1.0, "charge: fills while held")
	g.p.crit = 0.0
	g.arrows.clear()
	g.fire_cd = 0.0
	var base_dmg: float = g._attack_damage()
	g._shoot(0.016)
	expect(g.arrows.size() >= 1, "charge: charged shot fired")
	if g.arrows.size() >= 1:
		expect(bool(g.arrows[0].get("charged", false)), "charge: arrow flagged")
		expect(g.arrows[0].dmg > base_dmg * 1.7, "charge: real damage boost")
	g._handle_release(11)

	# ---- 5. 永久强化属性 ----
	g.test_mode = true
	g.meta.perm = { "atk": 2, "hp": 3, "speed": 2, "crit": 2, "magnet": 1, "greed": 2 }
	g._apply_meta_visuals()
	g._init_player()
	var c = g.current_class
	var w = g.current_weapon
	var base_hp: float = float(c.hp) + 18.0 * 3.0
	expect(approx(g.p.max_hp, base_hp), "perm: hp applied")
	expect(approx(g.p.speed, float(c.speed) * 1.08), "perm: speed applied")
	expect(approx(g.p.crit, float(c.crit) + 0.04), "perm: crit applied")
	expect(approx(g.p.magnet, 120.0 * 1.18), "perm: magnet applied")
	expect(approx(g.p.greed, 0.12), "perm: greed applied")
	var expected_dmg: float = 10.0 * float(c.dmg) * float(w.dmg) * 1.16
	expect(approx(g.p.dmg, expected_dmg), "perm: damage applied")
	g.meta.perm = {}
	g._init_player()

	# ---- 6. 永久强化购买 / 上限 / 失败回滚 ----
	g.state = g.S.UPGRADES
	g._build_perm_grid()
	g.meta.coins = 1000
	g.perm_buy(0)
	expect(int(g.meta.perm.get("atk", 0)) == 1, "perm buy: level up")
	expect(int(g.meta.coins) == 940, "perm buy: price deducted")
	g.meta.coins = 0
	g.perm_buy(1)
	expect(int(g.meta.perm.get("hp", 0)) == 0, "perm buy: no money no purchase")
	g.meta.coins = 1000
	g.test_mode = false
	g.preview_mode = false
	g.meta_readonly = true
	var lv_before := int(g.meta.perm.get("atk", 0))
	var coins_before := int(g.meta.coins)
	g.perm_buy(0)
	expect(int(g.meta.perm.get("atk", 0)) == lv_before and int(g.meta.coins) == coins_before, "perm buy: rollback on save failure")
	g.meta_readonly = false
	g.test_mode = true
	g.preview_mode = true

	# ---- 7. 存档兼容与持久化 ----
	g.test_mode = false
	g.preview_mode = false
	g.meta.perm = { "atk": 3, "hp": 1 }
	g.meta.coins = 777
	expect(g._save_meta(), "save: perm written")
	g.meta.perm = {}
	g.meta.coins = 0
	g._load_meta()
	expect(int(g.meta.perm.get("atk", 0)) == 3, "load: perm restored")
	expect(int(g.meta.coins) == 777, "load: coins restored")
	# 旧档：没有 perm 字段仍能读，默认 0 级
	var legacy := ConfigFile.new()
	legacy.set_value("meta", "coins", 123)
	legacy.set_value("meta", "weapon", "shortbow")
	legacy.set_value("meta", "skin", "ranger")
	legacy.set_value("meta", "cls", "ranger")
	legacy.set_value("meta", "schema_version", 1)
	legacy.save("user://settings.cfg")
	g.meta.perm = { "atk": 9 }
	g._load_meta()
	expect(int(g.meta.coins) == 123, "legacy: old save reads")
	expect(g.meta.perm.is_empty(), "legacy: missing perm defaults empty")
	g.test_mode = true
	g.preview_mode = true

	# ---- 8. 祭坛二选一 ----
	g.meta.perm = {}
	g.altar_test_mode = true
	g.start_run()
	g.state = g.S.PLAYING
	g.enemies.clear()
	expect(g.altars.size() == 1, "altar: spawned per level")
	g.p.pos = g.altars[0].pos
	g.step_game(0.02)
	expect(g.state == g.S.ALTAR, "altar: stepping on it opens choice")
	expect(g.altar_choices.size() == 2, "altar: two choices")
	if g.altar_choices.size() == 2:
		expect(str(g.altar_choices[0].d) != "" and str(g.altar_choices[0].c) != "", "altar: boon and curse shown")
	var stats_before := [g.p.dmg, g.p.max_hp, g.p.speed, g.p.crit, g.p.armor, g.p.regen, g.p.greed, float(g.p.arrows), g.p.element_power, float(g.p.chain), g.p.fire_cd]
	g.apply_altar(0)
	expect(g.state == g.S.PLAYING, "altar: choice resumes play")
	var stats_after := [g.p.dmg, g.p.max_hp, g.p.speed, g.p.crit, g.p.armor, g.p.regen, g.p.greed, float(g.p.arrows), g.p.element_power, float(g.p.chain), g.p.fire_cd]
	expect(stats_before != stats_after, "altar: choice has real effect")
	g.open_altar()
	var gold_before: int = g.gold
	g.skip_altar()
	expect(g.gold == gold_before + 20, "altar: skip pays 20")
	expect(g.state == g.S.PLAYING, "altar: skip resumes play")

	# ---- 9. 悬赏 ----
	g.start_run()
	g.enemies.clear()
	var be = g.spawn_elite(false)
	g.bounty = { "e": be, "t": 22.0, "total": 22.0, "done": false }
	be["bounty"] = true
	g.p.hp = maxf(1.0, g.p.max_hp - 50.0)
	var gold0: int = g.gold
	var hp0: float = g.p.hp
	g.kill_enemy(be)
	expect(bool(g.bounty.get("done", false)), "bounty: kill marks done")
	expect(g.gold >= gold0 + 45, "bounty: kill pays bonus")
	expect(g.p.hp >= hp0, "bounty: kill heals")
	g.bounty = {}
	var be2 = g.spawn_elite(false)
	g.bounty = { "e": be2, "t": 0.01, "total": 22.0, "done": false }
	var spd0: float = be2.speed
	g._update_bounty(0.02)
	expect(bool(be2.get("enraged", false)), "bounty: timeout enrages")
	expect(be2.speed > spd0, "bounty: enrage is real")
	g.bounty = {}

	# ---- 10. 职业差异 ----
	# 剑士：三次命中触发剑势冲击波
	g.meta.cls = "blade"
	g._apply_meta_visuals()
	g._init_player()
	g.start_run()
	g.enemies.clear()
	g.fxs.clear()
	var be3 = dummy(g.p.pos + Vector2(50, 0))
	g.last_aim = 0.0
	g.blade_stack = 2
	g._melee_attack()
	expect(g.blade_stack == 0, "class blade: stack resets at 3")
	expect(g.fxs.size() > 0, "class blade: shockwave fx")
	# 刺客：暴击标记，后续伤害 +15%
	g.enemies.clear()
	g.class_style = "assassin"
	g.p.crit = 0.0
	var ae = dummy(g.p.pos + Vector2(80, 0))
	g.damage_enemy(ae, 10.0, true)
	expect(float(ae.get("mark_t", 0.0)) > 0.0, "class assassin: crit marks")
	var hp_a: float = ae.hp
	g.damage_enemy(ae, 10.0, false)
	expect(hp_a - ae.hp > 11.0, "class assassin: mark amplifies damage")
	# 游侠：远距离箭 +15%
	g.class_style = "ranger"
	g.enemies.clear()
	g.arrows.clear()
	var re = dummy(g.p.pos + Vector2(400, 0))
	var ra = arrow_at(re.pos, 10.0, g.p.pos, { "cls": "ranger", "charged": false })
	g.arrows.append(ra)
	g._update_arrows(0.001)
	expect(re.hp < 10000.0 - 11.0, "class ranger: long shot bonus")
	# 法师火杖：命中溅射
	g.class_style = "mage"
	g.current_weapon = g.WeaponsData.find("firestaff")
	g.p.crit = 0.0
	g.enemies.clear()
	g.arrows.clear()
	var me1 = dummy(g.p.pos + Vector2(300, 0))
	var me2 = dummy(g.p.pos + Vector2(330, 0))
	var ma = arrow_at(me1.pos, 10.0, g.p.pos, { "spell": true, "element": "burn", "cls": "mage" })
	g.arrows.append(ma)
	g._update_arrows(0.001)
	expect(me2.hp < 10000.0, "class mage: fire staff splash")
	# 狂战：近战吸血
	g.class_style = "berserker"
	g.current_weapon = g.WeaponsData.find("greataxe")
	g._init_player()
	g.enemies.clear()
	g.p.hp = 20.0
	var bze = dummy(g.p.pos + Vector2(60, 0))
	g.last_aim = 0.0
	g._melee_attack()
	expect(g.p.hp > 20.0, "class berserker: melee lifesteal")
	# 召唤师：追踪箭 +10%
	g.class_style = "summoner"
	g.p.crit = 0.0
	g.enemies.clear()
	g.arrows.clear()
	var se = dummy(g.p.pos + Vector2(400, 0))
	var sa = arrow_at(se.pos, 10.0, g.p.pos, { "cls": "summoner", "homing": true })
	g.arrows.append(sa)
	g._update_arrows(0.001)
	expect(se.hp < 10000.0 - 10.9, "class summoner: spirit bonus")

	print("V43_SUMMARY checks=", checks, " failures=", failures)
	g.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures == 0 else 1)
