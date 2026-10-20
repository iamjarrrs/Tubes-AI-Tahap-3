extends CanvasLayer

@onready var mc_cards: HBoxContainer = $CenterContainer/PanelContainer/Content/MCCards
@onready var npc_cards: HBoxContainer = $CenterContainer/PanelContainer/Content/NPCCards
@onready var game_state: Node = get_node("/root/GameState")

func _ready() -> void:
	_set_map_background()
	var mc_loadout: Dictionary = game_state.get("mc_loadout")
	var npc_loadout: Dictionary = game_state.get("npc_loadout")
	_add_loadout_cards(mc_cards, mc_loadout)
	_add_loadout_cards(npc_cards, npc_loadout)
	$CenterContainer/PanelContainer/Content/StatsLabel.text = _make_stats_text(mc_loadout, npc_loadout)

func _set_map_background() -> void:
	var selected_map: String = str(game_state.get("selected_map")).to_lower()
	var background_path := "res://map/map_aqua.jpg"
	if selected_map.contains("forest"):
		background_path = "res://map/map_forest.jpg"
	elif selected_map.contains("volcano"):
		background_path = "res://map/map_volcano.jpg"
	$MapBackground.texture = load(background_path)

func _add_loadout_cards(container: HBoxContainer, loadout: Dictionary) -> void:
	for category in ["weapon", "armor", "accessory"]:
		var item: Dictionary = loadout.get(category, {})
		var item_name := str(item.get("name", "Not selected"))
		_add_card(container, category.capitalize(), item_name)

func _make_stats_text(mc_loadout: Dictionary, npc_loadout: Dictionary) -> String:
	var mc_stats := _total_stats(mc_loadout)
	var npc_stats := _total_stats(npc_loadout)
	return "MC   ATK %d  |  DEF %d       VS       NPC   ATK %d  |  DEF %d" % [
		mc_stats["attack"], mc_stats["defense"], npc_stats["attack"], npc_stats["defense"]
	]

func _total_stats(loadout: Dictionary) -> Dictionary:
	var totals := {"attack": 0, "defense": 0}
	for category in ["weapon", "armor", "accessory"]:
		var item: Dictionary = loadout.get(category, {})
		totals["attack"] += int(item.get("power", 0))
		totals["defense"] += int(item.get("defense", 0))
	return totals

func _add_card(container: HBoxContainer, category: String, item_name: String) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(145, 190)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("11191b", 1.0)
	style.border_color = Color("62b4a9")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 3.0
	style.content_margin_right = 3.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	card.add_theme_stylebox_override("panel", style)
	var artwork := TextureRect.new()
	artwork.custom_minimum_size = Vector2(139, 184)
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var artwork_path := _get_artwork_path(category.to_lower(), item_name)
	if not artwork_path.is_empty():
		artwork.texture = load(artwork_path)
	card.add_child(artwork)
	container.add_child(card)

func _get_artwork_path(category: String, item_name: String) -> String:
	var file_name := item_name
	if item_name == "Berserker Amulet":
		file_name = "Berseker Amulet"
	var path := "res://%s/%s.jpg" % [category.capitalize(), file_name]
	return path if ResourceLoader.exists(path) else ""