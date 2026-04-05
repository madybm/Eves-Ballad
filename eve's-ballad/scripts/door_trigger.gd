extends Area2D

func _on_body_entered(body):
	if body is CharacterBody2D:
		print("Loading outside...")
		var outside = load("res://scripts/outside.tscn")
		get_tree().change_scene_to_packed(outside)
