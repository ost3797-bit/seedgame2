extends Node2D

const FONT_PATH := "res://fonts/Cafe24Ssurround-v2.0.ttf"

@onready var grid_node: Node2D = $Grid
@onready var gage_bar: Sprite2D = $UI/GageBar
@onready var btn_back: Button = $UI/BackButton

var cols := 6
var rows := 6

# ==========================================
# 🍅 [방울토마토 위치 맞춤 설정] 🍅
# 에디터에서 게임판(BoardBg) 크기나 위치를 수정하셨다면,
# 방울토마토가 칸에 딱 맞게 들어가도록 아래 숫자들을 조절해 보세요!
var cell_space_x := 100.0 # 토마토 간의 가로 간격 (넓으면 줄이세요)
var cell_space_y := 98.0 # 토마토 간의 세로 간격
var tweak_pos_x := -95.0    # 전체 덩어리의 좌우 위치 (오른쪽: +, 왼쪽: -)
var tweak_pos_y := 30.0    # 전체 덩어리의 상하 위치 (아래: +, 위: -)
var tomato_scale := 0.9   # 토마토 알맹이 자체의 크기 조절 (작게 하려면 0.8 등)
# ==========================================

var icons = [
	preload("res://assets/game/tomato/tomato-icon1.png"),
	preload("res://assets/game/tomato/tomato-icon2.png"),
	preload("res://assets/game/tomato/tomato-icon3.png"),
	preload("res://assets/game/tomato/tomato-icon4.png"),
	preload("res://assets/game/tomato/tomato-icon5.png"),
	preload("res://assets/game/tomato/tomato-icon6.png")
]

var booms = [
	preload("res://assets/game/tomato/boom1.png"),
	preload("res://assets/game/tomato/boom2.png"),
	preload("res://assets/game/tomato/boom3.png")
]

var grid_data: Array = []
var selected_cell := Vector2i(-1, -1)

var score := 0
var max_score := 100
var is_game_over := false
var game_active := false
var start_popup: CanvasLayer
var is_animating := false

func _ready() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_minigame_bgm()
	if has_node("/root/MobileUI"):
		var m_ui = get_node("/root/MobileUI")
		m_ui.hide()
		m_ui.process_mode = Node.PROCESS_MODE_DISABLED
	
	btn_back.pressed.connect(_shuffle_grid)
	
	_init_grid()
	_show_instruction_popup()

func _exit_tree() -> void:
	if has_node("/root/MobileUI"):
		var m_ui = get_node("/root/MobileUI")
		m_ui.show()
		m_ui.process_mode = Node.PROCESS_MODE_INHERIT

func _init_grid() -> void:
	for x in range(cols):
		grid_data.append([])
		for y in range(rows):
			grid_data[x].append(null)
			
	for x in range(cols):
		for y in range(rows):
			var type = _get_random_type(x, y)
			_spawn_icon(x, y, type)

func _get_random_type(x: int, y: int) -> int:
	var type = randi() % icons.size()
	while true:
		var has_horizontal_match = (x >= 2 and grid_data[x-1][y] and grid_data[x-2][y] and grid_data[x-1][y].get_meta("type") == type and grid_data[x-2][y].get_meta("type") == type)
		var has_vertical_match = (y >= 2 and grid_data[x][y-1] and grid_data[x][y-2] and grid_data[x][y-1].get_meta("type") == type and grid_data[x][y-2].get_meta("type") == type)
		if not has_horizontal_match and not has_vertical_match:
			break
		type = randi() % icons.size()
	return type

func _spawn_icon(x: int, y: int, type: int) -> void:
	var sprite = Sprite2D.new()
	sprite.texture = icons[type]
	sprite.set_meta("type", type)
	sprite.set_meta("grid_pos", Vector2i(x, y))
	sprite.position = _get_pos(x, y)
	sprite.scale = Vector2(tomato_scale, tomato_scale)
	grid_node.add_child(sprite)
	grid_data[x][y] = sprite

func _get_pos(x: int, y: int) -> Vector2:
	var base_offset_x = - (cols * cell_space_x) / 2.0 + cell_space_x / 2.0 + tweak_pos_x
	var base_offset_y = - (rows * cell_space_y) / 2.0 + cell_space_y / 2.0 + tweak_pos_y
	return Vector2(base_offset_x + x * cell_space_x, base_offset_y + y * cell_space_y)

func _get_cell_from_pos(pos: Vector2) -> Vector2i:
	var local = (pos - grid_node.position) / grid_node.scale
	var base_offset_x = - (cols * cell_space_x) / 2.0 + cell_space_x / 2.0 + tweak_pos_x
	var base_offset_y = - (rows * cell_space_y) / 2.0 + cell_space_y / 2.0 + tweak_pos_y
	var x = int(floor((local.x - base_offset_x + cell_space_x/2.0) / cell_space_x))
	var y = int(floor((local.y - base_offset_y + cell_space_y/2.0) / cell_space_y))
	return Vector2i(x, y)

var drag_start_cell := Vector2i(-1, -1)

func _unhandled_input(event: InputEvent) -> void:
	if not game_active or is_game_over or is_animating: return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var cell = _get_cell_from_pos(event.position)
			if cell.x >= 0 and cell.x < cols and cell.y >= 0 and cell.y < rows:
				drag_start_cell = cell
				_on_click(event.position)
		else:
			drag_start_cell = Vector2i(-1, -1)
			
	elif event is InputEventMouseMotion and drag_start_cell != Vector2i(-1, -1):
		var cell = _get_cell_from_pos(event.position)
		if cell.x >= 0 and cell.x < cols and cell.y >= 0 and cell.y < rows:
			if cell != drag_start_cell:
				var dx = abs(cell.x - drag_start_cell.x)
				var dy = abs(cell.y - drag_start_cell.y)
				if (dx == 1 and dy == 0) or (dx == 0 and dy == 1):
					_on_click(event.position)
					drag_start_cell = Vector2i(-1, -1)

func _on_click(pos: Vector2) -> void:
	var cell = _get_cell_from_pos(pos)
	if cell.x < 0 or cell.x >= cols or cell.y < 0 or cell.y >= rows:
		return
		
	if selected_cell == Vector2i(-1, -1):
		selected_cell = cell
		# Highlight selected
		if grid_data[cell.x][cell.y]:
			grid_data[cell.x][cell.y].modulate = Color(1.5, 1.5, 1.5)
	else:
		# Unhighlight
		if grid_data[selected_cell.x][selected_cell.y]:
			grid_data[selected_cell.x][selected_cell.y].modulate = Color(1, 1, 1)
			
		var dx = abs(cell.x - selected_cell.x)
		var dy = abs(cell.y - selected_cell.y)
		if (dx == 1 and dy == 0) or (dx == 0 and dy == 1):
			_swap_cells(selected_cell, cell)
		
		selected_cell = Vector2i(-1, -1)

func _swap_cells(c1: Vector2i, c2: Vector2i) -> void:
	is_animating = true
	var s1 = grid_data[c1.x][c1.y]
	var s2 = grid_data[c2.x][c2.y]
	
	grid_data[c1.x][c1.y] = s2
	grid_data[c2.x][c2.y] = s1
	
	var tw = create_tween()
	tw.set_parallel(true)
	if s1: tw.tween_property(s1, "position", _get_pos(c2.x, c2.y), 0.2).set_trans(Tween.TRANS_QUAD)
	if s2: tw.tween_property(s2, "position", _get_pos(c1.x, c1.y), 0.2).set_trans(Tween.TRANS_QUAD)
	
	tw.set_parallel(false)
	tw.tween_callback(func():
		var matches = _find_matches()
		if matches.size() > 0:
			_process_matches(matches)
		else:
			# Revert swap
			grid_data[c1.x][c1.y] = s1
			grid_data[c2.x][c2.y] = s2
			var tw2 = create_tween()
			tw2.set_parallel(true)
			if s1: tw2.tween_property(s1, "position", _get_pos(c1.x, c1.y), 0.2).set_trans(Tween.TRANS_QUAD)
			if s2: tw2.tween_property(s2, "position", _get_pos(c2.x, c2.y), 0.2).set_trans(Tween.TRANS_QUAD)
			tw2.set_parallel(false)
			tw2.tween_callback(func(): is_animating = false)
	)

func _find_matches() -> Array:
	var matches = []
	# Horizontal
	for y in range(rows):
		var match_count = 1
		for x in range(1, cols):
			if grid_data[x][y] and grid_data[x-1][y] and grid_data[x][y].get_meta("type") == grid_data[x-1][y].get_meta("type"):
				match_count += 1
			else:
				if match_count >= 3:
					for i in range(match_count):
						var m = Vector2i(x - 1 - i, y)
						if not m in matches: matches.append(m)
				match_count = 1
		if match_count >= 3:
			for i in range(match_count):
				var m = Vector2i(cols - 1 - i, y)
				if not m in matches: matches.append(m)
				
	# Vertical
	for x in range(cols):
		var match_count = 1
		for y in range(1, rows):
			if grid_data[x][y] and grid_data[x][y-1] and grid_data[x][y].get_meta("type") == grid_data[x][y-1].get_meta("type"):
				match_count += 1
			else:
				if match_count >= 3:
					for i in range(match_count):
						var m = Vector2i(x, y - 1 - i)
						if not m in matches: matches.append(m)
				match_count = 1
		if match_count >= 3:
			for i in range(match_count):
				var m = Vector2i(x, rows - 1 - i)
				if not m in matches: matches.append(m)
				
	return matches

func _process_matches(matches: Array) -> void:
	if matches.is_empty():
		is_animating = false
		return
		
	# Increase score based on number of matched blocks, or just fixed +10 per combo
	score += min(matches.size() * 3, 20) 
	score = min(score, 100)
	
	var score_step = int(score / 10) * 10
	var gage_path = "res://assets/game/tomato/%dper.png" % score_step
	gage_bar.texture = load(gage_path)
	
	# Explode
	if matches.size() > 0 and has_node("/root/AudioManager"):
		AudioManager.play_pop_sfx()
		
	for m in matches:
		var s = grid_data[m.x][m.y]
		if s:
			# Play explosion
			var expl = Sprite2D.new()
			expl.texture = booms[0]
			expl.global_position = s.global_position
			add_child(expl)
			var tw = create_tween()
			tw.tween_interval(0.1)
			tw.tween_callback(func(): expl.texture = booms[1])
			tw.tween_interval(0.1)
			tw.tween_callback(func(): expl.texture = booms[2])
			tw.tween_interval(0.1)
			tw.tween_callback(func(): expl.queue_free())
			
			s.queue_free()
			grid_data[m.x][m.y] = null
			
	var tw = create_tween()
	tw.tween_interval(0.3)
	tw.tween_callback(_apply_gravity)

func _apply_gravity() -> void:
	var tw = create_tween()
	tw.set_parallel(true)
	var any_moved = false
	
	for x in range(cols):
		var empty_slots = 0
		for y in range(rows - 1, -1, -1):
			if grid_data[x][y] == null:
				empty_slots += 1
			elif empty_slots > 0:
				var s = grid_data[x][y]
				grid_data[x][y + empty_slots] = s
				grid_data[x][y] = null
				tw.tween_property(s, "position", _get_pos(x, y + empty_slots), 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
				any_moved = true
				
		for i in range(empty_slots):
			var type = randi() % icons.size()
			var s = Sprite2D.new()
			s.texture = icons[type]
			s.set_meta("type", type)
			s.position = _get_pos(x, -empty_slots + i)
			grid_node.add_child(s)
			grid_data[x][i] = s
			tw.tween_property(s, "position", _get_pos(x, i), 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			any_moved = true
			
	tw.set_parallel(false)
	if any_moved:
		tw.tween_interval(0.1)
		tw.tween_callback(func():
			var matches = _find_matches()
			_process_matches(matches)
		)
	else:
		is_animating = false
		if score < 100 and not is_game_over and not _has_possible_match():
			_auto_shuffle()
		
	if score >= 100 and not is_game_over:
		_game_over()

func _shuffle_grid() -> void:
	if is_animating or is_game_over or not game_active: return
	
	selected_cell = Vector2i(-1, -1)
	for x in range(cols):
		for y in range(rows):
			if grid_data[x][y]:
				grid_data[x][y].queue_free()
			grid_data[x][y] = null
			
	for x in range(cols):
		for y in range(rows):
			var type = _get_random_type(x, y)
			_spawn_icon(x, y, type)
			
	if not _has_possible_match():
		call_deferred("_shuffle_grid")

func _has_possible_match() -> bool:
	for x in range(cols):
		for y in range(rows):
			if x < cols - 1:
				_test_swap(x, y, x + 1, y)
				var match_r = _find_matches().size() > 0
				_test_swap(x, y, x + 1, y)
				if match_r: return true
				
			if y < rows - 1:
				_test_swap(x, y, x, y + 1)
				var match_d = _find_matches().size() > 0
				_test_swap(x, y, x, y + 1)
				if match_d: return true
	return false

func _test_swap(x1: int, y1: int, x2: int, y2: int) -> void:
	var s1 = grid_data[x1][y1]
	var s2 = grid_data[x2][y2]
	grid_data[x1][y1] = s2
	grid_data[x2][y2] = s1

func _auto_shuffle() -> void:
	is_animating = true
	var label = Label.new()
	label.text = "더 이상 깰 수 있는 방울토마토가 없어요!\n자동으로 섞습니다..."
	label.add_theme_font_override("font", load(FONT_PATH))
	label.add_theme_font_size_override("font_size", 48)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	
	var ui_layer = $UI
	ui_layer.add_child(label)
	
	var tw = create_tween()
	tw.tween_interval(1.5)
	tw.tween_callback(func():
		label.queue_free()
		is_animating = false
		_shuffle_grid()
	)

func _game_over() -> void:
	is_game_over = true
	var tw = create_tween()
	tw.tween_interval(1.5)
	tw.tween_callback(_show_success_popup)

func _show_success_popup() -> void:
	var success_popup = CanvasLayer.new()
	success_popup.layer = 150
	add_child(success_popup)
	
	var panel = Panel.new()
	success_popup.add_child(panel)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -300
	panel.offset_top = -150
	panel.offset_right = 300
	panel.offset_bottom = 150
	
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(bg)
	
	var label = Label.new()
	label.text = "방울토마토 100% 달성!\n\n농부 할아버지에게 돌아가서 말을 걸자!"
	label.add_theme_font_override("font", load(FONT_PATH))
	label.add_theme_font_size_override("font_size", 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_top = -30
	panel.add_child(label)
	
	var btn = Button.new()
	btn.text = "텃밭으로 돌아가기"
	btn.add_theme_font_override("font", load(FONT_PATH))
	btn.add_theme_font_size_override("font_size", 26)
	btn.anchor_left = 0.5
	btn.anchor_top = 1.0
	btn.anchor_right = 0.5
	btn.anchor_bottom = 1.0
	btn.offset_left = -150
	btn.offset_top = -80
	btn.offset_right = 150
	btn.offset_bottom = -20
	panel.add_child(btn)
	
	btn.pressed.connect(func():
		GameManager.tomato_quest_state = 2
		_on_back_pressed()
	)

func _on_back_pressed() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		GameManager.return_position = players[0].global_position
		GameManager.use_return_position = true
	get_tree().change_scene_to_file("res://scenes/Farm.tscn")

func _show_instruction_popup() -> void:
	start_popup = CanvasLayer.new()
	start_popup.layer = 150
	add_child(start_popup)
	
	var panel = Panel.new()
	start_popup.add_child(panel)
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
	title.text = "방울토마토 팡팡 퍼즐"
	if font: title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 40
	panel.add_child(title)
	
	var desc = Label.new()
	desc.text = "인접한 방울토마토 타일의 위치를 서로 바꾸어\n같은 색상의 타일을 3개 이상 가로세로로 맞추세요!\n\n게이지를 100%까지 채우면 성공입니다."
	if font: desc.add_theme_font_override("font", font)
	desc.add_theme_font_size_override("font_size", 28)
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
		start_popup.queue_free()
		game_active = true
	)
