extends Node2D

const FONT_PATH := "res://fonts/Cafe24Ssurround-v2.0.ttf"

@onready var spots_parent: Node2D = $CornSpots
@onready var score_label: Label = $UI/ScoreLabel
@onready var btn_back: Button = $UI/BackButton

var tex_corn1 = preload("res://assets/game/corn/corn1.png")
var tex_corn2 = preload("res://assets/game/corn/corn2.png")
var tex_corn3 = preload("res://assets/game/corn/corn3.png")
var tex_corn4 = preload("res://assets/game/corn/corn4.png")
var tex_corn5 = preload("res://assets/game/corn/corn5.png")
var tex_corn6 = preload("res://assets/game/corn/corn6.png")
var tex_corn7 = preload("res://assets/game/corn/corn7.png")

var score := 0
var max_score := 18
var is_game_over := false
var game_active := false
var start_popup: CanvasLayer

class CornSpot:
	var area: Area2D
	var sprite: Sprite2D
	var state: int = 0 # 0: idle(corn1), 1: popping, 2: popped/empty
	var timer: float = 0.0
	var pop_stage: int = 0
	
var spots: Array[CornSpot] = []
var spawn_timer := 0.0
var spawn_interval := 1.0

func _ready() -> void:
	if has_node("/root/MobileUI"):
		var m_ui = get_node("/root/MobileUI")
		m_ui.hide()
		m_ui.process_mode = Node.PROCESS_MODE_DISABLED
	
	btn_back.pressed.connect(_on_back_pressed)
	
	for child in spots_parent.get_children():
		if child is Area2D:
			var cs = CornSpot.new()
			cs.area = child
			cs.sprite = child.get_node("Sprite2D")
			cs.area.input_event.connect(_on_spot_input_event.bind(cs))
			spots.append(cs)
			
	_show_instruction_popup()

func _process(delta: float) -> void:
	if not game_active or is_game_over: return
	
	# Handle spawning
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = randf_range(0.4, 1.2)
		_activate_random_spot()
		
	# Handle states
	for cs in spots:
		if cs.state == 1:
			cs.timer -= delta
			if cs.timer <= 0.0:
				if cs.pop_stage == 0:
					cs.sprite.texture = tex_corn3
					cs.pop_stage = 1
					cs.timer = 0.2
				elif cs.pop_stage == 1:
					cs.sprite.texture = tex_corn4
					cs.pop_stage = 2
					cs.timer = 0.8 # Time to click
				elif cs.pop_stage == 2:
					# Missed
					cs.sprite.texture = tex_corn1
					cs.state = 0
					cs.pop_stage = 0

func _activate_random_spot() -> void:
	var idle_spots = []
	for cs in spots:
		if cs.state == 0:
			idle_spots.append(cs)
			
	if idle_spots.size() > 0:
		var target = idle_spots[randi() % idle_spots.size()]
		target.state = 1
		target.pop_stage = 0
		target.timer = 0.2
		target.sprite.texture = tex_corn2

func _on_spot_input_event(viewport: Node, event: InputEvent, shape_idx: int, cs: CornSpot) -> void:
	if not game_active or is_game_over: return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_try_harvest(cs)
	elif event is InputEventScreenTouch and event.pressed:
		_try_harvest(cs)

func _try_harvest(cs: CornSpot) -> void:
	if cs.state == 1:
		cs.state = 2 # Harvested
		cs.sprite.texture = null # Hide original
		
		# Play harvest effect
		score += 1
		_update_score()
		
		var effect = Sprite2D.new()
		effect.texture = tex_corn5
		effect.global_position = cs.area.global_position
		effect.scale = cs.area.scale * 0.85
		add_child(effect)
		
		var tw = create_tween()
		tw.tween_interval(0.1)
		tw.tween_callback(func(): effect.texture = tex_corn6)
		tw.tween_interval(0.1)
		tw.tween_callback(func(): effect.texture = tex_corn7)
		# Fall down
		tw.tween_property(effect, "global_position:y", effect.global_position.y + 600.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func(): effect.queue_free())
		
		# Optional: Audio stream for popping sound
		# var ap = AudioStreamPlayer.new()
		# ap.stream = preload("res://assets/game/corn/pop.wav")
		# add_child(ap)
		# ap.play()
		
		if score >= max_score:
			_game_over()

func _update_score() -> void:
	score_label.text = "수확량: %d / %d" % [score, max_score]

func _game_over() -> void:
	is_game_over = true
	var tw = create_tween()
	tw.tween_interval(1.0)
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
	label.text = "옥수수 18개 수확 완료!\n\n농부 할아버지에게 돌아가서 말을 걸자!"
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
		GameManager.corn_quest_state = 2
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
	title.text = "톡톡 옥수수 알 빼기"
	if font: title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 40
	panel.add_child(title)
	
	var desc = Label.new()
	desc.text = "톡톡 튀어나오려고 반짝이는 옥수수 알갱이를\n재빠르게 터치하여 수확하세요!\n\n18개의 옥수수 알을 모두 수확하면 성공입니다."
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
