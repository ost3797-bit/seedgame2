extends CanvasLayer

var joypad_scene = preload("res://addons/virtual_joystick/virtual_joystick_scene.tscn")

func _ready() -> void:
	layer = 90 # SeedUI(100)보다 아래, 일반 씬보다는 위에
	
	# 데스크탑 등 터치 미지원 환경에서 안 보이게 하려면 주석 해제 (지금은 강제로 보이게 함)
	# if not DisplayServer.is_touchscreen_available():
	# 	return
		
	# 가상 조이스틱 (이동)
	var joystick = joypad_scene.instantiate()
	# 좌측 하단 고정
	joystick.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	joystick.position = Vector2(50, 420)
	add_child(joystick)
	
	# 대화/상호작용 버튼 (Space / ui_accept)
	var action_btn = TouchScreenButton.new()
	action_btn.action = "ui_accept"
	
	# 동그란 버튼 모양 텍스처 생성
	var normal_tex = GradientTexture2D.new()
	normal_tex.width = 120
	normal_tex.height = 120
	normal_tex.fill = GradientTexture2D.FILL_RADIAL
	normal_tex.fill_from = Vector2(0.5, 0.5)
	normal_tex.fill_to = Vector2(0.5, 0.0)
	var grad = Gradient.new()
	grad.add_point(0.0, Color(1, 1, 1, 0.6))
	grad.add_point(1.0, Color(1, 1, 1, 0.0))
	normal_tex.gradient = grad
	action_btn.texture_normal = normal_tex
	
	action_btn.position = Vector2(1080, 520) # 우측 하단 쯤
	
	# 버튼 위에 라벨(아이콘) 추가
	var label = Label.new()
	label.text = "ACTION\n(SPACE)"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color.BLACK)
	label.add_theme_color_override("font_outline_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 4)
	action_btn.add_child(label)
	
	add_child(action_btn)
