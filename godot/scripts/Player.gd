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
var atk_cd: float = 0.0
var gcd: float = 0.0
var sitting: bool = false
var character_visual: Node3D

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
        t.take_damage(dmg)
        emit_signal("floating_text", "-%d" % dmg, Color(1, 0.85, 0.4), t.global_position + Vector3(0, 1.6, 0))
        if t.dead:
            _gain_xp(t.kind.xp)

func use_skill_power() -> void:
    if gcd > 0 or mp < 8 or target == null or not is_instance_valid(target) or target.dead:
        return
    mp -= 8
    gcd = 1.5
    character_visual.trigger_attack()
    var t = target
    var dmg := atk * 2 + randi() % 7
    await get_tree().create_timer(0.20).timeout
    if is_instance_valid(t) and not t.dead:
        t.take_damage(dmg)
        emit_signal("floating_text", "-%d ★" % dmg, Color(1, 0.95, 0.5), t.global_position + Vector3(0, 1.6, 0))
        if t.dead: _gain_xp(t.kind.xp)
    emit_signal("stats_changed")

func use_skill_heal() -> void:
    if gcd > 0 or mp < 12: return
    mp -= 12
    gcd = 1.0
    var heal := 25 + randi() % 11
    hp = min(max_hp, hp + heal)
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
        dead = true

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

func set_target(t: Node) -> void:
    target = t
    emit_signal("target_changed", t)

func clear_target() -> void:
    target = null
    emit_signal("target_changed", null)
