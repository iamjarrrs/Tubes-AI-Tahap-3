extends Node

const MAX_LOADOUT_WEIGHT := 65
const ELEMENTS: Array[String] = ["Fire", "Water", "Nature"]
const ITEM_CATALOG := {
	"weapon": [
		{"name": "Dagger", "atk": 5, "power": 5, "def": 0, "defense": 0, "weight": 10, "hp": 0, "element": "Neutral"},
		{"name": "Flame Sword", "atk": 15, "power": 15, "def": 0, "defense": 0, "weight": 30, "hp": 0, "element": "Fire"},
		{"name": "Aqua Wand", "atk": 12, "power": 12, "def": 0, "defense": 0, "weight": 20, "hp": 0, "element": "Water"},
		{"name": "Leaf Blade", "atk": 14, "power": 14, "def": 0, "defense": 0, "weight": 25, "hp": 0, "element": "Nature"}
	],
	"armor": [
		{"name": "Leather Vest", "atk": 0, "power": 0, "def": 5, "defense": 5, "weight": 15, "hp": 0, "element": "Neutral"},
		{"name": "Flame Mail", "atk": 0, "power": 0, "def": 12, "defense": 12, "weight": 35, "hp": 0, "element": "Fire"},
		{"name": "Ocean Shield", "atk": 0, "power": 0, "def": 10, "defense": 10, "weight": 25, "hp": 0, "element": "Water"},
		{"name": "Forest Cloak", "atk": 0, "power": 0, "def": 8, "defense": 8, "weight": 20, "hp": 0, "element": "Nature"}
	],
	"accessory": [
		{"name": "None", "atk": 0, "power": 0, "def": 0, "defense": 0, "weight": 0, "hp": 0, "element": "Neutral"},
		{"name": "Apothecary Charm", "atk": 2, "power": 2, "def": 3, "defense": 3, "weight": 15, "hp": 0, "element": "Neutral"},
		{"name": "Guardian Pendant", "atk": 0, "power": 0, "def": 0, "defense": 0, "weight": 20, "hp": 0, "damage_reduction": 10, "element": "Neutral"},
		{"name": "Berserker Amulet", "atk": 10, "power": 10, "def": -5, "defense": -5, "weight": 25, "hp": 0, "element": "Neutral"},
		{"name": "Elemental Gem", "atk": 5, "power": 5, "def": 5, "defense": 5, "weight": 20, "hp": 0, "element": "Neutral"}
	]
}

var selected_map: String = ""
var mc_base_stats: Dictionary = {"attack": 30, "defense": 0, "hp": 100}
var npc_base_stats: Dictionary = {"attack": 30, "defense": 0, "hp": 100}
var mc_loadout: Dictionary = {
	"element": "",
	"weapon": {},
	"armor": {},
	"accessory": {}
}
var npc_loadout: Dictionary = {
	"element": "",
	"weapon": {},
	"armor": {},
	"accessory": {}
}

func reset_draft() -> void:
	mc_loadout = {
		"element": "",
		"weapon": {},
		"armor": {},
		"accessory": {}
	}
	npc_loadout = {
		"element": "",
		"weapon": {},
		"armor": {},
		"accessory": {}
	}

func start_map_draft(map_name: String, scene_path: String) -> void:
	reset_draft()
	selected_map = map_name
	if not ResourceLoader.exists(scene_path):
		push_error("Selected map scene does not exist: " + scene_path)
		return

	var scene_changer := get_node_or_null("/root/SceneChanger")
	if scene_changer == null:
		push_error("SceneChanger Autoload is missing.")
		return

	var changed: bool = await scene_changer.call("change_scene_with_fade", scene_path)
	if not changed:
		push_error("Could not open selected map: " + scene_path)
		return
	await get_tree().process_frame

	var map_scene := get_tree().current_scene as Node2D
	if map_scene == null:
		push_error("No active map scene after scene transition.")
		return
	var player := map_scene.find_child("Player", true, false) as CharacterBody2D
	if player:
		player.set_physics_process(false)
	else:
		push_error("Selected map has no Player node; cannot start NPC pathfinding.")
		return
	var map_sprite := _get_map_background(map_scene)
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera:
		camera.zoom = Vector2.ONE
		if map_sprite:
			camera.global_position = map_sprite.global_position

	var npc := load("res://Tiled_files/npc.tscn").instantiate() as CharacterBody2D
	if npc == null:
		push_error("Could not instantiate NPC scene.")
		return
	npc.name = "BattleNPC"
	npc.scale = player.scale
	map_scene.add_child(npc)
	var debug_overlay := load("res://scripts/gameplay_debug_overlay.gd").new() as CanvasLayer
	debug_overlay.name = "GameplayDebugOverlay"
	map_scene.add_child(debug_overlay)
	npc.global_position = npc.call("find_spawn_position", player.global_position)
	player.set_physics_process(true)
	await get_tree().process_frame

	var elapsed := 0.0
	var approach_timeout := 60.0
	while elapsed < approach_timeout and npc.global_position.distance_to(player.global_position) > 32.0:
		await get_tree().create_timer(0.1).timeout
		elapsed += 0.1
	if npc.global_position.distance_to(player.global_position) > 32.0:
		push_error("NPC gagal mencapai player sebelum batas waktu; kartu draft tidak ditampilkan.")
		return
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	npc.set_physics_process(false)

	var element_ui := _instantiate_draft_ui("res://scenes/ui/ElementSelectionUI.tscn") as CanvasLayer
	if element_ui == null:
		return
	element_ui.layer = 200
	get_tree().root.add_child(element_ui)

func _get_map_background(map_scene: Node2D) -> Sprite2D:
	for child in map_scene.get_children():
		if child is Sprite2D and child.texture:
			return child as Sprite2D
	return null

func _get_npc_spawn_position(map_scene: Node2D, player: Node2D) -> Vector2:
	var map_sprite := _get_map_background(map_scene)
	if map_sprite:
		var map_size := Vector2(map_sprite.texture.get_size()) * map_sprite.global_scale
		var map_right := map_sprite.global_position.x + map_size.x * 0.5
		var map_top := map_sprite.global_position.y - map_size.y * 0.5
		var map_bottom := map_sprite.global_position.y + map_size.y * 0.5
		return Vector2(map_right - 64.0, clampf(player.global_position.y, map_top + 64.0, map_bottom - 64.0))
	return player.global_position + Vector2(640.0, 0.0)

func replace_draft_ui(current_ui: Node, scene_path: String) -> void:
	var next_ui := _instantiate_draft_ui(scene_path)
	if next_ui == null:
		return
	var map_scene := get_tree().current_scene
	if map_scene == null:
		push_error("Cannot show next draft UI because there is no active map scene.")
		next_ui.queue_free()
		return
	if next_ui is CanvasLayer:
		next_ui.layer = 110
	map_scene.add_child(next_ui)
	current_ui.queue_free()

func _instantiate_draft_ui(scene_path: String) -> Node:
	if not ResourceLoader.exists(scene_path):
		push_error("Draft UI scene does not exist: " + scene_path)
		return null
	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		push_error("Draft UI is not a PackedScene: " + scene_path)
		return null
	return packed_scene.instantiate()

func get_random_npc_element() -> String:
	return ELEMENTS.pick_random()

func get_item_catalog(category: String) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for item in ITEM_CATALOG.get(category, []):
		items.append(item.duplicate(true))
	return items

func choose_npc_loadout() -> void:
	var element := get_random_npc_element()
	var weapons := _compatible_items("weapon", element)
	var armors := _compatible_items("armor", element)
	var accessories := _compatible_items("accessory", element)
	var candidates: Array[Dictionary] = []

	# CSP domains only contain items compatible with the NPC's chosen element.
	for weapon in weapons:
		for armor in armors:
			for accessory in accessories:
				candidates.append({"weapon": weapon, "armor": armor, "accessory": accessory})

	if candidates.is_empty():
		return

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var current_index := rng.randi_range(0, candidates.size() - 1)
	var best_index := current_index
	var best_score := _score_npc_candidate(candidates[best_index], element)
	var temperature := 8.0

	# Simulated annealing explores compatible loadouts and keeps the best score.
	for _iteration in range(100):
		var proposed_index := rng.randi_range(0, candidates.size() - 1)
		var current_score := _score_npc_candidate(candidates[current_index], element)
		var proposed_score := _score_npc_candidate(candidates[proposed_index], element)
		var score_delta := proposed_score - current_score
		if score_delta >= 0.0 or rng.randf() < exp(score_delta / maxf(temperature, 0.01)):
			current_index = proposed_index
		if proposed_score > best_score:
			best_index = proposed_index
			best_score = proposed_score
		temperature *= 0.94

	npc_loadout = {
		"element": element,
		"weapon": candidates[best_index]["weapon"].duplicate(true),
		"armor": candidates[best_index]["armor"].duplicate(true),
		"accessory": candidates[best_index]["accessory"].duplicate(true)
	}

func _compatible_items(category: String, element: String) -> Array[Dictionary]:
	var compatible: Array[Dictionary] = []
	for item in get_item_catalog(category):
		if item["element"] == "Neutral" or item["element"] == element:
			compatible.append(item)
	return compatible

func _score_npc_candidate(candidate: Dictionary, element: String) -> float:
	var score := 0.0
	for category in ["weapon", "armor", "accessory"]:
		var item: Dictionary = candidate[category]
		score += float(item["power"]) * 1.25 + float(item["defense"])
		if item["element"] == element:
			score += 2.0
	if candidate["weapon"]["element"] == element and candidate["accessory"]["name"] == "Elemental Gem":
		score += 3.0
	return score
