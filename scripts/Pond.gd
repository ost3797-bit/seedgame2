extends "res://scripts/MapController.gd"

const FONT_PATH := "res://fonts/Cafe24Ssurround-v2.0.ttf"

var seed_ui: CanvasLayer
@onready var frog_npc: Area2D = $FrogNPC
# @onready var hint_label: Label = $FrogNPC/HintLabel

@onready var hyacinth_plant: Area2D = $HyacinthPlant
# @onready var hyacinth_hint: Label = $HyacinthPlant/HintLabel

@onready var cattail_plant: Area2D = $CattailPlant
# @onready var cattail_hint: Label = $CattailPlant/HintLabel

@onready var reward_popup: CanvasLayer = $RewardPopup
@onready var reward_card: TextureRect = $RewardPopup/RewardCard
@onready var btn_close: TextureButton = $RewardPopup/BtnClose

@onready var frog_marker: Label = $FrogNPC/QuestMarker
@onready var hyacinth_marker: Label = $HyacinthPlant/QuestMarker
@onready var cattail_marker: Label = $CattailPlant/QuestMarker

var dialogue_panel: ColorRect
var dialogue_text: Label
var dialogue_npc_name: Label
var dialogue_accept_btn: Button
var is_near_frog := false
var is_near_hyacinth := false
var is_near_cattail := false

var is_typing := false
var type_timer := 0.0
var full_dialogue_text := ""
var chars_per_sec := 45.0
var dialogue_queue: Array[String] = []
var current_speaker := ""
var _pending_accept := Callable()

var frog_marker_base_y := -120.0
var hyacinth_marker_base_y := -110.0
var cattail_marker_base_y := -110.0
var pending_final_dialogue := false

func _ready() -> void:
	super._ready()
	_build_ui()
	_build_dialogue_panel()
	
	if frog_npc:
		frog_npc.body_entered.connect(_on_frog_body_entered)
		frog_npc.body_exited.connect(_on_frog_body_exited)
		
	if hyacinth_plant:
		hyacinth_plant.body_entered.connect(_on_hyacinth_body_entered)
		hyacinth_plant.body_exited.connect(_on_hyacinth_body_exited)
		
	if cattail_plant:
		cattail_plant.body_entered.connect(_on_cattail_body_entered)
		cattail_plant.body_exited.connect(_on_cattail_body_exited)
			
	if btn_close:
		btn_close.pressed.connect(_on_reward_close_pressed)

	if frog_marker: frog_marker_base_y = frog_marker.position.y
	if hyacinth_marker: hyacinth_marker_base_y = hyacinth_marker.position.y
	if cattail_marker: cattail_marker_base_y = cattail_marker.position.y

	_update_quest_markers()
	
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		var cam = p.get_node_or_null("Camera2D")
		if cam:
			cam.zoom = Vector2(1.2, 1.2)
			cam.limit_left = -960
			cam.limit_right = 960
			cam.limit_top = -540
			cam.limit_bottom = 540

func _update_quest_markers() -> void:
	if not is_instance_valid(frog_marker): return
	
	frog_marker.hide()
	hyacinth_marker.hide()
	if cattail_marker: cattail_marker.hide()
	
	if GameManager.hyacinth_quest_state == 0 or (GameManager.hyacinth_quest_state == 3 and GameManager.cattail_quest_state == 0):
		frog_marker.text = "!"
		frog_marker.add_theme_color_override("font_color", Color(1.0, 0.9, 0.0))
		frog_marker.show()
	elif GameManager.hyacinth_quest_state == 2 or GameManager.cattail_quest_state == 2:
		frog_marker.text = "?"
		frog_marker.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		frog_marker.show()
		
	if GameManager.hyacinth_quest_state == 1:
		hyacinth_marker.text = "!"
		hyacinth_marker.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		hyacinth_marker.show()
		
	if GameManager.cattail_quest_state == 1 and cattail_marker:
		cattail_marker.text = "!"
		cattail_marker.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		cattail_marker.show()

func _build_ui() -> void:
	var seed_ui_script = load("res://scripts/SeedCounterUI.gd")
	if seed_ui_script:
		seed_ui = seed_ui_script.new()
		add_child(seed_ui)

func _build_dialogue_panel() -> void:
	var font = load(FONT_PATH) as FontFile
	
	var dl = CanvasLayer.new()
	dl.layer = 110
	add_child(dl)
	
	dialogue_panel = ColorRect.new()
	dialogue_panel.color = Color(0.1, 0.1, 0.1, 0.9)
	dialogue_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dialogue_panel.offset_top = -260
	dialogue_panel.offset_left = 40
	dialogue_panel.offset_right = -40
	dialogue_panel.offset_bottom = -20
	dialogue_panel.hide()
	dl.add_child(dialogue_panel)
	
	dialogue_npc_name = Label.new()
	dialogue_npc_name.position = Vector2(24, 16)
	if font:
		dialogue_npc_name.add_theme_font_override("font", font)
	dialogue_npc_name.add_theme_font_size_override("font_size", 36)
	dialogue_npc_name.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	dialogue_panel.add_child(dialogue_npc_name)
	
	dialogue_text = Label.new()
	dialogue_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialogue_text.offset_left = 24
	dialogue_text.offset_top = 64
	dialogue_text.offset_right = -180
	dialogue_text.offset_bottom = -24
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if font:
		dialogue_text.add_theme_font_override("font", font)
	dialogue_text.add_theme_font_size_override("font_size", 32)
	dialogue_panel.add_child(dialogue_text)
	
	dialogue_accept_btn = Button.new()
	dialogue_accept_btn.text = "계속"
	dialogue_accept_btn.position = Vector2(740, 130)
	dialogue_accept_btn.size = Vector2(240, 50)
	dialogue_accept_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	dialogue_accept_btn.offset_left = -260
	dialogue_accept_btn.offset_top = -70
	dialogue_accept_btn.offset_right = -20
	dialogue_accept_btn.offset_bottom = -20
	
	if font:
		dialogue_accept_btn.add_theme_font_override("font", font)
	dialogue_accept_btn.add_theme_font_size_override("font_size", 26)
	dialogue_accept_btn.pressed.connect(_accept_dialogue)
	
	var sc := Shortcut.new()
	var ev_space := InputEventKey.new()
	ev_space.physical_keycode = KEY_SPACE
	ev_space.pressed = true
	sc.events.append(ev_space)
	dialogue_accept_btn.shortcut = sc
	
	dialogue_panel.add_child(dialogue_accept_btn)

func _on_frog_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_near_frog = true
		# if hint_label: hint_label.show()

func _on_frog_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_near_frog = false
		# if hint_label: hint_label.hide()

func _on_hyacinth_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_near_hyacinth = true
		# if hyacinth_hint: hyacinth_hint.show()

func _on_hyacinth_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_near_hyacinth = false
		# if hyacinth_hint: hyacinth_hint.hide()

func _on_cattail_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_near_cattail = true
		# if cattail_hint: cattail_hint.show()

func _on_cattail_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_near_cattail = false
		# if cattail_hint: cattail_hint.hide()

func _process(delta: float) -> void:
	if hyacinth_plant: hyacinth_plant.visible = (GameManager.hyacinth_quest_state >= 1)
	if cattail_plant: cattail_plant.visible = (GameManager.cattail_quest_state >= 1)
	
	if frog_marker and frog_marker.visible:
		frog_marker.position.y = frog_marker_base_y + sin(Time.get_ticks_msec() / 150.0) * 8.0
	if hyacinth_marker and hyacinth_marker.visible:
		hyacinth_marker.position.y = hyacinth_marker_base_y + sin(Time.get_ticks_msec() / 150.0) * 8.0
	if cattail_marker and cattail_marker.visible:
		cattail_marker.position.y = cattail_marker_base_y + sin(Time.get_ticks_msec() / 150.0) * 8.0
		
	if is_typing:
		type_timer += delta
		var chars_to_show = int(type_timer * chars_per_sec)
		if chars_to_show >= full_dialogue_text.length():
			dialogue_text.text = full_dialogue_text
			is_typing = false
			dialogue_accept_btn.show()
		else:
			dialogue_text.text = full_dialogue_text.substr(0, chars_to_show)

func _unhandled_input(event: InputEvent) -> void:
	if reward_popup and reward_popup.visible:
		get_viewport().set_input_as_handled()
		return
		
	if dialogue_panel and dialogue_panel.visible:
		if (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_SPACE) or \
		   (event is InputEventScreenTouch and event.pressed):
			if is_typing:
				dialogue_text.text = full_dialogue_text
				is_typing = false
				dialogue_accept_btn.show()
			else:
				if dialogue_accept_btn.visible:
					dialogue_accept_btn.emit_signal("pressed")
			if get_viewport(): get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_SPACE):
		if is_near_frog:
			_interact_frog()
			if get_viewport(): get_viewport().set_input_as_handled()
		elif is_near_hyacinth:
			_interact_hyacinth()
			if get_viewport(): get_viewport().set_input_as_handled()
		elif is_near_cattail:
			_interact_cattail()
			if get_viewport(): get_viewport().set_input_as_handled()

func _interact_hyacinth() -> void:
	if GameManager.hyacinth_quest_state == 0:
		_show_dialogue("시스템", ["아직 연못의 개구리와 이야기하지 않았다.\n먼저 개구리와 대화하자."], func(): pass)
	elif GameManager.hyacinth_quest_state == 1:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			GameManager.return_position = players[0].global_position
			GameManager.use_return_position = true
		get_tree().change_scene_to_file("res://scenes/MinigameHyacinth.tscn")
	elif GameManager.hyacinth_quest_state >= 2:
		_show_dialogue("시스템", ["이미 부레옥잠 씨앗을 구했다!"], func(): pass)

func _interact_cattail() -> void:
	if GameManager.cattail_quest_state == 0:
		_show_dialogue("시스템", ["아직 부들과 상호작용할 수 없다.\n먼저 개구리와 대화하자."], func(): pass)
	elif GameManager.cattail_quest_state == 1:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			GameManager.return_position = players[0].global_position
			GameManager.use_return_position = true
		get_tree().change_scene_to_file("res://scenes/MinigameCattail.tscn")
	elif GameManager.cattail_quest_state >= 2:
		_show_dialogue("시스템", ["이미 부들 솜털 씨앗을 모두 모았다!"], func(): pass)

func _interact_frog() -> void:
	if GameManager.hyacinth_quest_state == 0:
		_show_dialogue("개구리", [
			"개굴! 연못에 온 걸 환영한다구리!",
			"나는 이 연못의 물길을 관리하는 개구리다구리.",
			"새로운 씨앗을 원한다고 구리?",
			"그렇다면 저기 연못 주변에 떠다니는 부레옥잠을 찾아가서 말을 걸어보라구리!",
			"부레옥잠을 채집망으로 조심히 옮겨주면 씨앗을 주겠다구리!"
		], func():
			GameManager.hyacinth_quest_state = 1
			_update_quest_markers()
		)
	elif GameManager.hyacinth_quest_state == 1:
		_show_dialogue("개구리", ["연못 주변의 부레옥잠을 찾아서 말을 걸어보라구리!"], func(): pass)
	elif GameManager.hyacinth_quest_state == 2:
		_show_dialogue("개구리", [
			"개굴! 부레옥잠을 모두 채집망에 안전하게 옮겨주었구나!",
			"고맙다구리! 이건 약속한 보상이다구리!"
		], func():
			GameManager.hyacinth_quest_state = 3
			GameManager.pond_hyacinth_cleared = true
			GameManager.collected_seeds += 1
			reward_card.texture = load("res://assets/game/water/water hyacinthcard.png")
			reward_popup.show()
			_update_quest_markers()
			
			if seed_ui and seed_ui.has_method("update_counter"):
				seed_ui.update_counter()
		)
	elif GameManager.hyacinth_quest_state == 3 and GameManager.cattail_quest_state == 0:
		_show_dialogue("개구리", [
			"개굴! 이제 마지막 미션이 남았다구리!",
			"이번엔 연못가에 있는 '부들'을 찾아가보라구리!",
			"바람을 타고 날아가는 부들 솜털 씨앗을 모아주면 마지막 씨앗 보상을 주겠다구리!"
		], func():
			GameManager.cattail_quest_state = 1
			_update_quest_markers()
		)
	elif GameManager.cattail_quest_state == 1:
		_show_dialogue("개구리", ["연못가의 부들을 찾아서 바람몰이 미션을 수행하라구리!"], func(): pass)
	elif GameManager.cattail_quest_state == 2:
		_show_dialogue("개구리", [
			"개굴! 부들 솜털을 모두 안전하게 모아왔구나!",
			"정말 수고 많았다구리! 약속한 마지막 보상이다구리!"
		], func():
			GameManager.cattail_quest_state = 3
			GameManager.pond_cattail_cleared = true
			GameManager.collected_seeds += 1
			reward_card.texture = load("res://assets/game/flag/flagcard.png")
			reward_popup.show()
			pending_final_dialogue = true
			_update_quest_markers()
			
			if seed_ui and seed_ui.has_method("update_counter"):
				seed_ui.update_counter()
		)
	elif GameManager.cattail_quest_state == 3:
		_show_dialogue("개구리", [
			"연못이 아주 풍성해졌다구리! 정말 고맙다구리!",
			"수집한 씨앗들은 메인 광장의 '씨앗 보관소'에서 확인할 수 있다구리!",
			"씨앗 보관소로 돌아가서 수집한 씨앗들을 확인해 보라구리!"
		], func(): pass)

func _show_dialogue(speaker: String, texts: Array, on_accept: Callable) -> void:
	if texts.is_empty(): return
	
	dialogue_queue.assign(texts)
	current_speaker = speaker
	_pending_accept = on_accept
	
	_show_next_dialogue()

func _show_next_dialogue() -> void:
	if dialogue_queue.is_empty():
		dialogue_panel.hide()
		is_typing = false
		if _pending_accept.is_valid():
			_pending_accept.call()
		_pending_accept = Callable()
		return
		
	var next_text = dialogue_queue.pop_front()
	dialogue_panel.show()
	dialogue_npc_name.text = current_speaker
	full_dialogue_text = next_text
	dialogue_text.text = ""
	is_typing = true
	type_timer = 0.0
	dialogue_accept_btn.hide()

func _accept_dialogue() -> void:
	_show_next_dialogue()

func _on_reward_close_pressed() -> void:
	if reward_popup: reward_popup.hide()
	
	if pending_final_dialogue:
		pending_final_dialogue = false
		_show_dialogue("개구리", [
			"개굴! 연못의 미션을 모두 달성했구나!",
			"수집한 씨앗들은 메인 광장의 '씨앗 보관소'에서 확인할 수 있다구리!",
			"씨앗 보관소로 돌아가서 수집한 씨앗들을 확인해 보라구리!"
		], func(): pass)
