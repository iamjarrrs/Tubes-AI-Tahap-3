extends Node

const ELEMENTS: Array[String] = ["Fire", "Water", "Nature"]
const ITEM_CATALOG := {
	"weapon": [
		{"name": "Dagger", "power": 3, "defense": 0, "element": "Any"},
		{"name": "Flame Sword", "power": 7, "defense": 0, "element": "Fire"},
		{"name": "Aqua Wand", "power": 5, "defense": 1, "element": "Water"},
		{"name": "Leaf Blade", "power": 6, "defense": 1, "element": "Nature"}
	],
	"armor": [
		{"name": "Leather Vest", "power": 0, "defense": 3, "element": "Any"},
		{"name": "Flame Mail", "power": 1, "defense": 6, "element": "Fire"},
		{"name": "Ocean Shield", "power": 0, "defense": 7, "element": "Water"},
		{"name": "Forest Cloak", "power": 2, "defense": 4, "element": "Nature"}
	],
	"accessory": [
		{"name": "Apothecary Charm", "power": 1, "defense": 1, "element": "Any"},
		{"name": "Guardian Pendant", "power": 0, "defense": 4, "element": "Any"},
		{"name": "Berserker Amulet", "power": 4, "defense": 0, "element": "Any"},
		{"name": "Elemental Gem", "power": 3, "defense": 2, "element": "Any"}
	]
}

var selected_map: String = ""
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

	var map_scene := get_tree().current_scene
	if map_scene == null:
		push_error("No active map scene after scene transition.")
		return
	var player := map_scene.find_child("Player", true, false) as CharacterBody2D
	if player:
		player.set_physics_process(false)
	else:
		push_error("Selected map has no Player node; cannot start NPC pathfinding.")
		return

	var npc := load("res://Tiled_files/npc.tscn").instantiate() as CharacterBody2D
	if npc == null:
		push_error("Could not instantiate NPC scene.")
		return
	npc.name = "BattleNPC"
	npc.global_position = player.global_position + Vector2(112.0, 0.0)
	map_scene.add_child(npc)
	await get_tree().process_frame

	var elapsed := 0.0
	while elapsed < 3.0 and npc.global_position.distance_to(player.global_position) > 24.0:
		await get_tree().create_timer(0.1).timeout
		elapsed += 0.1
	npc.set_physics_process(false)

	var element_ui := _instantiate_draft_ui("res://scenes/ui/ElementSelectionUI.tscn") as CanvasLayer
	if element_ui == null:
		return
	element_ui.layer = 110
	map_scene.add_child(element_ui)

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
		if item["element"] == "Any" or item["element"] == element:
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
