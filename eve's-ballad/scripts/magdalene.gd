extends CharacterBody2D

@export var SPEED = 200.0
const GRAVITY = 800.0

@onready var sprite = $AnimatedSprite2D

func _ready():
	print("Magdalene ready, spawn_position: ", Global.spawn_position)
	if Global.spawn_position != null:
		position = Global.spawn_position
		Global.spawn_position = null
		sprite.flip_h = true  # face left when spawning from outside

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Movement
	var direction = 0
	if Input.is_key_pressed(KEY_A):
		direction = -1
	elif Input.is_key_pressed(KEY_D):
		direction = 1

	velocity.x = direction * SPEED

	# Flip sprite based on direction
	if direction != 0:
		sprite.flip_h = direction == -1

	# Animations
	if direction != 0:
		sprite.play("walk")
	else:
		sprite.play("idle")

	move_and_slide()


func _on_basket_pressed() -> void:
	pass # Replace with function body.
