extends Sprite2D

@onready var joystick = $".."

var pressing: bool = false

@onready var max_length = 2600
@export var deadzone = 100
@onready var curr_touch_index = null

var curr_drag_pos = null

func _ready():
	max_length *= joystick.scale.x
	deadzone *= joystick.scale.x

func _input(event):
	if event is InputEventScreenTouch and event.pressed:
		if event.position.distance_to(joystick.global_position) <= max_length:
			curr_touch_index = event.index
			curr_drag_pos = event.position
			pressing = true
	elif event is InputEventScreenTouch and not event.pressed:
		if event.index == curr_touch_index:
			curr_touch_index = null
			pressing = false
	# Event is dragging and matches our index
	elif event is InputEventScreenDrag and event.index == curr_touch_index:
		curr_drag_pos = event.position

func _process(_delta):
	if not pressing:
		joystick.pos_vector = Vector2.ZERO
		global_position = lerp(global_position, joystick.global_position, 0.5)
		return # Nothing to do if not pressing!
	if curr_drag_pos.distance_to(joystick.global_position) <= max_length:
		global_position = curr_drag_pos
	else:
		var angle = joystick.global_position.angle_to_point(curr_drag_pos)
		global_position.x = joystick.global_position.x + cos(angle)*max_length
		global_position.y = joystick.global_position.y + sin(angle)*max_length
	calculate_vector()

func calculate_vector():
	if abs(global_position.x - joystick.global_position.x) >= deadzone:
		joystick.pos_vector.x = (global_position.x - joystick.global_position.x)/max_length
	else:
		joystick.pos_vector.x = 0
	if abs(global_position.y - joystick.global_position.y) >= deadzone:
		joystick.pos_vector.y = (global_position.y - joystick.global_position.y)/max_length
	else:
		joystick.pos_vector.y = 0
