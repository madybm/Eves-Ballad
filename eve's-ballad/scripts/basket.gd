extends TextureButton

@onready var open_basket = $"../OpenBasket"

var is_open = false

func _ready():
	open_basket.visible = false

func _on_pressed():
	is_open = !is_open
	open_basket.visible = is_open
