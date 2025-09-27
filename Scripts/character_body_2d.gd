# Player.gd - Updated movement script with sacrifice system
extends CharacterBody2D

const SPEED = 250.0
const JUMP_VELOCITY = -320.0
const ROLL_SPEED = 400.0
const ROLL_DURATION = 0.28
const ROLL_COOLDOWN = 0.8  # Cooldown time after roll ends

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var was_on_floor = false
var jumps_left = 2  # Changed to double jump
var coyote_time = 0.1  # Grace period for jumping after leaving ground
var coyote_timer = 0.0

# Roll variables
var is_rolling = false
var roll_timer = 0.0
var roll_direction = 0
var roll_cooldown_timer = 0.0  # Cooldown timer
var sprite_facing_right = true  # Track sprite direction

# Control sacrifice system
var disabled_controls = []
var movement_locked = false  # New variable to completely lock movement

func set_disabled_controls(controls: Array):
	disabled_controls = controls.duplicate()
	movement_locked = false  # Unlock movement when controls are set
	print("Player controls disabled: ", disabled_controls)

func lock_movement():
	movement_locked = true
	print("Player movement locked!")

func unlock_movement():
	movement_locked = false
	print("Player movement unlocked!")

func _is_control_enabled(control: String) -> bool:
	return not control in disabled_controls

func _physics_process(delta: float) -> void:
	# Don't process movement if locked
	if movement_locked:
		# Still apply gravity but no player input
		if not is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		return
		
	# Handle coyote time
	if is_on_floor():
		was_on_floor = true
		jumps_left = 2  # Changed to double jump
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta
		
	# Detect when leaving the ground (for first jump consumption)
	if was_on_floor and not is_on_floor() and coyote_timer <= 0:
		if jumps_left == 2:  # Only consume jump if we haven't jumped manually
			jumps_left = 1  # Leave 1 air jump available
		was_on_floor = false
	
	# Handle roll timer
	if is_rolling:
		roll_timer -= delta
		if roll_timer <= 0:
			is_rolling = false
			roll_timer = 0.0
			roll_cooldown_timer = ROLL_COOLDOWN  # Start cooldown when roll ends
	
	# Handle roll cooldown timer
	if roll_cooldown_timer > 0:
		roll_cooldown_timer -= delta
	
	# Handle roll input - only if dash is enabled
	if (_is_control_enabled("dash") and 
		Input.is_action_just_pressed("roll") and 
		not is_rolling and 
		roll_cooldown_timer <= 0):
		is_rolling = true
		roll_timer = ROLL_DURATION
		roll_direction = 1 if sprite_facing_right else -1
		velocity.y = 0  # Zero out vertical velocity when starting roll
		# You could add roll animation here
		# animated_sprite.play("roll")
	
	# Add gravity when not rolling
	if not is_rolling and not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle jumping (disabled during roll) - only if jump is enabled
	if (_is_control_enabled("jump") and 
		Input.is_action_just_pressed("up") and 
		not is_rolling):
		if is_on_floor() or coyote_timer > 0:
			# Ground jump or coyote time jump
			velocity.y = JUMP_VELOCITY
			jumps_left = 1  # Reset to 1 air jump remaining
			coyote_timer = 0  # Cancel coyote time
		elif jumps_left > 0:
			# Air jump
			velocity.y = JUMP_VELOCITY
			jumps_left -= 1
	
	# Get the input direction and handle the movement/deceleration
	var direction = 0.0
	
	# Check movement controls individually
	if _is_control_enabled("move_right") and Input.is_action_pressed("right"):
		direction += 1.0
	if _is_control_enabled("move_left") and Input.is_action_pressed("left"):
		direction -= 1.0
	
	# Handle sprite flipping and track facing direction
	if not is_rolling:
		if direction > 0:
			animated_sprite.flip_h = false
			sprite_facing_right = true
		elif direction < 0:
			animated_sprite.flip_h = true
			sprite_facing_right = false
	
	# Handle horizontal movement
	if is_rolling:
		# Use roll speed and direction, lock vertical movement
		velocity.x = roll_direction * ROLL_SPEED
		velocity.y = 0  # Keep vertical velocity at zero during roll
	elif direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	move_and_slide()

# Debug function to show current disabled controls
func _input(event):
	if event.is_action_pressed("ui_accept"):  # Enter key for debug
		print("Disabled controls: ", disabled_controls)
		print("Movement locked: ", movement_locked)
		var enabled_controls = []
		for control in ["move_left", "move_right", "jump", "dash"]:
			if _is_control_enabled(control):
				enabled_controls.append(control)
		print("Enabled controls: ", enabled_controls)
