extends Node
## Autoload — persistent save (level/xp/gold/race/class) in user:// (browser localStorage on Web).

const SAVE_PATH := "user://linecraft2_save.json"

var data: Dictionary = {
    "race_id": "human",
    "class_id": "fighter",
    "level": 1,
    "xp": 0,
    "xp_next": 100,
    "gold": 0,
    "hp_potions": 0,
    "mp_potions": 0,
}

func _ready() -> void:
    load_data()

func load_data() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if f == null: return
    var txt := f.get_as_text()
    f.close()
    var parsed = JSON.parse_string(txt)
    if parsed is Dictionary:
        for k in parsed.keys():
            data[k] = parsed[k]

func save_data() -> void:
    var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if f == null: return
    f.store_string(JSON.stringify(data))
    f.close()

func reset() -> void:
    data = {
        "race_id": "human",
        "class_id": "fighter",
        "level": 1,
        "xp": 0,
        "xp_next": 100,
        "gold": 0,
        "hp_potions": 0,
        "mp_potions": 0,
    }
    save_data()
