extends CanvasLayer

func _ready() -> void:
	$Button.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		$Button.text = "전체화면"
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		$Button.text = "창모드"
