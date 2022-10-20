extends KinematicBody2D
var picked_up = false

onready var state_machine = $AnimationTree.get("parameters/playback")
onready var sprite = $Sprite
onready var hitbox = $Hitbox/CollisionShape2D
onready var animation_player = $AnimationPlayer
onready var collision = $CollisionShape2D
onready var timer = $DissapearanceTimer
onready var timer_collectable = $Collectable_Timer
onready var audio_player = $Effects



var speed = 200
var velocity = Vector2.ZERO
var lost_ring = false
var created_collision = false
var bouncing = false
var timer_time_out = false
var non_collectable_ring = false 

var pick_up_ring_audio = preload("res://assets/world/pick_up_ring.wav")


func _process(delta):
	
	if picked_up:
		
		state_machine.travel("collected")
		state_machine.travel("gone")
		picked_up = false
		lost_ring = false
		collision.disabled = true
		
func _physics_process(delta):
	
	if non_collectable_ring:
		hitbox.disabled = true
			
	if lost_ring:
		
		if created_collision:
			collision.disabled = false
			created_collision = false
			
		if get_slide_count() == 0 :
			if not bouncing:
				hitbox.disabled = true
				timer.start()
			velocity.y += 10
			
		elif not timer_time_out:
			bouncing = true
			bounce()
				
		else:
			picked_up = true		
		
		move_and_slide(velocity)	

func bounce():
	if not non_collectable_ring:
		hitbox.disabled = false
	var collision_with_block = get_slide_collision(0)
	velocity.y-=20
	if collision_with_block != null:
			velocity = velocity.bounce(collision_with_block.normal)
			
				
func change_and_play_audio(audio):
	audio_player.stream = audio
	audio_player.play()	

func _on_Hitbox_area_entered(area):
	change_and_play_audio(pick_up_ring_audio)
	picked_up = true
	
	
	
func _on_Timer_timeout():
	state_machine.travel('gone')
	timer.stop()
	timer_time_out = true
	

func start_ring_non_collectable():
	non_collectable_ring = true
	timer_collectable.start()

func _on_Collectable_Timer_timeout():
	timer_collectable.stop()
	non_collectable_ring = false
	hitbox.disabled = false
