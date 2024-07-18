# Generic base class for tool attachments
extends RigidBody3D
class_name ToolAttachment

@export var path: String = ""
@onready var connector = $ConnectorComponent
