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

rep('''var stick_active := false
''','''var stick_active := false
var active_touches := {}
''')

rep('''func _handle_press(pos: Vector2, id: int) -> void:
	if backgrounded: return
	if state in [S.TITLE, S.PAUSED] and _audio_click(pos): return
''','''func _handle_press(pos: Vector2, id: int) -> void:
	if backgrounded: return
	# 漏收 release 时，同 id 的新 press 视为重新按下；没有活动手指的 owner 直接清掉。
	if active_touches.has(id):
		if stick_active and stick_id == id: _release_stick("re-press")
		if aim_active and aim_id == id: _release_aim("re-press")
	active_touches[id] = true
	_clean_stale_owners()
	if state in [S.TITLE, S.PAUSED] and _audio_click(pos): return
''')

rep('''func _handle_release(id: int, reason: String = "release") -> void:
	if stick_active and id == stick_id:
		_release_stick(reason)
	elif aim_active and id == aim_id:
		_release_aim(reason)
''','''func _handle_release(id: int, reason: String = "release") -> void:
	active_touches.erase(id)
	if stick_active and id == stick_id:
		_release_stick(reason)
	elif aim_active and id == aim_id:
		_release_aim(reason)
	_clean_stale_owners()
''')

rep('''func _release_controls(reason: String = "state_change") -> void:
	_release_stick(reason)
	_release_aim(reason)
''','''func _clean_stale_owners() -> void:
	if stick_active and not active_touches.has(stick_id):
		_release_stick("stale")
	if aim_active and not active_touches.has(aim_id):
		_release_aim("stale")

func _release_controls(reason: String = "state_change") -> void:
	_release_stick(reason)
	_release_aim(reason)
	active_touches.clear()
''')

rep('''	if state != S.PLAYING: _release_controls()
''','''	if state != S.PLAYING and not p.is_empty():
		# 弹窗期间保留 owner，手指没松就能回来后继续用；只停住速度。
		p.vel = Vector2.ZERO
		p.dash_t = 0.0
''')

rep('''	if state != S.PLAYING or backgrounded:
		_release_controls("inactive")
		return
''','''	if state != S.PLAYING or backgrounded:
		return
''')

rep('''	elif state == S.PAUSED:
		_resume_play()
''','''	elif state == S.PAUSED:
		_resume_play()
''')

rep('''		state = S.PAUSED
		_release_controls("pause")
''','''		state = S.PAUSED
''')

rep('''	state = S.ALTAR
	_release_controls("altar")
	play_sfx("level")
''','''	state = S.ALTAR
	play_sfx("level")
''')
rep('''	state = S.PLAYING
	_release_controls("altar_done")
''','''	state = S.PLAYING
''')
rep('''	state = S.PLAYING
	_release_controls("altar_skip")
''','''	state = S.PLAYING
''')

rep('''	state = S.PLAYING
	_release_controls()
	while pending_levels > 0 and state == S.PLAYING:
''','''	state = S.PLAYING
	while pending_levels > 0 and state == S.PLAYING:
''')
rep('''	state = S.LEVELUP
	_release_controls()
	spawn_level_fx()
''','''	state = S.LEVELUP
	spawn_level_fx()
''')
rep('''	state = S.SHOP
	_release_controls()
	shop_auto_t = 0.0
''','''	state = S.SHOP
	shop_auto_t = 0.0
''')

io.open(P,'w',encoding='utf-8').write(s)
print('PATCH7 OK lines=%d'%s.count('\n'))
