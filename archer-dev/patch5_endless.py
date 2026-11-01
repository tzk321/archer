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

rep('''const PERM_BACK := Rect2(W - 168, 24, 140, 52)
''','''const PERM_BACK := Rect2(W - 168, 24, 140, 52)
const MODE_RECT := Rect2(W - 388, 20, 208, 52)
const ENDLESS_ROTATE := 120.0
const ENDLESS_BOSS_GAP := 80.0
''')

rep('''var altar_test_mode := false
''','''var altar_test_mode := false
var endless_mode := false
var lobby_mode := "campaign"
var endless_rotation := 0
var dual_swing := false
''')

rep('''	"perm": {},
	"best": 0, "bgm": 0.65, "sfx": 0.65
''','''	"perm": {},
	"best": 0, "best_endless": 0, "endless_wave": 0, "bgm": 0.65, "sfx": 0.65
''')

rep('''	for key in ["coins", "best", "diff", "bgm", "sfx"]:
''','''	for key in ["coins", "best", "best_endless", "endless_wave", "diff", "bgm", "sfx"]:
''')

rep('''func start_run(level_index: int = -1, one_level: bool = false) -> void:
''','''func start_run(level_index: int = -1, one_level: bool = false) -> void:
	endless_mode = false
''')

rep('''	setup_level(selected_level)
	state = S.PLAYING
''','''	setup_level(selected_level)
	state = S.PLAYING

func start_endless() -> void:
	start_run(0, false)
	endless_mode = true
	lobby_mode = "endless"
	endless_rotation = 0
	next_boss = ENDLESS_BOSS_GAP
	cur_wave = 0
	announce("无尽轮回 · 活下去")
	play_sfx("level")
''')

# 大厅模式按钮
rep('''			if START_RECT.has_point(pos):
				start_run(selected_level, true)
			elif BTN_LEVELS.has_point(pos):
				state = S.LEVELS
				_build_level_grid()
''','''			if START_RECT.has_point(pos):
				if lobby_mode == "endless":
					start_endless()
				else:
					start_run(selected_level, true)
			elif MODE_RECT.has_point(pos):
				lobby_mode = "endless" if lobby_mode == "campaign" else "campaign"
				toast_text = "模式：" + ("无尽轮回" if lobby_mode == "endless" else "战役")
				toast_t = 1.3
			elif BTN_LEVELS.has_point(pos):
				lobby_mode = "campaign"
				state = S.LEVELS
				_build_level_grid()
''')

# 暂停/结算返回
rep('''			elif PAUSE_LOBBY.has_point(pos):
				bank_run(false)
				state = S.TITLE
''','''			elif PAUSE_LOBBY.has_point(pos):
				bank_run(false)
				endless_mode = false
				state = S.TITLE
''')
rep('''			if OVER_RESTART.has_point(pos):
				start_run(selected_level, single_level)
			elif OVER_LOBBY.has_point(pos):
				bank_run(false)
				state = S.TITLE
''','''			if OVER_RESTART.has_point(pos):
				if endless_mode:
					start_endless()
				else:
					start_run(selected_level, single_level)
			elif OVER_LOBBY.has_point(pos):
				bank_run(false)
				endless_mode = false
				state = S.TITLE
''')

# 键盘空格
rep('''		KEY_SPACE:
			if state == S.TITLE or state == S.OVER:
				start_run(selected_level, true)
			elif state == S.PLAYING:
				try_dash()
''','''		KEY_SPACE:
			if state == S.TITLE:
				if lobby_mode == "endless":
					start_endless()
				else:
					start_run(selected_level, true)
			elif state == S.OVER:
				if endless_mode:
					start_endless()
				else:
					start_run(selected_level, true)
			elif state == S.PLAYING:
				try_dash()
''')

# 无尽波次
rep('''func _update_wave() -> void:
	if single_level:
''','''func _update_endless_wave() -> void:
	var rot := int(elapsed / ENDLESS_ROTATE)
	if rot != endless_rotation:
		endless_rotation = rot
		var next_idx := (level_idx + 3 + rot) % LevelsData.LIST.size()
		setup_level(next_idx)
		enemies.clear(); arrows.clear(); orbs.clear(); gems.clear(); strikes.clear(); pickups.clear()
		boss = null
		p.pos = _safe_position(p.pos, 16.0)
		p.vel = Vector2.ZERO
		invuln = maxf(invuln, 1.0)
		wave_affix = ""
		next_boss = elapsed + ENDLESS_BOSS_GAP
		if state == S.PLAYING:
			open_shop()
		return
	var gw := 1 + int(elapsed / WAVE_TIME)
	if gw == cur_wave:
		return
	cur_wave = gw
	wave_in_level = ((gw - 1) % LEVEL_WAVES) + 1
	announce("第 %d 波" % gw)
	if gw % 5 == 0:
		spawn_elite(true)
		_spawn_heart_pickup()
	if gw % 3 == 0:
		var affs := ["frenzy", "split", "shield", "toxic", "treasure"]
		wave_affix = affs[rng.randi_range(0, affs.size() - 1)]
		announce("词缀 · " + _affix_name(wave_affix))
		play_sfx("level")
		if wave_affix == "toxic":
			for i in range(2):
				zones.append({
					"kind": "poison",
					"pos": Vector2(rng.randf_range(180, W - 180), rng.randf_range(TOP + 90, BOTTOM - 60)),
					"r": rng.randf_range(70, 100), "t": rng.randf_range(0, 6)
				})
	if gw % 2 == 0:
		if state == S.PLAYING:
			open_shop()

func _update_wave() -> void:
	if endless_mode:
		_update_endless_wave()
		return
	if single_level:
''')

# 出生点公告与 boss 间隔
rep('''	level_banner = 2.4
	announce("第 %d 关 · %s" % [level_idx + 1, str(level_data.n)])
''','''	level_banner = 2.4
	if endless_mode:
		announce("轮回场地 · %s" % str(level_data.n))
	else:
		announce("第 %d 关 · %s" % [level_idx + 1, str(level_data.n)])
''')

rep('''	if boss == null and elapsed >= next_boss:
		spawn_boss()
		next_boss = INF if level_idx == LevelsData.LIST.size() - 1 else float(int(elapsed / LEVEL_TIME) + 1) * LEVEL_TIME + 90.0
''','''	if boss == null and elapsed >= next_boss:
		spawn_boss()
		if endless_mode:
			next_boss = elapsed + ENDLESS_BOSS_GAP
		else:
			next_boss = INF if level_idx == LevelsData.LIST.size() - 1 else float(int(elapsed / LEVEL_TIME) + 1) * LEVEL_TIME + 90.0
''')

# BOSS 在无尽模式按时间升级
rep('''	var bl := level_idx + 1
	var hp := 360.0 * (1.0 + 0.65 * float(bl - 1)) * (1.0 + maxf(0.0, float(bl) - 1.0) * 0.1) * _diff_hp()
''','''	var bl := level_idx + 1
	if endless_mode:
		bl = maxi(1, 1 + int(elapsed / ENDLESS_BOSS_GAP))
	var hp := 360.0 * (1.0 + 0.65 * float(bl - 1)) * (1.0 + maxf(0.0, float(bl) - 1.0) * 0.1) * _diff_hp()
	if endless_mode:
		hp *= 1.0 + 0.08 * float(endless_rotation)
''')

# 分数与结算
rep('''	score = kills * 10 + level * 50 + int(elapsed) + best_combo * 5
''','''	score = kills * 10 + level * 50 + int(elapsed) + best_combo * 5 + (cur_wave * 100 if endless_mode else 0)
''',3)
rep('''	if not rewarded:
		rewarded = true
		bank_run(true)
		if score > int(meta.best):
			meta.best = score
		_save_meta()
''','''	if not rewarded:
		rewarded = true
		bank_run(true)
		if score > int(meta.best):
			meta.best = score
		if endless_mode:
			if score > int(meta.get("best_endless", 0)):
				meta.best_endless = score
			meta.endless_wave = maxi(int(meta.get("endless_wave", 0)), cur_wave)
		_save_meta()
''')

# 大厅模式按钮与开始文案
rep('''	_card_bg(START_RECT, Color("#ff7aa6"), true)
	_outline_text("开始第 %d 关" % (selected_level + 1), START_RECT.get_center().x, START_RECT.position.y + 52, 30, Color("#ffffff"))
	tc_at("第 %d 关 · %s" % [selected_level + 1, str(LevelsData.LIST[selected_level].n)], START_RECT.get_center().x, START_RECT.position.y + 80, 16, Color("#ffd6e8"))
''','''	_card_bg(START_RECT, Color("#ff7aa6"), true)
	if lobby_mode == "endless":
		_outline_text("开始无尽轮回", START_RECT.get_center().x, START_RECT.position.y + 52, 30, Color("#ffffff"))
		tc_at("无限波次 · 120秒换场 · 死亡结算", START_RECT.get_center().x, START_RECT.position.y + 80, 16, Color("#ffd6e8"))
	else:
		_outline_text("开始第 %d 关" % (selected_level + 1), START_RECT.get_center().x, START_RECT.position.y + 52, 30, Color("#ffffff"))
		tc_at("第 %d 关 · %s" % [selected_level + 1, str(LevelsData.LIST[selected_level].n)], START_RECT.get_center().x, START_RECT.position.y + 80, 16, Color("#ffd6e8"))
	_card_bg(MODE_RECT, Color("#ffd166"), true)
	tc_at("模式：" + ("无尽轮回" if lobby_mode == "endless" else "战役"), MODE_RECT.get_center().x, MODE_RECT.position.y + 23, 19, Color("#fff4d0"))
	tc_at("点击切换 · 无尽最佳 %d 波" % int(meta.get("endless_wave", 0)), MODE_RECT.get_center().x, MODE_RECT.position.y + 43, 12, Color("#c9b8ff"))
''')

# HUD 无尽波次
rep('''	var lvl_name := str(level_data.get("n", ""))
	if elapsed >= LEVEL_TIME * LevelsData.LIST.size(): lvl_name = "最终决战 · 击杀首领"
	draw_string(font, Vector2(W * 0.5 - 240, 78), "第 %d 关 · %s · 第 %d/%d 波" % [level_idx + 1, lvl_name, wave_in_level, LEVEL_WAVES], HORIZONTAL_ALIGNMENT_CENTER, 480, 17, Color("#b8c8ff"))
''','''	var lvl_name := str(level_data.get("n", ""))
	if endless_mode:
		var until_rot := int(ceil(ENDLESS_ROTATE - fmod(elapsed, ENDLESS_ROTATE)))
		draw_string(font, Vector2(W * 0.5 - 260, 78), "无尽轮回 · 第 %d 波 · %s · 换场 %ds" % [cur_wave, lvl_name, until_rot], HORIZONTAL_ALIGNMENT_CENTER, 520, 17, Color("#b8c8ff"))
	else:
		if elapsed >= LEVEL_TIME * LevelsData.LIST.size(): lvl_name = "最终决战 · 击杀首领"
		draw_string(font, Vector2(W * 0.5 - 240, 78), "第 %d 关 · %s · 第 %d/%d 波" % [level_idx + 1, lvl_name, wave_in_level, LEVEL_WAVES], HORIZONTAL_ALIGNMENT_CENTER, 480, 17, Color("#b8c8ff"))
''')

# 结算文案
rep('''	var end_title := "二十关通关" if victory else "旅途暂歇"
	if single_level:
''','''	var end_title := "二十关通关" if victory else "旅途暂歇"
	if endless_mode:
		end_title = "无尽轮回 · 第 %d 波" % cur_wave
	if single_level:
''')

# demo
rep('''			"aim":
				start_run()
				_handle_press(Vector2(1000, 500), 1)
				_update_aim(Vector2(1080, 470))
				charge = 0.68
''','''			"aim":
				start_run()
				_handle_press(Vector2(1000, 500), 1)
				_update_aim(Vector2(1080, 470))
				charge = 0.68
			"endless":
				start_endless()
				elapsed = 145.0
				cur_wave = 8
				wave_in_level = 2
''')

io.open(P,'w',encoding='utf-8').write(s)
print('PATCH5 OK lines=%d'%s.count('\n'))
