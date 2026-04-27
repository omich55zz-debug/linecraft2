extends Node3D
## A glowing coin pile dropped by a slain monster. Auto-picks up when player walks near.

var amount: int = 1
var lifetime: float = 30.0
var picked: bool = false
var bob_t: float = 0.0
var coins_mesh: MeshInstance3D

func _ready() -> void:
    coins_mesh = MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = 0.32
    cm.bottom_radius = 0.32
    cm.height = 0.10
    coins_mesh.mesh = cm
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(1.0, 0.85, 0.32)
    mat.metallic = 0.85
    mat.roughness = 0.25
    mat.emission_enabled = true
    mat.emission = Color(1.0, 0.78, 0.18)
    mat.emission_energy_multiplier = 0.45
    coins_mesh.material_override = mat
    coins_mesh.position.y = 0.20
    add_child(coins_mesh)

    var label := Label3D.new()
    label.text = "💰 %d" % amount
    label.modulate = Color(1, 0.92, 0.4)
    label.font_size = 22
    label.outline_size = 6
    label.position = Vector3(0, 0.95, 0)
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.no_depth_test = true
    add_child(label)

func _process(delta: float) -> void:
    if picked: return
    bob_t += delta
    rotation.y += delta * 1.6
    if coins_mesh:
        coins_mesh.position.y = 0.20 + sin(bob_t * 3.0) * 0.08

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

func _pick(player: Node) -> void:
    picked = true
    if player.has_method("add_gold"):
        player.add_gold(amount)
    var tw := create_tween()
    tw.tween_property(self, "position:y", 1.5, 0.4).set_trans(Tween.TRANS_CUBIC)
    tw.parallel().tween_property(self, "scale", Vector3.ZERO, 0.4)
    tw.tween_callback(queue_free)
