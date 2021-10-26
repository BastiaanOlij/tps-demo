extends "res://addons/godot-openxr/scenes/first_person_controller_vr.gd"

export var pointers_enabled = false setget set_pointers_enabled
export var movement_enabled = false setget set_movement_enabled
export var robot_enabled = false setget set_robot_enabled

export var reset_button = JOY_BUTTON_7
export var shoot_button = JOY_BUTTON_15

var which_pointer = 1 # 0 = left, 1 = right
var reset_button_state = 0 # 0 = not pressed, 1 = left pressed, 2 = right pressed

onready var fire_cooldown = $FireCooldown
onready var sound_effect_shoot = $SoundEffects/Shoot
onready var shoot_particle = $PlayerAnchor/player/Robot_Skeleton/Skeleton/GunBone/ShootFrom/ShootParticle
onready var muzzle_particle = $PlayerAnchor/player/Robot_Skeleton/Skeleton/GunBone/ShootFrom/MuzzleFlash

func set_pointers_enabled(p_enable):
	pointers_enabled = p_enable
	if is_inside_tree():
		_update_pointers()

func _update_pointers():
	$LeftHand/Function_pointer.enabled = which_pointer == 0 and pointers_enabled
	$RightHand/Function_pointer.enabled = which_pointer == 1 and pointers_enabled

func set_movement_enabled(p_enable):
	movement_enabled = p_enable
	if is_inside_tree():
		_update_movement()

func _update_movement():
	$LeftHand/Function_Teleport.enabled = movement_enabled
	$RightHand/Function_Direct_movement.enabled = movement_enabled

func set_robot_enabled(p_enable):
	robot_enabled = p_enable
	if is_inside_tree():
		_update_robot()

func _update_robot():
	# Note, our menu system that we load at startup has this disabled so we're not showing our robot
	# but we are playing our arm cannon animation to get Roby in the right state before enabling this
	$PlayerAnchor.visible = robot_enabled
	if robot_enabled:
		# TODO react to controller being enabled/disabled
		$PlayerAnchor/player/Robot_Skeleton/Skeleton/SkeletonIK_Left.start()
		$PlayerAnchor/player/Robot_Skeleton/Skeleton/SkeletonIK_Right.start()
	else:
		$PlayerAnchor/player/Robot_Skeleton/Skeleton/SkeletonIK_Left.stop()
		$PlayerAnchor/player/Robot_Skeleton/Skeleton/SkeletonIK_Right.stop()

# Called when the node enters the scene tree for the first time.
func _ready():
	_update_pointers()
	_update_movement()
	_update_robot()

func _process(delta):
	# position our robot body based on our players head position
	var camera_transform : Transform = $ARVRCamera.transform
	var player_transform : Transform

	# We just copy the origin
	player_transform.origin = camera_transform.origin
	
	# now calculate a lookat value
	var lookat : Vector3 = camera_transform.basis.z
	lookat.y = 0.0
	$PlayerAnchor.transform = player_transform.looking_at(player_transform.origin + lookat.normalized(), Vector3.UP)

func _shoot():
	if fire_cooldown.time_left== 0:
		var shoot_transform = $PlayerAnchor/player/Robot_Skeleton/Skeleton/GunBone/ShootFrom.global_transform
		var bullet = preload("res://player/bullet/bullet.tscn").instance()
		get_parent().add_child(bullet)
		bullet.global_transform.origin = shoot_transform.origin
		# If we don't rotate the bullets there is no useful way to control the particles ..
		bullet.look_at(shoot_transform.origin + shoot_transform.basis.y, Vector3.UP)
		bullet.add_collision_exception_with(self)
		shoot_particle.restart()
		shoot_particle.emitting = true
		muzzle_particle.restart()
		muzzle_particle.emitting = true
		fire_cooldown.start()
		sound_effect_shoot.play()

func _on_LeftHand_button_pressed(button):
	if pointers_enabled and which_pointer == 1 and button == $LeftHand/Function_pointer.active_button:
		which_pointer = 0
		_update_pointers()

	if reset_button_state == 0 and button == reset_button:
		reset_button_state = 1
		$ResetTimer.start()

func _on_RightHand_button_pressed(button):
	if pointers_enabled and which_pointer == 0 and button == $RightHand/Function_pointer.active_button:
		which_pointer = 1
		_update_pointers()

	if robot_enabled and button == shoot_button:
		_shoot()

	if reset_button_state == 0 and button == reset_button:
		reset_button_state = 2
		$ResetTimer.start()

func _on_LeftHand_button_release(button):
	if reset_button_state == 1 and button == reset_button:
		reset_button_state = 0
		$ResetTimer.stop()

func _on_RightHand_button_release(button):
	if reset_button_state == 2 and button == reset_button:
		reset_button_state = 0
		$ResetTimer.stop()

func _on_ResetTimer_timeout():
	# we pressed our button for 2 seconds, reset our view
	ARVRServer.center_on_hmd(ARVRServer.RESET_BUT_KEEP_TILT, true)
