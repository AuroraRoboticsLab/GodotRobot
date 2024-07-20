# Generic base class for tool attachments
extends RigidBody3D
class_name ToolAttachment

# The tool's scene's file path
@export var path: String = ""
@onready var connector = $ConnectorComponent
