extends Node

func _ready():
	# Don't run fullscreen in VR, just waste performance
	# OS.window_fullscreen = Settings.fullscreen
	
	# Start VR mode
	$Player.initialise()
	
	# load our main menu
	go_to_main_menu()


func go_to_main_menu():
	var menu = ResourceLoader.load("res://menu/menu_vr.tscn")
	change_scene(menu)


func replace_main_scene(resource):
	call_deferred("change_scene", resource)


func change_scene(resource : Resource):
	var node : BaseLevel = resource.instance()
	node.visible = false

	for child in $Level.get_children():
		$Level.remove_child(child)
		child.queue_free()
	$Level.add_child(node)

	node.connect("quit", self, "go_to_main_menu")
	node.connect("replace_main_scene", self, "replace_main_scene")

	# reset player orientation and position
	ARVRServer.center_on_hmd(ARVRServer.RESET_BUT_KEEP_TILT, true)

	# now position our player at our spawn point
	$Player.transform = node.get_spawn_point_transform()
	$Player.pointers_enabled = node.enable_pointers
	$Player.movement_enabled = node.enable_movement
	$Player.robot_enabled = node.enable_robot

	node.visible = true
