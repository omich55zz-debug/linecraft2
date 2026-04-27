extends Node3D
## Builds the starting outdoor scene: ground, trees, rocks, ambient lighting.

const TREE_COUNT := 60
const ROCK_COUNT := 30
const DAY_LENGTH := 180.0  # full day cycle in seconds

@export var size: float = 80.0

var sun_light: DirectionalLight3D
var sky_material: ProceduralSkyMaterial
var environment: Environment
var time_of_day: float = 0.30  # 0..1, 0=midnight, 0.25=sunrise, 0.5=noon, 0.75=sunset

func _ready() -> void:
    _build_lighting()
    _build_ground()
    _scatter_decoration()

func _process(delta: float) -> void:
    time_of_day = fmod(time_of_day + delta / DAY_LENGTH, 1.0)
    _apply_day_night()

func _apply_day_night() -> void:
    if sun_light == null: return
    var sun_angle: float = (time_of_day - 0.25) * TAU
    sun_light.rotation = Vector3(-sun_angle, deg_to_rad(-35), 0)
    var noon_factor: float = clamp(sin(time_of_day * PI), 0.0, 1.0)
    sun_light.light_energy = lerp(0.10, 1.30, noon_factor)
    sun_light.light_color = Color(1.0, lerp(0.65, 1.0, noon_factor), lerp(0.55, 0.95, noon_factor))
    if sky_material:
        var top_day := Color(0.34, 0.55, 0.78)
        var top_night := Color(0.04, 0.05, 0.10)
        var horiz_day := Color(0.71, 0.84, 0.91)
        var horiz_night := Color(0.10, 0.10, 0.18)
        var horiz_dusk := Color(0.95, 0.55, 0.32)
        var dusk_factor: float = clamp(1.0 - abs(noon_factor - 0.0) - abs(noon_factor - 1.0), 0.0, 1.0)
        var horiz: Color = horiz_night.lerp(horiz_day, noon_factor)
        if noon_factor < 0.4:
            horiz = horiz.lerp(horiz_dusk, dusk_factor * 0.5)
        sky_material.sky_top_color = top_night.lerp(top_day, noon_factor)
        sky_material.sky_horizon_color = horiz
    if environment:
        environment.ambient_light_energy = lerp(0.18, 0.65, noon_factor)
        environment.fog_light_color = Color(0.55, 0.55, 0.65).lerp(Color(0.71, 0.81, 0.86), noon_factor)

func _build_lighting() -> void:
    sun_light = DirectionalLight3D.new()
    sun_light.rotation_degrees = Vector3(-50, -35, 0)
    sun_light.light_energy = 1.05
    sun_light.shadow_enabled = true
    add_child(sun_light)

    var env := WorldEnvironment.new()
    environment = Environment.new()
    environment.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    sky_material = ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color(0.34, 0.55, 0.78)
    sky_material.sky_horizon_color = Color(0.71, 0.84, 0.91)
    sky_material.ground_bottom_color = Color(0.18, 0.21, 0.26)
    sky_material.ground_horizon_color = Color(0.55, 0.62, 0.51)
    sky.sky_material = sky_material
    environment.sky = sky
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    environment.ambient_light_energy = 0.6
    environment.fog_enabled = true
    environment.fog_density = 0.005
    environment.fog_light_color = Color(0.71, 0.81, 0.86)
    env.environment = environment
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
