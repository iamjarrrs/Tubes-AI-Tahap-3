extends CharacterBody2D

const WALK_SPEED = 120.0
const RUN_SPEED = 200.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta):
	# Mengecek tombol Shift untuk lari
	var is_running = Input.is_action_pressed("ui_shift") or Input.is_key_pressed(KEY_SHIFT)
	var current_speed = RUN_SPEED if is_running else WALK_SPEED

	# Membaca input arah (WASD / Panah)
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * current_speed
	
	update_animation(direction, is_running)
	
	move_and_slide()

func _ready():
	add_to_group("player")

func update_animation(direction: Vector2, is_running: bool):
	if direction == Vector2.ZERO:
		anim.stop()
		return

	var suffix = "_run" if is_running else ""

	# Cek ketersediaan animasi melalui sprite_frames di Godot 4
	if abs(direction.x) > abs(direction.y):
		if anim.sprite_frames.has_animation("walk_side" + suffix):
			anim.play("walk_side" + suffix)
		elif anim.sprite_frames.has_animation("walk_side"):
			anim.play("walk_side")
		else:
			anim.play("default")
			
		# Diubah menjadi arah sebaliknya agar tidak terbalik
		anim.flip_h = direction.x > 0
	else:
		anim.flip_h = false
		if direction.y > 0:
			if anim.sprite_frames.has_animation("walk_down" + suffix):
				anim.play("walk_down" + suffix)
			elif anim.sprite_frames.has_animation("walk_down"):
				anim.play("walk_down")
			else:
				anim.play("default")
		else:
			if anim.sprite_frames.has_animation("walk_up" + suffix):
				anim.play("walk_up" + suffix)
			elif anim.sprite_frames.has_animation("walk_up"):
				anim.play("walk_up")
			else:
				anim.play("default")
