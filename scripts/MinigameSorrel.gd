extends Control

@onready var indicator = $Indicator
@onready var gauge_bg = $GaugeBg
@onready var target_zone = $GaugeBg/TargetZone
@onready var plant_image = $PlantImage
@onready var instruction_label = $InstructionLabel
@onready var rules_popup = $RulesPopup
@onready var rules_text = $RulesPopup/RulesText
@onready var start_btn = $RulesPopup/StartButton
@onready var round_success_image = $RoundSuccessImage

var tex_normal: AtlasTexture
var tex_swollen: AtlasTexture
var tex_bursting: AtlasTexture
var tex_exploded: AtlasTexture

@export var indicator_speed = 600.0

var direction = 1
var is_game_active = false
var is_showing_rules = true

var current_round = 1
var max_round = 5

func _ready():
	# 모바일 UI(조이스틱) 숨기기
	if has_node("/root/MobileUI"):
		get_node("/root/MobileUI").hide()
	
	round_success_image.hide()
	
	# 아틀라스 텍스처(잘라낸 이미지) 생성
	var base_tex = load("res://assets/game/bab/bob_asset.png")
	
	tex_normal = AtlasTexture.new()
	tex_normal.atlas = base_tex
	tex_normal.region = Rect2(0, 0, 202, 341)
	
	tex_swollen = AtlasTexture.new()
	tex_swollen.atlas = base_tex
	tex_swollen.region = Rect2(202, 0, 202, 341)
	
	tex_bursting = AtlasTexture.new()
	tex_bursting.atlas = base_tex
	tex_bursting.region = Rect2(0, 341, 404, 341)
	
	tex_exploded = AtlasTexture.new()
	tex_exploded.atlas = base_tex
	tex_exploded.region = Rect2(0, 682, 404, 342)
	
	is_showing_rules = true
	is_game_active = false
	indicator.hide()
	rules_popup.show()
	plant_image.texture = tex_normal
	instruction_label.text = ""
	start_btn.pressed.connect(_on_start_btn_pressed)

func _on_start_btn_pressed():
	if is_showing_rules:
		is_showing_rules = false
		indicator.show()
		_start_round()

func _start_round():
	is_game_active = true
	rules_popup.hide()
	plant_image.texture = tex_normal
	instruction_label.text = "라운드 %d/%d! 타이밍에 맞춰 SPACE 바를 누르세요!" % [current_round, max_round]
	instruction_label.add_theme_color_override("font_color", Color.BLACK)

func _process(delta):
	if not is_game_active:
		return
		
	# 게이지 크기가 0이면 UI 레이아웃이 아직 계산되지 않은 것이므로 대기
	if gauge_bg.size.x == 0:
		return
		
	# 인디케이터 이동
	indicator.position.x += direction * indicator_speed * delta
	
	# 게이지 양끝 도달 시 방향 전환 (스케일 고려)
	var gauge_real_width = gauge_bg.size.x * gauge_bg.scale.x
	var min_x = gauge_bg.position.x
	var max_x = gauge_bg.position.x + gauge_real_width - (indicator.size.x * indicator.scale.x)
	
	if indicator.position.x > max_x:
		indicator.position.x = max_x
		direction = -1
	elif indicator.position.x < min_x:
		indicator.position.x = min_x
		direction = 1
		
	# 인디케이터 거리에 따른 식물 이미지 변경
	var target_rect = target_zone.get_global_rect()
	var center_x = indicator.global_position.x + (indicator.size.x * indicator.scale.x) / 2.0
	
	if center_x >= target_rect.position.x and center_x <= target_rect.end.x:
		plant_image.texture = tex_swollen
	else:
		plant_image.texture = tex_normal

func _input(event):
	if event.is_action_pressed("ui_accept") or (event is InputEventScreenTouch and event.pressed):
		if is_game_active:
			_check_timing()

func _check_timing():
	var target_rect = target_zone.get_global_rect()
	var center_x = indicator.global_position.x + (indicator.size.x * indicator.scale.x) / 2.0
	
	if center_x >= target_rect.position.x and center_x <= target_rect.end.x:
		_on_success()
	else:
		_on_fail()

func _on_success():
	is_game_active = false
	plant_image.texture = tex_exploded
	
	if current_round < max_round:
		instruction_label.text = "라운드 %d 성공! 다음 라운드 준비!" % current_round
		instruction_label.add_theme_color_override("font_color", Color(0, 0.6, 0))
		round_success_image.show()
		
		# 1.5초 대기 후 다음 라운드
		await get_tree().create_timer(1.5).timeout
		
		round_success_image.hide()
		current_round += 1
		indicator_speed += 200.0 # 라운드마다 속도 대폭 증가
		_start_round()
	else:
		# 최종 5라운드 성공
		is_game_active = false
		if GameManager.sorrel_quest_state == 1:
			GameManager.sorrel_quest_state = 2
			
		instruction_label.text = ""
		rules_popup.show()
		rules_text.text = "축하합니다!\n\n괭이밥 꼬투리 터뜨리기 미션을\n성공적으로 마쳤습니다!\n\n이제 고양이에게 돌아가세요!"
		start_btn.text = "돌아가기"
		
		if start_btn.pressed.is_connected(_on_start_btn_pressed):
			start_btn.pressed.disconnect(_on_start_btn_pressed)
		
		start_btn.pressed.connect(func():
			get_tree().change_scene_to_file("res://scenes/FlowerGarden.tscn")
		)

func _on_fail():
	instruction_label.text = "앗, 빗나갔어요! 다시 도전!"
	instruction_label.add_theme_color_override("font_color", Color(0.8, 0, 0))
	
	var tween = create_tween()
	tween.tween_property(instruction_label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(instruction_label, "scale", Vector2(1.0, 1.0), 0.2)
