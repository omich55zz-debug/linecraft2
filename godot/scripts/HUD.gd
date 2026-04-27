extends CanvasLayer
## Top-bar character info, target frame, action bar, level toast.

@export var player_path: NodePath
var player: Node = null

@onready var hp_bar: ProgressBar = $Top/Bars/HpBar
@onready var hp_label: Label = $Top/Bars/HpBar/Label
@onready var mp_bar: ProgressBar = $Top/Bars/MpBar
@onready var mp_label: Label = $Top/Bars/MpBar/Label
@onready var xp_bar: ProgressBar = $Top/Bars/XpBar
@onready var xp_label: Label = $Top/Bars/XpBar/Label
@onready var char_label: Label = $Top/CharLabel
@onready var target_panel: PanelContainer = $TargetPanel
@onready var target_name: Label = $TargetPanel/V/TargetName
@onready var target_hp: ProgressBar = $TargetPanel/V/TargetHp
@onready var toast: Label = $Toast

var target_ref: Node = null

func _ready() -> void:
    player = get_node_or_null(player_path)
    if player == null:
        player = get_tree().get_first_node_in_group("player")
    if player:
        player.stats_changed.connect(_refresh)
        player.target_changed.connect(_on_target_changed)
        player.level_up.connect(_on_level_up)
        player.floating_text.connect(_on_floating_text)
    target_panel.visible = false
    toast.visible = false
    var ab := get_node_or_null("ActionBar")
    if ab:
        ab.get_node("BtnAttack").pressed.connect(_on_btn_attack_pressed)
        ab.get_node("BtnPower").pressed.connect(_on_btn_power_pressed)
        ab.get_node("BtnHeal").pressed.connect(_on_btn_heal_pressed)
        ab.get_node("BtnSit").pressed.connect(_on_btn_sit_pressed)
    _refresh()

func _process(_delta: float) -> void:
    if target_ref != null and is_instance_valid(target_ref) and not target_ref.dead:
        target_hp.max_value = target_ref.max_hp
        target_hp.value = target_ref.hp
    elif target_ref != null:
        target_panel.visible = false
        target_ref = null

func _refresh() -> void:
    if player == null: return
    hp_bar.max_value = player.max_hp; hp_bar.value = player.hp
    hp_label.text = "%d / %d" % [player.hp, player.max_hp]
    mp_bar.max_value = player.max_mp; mp_bar.value = player.mp
    mp_label.text = "%d / %d" % [player.mp, player.max_mp]
    xp_bar.max_value = player.xp_next; xp_bar.value = player.xp
    xp_label.text = "XP %d / %d" % [player.xp, player.xp_next]
    char_label.text = "%s · %s · ур.%d %s" % [player.race.name, player.klass.name, player.level, ("(сидит)" if player.sitting else "")]

func _on_target_changed(t) -> void:
    target_ref = t
    if t == null:
        target_panel.visible = false
        return
    target_panel.visible = true
    target_name.text = "%s · ур.%d" % [t.kind.name, t.kind.level]

func _on_level_up(lvl: int) -> void:
    toast.text = "Уровень %d!" % lvl
    toast.visible = true
    toast.modulate = Color(1, 1, 0.5, 1)
    var tw := create_tween()
    tw.tween_property(toast, "modulate:a", 0.0, 2.5)
    tw.tween_callback(func(): toast.visible = false)

func _on_floating_text(text, color, world_pos) -> void:
    var lbl := Label3D.new()
    lbl.text = text
    lbl.modulate = color
    lbl.font_size = 36
    lbl.outline_size = 10
    lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    lbl.no_depth_test = true
    lbl.position = world_pos
    var world := get_tree().current_scene
    world.add_child(lbl)
    var tw := create_tween()
    tw.tween_property(lbl, "position:y", world_pos.y + 1.4, 1.0)
    tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.0)
    tw.tween_callback(lbl.queue_free)

func _on_btn_attack_pressed() -> void:
    pass
func _on_btn_power_pressed() -> void:
    if player: player.use_skill_power()
func _on_btn_heal_pressed() -> void:
    if player: player.use_skill_heal()
func _on_btn_sit_pressed() -> void:
    if player: player.toggle_sit()
