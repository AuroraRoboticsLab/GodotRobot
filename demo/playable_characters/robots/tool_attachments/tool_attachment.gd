# Generic base class for tool attachments
@tool
extends RigidBody3D
class_name ToolAttachment

@onready var connector: Connector = $ConnectorComponent

# The tool's scene's file path
@export var path: String = ""
@export var mass_pos: Vector3 = Vector3.ZERO:
	set(value):
		$CenterOfMass.position = value
		center_of_mass = value
		mass_pos = value

func _ready() -> void:
	center_of_mass = mass_pos
