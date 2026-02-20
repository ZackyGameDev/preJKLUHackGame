extends CharacterBody2D
@onready var speech_bubble = $SpeechBubble
@onready var speech_panel = $SpeechBubble/Panel
@onready var speech_label = $SpeechBubble/Panel/Label
enum { IDLE, WAITING, MOVING, TALKING }
var state = IDLE
var roam_radius_x := 320.0
var roam_radius_y := 180.0
var home_position: Vector2
var wander_target: Vector2
var focus_target: Node2D = null
var pending_line := ""
var last_dist := INF
var stuck_time := 0.0
var talk_distance := 40.0
var speed := 60.0
var think_timer := 0.0
var wait_timer := 0.0
var facing := 1            # 1 = right, -1 = left
var turning := false
var base_scale: Vector2
var bob_time := 0.0

@onready var sprite = $Sprite2D
@onready var ray_f = $Ray_F
@onready var ray_l = $Ray_L
@onready var ray_r = $Ray_R
@export var perspective_strength := 0.0025    # tweak this in inspector
@export var min_scale_multiplier := 0.75
@export var max_scale_multiplier := 1.35

var base_visual_scale: Vector2
var base_y: float

func _ready():
	z_as_relative = false
	randomize()
	home_position = global_position
	base_scale = sprite.scale
	choose_new_wander()
	speech_panel.visible = false
	speech_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	speech_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speech_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	speech_panel.offset_left = 0
	speech_panel.offset_top = 0
	speech_panel.offset_right = 0
	speech_panel.offset_bottom = 0
	speech_bubble.z_as_relative = false
	speech_bubble.z_index = 100
	base_visual_scale = sprite.scale
	base_y = global_position.y
func apply_perspective_scale():

	var y_offset = global_position.y - base_y

	var factor = 1.0 + (y_offset * perspective_strength)
	factor = clamp(factor, min_scale_multiplier, max_scale_multiplier)

	sprite.scale.y = base_visual_scale.y * factor
	sprite.scale.x = abs(base_visual_scale.x * factor) * facing
func show_speech(text: String, duration: float):

	speech_label.text = text
	speech_panel.visible = true

	await get_tree().process_frame

	var max_width := 180.0
	speech_label.size.x = max_width

	# measure wrapped text using font
	var font: Font = speech_label.get_theme_font("font")
	var font_size: int = speech_label.get_theme_font_size("font_size")

	var text_size: Vector2 = font.get_multiline_string_size(
		text,
		HORIZONTAL_ALIGNMENT_CENTER,
		max_width,
		font_size
	)

	var padding := Vector2(24, 18)

	speech_panel.size = text_size + padding

	# label fills panel
	speech_label.position = Vector2(padding.x/2, padding.y/2)
	speech_label.size = text_size

	await get_tree().create_timer(duration).timeout
	
	speech_panel.visible = false
	
func _physics_process(delta):

	z_index = int(global_position.y/10)
	match state:
		IDLE:
			idle_wander(delta)

		WAITING:
			wait_timer -= delta
			velocity = Vector2.ZERO
			if wait_timer <= 0:
				get_node("SpeechBubble/!").visible = false
				state = MOVING

		MOVING:
			move_to_focus(delta)

		TALKING:
			velocity = Vector2.ZERO

	apply_bob(delta)
	move_and_slide()
	apply_perspective_scale()


# ================= IDLE =================
func update_facing(move_vec: Vector2):

	# ignore tiny horizontal noise
	if abs(move_vec.x) < 0.25:
		return

	var new_facing = 1 if move_vec.x > 0 else -1

	if new_facing == facing or turning:
		return

	turning = true
	facing = new_facing

	var t = create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_IN_OUT)

	# squash
	t.tween_property(sprite, "scale:x", 0.05 * sign(base_scale.x), 0.09)

	# flip exactly when flat
	t.tween_callback(func():
		sprite.scale.x = abs(base_scale.x) * facing
	)

	# expand back
	t.tween_property(sprite, "scale:x", base_scale.x * facing, 0.09)

	t.finished.connect(func(): turning = false)
	
func idle_wander(delta):

	think_timer -= delta
	if think_timer <= 0:
		choose_new_wander()
		think_timer = randf_range(2.0, 5.5)

	move_towards(wander_target)

	if global_position.distance_to(wander_target) < 10:
		velocity = Vector2.ZERO



func choose_new_wander():

	var tries := 0

	while tries < 10:

		var offset = Vector2(
			randf_range(-roam_radius_x, roam_radius_x),
			randf_range(-roam_radius_y, roam_radius_y)
		)

		var candidate = home_position + offset

		# avoid choosing targets inside walls
		if not test_move(transform, candidate - global_position):
			wander_target = candidate
			return

		tries += 1

	wander_target = home_position



# ================= PLAYER INTERACTION =================

	
func look_at_object(target: Node2D, line: String):
	focus_target = target
	pending_line = line
	update_facing((target.global_position - global_position).normalized())
	state = WAITING
	get_node("SpeechBubble/!").visible = true
	wait_timer = 2
	last_dist = INF
	stuck_time = 0.0


# ================= MOVE TO OBJECT =================

func move_to_focus(delta):

	if focus_target == null:
		state = IDLE
		return

	var dist = global_position.distance_to(focus_target.global_position)

	move_towards(focus_target.global_position)

	# reached normally
	if dist < talk_distance:
		start_dialogue()
		return

	# detect stuck (distance not improving)
	if dist >= last_dist - 0.5:
		stuck_time += delta
	else:
		stuck_time = 0.0

	last_dist = dist

	# if stuck for a bit, give up and talk
	if stuck_time > 0.7:
		start_dialogue()



# ================= DIALOGUE =================

func start_dialogue():

	state = TALKING
	velocity = Vector2.ZERO
	
	var line_to_say = Network.pop_message()
	#await show_speech(pending_line, 2.5)
	await show_speech(line_to_say, 2.5)

	state = IDLE
	focus_target = null
	pending_line = ""

# ================= MOVEMENT =================

func move_towards(target_pos: Vector2):

	var desired = target_pos - global_position

	if desired.length() < 4:
		velocity = Vector2.ZERO
		return

	var dir = desired.normalized()

	update_facing(dir)

	var steer_vec = avoid_obstacles(dir)
	velocity = steer_vec * speed



# ================= COLLISION STEERING =================

func avoid_obstacles(dir: Vector2) -> Vector2:

	var angle = dir.angle()

	ray_f.target_position = Vector2.RIGHT.rotated(angle) * 28
	ray_l.target_position = Vector2.RIGHT.rotated(angle + 0.6) * 26
	ray_r.target_position = Vector2.RIGHT.rotated(angle - 0.6) * 26

	ray_f.force_raycast_update()
	ray_l.force_raycast_update()
	ray_r.force_raycast_update()

	if ray_f.is_colliding():

		if not ray_l.is_colliding():
			return dir.rotated(0.7)

		if not ray_r.is_colliding():
			return dir.rotated(-0.7)

		return Vector2.ZERO

	return dir



# ================= BOB ONLY WHILE MOVING =================

func apply_bob(delta):

	if velocity.length() > 5 and state != TALKING:
		bob_time += delta * 8.0
		var bob = sin(bob_time) * 4.0
		sprite.position.y = bob
	else:
		bob_time = 0.0
		sprite.position.y = 0
