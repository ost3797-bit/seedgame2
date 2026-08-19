extends Node2D

@onready var launcher_base = $LauncherBase
@onready var stay_sprite = $LauncherBase/StaySprite
@onready var trajectory_line = $LauncherBase/TrajectoryLine
@onready var drag_area = $LauncherBase/DragArea/CollisionShape2D
@onready var basket = $Basket
@onready var instruction_label = $UI/InstructionLabel
@onready var rules_popup = $UI/RulesPopup
@onready var start_btn = $UI/RulesPopup/StartButton

var seed_scene = preload("res://scenes/SeedProjectile.tscn")

var is_showing_rules = true
var is_game_active = false
var is_dragging = false
var drag_start_pos = Vector2.ZERO
var drag_current_pos = Vector2.ZERO
var max_drag_dist = 250.0
var power_multiplier = 7.0 # 조준선 길이에 곱해질 발사 힘
var basket_start_pos = Vector2(1500, 800)

var current_round = 1
var max_round = 2
var seeds_in_current_round = 0
var seed_instance = null
var throb_tween: Tween

func _ready():
	if has_node("/root/MobileUI"):
		get_node("/root/MobileUI").hide()
		
	is_showing_rules = true
	is_game_active = false
	rules_popup.show()
	stay_sprite.frame = 0
	trajectory_line.hide()
	instruction_label.text = ""
	
	basket_start_pos = basket.position
	
	start_btn.pressed.connect(_on_start_btn_pressed)
	$Basket/GoalZone.body_entered.connect(_on_basket_body_entered)

func _on_start_btn_pressed():
	if is_showing_rules:
		is_showing_rules = false
		_start_round()

func _start_round():
	is_game_active = true
	rules_popup.hide()
	stay_sprite.show()
	stay_sprite.frame = 0
	stay_sprite.rotation = 0
	trajectory_line.hide()
	
	instruction_label.text = "라운드 %d/%d! 바구니에 골인시키세요!" % [current_round, max_round]
	
	seeds_in_current_round = 0
	_start_throb()
	
	if seed_instance and is_instance_valid(seed_instance):
		seed_instance.queue_free()
		seed_instance = null
		
	# 2라운드면 바구니 상하 이동 추가
	if current_round == 2:
		var tween = create_tween().set_loops()
		tween.tween_property(basket, "position:y", basket_start_pos.y - 150, 1.5).set_trans(Tween.TRANS_SINE)
		tween.tween_property(basket, "position:y", basket_start_pos.y + 150, 1.5).set_trans(Tween.TRANS_SINE)
	else:
		basket.position = basket_start_pos

func _unhandled_input(event):
	if not is_game_active: return
	if seed_instance and is_instance_valid(seed_instance): return # 이미 발사된 씨앗이 있으면 조작 불가

	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed:
			var global_click_pos = get_global_mouse_position()
			
			var dist = global_click_pos.distance_to(launcher_base.global_position)
			if dist < 200: # 드래그 감지 반경
				is_dragging = true
				_stop_throb()
				drag_start_pos = launcher_base.global_position
				trajectory_line.show()
		else:
			if is_dragging:
				_shoot()
				is_dragging = false
				trajectory_line.hide()
				
	elif (event is InputEventMouseMotion or event is InputEventScreenDrag) and is_dragging:
		var global_pos = get_global_mouse_position()
		drag_current_pos = global_pos
		_update_aim()

func _update_aim():
	var drag_vec = drag_current_pos - drag_start_pos
	if drag_vec.length() > max_drag_dist:
		drag_vec = drag_vec.normalized() * max_drag_dist
		
	# 당기는 거리에 따라 stay.png 프레임 조절 (0~5)
	var pull_ratio = drag_vec.length() / max_drag_dist
	var frame_idx = int(pull_ratio * 5.99)
	stay_sprite.frame = frame_idx
	
	# 조준 각도로 회전
	var aim_angle = drag_vec.angle()
	stay_sprite.rotation = aim_angle
	
	_draw_trajectory(-drag_vec * power_multiplier)

func _draw_trajectory(impulse: Vector2):
	trajectory_line.clear_points()
	var pos = Vector2.ZERO # 로컬 기준점
	var vel = impulse
	var grav = 980.0 * 1.2 # RigidBody2D의 기본 중력(980) * gravity_scale(1.2)
	var step = 0.05
	
	for i in range(12): # 점선 궤적 절반 길이로 수정
		trajectory_line.add_point(pos)
		pos += vel * step
		vel.y += grav * step
		if pos.y > 1000: break # 화면 아래로 벗어나면 중단

func _shoot():
	var drag_vec = drag_current_pos - drag_start_pos
	if drag_vec.length() < 20.0:
		stay_sprite.frame = 0
		stay_sprite.rotation = 0
		return # 너무 조금 당기면 취소
		
	if drag_vec.length() > max_drag_dist:
		drag_vec = drag_vec.normalized() * max_drag_dist
		
	var impulse = -drag_vec * power_multiplier
	
	stay_sprite.hide()
	
	seed_instance = seed_scene.instantiate()
	seed_instance.global_position = launcher_base.global_position
	add_child(seed_instance)
	seed_instance.apply_impulse(impulse)
	
func _process(_delta):
	# 씨앗이 화면 밖으로 벗어났는지 체크 (실패)
	if seed_instance and is_instance_valid(seed_instance):
		if seed_instance.global_position.y > 1200 or seed_instance.global_position.x > 2200 or seed_instance.global_position.x < -200:
			_on_miss()

func _on_miss():
	if not is_game_active: return
	
	if seed_instance and is_instance_valid(seed_instance):
		seed_instance.queue_free()
		seed_instance = null
		
	instruction_label.text = "앗, 빗나갔어요! 다시 당겨보세요!"
	instruction_label.add_theme_color_override("font_color", Color(0.8, 0, 0))
	
	_reset_launcher()

func _on_basket_body_entered(body):
	if body.is_in_group("seed") and is_game_active:
		_on_success()

func _on_success():
	if not is_game_active: return
	
	if seed_instance and is_instance_valid(seed_instance):
		seed_instance.queue_free()
		seed_instance = null
		
	seeds_in_current_round += 1
	
	if seeds_in_current_round < 2:
		instruction_label.text = "%d라운드 %d번째 성공! 하나 더 넣으세요!" % [current_round, seeds_in_current_round]
		instruction_label.add_theme_color_override("font_color", Color(0, 0.6, 0))
		_reset_launcher()
	else:
		is_game_active = false
		if current_round >= max_round:
			_show_final_success()
		else:
			current_round += 1
			instruction_label.text = "라운드 성공! 다음 라운드 준비!"
			instruction_label.add_theme_color_override("font_color", Color(0, 0.6, 0))
			await get_tree().create_timer(1.5).timeout
			_start_round()

func _start_throb():
	if throb_tween and throb_tween.is_valid():
		throb_tween.kill()
	stay_sprite.scale = Vector2(0.5, 0.5)
	throb_tween = create_tween().set_loops()
	throb_tween.tween_property(stay_sprite, "scale", Vector2(0.6, 0.6), 0.5).set_trans(Tween.TRANS_SINE)
	throb_tween.tween_property(stay_sprite, "scale", Vector2(0.5, 0.5), 0.5).set_trans(Tween.TRANS_SINE)

func _stop_throb():
	if throb_tween and throb_tween.is_valid():
		throb_tween.kill()
	stay_sprite.scale = Vector2(0.5, 0.5)

func _reset_launcher():
	stay_sprite.show()
	stay_sprite.frame = 0
	stay_sprite.rotation = 0
	_start_throb()

func _show_final_success():
	if GameManager.balsam_quest_state == 1:
		GameManager.balsam_quest_state = 2
	
	instruction_label.text = ""
	rules_popup.show()
	$UI/RulesPopup/RulesText.text = "축하합니다!\n\n봉선화 씨앗 쏘기 미션을\n성공적으로 마쳤습니다!\n\n이제 고양이에게 돌아가세요!"
	start_btn.text = "돌아가기"
	
	if start_btn.pressed.is_connected(_on_start_btn_pressed):
		start_btn.pressed.disconnect(_on_start_btn_pressed)
	
	start_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/FlowerGarden.tscn")
	)
