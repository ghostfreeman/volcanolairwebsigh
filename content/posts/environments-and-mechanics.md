---
title: "Environments and a Player Controller"
date: 2023-02-24T20:48:16-06:00
draft: false
toc: false
images:
tags:
  - game-design
  - godot
---

The time has finally come for an exciting devlog! Fresh off the presses, these posts will provide insight on projects, here at Volcano Lair, and our whopping staff of...one. One unpaid developer between jobs. Many of the things you'll read, have actually been in development for some time. It's going to take time to catch up with the project's current state, but these articles, they take time.

So, lets jump right in on an in-development project. I've been sitting on this for a while as I watched the tooling for Godot improve. One of these spaces is level design tools. While I have used Blender before in the past, it's top-heavy. And I am an old-school gamer, who used to do stupid things in Quake and Half-Life. Blender isn't the tool i'm used to. It was my hopes that something more oriented around CSG-style modelling would be available. I hit the search engines and found a Quake map importer called [Qodot](https://github.com/QodotPlugin/qodot-plugin) covered on YouTube. Combined with [TrenchBroom](https://trenchbroom.github.io/), a Quake level editor, I had the necessary tooling for environments.

My first introduction to both came courtesy of [LucyLavend's](https://lucylavend.com/) tutorial on Qodot, embedded below.

{{< youtube dVagDDRb2jQ >}}

For the test scene: I dropped a plane in TrenchBroom, and a quick and dirty placeholder texture. With a few clicks, the .map file imported without a hitch, and I was able to apply the materials created with ease. Qodot imported the .map, and built the necessary collision meshes.

![Image of TrenchBroom editor](/img/blog/environments-and-movement/trenchbroom_screen.jpg)

The next step in the process was a player and a player controller. I’m no stranger to third person controllers. I’ve used [another contrib controller](https://github.com/khairul169/3rdperson-godot) pre 3.x, and had [updated it](https://github.com/ghostfreeman/3rdperson-godot) to work with 3.x.

{{< youtube Wwhhgz53_HI >}}

I felt this controller lagged behind its contemporaries in the sea of the Soulslike; so I evaluated a few controllers in the Asset Library. Ultimately, [pemguin005’s third person controller](https://github.com/pemguin005/Third-Person-Controller---Godot-Souls-like) won out. It leaned on the Animation StateMachine and was documented, especially on the topic of importing assets from Mixamo. These video tutorials saved me many days of fiddling with Blender. There's a lot of specialized tooling around exporting Mixamo-rigged models straight to Godot preferred formats.

There was some code cleanup involved. Out of a passion to make functionality more readable, methods were moved around. The goal would be to make it more maintainable as a daily driver.

{{< rawhtml >}}
<script src="https://gist.github.com/ghostfreeman/af386533db9bdb8fb8e08c68a2b9d92a.js"></script>
{{< /rawhtml >}}

```gdscript
extends KinematicBody

# Imports 

# Allows to pick your animation tree from the inspector
export (NodePath) var PlayerAnimationTree
export onready var animation_tree = get_node(PlayerAnimationTree)
onready var playback = animation_tree.get("parameters/playback");

# Allows to pick your chracter's mesh from the inspector
export (NodePath) var PlayerCharacterMesh
export onready var player_mesh = get_node(PlayerCharacterMesh)

# Gamplay mechanics and Inspector tweakables
export var gravity = 9.8
export var jump_force = 9
export var walk_speed = 1.3
export var run_speed = 5.5
export var dash_power = 12 # Controls roll and big attack speed boosts

# Animation node names
var roll_node_name = "Roll"
var idle_node_name = "Idle"
var walk_node_name = "Walk"
var run_node_name = "Run"
var jump_node_name = "Jump"
var attack1_node_name = "Attack1"
var attack2_node_name = "Attack2"
var bigattack_node_name = "BigAttack"
var death_node_name = "Death"

# Condition States
var is_attacking : bool = bool()
var is_rolling : bool = bool()
var is_walking : bool = bool()
var is_running : bool = bool()

# Physics values
var direction = Vector3()
var horizontal_velocity = Vector3()
var aim_turn = float()
var movement = Vector3()
var vertical_velocity = Vector3()
var movement_speed = int()
var angular_acceleration = int()
var acceleration = int()

# Context Panel
var is_context_on : bool = false

# Lock jumping (for various UI actions)
var is_jumping_locked : bool = false

# Lock interact (for various UI actions)
var is_interact_locked : bool = false

# Nodes in Scene 
onready var InteractRayCast : RayCast = $Camroot/h/v/Camera/InteractRay
onready var poison_timer : Timer = $CharacterStatusTimers/PoisonTimer
onready var player_death_sound : AudioStreamPlayer3D = $Sounds/PlayerDeath

# Signals
signal looking_at_interactive
signal interacting_with_interactive
signal not_looking_at_interactive
signal looking_at_character_with_dialog
signal interacting_with_chracter_with_dialog
signal not_looking_at_character_with_dialog
# signal player_hit
signal free_camera
signal lock_camera

# System Methods

## Fired on scene load
func _ready() -> void: 
	# Connecting signals
	var hud = get_node("/root/Spatial/HUD") 
	PlayerVitals.connect("player_is_dead", self, "player_has_died")
	hud.connect("in_dialogue", self, "lock_dialog_ui_elements")
	hud.connect("out_of_dialogue", self, "unlock_dialog_ui_elements")

	# Camera based Rotation
	direction = Vector3.BACK.rotated(Vector3.UP, $Camroot/h.global_transform.basis.get_euler().y)

## Fired with every input event
func _input(event) -> void: # All major mouse and button input events
	if event is InputEventMouseMotion:
		aim_turn = -event.relative.x * 0.015 # animates player with mouse movement while aiming 
	
	if event.is_action_pressed("aim"): # Aim button triggers a strafe walk and camera mechanic
		direction = $Camroot/h.global_transform.basis.z

## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	check_frustrum_look()

## Called at every Physics tick, which is before every frame.
##
## This contains the resounding corpus of our game logic, as recommended
## by Godot.
func _physics_process(delta) -> void:
	rollattack()
	bigattack()
	attack1()
	attack2()
	roll()
	
	var on_floor = is_on_floor() # State control for is jumping/falling/landing
	var h_rot = $Camroot/h.global_transform.basis.get_euler().y
	
	movement_speed = 0
	angular_acceleration = 10
	acceleration = 15

	# Gravity mechanics and prevent slope-sliding
	if not is_on_floor(): 
		vertical_velocity += Vector3.DOWN * gravity * 2 * delta
	else: 
		vertical_velocity = -get_floor_normal() * gravity / 3
	
	# Defining attack state: Add more attacks animations here as you add more!
	if (attack1_node_name in playback.get_current_node()) or (attack2_node_name in playback.get_current_node()) or (bigattack_node_name in playback.get_current_node()): 
		is_attacking = true
	else: 
		is_attacking = false
		
	# Return a summary of objects in the game world that intersect on where the camera is looking
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(Vector3(0, 0, 0), Vector3(100, 100, 100))

	# Giving BigAttack some Slide
	if bigattack_node_name in playback.get_current_node(): 
		acceleration = 3

	# Defining Roll state and limiting movment during rolls
	if roll_node_name in playback.get_current_node(): 
		is_rolling = true
		acceleration = 2
		angular_acceleration = 2
	else: 
		is_rolling = false
	
	# Jump input and Mechanics
	if Input.is_action_just_pressed("jump") and ((is_attacking != true) and (is_rolling != true)) and is_on_floor():
		if not is_jumping_locked:
			vertical_velocity = Vector3.UP * jump_force
		
	# Quit Game
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()
		
	# Pause Menu
	if Input.is_action_just_pressed("pause"):
		pass
		
	# Self Poison (Testing)
	if Input.is_action_just_pressed("inflict_poison"):
		if !PlayerVitals.is_poisoned:
			var absorb_poison = PlayerEffects.calculate_poison_providence_chance()
			
			if !absorb_poison:
				PlayerVitals.is_poisoned = true
				var poison_time = PlayerEffects.calculate_poison_time()
				print("Poison Time: ", str(poison_time))
				poison_timer.set_wait_time(poison_time)
				PlayerEffects.start_poison()
				poison_timer.start()
		
	# Context Menu
	if Input.is_action_just_pressed("context"):
		if (is_context_on):
			is_context_on = false
			emit_signal("lock_camera")
			get_parent().get_node("ContextRoot").hide()
		else:
			is_context_on = true
			emit_signal("free_camera")
			get_parent().get_node("ContextRoot").show()
			
	# Movement input, state and mechanics. *Note: movement stops if attacking
	if (Input.is_action_pressed("forward") ||  Input.is_action_pressed("backward") ||  Input.is_action_pressed("left") ||  Input.is_action_pressed("right")):
		direction = Vector3(Input.get_action_strength("left") - Input.get_action_strength("right"),
					0,
					Input.get_action_strength("forward") - Input.get_action_strength("backward"))
		direction = direction.rotated(Vector3.UP, h_rot).normalized()
		is_walking = true
		
	# Sprint input, state and speed
		if (Input.is_action_pressed("sprint")) and (is_walking == true): 
			movement_speed = run_speed
			is_running = true
		else: # Walk State and speed
			movement_speed = walk_speed
			is_running = false
	else: 
		is_walking = false
		is_running = false
		
	if Input.is_action_pressed("aim"):  # Aim/Strafe input and  mechanics
		player_mesh.rotation.y = lerp_angle(player_mesh.rotation.y, $Camroot/h.rotation.y, delta * angular_acceleration)

	else: # Normal turn movement mechanics
		player_mesh.rotation.y = lerp_angle(player_mesh.rotation.y, atan2(direction.x, direction.z) - rotation.y, delta * angular_acceleration)
	
	# Movment mechanics with limitations during rolls/attacks
	if ((is_attacking == true) or (is_rolling == true)): 
		horizontal_velocity = horizontal_velocity.linear_interpolate(direction.normalized() * .01 , acceleration * delta)
	else: # Movement mechanics without limitations 
		horizontal_velocity = horizontal_velocity.linear_interpolate(direction.normalized() * movement_speed, acceleration * delta)
	
	# Interact
	if Input.is_action_just_pressed("interact"):
		if not is_interact_locked:
			print("Interact thrown")
			var object = return_frustrum_item()
			print("Object in frustrum: ", object)
			# if object != null:
				# TODO Send signal to handle Item
				# object.queue_free()
			
	# Subtract HP
	if Input.is_action_just_pressed("subtract_hp"):
		print("Subtracting HP")
		PlayerVitals.decrease_health(5)
		
	# Subtract Psi
	if Input.is_action_just_pressed("subtract_psi"):
		print("Subtracing Psi")
		PlayerVitals.decrease_psi(5)
	
	# The Physics Sauce. Movement, gravity and velocity in a perfect dance.
	movement.z = horizontal_velocity.z + vertical_velocity.z
	movement.x = horizontal_velocity.x + vertical_velocity.x
	movement.y = vertical_velocity.y
	move_and_slide(movement, Vector3.UP)

	# ========= State machine controls =========
	# The booleans of the on_floor, is_walking etc, trigger the 
	# advanced conditions of the AnimationTree, controlling animation paths
	
	# on_floor manages jumps and falls
	animation_tree["parameters/conditions/IsOnFloor"] = on_floor
	animation_tree["parameters/conditions/IsInAir"] = !on_floor
	# Moving and running respectively
	animation_tree["parameters/conditions/IsWalking"] = is_walking
	animation_tree["parameters/conditions/IsNotWalking"] = !is_walking
	animation_tree["parameters/conditions/IsRunning"] = is_running
	animation_tree["parameters/conditions/IsNotRunning"] = !is_running
	# Attacks and roll don't use these boolean conditions, instead
	# they use "travel" or "start" to one-shot their animations.

# Custom Methods

## Rolls the player on the floor.
func roll() -> void:
	## Dodge button input with dash and interruption to basic actions
	if Input.is_action_just_pressed("roll"):
		if !roll_node_name in playback.get_current_node() and !jump_node_name in playback.get_current_node() and !bigattack_node_name in playback.get_current_node():
			playback.start(roll_node_name) #"start" not "travel" to speedy teleport to the roll!
			horizontal_velocity = direction * dash_power

## Executes the Short Hand Attack
func attack1() -> void: 
	# If not doing other things, start attack1
	if (idle_node_name in playback.get_current_node() or walk_node_name in playback.get_current_node()) and is_on_floor():
		if Input.is_action_just_pressed("attack"):
			if (is_attacking == false):
				playback.travel(attack1_node_name)

## Executes the dual hand attack
func attack2() -> void: 
	# If attack1 is animating, combo into attack 2
	if attack1_node_name in playback.get_current_node(): # Big Attack if sprinting, adds a dash
		if Input.is_action_just_pressed("attack"):
			playback.travel(attack2_node_name)
			
## Executes the third type of attack
func attack3() -> void: 
	# If attack2 is animating, combo into attack 3. This is a template.
	if attack1_node_name in playback.get_current_node(): 
		if Input.is_action_just_pressed("attack"):
			pass #no current animation, but add it's playback here!
	
## Executes the roll attack, typically tied in after a roll attack
func rollattack() -> void: 
	# If attack pressed while rolling, do a special attack afterwards.
	if roll_node_name in playback.get_current_node(): 
		if Input.is_action_just_pressed("attack"):
			horizontal_velocity = direction * dash_power
			playback.travel(bigattack_node_name) #change this animation for a different attack
			
## Executes the big attack
func bigattack() -> void: 
	# If attack pressed while springing, do a special attack
	if run_node_name in playback.get_current_node(): # Big Attack if sprinting, adds a dash
		if Input.is_action_just_pressed("attack"):
			horizontal_velocity = direction * dash_power
			playback.travel(bigattack_node_name) #Add and Change this animation node for a different attack

## Checks the Interact frustrum raycast to see if any object is colliding, and returns it.
##
## This was originally written for testing and is not actively being used, it is deprecated
## and should be removed in the future
func check_collider_look() -> void:
	var collider = InteractRayCast.get_collider()
	if collider != null:
		if collider.is_in_group("Environment") != true:
			print("Floorcheck Collider hit against ", collider)
			# TODO Send signal for other collider types

## Checks the Interact frustrum raycast for any colliding objects, prints a status of what item type it is
## (based on the group), and emits a "looking_at_interactive" signal. Similarly, if the frustrum is
## not looking at anything, signal "not_looking_at_interactive" is thrown.
func check_frustrum_look() -> void:
	var collider = InteractRayCast.get_collider()
	if collider != null:
		if collider.is_in_group("Environment") != true:
			# print("Frustrum Collider hit against ", collider)
			# print("Groups: ", collider.get_groups())
			
			for group in collider.get_groups():
				match group:
					"Item":
						emit_signal("looking_at_interactive")
						# print("We have an item!")
						# collider.item_used()
					"Dialog":
						emit_signal("looking_at_interactive")
						#print("We have a dialog-ready object!")
	else:
		emit_signal("not_looking_at_interactive")

## Checks the Interact frustrum raycast for any object and returns it if is an Item or Dialog.
## Additionally, it will emit signals "looking_at_interactive" and "interacting_with_interactive."
func return_frustrum_item():
	var collider = InteractRayCast.get_collider()
	if collider != null:
		if collider.is_in_group("Environment") != true:
			if collider.is_in_group("Item") == true:
				emit_signal("looking_at_interactive")
				emit_signal("interacting_with_interactive")
				collider.item_interacted()
				return collider
			elif collider.is_in_group("Dialog") == true:
				emit_signal("looking_at_interactive")
				emit_signal("interacting_with_interactive")
				collider.item_interacted()
				return collider
	
# Signal Methods

func _on_PoisonTimer_timeout():
	poison_timer.stop()
	PlayerVitals.is_poisoned = false
	PlayerEffects.end_poison()
	
func player_has_died():
	playback.start(death_node_name)
	player_death_sound.play()

func lock_dialog_ui_elements():
	lock_jumping()
	lock_interact()

func unlock_dialog_ui_elements():
	unlock_jumping()
	unlock_interact()

func lock_jumping():
	is_jumping_locked = true

func unlock_jumping():
	is_jumping_locked = false
	
func lock_interact():
	is_interact_locked = true
	
func unlock_interact():
	is_interact_locked = false
```

During the cleanup, I introduced a bug where it forces camera rotation on the X axis clockwise after a second or so of no input. It's been a sore oversight, but hasn’t been a high priority compared to new feature adds. My long term plan is to address this, or revert changes back to the origin. There’s always a chance this all gets rewritten.

{{< youtube 3zQMv-RRaek >}}

Combined, these two changes make for an ideal player controller for further development.

Thanks again for reading, if you still are. Stay tuned, more posts are coming in the future.
