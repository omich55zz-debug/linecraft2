extends Camera3D
## L2-style follow camera. RMB drag rotates yaw, wheel zooms, follows player smoothly.

@export var target_path: NodePath
var target: Node3D
var distance: float = 14.0
var min_dist: float = 4.0
var max_dist: float = 30.0
var yaw: float = PI * 0.25
var pitch: float = 1.0
var min_pitch: float = 0.25
var max_pitch: float = 1.4
var dragging: bool = false

var _pinch_start_dist: float = 0.0
var _pinch_start_zoom: float = 0.0
var _active_touches := {}

func _ready() -> void:
    target = get_node_or_null(target_path)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_RIGHT:
            dragging = event.pressed
        elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
            distance = clamp(distance - 1.5, min_dist, max_dist)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            distance = clamp(distance + 1.5, min_dist, max_dist)
    elif event is InputEventMouseMotion and dragging:
        yaw -= event.relative.x * 0.005
        pitch = clamp(pitch + event.relative.y * 0.004, min_pitch, max_pitch)
    elif event is InputEventScreenTouch:
        if event.pressed:
            _active_touches[event.index] = event.position
        else:
            _active_touches.erase(event.index)
        if _active_touches.size() == 2:
            var ps: Array = _active_touches.values()
            _pinch_start_dist = (ps[0] as Vector2).distance_to(ps[1])
            _pinch_start_zoom = distance
    elif event is InputEventScreenDrag:
        _active_touches[event.index] = event.position
        if _active_touches.size() == 1:
            yaw -= event.relative.x * 0.006
            pitch = clamp(pitch + event.relative.y * 0.005, min_pitch, max_pitch)
        elif _active_touches.size() == 2 and _pinch_start_dist > 0:
            var ps2: Array = _active_touches.values()
            var d2: float = (ps2[0] as Vector2).distance_to(ps2[1])
            distance = clamp(_pinch_start_zoom * (_pinch_start_dist / max(d2, 1.0)), min_dist, max_dist)

func _process(_delta: float) -> void:
    if target == null:
        target = get_node_or_null(target_path)
        if target == null: return
    var t: Vector3 = target.global_position
    var cos_p := cos(pitch)
    var sin_p := sin(pitch)
    var x := t.x + sin(yaw) * distance * cos_p
    var z := t.z + cos(yaw) * distance * cos_p
    var y := t.y + sin_p * distance + 1.0
    global_position = Vector3(x, y, z)
    look_at(t + Vector3(0, 1.0, 0), Vector3.UP)
