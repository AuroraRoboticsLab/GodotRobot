extends Generic6DOFJoint3D

enum Axis { X, Y, Z }
@export var rotation_axis: Axis = Axis.X
@onready var axis_string: String = {Axis.X: "x", Axis.Y: "y", Axis.Z: "z"}[rotation_axis]

@onready var angle_limit: float = 0:
	set(value):
		set("angular_limit_"+axis_string+"/upper_angle", value)
		set("angular_limit_"+axis_string+"/lower_angle", value)
		angle_limit = value
		
@export var max_upper_angle: float = 0
@export var max_lower_angle: float = 0

@onready var moving: bool = false
@onready var force: float = 0
@onready var prev_set_angle: float = INF

func _physics_process(delta):
	if moving:
		var new_angle = prev_set_angle
		if prev_set_angle != INF:
			new_angle += (force*delta) * 0.5
		else:
			new_angle = get_angle() + (force*delta)
		if new_angle > deg_to_rad(max_upper_angle):
			set_angle(deg_to_rad(max_upper_angle))
		elif new_angle < deg_to_rad(max_lower_angle):
			set_angle(deg_to_rad(max_lower_angle))
		else:
			set_angle(new_angle)
			prev_set_angle = new_angle

func move_motor(move_force: float):
	moving = true
	force = move_force

func stop_motor():
	moving = false

func get_angle():
	var node = get_node_or_null(node_b)
	if node:
		return -node.get_rotation()[rotation_axis]
	else:
		print("WARN: Getting angle of nonexistant node.")

func set_angle(angle: float):
	angle_limit = angle
