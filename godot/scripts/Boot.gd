extends Control
## Race + class selection screen.

const Data := preload("res://scripts/Data.gd")

@onready var race_grid: GridContainer = $Panel/V/RaceRow/RaceGrid
@onready var class_box: HBoxContainer = $Panel/V/ClassRow/ClassBox
@onready var preview_label: Label = $Panel/V/PreviewLabel
@onready var start_btn: Button = $Panel/V/StartBtn

var sel_race: String = "human"
var sel_class: String = "fighter"

func _ready() -> void:
    for race in Data.RACES:
        var b := Button.new()
        b.text = "%s  %s" % [race.icon, race.name]
        b.toggle_mode = true
        b.custom_minimum_size = Vector2(180, 56)
        var rid: String = race.id
        b.pressed.connect(func(): _select_race(rid))
        race_grid.add_child(b)
    var sg := get_node_or_null("/root/SaveGame")
    var initial_race := "human"
    if sg and int(sg.data.level) > 1:
        initial_race = String(sg.data.race_id)
        sel_class = String(sg.data.class_id)
    _select_race(initial_race)
    if sg and int(sg.data.level) > 1:
        sel_class = String(sg.data.class_id)
        _select_class(sel_class)
    if sg and int(sg.data.level) > 1:
        start_btn.text = "▶ Продолжить (ур.%d, %d 💰)" % [int(sg.data.level), int(sg.data.gold)]
    start_btn.pressed.connect(_on_start)
    var reset_btn := Button.new()
    reset_btn.text = "↺ Сбросить прогресс"
    reset_btn.custom_minimum_size = Vector2(0, 36)
    reset_btn.pressed.connect(_on_reset)
    start_btn.get_parent().add_child(reset_btn)

func _on_reset() -> void:
    var sg := get_node_or_null("/root/SaveGame")
    if sg: sg.reset()
    preview_label.text = "Прогресс сброшен. Выбери новую расу."

func _select_race(id: String) -> void:
    sel_race = id
    var race := Data.race(id)
    for c in class_box.get_children():
        c.queue_free()
    for cid in race.classes:
        var k := Data.klass(cid)
        var cb := Button.new()
        cb.text = "%s\nHP %d · MP %d · ATK %d · MAtk %d" % [k.name, k.base_hp, k.base_mp, k.atk, k.m_atk]
        cb.custom_minimum_size = Vector2(280, 80)
        var ccid: String = cid
        cb.pressed.connect(func(): _select_class(ccid))
        class_box.add_child(cb)
    _select_class(race.classes[0])

func _select_class(id: String) -> void:
    sel_class = id
    var race := Data.race(sel_race)
    var k := Data.klass(id)
    preview_label.text = "%s · %s\nSTR %d  DEX %d  CON %d  INT %d  WIT %d  MEN %d" % [
        race.name, k.name,
        race.stats.str, race.stats.dex, race.stats.con,
        race.stats.int, race.stats.wit, race.stats.men,
    ]

func _on_start() -> void:
    var sel := get_node("/root/Selection")
    sel.race_id = sel_race
    sel.class_id = sel_class
    get_tree().change_scene_to_file("res://scenes/GameWorld.tscn")
