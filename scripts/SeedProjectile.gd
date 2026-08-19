extends RigidBody2D

@onready var sprite = $Sprite2D
var anim_timer = 0.0

func _ready():
	# 약간 회전하면서 날아가게 초기 각속도
	angular_velocity = randf_range(2.0, 5.0)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name == "Floor":
		var game = get_parent()
		if game and game.has_method("_on_miss"):
			game._on_miss()
