extends KinematicBody2D

const ACCEL = 500
const MAX_SPEED = 500
const FRICTION = 500
const ROLLING_FRICTION = 250
const JUMP_FORCE = -900
const SPIN_DASH_ACCEL = 60000
const MAX_ROLLING_SPEED = 40000
const GRAVITY = 30
const DAMAGE_KNOCKBACK = 900
var velocity = Vector2.ZERO
var abrupt_change = false
var abrupt_change_to_left = false
var abrupt_change_to_right = false
var rolling = false
var jumping = false
var spin_dash = false
var charging_spin_attack = false
var damage_taken = false
var dead = false
var end = false
var invicibility_after_damage = false
var on_air = false
var hit_environment_danger = false
var rebound = false
var audio_has_been_played = false
var animation_timer_started = false
var ring_count = 0
var enemy_killed:KinematicBody2D = null
var final_position = Vector2.ZERO


var flip_ring = false
var ring_angle = 184

var jump_audio = preload("res://assets/player/jump.mp3")
var spin_dash_audio = preload("res://assets/player/spin_dash.mp3")
var spin_dash_release_audio = preload("res://assets/player/spin_dash_release.mp3")
var abrupt_change_audio = preload("res://assets/player/abrupt_change.mp3")
var spin_attack_audio = preload("res://assets/player/spin_attack.mp3")
var rings_lost_audio = preload("res://assets/player/rings_lost.wav")
var dead_audio = preload("res://assets/player/dead.wav")
var lock_camera = false



onready var ring_label = $RingCounter
onready var camera = $Camera2D
onready var state_machine = $AnimationTree.get("parameters/playback")
onready var player_collision = $CollisionShape2D
onready var hurtbox_collision = $Hurtbox/CollisionShape2D
onready var hitbox_collision = $Hitbox/CollisionShape2D
onready var ring_collision = $RingCollection/CollisionShape2D
onready var followbox_collision = $Followbox/CollisionShape2D
onready var audio_player = $Effects
onready var animation_timer = $WaitTimerAnimation

signal drop_rings(ring_count)
signal player_dead(final_position)



func _input(event):
	if event is InputEventKey:
		if event.scancode == KEY_LEFT:
			if velocity.x >= 250 :
				abrupt_change = true
				abrupt_change_to_left = true
				if is_on_floor():
					change_and_play_audio(abrupt_change_audio)
			
		elif event.scancode == KEY_RIGHT :
			if velocity.x <= -250:
				abrupt_change = true
				abrupt_change_to_right = true
				if is_on_floor():		
					change_and_play_audio(abrupt_change_audio)
		elif event.scancode == KEY_DOWN and int(round(velocity.x)) != 0:
			rolling = true
			if not audio_player.playing:
				change_and_play_audio(spin_attack_audio)
	
		elif event.scancode == KEY_SPACE and is_on_floor():
			if not audio_player.playing:
				change_and_play_audio(jump_audio)
			jumping = true
			on_air = true	
	
		elif event.scancode == KEY_Z and is_on_floor() and int(round(velocity.x)) == 0:
			charging_spin_attack = true
			state_machine.travel("spin_dash")
			if not audio_player.playing:
				change_and_play_audio(spin_dash_audio)
			if not event.pressed:
				audio_player.stop()
				change_and_play_audio(spin_dash_release_audio)
				spin_dash = true
				charging_spin_attack = false
			
func _physics_process(delta):
	var input_vector = Vector2.ZERO
	if not invicibility_after_damage:
	
		input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		input_vector = input_vector.normalized()
	
	velocity.y = velocity.y + GRAVITY
	#print(is_on_floor())
	if not is_on_floor() and not charging_spin_attack and not invicibility_after_damage and on_air:
		jump()
	elif is_on_floor() and invicibility_after_damage:
		invicibility_after_damage = false	
	if input_vector != Vector2.ZERO and not rolling and not charging_spin_attack and not dead:
		animation_timer_started = false
		animation_timer.stop()
		velocity = velocity.move_toward(input_vector*MAX_SPEED, ACCEL*delta)
		accelerate()
	elif not rolling:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION*delta)
		deaccelerate()	
	if velocity.x < 0:
		$Sprite.scale.x = -1
	elif velocity.x > 0:
		$Sprite.scale.x = 1
	
	if abrupt_change:
		skid()
	if rolling:
		velocity = velocity.move_toward(Vector2.ZERO, ROLLING_FRICTION*delta)
		roll()		
	if jumping:
		if rolling:
			rolling = false
		velocity.y = JUMP_FORCE
		jumping = false
	if lock_camera:
		camera.global_position = final_position
	if spin_dash :
		rolling = true
		var unit_vector
		if $Sprite.scale.x == 1:
			unit_vector = Vector2.RIGHT	
		else:
			unit_vector = Vector2.LEFT
		velocity = velocity.move_toward(unit_vector*MAX_ROLLING_SPEED, SPIN_DASH_ACCEL*delta)		
		spin_dash = false
	if damage_taken and not invicibility_after_damage and not dead:
		take_damage()
	if dead:
		die()			
	if rebound:
		kill_rebound()
	velocity = move_and_slide(velocity, Vector2.UP)			
	
	for i in get_slide_count():	
		var collision = get_slide_collision(i)
		if collision.collider.is_in_group('environment_hurt_player') and not hit_environment_danger:
			damage_taken = true
			hit_environment_danger = false
			
func accelerate():
	if is_on_floor():
			state_machine.travel("walk")
	if velocity.x > 450 or velocity.x < -450:
		if is_on_floor():
			state_machine.travel("run")	
				
			
func deaccelerate():
	if int(round(velocity.x)) == 0 and is_on_floor() and not charging_spin_attack:
			if not animation_timer_started:
					animation_timer.start()
					animation_timer_started = true
					state_machine.travel('idle')
	elif (velocity.x < 500 or velocity.x > -500) and is_on_floor() and not charging_spin_attack:
			state_machine.travel("walk")	
	if velocity.x < 0 and velocity.x > -1 || velocity.x > 0 and velocity.x < 1:
			velocity.x = 0	
			
func jump():
	state_machine.travel('jump')
	animation_timer_started = false
	animation_timer.stop()
	on_air = false		
	
func skid():
	if is_on_floor():
		state_machine.travel('abrupt_direction_change')
	if abrupt_change_to_left:
		if velocity.x <= 0 or Input.is_key_pressed(KEY_RIGHT):	
			abrupt_change = false
			abrupt_change_to_left = false
	elif abrupt_change_to_right:
		if velocity.x >= 0 or Input.is_key_pressed(KEY_LEFT):
			abrupt_change = false		
			abrupt_change_to_right = false
				
func roll():
	if is_on_floor():
		state_machine.travel("spin_attack")
	if int(round(velocity.x)) == 0:
		velocity.x == 0
		rolling = false	
		
func take_damage():
	if ring_count > 0:
		animation_timer_started = false
		animation_timer.stop()
		change_and_play_audio(rings_lost_audio)
		state_machine.travel("hurt")
		invicibility_after_damage = true
		damage_taken = false
		velocity.y = velocity.y - DAMAGE_KNOCKBACK
		velocity.x = velocity.x - get_knockback()
		ring_angle = 184
		emit_signal("drop_rings", ring_count)
		ring_count = 0
		_update_ring_count()
	else:
		dead = true
		final_position = global_position
		velocity.y -= 500
		
func die():
	ring_label.visible = false
	lock_camera = true
	state_machine.travel('dead')
	player_collision.disabled = true
	hurtbox_collision.disabled = true
	hitbox_collision.disabled = true
	ring_collision.disabled  = true
	followbox_collision.disabled = true
	if not end:
		change_and_play_audio(dead_audio)
		emit_signal("player_dead", final_position)
		end = true	
func kill_rebound():
	if not is_on_floor() and velocity.y >= 0 and enemy_killed.global_position.y > global_position.y:
		velocity.y*=-1
	rebound = false
				
					
func change_and_play_audio(audio):
	audio_player.stream = audio
	audio_player.play()			
			
func get_knockback():	
	var knockback		
	if velocity.x > 0:
		knockback = DAMAGE_KNOCKBACK
	else:
		knockback = -DAMAGE_KNOCKBACK
	return knockback		
			
func _on_Hurtbox_area_entered(area):
	damage_taken = true
	
func _on_RingCollection_area_entered(area):
	ring_count+=1
	_update_ring_count()

func _on_Hitbox_area_entered(area):
	enemy_killed = area.get_owner()
	rebound = true

func _update_ring_count():	
	ring_label.text = str("Rings: " + str(ring_count))
	
func _on_WaitTimerAnimation_timeout():
	animation_timer.stop()
	state_machine.travel("wait")
	
