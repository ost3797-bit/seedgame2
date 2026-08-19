extends Node2D

const FONT_PATH := "res://fonts/Cafe24Ssurround-v2.0.ttf"

@onready var farmer_npc: Area2D = $FarmerNPC
@onready var bean_plant: Area2D = $BeanPlant
@onready var corn_plant: Area2D = $CornPlant
@onready var tomato_plant: Area2D = $TomatoPlant

@onready var farmer_marker: Label = $FarmerNPC/QuestMarker
@onready var bean_marker: Label = $BeanPlant/QuestMarker
@onready var corn_marker: Label = $CornPlant/QuestMarker
@onready var tomato_marker: Label = $TomatoPlant/QuestMarker

@onready var btn_close: TextureButton = $RewardPopup/CloseButton
@onready var reward_popup: CanvasLayer = $RewardPopup
@onready var reward_card: TextureRect = $RewardPopup/RewardCard

var is_near_farmer := false
var is_near_bean := false
var is_near_corn := false
var is_near_tomato := false

var seed_ui: CanvasLayer

var dialogue_panel: ColorRect
var dialogue_text: Label
var dialogue_npc_name: Label
var dialogue_accept_btn: Button

var is_typing := false
var type_timer := 0.0
var full_dialogue_text := ""
var chars_per_sec := 45.0
var dialogue_queue: Array[String] = []
var current_speaker := ""
var _pending_accept := Callable()

var farmer_marker_base_y := -100.0
var bean_marker_base_y := -80.0
var corn_marker_base_y := -80.0
var tomato_marker_base_y := -80.0

var pending_final_dialogue := false

func _ready() -> void:
	if has_node("/root/MobileUI"):
		var m_ui = get_node("/root/MobileUI")
		m_ui.show()
		m_ui.process_mode = Node.PROCESS_MODE_INHERIT
		
	if GameManager.use_return_position:
		var players = get_tree().get_nodes_in_group("player")
		for p in players:
			p.global_position = GameManager.return_position
		GameManager.use_return_position = false
		
	_build_ui()
	_build_dialogue_panel()
	
	if farmer_npc:
		farmer_npc.body_entered.connect(_on_farmer_body_entered)
		farmer_npc.body_exited.connect(_on_farmer_body_exited)
		
	if bean_plant:
		bean_plant.body_entered.connect(_on_bean_body_entered)
		bean_plant.body_exited.connect(_on_bean_body_exited)
		
	if corn_plant:
		corn_plant.body_entered.connect(_on_corn_body_entered)
		corn_plant.body_exited.connect(_on_corn_body_exited)

	if tomato_plant:
		tomato_plant.body_entered.connect(_on_tomato_body_entered)
		tomato_plant.body_exited.connect(_on_tomato_body_exited)
			
	if btn_close:
		btn_close.pressed.connect(_on_reward_close_pressed)

	if farmer_marker: farmer_marker_base_y = farmer_marker.position.y
	if bean_marker: bean_marker_base_y = bean_marker.position.y
	if corn_marker: corn_marker_base_y = corn_marker.position.y
	if tomato_marker: tomato_marker_base_y = tomato_marker.position.y

	_update_quest_markers()

func _update_quest_markers() -> void:
	if not is_instance_valid(farmer_marker): return
	
	farmer_marker.hide()
	bean_marker.hide()
	corn_marker.hide()
	tomato_marker.hide()
	
	if GameManager.bean_quest_state == 0 or (GameManager.bean_quest_state == 3 and GameManager.corn_quest_state == 0) or (GameManager.corn_quest_state == 3 and GameManager.tomato_quest_state == 0):
		farmer_marker.text = "!"
		farmer_marker.add_theme_color_override("font_color", Color(1.0, 0.9, 0.0))
		farmer_marker.show()
	elif GameManager.bean_quest_state == 2 or GameManager.corn_quest_state == 2 or GameManager.tomato_quest_state == 2:
		farmer_marker.text = "?"
		farmer_marker.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		farmer_marker.show()
		
	if GameManager.bean_quest_state == 1:
		bean_marker.text = "!"
		bean_marker.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		bean_marker.show()
		
	if GameManager.corn_quest_state == 1:
		corn_marker.text = "!"
		corn_marker.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		corn_marker.show()

	if GameManager.tomato_quest_state == 1:
		tomato_marker.text = "!"
		tomato_marker.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		tomato_marker.show()

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
	if font: dialogue_npc_name.add_theme_font_override("font", font)
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
	if font: dialogue_text.add_theme_font_override("font", font)
	dialogue_text.add_theme_font_size_override("font_size", 32)
	dialogue_panel.add_child(dialogue_text)
	
	dialogue_accept_btn = Button.new()
	dialogue_accept_btn.text = "계속"
	dialogue_accept_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	dialogue_accept_btn.offset_left = -260
	dialogue_accept_btn.offset_top = -70
	dialogue_accept_btn.offset_right = -20
	dialogue_accept_btn.offset_bottom = -20
	if font: dialogue_accept_btn.add_theme_font_override("font", font)
	dialogue_accept_btn.add_theme_font_size_override("font_size", 26)
	dialogue_accept_btn.pressed.connect(_accept_dialogue)
	
	var sc := Shortcut.new()
	var ev_space := InputEventKey.new()
	ev_space.physical_keycode = KEY_SPACE
	ev_space.pressed = true
	sc.events.append(ev_space)
	dialogue_accept_btn.shortcut = sc
	
	dialogue_panel.add_child(dialogue_accept_btn)

func _on_farmer_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"): is_near_farmer = true

func _on_farmer_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"): is_near_farmer = false

func _on_bean_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"): is_near_bean = true

func _on_bean_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"): is_near_bean = false

func _on_corn_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"): is_near_corn = true

func _on_corn_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"): is_near_corn = false

func _on_tomato_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"): is_near_tomato = true

func _on_tomato_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"): is_near_tomato = false

func _process(delta: float) -> void:
	if bean_plant: bean_plant.visible = (GameManager.bean_quest_state >= 1)
	if corn_plant: corn_plant.visible = (GameManager.corn_quest_state >= 1)
	if tomato_plant: tomato_plant.visible = (GameManager.tomato_quest_state >= 1)
	
	if farmer_marker and farmer_marker.visible:
		farmer_marker.position.y = farmer_marker_base_y + sin(Time.get_ticks_msec() / 150.0) * 8.0
	if bean_marker and bean_marker.visible:
		bean_marker.position.y = bean_marker_base_y + sin(Time.get_ticks_msec() / 150.0) * 8.0
	if corn_marker and corn_marker.visible:
		corn_marker.position.y = corn_marker_base_y + sin(Time.get_ticks_msec() / 150.0) * 8.0
	if tomato_marker and tomato_marker.visible:
		tomato_marker.position.y = tomato_marker_base_y + sin(Time.get_ticks_msec() / 150.0) * 8.0
		
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
		if is_near_farmer:
			_interact_farmer()
			if get_viewport(): get_viewport().set_input_as_handled()
		elif is_near_bean:
			_interact_bean()
			if get_viewport(): get_viewport().set_input_as_handled()
		elif is_near_corn:
			_interact_corn()
			if get_viewport(): get_viewport().set_input_as_handled()
		elif is_near_tomato:
			_interact_tomato()
			if get_viewport(): get_viewport().set_input_as_handled()

func _interact_bean() -> void:
	if GameManager.bean_quest_state == 0:
		_show_dialogue("시스템", ["아직 강낭콩과 상호작용할 수 없다.\n먼저 농부와 대화하자."], func(): pass)
	elif GameManager.bean_quest_state == 1:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			GameManager.return_position = players[0].global_position
			GameManager.use_return_position = true
		get_tree().change_scene_to_file("res://scenes/MinigameBean.tscn")
	elif GameManager.bean_quest_state >= 2:
		_show_dialogue("시스템", ["이미 강낭콩 씨앗을 구했다!"], func(): pass)

func _interact_corn() -> void:
	if GameManager.corn_quest_state == 0:
		_show_dialogue("시스템", ["아직 옥수수와 상호작용할 수 없다.\n먼저 농부와 대화하자."], func(): pass)
	elif GameManager.corn_quest_state == 1:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			GameManager.return_position = players[0].global_position
			GameManager.use_return_position = true
		get_tree().change_scene_to_file("res://scenes/MinigameCorn.tscn")
	elif GameManager.corn_quest_state >= 2:
		_show_dialogue("시스템", ["이미 옥수수 씨앗을 모았다!"], func(): pass)

func _interact_tomato() -> void:
	if GameManager.tomato_quest_state == 0:
		_show_dialogue("시스템", ["아직 방울토마토와 상호작용할 수 없다.\n먼저 농부와 대화하자."], func(): pass)
	elif GameManager.tomato_quest_state == 1:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			GameManager.return_position = players[0].global_position
			GameManager.use_return_position = true
		get_tree().change_scene_to_file("res://scenes/MinigameTomato.tscn")
	elif GameManager.tomato_quest_state >= 2:
		_show_dialogue("시스템", ["이미 방울토마토 씨앗을 모았다!"], func(): pass)

func _interact_farmer() -> void:
	if GameManager.bean_quest_state == 0:
		_show_dialogue("농부", [
			"허허, 텃밭에 온 걸 환영한다!",
			"나는 이 텃밭을 가꾸는 농부란다.",
			"씨앗을 구하러 왔다고?",
			"그렇다면 오른쪽으로 이동해서 텃밭에 있는 강낭콩을 도와주렴!",
			"강낭콩 덩굴이 햇빛을 받도록 길을 이어주면 씨앗을 주마!"
		], func():
			GameManager.bean_quest_state = 1
			_update_quest_markers()
		)
	elif GameManager.bean_quest_state == 1:
		_show_dialogue("농부", ["오른쪽으로 이동해서 강낭콩을 찾아 햇빛까지 덩굴을 연결해보렴!"], func(): pass)
	elif GameManager.bean_quest_state == 2:
		_show_dialogue("농부", [
			"오! 강낭콩 덩굴이 햇빛을 듬뿍 받았구나!",
			"고맙다! 이건 약속한 보상이다!"
		], func():
			GameManager.bean_quest_state = 3
			GameManager.farm_bean_cleared = true
			GameManager.collected_seeds += 1
			reward_card.texture = load("res://assets/game/bean/beancard.png")
			if has_node("/root/AudioManager"):
				AudioManager.play_reward_sfx()
			reward_popup.show()
			_update_quest_markers()
			if seed_ui and seed_ui.has_method("update_counter"): seed_ui.update_counter()
		)
	elif GameManager.bean_quest_state == 3 and GameManager.corn_quest_state == 0:
		_show_dialogue("농부", [
			"다음은 옥수수란다!",
			"왼편에 있는 옥수수 밭으로 가서 톡톡 튀어나오는 옥수수 알갱이를 수확해주면 다음 씨앗을 주마!"
		], func():
			GameManager.corn_quest_state = 1
			_update_quest_markers()
		)
	elif GameManager.corn_quest_state == 1:
		_show_dialogue("농부", ["왼편에 있는 옥수수를 찾아가 톡톡 알 빼기 미션을 수행해보렴!"], func(): pass)
	elif GameManager.corn_quest_state == 2:
		_show_dialogue("농부", [
			"하하! 옥수수 수확을 아주 잘 도와주었구나!",
			"수고했다! 여깄다, 옥수수 씨앗이다!"
		], func():
			GameManager.corn_quest_state = 3
			GameManager.farm_corn_cleared = true
			GameManager.collected_seeds += 1
			reward_card.texture = load("res://assets/game/corn/corncard.png")
			if has_node("/root/AudioManager"):
				AudioManager.play_reward_sfx()
			reward_popup.show()
			_update_quest_markers()
			if seed_ui and seed_ui.has_method("update_counter"): seed_ui.update_counter()
		)
	elif GameManager.corn_quest_state == 3 and GameManager.tomato_quest_state == 0:
		_show_dialogue("농부", [
			"이제 마지막 작물이 남았구나!",
			"왼쪽 아래로 가다보면 나오는 방울토마토 팡팡 퍼즐을 풀어서 열매를 수확해주렴!"
		], func():
			GameManager.tomato_quest_state = 1
			_update_quest_markers()
		)
	elif GameManager.tomato_quest_state == 1:
		_show_dialogue("농부", ["왼쪽 아래로 가다보면 나오는 방울토마토 퍼즐을 풀어서 수확을 도와주렴!"], func(): pass)
	elif GameManager.tomato_quest_state == 2:
		_show_dialogue("농부", [
			"허허허! 방울토마토 수확까지 완벽하게 끝냈구나!",
			"정말 수고 많았다! 약속한 마지막 보상이다!"
		], func():
			GameManager.tomato_quest_state = 3
			GameManager.farm_tomato_cleared = true
			GameManager.collected_seeds += 1
			reward_card.texture = load("res://assets/game/tomato/tomatocard.png")
			if has_node("/root/AudioManager"):
				AudioManager.play_reward_sfx()
			reward_popup.show()
			pending_final_dialogue = true
			_update_quest_markers()
			if seed_ui and seed_ui.has_method("update_counter"): seed_ui.update_counter()
		)
	elif GameManager.tomato_quest_state == 3:
		_show_dialogue("농부", [
			"텃밭 작물들이 아주 쑥쑥 자라겠구나! 고맙다!",
			"수집한 씨앗들은 메인 광장의 '씨앗 보관소'에서 확인할 수 있단다!"
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
		_show_dialogue("농부", [
			"허허허! 텃밭의 모든 미션을 달성했구나!",
			"수집한 씨앗들은 메인 광장의 '씨앗 보관소'에서 확인할 수 있단다!",
			"씨앗 보관소로 돌아가서 도감을 채워보려무나!"
		], func(): pass)
