extends Node
## Autoload — tracks active and completed quests, persists via SaveGame.

signal quest_updated(quest_id)

const QUESTS := {
    "wolf_hunt": {
        "id": "wolf_hunt",
        "name": "Угроза волков",
        "desc": "Убей 5 волков для торговца Альтрана.",
        "target_kind": "wolf",
        "target_count": 5,
        "reward_gold": 80,
        "reward_xp": 60,
    },
    "boar_hunt": {
        "id": "boar_hunt",
        "name": "Свиная вылазка",
        "desc": "Уничтожь 4 кабанов, что разорили огороды.",
        "target_kind": "boar",
        "target_count": 4,
        "reward_gold": 120,
        "reward_xp": 90,
    },
    "gnoll_threat": {
        "id": "gnoll_threat",
        "name": "Гнольский налёт",
        "desc": "Убей 6 гноллов вокруг лагеря.",
        "target_kind": "gnoll",
        "target_count": 6,
        "reward_gold": 200,
        "reward_xp": 160,
    },
}

var active_quest_id: String = ""
var active_progress: int = 0
var completed: Array = []

func _ready() -> void:
    _load_from_save()

func _load_from_save() -> void:
    var sg := get_node_or_null("/root/SaveGame")
    if sg == null: return
    active_quest_id = String(sg.data.get("quest_id", ""))
    active_progress = int(sg.data.get("quest_progress", 0))
    completed = Array(sg.data.get("quest_done", []))

func _save() -> void:
    var sg := get_node_or_null("/root/SaveGame")
    if sg == null: return
    sg.data["quest_id"] = active_quest_id
    sg.data["quest_progress"] = active_progress
    sg.data["quest_done"] = completed
    sg.save_data()

func has_active() -> bool:
    return active_quest_id != "" and QUESTS.has(active_quest_id)

func active_quest() -> Dictionary:
    if not has_active(): return {}
    return QUESTS[active_quest_id]

func is_done(quest_id: String) -> bool:
    return quest_id in completed

func can_offer(quest_id: String) -> bool:
    return not is_done(quest_id) and active_quest_id != quest_id

func accept(quest_id: String) -> void:
    if not QUESTS.has(quest_id): return
    active_quest_id = quest_id
    active_progress = 0
    _save()
    emit_signal("quest_updated", quest_id)

func record_kill(kind_id: String) -> void:
    if not has_active(): return
    var q: Dictionary = active_quest()
    if q.target_kind == kind_id and active_progress < int(q.target_count):
        active_progress += 1
        _save()
        emit_signal("quest_updated", q.id)

func is_completable() -> bool:
    if not has_active(): return false
    var q: Dictionary = active_quest()
    return active_progress >= int(q.target_count)

func turn_in() -> Dictionary:
    if not is_completable(): return {}
    var q: Dictionary = active_quest()
    completed.append(q.id)
    active_quest_id = ""
    active_progress = 0
    _save()
    emit_signal("quest_updated", q.id)
    return q

func next_offerable() -> String:
    var ordered := ["wolf_hunt", "boar_hunt", "gnoll_threat"]
    for qid in ordered:
        if can_offer(qid) and not is_done(qid):
            return qid
    return ""
