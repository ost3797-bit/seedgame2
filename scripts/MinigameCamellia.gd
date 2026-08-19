extends Node2D

const FONT_PATH := "res://fonts/Cafe24Ssurround-v2.0.ttf"

@onready var fruit_sprite = $FruitArea/Sprite2D
@onready var fruit_area = $FruitArea

@onready var boom_template = $BoomTemplate
@onready var popup_layer = $PopupLayer
@onready var hammer_cursor = $HammerCursor

var current_stage := 1
var max_stage := 7
var clicks_per_stage := 15
var current_clicks := 0

var game_active := true

func _ready() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_minigame_bgm()
	if has_node("/root/MobileUI"):
		get_node("/root/MobileUI").hide()
		
	boom_template.hide()
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		
	fruit_area.input_event.connect(_on_fruit_input_event)

func _process(_delta: float) -> void:
	if is_instance_valid(hammer_cursor):
		hammer_cursor.global_position = get_global_mouse_position()

func _exit_tree() -> void:
	if has_node("/root/MobileUI"):
		get_node("/root/MobileUI").show()
		
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_fruit_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if not game_active: return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_hit(get_global_mouse_position())
		
		# 모바일 터치 대응
	elif event is InputEventScreenTouch and event.pressed:
		_handle_hit(get_global_mouse_position())

func _handle_hit(hit_pos: Vector2) -> void:
	if not game_active: return
	
	if has_node("/root/AudioManager"):
		AudioManager.play_hammer_sfx()
		
	_animate_hammer()
	_spawn_boom(hit_pos)
	_shake_fruit()
	
	current_clicks += 1
	if current_clicks >= clicks_per_stage:
		current_clicks = 0
		current_stage += 1
		
		if current_stage <= max_stage:
			fruit_sprite.texture = load("res://assets/game/Camellia/camellia_" + str(current_stage) + ".png")
			
		if current_stage >= max_stage:
			_game_over()

func _animate_hammer() -> void:
	if not is_instance_valid(hammer_cursor): return
	var tween = create_tween()
	var orig_rot = hammer_cursor.rotation
	tween.tween_property(hammer_cursor, "rotation", orig_rot - 0.5, 0.05)
	tween.tween_property(hammer_cursor, "rotation", orig_rot, 0.1)

func _spawn_boom(pos: Vector2) -> void:
	var new_boom = boom_template.duplicate()
	new_boom.position = pos
	new_boom.show()
	add_child(new_boom)
	
	var tween = create_tween()
	var target_scale = new_boom.scale * 1.5
	tween.tween_property(new_boom, "scale", target_scale, 0.1)
	tween.parallel().tween_property(new_boom, "modulate:a", 0.0, 0.2)
	tween.tween_callback(new_boom.queue_free)

func _shake_fruit() -> void:
	var tween = create_tween()
	tween.tween_property(fruit_sprite, "position", Vector2(10, 10), 0.05)
	tween.tween_property(fruit_sprite, "position", Vector2(-10, -10), 0.05)
	tween.tween_property(fruit_sprite, "position", Vector2(0, 0), 0.05)

func _game_over() -> void:
	game_active = false
	await get_tree().create_timer(1.0).timeout
	
	popup_layer.show()
	var title_label = popup_layer.get_node("Panel/Title")
	var desc_label = popup_layer.get_node("Panel/Desc")
	var btn = popup_layer.get_node("Panel/ReturnBtn")
	
	title_label.text = "성공!"
	desc_label.text = "단단한 동백 열매를 깨고 까만 씨앗을 얻었습니다!\n\n이제 다람쥐에게 돌아가세요!"
	
	GameManager.camellia_quest_state = 2
	btn.pressed.connect(_on_return_btn_pressed)

func _on_return_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Forest.tscn")
