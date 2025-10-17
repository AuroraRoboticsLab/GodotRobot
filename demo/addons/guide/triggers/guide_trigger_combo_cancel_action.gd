@icon("res://addons/guide/guide_internal.svg")
class_name GUIDETriggerComboCancelAction
extends Resource

@export var action:GUIDEAction
@export_flags("Triggered:1", "Started:2", "Ongoing:4", "Cancelled:8","Completed:16") 
var completion_events:int = GUIDETriggerCombo.ActionEventType.TRIGGERED

var _has_fired:bool = false

func is_same_as(other:GUIDETriggerComboCancelAction) -> bool:
	return action == other.action and \
		completion_events == other.completion_events

func _prepare():
	if completion_events & GUIDETriggerCombo.ActionEventType.TRIGGERED:
		action.triggered.connect(_fired)
	if completion_events & GUIDETriggerCombo.ActionEventType.STARTED:
		action.started.connect(_fired)
	if completion_events & GUIDETriggerCombo.ActionEventType.ONGOING:
		action.ongoing.connect(_fired)
	if completion_events & GUIDETriggerCombo.ActionEventType.CANCELLED:
		action.cancelled.connect(_fired)
	if completion_events & GUIDETriggerCombo.ActionEventType.COMPLETED:
		action.completed.connect(_fired)
	_has_fired = false
		
		
func _fired():
	_has_fired = true
	
