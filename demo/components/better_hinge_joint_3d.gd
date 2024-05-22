extends Generic6DOFJoint3D

@onready var x_upper_angle_limit: float = 0:
	get:
		return get("angular_limit_x/upper_angle")
	set(value):
		set("angular_limit_x/upper_angle", value)
		
@onready var x_lower_angle_limit: float = 0:
	get:
		return get("angular_limit_x/lower_angle")
	set(value):
		set("angular_limit_x/lower_angle", value)
		
@export var x_max_upper_angle: float = 0
@export var x_max_lower_angle: float = 0
@onready var moving: bool = false

func _physics_process(delta):
	pass

func move_motor(force: float, current_angle):
	moving = true
	print("Moving: ", rad_to_deg(current_angle))
	x_upper_angle_limit = deg_to_rad(x_max_upper_angle)
	x_lower_angle_limit = deg_to_rad(x_max_lower_angle)
	set("angular_motor_x/target_velocity", force)
	
func stop_motor(current_angle: float):
	if moving:
		set("angular_motor_x/target_velocity", 0)
		print("Stopping at ", rad_to_deg(current_angle))
		x_upper_angle_limit = -current_angle
		x_lower_angle_limit = -current_angle
		moving = false
