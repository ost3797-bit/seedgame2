extends CanvasLayer

var label: Label

func _ready() -> void:
	layer = 100

	# 폰트 로드
	var font = load("res://fonts/Cafe24Ssurround-v2.0.ttf") as FontFile

	# 좌측 상단 Panel 배경 (반투명 검은 박스)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.offset_left = 20
	panel.offset_top = 20

	# 박스 스타일
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.55)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# 상단 타이틀 "씨앗 수집 현황"
	var title_lbl := Label.new()
	title_lbl.text = "🌱 씨앗 수집 현황"
	if font:
		title_lbl.add_theme_font_override("font", font)
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(0.9, 1.0, 0.7))
	title_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	title_lbl.add_theme_constant_override("outline_size", 3)
	vbox.add_child(title_lbl)

	# 구분선
	var sep := HSeparator.new()
	sep.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(sep)

	# 카운터 숫자
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(hbox)

	var icon := TextureRect.new()
	var tex = load("res://assets/game/min/seed7.png")
	if tex:
		icon.texture = tex
		icon.custom_minimum_size = Vector2(40, 40)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(icon)

	label = Label.new()
	if font:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	hbox.add_child(label)

	_update_text()

func _process(_delta: float) -> void:
	_update_text()

func _update_text() -> void:
	if GameManager:
		label.text = "%d / %d" % [GameManager.collected_seeds, GameManager.total_seeds]
