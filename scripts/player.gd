extends CharacterBody2D


enum State { IDLE, RUN, JUMP, FALL, HURT, DEAD }

const MOVE_LEFT_ACTION := &"move_left"
const MOVE_RIGHT_ACTION := &"move_right"
const JUMP_ACTION := &"jump"
const IDLE_ANIMATION := &"idle"
const RUN_ANIMATION := &"run"
const JUMP_ANIMATION := &"jump"
const FALL_ANIMATION := &"fall"
const LOW_JUMP_ANIMATION := &"jump_low"
const LOW_FALL_ANIMATION := &"fall_low"
const HURT_ANIMATION := &"hurt"
const DEATH_ANIMATION := &"death"

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

@export_category("Airborne Animation")
@export_range(0.0, 0.3, 0.01) var roll_commit_hold_time := 0.14

var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _jump_hold_timer := 0.0
var _high_jump_committed := false
var _state: State = State.IDLE

@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_play_state_animation()


func _physics_process(delta: float) -> void:
	_update_jump_timers(delta)
	_apply_horizontal_movement(delta)
	_try_jump()
	_apply_gravity(delta)
	_apply_variable_jump_height()
	_update_jump_style(delta)
	move_and_slide()
	_update_movement_state()


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
	_update_facing(input_direction)

	if not is_on_floor():
		acceleration *= air_control_multiplier

	velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)


func _try_jump() -> void:
	if _jump_buffer_timer <= 0.0 or _coyote_timer <= 0.0:
		return

	velocity.y = jump_velocity
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0
	_jump_hold_timer = 0.0
	_high_jump_committed = false


func _apply_gravity(delta: float) -> void:
	if is_on_floor() and velocity.y >= 0.0:
		return

	velocity += get_gravity() * delta
	velocity.y = minf(velocity.y, max_fall_speed)


func _apply_variable_jump_height() -> void:
	if Input.is_action_just_released(JUMP_ACTION) and velocity.y < 0.0:
		velocity.y *= jump_release_multiplier


func _update_jump_style(delta: float) -> void:
	if _high_jump_committed or velocity.y >= 0.0:
		return
	if not Input.is_action_pressed(JUMP_ACTION):
		return

	_jump_hold_timer += delta
	if _jump_hold_timer < roll_commit_hold_time:
		return

	_high_jump_committed = true
	if _state == State.JUMP:
		_play_state_animation()
		_animated_sprite.frame = 1


func _update_facing(input_direction: float) -> void:
	if is_zero_approx(input_direction):
		return

	_animated_sprite.flip_h = input_direction < 0.0


func _update_movement_state() -> void:
	if _state == State.HURT or _state == State.DEAD:
		return

	if is_on_floor():
		_jump_hold_timer = 0.0
		_high_jump_committed = false

	if not is_on_floor():
		_set_state(State.JUMP if velocity.y < 0.0 else State.FALL)
	elif not is_zero_approx(velocity.x):
		_set_state(State.RUN)
	else:
		_set_state(State.IDLE)


func _set_state(next_state: State) -> void:
	if _state == next_state:
		return

	_state = next_state
	_play_state_animation()


func _play_state_animation() -> void:
	match _state:
		State.IDLE:
			_animated_sprite.play(IDLE_ANIMATION)
		State.RUN:
			_animated_sprite.play(RUN_ANIMATION)
		State.JUMP:
			_animated_sprite.play(JUMP_ANIMATION if _high_jump_committed else LOW_JUMP_ANIMATION)
		State.FALL:
			_animated_sprite.play(FALL_ANIMATION if _high_jump_committed else LOW_FALL_ANIMATION)
		State.HURT:
			_animated_sprite.play(HURT_ANIMATION)
		State.DEAD:
			_animated_sprite.play(DEATH_ANIMATION)
