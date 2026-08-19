extends Node

var bgm_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

var main_bgm: AudioStream
var minigame_bgm: AudioStream
var sfx_reward: AudioStream
var sfx_pop: AudioStream
var sfx_hammer: AudioStream
var sfx_wood: AudioStream

func _ready() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"
	add_child(bgm_player)
	
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "Master"
	add_child(sfx_player)
	
	main_bgm = preload("res://assets/music/Over_the_Stone_Bridge.mp3")
	minigame_bgm = preload("res://assets/music/Hidden_Moss_Trail.mp3")
	sfx_reward = preload("res://assets/music/cute-happy.mp3")
	sfx_pop = preload("res://assets/music/pop.mp3")
	sfx_hammer = preload("res://assets/music/hammering_Dg4o80PG.mp3")
	sfx_wood = preload("res://assets/music/wood.mp3")
	
	# Loop BGM
	if main_bgm is AudioStreamMP3:
		main_bgm.loop = true
	if minigame_bgm is AudioStreamMP3:
		minigame_bgm.loop = true

func play_main_bgm() -> void:
	if bgm_player.stream != main_bgm:
		bgm_player.stream = main_bgm
		bgm_player.play()

func play_minigame_bgm() -> void:
	if bgm_player.stream != minigame_bgm:
		bgm_player.stream = minigame_bgm
		bgm_player.play()

func play_reward_sfx() -> void:
	sfx_player.stream = sfx_reward
	sfx_player.play()

func play_pop_sfx() -> void:
	var player = AudioStreamPlayer.new()
	player.bus = "Master"
	player.stream = sfx_pop
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func play_hammer_sfx() -> void:
	sfx_player.stream = sfx_hammer
	sfx_player.play()

func play_wood_sfx() -> void:
	sfx_player.stream = sfx_wood
	sfx_player.play()
