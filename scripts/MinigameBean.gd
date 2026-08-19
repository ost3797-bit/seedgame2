extends Node2D

const FONT_PATH := "res://fonts/Cafe24Ssurround-v2.0.ttf"

@onready var grid_node: ColorRect = $Grid
@onready var inv_node: Node2D = $Inventory
@onready var start_pos: Sprite2D = $StartPos
@onready var end_pos: Sprite2D = $EndPos
@onready var btn_check: Button = $UI/CheckButton
@onready var btn_reset: Button = $UI/ResetButton

var grid_size := 5
# cell_size는 _ready()에서 GameBoard 크기 기반으로 자동 계산됩니다
var cell_size := 150.0
var offset_x := 0.0
var offset_y := 0.0

var board: Dictionary = {} # Vector2i -> { type: int, rot: int, sprite: Sprite2D, is_fixed: bool }
var start_cell := Vector2i(0, 4)
var end_cell := Vector2i(4, 0)

var dragged_sprite: Sprite2D = null
var dragged_type: int = 0
var dragged_offset := Vector2.ZERO
var dragged_from_board := false
var dragged_original_cell := Vector2i.ZERO

enum TileType { NONE, STRAIGHT, T_SHAPE, L_SHAPE }

var tile_tex: Array = [
	null,
	preload("res://assets/game/bean/tile1-1.png"),
	preload("res://assets/game/bean/tile2-4.png"),
	preload("res://assets/game/bean/tile3-2.png")
]

var tile_e_tex: Array = [
	null,
	preload("res://assets/game/bean/tilee1-1.png"),
	preload("res://assets/game/bean/tilee2-4.png"),
	preload("res://assets/game/bean/tilee3-2.png")
]

# Base connections (0 degrees)
# STRAIGHT (tile1-1): Up, Down
# T_SHAPE (tile2-4): Left, Right, Down
# L_SHAPE (tile3-2): Up, Right
# Base connections (0 degrees)
# STRAIGHT (tile1-1): Up, Down
# T_SHAPE (tile2-4): Down, Left, Right
# L_SHAPE (tile3-2): Left, Down
var base_conns = {
	TileType.STRAIGHT: [Vector2i(0, -1), Vector2i(0, 1)],
	TileType.T_SHAPE: [Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)],
	TileType.L_SHAPE: [Vector2i(-1, 0), Vector2i(0, 1)]
}

var is_game_over := false
var start_popup: CanvasLayer

var current_stage := 1
var fixed_blocks := [] # Array of Vector2i for current stage

func _ready() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_minigame_bgm()
	if has_node("/root/MobileUI"):
		var m_ui = get_node("/root/MobileUI")
		m_ui.hide()
		m_ui.process_mode = Node.PROCESS_MODE_DISABLED
	
	# ─── 1. Grid 노드(ColorRect) 기반 설정 ──────────────────
	# 에디터에서 빨간 네모(Grid)의 모서리를 드래그해서 크기와 위치를 맞추세요.
	cell_size = grid_node.size.x / float(grid_size)
	offset_x = cell_size / 2.0
	offset_y = cell_size / 2.0

	
	# ─── 2. StartPos / EndPos 그리드 셀에 정렬 (유지) ────────────────────────
	
	# ─── 3. 게임 시작 ───────────────────────
	_start_stage(1)
	
	btn_check.pressed.connect(_on_check_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	
	_setup_grid()
	_setup_inventory()

func _exit_tree() -> void:
	if has_node("/root/MobileUI"):
		var m_ui = get_node("/root/MobileUI")
		m_ui.show()
		m_ui.process_mode = Node.PROCESS_MODE_INHERIT



func _start_stage(stage: int) -> void:
	current_stage = stage
	is_game_over = false
	btn_check.show()
	btn_check.text = "물 주기 (확인)"
	btn_check.modulate = Color(1, 1, 1)
	fixed_blocks.clear()
	
	# Clear existing board
	for cell in board.keys():
		var b = board[cell]
		if is_instance_valid(b.sprite):
			b.sprite.queue_free()
	board.clear()
	
	if current_stage == 2:
		# 고정 지지대를 왼쪽 위(1, 1)로 이동하고 ㄱ자 모양 적용
		_place_fixed_block(Vector2i(1, 1), TileType.L_SHAPE, 2, "")
	elif current_stage == 3:
		# 거리를 띄우고(1,3과 3,1) 서로 다른 블록(ㄱ자, ㄱ자) 사용
		_place_fixed_block(Vector2i(1, 3), TileType.L_SHAPE, 1, "1")
		_place_fixed_block(Vector2i(3, 1), TileType.L_SHAPE, 3, "2")
		
	_show_instruction_popup()

func _place_fixed_block(cell: Vector2i, type: int, rot: int, label_text: String) -> void:
	var sprite = Sprite2D.new()
	sprite.texture = tile_tex[type]
	grid_node.add_child(sprite)
	sprite.scale = _get_target_scale(sprite)
	sprite.position = _get_cell_pos(cell)
	sprite.rotation_degrees = rot * 90.0
	sprite.set_meta("rot", rot)
	
	if label_text != "":
		var lbl = Label.new()
		lbl.text = label_text
		var font = load(FONT_PATH)
		if font: lbl.add_theme_font_override("font", font)
		lbl.add_theme_font_size_override("font_size", 60)
		lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		lbl.add_theme_constant_override("outline_size", 8)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		var tex_size = sprite.texture.get_size()
		lbl.position = -tex_size / 2.0
		lbl.size = tex_size
		
		# Cancel rotation visually for the label so the number reads upright
		lbl.rotation_degrees = -rot * 90.0
		lbl.pivot_offset = lbl.size / 2.0
		
		sprite.add_child(lbl)
		
	board[cell] = { "type": type, "rot": rot, "sprite": sprite, "is_fixed": true }
	fixed_blocks.append(cell)

func _setup_grid() -> void:
	grid_node.z_index = 40

func _setup_inventory() -> void:
	for child in inv_node.get_children():
		if child is Sprite2D:
			child.set_meta("source", true)
			if child.texture == tile_tex[TileType.STRAIGHT]:
				child.set_meta("type", TileType.STRAIGHT)
			elif child.texture == tile_tex[TileType.T_SHAPE]:
				child.set_meta("type", TileType.T_SHAPE)
			elif child.texture == tile_tex[TileType.L_SHAPE]:
				child.set_meta("type", TileType.L_SHAPE)

func _get_cell_pos(cell: Vector2i) -> Vector2:
	return Vector2(offset_x + cell.x * cell_size, offset_y + cell.y * cell_size)

func _get_cell_from_pos(pos: Vector2) -> Vector2i:
	var local = grid_node.get_global_transform().affine_inverse() * pos
	var x = round((local.x - offset_x) / cell_size)
	var y = round((local.y - offset_y) / cell_size)
	return Vector2i(x, y)

func _unhandled_input(event: InputEvent) -> void:
	if is_game_over or (start_popup and start_popup.visible): return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_try_pickup(event.position)
		else:
			_try_drop(event.position)
	elif event is InputEventMouseMotion:
		if dragged_sprite:
			dragged_sprite.global_position = event.position + dragged_offset

func _try_pickup(pos: Vector2) -> void:
	# Check board first (to move or rotate)
	var cell = _get_cell_from_pos(pos)
	if _is_valid_cell(cell) and board.has(cell):
		var b = board[cell]
		if b.get("is_fixed", false): return # Cannot pick up or rotate fixed blocks!
		
		if has_node("/root/AudioManager"):
			AudioManager.play_wood_sfx()
			
		dragged_sprite = b.sprite
		dragged_type = b.type
		dragged_offset = dragged_sprite.global_position - pos
		dragged_from_board = true
		dragged_original_cell = cell
		board.erase(cell)
		return
		
	# Check inventory
	for child in inv_node.get_children():
		if child is Sprite2D and child.has_meta("source") and child.get_meta("source") == true:
			if child.has_meta("type"):
				if child.get_rect().has_point(child.to_local(pos)):
					dragged_type = child.get_meta("type")
					
					if has_node("/root/AudioManager"):
						AudioManager.play_wood_sfx()
						
					dragged_sprite = Sprite2D.new()
					dragged_sprite.texture = tile_tex[dragged_type]
					dragged_sprite.global_position = child.global_position
					dragged_sprite.scale = _get_target_scale(dragged_sprite) * 0.495
					dragged_offset = dragged_sprite.global_position - pos
					dragged_from_board = false
					add_child(dragged_sprite)
					return

func _try_drop(pos: Vector2) -> void:
	if not dragged_sprite: return
	
	var cell = _get_cell_from_pos(dragged_sprite.global_position)
	var moved_dist = dragged_sprite.global_position.distance_to(pos + dragged_offset) if dragged_from_board else 100.0
	
	if dragged_from_board and moved_dist < 10.0:
		# Just a click: Rotate 90 degrees
		dragged_sprite.rotation_degrees += 90.0
		if dragged_sprite.rotation_degrees >= 360.0:
			dragged_sprite.rotation_degrees -= 360.0
		_place_on_board(cell, dragged_type, dragged_sprite)
		if has_node("/root/AudioManager"):
			AudioManager.play_wood_sfx()
	else:
		if _is_valid_cell(cell) and not board.has(cell):
			_place_on_board(cell, dragged_type, dragged_sprite)
			if has_node("/root/AudioManager"):
				AudioManager.play_wood_sfx()
		else:
			dragged_sprite.queue_free()
			
	dragged_sprite = null

func _place_on_board(cell: Vector2i, type: int, sprite: Sprite2D) -> void:
	if sprite.get_parent() != grid_node:
		sprite.get_parent().remove_child(sprite)
		grid_node.add_child(sprite)
	sprite.scale = _get_target_scale(sprite)
	sprite.position = _get_cell_pos(cell)
	var rot = int(round(sprite.rotation_degrees / 90.0)) % 4
	if rot < 0: rot += 4
	board[cell] = { "type": type, "rot": rot, "sprite": sprite, "is_fixed": false }



func _is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < grid_size and cell.y >= 0 and cell.y < grid_size

func _get_target_scale(sprite: Sprite2D) -> Vector2:
	if not sprite or not sprite.texture: return Vector2(1, 1)
	var tex_size = sprite.texture.get_size()
	# cell_size는 Grid 로컬 좌표계 기준이므로 그대로 사용
	return Vector2(cell_size / tex_size.x, cell_size / tex_size.y)

func _get_connections(cell: Vector2i) -> Array:
	if not board.has(cell): return []
	var b = board[cell]
	var conns = base_conns[b.type]
	var res = []
	for c in conns:
		var rotated = _rotate_vec(c, b.rot)
		res.append(cell + rotated)
	return res

func _rotate_vec(v: Vector2i, rot: int) -> Vector2i:
	var cur = v
	for i in range(rot):
		cur = Vector2i(-cur.y, cur.x)
	return cur

func _on_check_pressed() -> void:
	if is_game_over: return
	
	# ===== DEBUG: 모든 셀의 연결 방향 출력 =====
	print("=== 보드 상태 디버그 ===")
	print("start_cell:", start_cell, "  end_cell:", end_cell)
	for cell in board.keys():
		var b = board[cell]
		var conns = _get_connections(cell)
		print("셀", cell, " 타입:", b.type, " rot:", b.rot, " 각도:", b.sprite.rotation_degrees, " → 연결:", conns)
	print("========================")
	
	var valid_paths = []
	var visited = {}
	var current_path = []
	
	# Recursively find all paths
	var find_paths = Callable()
	find_paths = func(curr: Vector2i, path_so_far: Array, self_ref: Callable):
		if curr == end_cell:
			valid_paths.append(path_so_far.duplicate())
			return
			
		var conns = _get_connections(curr)
		for next_cell in conns:
			if next_cell == end_cell:
				var final_path = path_so_far.duplicate()
				final_path.append(end_cell)
				valid_paths.append(final_path)
				continue
				
			if _is_valid_cell(next_cell) and board.has(next_cell) and not visited.has(next_cell):
				var next_conns = _get_connections(next_cell)
				var connects_back = false
				for nc in next_conns:
					if nc == curr:
						connects_back = true
						break
				if connects_back:
					visited[next_cell] = true
					path_so_far.append(next_cell)
					self_ref.call(next_cell, path_so_far, self_ref)
					path_so_far.pop_back()
					visited.erase(next_cell)
					
	# Seed the DFS with nodes connected to start_cell
	visited[start_cell] = true
	var start_path = [start_cell]
	
	# Handle case where block is exactly ON start_cell
	if board.has(start_cell):
		find_paths.call(start_cell, start_path, find_paths)
	else:
		for dir in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
			var adj = start_cell + dir
			if board.has(adj):
				var conns = _get_connections(adj)
				for c in conns:
					if c == start_cell:
						visited[adj] = true
						start_path.append(adj)
						find_paths.call(adj, start_path, find_paths)
						start_path.pop_back()
						visited.erase(adj)
						break

	var success = false
	var final_winning_path = []
	
	for path in valid_paths:
		var satisfies_constraints = true
		
		# Validate stage constraints
		if current_stage == 2:
			if not fixed_blocks[0] in path:
				satisfies_constraints = false
		elif current_stage == 3:
			var idx1 = path.find(fixed_blocks[0])
			var idx2 = path.find(fixed_blocks[1])
			if idx1 == -1 or idx2 == -1 or idx1 > idx2:
				satisfies_constraints = false
				
		if satisfies_constraints:
			success = true
			final_winning_path = path
			break
			
	if success:
		_win_anim(final_winning_path, end_cell)
	else:
		_fail_anim()

func _fail_anim() -> void:
	if current_stage == 2 or current_stage == 3:
		btn_check.text = "규칙을 위반했거나 끊겼어!"
	else:
		btn_check.text = "연결이 끊겼어!"
	var tw = create_tween()
	tw.tween_property(btn_check, "modulate", Color(1, 0, 0), 0.2)
	tw.tween_property(btn_check, "modulate", Color(1, 1, 1), 0.2)
	tw.tween_callback(func(): btn_check.text = "물 주기 (확인)")

func _win_anim(path: Array, end: Vector2i) -> void:
	is_game_over = true
	btn_check.hide()
	
	# path array contains start_cell and end_cell. We only need the board blocks.
	var board_path = []
	for cell in path:
		if board.has(cell):
			board_path.append(cell)
			
	var delay = 0.0
	for cell in board_path:
		var b = board[cell]
		var tw = create_tween()
		tw.tween_interval(delay)
		tw.tween_callback(func():
			b.sprite.texture = tile_e_tex[b.type]
		)
		delay += 0.3
		
	var final_tw = create_tween()
	final_tw.tween_interval(delay + 0.5)
	
	if current_stage < 3:
		final_tw.tween_callback(func(): _show_stage_clear_popup(current_stage))
	else:
		final_tw.tween_callback(_show_success_popup)

func _show_stage_clear_popup(stage: int) -> void:
	var popup = CanvasLayer.new()
	popup.layer = 150
	add_child(popup)
	
	var panel = Panel.new()
	popup.add_child(panel)
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
	label.text = str(stage) + "단계 성공! 다음 단계로 넘어갑니다."
	label.add_theme_font_override("font", preload("res://fonts/Cafe24Ssurround-v2.0.ttf"))
	label.add_theme_font_size_override("font_size", 32)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.anchor_left = 0.5
	label.anchor_top = 0.5
	label.anchor_right = 0.5
	label.anchor_bottom = 0.5
	label.offset_left = -250
	label.offset_top = -60
	label.offset_right = 250
	label.offset_bottom = 40
	panel.add_child(label)
	
	var btn = Button.new()
	btn.text = "다음 단계 시작"
	btn.add_theme_font_override("font", preload("res://fonts/Cafe24Ssurround-v2.0.ttf"))
	btn.add_theme_font_size_override("font_size", 28)
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
		popup.queue_free()
		_start_stage(stage + 1)
	)

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
	label.text = "최종 3단계 물 주기 성공!\n\n농부 할아버지에게 돌아가서 말을 걸자!"
	label.add_theme_font_override("font", preload("res://fonts/Cafe24Ssurround-v2.0.ttf"))
	label.add_theme_font_size_override("font_size", 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.anchor_left = 0.5
	label.anchor_top = 0.5
	label.anchor_right = 0.5
	label.anchor_bottom = 0.5
	label.offset_left = -250
	label.offset_top = -50
	label.offset_right = 250
	label.offset_bottom = 50
	panel.add_child(label)
	
	var btn = Button.new()
	btn.text = "텃밭으로 돌아가기"
	btn.add_theme_font_override("font", preload("res://fonts/Cafe24Ssurround-v2.0.ttf"))
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
		GameManager.bean_quest_state = 2
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			GameManager.return_position = players[0].global_position
			GameManager.use_return_position = true
		get_tree().change_scene_to_file("res://scenes/Farm.tscn")
	)

func _on_reset_pressed() -> void:
	if not is_game_over:
		var cells_to_remove = []
		for cell in board.keys():
			if not board[cell].get("is_fixed", false):
				cells_to_remove.append(cell)
		
		for cell in cells_to_remove:
			var b = board[cell]
			if is_instance_valid(b.sprite):
				b.sprite.queue_free()
			board.erase(cell)

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
	panel.offset_left = -450
	panel.offset_top = -250
	panel.offset_right = 450
	panel.offset_bottom = 250
	
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(bg)
	
	var font = load(FONT_PATH)
	
	var title = Label.new()
	if current_stage == 1:
		title.text = "1단계: 햇빛을 향한 덩굴 미로"
	elif current_stage == 2:
		title.text = "2단계: 고정 지지대 통과"
	elif current_stage == 3:
		title.text = "3단계: 순서대로 통과"
	if font: title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 40
	panel.add_child(title)
	
	var desc = Label.new()
	if current_stage == 1:
		desc.text = "하단의 줄기 조각을 드래그하여 빈칸을 채우세요!\n배치된 조각을 터치(클릭)하면 90도 회전합니다.\n\n출발점(씨앗)부터 상단의 도착점(햇빛)까지\n줄기가 끊기지 않게 연결한 후 [물 주기]를 누르세요!"
	elif current_stage == 2:
		desc.text = "이번에는 텃밭 중간에 고정된 지지대가 있습니다.\n반드시 이 지지대를 거쳐서 연결해야 합니다!"
	elif current_stage == 3:
		desc.text = "이번에는 고정된 지지대가 2개 있습니다.\n반드시 1번 지지대를 먼저 지나고, 2번 지지대를 지나도록\n순서대로 연결해야 합니다!"
	if font: desc.add_theme_font_override("font", font)
	desc.add_theme_font_size_override("font_size", 28)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	desc.offset_top = 130
	desc.offset_bottom = 350
	desc.offset_left = 20
	desc.offset_right = -20
	panel.add_child(desc)
	
	var start_btn = Button.new()
	start_btn.text = "게임 시작"
	if font: start_btn.add_theme_font_override("font", font)
	start_btn.add_theme_font_size_override("font_size", 32)
	start_btn.custom_minimum_size = Vector2(240, 70)
	start_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	start_btn.offset_left = 330
	start_btn.offset_top = -110
	start_btn.offset_right = -330
	start_btn.offset_bottom = -40
	panel.add_child(start_btn)
	
	start_btn.pressed.connect(func():
		start_popup.queue_free()
	)
