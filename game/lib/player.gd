extends CharacterBody3D

@onready var camera:Camera3D = $Camera
@onready var anim:AnimationPlayer = $AnimationPlayer

signal interaction_detected(node:Node3D)
signal interaction_detected_end(node:Node3D)
signal hit(node:Node3D)

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const ANIM_WALK = "player/walking"
const ANIM_IDLE = "player/standing_idle"
const ANIM_ATTACK= "player/sword_slash"

const mouse_sensitivity:float = 0.002
const max_camera_angle_up:float = deg_to_rad(60)
const max_camera_angle_down:float = -deg_to_rad(75)
var mouse_captured:bool = false
var hit_area:Area3D
var attacking:bool = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	capture_mouse()
	anim.play(ANIM_IDLE)
	hit_area = $Character.get_node("RootNode/Skeleton3D/HandAttachement/sword/HitArea")
	hit_area.connect("body_entered", _on_hit_area_body_entered)

func _input(event):
	if event is InputEventMouseMotion and mouse_captured:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(event.relative.y * mouse_sensitivity)
		camera.rotation.x = clampf(camera.rotation.x, max_camera_angle_down, max_camera_angle_up)
	if (event is InputEventKey) and Input.is_action_just_pressed("cancel"):
		release_mouse()

func _physics_process(delta):
	if not attacking and Input.is_action_just_released("attack"):
		anim.play(ANIM_ATTACK)
		attacking = true
	if (attacking):
		return
		
	if mouse_captured:
		var joypad_dir: Vector2 = Input.get_vector("player_look_left", "player_look_right", "player_look_up", "player_look_down")
		if joypad_dir.length() > 0:
			var look_dir = joypad_dir * delta
			rotate_y(-look_dir.x * 2.0)
			camera.rotate_x(-look_dir.y)
			camera.rotation.x = clamp(camera.rotation.x - look_dir.y,  max_camera_angle_down, max_camera_angle_up)

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("player_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("player_left", "player_right", "player_forward", "player_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		if (!mouse_captured): capture_mouse()
		anim.play(ANIM_WALK)
		for index in range(get_slide_collision_count()):
			var collision = get_slide_collision(index)
			var collider = collision.get_collider()
			if (collider != null) and collider.is_in_group("stairs"):
				velocity.y = 1.5
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		anim.play(ANIM_IDLE)

	move_and_slide()

func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func _on_area_3d_body_entered(body):
	interaction_detected.emit(body)

func _on_area_3d_body_exited(body):
	interaction_detected_end.emit(body)
	
func _on_hit_area_body_entered(body):
	if (attacking):
		hit.emit(body)

func _on_animation_player_animation_finished(anim_name):
	if (anim_name == ANIM_ATTACK):
		attacking = false
		anim.play(ANIM_IDLE)
