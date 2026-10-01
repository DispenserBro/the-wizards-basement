class_name FloatingTextHelper
extends Object

static func spawn(parent: Node, global_position: Vector2, text: String, color: Color, font_size: int = 16, scale: float = 1.0, dispersion_x: float = 0.0) -> void:
	if parent == null or not is_instance_valid(parent):
		return

	var label = Label.new()
	label.text = text
	label.z_index = 100
	label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var random_x = randf_range(-10.0, 10.0)
	var random_y = randf_range(-5.0, 5.0)
	label.position = global_position + Vector2(random_x, random_y)

	label.add_theme_color_override("font_color", color)

	var font = load("res://fonts/ithaca-font/Ithaca-LVB75.ttf")
	if font != null:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)

	label.clip_text = false
	parent.add_child(label)

	label.pivot_offset = label.get_minimum_size() / 2.0

	var tween = parent.create_tween()
	tween.set_parallel(true)

	var target_pos = label.position + Vector2(dispersion_x + randf_range(-5.0, 5.0), -40.0)
	tween.tween_property(label, "position", target_pos, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 1.2)

	label.scale = Vector2(0.5, 0.5)
	tween.tween_property(label, "scale", Vector2(scale, scale), 0.15)

	tween.chain().tween_callback(label.queue_free)
