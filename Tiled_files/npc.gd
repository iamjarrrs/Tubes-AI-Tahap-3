extends CharacterBody2D

const SPEED = 45.0
var player: Node2D = null
var astar_grid := AStarGrid2D.new()
@export var tile_size := 16 
var current_path: PackedVector2Array = []
var path_index := 0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_tree().current_scene.find_child("Player", true, false)

	setup_astar()

func setup_astar():
	astar_grid.region = Rect2i(-200, -200, 400, 400)
	astar_grid.cell_size = Vector2(tile_size, tile_size)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	
	# Memindai node Walls agar dihindari oleh algoritma A*
	var dungeon_map = get_parent()
	if dungeon_map:
		var walls_node = dungeon_map.find_child("Walls", true, false)
		if walls_node:
			var cells = []
			# Mendukung TileMapLayer maupun TileMap konvensional di Godot 4
			if walls_node.has_method("get_used_cells"):
				if walls_node is TileMapLayer:
					cells = walls_node.get_used_cells()
				elif walls_node is TileMap:
					for i in walls_node.get_layers_count():
						cells.append_array(walls_node.get_used_cells(i))
			
			for cell in cells:
				astar_grid.set_point_solid(cell, true)

func _physics_process(_delta):
	if not player:
		return

	var start_id = Vector2i(round(global_position / tile_size))
	var target_id = Vector2i(round(player.global_position / tile_size))
	
	current_path = astar_grid.get_point_path(start_id, target_id)
	queue_redraw()

	var direction = Vector2.ZERO

	if current_path.size() > 0:
		if path_index >= current_path.size():
			path_index = current_path.size() - 1
		
		var target_point = current_path[path_index]
		
		# Pindah ke titik checkpoint berikutnya jika sudah mendekati titik saat ini
		if global_position.distance_to(target_point) < 4.0 and path_index < current_path.size() - 1:
			path_index += 1
			target_point = current_path[path_index]
			
		direction = global_position.direction_to(target_point)
	else:
		direction = global_position.direction_to(player.global_position)
		path_index = 0

	velocity = direction * SPEED
	
	if direction != Vector2.ZERO:
		update_npc_animation(direction)
	else:
		anim.stop()

	move_and_slide()

func update_npc_animation(direction: Vector2):
	if abs(direction.y) >= abs(direction.x):
		anim.flip_h = false
		if direction.y > 0:
			if anim.sprite_frames.has_animation("walk_down"):
				anim.play("walk_down")
			else:
				anim.play("default")
		else:
			if anim.sprite_frames.has_animation("walk_up"):
				anim.play("walk_up")
			else:
				anim.play("default")
	else:
		if anim.sprite_frames.has_animation("walk_side"):
			anim.play("walk_side")
		else:
			anim.play("default")
		anim.flip_h = direction.x > 0

# Debug Overlay Grid A*
func _draw():
	for point in current_path:
		var local_point = point - global_position
		var rect = Rect2(local_point - Vector2(tile_size / 2.0, tile_size / 2.0), Vector2(tile_size, tile_size))
		
		draw_rect(rect, Color(0, 0.8, 1, 0.3), true)
		draw_rect(rect, Color(0, 0.4, 1, 0.8), false)
