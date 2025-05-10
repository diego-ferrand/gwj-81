extends Area2D

func _on_area_entered(area: Area2D) -> void:
	print("Area entered")
	if area.is_in_group("damageable"):
		print("area can take damage")
		area.take_damage(1)
