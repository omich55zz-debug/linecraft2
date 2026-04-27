extends CharacterBody3D
## Player wrapper: HP/MP/XP, click-to-move, auto-attack, skills.

const Data := preload("res://scripts/Data.gd")
const CharacterBuilder := preload("res://scripts/Character.gd")

signal stats_changed
signal target_changed(target)
signal level_up(new_level)
signal floating_text(text, color, world_pos)

@export var move_speed: float = 5.5
var move_target: Vector3 = Vector3.ZERO
var has_move_target: bool = false
var target: Node = null
var dead: bool = false

var race_id: String = "human"
var class_id: String = "fighter"
var race: Dictionary
var klass: Dictionary

var level: int = 1
var xp: int = 0
var xp_next: int = 100
var max_hp: int = 80
var max_mp: int = 20
var hp: int = 80
var mp: int = 20
var atk: int = 12
var m_atk: int = 4
var gold: int = 0
var hp_potions: int = 0
var mp_potions: int = 0
var atk_cd: float = 0.0
var gcd: float = 0.0
var sitting: bool = false
var character_visual: Node3D
var spawn_position: Vector3 = Vector3.ZERO

func _ready() -> void:
    var sel := get_node_or_null("/root/Selection")
    if sel:
        race_id = sel.race_id
        class_id = sel.class_id
    race = Data.race(race_id)
    klass = Data.klass(class_id)

    max_hp = klass.base_hp + int(race.stats.con * 0.5)
    max_mp = klass.base_mp + int(race.stats.men * 0.5)
    hp = max_hp
    mp = max_mp
    atk = klass.atk + int(race.stats.str * 0.2)
    m_atk = klass.m_atk + int(race.stats.int * 0.3)

    var sg := get_node_or_null("/root/SaveGame")
    if sg and sg.data.race_id == race_id and sg.data.class_id == class_id:
        level = int(sg.data.level)
        xp = int(sg.data.xp)
        xp_next = int(sg.data.xp_next)
        gold = int(sg.data.gold)
        hp_potions = int(sg.data.get("hp_potions", 0))
        mp_potions = int(sg.data.get("mp_potions", 0))
        for i in range(1, level):
            max_hp += 20
            max_mp += 8
            atk += 2
        hp = max_hp
        mp = max_mp
    spawn_position = global_position

    collision_layer = 2
    collision_mask = 1

    var col := CollisionShape3D.new()
    var cs := CapsuleShape3D.new()
    cs.radius = 0.45
    cs.height = 1.7
    col.shape = cs
    col.position.y = 0.85
    add_child(col)

    character_visual = CharacterBuilder.new()
    character_visual.race_id = race_id
    character_visual.class_id = class_id
    add_child(character_visual)

    add_to_group("player")
    emit_signal("stats_changed")

func _physics_process(delta: float) -> void:
    if dead: return
    if atk_cd > 0: atk_cd -= delta
    if gcd > 0: gcd -= delta

    if sitting:
        hp = min(max_hp, hp + int(20 * delta))
        mp = min(max_mp, mp + int(20 * delta))
        emit_signal("stats_changed")
        velocity = Vector3.ZERO
        return

    var moving := false
    if target != null and is_instance_valid(target) and not target.dead:
        var to_t: Vector3 = target.global_position - global_position
        to_t.y = 0
        var d := to_t.length()
        if d < 1.8:
            has_move_target = false
            look_at(global_position + to_t, Vector3.UP)
            if atk_cd <= 0 and gcd <= 0:
                _do_basic_attack()
        else:
            move_target = target.global_position
            has_move_target = true

    if has_move_target:
        var to_p: Vector3 = move_target - global_position
        to_p.y = 0
        if to_p.length() > 0.25:
            var dir := to_p.normalized()
            velocity.x = dir.x * move_speed
            velocity.z = dir.z * move_speed
            look_at(global_position + dir, Vector3.UP)
            move_and_slide()
            moving = true
            character_visual.walk_step(delta)
        else:
            has_move_target = false
            velocity = Vector3.ZERO
    if not moving:
        velocity = Vector3.ZERO
        character_visual.idle()

    if hp < max_hp:
        hp = min(max_hp, hp + int(2 * delta))
        emit_signal("stats_changed")
    if mp < max_mp:
        mp = min(max_mp, mp + int(3 * delta))
        emit_signal("stats_changed")

func _do_basic_attack() -> void:
    atk_cd = 1.5
    gcd = 1.0
    character_visual.trigger_attack()
    var t = target
    var dmg := atk + randi() % 5
    await get_tree().create_timer(0.20).timeout
    if is_instance_valid(t) and not t.dead:
        _spawn_hit_burst(t.global_position + Vector3(0, 1.0, 0), Color(1, 0.78, 0.32))
        t.take_damage(dmg)
        emit_signal("floating_text", "-%d" % dmg, Color(1, 0.85, 0.4), t.global_position + Vector3(0, 1.6, 0))
        if t.dead:
            _gain_xp(t.kind.xp)
            var loot: Array = t.kind.loot
            var coins: int = randi_range(int(loot[0]), int(loot[1]))
            _drop_coin_pile(t.global_position, coins)
            _record_quest_kill(t.kind_id)

func use_skill_power() -> void:
    if gcd > 0 or mp < 8 or target == null or not is_instance_valid(target) or target.dead:
        return
    _spawn_power_flash()
    mp -= 8
    gcd = 1.5
    character_visual.trigger_attack()
    var t = target
    var dmg := atk * 2 + randi() % 7
    await get_tree().create_timer(0.20).timeout
    if is_instance_valid(t) and not t.dead:
        _spawn_hit_burst(t.global_position + Vector3(0, 1.0, 0), Color(1, 0.95, 0.45))
        t.take_damage(dmg)
        emit_signal("floating_text", "-%d ★" % dmg, Color(1, 0.95, 0.5), t.global_position + Vector3(0, 1.6, 0))
        if t.dead:
            _gain_xp(t.kind.xp)
            var loot: Array = t.kind.loot
            var coins: int = randi_range(int(loot[0]), int(loot[1]))
            _drop_coin_pile(t.global_position, coins)
            _record_quest_kill(t.kind_id)
    emit_signal("stats_changed")

func _drop_coin_pile(pos: Vector3, amount: int) -> void:
    if amount <= 0: return
    var scene := get_tree().current_scene
    if scene == null:
        add_gold(amount)
        return
    var pile := preload("res://scripts/CoinPile.gd").new()
    pile.amount = amount
    pile.position = Vector3(pos.x, 0.0, pos.z)
    scene.add_child(pile)

func _record_quest_kill(kind_id: String) -> void:
    var q := get_node_or_null("/root/Quests")
    if q: q.record_kill(kind_id)

func _spawn_heal_aura() -> void:
    var scene := get_tree().current_scene
    if scene == null: return
    for i in 12:
        var spark := MeshInstance3D.new()
        var sm := SphereMesh.new()
        sm.radius = 0.10
        sm.height = 0.20
        spark.mesh = sm
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color(0.55, 1.0, 0.55)
        mat.emission_enabled = true
        mat.emission = Color(0.5, 1.0, 0.5)
        mat.emission_energy_multiplier = 2.4
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        spark.material_override = mat
        var ang := i * (TAU / 12.0)
        var r := 0.55
        spark.position = global_position + Vector3(cos(ang) * r, 0.4, sin(ang) * r)
        scene.add_child(spark)
        var tw := scene.create_tween()
        tw.tween_property(spark, "position:y", global_position.y + 2.6, 1.0).set_trans(Tween.TRANS_SINE)
        tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 1.0)
        tw.tween_callback(spark.queue_free)

func _spawn_power_flash() -> void:
    if character_visual == null: return
    var arm: Node3D = character_visual.arm_r
    if arm == null: return
    var flash := MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = 0.55
    sm.height = 1.0
    flash.mesh = sm
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(1.0, 0.9, 0.35, 0.7)
    mat.emission_enabled = true
    mat.emission = Color(1.0, 0.9, 0.4)
    mat.emission_energy_multiplier = 3.0
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    flash.material_override = mat
    flash.position = Vector3(0, -0.5, 0)
    arm.add_child(flash)
    var tw := arm.create_tween()
    tw.tween_property(flash, "scale", Vector3(1.6, 1.6, 1.6), 0.35)
    tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.35)
    tw.tween_callback(flash.queue_free)

func use_skill_heal() -> void:
    if gcd > 0 or mp < 12: return
    mp -= 12
    gcd = 1.0
    var heal := 25 + randi() % 11
    hp = min(max_hp, hp + heal)
    _spawn_heal_aura()
    emit_signal("floating_text", "+%d" % heal, Color(0.55, 1.0, 0.65), global_position + Vector3(0, 2.0, 0))
    emit_signal("stats_changed")

func toggle_sit() -> void:
    sitting = not sitting
    emit_signal("stats_changed")

func take_damage(d: int) -> void:
    if dead: return
    hp = max(0, hp - d)
    emit_signal("floating_text", "-%d" % d, Color(1, 0.55, 0.55), global_position + Vector3(0, 2.0, 0))
    emit_signal("stats_changed")
    if hp <= 0:
        _die()

func _die() -> void:
    dead = true
    has_move_target = false
    target = null
    emit_signal("target_changed", null)
    emit_signal("floating_text", "Вы пали!", Color(1, 0.4, 0.4), global_position + Vector3(0, 2.4, 0))
    var tw := create_tween()
    tw.tween_property(character_visual, "rotation:z", PI * 0.45, 0.5)
    tw.tween_interval(2.0)
    tw.tween_callback(_respawn)

func _respawn() -> void:
    dead = false
    var penalty: int = int(xp * 0.1)
    xp = max(0, xp - penalty)
    hp = max_hp
    mp = max_mp
    global_position = spawn_position
    if character_visual:
        character_visual.rotation.z = 0
    emit_signal("floating_text", "Воскрешение", Color(0.6, 1.0, 0.7), global_position + Vector3(0, 2.4, 0))
    emit_signal("stats_changed")
    _save_progress()

func add_gold(amount: int) -> void:
    gold += amount
    emit_signal("floating_text", "+%d 💰" % amount, Color(1, 0.85, 0.3), global_position + Vector3(0, 2.4, 0))
    emit_signal("stats_changed")
    _save_progress()

func _save_progress() -> void:
    var sg := get_node_or_null("/root/SaveGame")
    if sg == null: return
    sg.data.race_id = race_id
    sg.data.class_id = class_id
    sg.data.level = level
    sg.data.xp = xp
    sg.data.xp_next = xp_next
    sg.data.gold = gold
    sg.data.hp_potions = hp_potions
    sg.data.mp_potions = mp_potions
    sg.save_data()

func use_hp_potion() -> void:
    if hp_potions <= 0 or hp >= max_hp: return
    hp_potions -= 1
    var heal := 60
    hp = min(max_hp, hp + heal)
    emit_signal("floating_text", "+%d 🧪" % heal, Color(0.6, 1.0, 0.55), global_position + Vector3(0, 2.0, 0))
    emit_signal("stats_changed")
    _save_progress()

func use_mp_potion() -> void:
    if mp_potions <= 0 or mp >= max_mp: return
    mp_potions -= 1
    var restore := 50
    mp = min(max_mp, mp + restore)
    emit_signal("floating_text", "+%d 💧" % restore, Color(0.5, 0.8, 1.0), global_position + Vector3(0, 2.0, 0))
    emit_signal("stats_changed")
    _save_progress()

func _gain_xp(amount: int) -> void:
    xp += amount
    while xp >= xp_next:
        xp -= xp_next
        level += 1
        xp_next = int(xp_next * 1.5)
        max_hp += 20
        max_mp += 8
        atk += 2
        hp = max_hp
        mp = max_mp
        emit_signal("level_up", level)
    emit_signal("stats_changed")
    _save_progress()

func _spawn_hit_burst(pos: Vector3, color: Color) -> void:
    var scene := get_tree().current_scene
    if scene == null: return
    for i in 8:
        var spark := MeshInstance3D.new()
        var sm := SphereMesh.new()
        sm.radius = 0.08
        sm.height = 0.16
        spark.mesh = sm
        var mat := StandardMaterial3D.new()
        mat.albedo_color = color
        mat.emission_enabled = true
        mat.emission = color
        mat.emission_energy_multiplier = 2.0
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        spark.material_override = mat
        spark.position = pos
        scene.add_child(spark)
        var ang := randf() * TAU
        var pitch_a := randf_range(0.2, 1.4)
        var dist := randf_range(0.4, 1.1)
        var dest := pos + Vector3(cos(ang) * dist, sin(pitch_a) * dist * 0.7, sin(ang) * dist)
        var tw := scene.create_tween()
        tw.tween_property(spark, "position", dest, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
        tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.45)
        tw.tween_callback(spark.queue_free)

func set_target(t: Node) -> void:
    target = t
    emit_signal("target_changed", t)

func clear_target() -> void:
    target = null
    emit_signal("target_changed", null)
