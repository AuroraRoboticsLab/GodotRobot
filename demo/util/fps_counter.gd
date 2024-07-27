extends Node3D

# From  https://www.reddit.com/r/godot/comments/8p3lm0/fps_counter_in_game/
var time = 0.0
@export var fps = 0

func round_to_dec(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)

# Takes seconds and formats to HH:MM:SS
func seconds_to_time_string(seconds):
	var hours = int(seconds / (60*60))
	var minutes = int((seconds-(hours*3600)) / 60)
	var secs = int(seconds-(minutes*60))
	var hours_string = str(hours) if int(hours/10)>0 else "0"+str(hours)
	var minutes_string = str(minutes) if int(minutes/10)>0 else "0"+str(minutes)
	var secs_string = str(round_to_dec(secs, 0)) if int(secs/10)>0 else "0"+str(round_to_dec(secs, 0))
	return hours_string+":"+minutes_string+":"+secs_string

var PRINT_TIME = 2.0 if not GameManager.is_console_host else 10.0
var last_fps = -10.0
var fps_delta = time - last_fps

func _process(delta):
	time += delta
	fps_delta = time - last_fps
	if fps_delta >= PRINT_TIME:
		last_fps = time
		fps = Engine.get_frames_per_second()
		if GameManager.is_console_host:
			print(seconds_to_time_string(time), "    fps: ",fps,"    ",round_to_dec(1000.0/fps, 2),"  ms/frame")
		else:
			print("fps: ",fps,"    ",round_to_dec(1000.0/fps, 2),"  ms/frame")
