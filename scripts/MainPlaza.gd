extends "res://scripts/MapController.gd"

@onready var seed_house = $SeedHouse
@onready var seed_house_sprite = $SeedHouse/Sprite2D
@onready var seed_house_hint = $SeedHouse/HintLabel
@onready var seed_house_ui = $SeedHouseUI

var is_near_seed_house := false

func _ready() -> void:
	super._ready()
	
	if seed_house:
		seed_house.body_entered.connect(_on_seed_house_entered)
		seed_house.body_exited.connect(_on_seed_house_exited)
		
	# 처음에는 외곽선 끄기
	if seed_house_sprite and seed_house_sprite.material:
		seed_house_sprite.material.set_shader_parameter("outline_enabled", false)

func _on_seed_house_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_near_seed_house = true
		if seed_house_hint:
			seed_house_hint.show()
		if seed_house_sprite and seed_house_sprite.material:
			seed_house_sprite.material.set_shader_parameter("outline_enabled", true)

func _on_seed_house_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_near_seed_house = false
		if seed_house_hint:
			seed_house_hint.hide()
		if seed_house_sprite and seed_house_sprite.material:
			seed_house_sprite.material.set_shader_parameter("outline_enabled", false)

func _unhandled_input(event: InputEvent) -> void:
	if seed_house_ui and seed_house_ui.visible:
		get_viewport().set_input_as_handled()
		return
		
	if is_near_seed_house and (event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_SPACE)):
		if seed_house_ui:
			seed_house_ui.update_cards()
			seed_house_ui.show()
			get_viewport().set_input_as_handled()
