extends Area2D

var item_name = "Stick"
var is_hovered = false

@onready var sprite = $Sprite2D

func _ready():
	sprite.material = null
	print("Item ready: ", item_name)
	if Global.inventory.has("Stick"):
		queue_free()

func _on_stick_mouse_entered():
	print("Mouse entered stick!")
	var shader_material = ShaderMaterial.new()
	shader_material.shader = load("res://outline.gdshader")
	sprite.material = shader_material

func _on_stick_mouse_exited():
	print("Mouse exited stick!")
	sprite.material = null

func _on_stick_input_event(_viewport, event, _shape_idx):
	print("Input event on stick!")
	if event is InputEventMouseButton and event.pressed:
		print("Stick clicked!")
		get_tree().current_scene.get_node("UI").add_item(item_name, sprite.texture)
		queue_free()
