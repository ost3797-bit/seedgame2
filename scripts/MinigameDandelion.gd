extends Node2D

@onready var player = $Player
@onready var anim_player = $Player/AnimationPlayer
@onready var sprite = $Player/Sprite2D
@onready var bg1 = $ParallaxBackground/Layer1
@onready var bg2 = $ParallaxBackground/Layer2
@onready var bg3 = $ParallaxBackground/Layer3
@onready var rules_popup = $UI/RulesPopup
@onready var rules_text = $UI/RulesPopup/RulesText
@onready var start_btn = $UI/RulesPopup/StartButton
@onready var score_label = $UI/ScoreLabel
@onready var obstacle_container = $ObstacleContainer

var is_showing_rules = true
var is_game_active = false
var flap_force = -400.0
var base_gravity = 1.6

var scroll_speed = 300.0
var score = 0
var max_score = 10
var current_round = 1

var spawn_timer = 0.0
var spawn_interval = 1.5

var tex_up = [
	preload("res://assets/game/min/obstacle_up1.png"),
	preload("res://assets/game/min/obstacle_up2.png")
]
var tex_down = [
	preload("res://assets/game/min/obstacle_down1.png"),
	preload("res://assets/game/min/obstacle_down2.png"),
	preload("res://assets/game/min/obstacle_down3.png"),
	preload("res://assets/game/min/obstacle_down4.png")
]

func _ready():
	if has_node("/root/AudioManager"):
		AudioManager.play_minigame_bgm()
	if has_node("/root/MobileUI"):
		get_node("/root/MobileUI").hide()
		
	is_showing_rules = true
	is_game_active = false
	current_round = 1
	rules_popup.show()
	score_label.hide()
	
	player.gravity_scale = 0.0
	player.linear_velocity = Vector2.ZERO
	
	start_btn.pressed.connect(_on_start_btn_pressed)
	
	$DeathZones/TopBound.body_entered.connect(_on_obstacle_hit)
	$DeathZones/BottomBound.body_entered.connect(_on_obstacle_hit)

func _on_start_btn_pressed():
	if is_showing_rules:
		_start_game()

func _start_game():
	is_showing_rules = false
	rules_popup.hide()
	is_game_active = true
	score = 0
	_update_score()
	score_label.show()
	
	player.position = Vector2(300, 324)
	player.gravity_scale = base_gravity
	player.linear_velocity = Vector2.ZERO
	
	for child in obstacle_container.get_children():
		child.queue_free()
		
	spawn_timer = 1.0 # 첫 장애물은 조금 일찍

func _process(delta):
	if not is_game_active:
		return
		
	bg1.motion_offset.x -= scroll_speed * 0.2 * delta
	bg2.motion_offset.x -= scroll_speed * 0.5 * delta
	bg3.motion_offset.x -= scroll_speed * 1.0 * delta
	
	for child in obstacle_container.get_children():
		child.position.x -= scroll_speed * delta
		if child.position.x < -200:
			child.queue_free()
			
	spawn_timer -= delta
	if spawn_timer <= 0:
		_spawn_obstacle()
		spawn_timer = spawn_interval

func _spawn_obstacle():
	if score >= max_score: return 
	
	var gap_size = 250.0
	if current_round == 2:
		gap_size = 200.0
		
	var min_y = 100.0
	var max_y = 648.0 - 100.0 - gap_size
	
	var gap_y = randf_range(min_y, max_y)
	
	var obs_node = Area2D.new()
	obs_node.position = Vector2(1250, 0)
	
	var chosen_up = tex_up[randi() % tex_up.size()]
	var top_sprite = Sprite2D.new()
	top_sprite.texture = chosen_up
	top_sprite.centered = false
	top_sprite.scale = Vector2(80.0 / chosen_up.get_width(), gap_y / chosen_up.get_height())
	top_sprite.position = Vector2(-40, 0)
	obs_node.add_child(top_sprite)
	
	var top_shape = CollisionShape2D.new()
	var top_rect_shape = RectangleShape2D.new()
	top_rect_shape.size = Vector2(80, gap_y)
	top_shape.shape = top_rect_shape
	top_shape.position = Vector2(0, gap_y / 2.0)
	obs_node.add_child(top_shape)
	
	var bottom_height = 648.0 - (gap_y + gap_size)
	var chosen_down = tex_down[randi() % tex_down.size()]
	var bottom_sprite = Sprite2D.new()
	bottom_sprite.texture = chosen_down
	bottom_sprite.centered = false
	bottom_sprite.scale = Vector2(80.0 / chosen_down.get_width(), bottom_height / chosen_down.get_height())
	bottom_sprite.position = Vector2(-40, gap_y + gap_size)
	obs_node.add_child(bottom_sprite)
	
	var bottom_shape = CollisionShape2D.new()
	var bottom_rect_shape = RectangleShape2D.new()
	bottom_rect_shape.size = Vector2(80, bottom_height)
	bottom_shape.shape = bottom_rect_shape
	bottom_shape.position = Vector2(0, gap_y + gap_size + bottom_height / 2.0)
	obs_node.add_child(bottom_shape)
	
	var score_area = Area2D.new()
	var score_shape = CollisionShape2D.new()
	var score_rect = RectangleShape2D.new()
	score_rect.size = Vector2(20, 648)
	score_shape.shape = score_rect
	score_shape.position = Vector2(40, 324)
	score_area.add_child(score_shape)
	
	score_area.body_exited.connect(func(body):
		if body == player and is_game_active:
			_add_score()
	)
	
	obs_node.add_child(score_area)
	obs_node.body_entered.connect(_on_obstacle_hit)
	
	obstacle_container.add_child(obs_node)

func _add_score():
	score += 1
	_update_score()
	if score >= max_score:
		_on_success()

func _update_score():
	score_label.text = "Round %d - %d / %d" % [current_round, score, max_score]

func _unhandled_input(event):
	if rules_popup.visible: return
	
	if not is_game_active: return
	
	if event.is_action_pressed("ui_accept") or (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		player.linear_velocity.y = flap_force
		get_viewport().set_input_as_handled()

func _on_obstacle_hit(body):
	if body == player and is_game_active:
		_on_fail()

func _on_fail():
	is_game_active = false
	player.gravity_scale = 0
	player.linear_velocity = Vector2.ZERO
	
	rules_text.text = "앗, 부딪혔어요!\n\n%d라운드부터 다시 도전해볼까요?" % current_round
	start_btn.text = "재도전"
	rules_popup.show()
	
	is_showing_rules = true

func _on_success():
	is_game_active = false
	player.gravity_scale = 0
	player.linear_velocity = Vector2.ZERO
	
	if current_round == 1:
		current_round = 2
		rules_text.text = "1라운드 통과!\n\n장애물 사이가 더 좁아집니다.\n2라운드를 시작할까요?"
		start_btn.text = "2라운드 시작"
		rules_popup.show()
		is_showing_rules = true
	else:
		if GameManager.dandelion_quest_state == 1:
			GameManager.dandelion_quest_state = 2
			
		rules_text.text = "축하합니다!\n\n민들레 씨앗 비행 미션을\n성공적으로 마쳤습니다!\n\n이제 고양이에게 돌아가세요!"
		start_btn.text = "돌아가기"
		rules_popup.show()
		
		if start_btn.pressed.is_connected(_on_start_btn_pressed):
			start_btn.pressed.disconnect(_on_start_btn_pressed)
		
		start_btn.pressed.connect(func():
			get_tree().change_scene_to_file("res://scenes/FlowerGarden.tscn")
		)
