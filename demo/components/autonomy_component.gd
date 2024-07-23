extends Node3D
class_name AutonomyComponent
# Base class for autonomous robot control

@onready var subject = get_parent()
@onready var nav_agent = $NavigationAgent3D

func create_random_Vector3(vrange):
	return Vector3(randf_range(-vrange,+vrange),randf_range(-vrange,+vrange),randf_range(-vrange,+vrange))

var rand_pos = null
var dir = Vector3.ZERO
var total_target_time = 0.0
var just_created = false
func _process(delta):
	if GameManager.is_npc and (not just_created or total_target_time > 60.0):
		have_arrived = false
		rand_pos = create_random_Vector3(9)
		nav_agent.set_target_position(rand_pos)
		if total_target_time > 60.0:
			print("Time > 1 minute. Giving up on target.")
		total_target_time = 0.0
		just_created = true
	else:
		total_target_time += delta

var havent_moved_time = 0.0
var prev_local_dest = Vector3.ZERO
var prev_dir = Vector3.ZERO
func _physics_process(delta):
	if not GameManager.is_npc or not rand_pos:
		return
	var dest = nav_agent.get_next_path_position()
	var local_dest = dest - subject.global_position
	if (local_dest-prev_local_dest).length_squared() < 0.15 and dir.dot(prev_dir) > 0.95:
		# We haven't moved very far
		havent_moved_time += delta
	else:
		prev_local_dest = local_dest
		prev_dir = dir
		havent_moved_time = 0.0
	if havent_moved_time > 7.0:
		try_get_unstuck(delta, local_dest)
	
	dir = local_dest.normalized()
	if local_dest.length() < 0.7:
		_target_reached()

func try_get_unstuck(delta, local_dest):
	subject.linear_velocity += Vector3(0, 1.8*delta, 0)
	subject.linear_velocity += local_dest*delta*1.5

var have_arrived = false
@onready var targets_reached = 0
func _target_reached():
	print("Target reached!")
	just_created = false
	have_arrived = true
	targets_reached += 1
	print("Total targets reached: ", targets_reached)

# Called when asking for drive direction, from -1 to 1
var do_drive = false
func get_drive():
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
		if dir_dot > 0.9:
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
