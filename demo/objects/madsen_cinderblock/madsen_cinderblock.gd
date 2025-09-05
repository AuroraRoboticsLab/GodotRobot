extends RigidBody3D

var path = "res://objects/madsen_cinderblock/madsen_cinderblock.tscn"

func _ready():
	center_of_mass = $CenterOfMass.position
