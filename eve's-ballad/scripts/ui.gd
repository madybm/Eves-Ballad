extends CanvasLayer

@onready var closed_basket = $ClosedBasket
@onready var open_basket = $OpenBasket

var is_open = false
var overlay: ColorRect
var item_sprites = []

func _ready():
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.size = Vector2(1920, 1080)
	overlay.position = Vector2(0, 0)
	overlay.visible = false
	add_child(overlay)
	move_child(overlay, open_basket.get_index())
	
	# Rebuild inventory from Global on scene load
	for i in range(Global.inventory.size()):
		_create_item_sprite(Global.inventory[i], Global.inventory_textures[i])

func _create_item_sprite(item_name: String, texture: Texture2D):
	var item_sprite = Sprite2D.new()
	item_sprite.texture = texture
	
	if item_name == "Flute":
		item_sprite.scale = Vector2(1.5, 1.5)
		item_sprite.position = Vector2(800, 524)
	elif item_name == "Stick":
		item_sprite.scale = Vector2(1.3, 1.3)
		item_sprite.position = Vector2(1600, 524)
	
	add_child(item_sprite)
	item_sprites.append(item_sprite)
	item_sprite.visible = is_open

func add_item(item_name: String, texture: Texture2D):
	# Save to Global so it persists
	Global.inventory.append(item_name)
	Global.inventory_textures.append(texture)
	_create_item_sprite(item_name, texture)

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = event.position
		if closed_basket.get_rect().has_point(closed_basket.to_local(mouse_pos)):
			is_open = !is_open
			open_basket.visible = is_open
			overlay.visible = is_open
			for s in item_sprites:
				s.visible = is_open
