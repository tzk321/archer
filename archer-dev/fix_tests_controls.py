#!/usr/bin/env python3
import io,sys
p='/home/sbtzk/games/archer-godot/tests/joystick.gd'
s=io.open(p,encoding='utf-8').read()
old='''	g.gain_xp(1000)
	expect(g.state == g.S.LEVELUP and not g.stick_active, "queued levelup releases joystick")
	while g.state == g.S.LEVELUP:
		g.choose_card(0)
	g.open_shop()
	expect(not g._stick_visible() or g.state != g.S.PLAYING, "shop hides or nonplaying")
	g._resume_play()
	expect(g._stick_visible() and visible_inside(), "modal return visible")
	expect(not g.stick_active and g.stick_id == -1, "modal return no stuck owner")
'''
new='''	g.gain_xp(1000)
	expect(g.state == g.S.LEVELUP and g.stick_active and g.stick_id == 21, "queued levelup keeps held owner")
	while g.state == g.S.LEVELUP:
		g.choose_card(0)
	expect(g.stick_active and g.stick_id == 21, "levelup return keeps held owner")
	g.open_shop()
	expect(g.state == g.S.SHOP and g.stick_active and g.stick_id == 21, "shop keeps held owner")
	g._resume_play()
	expect(g._stick_visible() and visible_inside(), "modal return visible")
	expect(g.stick_active and g.stick_id == 21, "modal return keeps held owner")
	g._handle_release(21)
	expect(not g.stick_active and g.stick_id == -1, "release after modal clears")
'''
assert s.count(old)==1
s=s.replace(old,new)
io.open(p,'w',encoding='utf-8').write(s)
print('joystick.gd updated')

p='/home/sbtzk/games/archer-godot/tests/v43.gd'
s=io.open(p,encoding='utf-8').read()
anchor='''	# ---- 3. 测试模式仍自动索敌（回归兼容） ----
'''
add='''	# ---- 2b. 弹窗不丢按住的双 owner；漏收 release/同 id 重按能自愈 ----
	g.start_run()
	g.state = g.S.PLAYING
	g._handle_press(Vector2(600, 550), 30)
	g._handle_press(Vector2(1000, 550), 31)
	g._update_aim(Vector2(1080, 550))
	g.gain_xp(1000)
	expect(g.state == g.S.LEVELUP and g.stick_active and g.aim_active, "modal keeps both owners")
	while g.state == g.S.LEVELUP:
		g.choose_card(0)
	expect(g.stick_active and g.aim_active, "levelup return keeps both owners")
	g.open_shop()
	expect(g.stick_active and g.aim_active, "shop keeps both owners")
	g._resume_play()
	expect(g.stick_active and g.aim_active and g.stick_id == 30 and g.aim_id == 31, "modal return same owners")
	g._handle_release(30)
	expect(not g.stick_active and g.aim_active, "stick release after modal keeps aim")
	g._handle_release(31)
	expect(not g.aim_active and not g.stick_active, "both release after modal")
	g.start_run()
	g.state = g.S.PLAYING
	g._handle_press(Vector2(600, 550), 40)
	g._handle_press(Vector2(600, 550), 40)
	expect(g.stick_active and g.stick_id == 40, "same-id re-press reclaims")
	g.active_touches.erase(40)
	g._handle_press(Vector2(1000, 550), 41)
	expect(not g.stick_active and g.aim_active and g.aim_id == 41, "stale owner cleared on new press")
	g._handle_release(41)

'''
assert s.count(anchor)==1
s=s.replace(anchor,add+anchor)
io.open(p,'w',encoding='utf-8').write(s)
print('v43.gd updated')
