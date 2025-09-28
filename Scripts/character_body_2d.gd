extends CharacterBody2D

func _ready():
	add_to_group ("Player")
const SPEED = 200.0
const JUMP_VELOCITY = -320.0
const ROLL_SPEED = 300.0
const ROLL_DURATION = 0.4
const ROLL_COOLDOWN = 0.4  # in seconds, cooldown time after roll ends
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var was_on_floor = false
var jumps_left = 2  # Changed to double jump
var coyote_time = 0.1  # Grace period for jumping after leaving ground
var coyote_timer = 0.0
var can_move := true


# Roll variables
var is_rolling = false
var roll_timer = 0.0
var roll_direction = 0
var sprite_facing_right = true  # Track sprite direction
var roll_notactive = ROLL_COOLDOWN

func _physics_process(delta: float) -> void:
	
	
	
	if not can_move:
		velocity = Vector2.ZERO
		return  # Skip all movement code
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
	
	# Handle roll timer and cooldown
	if is_rolling:
		roll_timer -= delta
		if roll_timer <= 0:
			is_rolling = false
			roll_timer = 0.0
			roll_notactive = ROLL_COOLDOWN

	roll_notactive -= delta
	if roll_notactive <= 0:
			roll_notactive = 0

	# Handle roll input - can roll in air, uses sprite facing direction
	if Input.is_action_just_pressed("roll") and not is_rolling and roll_notactive==0:
		is_rolling = true
		roll_timer = ROLL_DURATION
		roll_direction = 1 if sprite_facing_right else -1
		velocity.y = 0  # Zero out vertical velocity when starting roll
		# You could add roll animation here
		# animated_sprite.play("roll")
	
	# Add gravity when not rolling
	if not is_rolling and not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle jumping (disabled during roll)
	if Input.is_action_just_pressed("up") and not is_rolling:
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
	var direction := Input.get_axis("left", "right")
	
	# Handle sprite flipping and track facing direction
	if not is_rolling:
		if direction > 0:
			animated_sprite.play("walking")
			animated_sprite.flip_h = false
			sprite_facing_right = true
		elif direction < 0:
			animated_sprite.play("walking")
			animated_sprite.flip_h = true
			sprite_facing_right = false
	
	# Handle horizontal movement
	if is_rolling:
		# Use roll speed and direction, lock vertical movement
		velocity.x = roll_direction * ROLL_SPEED
		velocity.y = 0  # Keep vertical velocity at zero during roll
	elif direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if velocity == Vector2.ZERO:
		animated_sprite.play("breathing")
	
	move_and_slide()
