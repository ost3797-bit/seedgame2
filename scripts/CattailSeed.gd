extends RigidBody2D

var time_passed: float = 0.0
var sway_amplitude: float = 400.0
var sway_frequency: float = 2.0
var base_gravity_scale: float = 0.15

var is_wet: bool = false
var is_captured: bool = false

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("cattail_seeds")
	gravity_scale = base_gravity_scale
	linear_damp = 4.0
	
	# 랜덤 흔들림
	sway_amplitude = randf_range(300.0, 600.0)
	sway_frequency = randf_range(1.5, 3.0)
	time_passed = randf_range(0.0, 10.0)
	
	# 씨앗 이미지 랜덤 지정 (flagseed1~3)
	var seed_idx = randi_range(1, 3)
	var tex = load("res://assets/game/flag/flagseed%d.png" % seed_idx)
	if tex:
		sprite.texture = tex

func _physics_process(delta: float) -> void:
	if is_wet or is_captured:
		return
		
	time_passed += delta
	# 부드러운 좌우 흔들림을 외력(Force)으로 적용 (바람 Impulse와 충돌 방지)
	var sway_force = cos(time_passed * sway_frequency) * sway_amplitude
	apply_central_force(Vector2(sway_force, 0))

func apply_wind(force_vector: Vector2) -> void:
	if is_wet or is_captured:
		return
	apply_central_impulse(force_vector)

func set_wet() -> void:
	is_wet = true
	gravity_scale = 1.0 # 물에 빠져서 가라앉음
	linear_velocity = Vector2.ZERO
	sprite.modulate = Color(0.5, 0.5, 0.5, 0.8)

func set_captured() -> void:
	is_captured = true
	gravity_scale = 0.0
	linear_velocity = Vector2.ZERO
	hide()
	queue_free()
