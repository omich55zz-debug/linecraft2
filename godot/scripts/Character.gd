extends Node3D
## Procedural humanoid for a chosen race+class. Skeletal animation via pivot Node3Ds.

const Data := preload("res://scripts/Data.gd")

@export var race_id: String = "human"
@export var class_id: String = "fighter"

var torso: Node3D
var head: Node3D
var leg_l: Node3D
var leg_r: Node3D
var arm_l: Node3D
var arm_r: Node3D
var cape: Node3D
var wings: Node3D = null
var weapon_node: Node3D = null

var _walk_t := 0.0
var _attack_t := 0.0
var attacking := false

func _ready() -> void:
    build()

func build() -> void:
    for c in get_children():
        c.queue_free()
    var race := Data.race(race_id)
    var klass := Data.klass(class_id)
    var h: float = race.height

    var skin := _color_mat(race.skin)
    var cloth := _color_mat(race.cape)
    var leather := _color_mat(Color(0.31, 0.20, 0.13))
    var metal := _color_mat(Color(0.71, 0.74, 0.78), 0.6, 0.7)
    var hair := _color_mat(race.hair)

    torso = Node3D.new()
    torso.position = Vector3(0, 1.05 * h, 0)
    add_child(torso)

    var torso_mesh := _box(0.55 * h, 0.7 * h, 0.32 * h, cloth)
    torso_mesh.position.y = -0.05 * h
    torso.add_child(torso_mesh)

    var belt := _box(0.58 * h, 0.08 * h, 0.34 * h, leather)
    belt.position.y = -0.42 * h
    torso.add_child(belt)

    head = Node3D.new()
    head.position = Vector3(0, 0.42 * h, 0)
    torso.add_child(head)
    var head_mesh := _box(0.32 * h, 0.34 * h, 0.30 * h, skin)
    head.add_child(head_mesh)

    var hair_mesh := _box(0.34 * h, 0.18 * h, 0.32 * h, hair)
    hair_mesh.position.y = 0.13 * h
    head.add_child(hair_mesh)

    match race.feature:
        "ears_long":
            var earL := _box(0.05 * h, 0.18 * h, 0.05 * h, skin)
            earL.position = Vector3(-0.18 * h, 0.05 * h, 0)
            earL.rotation.z = 0.3
            head.add_child(earL)
            var earR := _box(0.05 * h, 0.18 * h, 0.05 * h, skin)
            earR.position = Vector3(0.18 * h, 0.05 * h, 0)
            earR.rotation.z = -0.3
            head.add_child(earR)
        "beard":
            var beard := _box(0.30 * h, 0.22 * h, 0.10 * h, hair)
            beard.position = Vector3(0, -0.16 * h, 0.13 * h)
            head.add_child(beard)
        "tusks":
            var tL := _box(0.04 * h, 0.10 * h, 0.04 * h, _color_mat(Color(0.95, 0.91, 0.78)))
            tL.position = Vector3(-0.08 * h, -0.14 * h, 0.16 * h)
            head.add_child(tL)
            var tR := _box(0.04 * h, 0.10 * h, 0.04 * h, _color_mat(Color(0.95, 0.91, 0.78)))
            tR.position = Vector3(0.08 * h, -0.14 * h, 0.16 * h)
            head.add_child(tR)
        "wings":
            wings = Node3D.new()
            wings.position = Vector3(0, 0.10 * h, -0.18 * h)
            torso.add_child(wings)
            var wmat := _color_mat(Color(0.07, 0.07, 0.10))
            var wL := _box(0.65 * h, 0.05 * h, 0.40 * h, wmat)
            wL.position = Vector3(-0.42 * h, 0, 0)
            wings.add_child(wL)
            var wR := _box(0.65 * h, 0.05 * h, 0.40 * h, wmat)
            wR.position = Vector3(0.42 * h, 0, 0)
            wings.add_child(wR)

    cape = _box(0.55 * h, 0.65 * h, 0.05 * h, _color_mat(race.cape * 0.85))
    cape.position = Vector3(0, -0.10 * h, -0.20 * h)
    torso.add_child(cape)

    leg_l = Node3D.new()
    leg_l.position = Vector3(-0.13 * h, -0.45 * h, 0)
    torso.add_child(leg_l)
    var leg_l_mesh := _box(0.18 * h, 0.6 * h, 0.18 * h, _color_mat(Color(0.16, 0.14, 0.12)))
    leg_l_mesh.position.y = -0.30 * h
    leg_l.add_child(leg_l_mesh)

    leg_r = Node3D.new()
    leg_r.position = Vector3(0.13 * h, -0.45 * h, 0)
    torso.add_child(leg_r)
    var leg_r_mesh := _box(0.18 * h, 0.6 * h, 0.18 * h, _color_mat(Color(0.16, 0.14, 0.12)))
    leg_r_mesh.position.y = -0.30 * h
    leg_r.add_child(leg_r_mesh)

    arm_l = Node3D.new()
    arm_l.position = Vector3(-0.32 * h, 0.30 * h, 0)
    torso.add_child(arm_l)
    var arm_l_mesh := _box(0.16 * h, 0.55 * h, 0.16 * h, skin)
    arm_l_mesh.position.y = -0.27 * h
    arm_l.add_child(arm_l_mesh)

    arm_r = Node3D.new()
    arm_r.position = Vector3(0.32 * h, 0.30 * h, 0)
    torso.add_child(arm_r)
    var arm_r_mesh := _box(0.16 * h, 0.55 * h, 0.16 * h, skin)
    arm_r_mesh.position.y = -0.27 * h
    arm_r.add_child(arm_r_mesh)

    weapon_node = _build_weapon(klass.weapon, h)
    weapon_node.position = Vector3(0, -0.50 * h, 0.05 * h)
    arm_r.add_child(weapon_node)

    if klass.id in ["fighter", "trooper", "raider"]:
        var shield := _box(0.45 * h, 0.55 * h, 0.06 * h, metal)
        shield.position = Vector3(0.05 * h, -0.50 * h, 0.12 * h)
        arm_l.add_child(shield)

func _physics_process(delta: float) -> void:
    if attacking:
        _attack_t += delta * 4.0
        if _attack_t >= 1.0:
            attacking = false
            _attack_t = 0.0
        var t := _attack_t
        var swing := sin(t * PI) * 1.5
        arm_r.rotation.x = -swing
        arm_l.rotation.x = swing * 0.3
    else:
        arm_r.rotation.x = lerp(arm_r.rotation.x, 0.0, delta * 8.0)
        arm_l.rotation.x = lerp(arm_l.rotation.x, 0.0, delta * 8.0)

    if wings:
        wings.rotation.z = sin(Time.get_ticks_msec() / 180.0) * 0.3
    if cape:
        cape.rotation.x = sin(Time.get_ticks_msec() / 220.0) * 0.08

func walk_step(amount: float) -> void:
    _walk_t += amount
    var s := sin(_walk_t * 6.0) * 0.7
    leg_l.rotation.x = s
    leg_r.rotation.x = -s
    if not attacking:
        arm_l.rotation.x = -s * 0.6
        arm_r.rotation.x = s * 0.6

func idle() -> void:
    leg_l.rotation.x = lerp(leg_l.rotation.x, 0.0, 0.2)
    leg_r.rotation.x = lerp(leg_r.rotation.x, 0.0, 0.2)

func trigger_attack() -> void:
    attacking = true
    _attack_t = 0.0

func _box(sx: float, sy: float, sz: float, mat: StandardMaterial3D) -> MeshInstance3D:
    var m := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = Vector3(sx, sy, sz)
    m.mesh = bm
    m.material_override = mat
    return m

func _cyl(top_r: float, bot_r: float, height: float, mat: StandardMaterial3D) -> MeshInstance3D:
    var m := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = top_r
    cm.bottom_radius = bot_r
    cm.height = height
    m.mesh = cm
    m.material_override = mat
    return m

func _color_mat(c: Color, rough: float = 0.85, metal: float = 0.0) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = c
    mat.roughness = rough
    mat.metallic = metal
    return mat

func _build_weapon(kind: String, h: float) -> Node3D:
    var root := Node3D.new()
    var brown := _color_mat(Color(0.31, 0.20, 0.13))
    var metal := _color_mat(Color(0.78, 0.81, 0.85), 0.4, 0.7)
    var gold := _color_mat(Color(0.86, 0.74, 0.31), 0.4, 0.6)
    match kind:
        "sword":
            var blade := _box(0.08 * h, 0.85 * h, 0.02 * h, metal)
            blade.position.y = 0.30 * h
            root.add_child(blade)
            var guard := _box(0.30 * h, 0.05 * h, 0.05 * h, gold)
            guard.position.y = -0.10 * h
            root.add_child(guard)
            var grip := _box(0.07 * h, 0.20 * h, 0.07 * h, brown)
            grip.position.y = -0.22 * h
            root.add_child(grip)
        "staff":
            var pole := _cyl(0.03 * h, 0.03 * h, 1.4 * h, brown)
            pole.position.y = 0.40 * h
            root.add_child(pole)
            var orb := MeshInstance3D.new()
            var sm := SphereMesh.new()
            sm.radius = 0.10 * h
            sm.height = 0.20 * h
            orb.mesh = sm
            var orb_mat := _color_mat(Color(0.40, 0.95, 0.50), 0.2, 0.0)
            orb_mat.emission_enabled = true
            orb_mat.emission = Color(0.30, 0.95, 0.45)
            orb_mat.emission_energy_multiplier = 1.5
            orb.material_override = orb_mat
            orb.position.y = 1.10 * h
            root.add_child(orb)
        "axe":
            var pole := _cyl(0.04 * h, 0.04 * h, 1.0 * h, brown)
            pole.position.y = 0.20 * h
            root.add_child(pole)
            var head_axe := _box(0.40 * h, 0.30 * h, 0.06 * h, metal)
            head_axe.position = Vector3(0.18 * h, 0.65 * h, 0)
            root.add_child(head_axe)
        "crossbow":
            var stock := _box(0.10 * h, 0.50 * h, 0.10 * h, brown)
            stock.position.y = 0.10 * h
            root.add_child(stock)
            var lath := _box(0.55 * h, 0.04 * h, 0.04 * h, metal)
            lath.position.y = 0.30 * h
            root.add_child(lath)
        "pickaxe":
            var pole := _cyl(0.035 * h, 0.035 * h, 0.9 * h, brown)
            pole.position.y = 0.20 * h
            root.add_child(pole)
            var pick := _box(0.50 * h, 0.06 * h, 0.06 * h, metal)
            pick.position.y = 0.60 * h
            root.add_child(pick)
        _:
            var fb := _box(0.08 * h, 0.5 * h, 0.02 * h, metal)
            root.add_child(fb)
    return root
