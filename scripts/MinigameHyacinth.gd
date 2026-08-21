extends Node2D

const FONT_PATH := "res://fonts/Cafe24Ssurround-v2.0.ttf"
@onready var popup_layer = $PopupLayer

var score := 0
var max_score := 5
var game_active := false

var hyacinths: Array[RigidBody2D] = []

func _ready() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_minigame_bgm()
	if has_node("/root/MobileUI"):
		var m_ui = get_node("/root/MobileUI")
		m_ui.show()
		m_ui.process_mode = Node.PROCESS_MODE_INHERIT
		
	for child in get_tree().get_nodes_in_group("hyacinth"):
		if child is RigidBody2D:
			hyacinths.append(child)
			
	for child in get_tree().get_nodes_in_group("net"):
		if child is Area2D:
			child.body_entered.connect(_on_net_body_entered.bind(child))
			
	_show_instruction_popup()

func _show_instruction_popup() -> void:
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
	
	var font = load(FONT_PATH)
	
	var title = Label.new()
	title.text = "둥실둥실 부레옥잠 채집"
	title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 40
	panel.add_child(title)
	
	var desc = Label.new()
	desc.text = "스마트폰을 상하좌우로 기울이거나 키보드 방향키를 눌러\n부레옥잠 5개를 채집망으로 옮기세요!\n\n장애물(돌멩이, 연잎)을 피해서 안전하게 안착시켜야 합니다."
	desc.add_theme_font_override("font", font)
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
	start_btn.add_theme_font_override("font", font)
	start_btn.add_theme_font_size_override("font_size", 32)
	start_btn.custom_minimum_size = Vector2(240, 70)
	start_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	start_btn.offset_left = 280
	start_btn.offset_top = -110
	start_btn.offset_right = -280
	start_btn.offset_bottom = -40
	panel.add_child(start_btn)
	
	start_btn.pressed.connect(func():
		if OS.has_feature("web"):
			var js_code = """
				window.tiltX = 0;
				window.tiltY = 0;
				window.addEventListener('deviceorientation', function(e) {
					window.tiltX = e.gamma;
					window.tiltY = e.beta;
				});
				if (typeof DeviceOrientationEvent !== 'undefined' && typeof DeviceOrientationEvent.requestPermission === 'function') {
					DeviceOrientationEvent.requestPermission().catch(console.error);
				}
				if (typeof DeviceMotionEvent !== 'undefined' && typeof DeviceMotionEvent.requestPermission === 'function') {
					DeviceMotionEvent.requestPermission().catch(console.error);
				}
			"""
			JavaScriptBridge.eval(js_code)
			
		inst_layer.queue_free()
		game_active = true
	)

func _physics_process(delta: float) -> void:
	if not game_active: return
	
	var tilt_dir = Vector2.ZERO
	
	if OS.has_feature("web"):
		var js_x = JavaScriptBridge.eval("window.tiltX")
		var js_y = JavaScriptBridge.eval("window.tiltY")
		if js_x != null and js_y != null:
			# gamma (js_x) is left/right tilt. beta (js_y) is front/back tilt.
			var tx = clamp(float(js_x) / 30.0, -1.0, 1.0) * 10.0
			var ty = clamp(float(js_y) / 30.0, -1.0, 1.0) * 10.0
			tilt_dir = Vector2(tx, ty)
	else:
		# 스마트폰 기울기 센서 (가속도계) 입력 (안드로이드 등 네이티브 앱)
		var accel = Input.get_accelerometer()
		tilt_dir = Vector2(accel.x, -accel.y)
	
	# PC 테스트용 화살표 키 폴백
	if tilt_dir.length() < 0.1:
		if Input.is_action_pressed("ui_right"): tilt_dir.x += 5.0
		if Input.is_action_pressed("ui_left"): tilt_dir.x -= 5.0
		if Input.is_action_pressed("ui_up"): tilt_dir.y -= 5.0
		if Input.is_action_pressed("ui_down"): tilt_dir.y += 5.0
		
	var force = tilt_dir * 120.0
	for h in hyacinths:
		if h.has_meta("in_net") and h.get_meta("in_net"):
			continue
		h.apply_central_force(force)

func _on_net_body_entered(body: Node2D, net: Area2D) -> void:
	if not game_active: return
	if body.is_in_group("hyacinth"):
		if body.has_meta("in_net") and body.get_meta("in_net"):
			return
		if net.has_meta("is_full") and net.get_meta("is_full"):
			return
			
		body.set_meta("in_net", true)
		net.set_meta("is_full", true)
		
		# 물리 비활성화 및 안착
		body.set_deferred("freeze", true)
		var tween = create_tween()
		tween.tween_property(body, "global_position", net.global_position, 0.2)
		
		# 채집망 이미지 변경
		var net_sprite = net.get_node_or_null("Sprite2D")
		if net_sprite:
			net_sprite.texture = load("res://assets/game/water/net2.png")
			
		score += 1
		if score >= max_score:
			_game_over()

func _game_over() -> void:
	game_active = false
	await get_tree().create_timer(1.0).timeout
	
	popup_layer.show()
	var title_label = popup_layer.get_node("Panel/Title")
	var desc_label = popup_layer.get_node("Panel/Desc")
	var btn = popup_layer.get_node("Panel/ReturnBtn")
	
	title_label.text = "성공!"
	desc_label.text = "부레옥잠을 모두 채집망에 안전하게 넣었습니다!\n연못으로 돌아가 개구리에게 완료를 보고하세요."
	
	GameManager.hyacinth_quest_state = 2
	btn.pressed.connect(_on_return_btn_pressed)

func _on_return_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Pond.tscn")

func _exit_tree() -> void:
	if has_node("/root/MobileUI"):
		var m_ui = get_node("/root/MobileUI")
		m_ui.show()
		m_ui.process_mode = Node.PROCESS_MODE_INHERIT
