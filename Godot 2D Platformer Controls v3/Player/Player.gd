extends KinematicBody2D

var motion=Vector2(0,0)
const UP=Vector2(0,-1)
const SPEED=600
const GRAVITY=51
const JUMP_SPEED=1200
const JUMP_SUBLIMIT = 400
const WORLD_LIMIT=3000
var jump_count=0
var wall_slide_speed=0
var wall_slide_max=500
var is_working = true
var earlyjump = false 
var can_jump = false
var can_wall_jump = false

var left = "left"
var right = "right"
var jump = "jump"
#I added controls as variables so you can change them with code


func _physics_process(delta):
	apply_gravity()
	move_and_slide(motion,UP)
	up_collision()
	side_collision()
	movement(left,right)
	jumping(jump,left,right)
	jump_breaker(jump)
	early_jump(jump,left,right)
	coyote_jump()
	animate(left,right)


func up_collision():
	if is_on_ceiling():
		motion.y=1
		#if player bumps its head to ceiling, it will start to fall
func side_collision():
	#this function makes player stick to wall, also it stops player running animations when it hits a wall
	if $AnimatedSprite.animation=="wallslide":
		if is_on_wall():
			if $AnimatedSprite.flip_h:
				motion.x = 1
			elif not $AnimatedSprite.flip_h:
				motion.x = -1
			can_wall_jump = true
			yield(get_tree().create_timer(0.1),"timeout")
			can_wall_jump = false
	else:
		if is_on_wall():
			motion.x=0
func apply_gravity():
	if is_on_floor() and motion.y > 0:
		jump_count=1
		motion.y=1
		#I changed this from 0 to 1 to make sure jump code detects that we are touching the floor
	elif is_on_wall() and motion.y > 0:
		if wall_slide_speed < wall_slide_max:
			motion.y += 20
			wall_slide_speed=motion.y
		else:
			wall_slide_speed=wall_slide_max
			motion.y += 20
	else:
		motion.y+=GRAVITY
		if motion.y > 0 and not is_on_wall():
			motion.y += GRAVITY/4
		if position.y > 1000:
			#resets the player position if player falls down from world
			position = Vector2(90,0)
			motion = Vector2(0,1000)
func movement(left,right):
	if Input.is_action_pressed(left) and not Input.is_action_pressed(right):
		left()
	elif Input.is_action_pressed(right) and not Input.is_action_pressed(left):
		right()
	#this part makes player slide rather than stop instantly
	elif motion.x>0 and is_on_floor():
		motion.x = clamp(motion.x - 50, 0, SPEED)
	elif motion.x<0 and is_on_floor():
		motion.x = clamp(motion.x + 50, -SPEED, 0)
		
func left():
	if motion.x <= -SPEED:
		motion.x = -SPEED
	else:
		if is_on_wall() and $AnimatedSprite.animation == "wallslide":
			if motion.x == 1:
				yield(get_tree().create_timer(0.1),"timeout")
				motion.x -= 50
		else:
			motion.x-=50
		
func right():
	if motion.x >= SPEED:
		motion.x = SPEED
	else:
		if is_on_wall() and $AnimatedSprite.animation == "wallslide":
			if motion.x == -1:
				yield(get_tree().create_timer(0.1),"timeout")
				motion.x += 50
		else:
			motion.x+=50
func jumping(jump,left,right):
	if Input.is_action_just_pressed(jump) or earlyjump:
		#earlyjump variable here is makes sure player jumps even if we press slightly early
			if is_on_floor() or can_jump:
				$AnimatedSprite.play("jump")
				motion.y = -JUMP_SPEED
				jump_count-=1
				#this is normal jump, player can jump depends on how many jumps it left
				#default jump count is 1 but you can make it double jump by adjusting jump_count in apply_gravity function
			elif $AnimatedSprite.animation == "wallslide" and can_wall_jump:
				if not is_on_floor():
					if $AnimatedSprite.flip_h:
						motion.y = -JUMP_SPEED*(0.8)
						motion.x = -SPEED
					else:
						motion.y = -JUMP_SPEED*(0.8)
						motion.x = SPEED
					#this part makes player jump from walls to right direction
				
func jump_breaker(jump):
	#this code adjusts the jump height by how much we hold jump key
	if motion.y < -JUMP_SUBLIMIT and Input.is_action_just_released(jump):
		motion.y = -JUMP_SUBLIMIT
				
func early_jump(jump,left,right):
	#this is an important code for gamefeel
	#this code changes earlyjump variable if we are not touching ground but stil trying to jump
	if jump_count == 0 and Input.is_action_just_pressed(jump):
		if not is_on_floor():
			if not is_on_wall():
				#if player is in air and jump button is pressed while it has no jumps left. Earlyjump activates
				earlyjump = true
				yield(get_tree().create_timer(0.1),"timeout")
				#you can change 0.1 wait time value to adjust time window between how early we press the jump button and players feet touch to ground
				earlyjump = false
func coyote_jump():
	if is_on_floor():
		can_jump = true
		#I didn't use yield to create timer because I don't want code to create a new timer every frame when we are not touching ground
		#You can change wait time on CoyoteTimer node to adjust the time you can coyote jump
		$CoyoteTimer.start()

func _on_CoyoteTimer_timeout():
	can_jump = false

func animate(left,right):
	#animation codes are important because I use some of them to determine how player will act when we press a button
	#some jump animations are in jump function
	if is_working:
		if motion.y < -51 and not is_on_wall():
			if is_on_floor():
				$AnimatedSprite.play("jump")
		elif motion.x != 0 and not is_on_wall():
			$AnimatedSprite.get_sprite_frames().set_animation_speed("walk", 24)
			if motion.x < 0 and is_on_floor():
				if Input.is_action_pressed(left):
					$AnimatedSprite.flip_h=true
					$AnimatedSprite.play("walk")
				else:
					$AnimatedSprite.play("default")
			elif motion.x > 0 and is_on_floor():
				if Input.is_action_pressed(right):
					$AnimatedSprite.flip_h=false
					$AnimatedSprite.play("walk")
				else:
					$AnimatedSprite.play("default")
		elif motion.y == 0 and is_on_wall():
			if motion.x < 0:
				$AnimatedSprite.flip_h=true
				$AnimatedSprite.play("default")
			elif motion.x > 0:
				$AnimatedSprite.flip_h=false
				$AnimatedSprite.play("default")
		elif motion.y != 0  and is_on_wall():
			if motion.y > 51 or motion.y < -51:
				if motion.x < 0:
					$AnimatedSprite.play("wallslide")
					$AnimatedSprite.flip_h=false
				elif motion.x > 0:
					$AnimatedSprite.play("wallslide")
					$AnimatedSprite.flip_h=true
		elif motion.x == 0 and not is_on_wall():
			if Input.is_action_pressed(right):
				pass
			elif Input.is_action_pressed(left):
				pass
			elif is_on_floor():
				$AnimatedSprite.play("default")
		if not Input.is_action_pressed(left) and motion.x < 0:
			$AnimatedSprite.get_sprite_frames().set_animation_speed("walk", 10)
			if Input.is_action_pressed(right) and is_on_floor():
				$AnimatedSprite.flip_h=true
				$AnimatedSprite.play("slide")
		if not Input.is_action_pressed(right) and motion.x > 0:
			$AnimatedSprite.get_sprite_frames().set_animation_speed("walk", 10)
			if Input.is_action_pressed(left) and is_on_floor():
				$AnimatedSprite.flip_h=false
				$AnimatedSprite.play("slide")
