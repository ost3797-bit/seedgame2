extends "res://scripts/MapController.gd"

const FONT_PATH := "res://fonts/Cafe24Ssurround-v2.0.ttf"

var seed_ui: CanvasLayer
@onready var squirrel_npc: Area2D = $SquirrelNPC
@onready var hint_label: Label = $SquirrelNPC/HintLabel

@onready var maple_tree: Area2D = $MapleTree
@onready var maple_hint: Label = $MapleTree/HintLabel
@onready var camellia_tree: Area2D = $CamelliaTree
@onready var camellia_hint: Label = $CamelliaTree/HintLabel

@onready var reward_popup: CanvasLayer = $RewardPopup
@onready var reward_card: TextureRect = $RewardPopup/RewardCard
@onready var btn_close: TextureButton = $RewardPopup/BtnClose

@onready var squirrel_marker: Label = $SquirrelNPC/QuestMarker
@onready var maple_marker: Label = $MapleTree/QuestMarker
@onready var camellia_marker: Label = $CamelliaTree/QuestMarker

var dialogue_panel: ColorRect
var dialogue_text: Label
var dialogue_npc_name: Label
var dialogue_accept_btn: Button
var is_near_squirrel := false
var is_near_maple := false
var is_near_camellia := false

var is_typing := false
var type_timer := 0.0
var full_dialogue_text := ""
var chars_per_sec := 45.0
var dialogue_queue: Array[String] = []
var current_speaker := ""
var _pending_accept := Callable()

func _ready() -> void:
	super._ready()
	_build_ui()
	_build_dialogue_panel()
	
	if squirrel_npc:
		squirrel_npc.body_entered.connect(_on_squirrel_body_entered)
		squirrel_npc.body_exited.connect(_on_squirrel_body_exited)
		
	if maple_tree:
		maple_tree.body_entered.connect(_on_maple_body_entered)
		maple_tree.body_exited.connect(_on_maple_body_exited)
		
	if camellia_tree:
		camellia_tree.body_entered.connect(_on_camellia_body_entered)
		camellia_tree.body_exited.connect(_on_camellia_body_exited)
			
	if btn_close:
		btn_close.pressed.connect(_on_reward_close_pressed)

	_update_quest_markers()

func _update_quest_markers() -> void:
	if not is_instance_valid(squirrel_marker): return
	
	squirrel_marker.hide()
	maple_marker.hide()
	camellia_marker.hide()
	
	# 다람쥐 마커
	if GameManager.maple_quest_state == 0 or (GameManager.maple_quest_state == 3 and GameManager.camellia_quest_state == 0):
		squirrel_marker.text = "!"
		squirrel_marker.add_theme_color_override("font_color", Color(1.0, 0.9, 0.0))
		squirrel_marker.show()
	elif GameManager.maple_quest_state == 2 or GameManager.camellia_quest_state == 2:
		squirrel_marker.text = "?"
		squirrel_marker.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		squirrel_marker.show()
		
	# 식물 마커
	if GameManager.maple_quest_state == 1:
		maple_marker.text = "!"
		maple_marker.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		maple_marker.show()
		
	if GameManager.camellia_quest_state == 1:
		camellia_marker.text = "!"
		camellia_marker.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		camellia_marker.show()

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

func _on_squirrel_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_near_squirrel = true
		if hint_label: hint_label.show()

func _on_squirrel_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_near_squirrel = false
		if hint_label: hint_label.hide()

func _on_maple_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_near_maple = true
		if maple_hint: maple_hint.show()

func _on_maple_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_near_maple = false
		if maple_hint: maple_hint.hide()

func _on_camellia_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_near_camellia = true
		if camellia_hint: camellia_hint.show()

func _on_camellia_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_near_camellia = false
		if camellia_hint: camellia_hint.hide()

func _process(delta: float) -> void:
	if maple_tree: maple_tree.visible = (GameManager.maple_quest_state >= 1)
	if camellia_tree: camellia_tree.visible = (GameManager.camellia_quest_state >= 1)
	
	if squirrel_marker and squirrel_marker.visible:
		squirrel_marker.position.y = -120 + sin(Time.get_ticks_msec() / 150.0) * 8.0
	if maple_marker and maple_marker.visible:
		maple_marker.position.y = -110 + sin(Time.get_ticks_msec() / 150.0) * 8.0
	if camellia_marker and camellia_marker.visible:
		camellia_marker.position.y = -110 + sin(Time.get_ticks_msec() / 150.0) * 8.0
		
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
		if is_near_squirrel:
			_interact_squirrel()
			if get_viewport(): get_viewport().set_input_as_handled()
		elif is_near_maple:
			_interact_maple()
			if get_viewport(): get_viewport().set_input_as_handled()
		elif is_near_camellia:
			_interact_camellia()
			if get_viewport(): get_viewport().set_input_as_handled()

func _interact_maple() -> void:
	if GameManager.maple_quest_state == 0:
		_show_dialogue("시스템", ["지금은 이 나무를 건드릴 필요가 없을 것 같다.\n먼저 다람쥐와 대화하자."], func(): pass)
	elif GameManager.maple_quest_state == 1:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			GameManager.return_position = players[0].global_position
			GameManager.use_return_position = true
		get_tree().change_scene_to_file("res://scenes/MinigameMaple.tscn")
	elif GameManager.maple_quest_state >= 2:
		_show_dialogue("시스템", ["이미 단풍나무 씨앗을 모두 모았다!"], func(): pass)

func _interact_camellia() -> void:
	if GameManager.camellia_quest_state == 0:
		_show_dialogue("시스템", ["지금은 이 나무를 건드릴 필요가 없을 것 같다.\n먼저 다람쥐와 대화하자."], func(): pass)
	elif GameManager.camellia_quest_state == 1:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			GameManager.return_position = players[0].global_position
			GameManager.use_return_position = true
		get_tree().change_scene_to_file("res://scenes/MinigameCamellia.tscn")
	elif GameManager.camellia_quest_state >= 2:
		_show_dialogue("시스템", ["이미 동백나무 씨앗을 모두 모았다!"], func(): pass)

func _interact_squirrel() -> void:
	if GameManager.maple_quest_state == 0:
		_show_dialogue("다람쥐 나무꾼", [
			"찍찍! 숲에 온 걸 환영해!\n나는 이 숲을 지키는 다람쥐 나무꾼이야.",
			"가을이 오면 숲에는 수많은 씨앗들이 열리지.\n내가 모으는 걸 좀 도와줄래?",
			"저기 있는 단풍나무에서 씨앗이 떨어지고 있어!\n바구니를 들고 떨어지는 씨앗들을 모두 받아줘!"
		], func():
			GameManager.maple_quest_state = 1
			_update_quest_markers()
		)
	elif GameManager.maple_quest_state == 1:
		_show_dialogue("다람쥐 나무꾼", ["단풍나무 밑으로 가서 떨어지는 씨앗을 받아와!"], func(): pass)
	elif GameManager.maple_quest_state == 2:
		_show_dialogue("다람쥐 나무꾼", [
			"우와! 단풍나무 씨앗을 다 받아냈구나!",
			"이건 수고한 보상이야, 단풍나무 씨앗 카드를 줄게!"
		], func():
			GameManager.maple_quest_state = 3
			GameManager.forest_maple_cleared = true
			GameManager.collected_seeds += 1
			reward_card.texture = load("res://assets/game/maple/maplecard.png")
			reward_popup.show()
			_update_quest_markers()
			
			if seed_ui and seed_ui.has_method("update_counter"):
				seed_ui.update_counter()
		)
	elif GameManager.maple_quest_state == 3 and GameManager.camellia_quest_state == 0:
		_show_dialogue("다람쥐 나무꾼", [
			"이제 다음 나무로 가볼까?",
			"오른쪽으로 가면 단단한 껍질을 가진 동백 열매가 떨어져 있을 거야.",
			"내 망치를 빌려줄 테니, 껍질을 부수고 그 안의 까만 씨앗을 꺼내봐!"
		], func():
			GameManager.camellia_quest_state = 1
			_update_quest_markers()
		)
	elif GameManager.camellia_quest_state == 1:
		_show_dialogue("다람쥐 나무꾼", ["동백 열매를 찾아서 망치로 껍질을 부숴봐!"], func(): pass)
	elif GameManager.camellia_quest_state == 2:
		_show_dialogue("다람쥐 나무꾼", [
			"대단해! 그렇게 단단한 껍질을 깨고 씨앗을 꺼내다니!",
			"정말 수고 많았어. 이건 내 마지막 선물이야!"
		], func():
			GameManager.camellia_quest_state = 3
			GameManager.forest_camellia_cleared = true
			GameManager.collected_seeds += 1
			reward_card.texture = load("res://assets/game/Camellia/camelliacard.png")
			reward_popup.show()
			_update_quest_markers()
			
			if seed_ui and seed_ui.has_method("update_counter"):
				seed_ui.update_counter()
		)
	elif GameManager.camellia_quest_state == 3:
		_show_dialogue("다람쥐 나무꾼", ["숲의 씨앗을 전부 다 찾았네! 너는 숲의 영웅이야!"], func(): pass)

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
