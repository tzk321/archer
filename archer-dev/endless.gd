extends SceneTree

## v4.4 无尽轮回模式回归。

var g
var checks := 0
var failures := 0

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("ENDLESS_FAIL ", label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	g = load("res://game.gd").new()
	root.add_child(g)
	g.set_process(false)
	g.test_mode = true
	g.preview_mode = true

	g.start_endless()
	expect(g.endless_mode, "mode: endless active")
	expect(not g.single_level, "mode: not single-level")
	expect(g.state == g.S.PLAYING, "mode: playing")
	expect(int(g.meta.get("best_endless", -1)) >= 0, "meta: best_endless present")

	# 40 分钟也不触发战役胜利
	g.start_endless()
	g.elapsed = g.LEVEL_TIME * g.LevelsData.LIST.size() + 10.0
	g.state = g.S.PLAYING
	g.boss = null
	g.step_game(0.02)
	expect(not g.victory and g.state != g.S.OVER, "no campaign victory at 40 minutes")

	# 波次推进 + 商店节奏
	g.start_endless()
	g.elapsed = 39.9
	g.cur_wave = 0
	g.state = g.S.PLAYING
	g._update_wave()
	expect(g.cur_wave == 2, "wave advances to 2")
	expect(g.state == g.S.SHOP, "even wave opens shop")
	g._resume_play()

	# 120 秒换场，保留属性但清怪
	g.start_endless()
	g.elapsed = 120.0
	g.state = g.S.PLAYING
	g.enemies.clear()
	g._update_wave()
	expect(g.endless_rotation == 1, "rotation increments at 120")
	expect(g.level_idx == 4, "rotation picks next arena")
	expect(g.state == g.S.SHOP, "rotation opens shop")
	g._resume_play()

	# BOSS 随时间升级
	g.start_endless()
	g.elapsed = 0.0
	g.spawn_boss()
	var hp_early: float = g.boss_max_hp
	g.boss = null
	g.enemies.clear()
	g.elapsed = 240.0
	g.spawn_boss()
	var hp_late: float = g.boss_max_hp
	expect(hp_late > hp_early * 1.5, "boss scales with endless time")

	# 死亡结算写入无尽最佳
	g.start_endless()
	g.kills = 30
	g.cur_wave = 7
	g.level = 5
	g.best_combo = 12
	g.p.hp = 0.0
	g.step_game(0.02)
	expect(g.state == g.S.OVER, "death ends endless")
	expect(int(g.meta.get("best_endless", 0)) > 0, "death stores endless best")
	expect(int(g.meta.get("endless_wave", 0)) >= 7, "death stores endless wave")

	print("ENDLESS_SUMMARY checks=", checks, " failures=", failures)
	g.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures == 0 else 1)
