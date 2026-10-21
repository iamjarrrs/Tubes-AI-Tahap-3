extends CanvasLayer

var debug_panel: PanelContainer
var debug_label: Label

func _ready() -> void:
	layer = 120
	visible = false
	debug_panel = PanelContainer.new()
	debug_panel.position = Vector2(16.0, 16.0)
	debug_panel.custom_minimum_size = Vector2(350.0, 0.0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.07, 0.08, 0.94)
	panel_style.border_color = Color("62b4a9")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(6)
	panel_style.content_margin_left = 12.0
	panel_style.content_margin_right = 12.0
	panel_style.content_margin_top = 10.0
	panel_style.content_margin_bottom = 10.0
	debug_panel.add_theme_stylebox_override("panel", panel_style)
	debug_label = Label.new()
	debug_label.add_theme_color_override("font_color", Color("f4f1e8"))
	debug_label.add_theme_font_size_override("font_size", 15)
	debug_panel.add_child(debug_label)
	add_child(debug_panel)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		visible = not visible
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if visible:
		_refresh_text()

func _refresh_text() -> void:
	var lines: Array[String] = [
		"GAMEPLAY DEBUG  [F3]",
		"FPS: %d" % Engine.get_frames_per_second(),
		"AI: CSP + Simulated Annealing",
		"Minimax: not implemented in project"
	]
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var npc := get_tree().current_scene.get_node_or_null("BattleNPC") as Node2D
	if player:
		lines.append("MC position: %s" % str(player.global_position.round()))
	if npc:
		lines.append("NPC position: %s" % str(npc.global_position.round()))
		if player:
			lines.append("Distance: %.1f px" % npc.global_position.distance_to(player.global_position))
		var path: Variant = npc.get("current_path")
		var path_count: int = path.size() if path is PackedVector2Array else 0
		lines.append("NPC path points: %d" % path_count)
	debug_label.text = "\n".join(lines)