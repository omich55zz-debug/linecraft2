extends Node
## Static data — races, classes, monsters.

const RACES := [
    {
        "id": "human", "icon": "🛡", "name": "Человек",
        "skin": Color(0.902, 0.753, 0.639), "hair": Color(0.435, 0.306, 0.165),
        "height": 1.0, "cape": Color(0.208, 0.353, 0.471),
        "feature": "", "classes": ["fighter", "mystic"],
        "stats": {"str": 40, "dex": 30, "con": 43, "int": 21, "wit": 11, "men": 25},
    },
    {
        "id": "elf", "icon": "🌿", "name": "Эльф",
        "skin": Color(0.957, 0.875, 0.788), "hair": Color(0.984, 0.953, 0.749),
        "height": 1.04, "cape": Color(0.255, 0.518, 0.345),
        "feature": "ears_long", "classes": ["fighter", "mystic"],
        "stats": {"str": 36, "dex": 35, "con": 36, "int": 23, "wit": 14, "men": 26},
    },
    {
        "id": "darkelf", "icon": "🌑", "name": "Тёмный эльф",
        "skin": Color(0.518, 0.525, 0.580), "hair": Color(0.157, 0.118, 0.196),
        "height": 1.02, "cape": Color(0.310, 0.118, 0.357),
        "feature": "ears_long", "classes": ["fighter", "mystic"],
        "stats": {"str": 41, "dex": 34, "con": 32, "int": 23, "wit": 12, "men": 28},
    },
    {
        "id": "orc", "icon": "🪓", "name": "Орк",
        "skin": Color(0.553, 0.694, 0.467), "hair": Color(0.118, 0.094, 0.078),
        "height": 1.10, "cape": Color(0.443, 0.165, 0.165),
        "feature": "tusks", "classes": ["raider", "shaman"],
        "stats": {"str": 40, "dex": 26, "con": 47, "int": 18, "wit": 12, "men": 27},
    },
    {
        "id": "dwarf", "icon": "⛏", "name": "Гном",
        "skin": Color(0.937, 0.792, 0.659), "hair": Color(0.510, 0.275, 0.118),
        "height": 0.86, "cape": Color(0.486, 0.345, 0.157),
        "feature": "beard", "classes": ["scavenger", "artisan"],
        "stats": {"str": 39, "dex": 29, "con": 45, "int": 20, "wit": 10, "men": 27},
    },
    {
        "id": "kamael", "icon": "🦇", "name": "Камаэль",
        "skin": Color(0.835, 0.776, 0.776), "hair": Color(0.149, 0.157, 0.220),
        "height": 1.06, "cape": Color(0.090, 0.094, 0.118),
        "feature": "wings", "classes": ["soldier", "trooper"],
        "stats": {"str": 41, "dex": 33, "con": 35, "int": 23, "wit": 13, "men": 25},
    },
]

const CLASSES := {
    "fighter":  {"id": "fighter",  "name": "Воин",        "base_hp": 80, "base_mp": 20, "atk": 12, "m_atk": 4,  "weapon": "sword"},
    "mystic":   {"id": "mystic",   "name": "Маг",         "base_hp": 60, "base_mp": 60, "atk": 6,  "m_atk": 14, "weapon": "staff"},
    "raider":   {"id": "raider",   "name": "Налётчик",    "base_hp": 90, "base_mp": 18, "atk": 14, "m_atk": 3,  "weapon": "axe"},
    "shaman":   {"id": "shaman",   "name": "Шаман",       "base_hp": 70, "base_mp": 50, "atk": 8,  "m_atk": 12, "weapon": "staff"},
    "scavenger":{"id": "scavenger","name": "Старатель",   "base_hp": 75, "base_mp": 25, "atk": 10, "m_atk": 5,  "weapon": "pickaxe"},
    "artisan":  {"id": "artisan",  "name": "Ремесленник", "base_hp": 70, "base_mp": 35, "atk": 9,  "m_atk": 7,  "weapon": "pickaxe"},
    "soldier":  {"id": "soldier",  "name": "Солдат",      "base_hp": 78, "base_mp": 28, "atk": 12, "m_atk": 6,  "weapon": "crossbow"},
    "trooper":  {"id": "trooper",  "name": "Гвардеец",    "base_hp": 85, "base_mp": 22, "atk": 13, "m_atk": 4,  "weapon": "axe"},
}

const MONSTERS := [
    {"id": "wolf",  "name": "Волк",          "level": 2,  "hp": 35,  "atk": 6,  "xp": 18, "color": Color(0.42, 0.42, 0.42), "scale": 0.9, "loot": [3, 8],
        "drops": [{"mat": "wolf_fang", "chance": 0.55}, {"mat": "wolf_pelt", "chance": 0.35}]},
    {"id": "boar",  "name": "Кабан",         "level": 4,  "hp": 60,  "atk": 9,  "xp": 32, "color": Color(0.29, 0.21, 0.16), "scale": 1.0, "loot": [5, 14],
        "drops": [{"mat": "boar_tusk", "chance": 0.50}, {"mat": "leather", "chance": 0.40}]},
    {"id": "bear",  "name": "Медведь",       "level": 8,  "hp": 140, "atk": 16, "xp": 78, "color": Color(0.18, 0.13, 0.10), "scale": 1.3, "loot": [16, 38],
        "drops": [{"mat": "bear_claw", "chance": 0.60}, {"mat": "leather", "chance": 0.55}, {"mat": "wolf_pelt", "chance": 0.20}]},
    {"id": "gnoll", "name": "Гнолл",         "level": 5,  "hp": 80,  "atk": 11, "xp": 44, "color": Color(0.55, 0.43, 0.27), "scale": 1.05,"loot": [7, 18],
        "drops": [{"mat": "gnoll_bone", "chance": 0.55}, {"mat": "leather", "chance": 0.30}]},
    {"id": "ork",   "name": "Орк-разбойник", "level": 7,  "hp": 110, "atk": 14, "xp": 64, "color": Color(0.43, 0.55, 0.34), "scale": 1.15,"loot": [12, 28],
        "drops": [{"mat": "orc_horn", "chance": 0.45}, {"mat": "iron_scrap", "chance": 0.50}]},
]

const MATERIALS := {
    "wolf_fang":  {"id": "wolf_fang",  "name": "Клык волка",       "icon": "🦷", "color": Color(0.92, 0.92, 0.85)},
    "wolf_pelt":  {"id": "wolf_pelt",  "name": "Шкура волка",      "icon": "🟫", "color": Color(0.55, 0.45, 0.35)},
    "boar_tusk":  {"id": "boar_tusk",  "name": "Клык кабана",      "icon": "🦷", "color": Color(0.85, 0.78, 0.55)},
    "leather":    {"id": "leather",    "name": "Кожа",             "icon": "🟫", "color": Color(0.45, 0.30, 0.18)},
    "gnoll_bone": {"id": "gnoll_bone", "name": "Кость гнолла",     "icon": "🦴", "color": Color(0.95, 0.93, 0.82)},
    "bear_claw":  {"id": "bear_claw",  "name": "Коготь медведя",   "icon": "🐾", "color": Color(0.30, 0.20, 0.16)},
    "orc_horn":   {"id": "orc_horn",   "name": "Рог орка",         "icon": "🪈", "color": Color(0.20, 0.18, 0.16)},
    "iron_scrap": {"id": "iron_scrap", "name": "Кусок железа",     "icon": "⛓", "color": Color(0.55, 0.58, 0.62)},
}

const RECIPES := [
    {
        "id": "leather_armor",
        "name": "Кожаная броня",
        "desc": "+30 макс. HP",
        "cost": {"wolf_pelt": 5, "leather": 3},
        "gold": 50,
        "bonus": {"max_hp": 30},
        "icon": "🛡",
    },
    {
        "id": "bone_amulet",
        "name": "Костяной амулет",
        "desc": "+8 магической атаки",
        "cost": {"gnoll_bone": 8, "wolf_fang": 4},
        "gold": 100,
        "bonus": {"m_atk": 8},
        "icon": "📿",
    },
    {
        "id": "battle_elixir",
        "name": "Боевой эликсир",
        "desc": "+5 атаки навсегда",
        "cost": {"bear_claw": 3, "boar_tusk": 5},
        "gold": 200,
        "bonus": {"atk": 5},
        "icon": "🧪",
    },
    {
        "id": "spirit_totem",
        "name": "Тотем духа",
        "desc": "+15 макс. MP, +3 магической атаки",
        "cost": {"wolf_fang": 10, "orc_horn": 4, "gnoll_bone": 6},
        "gold": 500,
        "bonus": {"max_mp": 15, "m_atk": 3},
        "icon": "🪄",
    },
    {
        "id": "iron_pendant",
        "name": "Железный пендант",
        "desc": "+25 макс. HP, +2 атаки",
        "cost": {"iron_scrap": 8, "leather": 4},
        "gold": 350,
        "bonus": {"max_hp": 25, "atk": 2},
        "icon": "⛓",
    },
]

static func race(id: String) -> Dictionary:
    for r in RACES:
        if r.id == id:
            return r
    return RACES[0]

static func klass(id: String) -> Dictionary:
    return CLASSES.get(id, CLASSES["fighter"])

static func monster_kind(id: String) -> Dictionary:
    for m in MONSTERS:
        if m.id == id:
            return m
    return MONSTERS[0]

static func material(id: String) -> Dictionary:
    return MATERIALS.get(id, {})

static func recipe(id: String) -> Dictionary:
    for r in RECIPES:
        if r.id == id:
            return r
    return {}
