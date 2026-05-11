extends Area2D

func _on_body_entered(body):
	print("Forest trigger hit by: ", body.name)
	if body is CharacterBody2D and not Global.is_scene_transitioning:
		Global.is_scene_transitioning = true
		# Spawn far enough from the left return trigger to prevent immediate bounce-back.
		Global.spawn_position = Vector2(98, 137)
		var forest = load("res://scripts/firstforest.tscn")
		get_tree().change_scene_to_packed(forest)
