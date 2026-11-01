extends RefCounted

## 20 套皮肤：配色 + 帽子/披风 + 拖尾。只改视觉，不改数值。
## hat: none/hood/horns/helm/halo/crown/ears/antenna/wings/tail/flame/mask

const LIST := [
	{ "id": "ranger",  "n": "游侠",   "body": "#2fb37a", "cloak": "#1d6b4a", "eye": "#10231c", "hat": "hood",    "trail": "#54e6c0", "glow": "",        "cost": 0 },
	{ "id": "shadow",  "n": "暗影",   "body": "#4a3f6b", "cloak": "#2a2340", "eye": "#e0caff", "hat": "hood",    "trail": "#7b5cff", "glow": "#4a2f80", "cost": 20 },
	{ "id": "snow",    "n": "白雪",   "body": "#d8ecff", "cloak": "#8fb8dd", "eye": "#2a4a6b", "hat": "hood",    "trail": "#ffffff", "glow": "",        "cost": 30 },
	{ "id": "ember",   "n": "熔火",   "body": "#ff6b35", "cloak": "#8f2a12", "eye": "#ffe08a", "hat": "flame",   "trail": "#ff9a3a", "glow": "#ff4d1a", "cost": 40 },
	{ "id": "frost",   "n": "冰霜",   "body": "#8fd8ff", "cloak": "#3a7fa8", "eye": "#0b2a3a", "hat": "crown",   "trail": "#cfeaff", "glow": "#6fe3ff", "cost": 40 },
	{ "id": "golden",  "n": "黄金",   "body": "#ffd166", "cloak": "#a87c1a", "eye": "#4a2f00", "hat": "crown",   "trail": "#ffe9a8", "glow": "#ffca3a", "cost": 80 },
	{ "id": "voidkin", "n": "虚空",   "body": "#6a4fa8", "cloak": "#2a1a4a", "eye": "#d0b0ff", "hat": "horns",   "trail": "#b388ff", "glow": "#7b5cff", "cost": 80 },
	{ "id": "ghost",   "n": "幽灵",   "body": "#c9d8ee", "cloak": "#7f8fa6", "eye": "#2a3a4a", "hat": "none",    "trail": "#dbeaff", "glow": "#9fb3c8", "cost": 60 },
	{ "id": "moss",    "n": "苔藓",   "body": "#8ab86a", "cloak": "#3f5a2a", "eye": "#1a2a10", "hat": "ears",    "trail": "#a8d88a", "glow": "",        "cost": 20 },
	{ "id": "blood",   "n": "血月",   "body": "#c92a4a", "cloak": "#5a0f1c", "eye": "#ffd166", "hat": "horns",   "trail": "#ff5d73", "glow": "#8f0f20", "cost": 60 },
	{ "id": "thunder", "n": "雷电",   "body": "#f2e65c", "cloak": "#8f7a12", "eye": "#2a2a0a", "hat": "antenna", "trail": "#fff47a", "glow": "#f2e65c", "cost": 60 },
	{ "id": "ocean",   "n": "海洋",   "body": "#3a9fd8", "cloak": "#1a4a6b", "eye": "#eaffff", "hat": "tail",    "trail": "#7ee0c0", "glow": "#2fb3d8", "cost": 40 },
	{ "id": "dune",    "n": "沙丘",   "body": "#d9a066", "cloak": "#7a5224", "eye": "#2a1a08", "hat": "mask",    "trail": "#f2c94c", "glow": "",        "cost": 30 },
	{ "id": "sakura",  "n": "樱花",   "body": "#ffa6c9", "cloak": "#b84a7a", "eye": "#4a1028", "hat": "ears",    "trail": "#ffc9dd", "glow": "#ff7aa6", "cost": 50 },
	{ "id": "mecha",   "n": "机械",   "body": "#9aa7b8", "cloak": "#4a5260", "eye": "#54e6c0", "hat": "helm",    "trail": "#54e6c0", "glow": "",        "cost": 70 },
	{ "id": "demon",   "n": "恶魔",   "body": "#a83232", "cloak": "#3a0b0b", "eye": "#ffca3a", "hat": "horns",   "trail": "#ff4d4d", "glow": "#6b0f0f", "cost": 70 },
	{ "id": "angel",   "n": "天使",   "body": "#f0f0ff", "cloak": "#c9d8ee", "eye": "#5a6a8a", "hat": "halo",    "trail": "#ffffff", "glow": "#ffe9a8", "cost": 70 },
	{ "id": "beast",   "n": "兽王",   "body": "#b08a5a", "cloak": "#5a3a1a", "eye": "#ffe08a", "hat": "tail",    "trail": "#d9a066", "glow": "",        "cost": 50 },
	{ "id": "stardust","n": "星尘",   "body": "#7b5cff", "cloak": "#2a1a4a", "eye": "#ffffff", "hat": "antenna", "trail": "#c0a0ff", "glow": "#b388ff", "cost": 90 },
	{ "id": "rainbow", "n": "彩虹",   "body": "#ff7aa6", "cloak": "#7b5cff", "eye": "#ffffff", "hat": "wings",   "trail": "#54e6c0", "glow": "#ffd166", "cost": 120 },
]

static func find(id: String) -> Dictionary:
	for s in LIST:
		if s.id == id:
			return s
	return LIST[0]
