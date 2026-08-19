extends Node2D

const FONT_PATH := "res://fonts/Cafe24Ssurround-v2.0.ttf"

@onready var bg = $Background
@onready var basket = $Basket
@onready var basket_collision = $Basket/CollisionShape2D

@onready var score_label = $UI/ScoreLabel
@onready var time_label = $UI/TimeLabel
@onready var popup_layer = $PopupLayer

@onready var seed_template = $SeedTemplate

var score := 0
var target_score := 15
var time_left := 30.0
var game_active := false

var spawn_timer := 0.0
var spawn_interval := 0.8

var basket_speed := 600.0

func _ready() -> void:
	if has_node("/root/MobileUI"):
		get_node("/root/MobileUI").hide()
		
	seed_template.hide()
	basket.area_entered.connect(_on_basket_area_entered)
	_start_game()

func _exit_tree() -> void:
	if has_node("/root/MobileUI"):
		get_node("/root/MobileUI").show()

func _start_game() -> void:
	score = 0
	time_left = 30.0
	game_active = true
	_update_ui()
	popup_layer.hide()

func _process(delta: float) -> void:
	if not game_active:
		return
		
	time_left -= delta
	if time_left <= 0:
		time_left = 0
		_game_over(false)
		
	_update_ui()
	_handle_basket_movement(delta)
	_handle_spawning(delta)
	_move_seeds(delta)

func _handle_basket_movement(delta: float) -> void:
	var move_dir = 0.0
	if Input.is_action_pressed("ui_left"):
		move_dir -= 1.0
	if Input.is_action_pressed("ui_right"):
		move_dir += 1.0
		
	if move_dir != 0:
		basket.position.x += move_dir * basket_speed * delta
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var target_x = get_global_mouse_position().x
		basket.position.x = lerp(basket.position.x, target_x, 15.0 * delta)
	
	# 화면 범위 제한 (1920x1080 기준 중앙 0,0 뷰포트이므로 -960 ~ 960)
	if basket.position.x < -800: basket.position.x = -800
	if basket.position.x > 800: basket.position.x = 800

func _handle_spawning(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_timer = spawn_interval
		_spawn_seed()

func _spawn_seed() -> void:
	var new_seed = seed_template.duplicate()
	new_seed.show()
	add_child(new_seed)
	
	# x 위치는 -800 ~ 800
	new_seed.position.x = randf_range(-800.0, 800.0)
	new_seed.position.y = -600.0
	
	new_seed.add_to_group("falling_seeds")
	
	# 씨앗에 낙하 속도 및 회전 속도 부여
	new_seed.set_meta("fall_speed", randf_range(200.0, 350.0))
	new_seed.set_meta("spin_speed", randf_range(2.0, 5.0) * (1 if randi() % 2 == 0 else -1))
	new_seed.set_meta("time_alive", 0.0)
	
func _move_seeds(delta: float) -> void:
	for s in get_tree().get_nodes_in_group("falling_seeds"):
		if not is_instance_valid(s): continue
		
		var speed = s.get_meta("fall_speed")
		var spin = s.get_meta("spin_speed")
		var t = s.get_meta("time_alive") + delta
		s.set_meta("time_alive", t)
		
		s.position.y += speed * delta
		s.position.x += sin(t * 3.0) * 1.5 # 바람에 살랑이는 효과
		s.rotation += spin * delta
		
		# 3D 회전 착시 (scale.x 반전)
		s.scale.x = sin(t * 5.0)
		
		if s.position.y > 600:
			s.queue_free()

func _on_basket_area_entered(area: Area2D) -> void:
	if not game_active: return
	
	if area.is_in_group("falling_seeds"):
		score += 1
		area.queue_free()
		_update_ui()
		
		if score >= target_score:
			_game_over(true)

func _update_ui() -> void:
	score_label.text = "씨앗 수집: " + str(score) + " / " + str(target_score)
	time_label.text = "남은 시간: " + str(ceil(time_left)) + "초"

func _game_over(is_win: bool) -> void:
	game_active = false
	if is_win:
		_show_popup("성공!", "단풍나무 씨앗을 모두 모았습니다!", true)
	else:
		_show_popup("시간 초과", "단풍나무 씨앗을 충분히 모으지 못했습니다.", false)

func _show_popup(title: String, desc: String, is_win: bool) -> void:
	popup_layer.show()
	var title_label = popup_layer.get_node("Panel/Title")
	var desc_label = popup_layer.get_node("Panel/Desc")
	var btn = popup_layer.get_node("Panel/RetryBtn")
	
	title_label.text = title
	desc_label.text = desc
	
	if is_win:
		btn.text = "마을로 돌아가기"
		GameManager.maple_quest_state = 2
		btn.pressed.disconnect(_on_btn_pressed)
		btn.pressed.connect(_on_win_btn_pressed)
	else:
		btn.text = "다시 하기"
		btn.pressed.disconnect(_on_btn_pressed)
		btn.pressed.connect(_on_retry_btn_pressed)

func _on_btn_pressed() -> void: pass # dummy

func _on_retry_btn_pressed() -> void:
	for s in get_tree().get_nodes_in_group("falling_seeds"):
		s.queue_free()
	_start_game()

func _on_win_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Forest.tscn")
