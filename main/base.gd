extends Spatial

class_name BaseLevel

signal quit
#warning-ignore:unused_signal
signal replace_main_scene # Useless, but needed as there is no clean way to check if a node exposes a signal

export var enable_pointers = false
export var enable_movement = false
export var enable_robot = false

func get_spawn_point_transform() -> Transform:
	return $SpawnPoint.global_transform
