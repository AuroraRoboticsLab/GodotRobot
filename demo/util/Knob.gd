extends Sprite2D

@onready var joystick = $".."

var pressing: bool = false

@onready var max_length = 2600
@export var deadzone = 100

func _ready():
	max_length *= joystick.scale.x
	deadzone *= joystick.scale.x

func _process(delta):
	if not pressing:
		joystick.pos_vector = Vector2.ZERO
		global_position = lerp(global_position, joystick.global_position, 0.5)
		return # Nothing to do if not pressing!
	
	if get_global_mouse_position().distance_to(joystick.global_position) <= max_length:
		global_position = get_global_mouse_position()
	else:
		var angle = joystick.global_position.angle_to_point(get_global_mouse_position())
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

func _on_button_button_up():
	pressing = false

func _on_button_button_down():
	pressing = true
