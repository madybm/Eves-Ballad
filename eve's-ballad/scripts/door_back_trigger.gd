extends Area2D

func _on_body_entered(body):
	if body is CharacterBody2D:
		Global.spawn_position = Vector2(1451, -286)
		var house = load("res://scripts/house.tscn")
		get_tree().change_scene_to_packed(house)
