extends RefCounted
class_name EntitySpriteAtlas

const TEXTURE_PATH := "res://assets/sprites/entities/IsometricTRPGAssetPack_Entities.png"
const ATLAS_PATH := "res://assets/sprites/entities/outlined_entities_atlas.json"

static var _atlas: Dictionary = {}
static var _texture: Texture2D

static func apply(sprite: Sprite2D, sprite_name: String) -> void:
	if not sprite:
		return
	var entry: Dictionary = get_sprite(sprite_name)
	if entry.is_empty():
		push_warning("Entity sprite not found: %s" % sprite_name)
		return
	sprite.texture = get_texture()
	sprite.region_enabled = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var scale_factor := _get_texture_scale_factor()
	sprite.region_rect = Rect2(
		float(entry["x"]) * scale_factor,
		float(entry["y"]) * scale_factor,
		float(entry["w"]) * scale_factor,
		float(entry["h"]) * scale_factor
	)
	sprite.centered = true

static func apply_entity_frame(sprite: Sprite2D, type_name: String, facing: String, action: String, frame: int) -> void:
	apply(sprite, "%s_%s_%s_%d" % [type_name, facing, action, frame])

static func get_sprite(sprite_name: String) -> Dictionary:
	var sprites: Dictionary = _get_atlas().get("sprites", {})
	return sprites.get(sprite_name, {})

static func names_for_type(type_name: String) -> Array:
	var groups: Dictionary = _get_atlas().get("groups", {})
	return groups.get(type_name, [])

static func get_texture() -> Texture2D:
	if not _texture:
		_texture = load(TEXTURE_PATH)
	return _texture

static func _get_texture_scale_factor() -> float:
	var metadata: Dictionary = _get_atlas().get("grid", {})
	var columns := int(metadata.get("columns", 4))
	var base_cell_width := float(metadata.get("cell_width", 16))
	var texture := get_texture()
	if not texture or columns <= 0 or base_cell_width <= 0.0:
		return 1.0
	return float(texture.get_width()) / (float(columns) * base_cell_width)

static func _get_atlas() -> Dictionary:
	if not _atlas.is_empty():
		return _atlas
	if not FileAccess.file_exists(ATLAS_PATH):
		push_warning("Entity sprite atlas missing: %s" % ATLAS_PATH)
		return {}
	var file: FileAccess = FileAccess.open(ATLAS_PATH, FileAccess.READ)
	if not file:
		push_warning("Could not open entity sprite atlas: %s" % ATLAS_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		_atlas = parsed
	return _atlas
