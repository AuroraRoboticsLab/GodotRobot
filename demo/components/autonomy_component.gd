extends Node3D
class_name AutonomyComponent
# Base class for autonomous robot control

@onready var subject = get_parent()
@onready var nav_agent = $NavigationAgent3D

func create_random_Vector3(vrange):
	return Vector3(randf_range(-vrange,+vrange),randf_range(-vrange,+vrange),randf_range(-vrange,+vrange))

var rand_pos = null
var dir = Vector3.ZERO

func _ready():
	nav_agent.target_reached.connect(_target_reached)

var just_created = false
func _process(_delta):
	if not just_created and GameManager.is_npc:
		have_arrived = false
		rand_pos = create_random_Vector3(10)
		nav_agent.set_target_position(rand_pos)
		just_created = true
	elif not GameManager.is_npc:
		just_created = false

func _physics_process(_delta):
	if not GameManager.is_npc or not rand_pos:
		return
	var dest = nav_agent.get_next_path_position()
	var local_dest = dest - subject.global_position
	dir = local_dest.normalized()
	if abs(local_dest.x) < 0.4 and abs(local_dest.y) < 0.4 and abs(local_dest.z) < 0.4:
		_target_reached()

var have_arrived = false
func _target_reached():
	print("Target reached!")
	just_created = false
	have_arrived = true

# Called when asking for drive direction, from -1 to 1
var do_drive = false
func get_drive():
	var my_dir = -subject.transform.basis.z.normalized()
	if my_dir.dot(subject.linear_velocity.normalized()) < -0.9:
		return 0
	if not have_arrived and do_drive:
		return -1
	else:
		return 0

# Called when asking for steer direction, from -1 to 1
func get_steer():
	if not have_arrived:
		var my_dir = -subject.transform.basis.z.normalized()
		var dir_cross = my_dir.cross(dir)
		var dir_dot = my_dir.dot(dir)
		if dir_dot > 0.8:
			do_drive = true
		else:
			do_drive = false
		if dir_cross.y < -0.05: # Turn right
			return -1
		elif dir_cross.y > 0.05: #Turn left
			return 1
		else:
			return 0
		#return clampf(dir_cross.y, -1, 1)
	else:
		return 0

# Called when seeking input for tool attachment toggling, true or false
func get_toggle_attach():
	return false

# Get [Arm, Bollard, Tilt] inputs, from -1 to 1
# Call subject.arm.arm_joint.get_angle() for current arm angle, in degrees.
# Call subject.arm.bollard_joint.get_angle() for current bollard angle, in degrees.
# Call subject.arm.tilt_joint.get_angle() for current tilt angle, in degrees.
func get_arm_inputs():
	return [0,0,0]
