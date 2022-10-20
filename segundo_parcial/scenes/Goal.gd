extends KinematicBody2D


var velocity = Vector2.ZERO
var entered_area = false
var finished_spinning = false
onready var state_machine = $AnimationTree.get("parameters/playback")
onready var collision_shape = $CollisionShape2D
onready var timer = $GoalDownTimer
onready var area_square = $Area2D
onready var area_detection = $Area2D/CollisionShape2D
onready var audio_player = $Effects

var goal_spin_audio = preload("res://assets/world/goal_spin.wav")

signal game_won(goal_position)
signal disable_left_map()

func _ready():
	collision_shape.disabled = true
	

func _physics_process(delta):
	if get_slide_count() > 0 and not finished_spinning:
		state_machine.travel("end")
		emit_signal("game_won", global_position)
		finished_spinning = true
	move_and_slide(velocity)


func _on_Area2D_area_entered(area):
	if not entered_area:
		start_spinning()
		

func start_spinning():
	area_detection.call_deferred("set_disabled", true)
	state_machine.travel("rotating")
	velocity.y -= 300
	timer.start()
	change_and_play_audio(goal_spin_audio)
	entered_area = true
	emit_signal("disable_left_map")
			
		
		
	
func _on_GoalDownTimer_timeout():
	collision_shape.disabled = false
	timer.stop()
	velocity.y+=600
	
func change_and_play_audio(audio):
	audio_player.stream = audio
	audio_player.play()	
