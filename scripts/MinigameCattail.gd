extends Node2D

var score := 0
var max_score := 5
var game_active := false
var game_over := false

@onready var popup_layer: CanvasLayer = $PopupLayer
@onready var title_label: Label = $PopupLayer/Panel/Title
@onready var desc_label: Label = $PopupLayer/Panel/Desc

@onready var info_label: Label = $UILayer/Control/InfoLabel
@onready var intro_sprite: Sprite2D = $IntroSprite

var drag_start: Vector2
var is_dragging: bool = false
const WIND_RADIUS: float = 150.0
const FORCE_MULTIPLIER: float = 1.5

@onready var wind_line: Line2D = $WindManager/Line2D
@onready var fan_sprite: Sprite2D = $WindManager/FanSprite

var time_left: float = 30.0

var seed_scene = preload("res://scenes/CattailSeed.tscn")
var spawn_timer: Timer

func _ready() -> void:
	if has_node("/root/MobileUI"):
		get_node("/root/MobileUI").hide()
		
	popup_layer.hide()
	wind_line.hide()
	fan_sprite.hide()
	fan_sprite.scale = Vector2(0.5, 0.5)
	
	_update_info_label()
	
	for child in get_tree().get_nodes_in_group("water_area"):
		if child is Area2D:
			child.body_entered.connect(_on_water_body_entered)
			
	var basket = get_node("BasketTarget")
	if basket and basket is Area2D:
		basket.body_entered.connect(_on_basket_body_entered)
	
	_show_instruction_popup()

func _show_instruction_popup() -> void:
	var font_path = "res://fonts/Cafe24Ssurround-v2.0.ttf"
	var inst_layer = CanvasLayer.new()
	inst_layer.layer = 150
	add_child(inst_layer)
	
	var panel = Panel.new()
	inst_layer.add_child(panel)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -400
	panel.offset_top = -225
	panel.offset_right = 400
	panel.offset_bottom = 225
	
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(bg)
	
	var font = load(font_path)
	
	var title = Label.new()
	title.text = "살랑살랑 부들 바람몰이"
	if font: title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 40
	panel.add_child(title)
	
	var desc = Label.new()
	desc.text = "화면을 드래그하여 부채질을 하세요!\n바람을 일으켜 날아가는 솜털 씨앗의 방향을 조절하고\n씨앗 보관함으로 5개의 씨앗을 골인시키세요!"
	if font: desc.add_theme_font_override("font", font)
	desc.add_theme_font_size_override("font_size", 26)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	desc.offset_top = 130
	desc.offset_bottom = 300
	desc.offset_left = 20
	desc.offset_right = -20
	panel.add_child(desc)
	
	var start_btn = Button.new()
	start_btn.text = "게임 시작"
	if font: start_btn.add_theme_font_override("font", font)
	start_btn.add_theme_font_size_override("font_size", 32)
	start_btn.custom_minimum_size = Vector2(240, 70)
	start_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	start_btn.offset_left = 280
	start_btn.offset_top = -110
	start_btn.offset_right = -280
	start_btn.offset_bottom = -40
	panel.add_child(start_btn)
	
	start_btn.pressed.connect(func():
		inst_layer.queue_free()
		_play_intro_animation()
	)

func _play_intro_animation() -> void:
	# 부들 터지는 애니메이션 1~5
	var textures = [
		load("res://assets/game/flag/flag1.png"),
		load("res://assets/game/flag/flag2.png"),
		load("res://assets/game/flag/flag3.png"),
		load("res://assets/game/flag/flag4.png"),
		load("res://assets/game/flag/flag5.png")
	]
	
	for tex in textures:
		intro_sprite.texture = tex
		await get_tree().create_timer(0.4).timeout
		
	var tw = create_tween()
	tw.tween_property(intro_sprite, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func(): 
		intro_sprite.hide()
		_start_game()
	)

func _start_game() -> void:
	game_active = true
	
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 4.0
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(_spawn_seed)
	add_child(spawn_timer)
	
	# 처음 1개 바로 스폰
	_spawn_seed()

func _spawn_seed() -> void:
	if not game_active: return
	
	var vp_rect = get_viewport_rect()
	var seed_inst = seed_scene.instantiate()
	var rx = randf_range(150, vp_rect.size.x - 150)
	seed_inst.position = Vector2(rx, -50)
	add_child(seed_inst)

func _process(delta: float) -> void:
	if not game_active or game_over: return
	
	time_left -= delta
	_update_info_label()
	
	if time_left <= 0:
		_game_over(false)

func _unhandled_input(event: InputEvent) -> void:
	if not game_active or game_over: return
	
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed:
			is_dragging = true
			drag_start = event.position
			
			fan_sprite.position = drag_start
			fan_sprite.show()
			wind_line.clear_points()
			wind_line.add_point(drag_start)
			wind_line.add_point(drag_start)
			wind_line.show()
		else:
			if is_dragging:
				is_dragging = false
				var drag_end = event.position
				wind_line.hide()
				fan_sprite.hide()
				
				# 바람 이펙트 표시 없이 바로 힘만 적용
				if drag_start.distance_to(drag_end) > 20:
					apply_wind_force(drag_start, drag_end)

	elif (event is InputEventMouseMotion or event is InputEventScreenDrag) and is_dragging:
		wind_line.set_point_position(1, event.position)

func apply_wind_force(start: Vector2, end: Vector2) -> void:
	var wind_vector = end - start
	if wind_vector.length() < 20: return
	
	if wind_vector.length() > 300:
		wind_vector = wind_vector.normalized() * 300
	
	var wind_force = wind_vector * FORCE_MULTIPLIER
	
	for s in get_tree().get_nodes_in_group("cattail_seeds"):
		var closest_point = Geometry2D.get_closest_point_to_segment(s.global_position, start, end)
		if s.global_position.distance_to(closest_point) <= WIND_RADIUS:
			if s.has_method("apply_wind"):
				s.apply_wind(wind_force)

func _on_basket_body_entered(body: Node2D) -> void:
	if body.is_in_group("cattail_seeds") and body.has_method("set_captured"):
		if body.is_captured: return
		body.set_captured()
		score += 1
		_update_info_label()
		
		if score >= max_score:
			_game_over(true)

func _on_water_body_entered(body: Node2D) -> void:
	if body.is_in_group("cattail_seeds") and body.has_method("set_wet"):
		if body.is_wet: return
		body.set_wet()

func _game_over(is_success: bool) -> void:
	game_active = false
	game_over = true
	if spawn_timer: spawn_timer.stop()
	
	if has_node("/root/MobileUI"):
		get_node("/root/MobileUI").show()
		
	popup_layer.show()
	var btn = popup_layer.get_node("Panel/ReturnBtn")
	
	if is_success:
		title_label.text = "성공!"
		desc_label.text = "부들 씨앗을 모두 모았습니다!\n연못으로 돌아가 개구리에게 보고하세요."
		GameManager.cattail_quest_state = 2
	else:
		title_label.text = "시간 초과!"
		desc_label.text = "다시 도전해보세요!"
		
	# disconnect old connections to prevent double triggering
	if btn.pressed.is_connected(_on_return_btn_pressed):
		btn.pressed.disconnect(_on_return_btn_pressed)
	if btn.pressed.is_connected(_on_retry_btn_pressed):
		btn.pressed.disconnect(_on_retry_btn_pressed)
		
	if is_success:
		btn.pressed.connect(_on_return_btn_pressed)
	else:
		btn.pressed.connect(_on_retry_btn_pressed)

func _on_return_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Pond.tscn")

func _on_retry_btn_pressed() -> void:
	get_tree().reload_current_scene()

func _update_info_label() -> void:
	if info_label:
		info_label.text = "제한시간: %d 초\n목표: %d / %d" % [int(time_left), score, max_score]
