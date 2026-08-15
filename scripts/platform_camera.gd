class_name PlatformCamera2D
extends Camera2D


@export_category("Vertical Dead Zone")
@export_range(0.0, 1.0, 0.05) var top_margin := 0.4
@export_range(0.0, 1.0, 0.05) var bottom_margin := 0.3

var _target: Node2D


func _ready() -> void:
	_apply_follow_settings()
	set_physics_process(false)


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_target):
		freeze()
		return

	_sync_with_target()


func follow(target: Node2D) -> void:
	if target == null:
		push_error("PlatformCamera2D cannot follow a null target.")
		return

	_target = target
	_sync_with_target()
	enabled = true
	set_physics_process(true)
	reset_smoothing()


func freeze() -> void:
	set_physics_process(false)


func resume() -> void:
	if not is_instance_valid(_target):
		return

	set_physics_process(true)


func set_camera_bounds(bounds: Rect2i) -> void:
	if not bounds.has_area():
		push_error("PlatformCamera2D requires camera bounds with a positive size.")
		return

	limit_left = bounds.position.x
	limit_top = bounds.position.y
	limit_right = bounds.end.x
	limit_bottom = bounds.end.y
	limit_enabled = true
	reset_smoothing()


func _apply_follow_settings() -> void:
	drag_horizontal_enabled = false
	drag_vertical_enabled = true
	drag_top_margin = top_margin
	drag_bottom_margin = bottom_margin
	drag_vertical_offset = 0.0
	position_smoothing_enabled = false
	limit_smoothed = false
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS


func _sync_with_target() -> void:
	global_position = _target.global_position.round()
