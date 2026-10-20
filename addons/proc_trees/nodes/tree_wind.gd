@tool
@icon("res://addons/proc_trees/icons/tree_wind.svg")
class_name TreeWind
extends Node
## Sets the global wind every tree shader reads (shader global `tree_wind`). One per scene is enough;
## animate `strength` for storms. Works in the editor too.

@export_range(0.0, 360.0, 1.0, "suffix:°") var direction := 40.0:
	set(v):
		direction = v
		_apply()
@export_range(0.0, 3.0, 0.01) var strength := 0.5:
	set(v):
		strength = v
		_apply()
## 0 = steady wind, 1 = strong gusts.
@export_range(0.0, 1.0, 0.01) var gustiness := 0.6:
	set(v):
		gustiness = v
		_apply()


func _ready() -> void:
	_apply()


func _apply() -> void:
	TreeMaterials.ensure_globals()
	var a := deg_to_rad(direction)
	RenderingServer.global_shader_parameter_set("tree_wind", Vector4(cos(a), sin(a), strength, gustiness))
