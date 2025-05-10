extends CharacterBody2D

@export var speed: float = 100.0
@export var attack_duration: float = 0.3

var is_attacking: bool = false
var input_vector := Vector2.ZERO
var attacjubg
@onready var animation_tree = $AnimationTree
@onready var sword_hitbox = $SwordHitbox
@onready var sprite_2d = $Sprite2D
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]

func _physics_process(delta: float) -> void:
	if is_attacking:
		velocity = Vector2.ZERO
		end_of_process()
		return
	
	input_vector = Input.get_vector("left", "right", "up", "down") 

	if input_vector.length_squared() > 0:
		input_vector = input_vector.normalized()

	velocity = input_vector * speed
	end_of_process()
	
func end_of_process():
	move_and_slide()
	select_animation()
	update_animation_parameters()
	
func select_animation():
	if is_attacking:
		playback.travel("Attack")
	elif velocity == Vector2.ZERO:
		playback.travel("Idle")
	else:
		playback.travel("Walk")
	
func update_animation_parameters():
	if input_vector == Vector2.ZERO:
		return
		
	animation_tree["parameters/Idle/blend_position"] = input_vector
	animation_tree["parameters/Walk/blend_position"] = input_vector
	animation_tree["parameters/Attack/blend_position"] = input_vector
	

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("primary") and not is_attacking:
		swing_sword()
		
		
func swing_sword() -> void:
	is_attacking = true
	sword_hitbox.monitoring = true


	await get_tree().create_timer(attack_duration).timeout

	sword_hitbox.monitoring = false
	is_attacking = false
