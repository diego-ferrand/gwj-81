extends Area2D

func _on_body_entered(body: CharacterBody2D) -> void:
	if body.is_in_group("damageable") and body != self.get_parent().get_parent():
		body.take_damage(1)
