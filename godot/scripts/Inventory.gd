extends Node
## Autoload — material inventory and crafted items, persisted via SaveGame.

const Data := preload("res://scripts/Data.gd")

signal changed
signal crafted(recipe_id)

var materials: Dictionary = {}      # mat_id -> count
var crafted_items: Array = []       # array of recipe_id (each can only be crafted once)

func _ready() -> void:
    _load_from_save()

func _load_from_save() -> void:
    var sg := get_node_or_null("/root/SaveGame")
    if sg == null: return
    var m: Variant = sg.data.get("materials", {})
    if m is Dictionary:
        for k in m.keys():
            materials[String(k)] = int(m[k])
    var c: Variant = sg.data.get("crafted_items", [])
    if c is Array:
        for r in c:
            crafted_items.append(String(r))

func _save() -> void:
    var sg := get_node_or_null("/root/SaveGame")
    if sg == null: return
    sg.data["materials"] = materials
    sg.data["crafted_items"] = crafted_items
    sg.save_data()

func add(mat_id: String, qty: int = 1) -> void:
    if qty <= 0: return
    materials[mat_id] = int(materials.get(mat_id, 0)) + qty
    _save()
    emit_signal("changed")

func count(mat_id: String) -> int:
    return int(materials.get(mat_id, 0))

func has_owned(recipe_id: String) -> bool:
    return recipe_id in crafted_items

func can_craft(recipe: Dictionary, gold: int) -> bool:
    if recipe.is_empty(): return false
    if has_owned(recipe.id): return false
    if gold < int(recipe.gold): return false
    var cost: Dictionary = recipe.cost
    for mat_id in cost.keys():
        if count(mat_id) < int(cost[mat_id]):
            return false
    return true

func craft(recipe: Dictionary) -> bool:
    if recipe.is_empty() or has_owned(recipe.id): return false
    var cost: Dictionary = recipe.cost
    for mat_id in cost.keys():
        materials[mat_id] = int(materials.get(mat_id, 0)) - int(cost[mat_id])
        if materials[mat_id] <= 0:
            materials.erase(mat_id)
    crafted_items.append(String(recipe.id))
    _save()
    emit_signal("changed")
    emit_signal("crafted", String(recipe.id))
    return true

func materials_text() -> String:
    if materials.is_empty():
        return "📦 Пусто"
    var parts: Array[String] = []
    for mat_id in materials.keys():
        var info: Dictionary = Data.material(String(mat_id))
        if info.is_empty(): continue
        parts.append("%s×%d" % [info.icon, int(materials[mat_id])])
    return "📦 " + " ".join(parts)
