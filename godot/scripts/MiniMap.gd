extends Control
## Square mini-map. Renders player + monsters + NPCs as dots in a top-down view.

const RADIUS_M: float = 35.0      # world meters shown around player
const SIZE_PX: float = 160.0      # control size in pixels (square)

@export var player_path: NodePath
var player: Node3D = null
var monster_root: Node3D = null
var npc_root: Node3D = null

func _ready() -> void:
    custom_minimum_size = Vector2(SIZE_PX, SIZE_PX)
    size = Vector2(SIZE_PX, SIZE_PX)

func _process(_delta: float) -> void:
    if player == null:
        var sc := get_tree().current_scene
        if sc:
            player = sc.get_node_or_null("Player")
            monster_root = sc.get_node_or_null("Monsters")
            npc_root = sc.get_node_or_null("Npcs")
    queue_redraw()

func _world_to_map(pos: Vector3) -> Vector2:
    if player == null: return Vector2(SIZE_PX * 0.5, SIZE_PX * 0.5)
    var rel := Vector3(pos.x - player.global_position.x, 0, pos.z - player.global_position.z)
    var u: float = clamp(rel.x / RADIUS_M, -1.0, 1.0) * 0.5 + 0.5
    var v: float = clamp(rel.z / RADIUS_M, -1.0, 1.0) * 0.5 + 0.5
    return Vector2(u * SIZE_PX, v * SIZE_PX)

func _draw() -> void:
    var rect := Rect2(Vector2.ZERO, Vector2(SIZE_PX, SIZE_PX))
    draw_rect(rect, Color(0.05, 0.07, 0.10, 0.78), true)
    draw_rect(rect, Color(0.78, 0.78, 0.85, 0.85), false, 1.5)
    if player == null: return
    if npc_root:
        for n in npc_root.get_children():
            if n is Node3D:
                _dot(_world_to_map(n.global_position), 4.0, Color(1.0, 0.85, 0.30))
    if monster_root:
        for m in monster_root.get_children():
            if m is Node3D and not m.has_method("get_class") == false:
                if "dead" in m and m.dead: continue
                var elite: bool = ("is_elite" in m and m.is_elite)
                _dot(_world_to_map(m.global_position), 5.0 if elite else 3.5,
                    Color(1.0, 0.40, 0.40) if not elite else Color(1.0, 0.20, 0.85))
    var pp := _world_to_map(player.global_position)
    _dot(pp, 5.0, Color(0.55, 1.0, 0.55))
    var fwd := -player.global_transform.basis.z
    var endp := pp + Vector2(fwd.x, fwd.z) * 12.0
    draw_line(pp, endp, Color(0.55, 1.0, 0.55, 0.9), 2.0)
    draw_string(get_theme_default_font(), Vector2(SIZE_PX * 0.5 - 5, 14), "N",
        HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.95, 0.95, 1.0, 0.9))

func _dot(p: Vector2, r: float, c: Color) -> void:
    draw_circle(p, r + 0.5, Color(0, 0, 0, 0.85))
    draw_circle(p, r, c)
