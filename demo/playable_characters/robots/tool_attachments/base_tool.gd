# Generic base class for tool attachments
extends RigidBody3D
class_name BaseTool

@onready var connector: Connector = $ConnectorComponent

# The tool's scene's file path
@export var path: String = ""
@export var mass_pos: Vector3 = Vector3.ZERO:
	set(value):
		$CenterOfMassMarker.position = value
		center_of_mass = value
		mass_pos = value

func get_speed_mod():
	return 1.0 # To be overwritten by descendants
