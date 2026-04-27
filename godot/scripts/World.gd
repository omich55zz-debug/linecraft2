extends Node3D
## Builds the starting outdoor scene: ground, trees, rocks, ambient lighting.

const TREE_COUNT := 60
const ROCK_COUNT := 30

@export var size: float = 80.0

func _ready() -> void:
    _build_lighting()
    _build_ground()
    _scatter_decoration()

func _build_lighting() -> void:
    var dl := DirectionalLight3D.new()
    dl.rotation_degrees = Vector3(-50, -35, 0)
    dl.light_energy = 1.05
    dl.shadow_enabled = true
    add_child(dl)

    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var pm := ProceduralSkyMaterial.new()
    pm.sky_top_color = Color(0.34, 0.55, 0.78)
    pm.sky_horizon_color = Color(0.71, 0.84, 0.91)
    pm.ground_bottom_color = Color(0.18, 0.21, 0.26)
    pm.ground_horizon_color = Color(0.55, 0.62, 0.51)
    sky.sky_material = pm
    e.sky = sky
    e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    e.ambient_light_energy = 0.6
    e.fog_enabled = true
    e.fog_density = 0.005
    e.fog_light_color = Color(0.71, 0.81, 0.86)
    env.environment = e
    add_child(env)

func _build_ground() -> void:
    var ground := StaticBody3D.new()
    ground.name = "Ground"
    ground.collision_layer = 1
    ground.collision_mask = 0
    add_child(ground)

    var mesh_inst := MeshInstance3D.new()
    var pm := PlaneMesh.new()
    pm.size = Vector2(size * 4, size * 4)
    pm.subdivide_width = 32
    pm.subdivide_depth = 32
    mesh_inst.mesh = pm
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.31, 0.49, 0.27)
    mat.roughness = 0.95
    mesh_inst.material_override = mat
    ground.add_child(mesh_inst)

    var col := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(size * 4, 0.4, size * 4)
    col.shape = box
    col.position.y = -0.2
    ground.add_child(col)

    var path := MeshInstance3D.new()
    var torus := TorusMesh.new()
    torus.inner_radius = 5.4
    torus.outer_radius = 6.2
    path.mesh = torus
    var path_mat := StandardMaterial3D.new()
    path_mat.albedo_color = Color(0.55, 0.45, 0.31)
    path_mat.roughness = 1.0
    path.material_override = path_mat
    path.position.y = 0.02
    add_child(path)

func _scatter_decoration() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 1337

    var trunk_mat := StandardMaterial3D.new()
    trunk_mat.albedo_color = Color(0.31, 0.20, 0.12)
    var crown_mat := StandardMaterial3D.new()
    crown_mat.albedo_color = Color(0.18, 0.40, 0.18)

    for i in TREE_COUNT:
        var x := rng.randf_range(-size, size)
        var z := rng.randf_range(-size, size)
        if Vector2(x, z).length() < 8.0:
            continue
        var tree := Node3D.new()
        tree.position = Vector3(x, 0, z)
        var trunk := MeshInstance3D.new()
        var cm := CylinderMesh.new()
        cm.top_radius = 0.20
        cm.bottom_radius = 0.30
        cm.height = 2.4
        trunk.mesh = cm
        trunk.material_override = trunk_mat
        trunk.position.y = 1.2
        tree.add_child(trunk)

        var crown := MeshInstance3D.new()
        var sm := SphereMesh.new()
        sm.radius = 1.4 + rng.randf() * 0.6
        sm.height = (1.4 + rng.randf() * 0.6) * 2.0
        crown.mesh = sm
        crown.material_override = crown_mat
        crown.position.y = 3.4
        tree.add_child(crown)

        add_child(tree)

    var rock_mat := StandardMaterial3D.new()
    rock_mat.albedo_color = Color(0.49, 0.49, 0.51)
    for i in ROCK_COUNT:
        var x := rng.randf_range(-size, size)
        var z := rng.randf_range(-size, size)
        if Vector2(x, z).length() < 6.0:
            continue
        var rock := MeshInstance3D.new()
        var bm := BoxMesh.new()
        bm.size = Vector3(rng.randf_range(0.4, 1.2), rng.randf_range(0.3, 0.8), rng.randf_range(0.4, 1.2))
        rock.mesh = bm
        rock.material_override = rock_mat
        rock.position = Vector3(x, bm.size.y * 0.5, z)
        rock.rotation.y = rng.randf() * TAU
        add_child(rock)
