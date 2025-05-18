extends CharacterBody2D

enum State { IDLE, FOLLOW, ATTACK, PATROL, DEAD }
@export var speed: float = 50.0
@export var attack_range: float = 20.0
@export var follow_range: float = 200.0
@export var damage: int = 1
@export var max_health: int = 3
@export var patrol_points: Array[Vector2] = []
@export var patrol_speed: float = 30.0

var current_state: State = State.IDLE
var patrol_index: int = 0
var health: int = max_health
var player: Node2D
var is_attacking = false

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var weapon_hitbox = $WeaponHitbox
@onready var attack_area: Area2D = $WeaponHitbox/Sword
@onready var cooldown_timer: Timer = $AttackCooldown
@onready var healthbar_timer: Timer = $HealthbarTimer
@onready var health_bar: ProgressBar = $HealthBar
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]
@onready var corpse_timeout: Timer = $CorpseTimeout


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")  # Player must be in "player" group
	attack_area.monitoring = false
	animation_tree.active = true
	health_bar.visible = false
	health_bar.max_value = max_health

func _physics_process(delta: float) -> void:
	if player == null or current_state == State.DEAD: return

	var distance = global_position.distance_to(player.global_position)
	match current_state:
		State.IDLE:
			if distance < follow_range:
				current_state = State.FOLLOW
		State.PATROL:
			if distance < follow_range:
				current_state = State.FOLLOW
			else:
				patrol(delta)
		State.FOLLOW:
			if distance > follow_range:
				current_state = State.PATROL
			elif distance <= attack_range:
				current_state = State.ATTACK
			else:
				follow_player(delta)

		State.ATTACK:
			if distance > attack_range:
				current_state = State.FOLLOW
			elif not cooldown_timer.is_stopped():
				pass
			else:
				attack()

	select_animation()


func patrol(delta: float) -> void:
	if patrol_points.size() < 1:
		return

	var target = patrol_points[patrol_index]
	var direction = (target - global_position)
	
	if direction.length() < 5:
		patrol_index = (patrol_index + 1) % patrol_points.size()
	else:
		velocity = direction.normalized() * patrol_speed
		move_and_slide()
func follow_player(delta: float) -> void:
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	update_animation_direction(direction)

func select_animation():
	if current_state == State.DEAD:
		playback.travel("dead")
	elif is_attacking:
		playback.travel("Attack")
	elif velocity == Vector2.ZERO:
		playback.travel("Idle")
	else:
		playback.travel("Walk")

func update_animation_direction(direction: Vector2) -> void:	
	if animation_tree != null:
		animation_tree["parameters/Idle/blend_position"] = direction
		animation_tree["parameters/Walk/blend_position"] = direction
		animation_tree["parameters/Attack/blend_position"] = direction
	
func attack() -> void:
	weapon_hitbox.look_at(player.global_position) 
	weapon_hitbox.rotation -= deg_to_rad(90)
	attack_area.monitoring = true
	is_attacking = true
	cooldown_timer.start()

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		die()
		return
	
	show_health_bar()
	health_bar.value = float(health)

func show_health_bar() -> void:
	health_bar.visible = true
	healthbar_timer.start()

func _on_HealthBarTimer_timeout() -> void:
	health_bar.visible = false

func die() -> void:
	current_state = State.DEAD
	health_bar.value = 0
	select_animation()
	corpse_timeout.start()


func _on_attack_cooldown_timeout():
	attack_area.monitoring = false
	is_attacking = false
	select_animation()


func _on_corpse_timeout_timeout() -> void:
	queue_free()
