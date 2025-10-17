extends Node3D
class_name AutonomyComponent
# Base class for automating robot control
# Expects to be the child of a RigidBody3D

signal autonomy_changed(is_autonomous: bool)
@export var _autonomous: bool = false
func is_autonomous() -> bool:
	return _autonomous
func set_autonomous(in_autonomous: bool) -> void:
	if in_autonomous == _autonomous:
		return
	_autonomous = in_autonomous
	autonomy_changed.emit(_autonomous)
	_auto_state = AutoState.STANDBY
	_curr_drive_values = Vector3.ZERO
	_curr_arm_values = Vector3.ZERO
	_sprinting = false
	_jumping = false
	_is_attaching = false

# There will be exported vars for different sensor components that we can directly access
@export var nav_agent: NavigationAgent3D

func create_random_Vector3(vrange):
	return Vector3(randf_range(-vrange,+vrange),randf_range(-vrange,+vrange),randf_range(-vrange,+vrange))

enum AutoState { STANDBY, PATHFINDING  }
var _auto_state: AutoState = AutoState.STANDBY
var goto_pos: Vector3

func _ready() -> void:
	MQTTHandler.incoming_robot_data.connect(_on_incoming_robot_data)
	
	MQTTHandler.broker_connected.connect(_on_broker_connected)
	MQTTHandler.broker_connection_failed.connect(_on_broker_connection_failed)
	MQTTHandler.broker_disconnected.connect(_on_broker_disconnected)

func _on_broker_connected(_mqtt_host: String) -> void:
	# Subscribe to all of our incoming autonomy values
	var sub_topic: String = "luminsim/components/robots/"+get_parent().name+"/incoming/#"
	MQTTHandler.subscribe(sub_topic, 1)

func _on_broker_connection_failed(_mqtt_host: String) -> void:
	set_autonomous(false)

func _on_broker_disconnected(_mqtt_host: String) -> void:
	set_autonomous(false)

var debugging: bool = true
var _sprinting: bool = false
var _jumping: bool = false
var _jump_interval: float = 0.2
var _jump_elapsed: float = 0.2
func _physics_process(delta):
	if not _autonomous:
		return
	if _auto_state == AutoState.PATHFINDING:
		return
	_last_drive_value_elapsed += delta
	_jump_elapsed += delta
	
	if _jumping and _jump_elapsed >= _jump_interval:
		_jump_elapsed = 0.0
		get_parent().trigger_jump()

func is_sprinting() -> bool:
	return _sprinting

func pathfind_to(pos: Vector3):
	if not is_autonomous():
		set_autonomous(true)
	_auto_state = AutoState.PATHFINDING
	# set_target_position() does not like Vector3.ZERO
	goto_pos = pos if pos != Vector3.ZERO else Vector3(0.01, 0, 0)
	nav_agent.set_target_position(goto_pos)

func _target_reached():
	print("Target reached!")
	_auto_state = AutoState.STANDBY
	set_autonomous(false)

var _prev_yaw_err := 0.0
var _steer_cmd := 0.0
func _internal_pathfind_values() -> Vector3:
	if not _autonomous:
		return Vector3.ZERO
	
	var drive_force := 0.0
	var steer_force := 0.0

	# --- geometry toward target (planar) ---
	var to_target := goto_pos - global_transform.origin
	to_target.y = 0.0
	var dist := to_target.length()
	if dist < 0.001:
		return Vector3.ZERO

	var forward := (-global_transform.basis.z)
	forward.y = 0.0
	if forward.length_squared() < 1e-6:
		return Vector3.ZERO
	forward = forward.normalized()

	var dir := to_target.normalized()
	var right := global_transform.basis.x
	right.y = 0.0
	right = right.normalized()

	var forward_dot := forward.dot(dir)   # +1 ahead, -1 behind
	var right_dot := right.dot(dir)       # +right, -left

	# Signed yaw error (radians): right positive
	var yaw_err := atan2(right_dot, forward_dot)

	# --- control params ---
	const DEAD := deg_to_rad(10.0)     # no steering inside this cone
	const DRIVE_CONE := deg_to_rad(90) # only drive when within this cone
	const KP := 0.9                    # proportional gain
	const KD := 0.25                   # derivative gain
	const ALPHA := 0.2                 # EMA smoothing for steering
	const SLEW := 4.0                  # max change in steer per second (units/s)
	const STOP_DIST := 0.3             # optional: stop close to target (meters)

	var dt := 1.0 / float(Engine.get_physics_ticks_per_second())

	# Deadband to kill chatter around zero
	if abs(yaw_err) < DEAD:
		yaw_err = 0.0

	# PD controller on heading
	var d_err := (yaw_err - _prev_yaw_err) / dt
	var raw_cmd := KP * yaw_err + KD * d_err
	raw_cmd = clamp(raw_cmd, -1.0, 1.0)

	# Low-pass smooth
	var target_cmd := _steer_cmd + ALPHA * (raw_cmd - _steer_cmd)

	# Slew-rate limit
	var max_step := SLEW * dt
	var step: float = clamp(target_cmd - _steer_cmd, -max_step, max_step)
	_steer_cmd += step

	steer_force = _steer_cmd

	# Drive only if roughly facing target and not too close
	if dist > STOP_DIST and abs(yaw_err) < DRIVE_CONE:
		# Taper speed by heading alignment (0..1) and distance (soft)
		var align: float = 1.0 - (abs(yaw_err) / DRIVE_CONE)    # 1 when straight, 0 at 90°
		var dist_scale: float = clamp(dist / 2.0, 0.2, 1.0)     # gentle ramp with min speed
		drive_force = clamp(align * dist_scale, 0.0, 1.0)
	else:
		drive_force = 0.0

	_prev_yaw_err = yaw_err
	return Vector3(steer_force, 0.0, -drive_force)

func _on_incoming_robot_data(in_id: String, in_category: String, in_data: Dictionary) -> void:
	if in_id != get_parent().name: # Not for us!
		return
	match in_category:
		"drive-values":
			var in_drive_values: Vector3 = Vector3(in_data["x"], in_data["y"], in_data["z"])
			set_drive_values(in_drive_values)
			if in_data.has("sprint"):
				_sprinting = in_data["sprint"]
			if in_data.has("jump"):
				_jumping = in_data["jump"]
		"arm-values":
			var in_arm_values: Vector3 = Vector3(in_data["x"], in_data["y"], in_data["z"])
			if in_data.has("interact"):
				_is_attaching = in_data["interact"]
			set_arm_values(in_arm_values)
		"status":
			set_autonomous(in_data["autonomous"])

var _curr_drive_values: Vector3 = Vector3.ZERO
var _last_drive_value_elapsed: float = 0.0
var _max_last_drive_value: float = 3.0
func set_drive_values(drive_values: Vector3) -> void:
	_curr_drive_values = drive_values
	_last_drive_value_elapsed = 0.0

func get_drive_values() -> Vector3:
	if not _autonomous:
		return Vector3.ZERO
	if _auto_state == AutoState.PATHFINDING:
		return _internal_pathfind_values()
	# Stop driving if we haven't received a command for too long
	if _last_drive_value_elapsed >= _max_last_drive_value:
		return Vector3.ZERO
	return _curr_drive_values

# Called when seeking input for tool attachment toggling, true or false
var _is_attaching: bool = false
func get_toggle_attach():
	return _is_attaching

var _curr_arm_values: Vector3 = Vector3.ZERO
var _last_arm_value_elapsed: float = 0.0
var _max_last_arm_value: float = 3.0
func set_arm_values(arm_values: Vector3):
	_curr_arm_values = arm_values
	_last_arm_value_elapsed = 0.0

func get_arm_values() -> Vector3:
	if not _autonomous:
		return Vector3.ZERO
	# Stop arm moving if we haven't received a command for too long
	if _last_arm_value_elapsed >= _max_last_arm_value:
		return Vector3.ZERO
	return _curr_arm_values
