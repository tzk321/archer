#!/usr/bin/env python3
p='/home/sbtzk/games/archer-godot/README.md'
s=open(p,encoding='utf-8').read()
s=s.replace('新增  owner 自愈','新增 `active_touches` owner 自愈')
open(p,'w',encoding='utf-8').write(s)
print('readme backtick fixed')
