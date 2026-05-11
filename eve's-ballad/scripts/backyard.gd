extends Area2D

func _on_body_entered(body):
	if body is CharacterBody2D and not Global.is_scene_transitioning:
		Global.is_scene_transitioning = true
		# Spawn near the forest entrance in outside, but clear of triggers.
		Global.spawn_position = Vector2(1550, 80)
		var prev = load("res://scripts/outside.tscn")
		get_tree().change_scene_to_packed(prev)
