extends CharacterBody3D
## Generic monster: low-poly model + simple AI (idle/aggro/attack/dead).

const Data := preload("res://scripts/Data.gd")

signal died(monster)

@export var kind_id: String = "wolf"
var kind: Dictionary
var hp: int = 35
var max_hp: int = 35
var atk_cd: float = 0.0
var dead: bool = false
var target: Node3D = null
var aggro_range: float = 8.0
var attack_range: float = 1.6
var move_speed: float = 2.5
var spawn_position: Vector3
var hp_label: Label3D

func _ready() -> void:
    kind = Data.monster_kind(kind_id)
    hp = kind.hp
    max_hp = kind.hp
    spawn_position = global_position
    add_to_group("monsters")
    collision_layer = 4
    collision_mask = 1

    _build_model()
    _build_collider()
    _build_hp_label()

func _build_model() -> void:
    var s: float = kind.scale
    var body_mat := StandardMaterial3D.new()
    body_mat.albedo_color = kind.color
    body_mat.roughness = 0.95

    var body := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = Vector3(0.7 * s, 0.55 * s, 1.1 * s)
    body.mesh = bm
    body.material_override = body_mat
    body.position.y = 0.55 * s
    add_child(body)

    var head := MeshInstance3D.new()
    var hm := BoxMesh.new()
    hm.size = Vector3(0.5 * s, 0.45 * s, 0.5 * s)
    head.mesh = hm
    head.material_override = body_mat
    head.position = Vector3(0, 0.78 * s, 0.6 * s)
    add_child(head)

    for i in 4:
        var leg := MeshInstance3D.new()
        var lm := BoxMesh.new()
        lm.size = Vector3(0.18 * s, 0.5 * s, 0.18 * s)
        leg.mesh = lm
        leg.material_override = body_mat
        var lx: float = -0.25 if (i % 2) == 0 else 0.25
        var lz: float = -0.40 if i < 2 else 0.40
        leg.position = Vector3(lx * s, 0.25 * s, lz * s)
        add_child(leg)

    var eye_mat := StandardMaterial3D.new()
    eye_mat.albedo_color = Color(1, 0.87, 0.20)
    eye_mat.emission_enabled = true
    eye_mat.emission = Color(1, 0.87, 0.20)
    eye_mat.emission_energy_multiplier = 1.5
    for sx in [-1, 1]:
        var eye := MeshInstance3D.new()
        var sm := SphereMesh.new()
        sm.radius = 0.06 * s
        sm.height = 0.12 * s
        eye.mesh = sm
        eye.material_override = eye_mat
        eye.position = Vector3(0.15 * sx * s, 0.86 * s, 0.85 * s)
        add_child(eye)

func _build_collider() -> void:
    var col := CollisionShape3D.new()
    var cs := CapsuleShape3D.new()
    cs.radius = 0.55 * float(kind.scale)
    cs.height = 1.4 * float(kind.scale)
    col.shape = cs
    col.position.y = 0.7 * float(kind.scale)
    add_child(col)

func _build_hp_label() -> void:
    hp_label = Label3D.new()
    hp_label.text = "%s (%d)" % [kind.name, kind.level]
    hp_label.modulate = Color(1, 1, 0.6)
    hp_label.font_size = 28
    hp_label.outline_size = 8
    hp_label.position = Vector3(0, 1.7 * float(kind.scale), 0)
    hp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    hp_label.no_depth_test = true
    add_child(hp_label)

func _physics_process(delta: float) -> void:
    if dead:
        return
    if atk_cd > 0:
        atk_cd -= delta

    if target != null and is_instance_valid(target):
        var to_t: Vector3 = target.global_position - global_position
        to_t.y = 0
        var d := to_t.length()
        if d > 0.01:
            look_at(global_position + to_t, Vector3.UP)
        if d > attack_range:
            var dir := to_t.normalized()
            velocity = dir * move_speed
            move_and_slide()
        elif atk_cd <= 0:
            atk_cd = 1.6
            if target.has_method("take_damage"):
                target.take_damage(kind.atk)
        if d > aggro_range * 2.5:
            target = null
    else:
        var to_s: Vector3 = spawn_position - global_position
        to_s.y = 0
        if to_s.length() > 0.5:
            velocity = to_s.normalized() * move_speed * 0.4
            move_and_slide()
        else:
            velocity = Vector3.ZERO

func take_damage(d: int) -> void:
    if dead: return
    hp = max(0, hp - d)
    hp_label.text = "%s ▼ %d/%d" % [kind.name, hp, max_hp]
    if hp <= 0:
        die()

func die() -> void:
    dead = true
    if hp_label:
        hp_label.visible = false
    emit_signal("died", self)
    var t := create_tween()
    t.tween_property(self, "rotation:z", PI * 0.5, 0.4)
    t.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.8)
    t.tween_callback(queue_free)
