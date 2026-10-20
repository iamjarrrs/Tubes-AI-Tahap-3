extends CanvasLayer

@onready var fade_rect: ColorRect = $FadeRect

var is_transitioning := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	fade_rect.modulate.a = 0.0

func change_scene_with_fade(target_path: String) -> bool:
	if is_transitioning:
		return false
	if not ResourceLoader.exists(target_path):
		push_error("Could not find scene to change to: " + target_path)
		return false
	is_transitioning = true

	var fade_out := create_tween()
	fade_out.tween_property(fade_rect, "modulate:a", 1.0, 0.5)
	await fade_out.finished

	var change_error := get_tree().change_scene_to_file(target_path)
	var scene_changed := change_error == OK
	if change_error == OK:
		await get_tree().scene_changed
	else:
		push_error("Could not change scene to: " + target_path)

	var fade_in := create_tween()
	fade_in.tween_property(fade_rect, "modulate:a", 0.0, 0.5)
	await fade_in.finished
	is_transitioning = false
	return scene_changed