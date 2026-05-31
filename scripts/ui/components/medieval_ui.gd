extends RefCounted
class_name MedievalUI

const INK := Color("#2c2118")
const PARCHMENT := Color("#e1c894")
const PARCHMENT_DARK := Color("#b99256")
const GOLD := Color("#d9a441")
const WINE := Color("#6d2434")
const STONE := Color("#2f3440")
const BLUE_DARK := Color("#172333")
const BROWN := Color("#5b3726")
const MUTED_TEXT := Color("#d7c2a0")

static func panel_style(fill: Color = PARCHMENT, border: Color = BROWN, radius: int = 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	style.shadow_color = Color(0, 0, 0, 0.28)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	return style

static func button_style(fill: Color, border: Color, radius: int = 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style

static func apply_button(button: Button, accent: Color = GOLD) -> void:
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 48.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL if button.size_flags_horizontal == Control.SIZE_SHRINK_BEGIN else button.size_flags_horizontal
	button.set("text_overrun_behavior", TextServer.OVERRUN_TRIM_ELLIPSIS)
	button.set("clip_text", true)
	button.add_theme_color_override("font_color", Color("#fff4cf"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color("#1d1510"))
	button.add_theme_color_override("font_disabled_color", Color("#8a7c68"))
	button.add_theme_stylebox_override("normal", button_style(BROWN, accent))
	button.add_theme_stylebox_override("hover", button_style(BROWN.lightened(0.12), accent.lightened(0.16)))
	button.add_theme_stylebox_override("pressed", button_style(accent, Color("#fff0b0")))
	button.add_theme_stylebox_override("disabled", button_style(Color("#3c342d"), Color("#5d5044")))
	button.focus_mode = Control.FOCUS_ALL

static func apply_panel(panel: Control, dark := false) -> void:
	if panel is Panel or panel is PanelContainer:
		var fill := Color("#243043") if dark else PARCHMENT
		var border := GOLD if dark else BROWN
		panel.add_theme_stylebox_override("panel", panel_style(fill, border, 12))

static func apply_title(label: Label, size := 30) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", GOLD)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)

static func apply_body_label(label: Label, dark_text := false) -> void:
	label.add_theme_color_override("font_color", INK if dark_text else MUTED_TEXT)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

static func apply_compact_label(label: Label, dark_text := false) -> void:
	label.add_theme_color_override("font_color", INK if dark_text else MUTED_TEXT)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true

static func apply_progress(bar: ProgressBar, fill: Color = WINE) -> void:
	var background := button_style(Color("#1c1720"), Color("#6b5736"), 6)
	var foreground := button_style(fill, Color("#f1c15a"), 6)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", foreground)

static func apply_tree(root: Node) -> void:
	for child in root.get_children():
		if child is Panel or child is PanelContainer:
			apply_panel(child, true)
		if child is Button:
			apply_button(child)
		if child is Label:
			var label := child as Label
			if label.name.to_lower().contains("title"):
				apply_title(label, int(label.get_theme_font_size("font_size")) if label.get_theme_font_size("font_size") > 0 else 30)
			else:
				apply_body_label(label, false)
		if child is ProgressBar:
			apply_progress(child)
		apply_tree(child)

static func transition_in(control: Control) -> void:
	control.modulate.a = 0.0
	control.scale = Vector2(0.985, 0.985)
	var tween := control.create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate:a", 1.0, 0.18)
	tween.parallel().tween_property(control, "scale", Vector2.ONE, 0.18)

static func rarity_color(rarity: String) -> Color:
	match rarity:
		"incomum":
			return Color("#77d47b")
		"raro":
			return Color("#6fb7ff")
		"epico":
			return Color("#c990ff")
		"lendario":
			return Color("#f2c14e")
	return Color("#d8d3c8")

static func icon_text(icon: String, value: String) -> String:
	return "%s %s" % [icon, value]
