extends BaseLevel

var res_loader: ResourceInteractiveLoader = null
var loading_thread: Thread = null

onready var ui = $UI

onready var loading = $Loading

var loading_node : Control

func _ready():
	var sound_effects = $BackgroundCache/RedRobot/SoundEffects
	for child in sound_effects.get_children():
		child.unit_db = -200
	
	var ui_node : Control = ui.get_scene_instance()
	if ui_node:
		ui_node.connect("play_pressed", self, "_on_play_pressed")
	
	loading_node = loading.get_scene_instance()

func interactive_load(loader):
	while true:
		var status = loader.poll()
		if status == OK:
			if loading_node:
				loading_node.set_value((loader.get_stage() * 100) / loader.get_stage_count())
			continue
		elif status == ERR_FILE_EOF:
			if loading_node:
				loading_node.set_value(100)
			$Loading/DoneTimer.start()
			break
		else:
			print("Error while loading level: " + str(status))
			ui.show()
			loading.hide()
			break


func loading_done(loader):
	loading_thread.wait_to_finish()
	emit_signal("replace_main_scene", loader.get_resource())
	res_loader = null
	# Weirdly, "res_loader = null" is needed as otherwise
	# loading the resource again is not possible.


func _on_loading_done_timer_timeout():
	loading_done(res_loader)


func _on_play_pressed():
	ui.hide()
	loading.show()
	var path = "res://level/level_vr.tscn"
	if ResourceLoader.has_cached(path):
		emit_signal("replace_main_scene", ResourceLoader.load(path))
	else:
		res_loader = ResourceLoader.load_interactive(path)
		loading_thread = Thread.new()
		#warning-ignore:return_value_discarded
		loading_thread.start(self, "interactive_load", res_loader)






