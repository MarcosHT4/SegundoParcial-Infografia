extends Node2D


var ring_angle = 184
var flip_ring = false
var label_position = Vector2.ZERO
var width_with_offset = (ProjectSettings.get("display/window/size/width")/2) - 180
var height_with_offset = (ProjectSettings.get("display/window/size/height")/2) - 90

var game_over_audio = preload("res://assets/main/game_over.wav")
var game_won_audio = preload("res://assets/main/game_won.wav")

onready var player = $Player
onready var timer = $GameOverTimer
onready var timer_won = $GameWonTimer
onready var game_over_label = $GameOverLabel
onready var game_won_label = $GameWonLabel
onready var goal = $World/Goal
onready var end_collision = $World/EndCollision/CollisionShape2D
onready var audio_player = $Songs




func _ready():
	player.connect("drop_rings",self, "_make_rings_drop")
	player.connect("player_dead", self, "show_game_over")
	goal.connect("game_won", self, "show_game_won")
	goal.connect("disable_left_map", self, "enable_end_collision")
	
func _process(delta):
	if not audio_player.playing and (audio_player.stream == game_won_audio or audio_player.stream == game_over_audio):
		get_tree().change_scene("res://scenes/TitleScreen.tscn")	
	
	
	
	
func _make_rings_drop(ring_count):
	for i in range(0, ring_count):
		create_ring()

func create_ring():
	var ring_scene = preload("res://scenes/Ring.tscn")
	var ring_node = ring_scene.instance()
	ring_node.lost_ring = true
	ring_node.created_collision = true
	ring_node.position.x = player.position.x - 500
	ring_node.position.y = player.position.y - 430
	ring_node.scale.x = 2
	ring_node.scale.y = 2
	ring_node.velocity.x = ring_node.speed*cos(ring_angle)
	ring_node.velocity.y = ring_node.speed*(-sin(ring_angle))
	if flip_ring:
		ring_node.velocity.x = ring_node.velocity.x*-1
		ring_angle += 22.5
	flip_ring = not flip_ring
	ring_node.non_collectable_ring = true
	add_child(ring_node)
	ring_node.start_ring_non_collectable()
	
	
	
		

func enable_end_collision():
	end_collision.call_deferred("set_disabled", false)
	
	
func show_game_over(final_position):
	label_position = final_position
	label_position.x += width_with_offset
	label_position.y += height_with_offset 
	timer.start()			

func show_game_won(goal_position):
		
	label_position = goal_position
	label_position.x += (width_with_offset+270)
	label_position.y += (height_with_offset+240)
	timer_won.start()
		


func _on_GameOverTimer_timeout():
	end_game(timer, game_over_label, label_position,game_over_audio)

func _on_GameWonTimer_timeout():
	end_game(timer_won, game_won_label, label_position,game_won_audio)
	
	
func change_and_play_audio(audio):
	audio_player.stream = audio
	audio_player.play()	
	
func end_game(timer, label, label_final_position, audio):

	timer.stop()
	label.visible = true
	label.set_global_position(label_final_position)
	change_and_play_audio(audio)
	
	
			
	
	
	
	
