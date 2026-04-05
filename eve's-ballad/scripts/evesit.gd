extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D

func _ready():
	sprite.play("idle")  # change to your animation name


func _on_flute_mouse_entered() -> void:
	pass # Replace with function body.


func _on_flute_mouse_exited() -> void:
	pass # Replace with function body.


func _on_flute_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	pass # Replace with function body.


func _on_stick_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	pass # Replace with function body.


func _on_stick_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_stick_body_exited(body: Node2D) -> void:
	pass # Replace with function body.
