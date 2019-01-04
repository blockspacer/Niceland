extends KinematicBody

export(bool) var invert_mouse = true

var max_speed = 30.0
var acceleration = 60.0
var decceleration = 5.0
var mouse_speed = 0.003
var mouse_smooth = 0.1
var jump_force = 30.0

var gravity = Vector3(0, -30, 0)
var mv = Vector3(0,0,0)

var rotator_x = Spatial.new()
var rotator_y = Spatial.new()

var noise = preload("res://Scripts/HeightGenerator.gd").new()

func _ready():
	noise.init()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	

func _process(delta):
	
	var spd = max_speed
	var acc = acceleration
	var dec = decceleration
	
	# Teleport to random location
	if(Input.is_action_just_pressed("teleport")):
		var rv = Vector3(0,0,0)
		rv.x = randf() * 10000.0
		rv.z = randf() * 10000.0
		transform.origin += rv
	
	# Flying mode
	if(Input.is_key_pressed(KEY_SHIFT)):
		acc *= 2.0
		spd *= 10.0
		dec *= 0.2
	
	# WASD
	if(Input.is_action_pressed("move_forward")):
		mv -= transform.basis.z * acc * delta
		dec = 0.0
	if(Input.is_action_pressed("move_backward")):
		mv += transform.basis.z * acc * delta
		dec = 0.0
	if(Input.is_action_pressed("move_left")):
		mv -= transform.basis.x * acc * delta
		dec = 0.0
	if(Input.is_action_pressed("move_right")):
		mv += transform.basis.x * acc * delta
		dec = 0.0
	
	# Wheel
	if(Input.is_key_pressed(KEY_SHIFT)):
		mv.y = lerp(mv.y, 0.0, decceleration * delta / 5.0)
		if(Input.is_action_just_released("ui_scroll_up")):
			mv += transform.basis.y * acc * delta * 5.0
		if(Input.is_action_just_released("ui_scroll_down")):
			mv -= transform.basis.y * acc * delta * 5.0
	
	# Jump
	if(Input.is_action_just_pressed("jump")):
		mv.y = jump_force
	
	# Decceleration
	mv = mv.linear_interpolate(Vector3(0, mv.y, 0), dec * delta)
	
	# Apply gravity
	if(Input.is_key_pressed(KEY_SHIFT) == false):
		mv += gravity * delta
	
	# Max speed
	if(Input.is_key_pressed(KEY_SHIFT) == false):
		var mvy = mv.y
		mv.y = 0.0
		if(mv.length() > max_speed):
			mv = mv.normalized() * max_speed
		mv.y = mvy
	
	# Apply movement
	mv = move_and_slide(mv, Vector3(0,1,0), 0.05, 4, deg2rad(40.0))
	
	# Keep above ground no matter what
	var h =  noise.get_h(transform.origin)
	if(transform.origin.y < h + 1.5):
		transform.origin.y = h + 1.5
	
	# Smooth apply rotation
	rotator_x.transform.origin = $Camera.transform.origin
	rotator_y.transform.origin = transform.origin
	if(Input.is_key_pressed(KEY_SHIFT) == false):
		transform = transform.interpolate_with(rotator_y.transform, clamp(delta / mouse_smooth, 0.0, 1.0))
		$Camera.transform = $Camera.transform.interpolate_with(rotator_x.transform, clamp(delta / mouse_smooth, 0.0, 1.0))
	else:
		transform = transform.interpolate_with(rotator_y.transform, clamp(delta / mouse_smooth, 0.0, 1.0) / 10.0)
		$Camera.transform = $Camera.transform.interpolate_with(rotator_x.transform, clamp(delta / mouse_smooth, 0.0, 1.0) / 10.0)
	


func _input(event):
	
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_Y:
			invert_mouse = !invert_mouse
	
	# Mouselook
	if (event is InputEventMouseMotion):
		var mm = event.relative
#		mm *= mm.length() / 3.0
		mm *= mouse_speed
		rotator_y.rotate_y(-mm.x)
		
		if(invert_mouse):
			rotator_x.rotate_x(mm.y)
		else:
			rotator_x.rotate_x(-mm.y)
