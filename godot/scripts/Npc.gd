extends StaticBody3D
## Friendly NPC trader. Click to open shop dialog.

signal interacted(npc)

@export var npc_name: String = "Торговец Альтран"
@export var npc_color: Color = Color(0.85, 0.78, 0.55)

var name_label: Label3D

func _ready() -> void:
    add_to_group("npcs")
    collision_layer = 8
    collision_mask = 0
    _build_model()
    _build_collider()
    _build_label()

func _build_model() -> void:
    var skin := StandardMaterial3D.new()
    skin.albedo_color = Color(0.92, 0.78, 0.66)
    var robe := StandardMaterial3D.new()
    robe.albedo_color = npc_color

    var torso := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = Vector3(0.6, 0.8, 0.36)
    torso.mesh = bm
    torso.material_override = robe
    torso.position.y = 1.0
    add_child(torso)

    var head := MeshInstance3D.new()
    var hm := BoxMesh.new()
    hm.size = Vector3(0.32, 0.34, 0.30)
    head.mesh = hm
    head.material_override = skin
    head.position.y = 1.6
    add_child(head)

    var hat := MeshInstance3D.new()
    var hatm := CylinderMesh.new()
    hatm.top_radius = 0.05
    hatm.bottom_radius = 0.30
    hatm.height = 0.40
    hat.mesh = hatm
    var hat_mat := StandardMaterial3D.new()
    hat_mat.albedo_color = Color(0.20, 0.18, 0.14)
    hat.material_override = hat_mat
    hat.position.y = 1.95
    add_child(hat)

    for sx in [-1, 1]:
        var leg := MeshInstance3D.new()
        var lm := BoxMesh.new()
        lm.size = Vector3(0.18, 0.6, 0.18)
        leg.mesh = lm
        var leg_mat := StandardMaterial3D.new()
        leg_mat.albedo_color = Color(0.16, 0.14, 0.12)
        leg.material_override = leg_mat
        leg.position = Vector3(0.13 * sx, 0.30, 0)
        add_child(leg)

func _build_collider() -> void:
    var col := CollisionShape3D.new()
    var cs := CapsuleShape3D.new()
    cs.radius = 0.5
    cs.height = 1.8
    col.shape = cs
    col.position.y = 0.9
    add_child(col)

func _build_label() -> void:
    name_label = Label3D.new()
    name_label.text = "%s ✦" % npc_name
    name_label.modulate = Color(1, 0.9, 0.5)
    name_label.font_size = 32
    name_label.outline_size = 10
    name_label.position = Vector3(0, 2.3, 0)
    name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    name_label.no_depth_test = true
    add_child(name_label)

func _process(_delta: float) -> void:
    var q := get_node_or_null("/root/Quests")
    if q == null: return
    var prefix := ""
    if q.is_completable():
        prefix = "❓ "
        name_label.modulate = Color(0.55, 1.0, 0.55)
    elif not q.has_active() and q.next_offerable() != "":
        prefix = "❗ "
        name_label.modulate = Color(1, 0.92, 0.32)
    else:
        name_label.modulate = Color(1, 0.9, 0.5)
    name_label.text = "%s%s ✦" % [prefix, npc_name]
