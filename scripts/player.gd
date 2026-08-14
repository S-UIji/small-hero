extends CharacterBody2D


const MOVE_LEFT_ACTION := &"move_left"
const MOVE_RIGHT_ACTION := &"move_right"
const JUMP_ACTION := &"jump"

@export_category("Movement")
@export var max_run_speed := 130.0
@export var ground_acceleration := 900.0
@export var ground_deceleration := 1100.0
@export_range(0.0, 1.0, 0.05) var air_control_multiplier := 0.7
@export var jump_velocity := -300.0
@export var max_fall_speed := 500.0

@export_category("Jump Forgiveness")
@export var coyote_time := 0.1
@export var jump_buffer_time := 0.12
@export_range(0.0, 1.0, 0.05) var jump_release_multiplier := 0.5

var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0


func _physics_process(delta: float) -> void:
	_update_jump_timers(delta)
	_apply_horizontal_movement(delta)
	_try_jump()
	_apply_gravity(delta)
	_apply_variable_jump_height()
	move_and_slide()


func _update_jump_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)

	if Input.is_action_just_pressed(JUMP_ACTION):
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)


func _apply_horizontal_movement(delta: float) -> void:
	var input_direction := Input.get_axis(MOVE_LEFT_ACTION, MOVE_RIGHT_ACTION)
	var target_speed := input_direction * max_run_speed
	var acceleration := ground_acceleration if not is_zero_approx(input_direction) else ground_deceleration

	if not is_on_floor():
		acceleration *= air_control_multiplier

	velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)


func _try_jump() -> void:
	if _jump_buffer_timer <= 0.0 or _coyote_timer <= 0.0:
		return

	velocity.y = jump_velocity
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0


func _apply_gravity(delta: float) -> void:
	if is_on_floor() and velocity.y >= 0.0:
		return

	velocity += get_gravity() * delta
	velocity.y = minf(velocity.y, max_fall_speed)


func _apply_variable_jump_height() -> void:
	if Input.is_action_just_released(JUMP_ACTION) and velocity.y < 0.0:
		velocity.y *= jump_release_multiplier
