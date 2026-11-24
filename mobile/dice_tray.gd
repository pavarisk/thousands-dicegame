extends SubViewportContainer

signal finished(faces: Array)
signal die_tapped(index: int)

const DIE_SIZE := 0.89
const REVEAL_DELAY := 2.25
const SETTLE_START := 1.55
const SETTLE_LIMIT := 5.0
const FACE_NORMALS := [Vector3.UP, Vector3.RIGHT, Vector3.BACK, Vector3.FORWARD, Vector3.LEFT, Vector3.DOWN]
const PIP_LAYOUTS := [
	[Vector2.ZERO],
	[Vector2(-1, -1), Vector2(1, 1)],
	[Vector2(-1, -1), Vector2.ZERO, Vector2(1, 1)],
	[Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)],
	[Vector2(-1, -1), Vector2(1, -1), Vector2.ZERO, Vector2(-1, 1), Vector2(1, 1)],
	[Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(1, 0), Vector2(-1, 1), Vector2(1, 1)]
]

var viewport: SubViewport
var camera: Camera3D
var can_select := false
var selected_surface: StandardMaterial3D
var world: Node3D
var dice: Array[RigidBody3D] = []
var elapsed := 0.0
var stable_time := 0.0
var pip_mesh := CylinderMesh.new()
var dice_mesh: ArrayMesh

func build_tray() -> void:
	custom_minimum_size = Vector2.ZERO
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_2X
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(viewport)
	world = Node3D.new()
	viewport.add_child(world)

	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("#142c23")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("#fff4de")
	environment.environment.ambient_light_energy = 0.58
	world.add_child(environment)

	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 6.9
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	world.add_child(camera)
	camera.position = Vector3(0, 10, 4.0)
	camera.look_at(Vector3(0, 0.55, 0))

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-63, -30, 0)
	light.light_energy = 1.05
	light.shadow_enabled = true
	world.add_child(light)

	var felt := material(Color("#285943"), 0.96)
	var wood := material(Color("#644430"), 0.68)
	make_wall(Vector3(0, -0.16, 0), Vector3(6.25, 0.32, 3.6), felt)
	for side in [-1, 1]:
		make_wall(Vector3(side * 3.02, 0.49, 0), Vector3(0.22, 1.0, 3.6), wood)
		make_wall(Vector3(0, 0.49, side * 1.70), Vector3(6.25, 1.0, 0.20), wood)
		# Invisible upper rails keep energetic bounces inside the tray.
		make_wall(Vector3(side * 3.02, 2.3, 0), Vector3(0.22, 2.65, 3.6))
		make_wall(Vector3(0, 2.3, side * 1.70), Vector3(6.25, 2.65, 0.20))

	dice_mesh = rounded_cube()
	pip_mesh.top_radius = 0.077
	pip_mesh.bottom_radius = 0.077
	pip_mesh.height = 0.012
	pip_mesh.radial_segments = 16
	pip_mesh.material = material(Color("#252821"), 0.62)
	selected_surface = material(Color("#f3c979"), 0.40)

func clear_dice() -> void:
	can_select = false
	set_physics_process(false)
	for die in dice:
		die.hide()
		die.queue_free()
	dice.clear()

func launch(count: int) -> void:
	clear_dice()
	elapsed = 0.0
	stable_time = 0.0
	set_physics_process(true)
	for index in range(count):
		make_die(index)

func show_saved_faces(faces: Array) -> void:
	build_tray()
	for index in range(faces.size()):
		var die := make_die(index, true)
		var normal: Vector3 = FACE_NORMALS[faces[index] - 1]
		die.basis = Basis(Quaternion(normal, Vector3.UP))
		if normal == Vector3.DOWN:
			die.basis = Basis(Vector3.RIGHT, PI)
	set_physics_process(false)

func rounded_cube() -> ArrayMesh:
	var source := BoxMesh.new()
	source.size = Vector3.ONE * DIE_SIZE
	source.subdivide_width = 15
	source.subdivide_height = 15
	source.subdivide_depth = 15
	var arrays := source.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var radius := 0.088
	var inner := Vector3.ONE * (DIE_SIZE * 0.5 - radius)
	for index in range(vertices.size()):
		var vertex := vertices[index]
		var center := vertex.clamp(-inner, inner)
		normals[index] = (vertex - center).normalized()
		vertices[index] = center + normals[index] * radius
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, material(Color("#f1e4c8"), 0.43))
	return mesh

func material(color: Color, roughness: float) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	return result

func make_wall(at: Vector3, dimensions: Vector3, surface: Material = null) -> void:
	var body := StaticBody3D.new()
	body.position = at
	world.add_child(body)
	add_box_collision(body, dimensions)
	if surface:
		var mesh := BoxMesh.new()
		mesh.size = dimensions
		mesh.material = surface
		add_mesh(body, mesh)

func add_box_collision(body: PhysicsBody3D, dimensions: Vector3) -> void:
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = dimensions
	collision.shape = box
	body.add_child(collision)

func add_mesh(parent: Node3D, mesh: Mesh) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	parent.add_child(visual)
	return visual

func make_die(index: int, resting := false) -> RigidBody3D:
	var die := RigidBody3D.new()
	die.position = Vector3(-1.65 + (index % 3) * 1.6, 1.9 + randf_range(0, 0.32), -0.83 if index < 3 else 0.83)
	# A uniform random orientation avoids favoring a particular starting face.
	var heading := randf_range(0, TAU)
	var tilt := acos(randf_range(-1, 1))
	var twist := randf_range(0, TAU)
	die.basis = Basis(Vector3.UP, heading) * Basis(Vector3.RIGHT, tilt) * Basis(Vector3.UP, twist)
	if resting:
		die.position.y = DIE_SIZE * 0.5
		die.freeze = true
	die.mass = 0.12
	die.linear_damp = 0.42
	die.angular_damp = 0.55
	die.continuous_cd = true
	die.physics_material_override = PhysicsMaterial.new()
	die.physics_material_override.bounce = 0.34
	die.physics_material_override.friction = 0.73
	world.add_child(die)
	add_box_collision(die, Vector3.ONE * DIE_SIZE)
	var shell := add_mesh(die, dice_mesh)
	shell.name = "Shell"
	for index_face in range(6):
		var normal: Vector3 = FACE_NORMALS[index_face]
		var tangent := Vector3.RIGHT if absf(normal.x) < 0.5 else Vector3.FORWARD
		var bitangent := normal.cross(tangent)
		for offset in PIP_LAYOUTS[index_face]:
			var pip := add_mesh(die, pip_mesh)
			pip.basis = Basis(tangent, normal, tangent.cross(normal))
			pip.position = normal * (DIE_SIZE / 2.0 + 0.003) + (tangent * offset.x + bitangent * offset.y) * 0.23
	if not resting:
		die.linear_velocity = Vector3(randf_range(-1.8, 1.8), randf_range(0.0, 0.65), randf_range(-1.15, 1.15))
		die.angular_velocity = Vector3(randf_range(-13, 13), randf_range(-13, 13), randf_range(-13, 13))
	dice.append(die)
	return die

func set_die_selected(index: int, selected: bool) -> void:
	var shell := dice[index].get_node("Shell") as MeshInstance3D
	shell.material_override = selected_surface if selected else null

func _gui_input(event: InputEvent) -> void:
	if not can_select or not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	var index := die_at(event.position)
	if index >= 0:
		die_tapped.emit(index)
		accept_event()

func die_at(pixel: Vector2) -> int:
	var origin := camera.project_ray_origin(pixel)
	var end := origin + camera.project_ray_normal(pixel) * 30.0
	var bounds := AABB(-Vector3.ONE * DIE_SIZE / 2.0, Vector3.ONE * DIE_SIZE)
	var nearest := INF
	var picked := -1
	for index in range(dice.size()):
		var die := dice[index]
		var hit: Variant = bounds.intersects_segment(die.to_local(origin), die.to_local(end))
		if hit is Vector3:
			var distance := origin.distance_squared_to(die.to_global(hit))
			if distance < nearest:
				nearest = distance
				picked = index
	return picked

func _physics_process(delta: float) -> void:
	if dice.is_empty():
		return
	elapsed += delta
	if elapsed >= SETTLE_START and elapsed - delta < SETTLE_START:
		for die in dice:
			die.linear_damp = 2.5
			die.angular_damp = 3.5
	var settled := true
	var faces: Array = []
	for die in dice:
		var highest := -1.0
		var face := 0
		for index in range(6):
			var height: float = (die.basis * FACE_NORMALS[index]).dot(Vector3.UP)
			if height > highest:
				highest = height
				face = index + 1
		faces.append(face)
		if not die.sleeping and (die.linear_velocity.length() > 0.07 or die.angular_velocity.length() > 0.12):
			settled = false
		if highest < 0.94 and die.sleeping:
			settled = false
			die.apply_impulse(Vector3(randf_range(-0.09, 0.09), 0.20, randf_range(-0.09, 0.09)), Vector3(0.18, 0, 0.17))
	stable_time = stable_time + delta if settled else 0.0
	if elapsed < REVEAL_DELAY or (stable_time < 0.20 and elapsed < SETTLE_LIMIT):
		return
	for die in dice:
		die.freeze = true
	set_physics_process(false)
	finished.emit(faces)
