extends Node2D
## 弓箭手大作战 · Godot v2
## 横屏 1280x720 / 数据驱动内容 / 局内技能商店 / 20 关 20 武器 20 皮肤 20 特效
## 自动瞄准 + 移动走位 + 冲刺 + 词缀/事件/精英/连击

const SkillsData = preload("res://data/skills.gd")
const WeaponsData = preload("res://data/weapons.gd")
const LevelsData = preload("res://data/levels.gd")
const SkinsData = preload("res://data/skins.gd")
const EffectsData = preload("res://data/effects.gd")
const ClassesData = preload("res://data/classes.gd")
const UltimatesData = preload("res://data/ultimates.gd")

const W := 1280.0
const H := 720.0
const TOP := 96.0
const BOTTOM := H - 26.0
const LEVEL_TIME := 120.0
const WAVE_TIME := 20.0
const LEVEL_WAVES := 6

enum S { TITLE, WEAPONS, SKINS, EFFECTS, PLAYING, LEVELUP, SHOP, PAUSED, OVER, CLASSES }

const START_RECT := Rect2(80, 250, 400, 96)
const BTN_C := Rect2(80, 380, 150, 60)
const BTN_W := Rect2(242, 380, 150, 60)
const BTN_S := Rect2(404, 380, 150, 60)
const BTN_E := Rect2(566, 380, 150, 60)
const DIFF_RECT := Rect2(80, 454, 300, 48)
const BACK_RECT := Rect2(W - 168, 24, 140, 52)
const PAUSE_RECT := Rect2(W - 68, 22, 46, 46)
const SHOP_BTN := Rect2(W - 122, 22, 46, 46)
const DASH_RECT := Rect2(W - 116, H - 134, 86, 86)
const PAUSE_RESUME := Rect2(490, 360, 300, 70)
const PAUSE_LOBBY := Rect2(490, 448, 300, 70)
const OVER_RESTART := Rect2(390, 520, 240, 72)
const OVER_LOBBY := Rect2(650, 520, 240, 72)

var state: int = S.TITLE
var font: Font
var rng := RandomNumberGenerator.new()

var p := {}
var enemies: Array = []
var arrows: Array = []
var orbs: Array = []
var gems: Array = []
var pickups: Array = []
var particles: Array = []
var floaters: Array = []
var fxs: Array = []
var zaps: Array = []
var strikes: Array = []
var wolves: Array = []
var slashes: Array = []
var vortices: Array = []
var dragons: Array = []
var clones: Array = []
var obstacles: Array = []
var zones: Array = []
var weather_parts: Array = []

var level := 1
var xp := 0.0
var xp_need := 7
var kills := 0
var elapsed := 0.0
var fire_cd := 0.0
var spawn_cd := 0.5
var next_boss := 75.0
var boss = null
var boss_max_hp := 0.0
var boss_name := ""
var boss_count := 0
var invuln := 0.0
var regen_acc := 0.0
var env_acc := 0.0
var shake_t := 0.0
var shake_str := 0.0
var shake_off := Vector2.ZERO

var gold := 0
var combo := 0
var combo_t := 0.0
var best_combo := 0
var gold_mult := 1.0
var bloodmoon_t := 0.0
var meteor_t := 0.0
var meteor_cd := 0.0

var taken := {}
var owned_ults: Array = []
var ult_cd := {}
var freeze_t := 0.0
var pending_levels := 0
var cards: Array = []
var card_rects: Array = []
var class_rects: Array = []
var shop_offers: Array = []
var shop_rects: Array = []
var shop_auto_t := 0.0
var enemy_id := 0

var stars: Array = []
var petals: Array = []
var cur_wave := 0
var wave_in_level := 1
var level_idx := -1
var level_data := {}
var level_banner := 0.0
var darkness := false
var wind := Vector2.ZERO
var storm_cd := 2.0
var wave_affix := ""
var affix_wave := 0
var elite_wave := 0
var next_event := 34.0

var stick_active := false
var stick_id := -1
var stick_base := Vector2.ZERO
var stick_vec := Vector2.ZERO
var stick_cur := Vector2.ZERO
var last_aim := -PI * 0.5
var dash_dir := Vector2.RIGHT
var trail_acc := 0.0

var test_mode := false
var test_limit := 100.0
var diff_override := -1
var test_time := 0.0
var test_log := 0.0
var auto_choose := 0.0
var auto_mv := Vector2.ZERO
var over_timer := 0.0
var rewarded := false
var last_reward := 0
var score := 0

var banner_text := ""
var banner_t := 0.0
var toast_text := ""
var toast_t := 0.0

var meta := {
	"coins": 200,
	"weapon": "shortbow",
	"skin": "ranger",
	"cls": "ranger",
	"diff": 1,
	"fx_hit": "spark",
	"fx_kill": "burst",
	"fx_level": "pillar",
	"fx_trail": "rainbow",
	"uw": ["shortbow", "longbow", "repeater"],
	"us": ["ranger", "shadow"],
	"uf": ["spark", "burst", "pillar", "rainbow"],
	"best": 0
}
var current_weapon: Dictionary = {}
var current_skin: Dictionary = {}
var current_class: Dictionary = {}
var fx_hit_data: Dictionary = {}
var fx_kill_data: Dictionary = {}
var fx_level_data: Dictionary = {}
var fx_trail_data: Dictionary = {}
var arrow_speed := 820.0
var arrow_life := 1.15
var arrow_spread := 0.10
var weapon_color := Color("#d9a066")
var grid_rects: Array = []
var grid_ids: Array = []
var sfx_bank := {}
var sfx_players: Array = []
var sfx_i := 0

func _ready() -> void:
	rng.randomize()
	if ResourceLoader.exists("res://font.ttf"):
		font = load("res://font.ttf") as Font
	else:
		var sf := SystemFont.new()
		sf.font_names = PackedStringArray(["Noto Sans CJK SC", "Microsoft YaHei", "PingFang SC", "sans-serif"])
		font = sf
	_load_meta()
	_apply_meta_visuals()
	_init_audio()
	for i in range(110):
		stars.append({
			"pos": Vector2(rng.randf_range(0, W), rng.randf_range(0, H)),
			"r": rng.randf_range(0.6, 1.9),
			"a": rng.randf_range(0.12, 0.5),
			"spd": rng.randf_range(2.0, 12.0)
		})
	for i in range(26):
		petals.append({
			"pos": Vector2(rng.randf_range(0, W), rng.randf_range(0, H)),
			"spd": rng.randf_range(8.0, 26.0),
			"rot": rng.randf_range(0, TAU),
			"r": rng.randf_range(3.0, 7.0),
			"a": rng.randf_range(0.10, 0.35)
		})
	_init_player()
	state = S.TITLE
	var args := OS.get_cmdline_user_args()
	for a in args:
		if str(a).begins_with("--class="):
			meta.cls = str(a).substr(8)
			var cc = ClassesData.find(str(meta.cls))
			meta.weapon = str(cc.weapon)
			if not str(meta.weapon) in meta.uw:
				meta.uw.append(str(meta.weapon))
		if str(a).begins_with("--diff="):
			meta.diff = int(str(a).substr(7))
	_apply_meta_visuals()
	if "--test" in args:
		test_mode = true
		print("CONTENT skills=%d weapons=%d levels=%d skins=%d effects=%d classes=%d ultimates=%d" % [
			SkillsData.LIST.size(), WeaponsData.LIST.size(), LevelsData.LIST.size(),
			SkinsData.LIST.size(), EffectsData.LIST.size(), ClassesData.LIST.size(), UltimatesData.LIST.size()
		])
		start_run()
		if "--fast" in args:
			next_boss = 8.0
		if "--long" in args:
			test_limit = 200.0
	var demo := ""
	for a in args:
		if str(a).begins_with("--demo="):
			demo = str(a).substr(7)
	if demo != "":
		match demo:
			"grid":
				state = S.WEAPONS
				_build_grid()
			"class":
				state = S.CLASSES
				_build_class_grid()
			"skin":
				state = S.SKINS
				_build_grid()
			"fx":
				state = S.EFFECTS
				_build_grid()
			"shop":
				start_run()
				open_shop()
			"levelup":
				start_run()
				open_levelup()
			"pause":
				start_run()
				state = S.PAUSED
			"over":
				start_run()
				elapsed = 95.0
				kills = 88
				level = 9
				best_combo = 64
				score = 2310
				gold = 120
				game_over()
			"ult":
				start_run()
				for u in UltimatesData.LIST:
					owned_ults.append(str(u.id))
					ult_cd[str(u.id)] = 0.6

# ============================================================ 存档
func _load_meta() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://settings.cfg") != OK:
		_save_meta()
		return
	meta.coins = int(cfg.get_value("meta", "coins", 200))
	meta.weapon = str(cfg.get_value("meta", "weapon", "shortbow"))
	meta.skin = str(cfg.get_value("meta", "skin", "ranger"))
	meta.cls = str(cfg.get_value("meta", "cls", "ranger"))
	meta.diff = int(cfg.get_value("meta", "diff", 1))
	meta.fx_hit = str(cfg.get_value("meta", "fx_hit", "spark"))
	meta.fx_kill = str(cfg.get_value("meta", "fx_kill", "burst"))
	meta.fx_level = str(cfg.get_value("meta", "fx_level", "pillar"))
	meta.fx_trail = str(cfg.get_value("meta", "fx_trail", "rainbow"))
	meta.best = int(cfg.get_value("meta", "best", 0))
	meta.uw = Array(cfg.get_value("meta", "uw", PackedStringArray(["shortbow", "longbow", "repeater"])))
	meta.us = Array(cfg.get_value("meta", "us", PackedStringArray(["ranger", "shadow"])))
	meta.uf = Array(cfg.get_value("meta", "uf", PackedStringArray(["spark", "burst", "pillar", "rainbow"])))

func _save_meta() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "coins", meta.coins)
	cfg.set_value("meta", "weapon", meta.weapon)
	cfg.set_value("meta", "skin", meta.skin)
	cfg.set_value("meta", "cls", meta.cls)
	cfg.set_value("meta", "diff", meta.diff)
	cfg.set_value("meta", "fx_hit", meta.fx_hit)
	cfg.set_value("meta", "fx_kill", meta.fx_kill)
	cfg.set_value("meta", "fx_level", meta.fx_level)
	cfg.set_value("meta", "fx_trail", meta.fx_trail)
	cfg.set_value("meta", "best", meta.best)
	cfg.set_value("meta", "uw", PackedStringArray(meta.uw))
	cfg.set_value("meta", "us", PackedStringArray(meta.us))
	cfg.set_value("meta", "uf", PackedStringArray(meta.uf))
	cfg.save("user://settings.cfg")

func _apply_meta_visuals() -> void:
	current_weapon = WeaponsData.find(str(meta.weapon))
	current_skin = SkinsData.find(str(meta.skin))
	current_class = ClassesData.find(str(meta.cls))
	meta.cls = str(current_class.id)
	if not current_class.is_empty() and not WeaponsData.allowed(str(meta.cls), str(meta.weapon)):
		meta.weapon = str(current_class.weapon)
		current_weapon = WeaponsData.find(str(meta.weapon))
		if not str(meta.weapon) in meta.uw:
			meta.uw.append(str(meta.weapon))
	fx_hit_data = EffectsData.find(str(meta.fx_hit))
	fx_kill_data = EffectsData.find(str(meta.fx_kill))
	fx_level_data = EffectsData.find(str(meta.fx_level))
	fx_trail_data = EffectsData.find(str(meta.fx_trail))
	if fx_hit_data.cat != "hit":
		fx_hit_data = EffectsData.by_cat("hit")[0]
	if fx_kill_data.cat != "kill":
		fx_kill_data = EffectsData.by_cat("kill")[0]
	if fx_level_data.cat != "level":
		fx_level_data = EffectsData.by_cat("level")[0]
	if fx_trail_data.cat != "trail":
		fx_trail_data = EffectsData.by_cat("trail")[0]

# ============================================================ 开局
func _init_player() -> void:
	p = {
		"pos": Vector2(W * 0.5, H * 0.58),
		"vel": Vector2.ZERO,
		"hp": 150.0, "max_hp": 150.0, "speed": 250.0,
		"dmg": 10.0, "fire_cd": 0.40, "arrows": 1, "pierce": 0, "bounce": 0,
		"crit": 0.05, "crit_mult": 2.0, "regen": 0.0,
		"magnet": 120.0, "armor": 0.25,
		"shield": 0.0, "shield_max": 0.0, "shield_cd": 0.0,
		"thorn": 0.0, "greed": 0.0, "wisdom": 0.0, "lifesteal": 0.0,
		"revive": 0, "explode": 0, "frost": 0, "poison": 0, "chain": 0,
		"dash_cd_max": 3.0, "dash_cd": 0.0, "dash_t": 0.0
	}
	var c: Dictionary = current_class if not current_class.is_empty() else ClassesData.find("ranger")
	p.max_hp = float(c.hp)
	p.hp = p.max_hp
	p.speed = float(c.speed)
	p.dmg = 10.0 * float(c.dmg)
	p.crit = float(c.crit)
	p.armor = float(c.armor)
	var w: Dictionary = current_weapon if not current_weapon.is_empty() else WeaponsData.find("shortbow")
	var kind := str(w.get("kind", "ranged"))
	p.dmg *= float(w.dmg)
	p.fire_cd = float(w.rate)
	weapon_color = Color(str(w.color))
	if kind == "melee":
		p.arrows = 1
		p.pierce = 0
		p.bounce = 0
		arrow_speed = 0.0
		arrow_life = 0.0
		arrow_spread = 0.0
		if str(w.special) == "fast":
			p.crit += 0.10
	else:
		p.arrows = int(w.arrows)
		p.pierce = int(w.pierce)
		p.bounce = int(w.bounce)
		arrow_speed = float(w.speed)
		arrow_life = float(w.life)
		arrow_spread = float(w.spread)
	if str(w.special) == "moon":
		p.crit += 0.15
	if str(w.special) == "thorn":
		p.thorn += 8.0

func start_run() -> void:
	_apply_meta_visuals()
	_init_player()
	enemies.clear(); arrows.clear(); orbs.clear(); gems.clear()
	pickups.clear(); particles.clear(); floaters.clear(); fxs.clear()
	zaps.clear(); strikes.clear(); wolves.clear()
	slashes.clear(); vortices.clear(); dragons.clear(); clones.clear()
	owned_ults.clear(); ult_cd.clear(); freeze_t = 0.0
	cards.clear(); card_rects.clear(); shop_offers.clear(); shop_rects.clear()
	taken.clear()
	level = 1; xp = 0.0; xp_need = 7; kills = 0; score = 0
	if not current_class.is_empty():
		var ss := str(current_class.get("start_skill", ""))
		if ss != "":
			apply_skill(ss)
			taken[ss] = 1
	elapsed = 0.0; fire_cd = 0.0; spawn_cd = 0.5
	next_boss = 90.0; boss = null; boss_max_hp = 0.0; boss_name = ""; boss_count = 0
	invuln = 0.0; regen_acc = 0.0; env_acc = 0.0; pending_levels = 0
	shake_t = 0.0; shake_str = 0.0; shake_off = Vector2.ZERO
	gold = 0; combo = 0; combo_t = 0.0; best_combo = 0
	gold_mult = 1.0; bloodmoon_t = 0.0; meteor_t = 0.0; meteor_cd = 0.0
	cur_wave = 0; wave_in_level = 1; level_idx = -1; wave_affix = ""; affix_wave = 0; elite_wave = 0
	next_event = 34.0; storm_cd = 2.0
	stick_active = false; stick_vec = Vector2.ZERO; dash_dir = Vector2.RIGHT; trail_acc = 0.0
	rewarded = false; last_reward = 0; over_timer = 0.0
	setup_level(0)
	state = S.PLAYING

# ============================================================ 主循环
func _process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	if shake_t > 0.0:
		shake_t -= dt
		shake_off = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * shake_str * (shake_t / 0.3)
	else:
		shake_off = Vector2.ZERO
	if banner_t > 0.0:
		banner_t -= dt
	if toast_t > 0.0:
		toast_t -= dt
	_update_stars(dt)

	if test_mode:
		test_time += dt
		test_log += dt
		if test_log >= 1.0:
			test_log = 0.0
			print("DBG state=%d t=%.1f hp=%d lv=%d gold=%d kills=%d wave=%d lvl=%s en=%d combo=%d boss=%d" % [
				state, elapsed, int(p.hp), level, gold, kills, cur_wave,
				str(level_data.get("n", "?")), enemies.size(), combo, 1 if boss != null else 0
			])
		if state == S.OVER:
			over_timer += dt
		if test_time >= test_limit or over_timer >= 1.5:
			print("TEST_SUMMARY t=%.1f hp=%d lv=%d kills=%d gold=%d best_combo=%d bosses=%d" % [
				elapsed, int(p.hp), level, kills, gold, best_combo, boss_count
			])
			print("TEST_DONE")
			get_tree().quit()

	if state == S.PLAYING:
		if test_mode:
			_auto_move(dt)
		step_game(dt)
	elif state == S.LEVELUP and test_mode:
		auto_choose += dt
		if auto_choose >= 0.12:
			auto_choose = 0.0
			if not cards.is_empty():
				choose_card(rng.randi_range(0, cards.size() - 1))
	elif state == S.SHOP and test_mode:
		shop_auto_t += dt
		if shop_auto_t >= 0.2:
			_test_shop()
	queue_redraw()

func _update_stars(dt: float) -> void:
	for s in stars:
		s.pos.y += s.spd * dt
		if s.pos.y > H:
			s.pos.y = 0.0
			s.pos.x = rng.randf_range(0, W)
	for pt in petals:
		pt.pos.y += float(pt.spd) * dt
		pt.pos.x += sin(elapsed * 0.8 + float(pt.rot)) * 8.0 * dt
		pt.rot = float(pt.rot) + dt * 0.6
		if pt.pos.y > H + 12:
			pt.pos.y = -12.0
			pt.pos.x = rng.randf_range(0, W)

func _test_shop() -> void:
	var bought := 0
	for i in range(shop_offers.size()):
		if bought >= 2:
			break
		var o = shop_offers[i]
		if str(o.get("kind", "skill")) == "ult":
			if not str(o.id) in owned_ults and gold >= int(o.price):
				gold -= int(o.price)
				owned_ults.append(str(o.id))
				ult_cd[str(o.id)] = 0.5
				if str(o.id) == "guardian":
					p.revive += 1
					p.shield_max += 30.0
					p.shield += 30.0
				elif str(o.id) == "bloodmoon":
					p.lifesteal += 0.05
				bought += 1
			continue
		var sk = SkillsData.find(str(o.id))
		if sk.is_empty():
			continue
		if int(taken.get(sk.id, 0)) < int(sk.max) and gold >= int(o.price):
			gold -= int(o.price)
			apply_skill(str(sk.id))
			taken[sk.id] = int(taken.get(sk.id, 0)) + 1
			bought += 1
	shop_auto_t = 0.0
	state = S.PLAYING

# ============================================================ 输入
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_handle_press(event.position, event.index)
		else:
			_handle_release(event.index)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if stick_active and event.index == stick_id:
			_update_stick(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_handle_press(event.position, -1)
			else:
				_handle_release(-1)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		if stick_active and stick_id == -1:
			_update_stick(event.position)
	elif event is InputEventKey:
		if event.pressed and not event.echo:
			_handle_key(event.keycode)

func _handle_key(key: int) -> void:
	match key:
		KEY_P:
			if state == S.PLAYING or state == S.PAUSED:
				toggle_pause()
		KEY_B:
			if state == S.PLAYING:
				open_shop()
		KEY_ESCAPE:
			if state in [S.WEAPONS, S.SKINS, S.EFFECTS, S.CLASSES]:
				state = S.TITLE
			elif state == S.SHOP:
				state = S.PLAYING
			elif state == S.PLAYING:
				toggle_pause()
			elif state == S.PAUSED:
				state = S.PLAYING
			elif state == S.OVER:
				state = S.TITLE
		KEY_SPACE:
			if state == S.TITLE or state == S.OVER:
				start_run()
			elif state == S.PLAYING:
				try_dash()
		KEY_1:
			if state == S.LEVELUP:
				choose_card(0)
		KEY_2:
			if state == S.LEVELUP:
				choose_card(1)
		KEY_3:
			if state == S.LEVELUP:
				choose_card(2)

func _handle_press(pos: Vector2, id: int) -> void:
	match state:
		S.TITLE:
			if START_RECT.has_point(pos):
				start_run()
			elif BTN_C.has_point(pos):
				state = S.CLASSES
				_build_class_grid()
			elif BTN_W.has_point(pos):
				state = S.WEAPONS
				_build_grid()
			elif BTN_S.has_point(pos):
				state = S.SKINS
				_build_grid()
			elif BTN_E.has_point(pos):
				state = S.EFFECTS
				_build_grid()
			elif DIFF_RECT.has_point(pos):
				meta.diff = (int(meta.diff) + 1) % 3
				_save_meta()
				toast_text = "难度：" + _diff_name()
				toast_t = 1.4
		S.CLASSES:
			if BACK_RECT.has_point(pos):
				state = S.TITLE
				return
			for i in range(class_rects.size()):
				if class_rects[i].has_point(pos):
					_class_click(i)
					return
		S.WEAPONS, S.SKINS, S.EFFECTS:
			if BACK_RECT.has_point(pos):
				state = S.TITLE
				return
			for i in range(grid_rects.size()):
				if grid_rects[i].has_point(pos):
					_grid_click(state, i)
					return
		S.PLAYING:
			if PAUSE_RECT.has_point(pos):
				toggle_pause()
				return
			if SHOP_BTN.has_point(pos):
				open_shop()
				return
			if DASH_RECT.has_point(pos):
				try_dash()
				return
			if pos.y < TOP:
				return
			stick_active = true
			stick_id = id
			stick_base = pos
			stick_cur = pos
			stick_vec = Vector2.ZERO
		S.LEVELUP:
			for i in range(card_rects.size()):
				if card_rects[i].has_point(pos):
					choose_card(i)
					return
		S.SHOP:
			for i in range(shop_rects.size()):
				if shop_rects[i].has_point(pos):
					buy_offer(i)
					return
			if Rect2(52, 620, 190, 62).has_point(pos):
				refresh_shop()
				return
			if Rect2(W - 242, 620, 190, 62).has_point(pos):
				state = S.PLAYING
				return
		S.PAUSED:
			if PAUSE_RESUME.has_point(pos):
				state = S.PLAYING
			elif PAUSE_LOBBY.has_point(pos):
				state = S.TITLE
		S.OVER:
			if OVER_RESTART.has_point(pos):
				start_run()
			elif OVER_LOBBY.has_point(pos):
				state = S.TITLE

func _handle_release(id: int) -> void:
	if stick_active and id == stick_id:
		stick_active = false
		stick_vec = Vector2.ZERO
		stick_id = -1

func _update_stick(pos: Vector2) -> void:
	var v := pos - stick_base
	var l := v.length()
	if l > 90.0:
		v = v / l * 90.0
	stick_vec = v / 90.0
	stick_cur = stick_base + v

func toggle_pause() -> void:
	if state == S.PLAYING:
		state = S.PAUSED
		stick_active = false
		stick_vec = Vector2.ZERO
	elif state == S.PAUSED:
		state = S.PLAYING

# ============================================================ 主逻辑
func step_game(dt: float) -> void:
	elapsed += dt
	_update_wave()
	_update_zones(dt)
	_move_player(dt)
	_shoot(dt)
	# 回复 / 护盾 / 冲刺
	if p.regen > 0.0 and p.hp < p.max_hp:
		regen_acc += p.regen * dt
		if regen_acc >= 0.25:
			p.hp = minf(p.max_hp, p.hp + regen_acc)
			regen_acc = 0.0
	if p.shield_max > 0.0 and p.shield < p.shield_max:
		p.shield_cd -= dt
		if p.shield_cd <= 0.0:
			p.shield = minf(p.shield_max, p.shield + 25.0)
			p.shield_cd = 12.0
	if p.dash_cd > 0.0:
		p.dash_cd -= dt
	if invuln > 0.0:
		invuln -= dt
	if combo_t > 0.0:
		combo_t -= dt
		if combo_t <= 0.0:
			combo = 0
	if bloodmoon_t > 0.0:
		bloodmoon_t -= dt
		gold_mult = 2.0
	else:
		gold_mult = 1.0
	_update_enemies(dt)
	_update_arrows(dt)
	_update_slashes(dt)
	_update_orbs(dt)
	_update_gems(dt)
	_update_pickups(dt)
	_update_wolves(dt)
	_update_ultimates(dt)
	_update_particles(dt)
	_update_floaters(dt)
	_update_fx(dt)
	_update_zaps(dt)
	_update_strikes(dt)
	_update_weather(dt)
	_update_events(dt)
	_spawn_logic(dt)
	_check_death()
	score = kills * 10 + level * 50 + int(elapsed) + best_combo * 5

func _move_player(dt: float) -> void:
	var mv := Vector2.ZERO
	if test_mode:
		mv = auto_mv
	else:
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): mv.x -= 1
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): mv.x += 1
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): mv.y -= 1
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): mv.y += 1
		if stick_active: mv += stick_vec
	if mv.length() > 1.0:
		mv = mv.normalized()
	var zf := _zone_speed(p.pos)
	var desired: Vector2 = mv * p.speed * zf
	var on_ice := _zone_at(p.pos, "ice")
	var k := 4.5 if not on_ice else 0.9
	p.vel = p.vel.lerp(desired, clampf(k * dt, 0.0, 1.0))
	if wind != Vector2.ZERO:
		p.vel += wind * 0.35
	if p.dash_t > 0.0:
		p.dash_t -= dt
		p.vel = dash_dir * 1000.0
	p.pos += p.vel * dt
	p.pos.x = clampf(p.pos.x, 26.0, W - 26.0)
	p.pos.y = clampf(p.pos.y, TOP + 14.0, BOTTOM)
	# 障碍推挤
	for o in obstacles:
		var d: float = p.pos.distance_to(o.pos)
		if d < o.r + 16.0:
			var n: Vector2 = (p.pos - o.pos)
			if n.length() < 0.01:
				n = Vector2.RIGHT
			p.pos = o.pos + n.normalized() * (o.r + 16.0)
	# 皮肤拖尾
	if not current_skin.is_empty() and p.vel.length() > 70.0:
		trail_acc += dt
		if trail_acc >= 0.055:
			trail_acc = 0.0
			particles.append({
				"pos": p.pos + Vector2(rng.randf_range(-6, 6), rng.randf_range(-4, 8)),
				"vel": -p.vel * 0.05,
				"life": 0.32, "max_life": 0.32, "r": rng.randf_range(2.0, 4.0),
				"col": Color(str(current_skin.trail))
			})

func try_dash() -> void:
	if state != S.PLAYING or p.dash_cd > 0.0:
		return
	var dir := Vector2.ZERO
	if stick_active and stick_vec.length() > 0.1:
		dir = stick_vec.normalized()
	elif auto_mv.length() > 0.1 and test_mode:
		dir = auto_mv.normalized()
	else:
		dir = Vector2(cos(last_aim), sin(last_aim))
	p.dash_dir = dir
	p.dash_t = 0.17
	p.dash_cd = p.dash_cd_max
	invuln = maxf(invuln, 0.32)
	play_sfx("shoot", 1.6)
	fx_at("hit", "ring", p.pos, "#7ee0c0", "#ffffff", 0.7)

func _shoot(dt: float) -> void:
	fire_cd -= dt
	var melee := str(current_weapon.get("kind", "ranged")) == "melee"
	var wid := str(current_weapon.get("id", ""))
	var spell := wid in ["firestaff", "froststaff", "stormstaff", "voidstaff", "tome", "bonestaff", "beaststaff", "soulbell"]
	var reach := (float(current_weapon.get("range", 100.0)) + 80.0) if melee else 1150.0
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

func _melee_attack() -> void:
	var w: Dictionary = current_weapon
	var aim := last_aim
	var reach := float(w.get("range", 100.0))
	var arc := float(w.get("arc", 1.5))
	var special := str(w.get("special", "none"))
	var knock := float(w.get("knock", 30.0))
	if special == "spin":
		arc = TAU
	var max_hits := 99 if special == "spin" else 8
	var hit_count := 0
	for e in enemies:
		if e.dead:
			continue
		var d: float = p.pos.distance_to(e.pos)
		if d > reach + e.r:
			continue
		var ang: float = (e.pos - p.pos).angle()
		if absf(wrapf(ang - aim, -PI, PI)) > arc * 0.5:
			continue
		var dir: Vector2 = (e.pos - p.pos).normalized()
		var times := 3 if special == "combo" else 1
		for k in range(times):
			var crit: bool = rng.randf() < p.crit
			var dmg: float = p.dmg * (p.crit_mult if crit else 1.0)
			if times > 1:
				dmg *= 0.6
			damage_enemy(e, dmg, crit)
		if special == "burn":
			e.burn_t = 3.0
			e.burn_dps = 6.0 + p.dmg * 0.1
		if special == "poison":
			e.poison_t = 3.0
			e.poison_dps = 4.0 + p.dmg * 0.12
		if special == "chain":
			chain_zap(e.pos, e, 2, p.dmg * 0.45)
		if p.frost > 0:
			e.slow_t = 2.0
		if p.poison > 0:
			e.poison_t = 3.0
			e.poison_dps = 3.0 + p.dmg * 0.1
		if p.explode > 0 or special == "slam":
			explode_at(e.pos, 55.0 + p.explode * 15.0, p.dmg * 0.4)
		e.pos += dir * knock
		hit_count += 1
		if hit_count >= max_hits:
			break
	if special == "slam":
		explode_at(p.pos + Vector2(cos(aim), sin(aim)) * reach * 0.6, 85.0, p.dmg * 0.8)
	slashes.append({ "pos": p.pos, "aim": aim, "arc": arc, "range": reach, "t": 0.0, "dur": 0.28, "color": weapon_color, "special": special })
	shake_t = maxf(shake_t, 0.08)
	shake_str = maxf(shake_str, 2.5)
	play_sfx("slash")

func _update_slashes(dt: float) -> void:
	for i in range(slashes.size() - 1, -1, -1):
		slashes[i].t += dt
		if slashes[i].t >= slashes[i].dur:
			slashes.remove_at(i)

func fire_arrows(target) -> void:
	var aim: float = (target.pos - p.pos).angle()
	last_aim = aim
	var n: int = p.arrows
	var ws: String = str(current_weapon.get("special", "none"))
	var wid: String = str(current_weapon.get("id", "shortbow"))
	var explode_r := 0.0
	if p.explode > 0:
		explode_r = 70.0 + 25.0 * p.explode
	if ws == "explode":
		explode_r = maxf(explode_r, 95.0 if wid == "bomber" else 72.0)
	if ws == "thorn":
		explode_r = maxf(explode_r, 55.0)
	var chain_n: int = p.chain + (2 if ws == "chain" else 0)
	var do_frost: bool = p.frost > 0 or ws == "frost"
	var do_poison: bool = p.poison > 0 or ws == "poison"
	var do_burn: bool = ws == "burn" or wid == "sunbow"
	var spell := wid in ["firestaff", "froststaff", "stormstaff", "voidstaff", "tome", "bonestaff", "beaststaff", "soulbell"]
	for i in range(n):
		var a: float = aim + (float(i) - float(n - 1) * 0.5) * arrow_spread
		var dir := Vector2(cos(a), sin(a))
		var crit: bool = rng.randf() < p.crit
		var dmg: float = p.dmg * (p.crit_mult if crit else 1.0)
		arrows.append({
			"pos": p.pos + dir * 22.0, "prev": p.pos,
			"vel": dir * arrow_speed, "dmg": dmg, "crit": crit,
			"pierce": p.pierce, "bounce": p.bounce,
			"life": arrow_life, "hit": {},
			"color": Color("#ffe08a") if crit else weapon_color,
			"explode_r": explode_r, "frost": do_frost, "poison": do_poison,
			"burn": do_burn, "chain": chain_n, "lifesteal": p.lifesteal,
			"homing": ws == "homing", "boomerang": ws == "boomerang",
			"execute": ws == "voidbow", "spin": 0.0, "reversed": false,
			"spell": spell
		})
	play_sfx("shoot")

func _update_wave() -> void:
	var new_level := int(elapsed / LEVEL_TIME) % LevelsData.LIST.size()
	if new_level != level_idx:
		setup_level(new_level)
		wave_affix = ""
		next_boss = float(int(elapsed / LEVEL_TIME)) * LEVEL_TIME + 90.0
		if state == S.PLAYING:
			open_shop()
	var gw := 1 + int(elapsed / WAVE_TIME)
	if gw == cur_wave:
		return
	cur_wave = gw
	wave_in_level = int(fmod(elapsed, LEVEL_TIME) / WAVE_TIME) + 1
	if wave_in_level != 1:
		announce("第 %d 波" % wave_in_level)
	if wave_in_level % 3 == 0:
		spawn_elite(false)
		_spawn_heart_pickup()
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
	if wave_in_level % 2 == 0:
		if state == S.PLAYING:
			open_shop()

func _affix_name(id: String) -> String:
	match id:
		"frenzy": return "狂暴（敌人加速）"
		"split": return "分裂（死亡分裂）"
		"shield": return "护盾（敌人带盾）"
		"toxic": return "毒雾（场地毒区）"
		"treasure": return "财宝（金币翻倍掉落）"
		"swift": return "迅捷"
		"vamp": return "吸血"
		"giant": return "巨大"
	return id

func setup_level(idx: int) -> void:
	level_idx = idx % LevelsData.LIST.size()
	level_data = LevelsData.LIST[level_idx]
	obstacles.clear()
	zones.clear()
	weather_parts.clear()
	darkness = bool(level_data.get("dark", false))
	wind = Vector2.ZERO
	if str(level_data.weather) == "sand":
		wind = Vector2(-55, 6)
	var lr := RandomNumberGenerator.new()
	lr.seed = 9001 + level_idx * 137
	var kind := str(level_data.obs)
	var layout: Array = level_data.get("obs_layout", [])
	if layout.size() > 0:
		for item in layout:
			var pos := Vector2(float(item[0]) * W, TOP + float(item[1]) * (BOTTOM - TOP))
			obstacles.append({ "pos": pos, "r": float(item[2]), "kind": kind })
	else:
		var n := 0
		var rad := 30.0
		match kind:
			"trees": n = 8; rad = 32.0
			"rocks": n = 7; rad = 30.0
			"crystals": n = 6; rad = 26.0
			"pillars": n = 4; rad = 42.0
		for i in range(n):
			var pos := Vector2(lr.randf_range(70, W - 70), lr.randf_range(TOP + 60, BOTTOM - 50))
			if pos.distance_to(Vector2(W * 0.5, H * 0.58)) < 170:
				pos.x = W - pos.x
			obstacles.append({ "pos": pos, "r": rad + lr.randf_range(-4, 6), "kind": kind })
	var zl: Array = level_data.get("zone_layout", [])
	var znames := ["ice", "lava", "poison", "haste", "heal", "void"]
	if zl.size() > 0:
		for item in zl:
			var zk: String = znames[int(item[0]) % znames.size()]
			zones.append({
				"kind": zk,
				"pos": Vector2(float(item[1]) * W, TOP + float(item[2]) * (BOTTOM - TOP)),
				"r": float(item[3]), "t": lr.randf_range(0, 6)
			})
	else:
		for z in level_data.zones:
			var pos := Vector2(lr.randf_range(110, W - 110), lr.randf_range(TOP + 80, BOTTOM - 60))
			zones.append({ "kind": str(z), "pos": pos, "r": lr.randf_range(72, 108), "t": lr.randf_range(0, 6) })
	var wn := str(level_data.weather)
	if wn != "none":
		for i in range(80):
			weather_parts.append({
				"pos": Vector2(lr.randf_range(0, W), lr.randf_range(0, H)),
				"spd": lr.randf_range(60, 180), "len": lr.randf_range(6, 16), "a": lr.randf_range(0.15, 0.5)
			})
	level_banner = 2.4
	announce("第 %d 关 · %s" % [level_idx + 1, str(level_data.n)])
	play_sfx("level")

func _update_zones(dt: float) -> void:
	for z in zones:
		z.t += dt
	var in_lava := false
	var in_poison := false
	for z in zones:
		if p.pos.distance_to(z.pos) < z.r:
			match str(z.kind):
				"lava": in_lava = true
				"poison": in_poison = true
				"heal":
					p.hp = minf(p.max_hp, p.hp + 10.0 * dt)
				"void":
					var pull: Vector2 = z.pos - p.pos
					if pull.length() > 1.0:
						p.vel += pull.normalized() * 120.0 * dt
	if in_lava:
		env_acc += 14.0 * dt
	if in_poison:
		env_acc += 7.0 * dt
	if env_acc >= 1.0:
		var d := floorf(env_acc)
		env_acc -= d
		_dot_damage(d)

func _dot_damage(amount: float) -> void:
	var d: float = amount * (1.0 - p.armor)
	if p.shield > 0.0:
		var s := minf(p.shield, d)
		p.shield -= s
		d -= s
	if d <= 0.0:
		return
	p.hp -= d
	env_acc = 0.0
	if rng.randf() < 0.03:
		floaters.append({ "pos": p.pos + Vector2(0, -30), "text": "-" + str(int(ceil(d))),
			"life": 0.5, "max_life": 0.5, "col": Color("#ff6b81") })

func _zone_at(pos: Vector2, kind: String) -> bool:
	for z in zones:
		if str(z.kind) == kind and pos.distance_to(z.pos) < z.r:
			return true
	return false

func _zone_speed(pos: Vector2) -> float:
	var f := 1.0
	for z in zones:
		if pos.distance_to(z.pos) < z.r:
			match str(z.kind):
				"haste": f *= 1.3
				"poison": f *= 0.82
				"ice": f *= 1.12
	return f

# ============================================================ 刷怪
func _spawn_logic(dt: float) -> void:
	spawn_cd -= dt
	if spawn_cd <= 0.0:
		spawn_cd = clampf(1.6 - elapsed * 0.006, 0.68, 1.6)
		var n := 1
		if cur_wave >= 3: n = 2
		if cur_wave >= 9: n = 3
		if cur_wave >= 12: n = 4
		if str(level_data.mod) == "horde": n += 1
		n = mini(n, 5)
		for i in range(n):
			spawn_enemy(cur_wave)
	if boss == null and elapsed >= next_boss:
		spawn_boss()
		next_boss = float(int(elapsed / LEVEL_TIME) + 1) * LEVEL_TIME + 90.0

func _edge_pos() -> Vector2:
	var side := rng.randi_range(0, 3)
	match side:
		0: return Vector2(-34, rng.randf_range(TOP + 60, BOTTOM - 30))
		1: return Vector2(W + 34, rng.randf_range(TOP + 60, BOTTOM - 30))
		2: return Vector2(rng.randf_range(40, W - 40), TOP - 30)
		_: return Vector2(rng.randf_range(40, W - 40), H + 34)

func spawn_enemy(wave: int) -> void:
	var cap := 42 if wave >= 8 else 32
	if enemies.size() >= cap:
		return
	var late := maxf(0.0, float(wave) - 6.0)
	var wave_f := 1.0 + wave * 0.34 + pow(late, 1.45) * 0.10
	var r := rng.randf()
	var type := "slime"
	var mix := str(level_data.get("mix", "mixed"))
	if mix == "slime":
		type = "slime"
	elif mix == "fast":
		type = "bat"
	elif mix == "mage":
		type = "mage"
	elif wave < 2:
		type = "slime"
	elif wave < 5:
		type = "slime" if r < 0.62 else "bat"
	else:
		type = "slime" if r < 0.42 else ("bat" if r < 0.72 else "mage")
	var hp_m := 1.0
	var spd_m := 1.0
	var gold_m := 1.0
	match str(level_data.mod):
		"armored": hp_m = 1.35
		"swift": spd_m = 1.15
		"spooky": hp_m = 0.9; spd_m = 1.2
		"void": hp_m = 1.1; gold_m = 1.2
		"elite": hp_m = 1.12
	var hp := 16.0 * wave_f * hp_m * _diff_hp()
	var spd := rng.randf_range(58.0, 74.0) * spd_m + late * 1.6
	var dmg := (6.0 + wave * 0.5 + pow(maxf(0.0, float(wave) - 8.0), 1.3) * 0.8) * _diff_dmg()
	var xp_v := 1
	var rad := 15.0
	if type == "bat":
		hp = 11.0 * wave_f * hp_m * _diff_hp()
		spd = rng.randf_range(112.0, 145.0) * spd_m + late * 2.0
		dmg = (4.0 + wave * 0.4 + late * 0.5) * _diff_dmg()
		rad = 12.0
	elif type == "mage":
		hp = 24.0 * wave_f * hp_m * _diff_hp()
		spd = 62.0 * spd_m + late * 1.2
		dmg = (7.0 + wave * 0.6 + late * 0.7) * _diff_dmg()
		xp_v = 2
		rad = 14.0
	var shield := 0.0
	if wave_affix == "shield":
		shield = hp * 0.35
	if wave_affix == "frenzy":
		spd *= 1.35
	enemy_id += 1
	enemies.append({
		"id": enemy_id, "type": type, "pos": _edge_pos(), "hp": hp, "max_hp": hp,
		"speed": spd, "dmg": dmg, "xp": xp_v, "r": rad, "gold_m": gold_m,
		"phase": rng.randf_range(0, TAU), "shot_cd": rng.randf_range(0.9, 1.8),
		"flash": 0.0, "dead": false, "shield": shield, "shield_max": hp * 0.35,
		"slow_t": 0.0, "poison_t": 0.0, "poison_dps": 0.0,
		"burn_t": 0.0, "burn_dps": 0.0, "elite": false, "affix": "", "split": wave_affix == "split"
	})

func spawn_elite(bonus: bool) -> void:
	if enemies.size() >= 30:
		return
	var wave := maxi(cur_wave, 1)
	var affs := ["swift", "split", "vamp", "shield", "giant"]
	var affix: String = affs[rng.randi_range(0, affs.size() - 1)]
	var hp := (70.0 + wave * 26.0) * (1.7 if bonus else 1.0) * _diff_hp()
	var spd := 70.0
	var rad := 26.0
	if affix == "giant":
		hp *= 2.0
		rad = 38.0
		spd = 56.0
	elif affix == "swift":
		spd = 120.0
	enemy_id += 1
	var e := {
		"id": enemy_id, "type": "slime", "pos": _edge_pos(), "hp": hp, "max_hp": hp,
		"speed": spd, "dmg": (10.0 + wave * 0.9) * _diff_dmg(), "xp": 6, "r": rad, "gold_m": 1.0,
		"phase": 0.0, "shot_cd": 1.4, "flash": 0.0, "dead": false,
		"shield": hp * 0.3 if affix == "shield" else 0.0,
		"shield_max": hp * 0.3,
		"slow_t": 0.0, "poison_t": 0.0, "poison_dps": 0.0,
		"burn_t": 0.0, "burn_dps": 0.0, "elite": true, "affix": affix, "split": affix == "split"
	}
	enemies.append(e)
	announce("精英出现 · " + _affix_name(affix))
	play_sfx("level")

func spawn_boss() -> void:
	boss_count += 1
	var bl := boss_count
	var hp := 360.0 * (1.0 + 0.65 * float(bl - 1)) * (1.0 + maxf(0.0, float(bl) - 1.0) * 0.1) * _diff_hp()
	if str(level_data.mod) == "elite":
		hp *= 1.15
	var pos := _edge_pos()
	enemy_id += 1
	boss = {
		"id": enemy_id, "type": "boss", "pos": pos, "hp": hp, "max_hp": hp,
		"speed": 55.0, "dmg": (16.0 + bl * 2.0) * _diff_dmg(), "xp": 15, "r": 46.0, "gold_m": 1.0,
		"phase": 0.0, "shot_cd": 1.8, "flash": 0.0, "dead": false,
		"shield": 0.0, "shield_max": 0.0, "slow_t": 0.0, "poison_t": 0.0,
		"poison_dps": 0.0, "burn_t": 0.0, "burn_dps": 0.0, "elite": true,
		"affix": "", "split": false, "boss_kind": (level_idx + bl) % 4
	}
	enemies.append(boss)
	boss_max_hp = hp
	boss_name = str(level_data.get("boss_name", "精英怪")) + " Lv." + str(bl)
	announce("BOSS · " + boss_name)
	shake_t = 0.35
	shake_str = 8.0
	play_sfx("death")

func _update_enemies(dt: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var e = enemies[i]
		if e.dead:
			continue
		e.flash = maxf(0.0, e.flash - dt)
		if e.slow_t > 0.0:
			e.slow_t -= dt
		if e.poison_t > 0.0:
			e.poison_t -= dt
			e.hp -= e.poison_dps * dt
			if rng.randf() < 0.02:
				particles.append({ "pos": e.pos + Vector2(rng.randf_range(-10, 10), rng.randf_range(-10, 10)),
					"vel": Vector2(0, -20), "life": 0.4, "max_life": 0.4, "r": 3.0, "col": Color("#78d17a") })
		if e.burn_t > 0.0:
			e.burn_t -= dt
			e.hp -= e.burn_dps * dt
		if e.hp <= 0.0:
			kill_enemy(e)
			continue
		if _zone_at(e.pos, "lava"):
			e.hp -= 9.0 * dt
			if e.hp <= 0.0:
				kill_enemy(e)
				continue
		elif _zone_at(e.pos, "poison"):
			e.hp -= 5.0 * dt
			if e.hp <= 0.0:
				kill_enemy(e)
				continue
		var to_p: Vector2 = p.pos - e.pos
		var d := maxf(to_p.length(), 0.001)
		var dir := to_p / d
		var slow_f := 0.0 if freeze_t > 0.0 else (0.55 if e.slow_t > 0.0 else 1.0)
		if e.type == "boss":
			_update_boss(e, dir, d, dt, slow_f)
		elif e.type == "slime":
			e.pos += dir * e.speed * slow_f * dt
		elif e.type == "bat":
			var perp := Vector2(-dir.y, dir.x)
			e.pos += (dir * e.speed * slow_f + perp * sin(elapsed * 6.0 + e.phase) * 90.0) * dt
		elif e.type == "mage":
			if d > 330.0:
				e.pos += dir * e.speed * slow_f * dt
			elif d < 230.0:
				e.pos -= dir * e.speed * slow_f * dt
			else:
				e.pos += Vector2(-dir.y, dir.x) * e.speed * 0.7 * slow_f * dt
			e.shot_cd -= dt
			if e.shot_cd <= 0.0 and d < 620.0 and freeze_t <= 0.0:
				e.shot_cd = 1.9 + rng.randf() * 0.5
				fire_orb(e.pos, (p.pos - e.pos).angle(), 176.0, e.dmg, 8.0)
		# 障碍推挤
		for o in obstacles:
			var od: float = e.pos.distance_to(o.pos)
			if od < o.r + e.r:
				var nv: Vector2 = e.pos - o.pos
				if nv.length() < 0.01:
					nv = Vector2.RIGHT
				e.pos = o.pos + nv.normalized() * (o.r + e.r)
		if e.type != "boss" and (e.pos.x < -160.0 or e.pos.x > W + 160.0 or e.pos.y < -160.0 or e.pos.y > H + 160.0):
			e.dead = true
			continue
		# 接触伤害
		if not e.dead and freeze_t <= 0.0 and invuln <= 0.0 and e.pos.distance_to(p.pos) < e.r + 16.0:
			hurt(e.dmg)
			var push: Vector2 = (e.pos - p.pos)
			if push.length() > 0.01:
				e.pos += push.normalized() * 14.0
			if p.thorn > 0.0:
				damage_enemy(e, p.thorn, false)
	cleanup_dead()

func _update_boss(e, dir: Vector2, d: float, dt: float, slow_f: float) -> void:
	if freeze_t > 0.0:
		return
	e.shot_cd -= dt
	var kind: int = int(e.get("boss_kind", 0))
	if kind == 2:
		# 巨兽冲锋
		if e.shot_cd <= 0.0:
			e.shot_cd = 3.2
			e["charge"] = 0.5
		if float(e.get("charge", 0.0)) > 0.0:
			e["charge"] = float(e.charge) - dt
			e.pos += dir * e.speed * 4.0 * dt
		else:
			e.pos += dir * e.speed * dt
		return
	e.pos += dir * e.speed * slow_f * dt
	if e.shot_cd <= 0.0:
		match kind:
			0:
				e.shot_cd = 2.4
				var base: float = (p.pos - e.pos).angle()
				for k in range(12):
					fire_orb(e.pos, base + float(k) * TAU / 12.0, 152.0, e.dmg * 0.6, 9.0)
			1:
				e.shot_cd = 1.8
				var base2: float = (p.pos - e.pos).angle()
				for k in range(5):
					fire_orb(e.pos, base2 + (float(k) - 2.0) * 0.16, 190.0, e.dmg * 0.55, 8.0)
			3:
				e.shot_cd = 2.2
				var base3: float = e.phase + elapsed
				for k in range(16):
					fire_orb(e.pos, base3 + float(k) * TAU / 16.0, 165.0, e.dmg * 0.5, 8.0)
		shake_t = 0.1
		shake_str = 3.0

func nearest_enemy(pos: Vector2, max_dist: float, except) -> Variant:
	var best = null
	var bd := max_dist * max_dist
	for e in enemies:
		if e.dead or e == except:
			continue
		var dd: float = pos.distance_squared_to(e.pos)
		if dd < bd:
			bd = dd
			best = e
	return best

func damage_enemy(e, dmg: float, crit: bool) -> void:
	if e.dead:
		return
	var d := dmg
	if e.shield > 0.0:
		var s := minf(e.shield, d)
		e.shield -= s
		d -= s
	if d <= 0.0:
		e.flash = 0.06
		return
	e.hp -= d
	e.flash = 0.08
	floaters.append({ "pos": e.pos + Vector2(0, -24), "text": str(int(round(d))),
		"life": 0.55, "max_life": 0.55, "col": Color("#ffd166") if crit else Color("#ffffff") })
	fx_at("hit", str(fx_hit_data.style), e.pos, str(fx_hit_data.c1), str(fx_hit_data.c2), 0.7)
	play_sfx("hit", rng.randf_range(0.9, 1.1))
	if p.lifesteal > 0.0 and p.hp < p.max_hp:
		p.hp = minf(p.max_hp, p.hp + d * p.lifesteal)
	if e.hp <= 0.0:
		kill_enemy(e)

func kill_enemy(e) -> void:
	if e.dead:
		return
	e.dead = true
	kills += 1
	combo += 1
	combo_t = 2.2
	best_combo = maxi(best_combo, combo)
	var base := 1
	match str(e.type):
		"mage": base = 2
		"boss": base = 25
		"bat": base = 1
	if bool(e.get("elite", false)):
		base += 7
	if wave_affix == "treasure":
		base += 2
	var g: float = float(base) * gold_mult * (1.0 + float(mini(combo, 50)) * 0.02) * (1.0 + p.greed) * _diff_gold()
	gold += int(ceil(g))
	if str(e.type) == "boss":
		if boss == e:
			boss = null
		shake_t = 0.4
		shake_str = 12.0
		for i in range(8):
			drop_gem(e.pos + Vector2(rng.randf_range(-60, 60), rng.randf_range(-60, 60)), 3)
		play_sfx("death")
		fx_at("kill", str(fx_kill_data.style), e.pos, str(fx_kill_data.c1), str(fx_kill_data.c2), 2.2)
	elif bool(e.get("elite", false)):
		shake_t = 0.2
		shake_str = 6.0
		for i in range(3):
			drop_gem(e.pos + Vector2(rng.randf_range(-30, 30), rng.randf_range(-30, 30)), 2)
		fx_at("kill", str(fx_kill_data.style), e.pos, str(fx_kill_data.c1), str(fx_kill_data.c2), 1.5)
	else:
		drop_gem(e.pos, int(e.xp))
		fx_at("kill", str(fx_kill_data.style), e.pos, str(fx_kill_data.c1), str(fx_kill_data.c2), 0.8)
	# 分裂词缀
	if bool(e.get("split", false)) and str(e.type) != "boss":
		for i in range(2):
			enemy_id += 1
			var hp2: float = maxf(6.0, float(e.max_hp) * 0.28)
			enemies.append({
				"id": enemy_id, "type": "slime", "pos": e.pos + Vector2(rng.randf_range(-18, 18), rng.randf_range(-18, 18)),
				"hp": hp2, "max_hp": hp2, "speed": float(e.speed) * 1.15, "dmg": float(e.dmg) * 0.5,
				"xp": 1, "r": float(e.r) * 0.7, "gold_m": 1.0, "phase": 0.0, "shot_cd": 1.0,
				"flash": 0.0, "dead": false, "shield": 0.0, "shield_max": 0.0,
				"slow_t": 0.0, "poison_t": 0.0, "poison_dps": 0.0, "burn_t": 0.0, "burn_dps": 0.0,
				"elite": false, "affix": "", "split": false
			})
	# 精英吸血词缀 -> 没死时回血，这里给附近敌人回一点，聊胜于无
	if str(e.get("affix", "")) == "vamp":
		p.hp = maxf(1.0, p.hp - 6.0)
	play_sfx("kill")

func cleanup_dead() -> void:
	var alive: Array = []
	for e in enemies:
		if not e.dead:
			alive.append(e)
	enemies = alive

# ============================================================ 箭矢
func _update_arrows(dt: float) -> void:
	for i in range(arrows.size() - 1, -1, -1):
		var a = arrows[i]
		a.prev = a.pos
		if bool(a.homing):
			var t = nearest_enemy(a.pos, 420.0, null)
			if t != null:
				var want: Vector2 = (t.pos - a.pos).normalized()
				var cur: Vector2 = a.vel.normalized()
				var ang := cur.angle_to(want)
				var na := cur.rotated(clampf(ang, -5.0 * dt, 5.0 * dt))
				a.vel = na * a.vel.length()
		if bool(a.boomerang):
			a.spin += dt * 14.0
			if not bool(a.reversed) and a.life < float(arrow_life) - 0.35:
				a.reversed = true
				a.vel = -a.vel * 0.85
				a.hit.clear()
		a.pos += a.vel * dt
		a.life -= dt
		if a.life <= 0.0 or a.pos.x < -60.0 or a.pos.x > W + 60.0 or a.pos.y < -60.0 or a.pos.y > H + 60.0:
			arrows.remove_at(i)
			continue
		var removed := false
		for o in obstacles:
			if seg_circle(a.prev, a.pos, o.pos, o.r):
				removed = true
				break
		if removed:
			arrows.remove_at(i)
			continue
		for j in range(enemies.size()):
			var e = enemies[j]
			if e.dead or a.hit.has(e.id):
				continue
			if seg_circle(a.prev, a.pos, e.pos, e.r + 5.0):
				a.hit[e.id] = true
				var dmg: float = a.dmg
				damage_enemy(e, dmg, bool(a.crit))
				if bool(a.execute) and not e.dead and str(e.type) != "boss" and e.hp / e.max_hp < 0.15:
					kill_enemy(e)
				if float(a.explode_r) > 0.0:
					explode_at(a.pos, float(a.explode_r), dmg * 0.6)
				if bool(a.frost):
					e.slow_t = 2.0
				if bool(a.poison):
					e.poison_t = 3.0
					e.poison_dps = 3.0 + dmg * 0.12
				if bool(a.burn):
					e.burn_t = 3.0
					e.burn_dps = 4.0 + dmg * 0.1
				if int(a.chain) > 0:
					chain_zap(a.pos, e, int(a.chain), dmg * 0.55)
				if int(a.pierce) > 0:
					a.pierce -= 1
				elif int(a.bounce) > 0:
					var nx = nearest_enemy(a.pos, 280.0, e)
					if nx != null:
						a.bounce -= 1
						a.vel = (nx.pos - a.pos).normalized() * a.vel.length()
						a.life = maxf(a.life, 0.7)
					else:
						removed = true
				elif bool(a.boomerang):
					pass
				else:
					removed = true
				break
		if removed:
			arrows.remove_at(i)
	cleanup_dead()

func seg_circle(a: Vector2, b: Vector2, c: Vector2, r: float) -> bool:
	var ab := b - a
	var l2 := ab.length_squared()
	var t := 0.0
	if l2 > 0.0001:
		t = clampf((c - a).dot(ab) / l2, 0.0, 1.0)
	var q := a + ab * t
	return q.distance_squared_to(c) <= r * r

func explode_at(pos: Vector2, radius: float, dmg: float) -> void:
	fx_at("hit", "ring", pos, "#ff8a3a", "#ffd166", radius / 90.0)
	for e in enemies:
		if e.dead:
			continue
		if pos.distance_to(e.pos) < radius + e.r:
			damage_enemy(e, dmg, false)
	shake_t = maxf(shake_t, 0.08)
	shake_str = maxf(shake_str, 2.0)

func chain_zap(from: Vector2, hit_e, count: int, dmg: float) -> void:
	var used := { hit_e.id: true }
	var cur: Vector2 = hit_e.pos
	for i in range(count):
		var best = null
		var bd := 240.0 * 240.0
		for e in enemies:
			if e.dead or used.has(e.id):
				continue
			var dd: float = cur.distance_squared_to(e.pos)
			if dd < bd:
				bd = dd
				best = e
		if best == null:
			break
		used[best.id] = true
		zaps.append({ "a": cur, "b": best.pos, "t": 0.18, "max": 0.18 })
		damage_enemy(best, dmg, false)
		cur = best.pos

func _update_zaps(dt: float) -> void:
	for i in range(zaps.size() - 1, -1, -1):
		zaps[i].t -= dt
		if zaps[i].t <= 0.0:
			zaps.remove_at(i)

# ============================================================ 弹幕
func fire_orb(pos: Vector2, angle: float, speed: float, dmg: float, rad: float) -> void:
	orbs.append({ "pos": pos, "vel": Vector2(cos(angle), sin(angle)) * speed,
		"dmg": dmg, "life": 4.0, "r": rad })
	play_sfx("orb", 0.8)

func _update_orbs(dt: float) -> void:
	for i in range(orbs.size() - 1, -1, -1):
		var o = orbs[i]
		o.pos += o.vel * dt
		o.life -= dt
		if o.life <= 0.0 or o.pos.x < -60.0 or o.pos.x > W + 60.0 or o.pos.y < -60.0 or o.pos.y > H + 60.0:
			orbs.remove_at(i)
			continue
		var blocked := false
		for ob in obstacles:
			if o.pos.distance_to(ob.pos) < ob.r:
				blocked = true
				break
		if blocked:
			orbs.remove_at(i)
			continue
		if invuln <= 0.0 and o.pos.distance_to(p.pos) < 22.0 + float(o.r) * 0.5:
			hurt(o.dmg)
			orbs.remove_at(i)

# ============================================================ 掉落
func drop_gem(pos: Vector2, value: int) -> void:
	gems.append({ "pos": pos, "value": value, "vel": Vector2(rng.randf_range(-30, 30), rng.randf_range(-30, 30)),
		"t": 0.0 })

func _update_gems(dt: float) -> void:
	for i in range(gems.size() - 1, -1, -1):
		var g = gems[i]
		g.t += dt
		g.vel *= 0.92
		g.pos += g.vel * dt
		var to_p: Vector2 = p.pos - g.pos
		var d := maxf(to_p.length(), 0.001)
		if d < p.magnet:
			var spd := clampf(700.0 - d * 2.0, 180.0, 900.0)
			g.pos += (to_p / d) * spd * dt
		if d < 30.0:
			gain_xp(int(g.value))
			gems.remove_at(i)

func _spawn_heart_pickup() -> void:
	var pos: Vector2 = p.pos + Vector2(rng.randf_range(-130, 130), rng.randf_range(-110, 110))
	pos.x = clampf(pos.x, 60, W - 60)
	pos.y = clampf(pos.y, TOP + 60, BOTTOM - 40)
	pickups.append({ "type": "heart", "pos": pos, "value": 0, "t": 0.0 })

func _update_pickups(dt: float) -> void:
	for i in range(pickups.size() - 1, -1, -1):
		var q = pickups[i]
		q.t += dt
		var to_p: Vector2 = p.pos - q.pos
		var d := maxf(to_p.length(), 0.001)
		if d < 110.0:
			q.pos += (to_p / d) * 260.0 * dt
		if d < 34.0:
			match str(q.type):
				"heart":
					p.hp = minf(p.max_hp, p.hp + p.max_hp * 0.25)
					floaters.append({ "pos": q.pos + Vector2(0, -24), "text": "+生命",
						"life": 0.8, "max_life": 0.8, "col": Color("#39d98a") })
				"coin":
					gold += int(q.value)
					floaters.append({ "pos": q.pos + Vector2(0, -24), "text": "+" + str(int(q.value)) + " 金",
						"life": 0.7, "max_life": 0.7, "col": Color("#ffd166") })
				"chest":
					gold += int(q.value)
					drop_gem(q.pos, 3)
					shake_t = 0.08
					shake_str = 2.0
					floaters.append({ "pos": q.pos + Vector2(0, -30), "text": "宝箱 +" + str(int(q.value)) + " 金",
						"life": 0.9, "max_life": 0.9, "col": Color("#ffe08a") })
			play_sfx("pickup")
			pickups.remove_at(i)

# ============================================================ 战狼
func _update_wolves(dt: float) -> void:
	for w in wolves:
		w.atk_cd = maxf(0.0, float(w.atk_cd) - dt)
		var t = nearest_enemy(w.pos, 520.0, null)
		if t != null:
			var to_t: Vector2 = t.pos - w.pos
			var d := maxf(to_t.length(), 0.001)
			if d > 28.0:
				w.pos += (to_t / d) * 230.0 * dt
			elif float(w.atk_cd) <= 0.0:
				w.atk_cd = 0.65
				damage_enemy(t, 7.0 + level * 2.0, false)
				fx_at("hit", "cross", t.pos, "#d9a066", "#ffffff", 0.5)
		else:
			var to_p: Vector2 = p.pos - w.pos
			if to_p.length() > 90.0:
				w.pos += to_p.normalized() * 180.0 * dt

# ============================================================ 经验 / 升级
func gain_xp(v: int) -> void:
	var vv := int(round(float(v) * (1.0 + p.wisdom)))
	xp += float(vv)
	while xp >= float(xp_need):
		xp -= float(xp_need)
		level += 1
		xp_need = int(round(5.0 + level * 2.2))
		p.hp = minf(p.max_hp, p.hp + p.max_hp * 0.2)
		if state == S.LEVELUP:
			pending_levels += 1
		else:
			open_levelup()

func open_levelup() -> void:
	if state != S.PLAYING:
		return
	state = S.LEVELUP
	stick_active = false
	stick_vec = Vector2.ZERO
	spawn_level_fx()
	play_sfx("level")
	var pool: Array = []
	for s in SkillsData.LIST:
		if str(s.get("cat", "")) == "觉醒":
			continue
		if not SkillsData.allowed(str(meta.cls), str(s.id)):
			continue
		if int(taken.get(s.id, 0)) < int(s.max):
			pool.append(s)
	cards.clear()
	while cards.size() < 3 and pool.size() > 0:
		var idx := rng.randi_range(0, pool.size() - 1)
		cards.append(pool[idx])
		pool.remove_at(idx)
	card_rects.clear()
	for i in range(cards.size()):
		card_rects.append(Rect2(160.0 + i * 330.0, 220.0, 300.0, 320.0))
	if cards.is_empty():
		gold += 12
		state = S.PLAYING
		floaters.append({ "pos": p.pos + Vector2(0, -40), "text": "+12 金",
			"life": 1.0, "max_life": 1.0, "col": Color("#ffd166") })

func choose_card(i: int) -> void:
	if state != S.LEVELUP or i < 0 or i >= cards.size():
		return
	var u = cards[i]
	apply_skill(str(u.id))
	taken[u.id] = int(taken.get(u.id, 0)) + 1
	state = S.PLAYING
	play_sfx("pickup")
	if pending_levels > 0:
		pending_levels -= 1
		open_levelup()

func apply_skill(id: String) -> void:
	var sk = SkillsData.find(id)
	var base := id
	if not sk.is_empty():
		base = str(sk.get("base", id))
	match base:
		"dmg": p.dmg *= 1.25
		"rate": p.fire_cd = maxf(0.09, p.fire_cd * 0.85)
		"multi": p.arrows += 1
		"pierce": p.pierce += 1
		"crit": p.crit = minf(0.8, p.crit + 0.10)
		"critdmg": p.crit_mult += 0.4
		"speed": p.speed *= 1.10
		"hp":
			p.max_hp += 30.0
			p.hp = minf(p.max_hp, p.hp + 30.0)
		"regen": p.regen += 0.9
		"magnet": p.magnet *= 1.35
		"bounce": p.bounce += 1
		"armor": p.armor = minf(0.6, p.armor + 0.07)
		"shield":
			p.shield_max += 25.0
			p.shield = p.shield_max
			p.shield_cd = 12.0
		"thorn": p.thorn += 15.0
		"greed": p.greed += 0.25
		"wisdom": p.wisdom += 0.2
		"explode": p.explode += 1
		"frost": p.frost += 1
		"poison": p.poison += 1
		"chain": p.chain += 1
		"lifesteal": p.lifesteal += 0.06
		"revive": p.revive += 1
		"dash": p.dash_cd_max = maxf(1.2, p.dash_cd_max - 0.7)
		"wolf":
			wolves.append({ "pos": p.pos + Vector2(rng.randf_range(-50, 50), rng.randf_range(-50, 50)),
				"atk_cd": 0.0, "phase": rng.randf_range(0, TAU) })
		"awaken_dmg": p.dmg *= 1.15
		"awaken_hp":
			p.max_hp += 40.0
			p.hp = minf(p.max_hp, p.hp + 40.0)
		"awaken_rate": p.fire_cd = maxf(0.07, p.fire_cd * 0.92)
		"awaken_crit": p.crit = minf(0.85, p.crit + 0.05)

func spawn_level_fx() -> void:
	fx_at("level", str(fx_level_data.style), p.pos, str(fx_level_data.c1), str(fx_level_data.c2), 1.0)
	play_sfx("level")

# ============================================================ 传说技能
func _update_ultimates(dt: float) -> void:
	if freeze_t > 0.0:
		freeze_t -= dt
	for id in owned_ults:
		var u = UltimatesData.find(str(id))
		if u.is_empty() or float(u.cd) <= 0.0:
			continue
		var t: float = float(ult_cd.get(str(id), 0.0)) - dt
		ult_cd[str(id)] = t
		if t <= 0.0:
			_cast_ult(str(id))
			ult_cd[str(id)] = float(u.cd)
	# 黑洞
	for i in range(vortices.size() - 1, -1, -1):
		var v = vortices[i]
		v.t += dt
		for e in enemies:
			if e.dead:
				continue
			var d: float = v.pos.distance_to(e.pos)
			if d < float(v.r):
				var pull: Vector2 = v.pos - e.pos
				if pull.length() > 2.0:
					e.pos += pull.normalized() * 220.0 * dt
				e.hp -= (18.0 + level * 2.0) * dt
				if e.hp <= 0.0:
					kill_enemy(e)
		if v.t >= v.dur:
			vortices.remove_at(i)
	# 巨龙
	for dg in dragons:
		dg.t += dt
		var to_p: Vector2 = p.pos - dg.pos
		if to_p.length() > 140.0:
			dg.pos += to_p.normalized() * 220.0 * dt
		dg.breath_cd -= dt
		if dg.breath_cd <= 0.0:
			dg.breath_cd = 3.0
			var tgt = nearest_enemy(dg.pos, 420.0, null)
			if tgt != null:
				zaps.append({ "a": dg.pos, "b": tgt.pos, "t": 0.2, "max": 0.2 })
				for e in enemies:
					if not e.dead and e.pos.distance_to(tgt.pos) < 110.0:
						damage_enemy(e, 55.0 + level * 4.0, false)
						e.burn_t = 3.0
						e.burn_dps = 10.0
				fx_at("kill", "flame", tgt.pos, "#ff8a3a", "#ffd166", 1.5)
	# 分身
	for i in range(clones.size() - 1, -1, -1):
		var c = clones[i]
		c.t -= dt
		var want: Vector2 = p.pos + Vector2(cos(float(c.ang)), sin(float(c.ang))) * 70.0
		c.pos = c.pos.lerp(want, clampf(3.0 * dt, 0.0, 1.0))
		c.atk_cd -= dt
		if c.atk_cd <= 0.0:
			c.atk_cd = 0.5
			var t2 = nearest_enemy(c.pos, 500.0, null)
			if t2 != null:
				var dir: Vector2 = (t2.pos - c.pos).normalized()
				arrows.append({
					"pos": c.pos, "prev": c.pos, "vel": dir * 900.0,
					"dmg": p.dmg * 0.45, "crit": false, "pierce": 0, "bounce": 0,
					"life": 0.8, "hit": {}, "color": Color("#7ee0c0"),
					"explode_r": 0.0, "frost": false, "poison": false, "burn": false,
					"chain": 0, "lifesteal": 0.0, "homing": true, "boomerang": false,
					"execute": false, "spin": 0.0, "reversed": false, "spell": false
				})
		if c.t <= 0.0:
			clones.remove_at(i)

func _cast_ult(id: String) -> void:
	if test_mode:
		print("CAST_ULT ", id)
	var target = nearest_enemy(p.pos, 700.0, null)
	var tpos: Vector2 = p.pos
	if target != null:
		tpos = target.pos
	match id:
		"meteor":
			var pos := tpos + Vector2(rng.randf_range(-60, 60), rng.randf_range(-60, 60))
			strikes.append({ "pos": pos, "t": 0.55, "r": 95.0, "de": 90.0 + level * 4.0, "dp": 0.0, "kind": "meteor", "done": false })
			floaters.append({ "pos": p.pos + Vector2(0, -50), "text": "陨石术", "life": 0.8, "max_life": 0.8, "col": Color("#ff8a3a") })
		"storm":
			var used := {}
			var cur: Vector2 = p.pos
			for i in range(8):
				var best = null
				var bd := 520.0 * 520.0
				for e in enemies:
					if e.dead or used.has(e.id):
						continue
					var dd: float = cur.distance_squared_to(e.pos)
					if dd < bd:
						bd = dd
						best = e
				if best == null:
					break
				used[best.id] = true
				zaps.append({ "a": cur, "b": best.pos, "t": 0.22, "max": 0.22 })
				damage_enemy(best, 45.0 + level * 3.0, false)
				cur = best.pos
			fx_at("level", "shockwave", p.pos, "#b197fc", "#ffffff", 1.2)
		"blackhole":
			var pos2 := tpos + Vector2(rng.randf_range(-40, 40), rng.randf_range(-40, 40))
			vortices.append({ "pos": pos2, "r": 130.0, "t": 0.0, "dur": 3.0 })
			fx_at("kill", "shockwave", pos2, "#b388ff", "#ffffff", 1.6)
		"timefreeze":
			freeze_t = 2.5
			fx_at("level", "shockwave", p.pos, "#8fd8ff", "#ffffff", 2.0)
			floaters.append({ "pos": p.pos + Vector2(0, -50), "text": "时间暂停", "life": 0.9, "max_life": 0.9, "col": Color("#8fd8ff") })
		"dragon":
			if dragons.is_empty():
				dragons.append({ "pos": p.pos + Vector2(-90, 0), "t": 0.0, "breath_cd": 0.5 })
			fx_at("level", "pillar", p.pos, "#ff5d3a", "#ffd166", 1.2)
		"clones":
			for i in range(2):
				clones.append({ "pos": p.pos + Vector2(rng.randf_range(-60, 60), rng.randf_range(-60, 60)),
					"t": 8.0, "atk_cd": 0.2, "ang": float(i) * PI })
			fx_at("level", "rune", p.pos, "#7ee0c0", "#ffffff", 1.0)
		"frostnova":
			for e in enemies:
				if not e.dead and e.pos.distance_to(p.pos) < 480.0:
					damage_enemy(e, 40.0 + level * 3.0, false)
					e.slow_t = 2.5
			fx_at("level", "shockwave", p.pos, "#cfeaff", "#6fe3ff", 2.4)
		"firestorm":
			for i in range(4):
				var pos3: Vector2 = p.pos + Vector2(rng.randf_range(-260, 260), rng.randf_range(-180, 180))
				pos3.x = clampf(pos3.x, 50, W - 50)
				pos3.y = clampf(pos3.y, TOP + 50, BOTTOM - 30)
				strikes.append({ "pos": pos3, "t": 0.4 + i * 0.25, "r": 80.0, "de": 60.0 + level * 3.0, "dp": 0.0, "kind": "meteor", "done": false })


# ============================================================ 商店
func open_shop() -> void:
	if state != S.PLAYING:
		return
	state = S.SHOP
	stick_active = false
	stick_vec = Vector2.ZERO
	shop_auto_t = 0.0
	_roll_shop()
	play_sfx("level")

func _roll_shop() -> void:
	shop_offers.clear()
	var pool: Array = []
	for s in SkillsData.LIST:
		if not SkillsData.allowed(str(meta.cls), str(s.id)):
			continue
		if int(taken.get(s.id, 0)) < int(s.max):
			pool.append(s)
	var upool: Array = []
	for u in UltimatesData.LIST:
		if not str(u.id) in owned_ults:
			upool.append(u)
	# 1-2 个传说 + 4-5 个技能
	if upool.size() > 0:
		var ui := rng.randi_range(0, upool.size() - 1)
		shop_offers.append({ "kind": "ult", "id": str(upool[ui].id), "price": int(upool[ui].cost) })
		upool.remove_at(ui)
	if upool.size() > 0 and rng.randf() < 0.55:
		var ui2 := rng.randi_range(0, upool.size() - 1)
		shop_offers.append({ "kind": "ult", "id": str(upool[ui2].id), "price": int(upool[ui2].cost) })
	while shop_offers.size() < 6 and pool.size() > 0:
		var idx := rng.randi_range(0, pool.size() - 1)
		var s = pool[idx]
		pool.remove_at(idx)
		shop_offers.append({ "kind": "skill", "id": str(s.id), "price": int(s.cost) + int(taken.get(s.id, 0)) * 3 })
	# 打乱位置但保留第一个传说在最前
	shop_rects.clear()
	for i in range(shop_offers.size()):
		var col := i % 3
		var row := int(i / 3)
		shop_rects.append(Rect2(50.0 + col * 400.0, 190.0 + row * 210.0, 380.0, 196.0))

func buy_offer(i: int) -> void:
	if i < 0 or i >= shop_offers.size():
		return
	var o = shop_offers[i]
	var kind := str(o.get("kind", "skill"))
	if int(o.price) > gold:
		toast_text = "金币不够"
		toast_t = 1.2
		play_sfx("hurt", 1.4)
		return
	if kind == "ult":
		var u = UltimatesData.find(str(o.id))
		if u.is_empty() or str(u.id) in owned_ults:
			_replace_offer(i)
			return
		gold -= int(o.price)
		owned_ults.append(str(u.id))
		ult_cd[str(u.id)] = 0.5
		if test_mode:
			print("BUY_ULT ", str(u.id))
		if str(u.id) == "guardian":
			p.revive += 1
			p.shield_max += 30.0
			p.shield += 30.0
		elif str(u.id) == "bloodmoon":
			p.lifesteal += 0.05
		toast_text = "传说到手：" + str(u.n)
		toast_t = 1.6
		play_sfx("level")
		_replace_offer(i)
		return
	var sk = SkillsData.find(str(o.id))
	if sk.is_empty() or int(taken.get(sk.id, 0)) >= int(sk.max):
		_replace_offer(i)
		return
	gold -= int(o.price)
	apply_skill(str(sk.id))
	taken[sk.id] = int(taken.get(sk.id, 0)) + 1
	play_sfx("buy")
	_replace_offer(i)

func _replace_offer(i: int) -> void:
	var upool: Array = []
	for u in UltimatesData.LIST:
		if not str(u.id) in owned_ults:
			var used_u := false
			for o in shop_offers:
				if str(o.kind) == "ult" and str(o.id) == str(u.id):
					used_u = true
					break
			if not used_u:
				upool.append(u)
	if upool.size() > 0:
		var u2 = upool[rng.randi_range(0, upool.size() - 1)]
		shop_offers[i] = { "kind": "ult", "id": str(u2.id), "price": int(u2.cost) }
		return
	var pool: Array = []
	for s in SkillsData.LIST:
		if not SkillsData.allowed(str(meta.cls), str(s.id)):
			continue
		if int(taken.get(s.id, 0)) < int(s.max):
			var used := false
			for o in shop_offers:
				if str(o.id) == str(s.id) and shop_offers.find(o) != i:
					used = true
					break
			if not used:
				pool.append(s)
	if pool.is_empty():
		shop_offers.remove_at(i)
		shop_rects.remove_at(i)
		return
	var s2 = pool[rng.randi_range(0, pool.size() - 1)]
	shop_offers[i] = { "kind": "skill", "id": str(s2.id), "price": int(s2.cost) + int(taken.get(s2.id, 0)) * 3 }

func refresh_shop() -> void:
	if gold < 3:
		toast_text = "金币不够"
		toast_t = 1.2
		return
	gold -= 3
	_roll_shop()
	play_sfx("buy")

# ============================================================ 受伤 / 死亡
func hurt(dmg: float) -> void:
	if invuln > 0.0:
		return
	var d: float = dmg * (1.0 - p.armor)
	if p.shield > 0.0:
		var s := minf(p.shield, d)
		p.shield -= s
		d -= s
		p.shield_cd = 12.0
	if d <= 0.0:
		invuln = 0.4
		return
	p.hp -= d
	invuln = 0.8
	floaters.append({ "pos": p.pos + Vector2(0, -34), "text": "-" + str(int(round(d))),
		"life": 0.65, "max_life": 0.65, "col": Color("#ff6b81") })
	particles.append({ "pos": p.pos, "vel": Vector2.ZERO, "life": 0.3, "max_life": 0.3,
		"r": 22.0, "col": Color(1.0, 0.42, 0.5, 0.4) })
	shake_t = 0.15
	shake_str = 5.0
	play_sfx("hurt")

func _check_death() -> void:
	if p.hp > 0.0:
		return
	if p.revive > 0:
		p.revive -= 1
		p.hp = p.max_hp * 0.5
		invuln = 3.0
		announce("不屈 · 复活")
		spawn_level_fx()
		shake_t = 0.3
		shake_str = 10.0
		for e in enemies:
			if e.pos.distance_to(p.pos) < 260.0:
				damage_enemy(e, 200.0, true)
		return
	game_over()

func game_over() -> void:
	if state == S.OVER:
		return
	state = S.OVER
	stick_active = false
	shake_t = 0.45
	shake_str = 14.0
	play_sfx("death")
	if not rewarded:
		rewarded = true
		last_reward = int(gold * 0.5) + int(elapsed / 8.0)
		meta.coins += last_reward
		if score > int(meta.best):
			meta.best = score
		_save_meta()

# ============================================================ 词缀 / 事件
func _update_events(dt: float) -> void:
	if meteor_t > 0.0:
		meteor_t -= dt
		meteor_cd -= dt
		if meteor_cd <= 0.0:
			meteor_cd = 0.85
			var pos := Vector2(rng.randf_range(80, W - 80), rng.randf_range(TOP + 80, BOTTOM - 40))
			strikes.append({ "pos": pos, "t": 0.7, "r": 76.0, "de": 55.0, "dp": 16.0, "kind": "meteor", "done": false })
	if str(level_data.id) == "thunder" or str(level_data.id) == "void":
		storm_cd -= dt
		if storm_cd <= 0.0:
			storm_cd = 2.8
			var pos2: Vector2 = p.pos + Vector2(rng.randf_range(-220, 220), rng.randf_range(-160, 160))
			pos2.x = clampf(pos2.x, 50, W - 50)
			pos2.y = clampf(pos2.y, TOP + 50, BOTTOM - 30)
			strikes.append({ "pos": pos2, "t": 0.9, "r": 70.0, "de": 45.0, "dp": 12.0, "kind": "bolt", "done": false })
	if elapsed >= next_event:
		_trigger_event()
		next_event = elapsed + 34.0 + rng.randf() * 20.0

func _trigger_event() -> void:
	var evs := ["caravan", "bloodmoon", "supply", "hunt", "meteor"]
	var ev: String = evs[rng.randi_range(0, evs.size() - 1)]
	match ev:
		"caravan":
			announce("事件 · 商队宝箱")
			for i in range(3):
				var pos: Vector2 = p.pos + Vector2(rng.randf_range(-190, 190), rng.randf_range(-150, 150))
				pos.x = clampf(pos.x, 60, W - 60)
				pos.y = clampf(pos.y, TOP + 60, BOTTOM - 40)
				pickups.append({ "type": "chest", "pos": pos, "value": rng.randi_range(10, 18), "t": 0.0 })
		"bloodmoon":
			announce("事件 · 血月（金币翻倍）")
			bloodmoon_t = 20.0
		"supply":
			announce("事件 · 补给空投")
			p.hp = minf(p.max_hp, p.hp + p.max_hp * 0.35)
			for i in range(5):
				var pos2: Vector2 = p.pos + Vector2(rng.randf_range(-160, 160), rng.randf_range(-130, 130))
				pos2.x = clampf(pos2.x, 50, W - 50)
				pos2.y = clampf(pos2.y, TOP + 50, BOTTOM - 30)
				pickups.append({ "type": "coin", "pos": pos2, "value": 5, "t": 0.0 })
		"hunt":
			announce("事件 · 精英狩猎")
			spawn_elite(true)
		"meteor":
			announce("事件 · 流星雨")
			meteor_t = 12.0
			meteor_cd = 0.2
	play_sfx("level")

func _update_strikes(dt: float) -> void:
	for i in range(strikes.size() - 1, -1, -1):
		var s = strikes[i]
		s.t -= dt
		if s.t <= 0.0 and not bool(s.done):
			s.done = true
			s.t = 0.35
			for e in enemies:
				if not e.dead and s.pos.distance_to(e.pos) < float(s.r) + e.r:
					damage_enemy(e, float(s.de), false)
			if float(s.dp) > 0.0 and s.pos.distance_to(p.pos) < float(s.r) * 0.7:
				hurt(float(s.dp))
			shake_t = 0.15
			shake_str = 6.0
			fx_at("kill", "shockwave", s.pos, "#ffe08a", "#ff8a3a", 1.2)
			play_sfx("death", 1.3)
		if s.t <= -0.2:
			strikes.remove_at(i)

# ============================================================ 天气
func _update_weather(dt: float) -> void:
	var wn := str(level_data.get("weather", "none"))
	if weather_parts.is_empty():
		return
	for w in weather_parts:
		match wn:
			"rain":
				w.pos.y += float(w.spd) * 1.6 * dt
				w.pos.x -= 60.0 * dt
			"snow":
				w.pos.y += float(w.spd) * 0.45 * dt
				w.pos.x += sin(elapsed * 1.5 + w.pos.y * 0.02) * 14.0 * dt
			"sand":
				w.pos.x -= float(w.spd) * 2.2 * dt
				w.pos.y += sin(elapsed * 2.0 + w.pos.x * 0.01) * 20.0 * dt
			"embers":
				w.pos.y -= float(w.spd) * 0.9 * dt
				w.pos.x += sin(elapsed * 2.4 + w.pos.y * 0.03) * 18.0 * dt
			"fog":
				w.pos.x += sin(elapsed * 0.4 + w.pos.y * 0.01) * 8.0 * dt
		if w.pos.y > H + 20: w.pos.y = -20.0; w.pos.x = rng.randf_range(0, W)
		if w.pos.y < -20.0: w.pos.y = H + 20.0
		if w.pos.x < -20.0: w.pos.x = W + 20.0
		if w.pos.x > W + 20.0: w.pos.x = -20.0

# ============================================================ 测试自动
func _auto_move(dt: float) -> void:
	var dir := Vector2.ZERO
	var melee := str(current_weapon.get("kind", "ranged")) == "melee"
	var best_gem = null
	var gd := 480.0 * 480.0
	for g in gems:
		var dd: float = p.pos.distance_squared_to(g.pos)
		if dd < gd:
			gd = dd
			best_gem = g
	if best_gem != null:
		dir += (best_gem.pos - p.pos).normalized() * 0.7
	if melee:
		var mt = nearest_enemy(p.pos, 320.0, null)
		if mt != null:
			dir += (mt.pos - p.pos).normalized() * 1.8
	for q in pickups:
		var dq: float = p.pos.distance_to(q.pos)
		if dq < 400.0:
			dir += (q.pos - p.pos).normalized() * (1.6 if str(q.type) == "heart" else 0.9)
	var erep := 1.4 if melee else 3.4
	for e in enemies:
		var d: float = p.pos.distance_to(e.pos)
		if d < 340.0:
			dir += (p.pos - e.pos).normalized() * (1.0 - d / 340.0) * erep
	for o in orbs:
		var d2: float = p.pos.distance_to(o.pos)
		if d2 < 190.0:
			dir += (p.pos - o.pos).normalized() * (1.0 - d2 / 190.0) * 3.0
	for z in zones:
		if str(z.kind) in ["lava", "poison", "void"]:
			var dz: float = p.pos.distance_to(z.pos)
			if dz < z.r + 70.0:
				dir += (p.pos - z.pos).normalized() * (1.0 - dz / (z.r + 70.0)) * 2.0
	for o in obstacles:
		var d3: float = p.pos.distance_to(o.pos)
		if d3 < o.r + 70.0:
			dir += (p.pos - o.pos).normalized() * (1.0 - d3 / (o.r + 70.0)) * 2.4
	dir += Vector2(W * 0.5 - p.pos.x, H * 0.55 - p.pos.y) * 0.0012
	if dir.length() > 0.01:
		auto_mv = dir.normalized()
	else:
		auto_mv = Vector2(cos(elapsed * 1.1), sin(elapsed * 1.3 + 0.5))
	var near = nearest_enemy(p.pos, 130.0, null)
	if near != null or p.hp < p.max_hp * 0.4:
		try_dash()

# ============================================================ 音效
func _init_audio() -> void:
	for i in range(8):
		var pl := AudioStreamPlayer.new()
		pl.volume_db = -10.0
		add_child(pl)
		sfx_players.append(pl)
	sfx_bank["shoot"] = _wav(760.0, 0.05, 0.10, "square")
	sfx_bank["hit"] = _wav(240.0, 0.05, 0.09, "noise")
	sfx_bank["hurt"] = _wav(130.0, 0.16, 0.16, "saw")
	sfx_bank["kill"] = _wav(320.0, 0.09, 0.10, "square")
	sfx_bank["level"] = _wav(880.0, 0.20, 0.12, "sine")
	sfx_bank["pickup"] = _wav(1040.0, 0.07, 0.08, "sine")
	sfx_bank["buy"] = _wav(1240.0, 0.12, 0.10, "sine")
	sfx_bank["death"] = _wav(70.0, 0.45, 0.18, "saw")
	sfx_bank["orb"] = _wav(420.0, 0.06, 0.06, "sine")
	sfx_bank["slash"] = _wav(300.0, 0.08, 0.12, "noise")

func _wav(freq: float, dur: float, vol: float, kind: String) -> AudioStreamWAV:
	var rate := 22050
	var n := int(dur * rate)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t := float(i) / float(rate)
		var env := pow(1.0 - float(i) / float(n), 1.5)
		var v := 0.0
		match kind:
			"square": v = 1.0 if sin(TAU * freq * t) >= 0.0 else -1.0
			"noise": v = rng.randf_range(-1.0, 1.0)
			"saw": v = fmod(t * freq, 1.0) * 2.0 - 1.0
			_: v = sin(TAU * freq * t)
		var s := int(clampf(v * env * vol, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	return w

func play_sfx(name: String, pitch: float = 1.0) -> void:
	if not sfx_bank.has(name) or sfx_players.is_empty():
		return
	var pl: AudioStreamPlayer = sfx_players[sfx_i % sfx_players.size()]
	sfx_i += 1
	pl.stream = sfx_bank[name]
	pl.pitch_scale = pitch
	pl.play()

# ============================================================ 提示 / 特效对象
func announce(txt: String) -> void:
	banner_text = txt
	banner_t = 2.2

func emit_particles(pos: Vector2, col: Color, n: int, speed: float) -> void:
	for i in range(n):
		var a := rng.randf_range(0, TAU)
		particles.append({
			"pos": pos, "vel": Vector2(cos(a), sin(a)) * rng.randf_range(speed * 0.3, speed),
			"life": rng.randf_range(0.22, 0.45), "max_life": 0.45,
			"r": rng.randf_range(2.0, 5.0), "col": col
		})

func fx_at(kind: String, style: String, pos: Vector2, c1: String, c2: String, scale: float) -> void:
	fxs.append({ "kind": kind, "style": style, "pos": pos, "t": 0.0,
		"dur": 0.9 if kind == "level" else (0.55 if kind == "kill" else 0.35),
		"c1": Color(c1), "c2": Color(c2), "scale": scale })

func _update_fx(dt: float) -> void:
	for i in range(fxs.size() - 1, -1, -1):
		fxs[i].t += dt
		if fxs[i].t >= fxs[i].dur:
			fxs.remove_at(i)

func _update_particles(dt: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var q = particles[i]
		q.life -= dt
		q.pos += q.vel * dt
		q.vel *= 0.94
		if q.life <= 0.0:
			particles.remove_at(i)

func _update_floaters(dt: float) -> void:
	for i in range(floaters.size() - 1, -1, -1):
		var f = floaters[i]
		f.life -= dt
		f.pos.y -= 55.0 * dt
		if f.life <= 0.0:
			floaters.remove_at(i)
func draw_class_screen() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.03, 0.06, 0.72))
	draw_string(font, Vector2(36, 58), "职业", HORIZONTAL_ALIGNMENT_LEFT, -1, 38, Color("#eaf7ff"))
	draw_string(font, Vector2(36, 88), "6 个职业 · 不同初始武器 / 属性 / 技能，点一张开打", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#8fb0d8"))
	draw_string(font, Vector2(W - 360, 56), "金币 " + str(int(meta.coins)), HORIZONTAL_ALIGNMENT_RIGHT, 160, 24, Color("#ffd166"))
	draw_rect(BACK_RECT, Color("#121a2e"))
	draw_rect(BACK_RECT, Color("#2f4468"), false, 2.0)
	draw_string(font, BACK_RECT.position + Vector2(34, 35), "返回", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#dbe9ff"))
	for i in range(ClassesData.LIST.size()):
		_draw_class_card(i)

func _draw_class_card(i: int) -> void:
	var c = ClassesData.LIST[i]
	var r: Rect2 = class_rects[i]
	var selected := str(meta.cls) == str(c.id)
	var w = WeaponsData.find(str(c.weapon))
	_card_bg(r, Color(str(c.color)), selected)
	draw_circle(r.position + Vector2(52, 62), 28, Color(str(c.color), 0.2))
	draw_circle(r.position + Vector2(52, 62), 20, Color(str(c.color)))
	draw_arc(r.position + Vector2(52, 62), 24, PI * 1.05, PI * 1.95, 14, Color(str(c.color)).lightened(0.2), 5.0, true)
	draw_string(font, Vector2(r.position.x + 96, r.position.y + 44), str(c.n), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("#f0f8ff"))
	draw_string(font, Vector2(r.position.x + 96, r.position.y + 72), str(c.d), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#8fb0d8"))
	draw_string(font, Vector2(r.position.x + 96, r.position.y + 104), "初始武器：" + str(w.n), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#54e6c0"))
	var dmg_pct := int((float(c.dmg) - 1.0) * 100.0)
	var dmg_txt := ("+%d%%" % dmg_pct) if dmg_pct >= 0 else ("%d%%" % dmg_pct)
	draw_string(font, Vector2(r.position.x + 24, r.position.y + 146), "生命 %d　移速 %d　伤害 %s　护甲 +%d%%" % [
		int(c.hp), int(c.speed), dmg_txt, int(float(c.armor) * 100.0)
	], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#9fb3c8"))
	var ss := str(c.start_skill)
	var extra := "自带技能：无"
	if ss != "":
		var sk = SkillsData.find(ss)
		extra = "自带技能：" + str(sk.get("n", ss)) + " Lv.1"
	draw_string(font, Vector2(r.position.x + 24, r.position.y + 174), extra, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#ffd166"))
	_draw_weapon_icon(w, r.position + Vector2(330, 152), 0.62)
	if selected:
		draw_string(font, Vector2(r.position.x + r.size.x - 100, r.position.y + 44), "使用中", HORIZONTAL_ALIGNMENT_RIGHT, 80, 18, Color("#62f0b6"))

# ============================================================ 图鉴 / 大厅交互
func _build_grid() -> void:
	grid_rects.clear()
	grid_ids.clear()
	if state == S.EFFECTS:
		for i in range(EffectsData.LIST.size()):
			var col := i % 5
			var row := int(i / 5)
			grid_rects.append(Rect2(36.0 + col * 244.0, 132.0 + row * 118.0, 232.0, 108.0))
	elif state == S.WEAPONS:
		var list := WeaponsData.for_class(str(meta.cls))
		for w in list:
			grid_ids.append(str(w.id))
		for i in range(list.size()):
			var col := i % 6
			var row := int(i / 6)
			grid_rects.append(Rect2(45.0 + col * 200.0, 118.0 + row * 92.0, 190.0, 84.0))
	else:
		for i in range(SkinsData.LIST.size()):
			var col := i % 4
			var row := int(i / 4)
			grid_rects.append(Rect2(42.0 + col * 302.0, 126.0 + row * 110.0, 290.0, 100.0))

func _grid_click(st: int, i: int) -> void:
	if st == S.WEAPONS:
		var w = WeaponsData.find(str(grid_ids[i]))
		if str(w.id) in meta.uw:
			meta.weapon = str(w.id)
			_apply_meta_visuals()
			_save_meta()
			toast_text = "已装备 " + str(w.n)
			toast_t = 1.2
			play_sfx("buy")
		elif int(meta.coins) >= int(w.cost):
			meta.coins -= int(w.cost)
			meta.uw.append(str(w.id))
			meta.weapon = str(w.id)
			_apply_meta_visuals()
			_save_meta()
			toast_text = "解锁并装备 " + str(w.n)
			toast_t = 1.4
			play_sfx("buy")
		else:
			toast_text = "金币不够"
			toast_t = 1.2
			play_sfx("hurt", 1.4)
	elif st == S.SKINS:
		var s = SkinsData.LIST[i]
		if str(s.id) in meta.us:
			meta.skin = str(s.id)
			_apply_meta_visuals()
			_save_meta()
			toast_text = "已换上 " + str(s.n)
			toast_t = 1.2
			play_sfx("buy")
		elif int(meta.coins) >= int(s.cost):
			meta.coins -= int(s.cost)
			meta.us.append(str(s.id))
			meta.skin = str(s.id)
			_apply_meta_visuals()
			_save_meta()
			toast_text = "解锁并换上 " + str(s.n)
			toast_t = 1.4
			play_sfx("buy")
		else:
			toast_text = "金币不够"
			toast_t = 1.2
			play_sfx("hurt", 1.4)
	elif st == S.EFFECTS:
		var e = EffectsData.LIST[i]
		if str(e.id) in meta.uf:
			_equip_effect(str(e.cat), str(e.id))
			toast_text = "已切换 " + str(e.n)
			toast_t = 1.2
			play_sfx("buy")
		elif int(meta.coins) >= int(e.cost):
			meta.coins -= int(e.cost)
			meta.uf.append(str(e.id))
			_equip_effect(str(e.cat), str(e.id))
			toast_text = "解锁并切换 " + str(e.n)
			toast_t = 1.4
			play_sfx("buy")
		else:
			toast_text = "金币不够"
			toast_t = 1.2
			play_sfx("hurt", 1.4)

func _build_class_grid() -> void:
	class_rects.clear()
	for i in range(ClassesData.LIST.size()):
		var col := i % 3
		var row := int(i / 3)
		class_rects.append(Rect2(50.0 + col * 400.0, 140.0 + row * 220.0, 380.0, 200.0))

func _class_click(i: int) -> void:
	if i < 0 or i >= ClassesData.LIST.size():
		return
	var c = ClassesData.LIST[i]
	meta.cls = str(c.id)
	meta.weapon = str(c.weapon)
	if not str(c.weapon) in meta.uw:
		meta.uw.append(str(c.weapon))
	_apply_meta_visuals()
	_save_meta()
	toast_text = "已选择职业：" + str(c.n)
	toast_t = 1.4
	play_sfx("buy")

func _diff_name() -> String:
	match int(meta.diff):
		0: return "休闲"
		1: return "标准"
		2: return "噩梦"
	return "休闲"

func _diff_hp() -> float:
	match int(meta.diff):
		0: return 0.75
		1: return 1.0
		2: return 1.35
	return 0.75

func _diff_dmg() -> float:
	match int(meta.diff):
		0: return 0.70
		1: return 1.0
		2: return 1.30
	return 0.70

func _diff_gold() -> float:
	match int(meta.diff):
		0: return 0.85
		1: return 1.0
		2: return 1.30
	return 0.85

func _equip_effect(cat: String, id: String) -> void:
	match cat:
		"hit": meta.fx_hit = id
		"kill": meta.fx_kill = id
		"level": meta.fx_level = id
		"trail": meta.fx_trail = id
	_apply_meta_visuals()
	_save_meta()

# ============================================================ 绘制入口
func _draw() -> void:
	_draw_background()
	if state == S.TITLE:
		draw_lobby()
		_draw_toast()
		return
	if state in [S.WEAPONS, S.SKINS, S.EFFECTS]:
		draw_grid_screen()
		_draw_toast()
		return
	if state == S.CLASSES:
		draw_class_screen()
		_draw_toast()
		return

	var so := shake_off
	draw_zones()
	draw_obstacles()
	draw_weather()
	draw_pickups(so)
	draw_gems(so)
	draw_enemies(so)
	draw_wolves(so)
	draw_vortices(so)
	draw_dragons(so)
	draw_clones(so)
	draw_player(so)
	draw_slashes(so)
	draw_arrows(so)
	draw_orbs(so)
	draw_zaps(so)
	draw_strikes()
	draw_particles(so)
	draw_fxs(so)
	draw_floaters(so)
	if darkness:
		draw_darkness()
	draw_hud()
	draw_banner()
	if stick_active:
		draw_stick()
	if state == S.LEVELUP:
		draw_levelup()
	elif state == S.SHOP:
		draw_shop()
	elif state == S.PAUSED:
		draw_pause()
	elif state == S.OVER:
		draw_over()
	_draw_toast()

func _draw_background() -> void:
	var bg := Color("#0b0e17")
	var grid := Color("#141b2e")
	if not level_data.is_empty() and state not in [S.TITLE, S.WEAPONS, S.SKINS, S.EFFECTS, S.CLASSES]:
		bg = Color(str(level_data.bg))
		grid = Color(str(level_data.grid))
	draw_rect(Rect2(0, 0, W, H), bg)
	_grad(Rect2(0, 0, W, H), bg.lightened(0.06), bg.darkened(0.35), 18)
	for s in stars:
		draw_circle(s.pos, s.r, Color(0.7, 0.8, 1.0, s.a))
	for pt in petals:
		var pp: Vector2 = pt.pos
		var r: float = pt.r
		var a: float = pt.a
		var rot: float = pt.rot
		var q1 := pp + Vector2(cos(rot), sin(rot)) * r
		var q2 := pp + Vector2(cos(rot + 1.6), sin(rot + 1.6)) * r * 0.55
		var q3 := pp - Vector2(cos(rot), sin(rot)) * r
		var q4 := pp - Vector2(cos(rot + 1.6), sin(rot + 1.6)) * r * 0.55
		draw_colored_polygon(PackedVector2Array([q1, q2, q3, q4]), Color(1.0, 0.65, 0.82, a))
	for x in range(0, int(W) + 1, 64):
		draw_line(Vector2(x, 0), Vector2(x, H), Color(grid, 0.45), 1.0)
	for y in range(0, int(H) + 1, 64):
		draw_line(Vector2(0, y), Vector2(W, y), Color(grid, 0.45), 1.0)

# ============================================================ 大厅
func draw_lobby() -> void:
	_grad(Rect2(0, 0, W, H), Color(0.07, 0.04, 0.16, 0.55), Color(0.02, 0.01, 0.06, 0.88), 12)
	_outline_text("弓箭手大作战", W * 0.5, 110, 78, Color("#ffe6ff"))
	tc("Godot v3.1 · 6 职业 45 武器 10 传说 · 20 关 20 皮肤 20 特效", 158, 21, Color("#9fd0ff"))
	tc("近战/远程 · 技能商店 · 词缀事件精英连击 · 三档难度", 190, 18, Color("#c9b8ff"))

	_card_bg(START_RECT, Color("#ff7aa6"), true)
	_outline_text("开始狩猎", START_RECT.get_center().x, START_RECT.position.y + 62, 36, Color("#ffffff"))

	_draw_lobby_btn(BTN_C, "职业", str(current_class.n))
	_draw_lobby_btn(BTN_W, "武器", str(current_weapon.n))
	_draw_lobby_btn(BTN_S, "皮肤", str(current_skin.n))
	_draw_lobby_btn(BTN_E, "特效", str(fx_hit_data.n))

	_card_bg(DIFF_RECT, Color("#ffd166"))
	draw_string(font, Vector2(DIFF_RECT.position.x + 16, DIFF_RECT.position.y + 32), "难度：" + _diff_name() + "（点击切换）", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#ffe9a8"))

	tc("金币 %d　最高分 %d" % [int(meta.coins), int(meta.best)], 540, 24, Color("#ffd166"))
	tc("职业：%s　武器：%s　皮肤：%s" % [str(current_class.n), str(current_weapon.n), str(current_skin.n)], 574, 18, Color("#8fb0d8"))
	tc("手机：按住屏幕拖动　电脑：WASD / 方向键　空格冲刺　B 商店　P 暂停", 608, 17, Color("#6d7f9c"))
	tc("商店有传说技能：陨石 / 黑洞 / 巨龙 / 时间暂停，每 3 波自动开", 636, 17, Color("#6d7f9c"))
	tc("REA 拆玩法 · Godot 手搓 · 无素材纯几何", 690, 14, Color("#43516b"))
	# 装饰
	var bob := sin(Time.get_ticks_msec() / 600.0) * 6.0
	draw_skin_char(Vector2(1070, 600 + bob), current_skin, 2.4, -PI * 0.5)
	draw_circle(Vector2(1070, 660 + bob), 22, Color(0, 0, 0, 0.2))

func _draw_lobby_btn(r: Rect2, title: String, val: String) -> void:
	var accent := Color("#7ee0c0")
	match title:
		"武器": accent = Color("#9fd0ff")
		"皮肤": accent = Color("#ff9ac9")
		"特效": accent = Color("#b197fc")
	_card_bg(r, accent)
	draw_string(font, Vector2(r.position.x + 14, r.position.y + 25), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#eaf6ff"))
	draw_string(font, Vector2(r.position.x + 14, r.position.y + 49), val, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, accent)

# ============================================================ 图鉴
func draw_grid_screen() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.03, 0.06, 0.72))
	var title := "武器图鉴"
	var sub := "%d 把 · %s专属 · 点击已拥有装备 / 未拥有购买" % [grid_ids.size(), str(current_class.n)]
	if state == S.SKINS:
		title = "皮肤"
		sub = "20 套 · 点击已拥有换上 / 未拥有购买"
	elif state == S.EFFECTS:
		title = "特效"
		sub = "20 个 · 命中 / 击杀 / 升级 / 拖尾，点一个装备"
	draw_string(font, Vector2(36, 58), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 38, Color("#eaf7ff"))
	draw_string(font, Vector2(36, 88), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#8fb0d8"))
	draw_string(font, Vector2(W - 360, 56), "金币 " + str(int(meta.coins)), HORIZONTAL_ALIGNMENT_RIGHT, 160, 24, Color("#ffd166"))
	draw_rect(BACK_RECT, Color("#121a2e"))
	draw_rect(BACK_RECT, Color("#2f4468"), false, 2.0)
	draw_string(font, BACK_RECT.position + Vector2(34, 35), "返回", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#dbe9ff"))

	if state == S.WEAPONS:
		for i in range(grid_ids.size()):
			_draw_weapon_card(i)
	elif state == S.SKINS:
		for i in range(SkinsData.LIST.size()):
			_draw_skin_card(i)
	else:
		for i in range(EffectsData.LIST.size()):
			_draw_effect_card(i)

func _draw_weapon_card(i: int) -> void:
	var w = WeaponsData.find(str(grid_ids[i]))
	var r: Rect2 = grid_rects[i]
	var owned: bool = str(w.id) in meta.uw
	var equipped: bool = str(meta.weapon) == str(w.id)
	var melee := str(w.get("kind", "ranged")) == "melee"
	_card_bg(r, Color(str(w.color)), equipped)
	draw_rect(Rect2(r.position.x + 6, r.position.y + 10, 4, 62), Color(str(w.color)))
	_draw_weapon_icon(w, r.position + Vector2(32, 44), 0.55)
	draw_string(font, Vector2(r.position.x + 58, r.position.y + 24), str(w.n), HORIZONTAL_ALIGNMENT_LEFT, 80, 16, Color("#f0f8ff"))
	draw_string(font, Vector2(r.position.x + 58, r.position.y + 41), str(w.d), HORIZONTAL_ALIGNMENT_LEFT, 122, 10, Color("#8fb0d8"))
	var stats := ""
	if melee:
		stats = "近战 范围%d 弧%.1f" % [int(w.range), float(w.arc)]
	else:
		stats = "伤%.0f 速%.2f 箭%d" % [float(w.dmg) * 10.0, float(w.rate), int(w.arrows)]
	draw_string(font, Vector2(r.position.x + 58, r.position.y + 66), stats, HORIZONTAL_ALIGNMENT_LEFT, 122, 10, Color("#6d8fb8"))
	var tag := "装备" if equipped else ("已有" if owned else str(int(w.cost)) + "金")
	var col := Color("#62f0b6") if equipped else (Color("#9fb3c8") if owned else Color("#ffd166"))
	draw_string(font, Vector2(r.position.x + r.size.x - 58, r.position.y + 24), tag, HORIZONTAL_ALIGNMENT_RIGHT, 50, 13, col)

func _draw_skin_card(i: int) -> void:
	var s = SkinsData.LIST[i]
	var r: Rect2 = grid_rects[i]
	var owned: bool = str(s.id) in meta.us
	var equipped: bool = str(meta.skin) == str(s.id)
	_card_bg(r, Color(str(s.body)), equipped)
	draw_skin_char(r.position + Vector2(46, 50), s, 1.25, -PI * 0.5)
	draw_string(font, Vector2(r.position.x + 88, r.position.y + 34), str(s.n), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#f0f8ff"))
	draw_string(font, Vector2(r.position.x + 88, r.position.y + 60), "帽子 " + _hat_name(str(s.hat)), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#8fb0d8"))
	var tag := "使用中" if equipped else ("已拥有" if owned else str(int(s.cost)) + " 金")
	var col := Color("#62f0b6") if equipped else (Color("#9fb3c8") if owned else Color("#ffd166"))
	draw_string(font, Vector2(r.position.x + r.size.x - 90, r.position.y + 34), tag, HORIZONTAL_ALIGNMENT_RIGHT, 76, 17, col)
	draw_rect(Rect2(r.position.x + 88, r.position.y + 72, 26, 8), Color(str(s.body)))
	draw_rect(Rect2(r.position.x + 120, r.position.y + 72, 26, 8), Color(str(s.cloak)))
	draw_rect(Rect2(r.position.x + 152, r.position.y + 72, 26, 8), Color(str(s.eye)))

func _draw_effect_card(i: int) -> void:
	var e = EffectsData.LIST[i]
	var r: Rect2 = grid_rects[i]
	var owned: bool = str(e.id) in meta.uf
	var equipped := false
	match str(e.cat):
		"hit": equipped = str(meta.fx_hit) == str(e.id)
		"kill": equipped = str(meta.fx_kill) == str(e.id)
		"level": equipped = str(meta.fx_level) == str(e.id)
		"trail": equipped = str(meta.fx_trail) == str(e.id)
	_card_bg(r, Color(str(e.c1)), equipped)
	# 图标
	var ip := r.position + Vector2(34, 54)
	_draw_effect_icon(str(e.c1), str(e.c2), ip)
	draw_string(font, Vector2(r.position.x + 62, r.position.y + 34), str(e.n), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#f0f8ff"))
	draw_string(font, Vector2(r.position.x + 62, r.position.y + 58), _cat_name(str(e.cat)), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#8fb0d8"))
	var tag := "使用中" if equipped else ("已拥有" if owned else str(int(e.cost)) + " 金")
	var col := Color("#62f0b6") if equipped else (Color("#9fb3c8") if owned else Color("#ffd166"))
	draw_string(font, Vector2(r.position.x + r.size.x - 80, r.position.y + 34), tag, HORIZONTAL_ALIGNMENT_RIGHT, 66, 15, col)

func _cat_name(c: String) -> String:
	match c:
		"hit": return "命中"
		"kill": return "击杀"
		"level": return "升级"
		"trail": return "拖尾"
	return c

func _hat_name(h: String) -> String:
	match h:
		"none": return "无"
		"hood": return "兜帽"
		"horns": return "犄角"
		"helm": return "头盔"
		"halo": return "光环"
		"crown": return "王冠"
		"ears": return "兽耳"
		"antenna": return "触角"
		"wings": return "翅膀"
		"tail": return "尾巴"
		"flame": return "火焰"
		"mask": return "面罩"
	return h

func _class_color(cls: String) -> Color:
	match cls:
		"ranger": return Color("#2fb37a")
		"blade": return Color("#9fd0ff")
		"mage": return Color("#b197fc")
		"assassin": return Color("#ff7aa6")
		"berserker": return Color("#ff8a3a")
		"summoner": return Color("#8ab86a")
	return Color("#ffd166")

func _ico_line(pos: Vector2, ang: float, length: float, col: Color, w: float) -> void:
	draw_line(pos, pos + Vector2(cos(ang), sin(ang)) * length, col, w)

func _ico_tri(pos: Vector2, ang: float, size: float, col: Color) -> void:
	var d := Vector2(cos(ang), sin(ang))
	var p := Vector2(-d.y, d.x)
	draw_colored_polygon(PackedVector2Array([pos + d * size, pos + p * size * 0.72, pos - p * size * 0.72]), col)

func _draw_skill_icon(id: String, pos: Vector2, s: float) -> void:
	var sd = SkillsData.find(id)
	if not sd.is_empty():
		var b := str(sd.get("base", ""))
		if b != "" and b != id:
			_draw_skill_icon(b, pos, s * 0.82)
			draw_arc(pos, 23.0 * s, 0, TAU, 28, _class_color(str(sd.get("cls", ""))), 2.0 * s, true)
			return
	var c := Color("#ffd166")
	match id:
		"dmg":
			c = Color("#ff8a3a")
			_ico_line(pos + Vector2(0, 14) * s, -PI * 0.5, 28 * s, c, 4 * s)
			_ico_tri(pos + Vector2(0, -14) * s, -PI * 0.5, 9 * s, c)
		"rate":
			c = Color("#7ee0c0")
			draw_polyline(PackedVector2Array([pos + Vector2(-10, -18) * s, pos + Vector2(2, -4) * s, pos + Vector2(-4, 0) * s, pos + Vector2(10, 16) * s]), c, 3 * s)
			draw_arc(pos + Vector2(0, 0), 19 * s, -1.2, 1.2, 10, c, 2 * s, true)
		"multi":
			c = Color("#54e6c0")
			for i in range(3):
				var a := -PI * 0.5 + (float(i) - 1.0) * 0.45
				_ico_line(pos, a, 22 * s, c, 2.5 * s)
				_ico_tri(pos + Vector2(cos(a), sin(a)) * 24 * s, a, 6 * s, c)
		"pierce":
			c = Color("#9fd0ff")
			draw_arc(pos, 13 * s, 0, TAU, 20, Color(c, 0.6), 2 * s, true)
			_ico_line(pos + Vector2(-20, 0) * s, 0, 40 * s, c, 3 * s)
			_ico_tri(pos + Vector2(20, 0) * s, 0, 7 * s, c)
		"crit":
			c = Color("#ffd166")
			draw_arc(pos, 16 * s, 0, TAU, 24, c, 2 * s, true)
			draw_line(pos + Vector2(-22, 0) * s, pos + Vector2(22, 0) * s, c, 1.5 * s)
			draw_line(pos + Vector2(0, -22) * s, pos + Vector2(0, 22) * s, c, 1.5 * s)
			draw_circle(pos, 3 * s, c)
		"critdmg":
			c = Color("#ff5d73")
			for i in range(8):
				var a := float(i) * TAU / 8.0
				draw_line(pos + Vector2(cos(a), sin(a)) * 7 * s, pos + Vector2(cos(a), sin(a)) * (19 + (5 if i % 2 == 0 else 0)) * s, c, 2 * s)
		"speed":
			c = Color("#7ee0c0")
			draw_colored_polygon(PackedVector2Array([pos + Vector2(-12, 12) * s, pos + Vector2(2, 12) * s, pos + Vector2(10, -6) * s, pos + Vector2(4, -6) * s, pos + Vector2(8, -16) * s, pos + Vector2(-10, 2) * s]), c)
			draw_line(pos + Vector2(-22, 0) * s, pos + Vector2(-12, 0) * s, Color(c, 0.6), 2 * s)
			draw_line(pos + Vector2(-20, 8) * s, pos + Vector2(-10, 8) * s, Color(c, 0.4), 2 * s)
		"hp":
			c = Color("#39d98a")
			draw_circle(pos + Vector2(-7, -4) * s, 9 * s, c)
			draw_circle(pos + Vector2(7, -4) * s, 9 * s, c)
			draw_colored_polygon(PackedVector2Array([pos + Vector2(-16, 0) * s, pos + Vector2(16, 0) * s, pos + Vector2(0, 18) * s]), c)
		"regen":
			c = Color("#78d17a")
			draw_rect(Rect2(pos.x - 4 * s, pos.y - 16 * s, 8 * s, 32 * s), c)
			draw_rect(Rect2(pos.x - 16 * s, pos.y - 4 * s, 32 * s, 8 * s), c)
			draw_circle(pos + Vector2(12, 10) * s, 5 * s, Color("#a8d88a"))
		"magnet":
			c = Color("#6fe3ff")
			draw_arc(pos + Vector2(0, -2) * s, 14 * s, 0, PI, 20, c, 5 * s, true)
			draw_line(pos + Vector2(-14, -2) * s, pos + Vector2(-14, 14) * s, c, 5 * s)
			draw_line(pos + Vector2(14, -2) * s, pos + Vector2(14, 14) * s, c, 5 * s)
			draw_line(pos + Vector2(-20, 14) * s, pos + Vector2(-8, 14) * s, Color("#ffffff", 0.7), 2 * s)
			draw_line(pos + Vector2(8, 14) * s, pos + Vector2(20, 14) * s, Color("#ffffff", 0.7), 2 * s)
		"bounce":
			c = Color("#ffb3c1")
			draw_circle(pos + Vector2(-12, 12) * s, 5 * s, c)
			draw_circle(pos + Vector2(10, 10) * s, 5 * s, c)
			draw_arc(pos + Vector2(0, -2) * s, 14 * s, PI * 1.1, PI * 1.9, 14, c, 2 * s, true)
			_ico_tri(pos + Vector2(14, -8) * s, -PI * 0.5, 6 * s, c)
		"armor":
			c = Color("#9fd0ff")
			draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -18) * s, pos + Vector2(16, -10) * s, pos + Vector2(12, 10) * s, pos + Vector2(0, 20) * s, pos + Vector2(-12, 10) * s, pos + Vector2(-16, -10) * s]), Color(c, 0.85))
			draw_line(pos + Vector2(-8, 0) * s, pos + Vector2(8, 0) * s, Color("#ffffff", 0.6), 2 * s)
		"shield":
			c = Color("#6fb6ff")
			draw_circle(pos, 18 * s, Color(c, 0.18))
			draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -16) * s, pos + Vector2(14, -8) * s, pos + Vector2(10, 10) * s, pos + Vector2(0, 18) * s, pos + Vector2(-10, 10) * s, pos + Vector2(-14, -8) * s]), c)
			draw_arc(pos, 20 * s, 0, TAU, 20, Color(c, 0.5), 2 * s, true)
		"thorn":
			c = Color("#8ab86a")
			draw_circle(pos, 10 * s, Color(c, 0.8))
			for i in range(8):
				var a := float(i) * TAU / 8.0
				_ico_tri(pos + Vector2(cos(a), sin(a)) * 12 * s, a, 7 * s, c)
		"greed":
			c = Color("#ffd166")
			draw_circle(pos, 16 * s, c)
			draw_circle(pos, 11 * s, Color("#a87c1a"))
			draw_circle(pos, 8 * s, c)
			draw_line(pos + Vector2(0, -6) * s, pos + Vector2(0, 6) * s, Color("#5a3a00"), 2 * s)
		"wisdom":
			c = Color("#9fd0ff")
			draw_rect(Rect2(pos.x - 14 * s, pos.y - 12 * s, 28 * s, 24 * s), Color(c, 0.85))
			draw_line(pos + Vector2(0, -12) * s, pos + Vector2(0, 12) * s, Color("#1a2f68"), 2 * s)
			for i in range(3):
				draw_line(pos + Vector2(-9, -4 + i * 6) * s, pos + Vector2(-2, -4 + i * 6) * s, Color("#1a2f68"), 1.5 * s)
		"explode":
			c = Color("#ff8a3a")
			draw_circle(pos, 10 * s, c)
			for i in range(8):
				var a := float(i) * TAU / 8.0
				draw_line(pos + Vector2(cos(a), sin(a)) * 13 * s, pos + Vector2(cos(a), sin(a)) * 21 * s, c, 2 * s)
		"frost":
			c = Color("#cfeaff")
			for i in range(3):
				var a := float(i) * PI / 3.0
				draw_line(pos - Vector2(cos(a), sin(a)) * 18 * s, pos + Vector2(cos(a), sin(a)) * 18 * s, c, 2.5 * s)
			draw_circle(pos, 3 * s, Color("#ffffff"))
		"poison":
			c = Color("#78d17a")
			draw_circle(pos + Vector2(0, 4) * s, 11 * s, c)
			_ico_tri(pos + Vector2(0, -8) * s, -PI * 0.5, 10 * s, c)
			draw_circle(pos + Vector2(-6, 8) * s, 2 * s, Color("#1a3a1a"))
			draw_circle(pos + Vector2(16, -12) * s, 3 * s, Color(c, 0.6))
			draw_circle(pos + Vector2(20, -2) * s, 2 * s, Color(c, 0.4))
		"chain":
			c = Color("#b197fc")
			draw_polyline(PackedVector2Array([pos + Vector2(-16, -14) * s, pos + Vector2(-2, -2) * s, pos + Vector2(-8, 2) * s, pos + Vector2(8, 16) * s]), c, 3 * s)
			draw_polyline(PackedVector2Array([pos + Vector2(4, -16) * s, pos + Vector2(12, -4) * s, pos + Vector2(6, 0) * s, pos + Vector2(18, 12) * s]), Color(c, 0.6), 2 * s)
		"wolf":
			c = Color("#b08a5a")
			draw_circle(pos, 14 * s, c)
			_ico_tri(pos + Vector2(-11, -8) * s, -PI * 0.65, 8 * s, c)
			_ico_tri(pos + Vector2(11, -8) * s, -PI * 0.35, 8 * s, c)
			draw_circle(pos + Vector2(-5, -2) * s, 2.5 * s, Color("#1a1208"))
			draw_circle(pos + Vector2(5, -2) * s, 2.5 * s, Color("#1a1208"))
			draw_circle(pos + Vector2(0, 8) * s, 3 * s, Color("#1a1208"))
		"lifesteal":
			c = Color("#ff5d73")
			draw_circle(pos + Vector2(0, 6) * s, 10 * s, c)
			_ico_tri(pos + Vector2(0, -6) * s, -PI * 0.5, 10 * s, c)
			draw_line(pos + Vector2(-14, -14) * s, pos + Vector2(14, 14) * s, Color("#ffffff", 0.7), 2 * s)
		"revive":
			c = Color("#ffe08a")
			draw_circle(pos, 12 * s, Color(c, 0.25))
			draw_line(pos + Vector2(0, -18) * s, pos + Vector2(0, 18) * s, c, 4 * s)
			draw_line(pos + Vector2(-12, -4) * s, pos + Vector2(12, -4) * s, c, 4 * s)
			draw_arc(pos + Vector2(0, -4) * s, 18 * s, 0, TAU, 24, Color(c, 0.5), 2 * s, true)
		"dash":
			c = Color("#7ee0c0")
			for i in range(2):
				draw_polyline(PackedVector2Array([
					pos + Vector2(-14 + i * 12, -14) * s, pos + Vector2(2 + i * 12, 0) * s, pos + Vector2(-14 + i * 12, 14) * s
				]), c, 3 * s)
		"awaken_dmg":
			c = Color("#ff8a3a")
			draw_circle(pos, 17 * s, Color(c, 0.2))
			_ico_line(pos, -PI * 0.5, 22 * s, c, 4 * s)
			_ico_tri(pos + Vector2(0, -18) * s, -PI * 0.5, 8 * s, c)
			draw_circle(pos, 3 * s, Color("#ffffff"))
		"awaken_hp":
			c = Color("#39d98a")
			draw_circle(pos + Vector2(-7, -4) * s, 9 * s, c)
			draw_circle(pos + Vector2(7, -4) * s, 9 * s, c)
			draw_colored_polygon(PackedVector2Array([pos + Vector2(-16, 0) * s, pos + Vector2(16, 0) * s, pos + Vector2(0, 18) * s]), c)
			draw_line(pos + Vector2(0, -18) * s, pos + Vector2(0, 18) * s, Color("#ffffff", 0.8), 2 * s)
		"awaken_rate":
			c = Color("#7ee0c0")
			draw_arc(pos, 18 * s, 0, TAU, 24, Color(c, 0.5), 2 * s, true)
			draw_polyline(PackedVector2Array([pos + Vector2(-8, -16) * s, pos + Vector2(4, -2) * s, pos + Vector2(-2, 2) * s, pos + Vector2(8, 16) * s]), c, 3 * s)
		"awaken_crit":
			c = Color("#ffd166")
			draw_circle(pos, 17 * s, Color(c, 0.16))
			for i in range(6):
				var a := float(i) * TAU / 6.0
				draw_line(pos + Vector2(cos(a), sin(a)) * 6 * s, pos + Vector2(cos(a), sin(a)) * 18 * s, c, 2 * s)
			draw_circle(pos, 4 * s, c)
		_:
			draw_circle(pos, 15 * s, Color(c, 0.5))
			draw_circle(pos, 6 * s, Color("#ffffff"))

func _draw_ult_icon(id: String, pos: Vector2, s: float) -> void:
	var c := Color("#ffd166")
	match id:
		"meteor":
			c = Color("#ff6b35")
			draw_circle(pos + Vector2(4, 4) * s, 12 * s, Color("#7a3a1a"))
			draw_circle(pos + Vector2(2, 2) * s, 10 * s, c)
			for i in range(3):
				draw_line(pos + Vector2(-6 - i * 6, -10 - i * 6) * s, pos + Vector2(-18 - i * 8, -24 - i * 8) * s, Color(c, 0.6), 3 * s)
		"storm":
			c = Color("#b197fc")
			draw_circle(pos + Vector2(-10, -8) * s, 9 * s, Color(c, 0.5))
			draw_circle(pos + Vector2(2, -12) * s, 11 * s, Color(c, 0.6))
			draw_circle(pos + Vector2(12, -7) * s, 8 * s, Color(c, 0.5))
			draw_polyline(PackedVector2Array([pos + Vector2(2, -4) * s, pos + Vector2(-4, 8) * s, pos + Vector2(2, 8) * s, pos + Vector2(-2, 20) * s]), c, 3 * s)
		"blackhole":
			c = Color("#b388ff")
			draw_circle(pos, 8 * s, Color(0.02, 0.0, 0.05, 1.0))
			for i in range(3):
				draw_arc(pos, (13 + i * 5) * s, float(i) * 1.6, float(i) * 1.6 + 4.4, 16, Color(c, 0.7 - i * 0.15), 2 * s, true)
		"timefreeze":
			c = Color("#8fd8ff")
			draw_circle(pos, 17 * s, Color(c, 0.18))
			draw_arc(pos, 15 * s, 0, TAU, 24, c, 2 * s, true)
			draw_line(pos, pos + Vector2(0, -10) * s, c, 2 * s)
			draw_line(pos, pos + Vector2(8, 3) * s, c, 2 * s)
		"dragon":
			c = Color("#ff5d3a")
			draw_colored_polygon(PackedVector2Array([pos + Vector2(-18, 10) * s, pos + Vector2(0, -18) * s, pos + Vector2(18, 10) * s]), c)
			draw_circle(pos + Vector2(-6, -2) * s, 2.5 * s, Color("#ffd166"))
			draw_circle(pos + Vector2(6, -2) * s, 2.5 * s, Color("#ffd166"))
			draw_line(pos + Vector2(-18, 10) * s, pos + Vector2(-24, 20) * s, Color(c, 0.6), 3 * s)
			draw_line(pos + Vector2(18, 10) * s, pos + Vector2(24, 20) * s, Color(c, 0.6), 3 * s)
		"clones":
			c = Color("#7ee0c0")
			draw_circle(pos + Vector2(-8, 0) * s, 9 * s, Color(c, 0.8))
			draw_circle(pos + Vector2(8, 0) * s, 9 * s, Color(c, 0.5))
			draw_circle(pos + Vector2(-10, -2) * s, 1.8 * s, Color("#ffffff"))
			draw_circle(pos + Vector2(6, -2) * s, 1.8 * s, Color("#ffffff"))
		"frostnova":
			c = Color("#cfeaff")
			for i in range(3):
				var a := float(i) * PI / 3.0
				draw_line(pos - Vector2(cos(a), sin(a)) * 16 * s, pos + Vector2(cos(a), sin(a)) * 16 * s, c, 2.5 * s)
			draw_arc(pos, 20 * s, 0, TAU, 24, Color(c, 0.5), 2 * s, true)
		"firestorm":
			c = Color("#ff8a3a")
			for i in range(3):
				var fx := (float(i) - 1.0) * 12.0
				draw_colored_polygon(PackedVector2Array([
					pos + Vector2(fx - 6, 12) * s, pos + Vector2(fx, -16 - i * 3) * s, pos + Vector2(fx + 6, 12) * s
				]), c)
		"guardian":
			c = Color("#ffe08a")
			draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -18) * s, pos + Vector2(14, -8) * s, pos + Vector2(10, 12) * s, pos + Vector2(0, 20) * s, pos + Vector2(-10, 12) * s, pos + Vector2(-14, -8) * s]), Color(c, 0.8))
			draw_arc(pos + Vector2(0, -20) * s, 8 * s, 0, TAU, 16, c, 2 * s, true)
		"bloodmoon":
			c = Color("#ff4d6d")
			draw_circle(pos, 15 * s, Color(c, 0.85))
			draw_circle(pos + Vector2(7, -4) * s, 12 * s, Color("#12101a"))
			draw_circle(pos + Vector2(-14, 12) * s, 3 * s, Color(c, 0.7))
			draw_circle(pos + Vector2(-4, 18) * s, 2 * s, Color(c, 0.5))
		_:
			draw_circle(pos, 15 * s, Color(c, 0.5))

func _draw_weapon_icon(w: Dictionary, pos: Vector2, s: float) -> void:
	var col := Color(str(w.get("color", "#d9a066")))
	var id := str(w.id)
	var kind := str(w.get("kind", "ranged"))
	match id:
		"ironsword":
			draw_line(pos + Vector2(-16, 16) * s, pos + Vector2(12, -14) * s, col, 6 * s)
			draw_line(pos + Vector2(-20, 12) * s, pos + Vector2(-8, 20) * s, Color("#d9a066"), 4 * s)
			draw_line(pos + Vector2(-4, 4) * s, pos + Vector2(4, 12) * s, Color("#8a5a2a"), 3 * s)
		"greataxe":
			draw_line(pos + Vector2(-12, 18) * s, pos + Vector2(10, -18) * s, Color("#8a5a2a"), 5 * s)
			draw_colored_polygon(PackedVector2Array([pos + Vector2(4, -18) * s, pos + Vector2(22, -10) * s, pos + Vector2(16, 10) * s, pos + Vector2(-2, 0) * s]), col)
		"spear":
			draw_line(pos + Vector2(-18, 18) * s, pos + Vector2(14, -14) * s, Color("#8a5a2a"), 4 * s)
			_ico_tri(pos + Vector2(18, -18) * s, -PI * 0.25, 9 * s, col)
		"daggers":
			draw_line(pos + Vector2(-16, 16) * s, pos + Vector2(-4, 2) * s, col, 5 * s)
			draw_line(pos + Vector2(2, -2) * s, pos + Vector2(14, -16) * s, col, 5 * s)
			draw_line(pos + Vector2(-12, -12) * s, pos + Vector2(-4, -4) * s, Color("#8a5a2a"), 3 * s)
			draw_line(pos + Vector2(6, 6) * s, pos + Vector2(14, 14) * s, Color("#8a5a2a"), 3 * s)
		"hammer":
			draw_line(pos + Vector2(-12, 18) * s, pos + Vector2(8, -10) * s, Color("#8a5a2a"), 5 * s)
			draw_rect(Rect2(pos.x + 2 * s, pos.y - 24 * s, 20 * s, 16 * s), col)
		"scythe":
			draw_line(pos + Vector2(-12, 18) * s, pos + Vector2(8, -10) * s, Color("#8a5a2a"), 4 * s)
			draw_arc(pos + Vector2(10, -14) * s, 18 * s, PI * 0.2, PI * 1.2, 16, col, 4 * s, true)
		"fists":
			draw_circle(pos + Vector2(-8, 4) * s, 10 * s, col)
			draw_circle(pos + Vector2(8, 4) * s, 10 * s, col)
			draw_rect(Rect2(pos.x - 14 * s, pos.y + 10 * s, 28 * s, 6 * s), Color("#8a5a2a"))
		"lightsaber":
			draw_line(pos + Vector2(-16, 16) * s, pos + Vector2(12, -12) * s, Color(0.4, 0.95, 1.0, 0.35), 12 * s)
			draw_line(pos + Vector2(-16, 16) * s, pos + Vector2(12, -12) * s, col, 4 * s)
			draw_line(pos + Vector2(-18, 14) * s, pos + Vector2(-10, 20) * s, Color("#9aa7b8"), 5 * s)
		"venomfang":
			draw_line(pos + Vector2(-12, 14) * s, pos + Vector2(12, -12) * s, col, 5 * s)
			draw_circle(pos + Vector2(14, -14) * s, 3 * s, Color("#b6ff9e"))
			draw_circle(pos + Vector2(4, 10) * s, 2 * s, Color(col, 0.6))
		"stormhammer":
			draw_line(pos + Vector2(-12, 18) * s, pos + Vector2(6, -10) * s, Color("#8a5a2a"), 5 * s)
			draw_rect(Rect2(pos.x, pos.y - 24 * s, 20 * s, 15 * s), col)
			draw_polyline(PackedVector2Array([pos + Vector2(16, -26) * s, pos + Vector2(10, -18) * s, pos + Vector2(18, -12) * s, pos + Vector2(12, -4) * s]), Color("#ffffff"), 2 * s)
		"firestaff":
			draw_line(pos + Vector2(-14, 18) * s, pos + Vector2(8, -14) * s, Color("#8a5a2a"), 5 * s)
			draw_circle(pos + Vector2(10, -16) * s, 8 * s, Color("#ff8a3a"))
			draw_circle(pos + Vector2(10, -16) * s, 4 * s, Color("#ffd166"))
		"spiritbow":
			draw_arc(pos + Vector2(-4, 0) * s, 18 * s, -PI * 0.5, PI * 0.5, 16, col, 3 * s, true)
			draw_line(pos + Vector2(-4, -18) * s, pos + Vector2(-4, 18) * s, Color("#dbeaff", 0.7), 1.5 * s)
			_ico_line(pos + Vector2(-10, 0) * s, 0, 28 * s, Color("#dbeaff", 0.7), 2 * s)
		"longsword", "greatsword":
			var blade_len := 24.0 if id == "greatsword" else 20.0
			draw_line(pos + Vector2(-18, 18) * s, pos + Vector2(blade_len, -blade_len) * s, col, (7.0 if id == "greatsword" else 5.0) * s)
			draw_line(pos + Vector2(-22, 14) * s, pos + Vector2(-6, 22) * s, Color("#ffd166"), 4 * s)
			draw_line(pos + Vector2(-4, 4) * s, pos + Vector2(6, 12) * s, Color("#8a5a2a"), 3 * s)
		"shadowblade", "throwknives":
			draw_line(pos + Vector2(-14, 14) * s, pos + Vector2(12, -12) * s, col, 5 * s)
			draw_line(pos + Vector2(-18, 8) * s, pos + Vector2(-8, 18) * s, Color("#8a5a2a"), 3 * s)
			draw_circle(pos + Vector2(14, -14) * s, 2.5 * s, Color("#ffffff"))
		"dualaxes":
			draw_line(pos + Vector2(-16, 16) * s, pos + Vector2(4, -8) * s, Color("#8a5a2a"), 4 * s)
			draw_line(pos + Vector2(16, 16) * s, pos + Vector2(-4, -8) * s, Color("#8a5a2a"), 4 * s)
			draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -18) * s, pos + Vector2(18, -8) * s, pos + Vector2(12, 10) * s, pos + Vector2(-4, 0) * s]), col)
			draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -18) * s, pos + Vector2(-18, -8) * s, pos + Vector2(-12, 10) * s, pos + Vector2(4, 0) * s]), Color(col, 0.7))
		"greatmaul":
			draw_line(pos + Vector2(-12, 18) * s, pos + Vector2(6, -10) * s, Color("#8a5a2a"), 6 * s)
			draw_rect(Rect2(pos.x - 2 * s, pos.y - 26 * s, 26 * s, 18 * s), col)
			draw_circle(pos + Vector2(10, -16) * s, 4 * s, Color("#ffe08a"))
		"froststaff", "stormstaff", "voidstaff", "bonestaff", "beaststaff", "soulbell":
			draw_line(pos + Vector2(-14, 18) * s, pos + Vector2(8, -14) * s, Color("#8a5a2a"), 5 * s)
			draw_circle(pos + Vector2(10, -16) * s, 9 * s, Color(col, 0.25))
			draw_circle(pos + Vector2(10, -16) * s, 6 * s, col)
			if id == "soulbell":
				draw_arc(pos + Vector2(10, -8) * s, 8 * s, PI, TAU, 12, Color(col, 0.8), 2 * s, true)
			else:
				draw_circle(pos + Vector2(10, -16) * s, 2.5 * s, Color("#ffffff"))
		"tome":
			draw_rect(Rect2(pos.x - 15 * s, pos.y - 16 * s, 30 * s, 32 * s), col)
			draw_line(pos + Vector2(0, -16) * s, pos + Vector2(0, 16) * s, Color("#1a2f68"), 2 * s)
			for i in range(3):
				draw_line(pos + Vector2(-10, -6 + i * 7) * s, pos + Vector2(-2, -6 + i * 7) * s, Color("#1a2f68"), 1.5 * s)
		_:
			if kind == "ranged":
				draw_arc(pos + Vector2(-2, 0) * s, 18 * s, -PI * 0.55, PI * 0.55, 16, col, 3 * s, true)
				draw_line(pos + Vector2(-2, -18) * s, pos + Vector2(-2, 18) * s, Color("#ffffff", 0.6), 1.2 * s)
				_ico_line(pos + Vector2(-12, 0) * s, 0, 26 * s, col, 2 * s)
				_ico_tri(pos + Vector2(14, 0) * s, 0, 6 * s, col)
			else:
				draw_line(pos + Vector2(-16, 16) * s, pos + Vector2(14, -14) * s, col, 5 * s)
	var sp := str(w.get("special", "none"))
	var badge := pos + Vector2(15, 15) * s
	match sp:
		"explode":
			draw_circle(badge, 4 * s, Color("#ff8a3a"))
			for i in range(4):
				var a := float(i) * TAU / 4.0
				draw_line(badge + Vector2(cos(a), sin(a)) * 5 * s, badge + Vector2(cos(a), sin(a)) * 8 * s, Color("#ffd166"), 1.5 * s)
		"frost":
			for i in range(3):
				var a2 := float(i) * PI / 3.0
				draw_line(badge - Vector2(cos(a2), sin(a2)) * 6 * s, badge + Vector2(cos(a2), sin(a2)) * 6 * s, Color("#cfeaff"), 1.5 * s)
		"poison":
			draw_circle(badge, 4 * s, Color("#78d17a"))
		"chain":
			draw_polyline(PackedVector2Array([badge + Vector2(-5, -6) * s, badge + Vector2(1, 0) * s, badge + Vector2(-3, 2) * s, badge + Vector2(5, 7) * s]), Color("#b197fc"), 2 * s)
		"homing":
			draw_arc(badge, 5 * s, 0, PI * 1.6, 10, Color("#6fe3ff"), 1.5 * s, true)
		"boomerang":
			draw_arc(badge, 5 * s, 0.3, PI * 1.7, 10, Color("#f2c94c"), 1.5 * s, true)
		"burn":
			draw_circle(badge, 4 * s, Color("#ff6b35"))
		"thorn":
			for i in range(5):
				var a3 := float(i) * TAU / 5.0
				draw_line(badge + Vector2(cos(a3), sin(a3)) * 2 * s, badge + Vector2(cos(a3), sin(a3)) * 7 * s, Color("#8ab86a"), 1.5 * s)

func _draw_effect_icon(c1: String, c2: String, pos: Vector2) -> void:
	var cc := Color(c1)
	draw_circle(pos, 22, Color(cc, 0.12))
	draw_circle(pos, 13, Color(cc, 0.5))
	draw_circle(pos, 6, Color(c2))
	for i in range(4):
		var a := float(i) * TAU / 4.0 + elapsed
		draw_line(pos + Vector2(cos(a), sin(a)) * 16.0, pos + Vector2(cos(a), sin(a)) * 24.0, Color(c2, 0.6), 2.0)

# ============================================================ 世界绘制
func draw_zones() -> void:
	for z in zones:
		var c := Color("#ff6b35")
		match str(z.kind):
			"lava": c = Color("#ff5d3a")
			"poison": c = Color("#78d17a")
			"ice": c = Color("#8fd8ff")
			"haste": c = Color("#7ee0c0")
			"heal": c = Color("#ffe08a")
			"void": c = Color("#b388ff")
		var pulse: float = 0.55 + 0.2 * sin(float(z.t) * 2.0)
		draw_circle(z.pos, float(z.r), Color(c, 0.13 * pulse))
		draw_arc(z.pos, float(z.r), 0.0, TAU, 44, Color(c, 0.45), 2.0, true)
		draw_arc(z.pos, float(z.r) * 0.62, 0.0, TAU, 30, Color(c, 0.22), 2.0, true)
		match str(z.kind):
			"lava":
				for i in range(3):
					var a := float(z.t) * 0.8 + float(i) * TAU / 3.0
					draw_circle(z.pos + Vector2(cos(a), sin(a)) * float(z.r) * 0.4, 7.0, Color("#ffd166", 0.5))
			"poison":
				for i in range(3):
					var a2 := -float(z.t) * 0.6 + float(i) * TAU / 3.0
					draw_circle(z.pos + Vector2(cos(a2), sin(a2)) * float(z.r) * 0.5, 5.0, Color("#b6ff9e", 0.45))
			"ice":
				for i in range(3):
					var a3 := float(i) * TAU / 3.0
					var p1: Vector2 = z.pos + Vector2(cos(a3), sin(a3)) * float(z.r) * 0.7
					var p2: Vector2 = z.pos + Vector2(cos(a3 + 2.1), sin(a3 + 2.1)) * float(z.r) * 0.7
					draw_line(p1, p2, Color("#cfeaff", 0.35), 2.0)
			"haste":
				for i in range(3):
					var p: Vector2 = z.pos + Vector2(-20 + i * 20, 0)
					draw_line(p, p + Vector2(12, 0), Color("#7ee0c0", 0.6), 3.0)
					draw_line(p + Vector2(12, 0), p + Vector2(4, -6), Color("#7ee0c0", 0.6), 2.0)
			"heal":
				draw_rect(Rect2(z.pos.x - 6, z.pos.y - 20, 12, 40), Color("#ffe08a", 0.6))
				draw_rect(Rect2(z.pos.x - 20, z.pos.y - 6, 40, 12), Color("#ffe08a", 0.6))
			"void":
				for i in range(3):
					draw_arc(z.pos, float(z.r) * (0.3 + i * 0.2), float(z.t) + i, float(z.t) + i + 3.6, 20, Color("#b388ff", 0.35), 2.0)

func draw_obstacles() -> void:
	for o in obstacles:
		var r: float = o.r
		match str(o.kind):
			"trees":
				draw_rect(Rect2(o.pos.x - 6, o.pos.y, 12, r * 1.4), Color("#5a3a1a"))
				draw_circle(o.pos, r, Color("#1d4a2a"))
				draw_circle(o.pos + Vector2(-r * 0.25, -r * 0.25), r * 0.55, Color("#2f7a42"))
			"rocks":
				draw_circle(o.pos + Vector2(0, 6), r * 0.95, Color(0, 0, 0, 0.2))
				var pts := PackedVector2Array()
				for k in range(6):
					var a := float(k) * TAU / 6.0 + 0.3
					pts.append(o.pos + Vector2(cos(a), sin(a)) * r)
				draw_colored_polygon(pts, Color("#5a5a68"))
				draw_circle(o.pos + Vector2(-r * 0.2, -r * 0.2), r * 0.4, Color("#787888"))
			"crystals":
				var pts2 := PackedVector2Array([
					o.pos + Vector2(0, -r * 1.4), o.pos + Vector2(r * 0.8, r * 0.5), o.pos + Vector2(-r * 0.8, r * 0.5)
				])
				draw_colored_polygon(pts2, Color("#2f7a8a"))
				draw_colored_polygon(PackedVector2Array([
					o.pos + Vector2(0, -r * 1.4), o.pos + Vector2(r * 0.35, r * 0.1), o.pos + Vector2(-r * 0.1, r * 0.2)
				]), Color("#6fe3ff", 0.8))
				draw_circle(o.pos, r * 0.9, Color("#6fe3ff", 0.08))
			"pillars":
				draw_circle(o.pos + Vector2(0, r * 0.4), r, Color(0, 0, 0, 0.22))
				draw_circle(o.pos, r, Color("#4a3a2a"))
				draw_circle(o.pos, r * 0.82, Color("#6b5540"))
				draw_arc(o.pos, r * 0.82, 0, TAU, 24, Color("#9a7a5a"), 2.0, true)

func draw_weather() -> void:
	var wn := str(level_data.get("weather", "none"))
	if wn == "none":
		return
	for w in weather_parts:
		var ppos: Vector2 = w.pos
		var a: float = w.a
		match wn:
			"rain":
				draw_line(ppos, ppos + Vector2(-5, 14), Color(0.6, 0.75, 1.0, a), 1.4)
			"snow":
				draw_circle(ppos, 2.0, Color(1, 1, 1, a))
			"sand":
				draw_line(ppos, ppos + Vector2(-16, 4), Color(0.9, 0.75, 0.4, a * 0.8), 1.2)
			"embers":
				draw_circle(ppos, 2.4, Color(1.0, 0.55, 0.2, a))
			"fog":
				draw_circle(ppos, 46.0, Color(0.7, 0.78, 0.9, 0.035))

func draw_darkness() -> void:
	var cx: float = p.pos.x
	var cy: float = p.pos.y
	var w2 := 250.0
	var h2 := 170.0
	var dark := Color(0.01, 0.01, 0.03, 0.78)
	draw_rect(Rect2(0, 0, W, maxf(0, cy - h2)), dark)
	draw_rect(Rect2(0, cy + h2, W, max(0.0, H - (cy + h2))), dark)
	draw_rect(Rect2(0, cy - h2, maxf(0, cx - w2), h2 * 2.0), dark)
	draw_rect(Rect2(cx + w2, cy - h2, maxf(0, W - (cx + w2)), h2 * 2.0), dark)
	for i in range(4):
		draw_circle(p.pos, 190.0 + i * 46.0, Color(0.6, 0.7, 1.0, 0.018))

func draw_gems(so: Vector2) -> void:
	for g in gems:
		var pos: Vector2 = g.pos + so
		var pulse: float = 1.0 + 0.15 * sin(float(g.t) * 6.0)
		draw_circle(pos, 10.0 * pulse, Color(0.33, 0.9, 0.75, 0.12))
		draw_colored_polygon(PackedVector2Array([
			pos + Vector2(0, -8), pos + Vector2(8, 0), pos + Vector2(0, 8), pos + Vector2(-8, 0)
		]), Color("#54e6c0"))
		draw_colored_polygon(PackedVector2Array([
			pos + Vector2(0, -8), pos + Vector2(4, -3), pos + Vector2(-1, -1)
		]), Color(0.78, 1.0, 0.94, 0.9))

func draw_pickups(so: Vector2) -> void:
	for q in pickups:
		var pos: Vector2 = q.pos + so
		var bob := sin(float(q.t) * 4.0) * 3.0
		match str(q.type):
			"heart":
				draw_circle(pos, 13, Color(0.9, 0.25, 0.35, 0.2))
				draw_rect(Rect2(pos.x - 4, pos.y - 12 + bob, 8, 24), Color("#ff5d73"))
				draw_rect(Rect2(pos.x - 12, pos.y - 4 + bob, 24, 8), Color("#ff5d73"))
			"coin":
				draw_circle(pos + Vector2(0, bob), 12, Color("#ffd166", 0.25))
				draw_circle(pos + Vector2(0, bob), 7, Color("#ffd166"))
				draw_circle(pos + Vector2(0, bob), 3, Color("#fff6cc"))
			"chest":
				draw_rect(Rect2(pos.x - 18, pos.y - 12 + bob, 36, 24), Color("#8a5a2a"))
				draw_rect(Rect2(pos.x - 18, pos.y - 12 + bob, 36, 8), Color("#c98b4b"))
				draw_rect(Rect2(pos.x - 4, pos.y - 4 + bob, 8, 10), Color("#ffd166"))
				draw_circle(pos, 26, Color("#ffd166", 0.06))

func draw_enemies(so: Vector2) -> void:
	for e in enemies:
		if e.dead:
			continue
		var pos: Vector2 = e.pos + so
		var rr: float = e.r
		draw_circle(pos + Vector2(0, rr * 0.75), rr * 0.85, Color(0, 0, 0, 0.22))
		if bool(e.get("elite", false)) and str(e.type) != "boss":
			var ec := Color("#ffd166")
			match str(e.get("affix", "")):
				"swift": ec = Color("#7ee0c0")
				"split": ec = Color("#ff9a3a")
				"vamp": ec = Color("#ff5d73")
				"shield": ec = Color("#9fd0ff")
				"giant": ec = Color("#c0a0ff")
			draw_arc(pos, rr + 7.0, elapsed * 2.0, elapsed * 2.0 + TAU, 30, Color(ec, 0.8), 3.0, true)
			draw_arc(pos, rr + 11.0, -elapsed * 1.5, -elapsed * 1.5 + TAU, 30, Color(ec, 0.3), 1.5, true)
		if float(e.get("shield", 0.0)) > 0.0:
			draw_arc(pos, rr + 4.0, 0, TAU, 30, Color(0.6, 0.8, 1.0, 0.6), 2.0, true)
		match str(e.type):
			"slime":
				var col := Color("#43a047")
				if float(e.get("slow_t", 0.0)) > 0.0: col = Color("#5aa8c9")
				if float(e.get("poison_t", 0.0)) > 0.0: col = Color("#78d17a")
				if float(e.get("burn_t", 0.0)) > 0.0: col = Color("#c96a2a")
				draw_circle(pos, rr + 2.0, Color("#0d2410"))
				draw_circle(pos, rr, col)
				draw_circle(pos + Vector2(-rr * 0.24, -rr * 0.32), rr * 0.38, col.lightened(0.35))
				draw_circle(pos + Vector2(-rr * 0.3, rr * 0.12), rr * 0.28, Color("#ffffff"))
				draw_circle(pos + Vector2(rr * 0.3, rr * 0.12), rr * 0.28, Color("#ffffff"))
				draw_circle(pos + Vector2(-rr * 0.28, rr * 0.16), rr * 0.15, Color("#10231c"))
				draw_circle(pos + Vector2(rr * 0.32, rr * 0.16), rr * 0.15, Color("#10231c"))
				draw_circle(pos + Vector2(-rr * 0.28, rr * 0.12), rr * 0.05, Color("#ffffff"))
				draw_arc(pos + Vector2(0, rr * 0.32), rr * 0.22, 0.2, PI - 0.2, 8, Color("#10231c"), 2.0)
				draw_circle(pos + Vector2(-rr * 0.62, rr * 0.3), rr * 0.12, Color(1.0, 0.5, 0.6, 0.35))
				draw_circle(pos + Vector2(rr * 0.62, rr * 0.3), rr * 0.12, Color(1.0, 0.5, 0.6, 0.35))
			"bat":
				draw_colored_polygon(PackedVector2Array([pos, pos + Vector2(-rr * 2.2, -rr * 1.1), pos + Vector2(-rr * 0.6, rr * 0.6)]), Color("#4a2a7a"))
				draw_colored_polygon(PackedVector2Array([pos, pos + Vector2(-rr * 1.6, -rr * 0.55), pos + Vector2(-rr * 0.45, rr * 0.35)]), Color("#6a3fa0"))
				draw_colored_polygon(PackedVector2Array([pos, pos + Vector2(rr * 2.2, -rr * 1.1), pos + Vector2(rr * 0.6, rr * 0.6)]), Color("#4a2a7a"))
				draw_colored_polygon(PackedVector2Array([pos, pos + Vector2(rr * 1.6, -rr * 0.55), pos + Vector2(rr * 0.45, rr * 0.35)]), Color("#6a3fa0"))
				draw_circle(pos, rr * 0.95, Color("#1a1030"))
				draw_circle(pos, rr * 0.82, Color("#8e5bd0"))
				draw_circle(pos + Vector2(-rr * 0.3, -rr * 0.1), rr * 0.26, Color("#ffffff"))
				draw_circle(pos + Vector2(rr * 0.3, -rr * 0.1), rr * 0.26, Color("#ffffff"))
				draw_circle(pos + Vector2(-rr * 0.28, -rr * 0.08), rr * 0.13, Color("#ff5d73"))
				draw_circle(pos + Vector2(rr * 0.32, -rr * 0.08), rr * 0.13, Color("#ff5d73"))
				draw_colored_polygon(PackedVector2Array([pos + Vector2(-rr * 0.18, rr * 0.28), pos + Vector2(-rr * 0.1, rr * 0.5), pos + Vector2(-rr * 0.02, rr * 0.28)]), Color("#ffffff"))
				draw_colored_polygon(PackedVector2Array([pos + Vector2(rr * 0.18, rr * 0.28), pos + Vector2(rr * 0.1, rr * 0.5), pos + Vector2(rr * 0.02, rr * 0.28)]), Color("#ffffff"))
			"mage":
				draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -rr), pos + Vector2(-rr * 1.3, rr * 1.45), pos + Vector2(rr * 1.3, rr * 1.45)]), Color("#1a1030"))
				draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -rr * 0.95), pos + Vector2(-rr * 1.2, rr * 1.35), pos + Vector2(rr * 1.2, rr * 1.35)]), Color("#2d4fa8"))
				draw_circle(pos + Vector2(0, -rr * 0.55), rr * 0.75, Color("#1a1030"))
				draw_circle(pos + Vector2(0, -rr * 0.55), rr * 0.65, Color("#9fd0ff"))
				draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -rr * 1.9), pos + Vector2(-rr * 1.35, -rr * 0.95), pos + Vector2(rr * 1.35, -rr * 0.95)]), Color("#12103a"))
				draw_circle(pos + Vector2(-rr * 0.24, -rr * 0.55), rr * 0.2, Color("#ffffff"))
				draw_circle(pos + Vector2(rr * 0.24, -rr * 0.55), rr * 0.2, Color("#ffffff"))
				draw_circle(pos + Vector2(-rr * 0.22, -rr * 0.52), rr * 0.1, Color("#08203f"))
				draw_circle(pos + Vector2(rr * 0.26, -rr * 0.52), rr * 0.1, Color("#08203f"))
				draw_circle(pos + Vector2(rr * 0.9, rr * 0.5), rr * 0.25, Color(0.6, 0.8, 1.0, 0.25))
			"boss":
				var bk: int = int(e.get("boss_kind", 0))
				var bc := Color("#7c1d1d")
				var bc2 := Color("#b02b2b")
				match bk:
					1: bc = Color("#2a1a5a"); bc2 = Color("#4a2f8a")
					2: bc = Color("#5a2a0a"); bc2 = Color("#8a4a1a")
					3: bc = Color("#2a0a3a"); bc2 = Color("#6a2a8a")
				draw_circle(pos, rr, bc)
				draw_circle(pos, rr * 0.8, bc2)
				draw_colored_polygon(PackedVector2Array([pos + Vector2(-rr * 0.7, -rr * 0.7), pos + Vector2(-rr * 0.95, -rr * 1.25), pos + Vector2(-rr * 0.35, -rr * 0.95)]), bc.darkened(0.4))
				draw_colored_polygon(PackedVector2Array([pos + Vector2(rr * 0.7, -rr * 0.7), pos + Vector2(rr * 0.95, -rr * 1.25), pos + Vector2(rr * 0.35, -rr * 0.95)]), bc.darkened(0.4))
				draw_circle(pos + Vector2(-rr * 0.32, -rr * 0.15), rr * 0.15, Color("#ffca3a"))
				draw_circle(pos + Vector2(rr * 0.32, -rr * 0.15), rr * 0.15, Color("#ffca3a"))
				draw_circle(pos + Vector2(-rr * 0.32, -rr * 0.15), rr * 0.07, Color("#220505"))
				draw_circle(pos + Vector2(rr * 0.32, -rr * 0.15), rr * 0.07, Color("#220505"))
				draw_arc(pos + Vector2(0, rr * 0.28), rr * 0.4, 0.15 * PI, 0.85 * PI, 8, Color("#2a0606"), 4.0)
		if e.flash > 0.0:
			draw_circle(pos, rr + 1.0, Color(1, 1, 1, 0.8))
		if freeze_t > 0.0:
			draw_circle(pos, rr + 3.0, Color(0.6, 0.9, 1.0, 0.28))
			draw_arc(pos, rr + 5.0, 0, TAU, 20, Color(0.8, 0.95, 1.0, 0.5), 2.0, true)
		if bool(e.get("elite", false)):
			draw_string(font, pos + Vector2(-20, -rr - 16), str(e.get("affix", "")), HORIZONTAL_ALIGNMENT_CENTER, 40, 13, Color("#ffd166", 0.9))

func draw_wolves(so: Vector2) -> void:
	for w in wolves:
		var pos: Vector2 = w.pos + so
		draw_circle(pos + Vector2(0, 8), 12, Color(0, 0, 0, 0.2))
		draw_circle(pos, 11, Color("#8a6a3a"))
		draw_circle(pos + Vector2(0, -8), 7, Color("#b08a5a"))
		draw_colored_polygon(PackedVector2Array([pos + Vector2(-7, -12), pos + Vector2(-3, -20), pos + Vector2(0, -12)]), Color("#b08a5a"))
		draw_colored_polygon(PackedVector2Array([pos + Vector2(7, -12), pos + Vector2(3, -20), pos + Vector2(0, -12)]), Color("#b08a5a"))
		draw_circle(pos + Vector2(-2, -9), 1.4, Color("#1a1208"))
		draw_circle(pos + Vector2(2, -9), 1.4, Color("#1a1208"))

func draw_vortices(so: Vector2) -> void:
	for v in vortices:
		var pos: Vector2 = v.pos + so
		var k: float = clampf(float(v.t) / float(v.dur), 0.0, 1.0)
		var r: float = float(v.r)
		draw_circle(pos, r, Color(0.25, 0.08, 0.42, 0.15 + 0.1 * (1.0 - k)))
		for i in range(5):
			var a := float(v.t) * (1.5 + i * 0.3) + float(i) * 1.2
			draw_arc(pos, r * (0.2 + i * 0.16), a, a + 2.6, 18, Color(0.7, 0.45, 1.0, 0.55), 3.0, true)
		draw_circle(pos, 14.0, Color(0.02, 0.0, 0.05, 0.85))

func draw_dragons(so: Vector2) -> void:
	for dg in dragons:
		var pos: Vector2 = dg.pos + so
		var flap := sin(elapsed * 6.0) * 8.0
		draw_colored_polygon(PackedVector2Array([pos + Vector2(-20, 0), pos + Vector2(-70, -40 + flap), pos + Vector2(-50, 15)]), Color("#8a2a12", 0.9))
		draw_colored_polygon(PackedVector2Array([pos + Vector2(20, 0), pos + Vector2(70, -40 + flap), pos + Vector2(50, 15)]), Color("#8a2a12", 0.9))
		draw_circle(pos, 30.0, Color("#b02b2b"))
		draw_circle(pos + Vector2(0, -6), 20.0, Color("#e05a2a"))
		draw_circle(pos + Vector2(-8, -12), 4.0, Color("#ffd166"))
		draw_circle(pos + Vector2(8, -12), 4.0, Color("#ffd166"))
		draw_circle(pos + Vector2(-8, -12), 1.8, Color("#2a0606"))
		draw_circle(pos + Vector2(8, -12), 1.8, Color("#2a0606"))
		draw_colored_polygon(PackedVector2Array([pos + Vector2(-16, 10), pos + Vector2(0, 24), pos + Vector2(16, 10)]), Color("#ff8a3a", 0.4))

func draw_clones(so: Vector2) -> void:
	for c in clones:
		var pos: Vector2 = c.pos + so
		draw_circle(pos, 16.0, Color(0.4, 0.95, 0.75, 0.18))
		draw_circle(pos, 12.0, Color("#7ee0c0", 0.55))
		draw_circle(pos + Vector2(-3, -2), 2.0, Color("#ffffff"))
		draw_circle(pos + Vector2(3, -2), 2.0, Color("#ffffff"))
		draw_arc(pos, 17.0, elapsed * 3.0, elapsed * 3.0 + TAU, 20, Color("#7ee0c0", 0.5), 1.5, true)

func draw_slashes(so: Vector2) -> void:
	for s in slashes:
		var pos: Vector2 = s.pos + so
		var k: float = clampf(float(s.t) / float(s.dur), 0.0, 1.0)
		var a: float = 1.0 - k
		var aim: float = float(s.aim)
		var arc: float = float(s.arc)
		var reach: float = float(s.range)
		var col: Color = s.color
		if str(s.special) == "spear":
			var dir := Vector2(cos(aim), sin(aim))
			draw_line(pos, pos + dir * reach, Color(col, a), 6.0 * a + 1.0)
			draw_line(pos, pos + dir * reach * 0.7, Color(1, 1, 1, a * 0.8), 2.0)
		else:
			var radius: float = reach * (0.55 + 0.45 * k)
			draw_arc(pos, radius, aim - arc * 0.5, aim + arc * 0.5, 32, Color(col, a * 0.9), 8.0 * a + 1.5, true)
			draw_arc(pos, radius * 0.82, aim - arc * 0.5, aim + arc * 0.5, 32, Color(1, 1, 1, a * 0.5), 3.0 * a + 1.0, true)
		if str(s.special) == "slam":
			draw_circle(pos + Vector2(cos(aim), sin(aim)) * reach * 0.6, 30.0 * (0.5 + k), Color("#ff8a3a", a * 0.25))

func draw_player(so: Vector2) -> void:
	var pos: Vector2 = p.pos + so
	draw_skin_char(pos, current_skin, 1.0, last_aim)
	var melee := str(current_weapon.get("kind", "ranged")) == "melee"
	var wid := str(current_weapon.get("id", ""))
	var staff := wid in ["firestaff", "froststaff", "stormstaff", "voidstaff", "tome", "bonestaff", "beaststaff", "soulbell"]
	if melee:
		var dir := Vector2(cos(last_aim), sin(last_aim))
		_draw_weapon_icon(current_weapon, pos + dir * 24.0, 0.65)
		draw_line(pos + dir * 10.0, pos + dir * 40.0, Color(weapon_color, 0.35), 2.0)
	elif staff:
		var dir2 := Vector2(cos(last_aim), sin(last_aim))
		var hand := pos + dir2 * 22.0
		_draw_weapon_icon(current_weapon, hand, 0.70)
		draw_circle(hand, 15.0, Color(weapon_color, 0.10))
		draw_arc(hand, 16.0, elapsed * 2.0, elapsed * 2.0 + TAU, 24, Color(weapon_color, 0.55), 2.0, true)
	else:
		# 弓
		var bc := pos + Vector2(cos(last_aim), sin(last_aim)) * 10.0
		var a0 := last_aim - 0.42 * PI
		var a1 := last_aim + 0.42 * PI
		draw_arc(bc, 22.0, a0, a1, 14, Color("#d9a066"), 4.0, true)
		var q0 := bc + Vector2(cos(a0), sin(a0)) * 22.0
		var q1 := bc + Vector2(cos(a1), sin(a1)) * 22.0
		draw_line(q0, q1, Color(0.96, 0.94, 0.9, 0.85), 1.2)
	if invuln > 0.0:
		draw_arc(pos, 26.0, 0, TAU, 30, Color(0.7, 0.9, 1.0, 0.35 + 0.2 * sin(elapsed * 20.0)), 2.0, true)
	if p.shield > 0.0:
		draw_arc(pos, 30.0, elapsed, elapsed + TAU, 40, Color(0.5, 0.8, 1.0, 0.45), 3.0, true)
	if p.dash_t > 0.0:
		draw_circle(pos, 20, Color(0.5, 0.9, 0.78, 0.25))

func draw_skin_char(pos: Vector2, sk: Dictionary, s: float, aim: float) -> void:
	if sk.is_empty():
		return
	var glow := str(sk.get("glow", ""))
	if glow != "":
		var gc := Color(glow)
		gc.a = 0.10
		draw_circle(pos, 30.0 * s, gc)
	draw_circle(pos + Vector2(0, 15 * s), 16 * s, Color(0.04, 0.02, 0.1, 0.35))
	var cloak := Color(str(sk.cloak))
	var body := Color(str(sk.body))
	var eye := Color(str(sk.eye))
	# 披风 / 轮廓
	draw_arc(pos, 22 * s, aim + PI * 0.55, aim + PI * 1.45, 20, cloak, 8 * s, true)
	draw_circle(pos, 19.5 * s, Color("#1a1030"))
	draw_circle(pos, 18 * s, cloak)
	# 头 / 身体
	draw_circle(pos, 16.5 * s, body)
	var face := body.lightened(0.42)
	draw_circle(pos + Vector2(0, 2.2 * s), 12.2 * s, face)
	# 头发
	var hair := cloak.lightened(0.18)
	draw_arc(pos + Vector2(0, -1 * s), 14.8 * s, PI * 1.03, PI * 1.97, 18, hair, 6.5 * s, true)
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-13.5, -2) * s, pos + Vector2(-5, -7) * s, pos + Vector2(-2, 1) * s
	]), hair)
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(13.5, -2) * s, pos + Vector2(5, -7) * s, pos + Vector2(2, 1) * s
	]), hair)
	# 大眼 + 高光
	draw_circle(pos + Vector2(-4.2, 1.2) * s, 3.8 * s, Color("#ffffff"))
	draw_circle(pos + Vector2(4.2, 1.2) * s, 3.8 * s, Color("#ffffff"))
	draw_circle(pos + Vector2(-4.2, 1.6) * s, 2.6 * s, eye)
	draw_circle(pos + Vector2(4.2, 1.6) * s, 2.6 * s, eye)
	draw_circle(pos + Vector2(-5.1, 0.6) * s, 1.1 * s, Color("#ffffff"))
	draw_circle(pos + Vector2(3.3, 0.6) * s, 1.1 * s, Color("#ffffff"))
	draw_circle(pos + Vector2(-7.5, 6.5) * s, 2.2 * s, Color(1.0, 0.55, 0.68, 0.35))
	draw_circle(pos + Vector2(7.5, 6.5) * s, 2.2 * s, Color(1.0, 0.55, 0.68, 0.35))
	draw_line(pos + Vector2(-2.4, 8.5) * s, pos + Vector2(2.4, 8.5) * s, eye, 1.3)
	# 围巾
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-10, 11) * s, pos + Vector2(9, 11) * s, pos + Vector2(6, 16) * s, pos + Vector2(-7, 16) * s
	]), body.lightened(0.15))
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(8, 13) * s, pos + Vector2(15, 19) * s, pos + Vector2(6, 18) * s
	]), body.lightened(0.25))
	var hat := str(sk.hat)
	match hat:
		"hood":
			draw_arc(pos, 17 * s, PI * 1.05, PI * 1.95, 16, cloak.lightened(0.12), 6 * s, true)
		"horns":
			draw_colored_polygon(PackedVector2Array([pos + Vector2(-12 * s, -10 * s), pos + Vector2(-17 * s, -26 * s), pos + Vector2(-6 * s, -15 * s)]), Color("#f2f2e8"))
			draw_colored_polygon(PackedVector2Array([pos + Vector2(12 * s, -10 * s), pos + Vector2(17 * s, -26 * s), pos + Vector2(6 * s, -15 * s)]), Color("#f2f2e8"))
		"helm":
			draw_rect(Rect2(pos.x - 13 * s, pos.y - 23 * s, 26 * s, 10 * s), Color("#9aa7b8"))
			draw_rect(Rect2(pos.x - 13 * s, pos.y - 15 * s, 26 * s, 4 * s), Color("#6d7f9c"))
		"halo":
			draw_arc(pos + Vector2(0, -28 * s), 10 * s, 0, TAU, 20, Color("#ffe9a8"), 3 * s, true)
		"crown":
			for i in range(3):
				var bx := (-8 + i * 8) * s
				draw_colored_polygon(PackedVector2Array([
					pos + Vector2(bx - 4 * s, -17 * s), pos + Vector2(bx, -30 * s), pos + Vector2(bx + 4 * s, -17 * s)
				]), Color("#ffd166"))
		"ears":
			draw_colored_polygon(PackedVector2Array([pos + Vector2(-12 * s, -12 * s), pos + Vector2(-10 * s, -28 * s), pos + Vector2(-2 * s, -16 * s)]), body)
			draw_colored_polygon(PackedVector2Array([pos + Vector2(12 * s, -12 * s), pos + Vector2(10 * s, -28 * s), pos + Vector2(2 * s, -16 * s)]), body)
		"antenna":
			draw_line(pos + Vector2(0, -16 * s), pos + Vector2(0, -30 * s), Color("#dbe9ff"), 2 * s)
			draw_circle(pos + Vector2(0, -32 * s), 3.4 * s, Color("#ffe08a"))
		"wings":
			draw_arc(pos + Vector2(-16 * s, 0), 14 * s, PI * 0.4, PI * 1.5, 16, Color("#e8f0ff", 0.8), 3 * s, true)
			draw_arc(pos + Vector2(16 * s, 0), 14 * s, -PI * 0.5, PI * 0.6, 16, Color("#e8f0ff", 0.8), 3 * s, true)
		"tail":
			draw_line(pos + Vector2(0, 14 * s), pos + Vector2(-14 * s, 24 * s), cloak, 4 * s)
			draw_line(pos + Vector2(-14 * s, 24 * s), pos + Vector2(-20 * s, 16 * s), body, 3 * s)
		"flame":
			for i in range(3):
				var fx := (-6 + i * 6) * s
				draw_colored_polygon(PackedVector2Array([
					pos + Vector2(fx - 4 * s, -16 * s), pos + Vector2(fx, -32 * s - i * 2 * s), pos + Vector2(fx + 4 * s, -16 * s)
				]), Color("#ff8a3a", 0.85))
		"mask":
			draw_rect(Rect2(pos.x - 15 * s, pos.y - 1 * s, 30 * s, 7 * s), Color("#3a2a1a", 0.9))

func draw_arrows(so: Vector2) -> void:
	var trail_style := str(fx_trail_data.get("style", "rainbow"))
	for a in arrows:
		var pos: Vector2 = a.pos + so
		var dir: Vector2 = a.vel.normalized()
		if bool(a.get("spell", false)):
			var ac: Color = a.color
			for j in range(4):
				draw_circle(pos - dir * (4.0 + j * 7.0), 7.0 - j * 1.2, Color(ac, 0.35 - j * 0.08))
			draw_circle(pos, 10.0, Color(ac, 0.18))
			draw_circle(pos, 6.0, ac)
			draw_circle(pos, 2.6, Color("#ffffff"))
			if bool(a.crit):
				draw_circle(pos, 12.0, Color(1.0, 0.88, 0.4, 0.25))
			continue
		if trail_style == "rainbow":
			for j in range(4):
				var pj: Vector2 = pos - dir * (5.0 + j * 6.0)
				var c := Color.from_hsv(fmod(elapsed * 0.6 + float(j) * 0.09, 1.0), 0.75, 1.0)
				c.a = 0.75 - float(j) * 0.16
				draw_line(pj - dir * 5.0, pj, c, 3.0)
		elif trail_style == "ghost":
			for j in range(3):
				var pj2: Vector2 = pos - dir * (8.0 + j * 10.0)
				draw_line(pj2 - dir * 10.0, pj2, Color(0.8, 0.85, 1.0, 0.3 - j * 0.08), 4.0)
		else:
			var tail := pos - dir * 20.0
			draw_line(tail, pos, Color(a.color, 0.85), 3.0)
		var col: Color = a.color
		var perp := Vector2(-dir.y, dir.x)
		var tip := pos + dir * 8.0
		draw_colored_polygon(PackedVector2Array([tip, pos + perp * 4.0, pos - perp * 4.0]), col)
		if bool(a.crit):
			draw_circle(pos, 5.0, Color(1.0, 0.88, 0.4, 0.5))
		if bool(a.homing):
			draw_circle(pos, 8.0, Color(0.4, 0.9, 1.0, 0.15))
		if bool(a.boomerang):
			draw_arc(pos, 10.0, float(a.spin), float(a.spin) + PI * 1.5, 12, Color("#f2c94c", 0.8), 2.0)

func draw_orbs(so: Vector2) -> void:
	for o in orbs:
		var pos: Vector2 = o.pos + so
		var rr: float = o.r
		draw_circle(pos, rr + 4.0, Color(0.2, 0.42, 0.95, 0.18))
		draw_circle(pos, rr, Color(0.36, 0.61, 0.95, 0.88))
		draw_circle(pos, rr * 0.45, Color("#dbeaff"))

func draw_zaps(so: Vector2) -> void:
	for z in zaps:
		var a: Vector2 = z.a + so
		var b: Vector2 = z.b + so
		var mid := (a + b) * 0.5 + Vector2(rng.randf_range(-12, 12), rng.randf_range(-12, 12))
		draw_polyline(PackedVector2Array([a, mid, b]), Color(0.76, 0.65, 1.0, float(z.t) / float(z.max)), 2.5)

func draw_strikes() -> void:
	for s in strikes:
		var ppos: Vector2 = s.pos
		if not bool(s.done):
			var k: float = 1.0 - float(s.t) / 0.9
			draw_circle(ppos, float(s.r), Color(1.0, 0.3, 0.2, 0.10 + 0.12 * k))
			draw_arc(ppos, float(s.r) * (0.4 + 0.6 * k), 0, TAU, 30, Color(1.0, 0.6, 0.3, 0.7), 2.0, true)
			if str(s.kind) == "meteor":
				var fall := clampf(k, 0.0, 1.0)
				var rock := ppos + Vector2(0, -300.0 * (1.0 - fall))
				draw_circle(rock, 20.0, Color("#7a3a1a"))
				draw_circle(rock + Vector2(-4, -4), 12.0, Color("#ff6b35"))
				draw_line(rock + Vector2(0, -10), rock + Vector2(0, -80), Color(1.0, 0.5, 0.2, 0.4), 5.0)
		else:
			draw_circle(ppos, float(s.r) * 0.7, Color(1.0, 0.9, 0.5, 0.35))
			if str(s.kind) == "bolt":
				draw_polyline(PackedVector2Array([ppos + Vector2(0, -260), ppos + Vector2(-14, -170), ppos + Vector2(8, -120), ppos + Vector2(-8, -50), ppos]), Color(1, 1, 1, 0.85), 3.0)
			elif str(s.kind) == "meteor":
				draw_circle(ppos, 26.0, Color(1.0, 0.55, 0.2, 0.5))
				for i in range(6):
					var a := float(i) * TAU / 6.0
					draw_line(ppos + Vector2(cos(a), sin(a)) * 12.0, ppos + Vector2(cos(a), sin(a)) * 40.0, Color("#ffd166", 0.6), 3.0)

func draw_particles(so: Vector2) -> void:
	for q in particles:
		var a: float = clampf(q.life / q.max_life, 0.0, 1.0)
		var c: Color = q.col
		c.a *= a
		draw_circle(q.pos + so, q.r * (0.5 + a * 0.5), c)

func draw_floaters(so: Vector2) -> void:
	for f in floaters:
		var a: float = clampf(f.life / f.max_life, 0.0, 1.0)
		var c: Color = f.col
		c.a = a
		draw_string(font, f.pos + so + Vector2(-50, 0), f.text, HORIZONTAL_ALIGNMENT_CENTER, 100, 20, c)

func draw_fxs(so: Vector2) -> void:
	for f in fxs:
		_draw_fx(f, so)

func _draw_fx(f: Dictionary, so: Vector2) -> void:
	var pos: Vector2 = f.pos + so
	var k: float = clampf(float(f.t) / float(f.dur), 0.0, 1.0)
	var alpha: float = 1.0 - k
	var c1: Color = f.c1
	var c2: Color = f.c2
	c1.a *= alpha
	c2.a *= alpha
	var s: float = f.scale
	match str(f.style):
		"spark":
			for i in range(6):
				var a := float(i) * TAU / 6.0 + 0.3
				var d := (10.0 + 26.0 * k) * s
				draw_line(pos, pos + Vector2(cos(a), sin(a)) * d, c1, 2.0)
		"star":
			var pts := PackedVector2Array()
			for i in range(10):
				var a := float(i) * TAU / 10.0 - PI * 0.5
				var rad := (22.0 if i % 2 == 0 else 9.0) * (0.5 + k) * s
				pts.append(pos + Vector2(cos(a), sin(a)) * rad)
			draw_colored_polygon(pts, c1)
		"ring":
			draw_arc(pos, (8.0 + 38.0 * k) * s, 0, TAU, 32, c1, 3.0, true)
			draw_arc(pos, (4.0 + 20.0 * k) * s, 0, TAU, 24, c2, 1.5, true)
		"cross":
			draw_line(pos + Vector2(-24 * k * s, 0), pos + Vector2(24 * k * s, 0), c1, 3.0)
			draw_line(pos + Vector2(0, -24 * k * s), pos + Vector2(0, 24 * k * s), c2, 3.0)
		"bolt":
			var pts2 := PackedVector2Array([pos + Vector2(-18, -14) * s])
			pts2.append(pos + Vector2(-4, -2) * s)
			pts2.append(pos + Vector2(-10, 2) * s)
			pts2.append(pos + Vector2(14, 16) * s)
			draw_polyline(pts2, c1, 3.0)
		"petal":
			for i in range(6):
				var a := float(i) * TAU / 6.0 + k * 2.0
				draw_circle(pos + Vector2(cos(a), sin(a)) * 20.0 * k * s, 4.0 * s * (1.0 - k * 0.4), c1 if i % 2 == 0 else c2)
		"pixel":
			for i in range(6):
				var a := float(i) * TAU / 6.0
				var pp := pos + Vector2(cos(a), sin(a)) * 26.0 * k * s
				draw_rect(Rect2(pp.x - 3, pp.y - 3, 6, 6), c1 if i % 2 == 0 else c2)
		"blood":
			for i in range(6):
				var a := float(i) * TAU / 6.0
				var pp := pos + Vector2(cos(a), sin(a)) * 20.0 * k * s + Vector2(0, 18.0 * k * k)
				draw_circle(pp, 3.5 * s, c1)
		"ice":
			for i in range(5):
				var a := float(i) * TAU / 5.0 + 0.4
				var d := 18.0 * k * s
				var pp := pos + Vector2(cos(a), sin(a)) * d
				var perp := Vector2(-sin(a), cos(a)) * 4.0 * s
				draw_colored_polygon(PackedVector2Array([pp + Vector2(cos(a), sin(a)) * 8 * s, pp + perp, pp - perp]), c1)
		"flame":
			for i in range(5):
				var pp := pos + Vector2((float(i) - 2.0) * 7.0 * s, -18.0 * k * s - float(i % 2) * 6.0)
				draw_circle(pp, (5.0 - k * 2.0) * s, c1 if i % 2 == 0 else c2)
		"burst":
			for i in range(10):
				var a := float(i) * TAU / 10.0
				draw_line(pos + Vector2(cos(a), sin(a)) * 6.0 * s, pos + Vector2(cos(a), sin(a)) * (14.0 + 36.0 * k) * s, c1, 2.0)
			draw_circle(pos, (10.0 + 18.0 * k) * s, Color(c2, alpha * 0.25))
		"smoke":
			for i in range(6):
				var a := float(i) * TAU / 6.0 + 0.6
				draw_circle(pos + Vector2(cos(a), sin(a)) * (10.0 + 26.0 * k) * s, (10.0 + 16.0 * k) * s, Color(c1, alpha * 0.3))
		"shard":
			for i in range(8):
				var a := float(i) * TAU / 8.0 + k * 1.4
				var d := (8.0 + 40.0 * k) * s
				var pp := pos + Vector2(cos(a), sin(a)) * d
				var perp := Vector2(-sin(a), cos(a)) * 5.0 * s
				draw_colored_polygon(PackedVector2Array([pp + Vector2(cos(a), sin(a)) * 8 * s, pp + perp, pp - perp]), c1 if i % 2 == 0 else c2)
		"halo":
			draw_arc(pos, (16.0 + 44.0 * k) * s, 0, TAU, 36, c1, 3.0, true)
			draw_arc(pos, (8.0 + 24.0 * k) * s, 0, TAU, 24, c2, 2.0, true)
		"skull":
			var sc := (1.0 - k * 0.4) * s
			draw_circle(pos, 16.0 * sc, c1)
			draw_circle(pos + Vector2(-6, -2) * sc, 4.0 * sc, Color(0.05, 0.05, 0.08, alpha))
			draw_circle(pos + Vector2(6, -2) * sc, 4.0 * sc, Color(0.05, 0.05, 0.08, alpha))
			draw_rect(Rect2(pos.x - 7 * sc, pos.y + 8 * sc, 14 * sc, 7 * sc), c1)
			draw_rect(Rect2(pos.x - 10 * sc, pos.y + 8 * sc, 20 * sc, 2 * sc), c2)
		"pillar":
			draw_rect(Rect2(pos.x - 34 * s, pos.y - 420 * s, 68 * s, 420 * s), Color(c1, alpha * 0.20))
			draw_rect(Rect2(pos.x - 12 * s, pos.y - 420 * s, 24 * s, 420 * s), Color(c2, alpha * 0.35))
		"rune":
			for i in range(3):
				draw_arc(pos, (34.0 + i * 12.0 + 14.0 * k) * s, float(f.t) * (1.5 + i * 0.4) + float(i), float(f.t) * (1.5 + i * 0.4) + float(i) + 4.2, 18, c1 if i % 2 == 0 else c2, 2.0, true)
		"shockwave":
			for i in range(3):
				draw_arc(pos, (20.0 + 60.0 * k + i * 16.0) * s, 0, TAU, 40, c1 if i % 2 == 0 else c2, 3.0, true)

# ============================================================ HUD
func draw_hud() -> void:
	_rrect(Rect2(12, 12, 350, 96), Color(0.05, 0.04, 0.12, 0.55), 14)
	# 左上：等级 + 血条
	draw_string(font, Vector2(24, 38), "Lv." + str(level), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#ffe6ff"))
	var ratio: float = clampf(float(p.hp) / float(p.max_hp), 0.0, 1.0)
	_rrect(Rect2(24, 50, 300, 18), Color("#2a1a3a"), 9)
	var hpc := Color("#39d98a") if ratio > 0.5 else (Color("#f5b942") if ratio > 0.25 else Color("#ff5d73"))
	if ratio > 0.0:
		_rrect(Rect2(26, 52, 296 * ratio, 14), hpc, 7)
	draw_line(Vector2(34, 55), Vector2(34 + 260 * ratio, 55), Color(1, 1, 1, 0.25), 2.0)
	if p.shield > 0.0 and p.shield_max > 0.0:
		_rrect(Rect2(24, 72, 300 * clampf(p.shield / p.shield_max, 0.0, 1.0), 5), Color("#6fb6ff"), 3)
	draw_string(font, Vector2(330, 66), str(int(ceil(p.hp))) + "/" + str(int(p.max_hp)), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#dbe9ff"))
	# 左下：击杀 / 金币 / 连击
	draw_string(font, Vector2(24, 108), "击杀 " + str(kills), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#ffd166"))
	draw_string(font, Vector2(24, 132), "金币 " + str(gold), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#ffe08a"))
	if combo >= 3:
		draw_string(font, Vector2(24, 156), "连击 x" + str(combo), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#ff9a3a"))
	# 中上：时间 / 波次关卡
	var m := int(elapsed / 60.0)
	var sec := int(elapsed) % 60
	var ts := (str(m) if m >= 10 else "0" + str(m)) + ":" + (str(sec) if sec >= 10 else "0" + str(sec))
	_outline_text(ts, W * 0.5, 48, 34, Color("#eaf6ff"))
	var lvl_name := str(level_data.get("n", ""))
	draw_string(font, Vector2(W * 0.5 - 240, 78), "第 %d 关 · %s · 第 %d/%d 波" % [level_idx + 1, lvl_name, wave_in_level, LEVEL_WAVES], HORIZONTAL_ALIGNMENT_CENTER, 480, 17, Color("#b8c8ff"))
	if wave_affix != "":
		draw_string(font, Vector2(W * 0.5 - 200, 96), "词缀 · " + _affix_name(wave_affix), HORIZONTAL_ALIGNMENT_CENTER, 400, 14, Color("#ff9a3a"))
	# 右上：按钮
	_rrect(PAUSE_RECT, Color(0.08, 0.06, 0.18, 0.8), 12)
	draw_string(font, PAUSE_RECT.position + Vector2(15, 33), "II", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#c9b8ff"))
	_rrect(SHOP_BTN, Color(0.08, 0.06, 0.18, 0.8), 12)
	draw_string(font, SHOP_BTN.position + Vector2(9, 34), "$", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#ffd166"))
	# 右下：冲刺
	var dc := Color("#7ee0c0") if p.dash_cd <= 0.0 else Color("#3a4a5c")
	draw_circle(DASH_RECT.get_center(), 45, Color(0.3, 0.9, 0.8, 0.08))
	draw_circle(DASH_RECT.get_center(), 40, Color(0.08, 0.06, 0.18, 0.75))
	draw_arc(DASH_RECT.get_center(), 40, 0, TAU, 36, dc, 3.0, true)
	if p.dash_cd > 0.0:
		var frac: float = clampf(1.0 - p.dash_cd / p.dash_cd_max, 0.0, 1.0)
		draw_arc(DASH_RECT.get_center(), 40, -PI * 0.5, -PI * 0.5 + TAU * frac, 36, Color("#7ee0c0"), 5.0, true)
	draw_string(font, DASH_RECT.position + Vector2(20, 52), "冲", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, dc)
	# 底部经验条
	draw_rect(Rect2(0, H - 14, W, 14), Color("#101627"))
	draw_rect(Rect2(0, H - 14, W * clampf(float(xp) / float(xp_need), 0.0, 1.0), 14), Color("#3b82f6"))
	draw_string(font, Vector2(12, H - 18), "EXP " + str(int(xp)) + "/" + str(xp_need), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#7ea4d8"))
	# BOSS 血条
	if boss != null:
		draw_string(font, Vector2(W * 0.5 - 280, 112), boss_name, HORIZONTAL_ALIGNMENT_CENTER, 560, 14, Color("#ff8fa3"))
		draw_rect(Rect2(W * 0.5 - 280, 116, 560, 12), Color("#241016"))
		var br: float = clampf(float(boss.hp) / boss_max_hp, 0.0, 1.0)
		draw_rect(Rect2(W * 0.5 - 278, 118, 556 * br, 8), Color("#ff4d6d"))

func draw_stick() -> void:
	draw_circle(stick_base, 86.0, Color(0.5, 0.9, 0.78, 0.12))
	draw_arc(stick_base, 86.0, 0.0, TAU, 40, Color(0.5, 0.9, 0.78, 0.5), 2.5, true)
	draw_circle(stick_cur, 28.0, Color(0.85, 1.0, 0.95, 0.75))

func draw_banner() -> void:
	if banner_t <= 0.0:
		return
	var a: float = clampf(banner_t / 0.6, 0.0, 1.0)
	var txt := banner_text
	var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
	draw_rect(Rect2(W * 0.5 - w * 0.5 - 24, 166, w + 48, 46), Color(0.03, 0.05, 0.09, 0.72 * a))
	draw_string(font, Vector2(W * 0.5 - w * 0.5, 198), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1, 1, 1, a))

func _draw_toast() -> void:
	if toast_t <= 0.0:
		return
	var a: float = clampf(toast_t / 0.4, 0.0, 1.0)
	var w := font.get_string_size(toast_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	draw_rect(Rect2(W * 0.5 - w * 0.5 - 20, H - 76, w + 40, 40), Color(0.02, 0.03, 0.06, 0.85 * a))
	draw_string(font, Vector2(W * 0.5 - w * 0.5, H - 48), toast_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, a))

# ============================================================ 覆盖层
func draw_levelup() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.03, 0.06, 0.82))
	tc("升级 · 三选一", 170, 34, Color("#8ff0c8"))
	tc("Lv." + str(level) + "　点卡牌 / 按 1 2 3", 200, 17, Color("#6f86a8"))
	for i in range(cards.size()):
		var u = cards[i]
		var r: Rect2 = card_rects[i]
		var cat := str(u.get("cat", "攻击"))
		var cc := Color("#ff8a3a")
		match cat:
			"攻击": cc = Color("#ff8a3a")
			"防御": cc = Color("#6fb6ff")
			"身法": cc = Color("#7ee0c0")
			"功能": cc = Color("#ffd166")
			"元素": cc = Color("#b197fc")
			"召唤": cc = Color("#8ab86a")
			"特殊": cc = Color("#ff5d73")
			"觉醒": cc = Color("#ffe08a")
		_card_bg(r, cc, true)
		draw_string(font, Vector2(r.position.x + 20, r.position.y + 34), "[" + cat + "]", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, cc)
		draw_circle(r.get_center() + Vector2(0, -128), 46, Color(cc, 0.10))
		_draw_skill_icon(str(u.id), r.get_center() + Vector2(0, -128), 1.35)
		tc_at(str(u.n), r.get_center().x, r.position.y + 134, 32, Color("#f0f8ff"))
		tc_at(str(u.d), r.get_center().x, r.position.y + 178, 18, Color("#8fb0d8"))
		tc_at("已选 " + str(int(taken.get(u.id, 0))) + " / " + str(int(u.max)), r.get_center().x, r.position.y + 224, 15, Color("#4c6183"))
		tc_at("点我选择", r.get_center().x, r.position.y + 286, 18, Color("#62f0b6"))

func draw_shop() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.03, 0.06, 0.86))
	draw_string(font, Vector2(52, 64), "技能商店", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color("#eaf7ff"))
	draw_string(font, Vector2(52, 96), "技能 / 传说自动技：陨石、黑洞、巨龙、时间暂停；每 3 波自动开", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#8fb0d8"))
	draw_string(font, Vector2(W - 60, 66), "金币 " + str(gold), HORIZONTAL_ALIGNMENT_RIGHT, 220, 26, Color("#ffd166"))
	for i in range(shop_offers.size()):
		var o = shop_offers[i]
		var r: Rect2 = shop_rects[i]
		var is_ult := str(o.get("kind", "skill")) == "ult"
		var name := ""
		var desc := ""
		var cc := Color("#2f4468")
		var afford := gold >= int(o.price)
		var sub := ""
		var icon_id := ""
		if is_ult:
			var u = UltimatesData.find(str(o.id))
			name = str(u.get("n", o.id))
			desc = str(u.get("d", ""))
			cc = Color("#ffd166")
			sub = "传说 · 自动施放"
			icon_id = str(o.id)
		else:
			var sk = SkillsData.find(str(o.id))
			name = str(sk.get("n", o.id))
			desc = str(sk.get("d", ""))
			sub = str(sk.get("cat", "技能")) + "技能"
			match str(sk.get("cat", "")):
				"攻击": cc = Color("#ff8a3a")
				"防御": cc = Color("#6fb6ff")
				"身法": cc = Color("#7ee0c0")
				"功能": cc = Color("#ffd166")
				"元素": cc = Color("#b197fc")
				"召唤": cc = Color("#8ab86a")
				"特殊": cc = Color("#ff5d73")
				"觉醒": cc = Color("#ffe08a")
			icon_id = str(sk.id)
		_card_bg(r, cc, is_ult)
		draw_circle(r.position + Vector2(64, 92), 40, Color(cc, 0.10))
		if is_ult:
			_draw_ult_icon(icon_id, r.position + Vector2(64, 92), 1.5)
		else:
			_draw_skill_icon(icon_id, r.position + Vector2(64, 92), 1.35)
		draw_string(font, Vector2(r.position.x + 128, r.position.y + 42), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("#f0f8ff"))
		draw_string(font, Vector2(r.position.x + 128, r.position.y + 68), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, cc)
		draw_string(font, Vector2(r.position.x + 128, r.position.y + 100), desc, HORIZONTAL_ALIGNMENT_LEFT, 240, 16, Color("#8fb0d8"))
		if is_ult:
			draw_string(font, Vector2(r.position.x + 128, r.position.y + 132), "一次购买，永久生效", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#9fb3c8"))
		else:
			var sk2 = SkillsData.find(str(o.id))
			var lv := int(taken.get(sk2.id, 0))
			draw_string(font, Vector2(r.position.x + 128, r.position.y + 132), "等级 " + str(lv) + " / " + str(int(sk2.max)), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#9fb3c8"))
			draw_rect(Rect2(r.position.x + 128, r.position.y + 142, 220, 6), Color("#26344d"))
			draw_rect(Rect2(r.position.x + 128, r.position.y + 142, 220 * clampf(float(lv) / float(sk2.max), 0.0, 1.0), 6), cc)
		var tag := str(int(o.price)) + " 金"
		var tcol := Color("#ffd166") if afford else Color("#ff5d73")
		draw_string(font, Vector2(r.position.x + 128, r.position.y + 180), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, tcol)
		draw_string(font, Vector2(r.position.x + r.size.x - 90, r.position.y + 180), "点击购买" if afford else "金币不够", HORIZONTAL_ALIGNMENT_RIGHT, 74, 13, Color("#5f7394"))
	draw_rect(Rect2(52, 620, 190, 62), Color("#121a2e"))
	draw_rect(Rect2(52, 620, 190, 62), Color("#2f4468"), false, 2.0)
	draw_string(font, Vector2(72, 659), "刷新 · 3 金", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#dbe9ff"))
	draw_rect(Rect2(W - 242, 620, 190, 62), Color("#1f8f62"))
	draw_rect(Rect2(W - 242, 620, 190, 62), Color("#62f0b6"), false, 2.0)
	draw_string(font, Vector2(W - 212, 659), "继续战斗", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#eafff6"))

func draw_pause() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.03, 0.06, 0.78))
	tc("暂停", 300, 54, Color("#eaf7ff"))
	draw_rect(PAUSE_RESUME, Color("#1f8f62"))
	draw_rect(PAUSE_RESUME, Color("#62f0b6"), false, 3.0)
	tc_at("继续战斗", PAUSE_RESUME.get_center().x, PAUSE_RESUME.position.y + 46, 28, Color("#eafff6"))
	draw_rect(PAUSE_LOBBY, Color("#121a2e"))
	draw_rect(PAUSE_LOBBY, Color("#2f4468"), false, 2.0)
	tc_at("返回大厅", PAUSE_LOBBY.get_center().x, PAUSE_LOBBY.position.y + 46, 28, Color("#dbe9ff"))

func draw_over() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.01, 0.02, 0.04, 0.88))
	tc("你死了", 250, 68, Color("#ff5d73"))
	var m := int(elapsed / 60.0)
	var sec := int(elapsed) % 60
	var ts := (str(m) if m >= 10 else "0" + str(m)) + ":" + (str(sec) if sec >= 10 else "0" + str(sec))
	tc("存活 " + ts + "　等级 " + str(level) + "　击杀 " + str(kills), 340, 26, Color("#c9d8ee"))
	tc("得分 " + str(score) + "　最高连击 " + str(best_combo) + "　最高分 " + str(int(meta.best)), 385, 24, Color("#c9d8ee"))
	tc("本局获得金币 +" + str(last_reward) + "　总金币 " + str(int(meta.coins)), 440, 24, Color("#ffd166"))
	draw_rect(OVER_RESTART, Color("#1f8f62"))
	draw_rect(OVER_RESTART, Color("#62f0b6"), false, 3.0)
	tc_at("再来一局", OVER_RESTART.get_center().x, OVER_RESTART.position.y + 47, 28, Color("#eafff6"))
	draw_rect(OVER_LOBBY, Color("#121a2e"))
	draw_rect(OVER_LOBBY, Color("#2f4468"), false, 2.0)
	tc_at("返回大厅", OVER_LOBBY.get_center().x, OVER_LOBBY.position.y + 47, 28, Color("#dbe9ff"))
	tc("空格 / 点按钮重开", 630, 15, Color("#5f7394"))

# ============================================================ 二次元 UI 工具
func _grad(rect: Rect2, c1: Color, c2: Color, steps: int = 14) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var n := maxi(2, steps)
	var hh := rect.size.y / float(n)
	for i in range(n):
		var t := float(i) / float(n - 1)
		draw_rect(Rect2(rect.position.x, rect.position.y + hh * i, rect.size.x, hh + 1.0), c1.lerp(c2, t))

func _rrect(rect: Rect2, c: Color, rad: float) -> void:
	var rr := minf(rad, minf(rect.size.x, rect.size.y) * 0.5)
	if rr <= 0.5:
		draw_rect(rect, c)
		return
	draw_rect(Rect2(rect.position.x + rr, rect.position.y, rect.size.x - rr * 2.0, rect.size.y), c)
	draw_rect(Rect2(rect.position.x, rect.position.y + rr, rect.size.x, rect.size.y - rr * 2.0), c)
	draw_circle(Vector2(rect.position.x + rr, rect.position.y + rr), rr, c)
	draw_circle(Vector2(rect.position.x + rect.size.x - rr, rect.position.y + rr), rr, c)
	draw_circle(Vector2(rect.position.x + rr, rect.position.y + rect.size.y - rr), rr, c)
	draw_circle(Vector2(rect.position.x + rect.size.x - rr, rect.position.y + rect.size.y - rr), rr, c)

func _card_bg(rect: Rect2, accent: Color, hot: bool = false) -> void:
	var glow := accent
	glow.a = 0.16 if hot else 0.08
	_rrect(rect.grow(3), glow, 16)
	_rrect(rect, accent, 14)
	_rrect(rect.grow(-2), Color("#151a30"), 12)
	_grad(Rect2(rect.position.x + 2, rect.position.y + 2, rect.size.x - 4, rect.size.y - 4), Color("#20264a"), Color("#0d1020"), 10)
	draw_line(Vector2(rect.position.x + 14, rect.position.y + 3), Vector2(rect.position.x + rect.size.x - 14, rect.position.y + 3), Color(accent, 0.8), 2.0)
	draw_colored_polygon(PackedVector2Array([
		rect.position + Vector2(12, 10), rect.position + Vector2(rect.size.x * 0.55, 10),
		rect.position + Vector2(12, rect.size.y * 0.42)
	]), Color(1, 1, 1, 0.035))

func _outline_text(txt: String, cx: float, y: float, size: int, col: Color, outline: Color = Color("#1a1030")) -> void:
	var w: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := Vector2(cx - w * 0.5, y)
	for dx in [-2, 0, 2]:
		for dy in [-2, 0, 2]:
			if dx != 0 or dy != 0:
				draw_string(font, pos + Vector2(dx, dy), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline)
	draw_string(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

# ============================================================ 文本工具
func tc(txt: String, baseline_y: float, size: int, col: Color) -> void:
	var w: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, Vector2((W - w) * 0.5, baseline_y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

func tc_in(txt: String, baseline_y: float, size: int, col: Color) -> void:
	tc(txt, baseline_y, size, col)

func tc_at(txt: String, cx: float, baseline_y: float, size: int, col: Color) -> void:
	var w: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, Vector2(cx - w * 0.5, baseline_y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
