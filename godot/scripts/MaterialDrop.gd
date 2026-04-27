extends Node3D
## Material item dropped by a slain monster — auto-pickup into Inventory.

const Data := preload("res://scripts/Data.gd")

var mat_id: String = ""
var qty: int = 1
var lifetime: float = 45.0
var picked: bool = false
var bob_t: float = 0.0
var visual: MeshInstance3D

func _ready() -> void:
    var info: Dictionary = Data.material(mat_id)
    if info.is_empty():
        queue_free()
        return

    visual = MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = Vector3(0.32, 0.18, 0.32)
    visual.mesh = bm
    var mat := StandardMaterial3D.new()
    mat.albedo_color = info.color
    mat.metallic = 0.25
    mat.roughness = 0.55
    mat.emission_enabled = true
    mat.emission = Color(info.color).lightened(0.25)
    mat.emission_energy_multiplier = 0.30
    visual.material_override = mat
    visual.position.y = 0.30
    add_child(visual)

    var label := Label3D.new()
    label.text = "%s ×%d" % [String(info.icon), qty]
    label.modulate = Color(1, 1, 0.85)
    label.font_size = 22
    label.outline_size = 6
    label.position = Vector3(0, 1.05, 0)
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.no_depth_test = true
    add_child(label)

func _process(delta: float) -> void:
    if picked: return
    bob_t += delta
    rotation.y += delta * 1.4
    if visual:
        visual.position.y = 0.30 + sin(bob_t * 3.0) * 0.06

    lifetime -= delta
    if lifetime <= 0:
        queue_free()
        return

    var scene := get_tree().current_scene
    if scene == null: return
    var player := scene.get_node_or_null("Player")
    if player == null: return
    var d: float = global_position.distance_to(player.global_position)
    if d < 1.4:
        _pick(player)

func _pick(_player: Node) -> void:
    picked = true
    var inv := get_node_or_null("/root/Inventory")
    if inv:
        inv.add(mat_id, qty)
    var scene := get_tree().current_scene
    if scene and scene.has_node("HUD"):
        var hud: Node = scene.get_node("HUD")
        if hud and hud.has_method("flash_material_pickup"):
            hud.flash_material_pickup(mat_id, qty)
    var tw := create_tween()
    tw.tween_property(self, "position:y", 1.5, 0.4).set_trans(Tween.TRANS_CUBIC)
    tw.parallel().tween_property(self, "scale", Vector3.ZERO, 0.4)
    tw.tween_callback(queue_free)
