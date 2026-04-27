extends Node3D
## Top-level game scene: spawns world, player, monsters, handles input (click-to-move/target).

const Data := preload("res://scripts/Data.gd")
const WorldRoot := preload("res://scripts/World.gd")
const PlayerScript := preload("res://scripts/Player.gd")
const MonsterScript := preload("res://scripts/Monster.gd")
const FollowCamera := preload("res://scripts/FollowCamera.gd")
const NpcScript := preload("res://scripts/Npc.gd")

var player: CharacterBody3D
var camera: Camera3D
var move_arrow: MeshInstance3D
var move_arrow_t: float = 0.0
var monster_kinds := ["wolf", "wolf", "wolf", "boar", "boar", "gnoll", "gnoll", "boar", "wolf", "ork", "boar", "wolf", "gnoll", "bear"]

func _ready() -> void:
    var world := WorldRoot.new()
    world.name = "World"
    add_child(world)

    player = PlayerScript.new()
    player.name = "Player"
    player.position = Vector3.ZERO
    add_child(player)

    camera = FollowCamera.new()
    camera.current = true
    add_child(camera)
    camera.target_path = NodePath("../Player")
    camera.target = player

    _spawn_monsters()
    _spawn_npcs()
    _build_move_arrow()
    _build_hud()

func _spawn_npcs() -> void:
    var npc := NpcScript.new()
    npc.name = "Trader"
    npc.position = Vector3(3.5, 0, -2.5)
    add_child(npc)

func _build_hud() -> void:
    var hud_scene := load("res://scenes/HUD.tscn")
    if hud_scene == null:
        return
    var hud: Node = hud_scene.instantiate()
    add_child(hud)
    if hud.has_method("set"):
        hud.set("player_path", NodePath("../Player"))

func _build_move_arrow() -> void:
    move_arrow = MeshInstance3D.new()
    var torus := TorusMesh.new()
    torus.inner_radius = 0.55
    torus.outer_radius = 0.85
    move_arrow.mesh = torus
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.43, 1.0, 0.55, 0.95)
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.emission_enabled = true
    mat.emission = Color(0.43, 1.0, 0.55)
    mat.emission_energy_multiplier = 0.6
    mat.no_depth_test = true
    move_arrow.material_override = mat
    move_arrow.visible = false
    add_child(move_arrow)

func _spawn_monsters() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 42
    for kind_id in monster_kinds:
        var m := MonsterScript.new()
        m.kind_id = kind_id
        var ang := rng.randf() * TAU
        var dist := rng.randf_range(9, 30)
        m.position = Vector3(cos(ang) * dist, 0, sin(ang) * dist)
        add_child(m)
        m.died.connect(_on_monster_died)

func _on_monster_died(m) -> void:
    var kind_id: String = m.kind_id
    var rng := RandomNumberGenerator.new()
    var ang := rng.randf() * TAU
    var dist := rng.randf_range(12, 30)
    var pos := Vector3(cos(ang) * dist, 0, sin(ang) * dist)
    await get_tree().create_timer(8.0).timeout
    var nm := MonsterScript.new()
    nm.kind_id = kind_id
    nm.position = pos
    add_child(nm)
    nm.died.connect(_on_monster_died)

func _process(delta: float) -> void:
    if move_arrow.visible:
        move_arrow_t -= delta
        var t := Time.get_ticks_msec() / 250.0
        move_arrow.scale = Vector3.ONE * (1.0 + sin(t) * 0.08)
        if move_arrow_t <= 0:
            move_arrow.visible = false

    for m in get_tree().get_nodes_in_group("monsters"):
        if m.dead or m.target != null: continue
        var d: float = m.global_position.distance_to(player.global_position)
        if d < m.aggro_range:
            m.target = player

    if Input.is_action_just_pressed("skill_2"):
        player.use_skill_power()
    if Input.is_action_just_pressed("skill_3"):
        player.use_skill_heal()
    if Input.is_action_just_pressed("sit"):
        player.toggle_sit()
    if Input.is_action_just_pressed("deselect"):
        player.clear_target()
        var hud := get_node_or_null("HUD")
        if hud and hud.has_method("close_shop"):
            hud.close_shop()
    if Input.is_key_pressed(KEY_4) and not _key4_held:
        player.use_hp_potion()
        _key4_held = true
    elif not Input.is_key_pressed(KEY_4):
        _key4_held = false
    if Input.is_key_pressed(KEY_5) and not _key5_held:
        player.use_mp_potion()
        _key5_held = true
    elif not Input.is_key_pressed(KEY_5):
        _key5_held = false

var _key4_held := false
var _key5_held := false

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _handle_world_click(event.position)
    elif event is InputEventScreenTouch and event.pressed and event.index == 0:
        _handle_world_click(event.position)

func _handle_world_click(screen_pos: Vector2) -> void:
    var space := get_world_3d().direct_space_state
    var from := camera.project_ray_origin(screen_pos)
    var dir := camera.project_ray_normal(screen_pos)
    var to := from + dir * 200.0

    var q_npc := PhysicsRayQueryParameters3D.create(from, to, 0b1000)
    var res_npc := space.intersect_ray(q_npc)
    if res_npc and res_npc.collider and res_npc.collider.is_in_group("npcs"):
        var dist_to_npc: float = player.global_position.distance_to(res_npc.collider.global_position)
        if dist_to_npc < 4.0:
            var hud := get_node_or_null("HUD")
            if hud and hud.has_method("open_shop"):
                hud.open_shop()
        else:
            var npc_pos: Vector3 = res_npc.collider.global_position
            player.move_target = npc_pos
            player.has_move_target = true
            move_arrow.global_position = Vector3(npc_pos.x, 0.10, npc_pos.z)
            move_arrow.visible = true
            move_arrow_t = 1.5
        return

    var q := PhysicsRayQueryParameters3D.create(from, to, 0b0100)
    var res := space.intersect_ray(q)
    if res and res.collider and res.collider.is_in_group("monsters") and not res.collider.dead:
        player.set_target(res.collider)
        return

    var q2 := PhysicsRayQueryParameters3D.create(from, to, 0b0001)
    var res2 := space.intersect_ray(q2)
    if res2 and res2.has("position"):
        var p: Vector3 = res2.position
        player.clear_target()
        player.move_target = Vector3(p.x, 0, p.z)
        player.has_move_target = true
        move_arrow.global_position = Vector3(p.x, 0.10, p.z)
        move_arrow.visible = true
        move_arrow_t = 1.5
