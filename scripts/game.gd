extends Node2D


@export_category("Camera Bounds")
@export var camera_bounds_override := Rect2i()

@onready var _terrain: TileMapLayer = $TileMapLayer
@onready var _player: CharacterBody2D = $Player
@onready var _camera: PlatformCamera2D = $Camera2D


func _ready() -> void:
	_configure_camera()


func _configure_camera() -> void:
	var camera_bounds := camera_bounds_override
	if not camera_bounds.has_area():
		camera_bounds = _get_terrain_bounds()

	if not camera_bounds.has_area():
		push_warning("Camera limits could not be configured because the terrain is empty.")
	else:
		_camera.set_camera_bounds(camera_bounds)

	_camera.follow(_player)


func _get_terrain_bounds() -> Rect2i:
	var used_rect := _terrain.get_used_rect()
	if not used_rect.has_area() or _terrain.tile_set == null:
		return Rect2i()

	var half_tile_size := Vector2(_terrain.tile_set.tile_size) * 0.5
	var last_cell := used_rect.position + used_rect.size - Vector2i.ONE
	var top_left := _terrain.to_global(_terrain.map_to_local(used_rect.position) - half_tile_size)
	var bottom_right := _terrain.to_global(_terrain.map_to_local(last_cell) + half_tile_size)
	var bounds_start := Vector2i(floori(top_left.x), floori(top_left.y))
	var bounds_end := Vector2i(ceili(bottom_right.x), ceili(bottom_right.y))

	return Rect2i(bounds_start, bounds_end - bounds_start)
