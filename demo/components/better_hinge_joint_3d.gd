extends Generic6DOFJoint3D

enum Axis { X, Y, Z }
@export var rotation_axis: Axis = Axis.X
@onready var axis_string: String = "x" if rotation_axis == Axis.X else "y" if rotation_axis == Axis.Y else "z"
@onready var axis_idx: int = 0 if rotation_axis == Axis.X else 1 if rotation_axis == Axis.Y else 2

@onready var upper_angle_limit: float = 0:
	get:
		return get("angular_limit_"+axis_string+"/upper_angle")
	set(value):
		set("angular_limit_"+axis_string+"/upper_angle", value)

@onready var lower_angle_limit: float = 0:
	get:
		return get("angular_limit_ "+axis_string+"/lower_angle")
	set(value):
		set("angular_limit_"+axis_string+"/lower_angle", value)
		
@export var max_upper_angle: float = 0
@export var max_lower_angle: float = 0
@onready var moving: bool = false
@onready var force: float = 0

func _physics_process(delta):
	if moving:
		var new_angle = get_angle() + (force*delta)
		if new_angle > deg_to_rad(max_upper_angle):
			set_angle(deg_to_rad(max_upper_angle))
		elif new_angle < deg_to_rad(max_lower_angle):
			set_angle(deg_to_rad(max_lower_angle))
		else:
			set_angle(new_angle)
		

func move_motor(move_force: float):
	moving = true
	force = move_force
	
	
func stop_motor():
	moving = false
		
func get_angle():
	var node = get_node_or_null(node_b)
	if node:
		return -node.get_rotation()[axis_idx]
	else:
		print("WARN: Getting angle of nonexistant node.")
	
func set_angle(angle: float):
	upper_angle_limit = angle
	lower_angle_limit = angle
