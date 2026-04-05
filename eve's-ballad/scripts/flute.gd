extends Area2D

var item_name = "Flute"
var is_hovered = false

@onready var sprite = $Sprite2D

func _ready():
	sprite.material = null
	print("Item ready: ", item_name)
	if Global.inventory.has("Flute"):
		queue_free()

func _on_flute_mouse_entered():
	print("Mouse entered flute!")
	var shader_material = ShaderMaterial.new()
	shader_material.shader = load("res://outline.gdshader")
	sprite.material = shader_material

func _on_flute_mouse_exited():
	print("Mouse exited flute!")
	sprite.material = null

func _on_flute_input_event(_viewport, event, _shape_idx):
	print("Input event on flute!")
	if event is InputEventMouseButton and event.pressed:
		print("Flute clicked!")
		get_tree().current_scene.get_node("UI").add_item(item_name, sprite.texture)
		queue_free()
