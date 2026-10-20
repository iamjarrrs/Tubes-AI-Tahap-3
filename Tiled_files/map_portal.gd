extends Node2D

const MAP_SELECTOR = preload("res://Tiled_files/map_selector.gd")

@onready var portal_area: Area2D = $Area2D

var selector_open := false
var animation_time := 0.0

func _ready() -> void:
	portal_area.body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	animation_time += delta
	queue_redraw()

func _draw() -> void:
	var pulse := 1.0 + sin(animation_time * 2.4) * 0.06
	var outer := _ellipse_points(34.0 * pulse, 47.0 * pulse)
	var inner := _ellipse_points(25.0, 37.0)
	draw_colored_polygon(outer, Color(0.18, 0.65, 1.0, 0.18))
	draw_colored_polygon(inner, Color(0.12, 0.48, 0.82, 0.72))
	draw_polyline(_ellipse_points(29.0 * pulse, 41.0 * pulse, true), Color(0.60, 0.88, 1.0, 0.95), 3.0, true)
	draw_colored_polygon(_ellipse_points(13.0, 26.0), Color(0.06, 0.13, 0.30, 0.78))

func _ellipse_points(radius_x: float, radius_y: float, close: bool = false) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(49 if close else 48):
		var angle := TAU * float(index) / 48.0
		points.append(Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or selector_open:
		return

	var selector := MAP_SELECTOR.new()
	selector_open = true
	selector.open_for(self, body as CharacterBody2D)
	get_tree().current_scene.add_child(selector)

func close_selector() -> void:
	selector_open = false
	var player := get_tree().get_first_node_in_group("player")
	if player is CharacterBody2D:
		player.set_physics_process(true)
