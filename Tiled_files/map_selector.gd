extends CanvasLayer

signal closed

const MAPS = [
	{
		"name": "Aqua",
		"path": "res://map_aqua.tscn",
		"preview": "res://map/map_aqua.jpg",
		"description": "Jelajahi dunia bawah laut",
	},
	{
		"name": "Forest",
		"path": "res://map_forest.tscn",
		"preview": "res://map/map_forest.jpg",
		"description": "Masuki hutan yang rimbun",
	},
	{
		"name": "Volcano",
		"path": "res://map_volcano.tscn",
		"preview": "res://map/map_volcano.jpg",
		"description": "Hadapi panasnya gunung berapi",
	},
]

var player: CharacterBody2D
var error_label: Label

func open_for(portal: Node2D, entering_player: CharacterBody2D) -> void:
	player = entering_player
	player.set_physics_process(false)
	closed.connect(portal.close_selector)
	_build_ui()

func _build_ui() -> void:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.025, 0.035, 0.07, 0.82)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(backdrop)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-400, -220)
	panel.size = Vector2(800, 440)
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	overlay.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	panel.add_child(content)

	var heading := Label.new()
	heading.text = "PILIH DUNIA"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 30)
	heading.add_theme_color_override("font_color", Color(0.82, 0.94, 1.0))
	content.add_child(heading)

	var instruction := Label.new()
	instruction.text = "Pilih salah satu portal untuk melanjutkan perjalanan"
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction.add_theme_color_override("font_color", Color(0.72, 0.78, 0.88))
	content.add_child(instruction)

	var cards := HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 18)
	content.add_child(cards)

	for map_data in MAPS:
		cards.add_child(_make_map_card(map_data))

	error_label = Label.new()
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.add_theme_color_override("font_color", Color(1.0, 0.48, 0.42))
	content.add_child(error_label)

	var close_button := Button.new()
	close_button.text = "Tutup  (Esc)"
	close_button.custom_minimum_size = Vector2(150, 38)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.pressed.connect(_close)
	content.add_child(close_button)

func _make_map_card(map_data: Dictionary) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(225, 190)
	card.clip_contents = true
	card.add_theme_stylebox_override("normal", _make_card_style(Color(0.10, 0.15, 0.24), Color(0.25, 0.34, 0.48)))
	card.add_theme_stylebox_override("hover", _make_card_style(Color(0.15, 0.25, 0.38), Color(0.34, 0.82, 1.0)))
	card.add_theme_stylebox_override("pressed", _make_card_style(Color(0.12, 0.21, 0.33), Color(0.55, 0.88, 1.0)))
	card.mouse_entered.connect(_set_card_hover.bind(card, true))
	card.mouse_exited.connect(_set_card_hover.bind(card, false))
	card.pressed.connect(_select_map.bind(map_data["path"]))

	var centered_preview := AtlasTexture.new()
	centered_preview.atlas = load(map_data["preview"])
	centered_preview.region = Rect2(222, 134, 900, 500)

	var preview := TextureRect.new()
	preview.texture = centered_preview
	preview.position = Vector2(10, 10)
	preview.size = Vector2(205, 108)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(preview)

	var text_background := ColorRect.new()
	text_background.position = Vector2(2, 120)
	text_background.size = Vector2(221, 68)
	text_background.color = Color(0.055, 0.075, 0.12, 0.96)
	text_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(text_background)

	var title := Label.new()
	title.text = map_data["name"]
	title.position = Vector2(10, 124)
	title.size = Vector2(205, 27)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.88, 0.95, 1.0))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(title)

	var description := Label.new()
	description.text = map_data["description"]
	description.position = Vector2(8, 153)
	description.size = Vector2(209, 20)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.add_theme_font_size_override("font_size", 12)
	description.add_theme_color_override("font_color", Color(0.70, 0.78, 0.88))
	description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(description)

	var border := Panel.new()
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.add_theme_stylebox_override("panel", _make_card_frame(Color(0.25, 0.34, 0.48)))
	card.add_child(border)
	card.mouse_entered.connect(_set_card_frame.bind(border, Color(0.34, 0.82, 1.0)))
	card.mouse_exited.connect(_set_card_frame.bind(border, Color(0.25, 0.34, 0.48)))

	return card

func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.075, 0.12, 0.98)
	style.border_color = Color(0.20, 0.63, 0.83, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(22)
	return style

func _make_card_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(6)
	return style

func _make_card_frame(border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	return style

func _set_card_frame(frame: Panel, border_color: Color) -> void:
	frame.add_theme_stylebox_override("panel", _make_card_frame(border_color))

func _set_card_hover(card: Button, hovering: bool) -> void:
	var tween := create_tween()
	tween.tween_property(card, "scale", Vector2.ONE * (1.045 if hovering else 1.0), 0.12)
	card.pivot_offset = card.size / 2.0

func _select_map(scene_path: String) -> void:
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		error_label.text = "Map tidak dapat dibuka (kode %d)." % error
		push_error("Gagal membuka scene map '%s' (kode %d)." % [scene_path, error])

func _close() -> void:
	closed.emit()
	queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()
